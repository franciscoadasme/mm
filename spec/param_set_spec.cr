require "./spec_helper"

describe MM::ParameterSet do
  describe "#[]?" do
    it "returns the pararameter for the connectivity" do
      topology = Chem::Topology.read "spec/data/5yok_initial.psf"
      params = MM::ParameterSet.new

      bond = topology.bonds[0]
      bond_type = MM::BondType.new(340, 1.09)
      params[bond.atoms.map(&.type.not_nil!)] = bond_type
      params[bond]?.should eq bond_type

      angle = topology.angles[0]
      angle_type = MM::AngleType.new(340, 1.09)
      params[angle.atoms.map(&.type.not_nil!)] = angle_type
      params[angle]?.should eq angle_type

      dihedral = topology.dihedrals[0]
      dihedral_type = MM::DihedralType.new(2, 340, 1.09)
      params[dihedral.atoms.map(&.type.not_nil!)] = dihedral_type
      params[dihedral]?.should eq [dihedral_type]

      improper = topology.impropers[0]
      improper_type = MM::ImproperType.new(340, 1.09)
      params[improper.atoms.map(&.type.not_nil!)] = improper_type
      params[improper]?.should eq improper_type
    end
  end

  describe "#[]=" do
    it "appends an bond" do
      bond = MM::BondType.new(force_constant: 1.1, eq_value: 180)

      params = MM::ParameterSet.new
      params[{"A", "B"}] = bond
      params.bonds[{"A", "B"}]?.should eq bond
      params.bonds[{"B", "A"}]?.should eq bond
    end

    it "appends an angle" do
      angle = MM::AngleType.new(force_constant: 1.1, eq_value: 180)

      params = MM::ParameterSet.new
      params[{"A", "B", "C"}] = angle
      params.angles[{"A", "B", "C"}]?.should eq angle
      params.angles[{"C", "B", "A"}]?.should eq angle
    end

    it "appends a dihedral" do
      dihedral2 = MM::DihedralType.new(2, force_constant: 1.1, eq_value: 180)
      dihedral3 = MM::DihedralType.new(2, force_constant: 1.1, eq_value: 180)

      params = MM::ParameterSet.new
      params[{"A", "B", "C", "D"}] = dihedral2
      params.dihedrals[{"A", "B", "C", "D"}]?.should eq [dihedral2]
      params.dihedrals[{"D", "C", "B", "A"}]?.should eq [dihedral2]

      params[{"A", "B", "C", "D"}] = dihedral3
      params.dihedrals[{"A", "B", "C", "D"}]?.should eq [dihedral2, dihedral3]
      params.dihedrals[{"D", "C", "B", "A"}]?.should eq [dihedral2, dihedral3]
    end

    it "appends an improper" do
      improper = MM::ImproperType.new(force_constant: 1.1, eq_value: 180)

      params = MM::ParameterSet.new
      params[{"A", "B", "C", "D"}] = improper
      params.impropers[{"A", "B", "C", "D"}]?.should eq improper
      params.impropers[{"A", "B", "D", "C"}]?.should eq improper
      params.impropers[{"C", "B", "A", "D"}]?.should eq improper
      params.impropers[{"C", "B", "D", "A"}]?.should eq improper
      params.impropers[{"D", "B", "A", "C"}]?.should eq improper
      params.impropers[{"D", "B", "C", "A"}]?.should eq improper
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
end
