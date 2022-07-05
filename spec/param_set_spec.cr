require "./spec_helper"

describe MM::ParameterSet do
  describe "#[]?" do
    it "returns the pararameter for the connectivity" do
      topology = Chem::Topology.read "spec/data/5yok_initial.psf"
      params = MM::ParameterSet.new

      bond = topology.bonds[0]
      typenames = bond.atoms.map(&.typename.not_nil!)
      bond_t = MM::BondType.new(typenames, 340, 1.09)
      params << bond_t
      params[bond]?.should eq bond_t

      angle = topology.angles[0]
      typenames = angle.atoms.map(&.typename.not_nil!)
      angle_t = MM::AngleType.new(typenames, 340, 1.09)
      params << angle_t
      params[angle]?.should eq angle_t

      dihedral = topology.dihedrals[0]
      typenames = dihedral.atoms.map(&.typename.not_nil!)
      dihedral_t = MM::DihedralType.new(typenames, [MM::Phase.new(340, 2, 1.09)])
      params << dihedral_t
      params[dihedral]?.should eq dihedral_t

      improper = topology.impropers[0]
      typenames = improper.atoms.map(&.typename.not_nil!)
      improper_t = MM::ImproperType.new(typenames, 340, 1.09)
      params << improper_t
      params[improper]?.should eq improper_t
    end
  end

  describe "#<<" do
    it "appends an bond" do
      bond = MM::BondType.new({"A", "B"}, force_constant: 1.1, eq_value: 180)

      params = MM::ParameterSet.new
      params << bond
      params.bonds.size.should eq 1
      params.bonds[0].should eq bond
    end

    it "appends an angle" do
      angle = MM::AngleType.new({"A", "B", "C"}, 1.1, 180)

      params = MM::ParameterSet.new
      params << angle
      params.angles.size.should eq 1
      params.angles[0].should eq angle
    end

    it "appends a dihedral" do
      dihedral_t = MM::DihedralType.new({"A", "B", "C", "D"}, [
        MM::Phase.new(1.1, 2, 180), MM::Phase.new(1.1, 3, 0.0),
      ])

      params = MM::ParameterSet.new
      params << dihedral_t
      params.dihedrals.size.should eq 1
      params.dihedrals[0].should eq dihedral_t

      params << dihedral_t
      params.dihedrals.size.should eq 1
      params.dihedrals[0].should eq dihedral_t
    end

    it "appends an improper" do
      improper = MM::ImproperType.new({"A", "B", "C", "D"}, 1.1, 180)

      params = MM::ParameterSet.new
      params << improper
      params.impropers.size.should eq 1
      params.impropers[0].should eq improper
    end

    it "appends an array of dihedrals (#1)" do
      params = MM::ParameterSet.new
      params << MM::DihedralType.new({"A", "B", "C", "D"}, [MM::Phase.new(1.1, 2, 180)])
      params.dihedrals.size.should eq 1
      params << params.dihedrals[0]
      params.dihedrals.size.should eq 1
    end
  end

  describe "#detect_missing" do
    it "finds missing parameters" do
      topology = Chem::Topology.read "spec/data/5yok_initial.psf"
      params = MM::ParameterSet.from_charmm(
        "spec/data/top_opls_aam_M.inp",
        "spec/data/par_opls_aam_M.inp")
      params.detect_missing(topology).map(&.atoms.map(&.typename)).should eq [
        {"C136", "C224", "C267"},
        {"C137", "C224", "C267"},
        {"C149", "C224", "C267"},
        {"C136", "C224", "C267", "O268"},
        {"C136", "C224", "C267", "O269"},
        {"H140", "C136", "C224", "C267"},
        {"C308", "C136", "C224", "C267"},
        {"C137", "C136", "C224", "C267"},
        {"C137", "C224", "C267", "O268"},
        {"C137", "C224", "C267", "O269"},
        {"H140", "C137", "C224", "C267"},
        {"C135", "C137", "C224", "C267"},
        {"C136", "C136", "C224", "C267"},
        {"C149", "C224", "C267", "O268"},
        {"C149", "C224", "C267", "O269"},
        {"H140", "C149", "C224", "C267"},
        {"C145", "C149", "C224", "C267"},
        {"C136", "C137", "C224", "C267"},
      ]
    end
  end

  describe "#fuzzy_search" do
    it "searches params for an angle" do
      topology = Chem::Topology.read "spec/data/5yok_initial.psf"
      params = MM::ParameterSet.from_charmm(
        "spec/data/top_opls_aam_M.inp",
        "spec/data/par_opls_aam_M.inp")
      angle = Chem::Angle.new *topology.atoms[{10, 8, 28}]
      angle_types = params.fuzzy_search(angle)
      angle_types.should_not be_empty
      angle_types.size.should eq 1
      angle_types[0].typenames.should eq({"C136", "C224", "C235"})
    end

    it "searches params for a dihedral" do
      topology = Chem::Topology.read "spec/data/5yok_initial.psf"
      params = MM::ParameterSet.from_charmm(
        "spec/data/top_opls_aam_M.inp",
        "spec/data/par_opls_aam_M.inp")
      dihedral = Chem::Dihedral.new *topology.atoms[{10, 8, 28, 30}]
      dihedral_types = params.fuzzy_search(dihedral)
      dihedral_types.should_not be_empty
      dihedral_types.size.should eq 1
      dihedral_types[0].typenames.should eq({"C136", "C224", "C235", "O236"})
    end

    it "searches for a reversed dihedral" do
      topology = Chem::Topology.read "spec/data/5yok_initial.psf"
      params = MM::ParameterSet.from_charmm(
        "spec/data/top_opls_aam_M.inp",
        "spec/data/par_opls_aam_M.inp")
      dihedral = Chem::Dihedral.new *topology.atoms[{11, 10, 8, 28}]
      dihedral_types = params.fuzzy_search(dihedral)
      dihedral_types.should_not be_empty
      dihedral_types.size.should eq 1
      dihedral_types[0].typenames.should eq({"C235", "C224", "C136", "H140"})
    end
  end

  describe "#dihedral?" do
    it "returns a dihedral with wildcards" do
      dihedral_t = MM::DihedralType.new({nil, "B", "C", nil}, [MM::Phase.new(1.1, 2, 180)])
      params = MM::ParameterSet.new
      params << dihedral_t
      params.dihedral?({"A", "B", "C", "D"}).should eq dihedral_t
      params.dihedral?({"Y", "B", "C", "Z"}).should eq dihedral_t
    end
  end

  describe "#improper?" do
    it "returns an improper with wildcards" do
      improper_t = MM::ImproperType.new({"A", nil, nil, "D"}, 1.1, 180)
      params = MM::ParameterSet.new
      params << improper_t
      params.improper?({"A", "B", "C", "D"}).should eq improper_t
      params.improper?({"A", "Y", "Z", "D"}).should eq improper_t
    end
  end
end
