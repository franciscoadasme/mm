require "./spec_helper"

describe MM::ParameterSet do
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
end
