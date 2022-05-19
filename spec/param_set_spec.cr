require "./spec_helper"

describe MM::ParameterSet do
  describe "#[]?" do
    it "returns the pararameter for the connectivity" do
      topology = Chem::Topology.read "spec/data/5yok_initial.psf"
      params = MM::ParameterSet.new

      bond = topology.bonds[0]
      typenames = bond.atoms.map(&.type.not_nil!)
      bond_type = MM::BondType.new(typenames, 340, 1.09)
      params << bond_type
      params[bond]?.should eq bond_type

      angle = topology.angles[0]
      typenames = angle.atoms.map(&.type.not_nil!)
      angle_type = MM::AngleType.new(typenames, 340, 1.09)
      params << angle_type
      params[angle]?.should eq angle_type

      dihedral = topology.dihedrals[0]
      typenames = dihedral.atoms.map(&.type.not_nil!)
      dihedral_type = MM::DihedralType.new(typenames, 2, 340, 1.09)
      params << dihedral_type
      params[dihedral]?.should eq [dihedral_type]

      improper = topology.impropers[0]
      typenames = improper.atoms.map(&.type.not_nil!)
      improper_type = MM::ImproperType.new(typenames, 340, 1.09)
      params << improper_type
      params[improper]?.should eq improper_type
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
      dihedral2 = MM::DihedralType.new({"A", "B", "C", "D"}, 2, 1.1, 180)
      dihedral3 = MM::DihedralType.new({"A", "B", "C", "D"}, 3, 1.1, 0.0)

      params = MM::ParameterSet.new
      params << dihedral2
      params.dihedrals.size.should eq 1
      params.dihedrals[0].should eq [dihedral2]

      params << dihedral3
      params.dihedrals.size.should eq 1
      params.dihedrals[0].should eq [dihedral2, dihedral3]
    end

    it "appends an improper" do
      improper = MM::ImproperType.new({"A", "B", "C", "D"}, 1.1, 180)

      params = MM::ParameterSet.new
      params << improper
      params.impropers.size.should eq 1
      params.impropers[0].should eq improper
    end
  end

  describe "#detect_missing" do
    it "finds missing parameters" do
      topology = Chem::Topology.read "spec/data/5yok_initial.psf"
      params = MM::ParameterSet.from_charmm(
        "spec/data/top_opls_aam_M.inp",
        "spec/data/par_opls_aam_M.inp")
      params.detect_missing(topology).map(&.atoms.map(&.type)).should eq [
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
      angle = Chem::Angle[*topology.atoms[{10, 8, 28}]]
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
      dihedral = Chem::Dihedral[*topology.atoms[{10, 8, 28, 30}]]
      dihedral_types = params.fuzzy_search(dihedral)
      dihedral_types.should_not be_empty
      dihedral_types.size.should eq 1
      dihedral_types[0][0].typenames.should eq({"C136", "C224", "C235", "O236"})
    end

    it "searches for a reversed dihedral" do
      topology = Chem::Topology.read "spec/data/5yok_initial.psf"
      params = MM::ParameterSet.from_charmm(
        "spec/data/top_opls_aam_M.inp",
        "spec/data/par_opls_aam_M.inp")
      dihedral = Chem::Dihedral[*topology.atoms[{11, 10, 8, 28}]]
      dihedral_types = params.fuzzy_search(dihedral)
      dihedral_types.should_not be_empty
      dihedral_types.size.should eq 1
      dihedral_types[0][0].typenames.should eq({"C235", "C224", "C136", "H140"})
    end
  end

  describe "#dihedral?" do
    it "returns a dihedral with wildcards" do
      dihedral_t = MM::DihedralType.new({nil, "B", "C", nil}, 2, 1.1, 180)
      params = MM::ParameterSet.new
      params << dihedral_t
      params.dihedral?({"A", "B", "C", "D"}).should eq [dihedral_t]
      params.dihedral?({"Y", "B", "C", "Z"}).should eq [dihedral_t]
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
