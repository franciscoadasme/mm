require "./spec_helper"

describe MM::CHARMM do
  describe ".read_topology" do
    it "reads a topology file" do
      params = MM::CHARMM.read_topology "spec/data/top_opls_aam_M.inp"
      params.atoms.size.should eq 79
      params.residues.size.should eq 25
      params.patches.size.should eq 18

      restype = params.residues["ALA"]?.should_not be_nil
      restype.name.should eq "ALA"
      restype.atoms.size.should eq 10
      restype.bonds.size.should eq 9
      restype.bonds.count(&.order.==(2)).should eq 1
      restype.link_bond.should eq MM::ResidueType::BondRecord.new("C", "N")
      restype.first_patch.should eq "NTER"
      restype.last_patch.should eq "CTER"
      restype.partial_charge.should eq 0

      patch = params.patches["DISU"]?.should_not be_nil
      patch.partial_charge.should be_close -0.24, 1e-15
      patch.atoms.size.should eq 4
      patch.delete_atoms.should eq ["1HG1", "2HG1"]
      patch.bonds.size.should eq 1
      patch.bonds.count(&.order.==(2)).should eq 0
    end
  end

  describe ".load_parameters" do
    it "reads a parameter file" do
      params = MM::CHARMM.read_topology "spec/data/top_opls_aam_M.inp"
      MM::CHARMM.load_parameters params, "spec/data/par_opls_aam_M.inp"

      params.bonds.size.should eq 313

      bond = params.bonds[{"C223", "C267"}]?.should_not be_nil
      bond.force_constant.should eq 317
      bond.eq_value.should eq 1.522
      bond.penalty.should eq 0.0
      bond.comment.should eq "phosphorylated C-terminal Gly, adm jr."

      params.angles.size.should eq 843

      params.angles[{"C136", "C224", "C267"}]?.should be_nil # commented

      angle = params.angles[{"HT", "OT", "HT"}]?.should_not be_nil
      angle.force_constant.should eq 55
      angle.eq_value.should eq 104.52
      angle.penalty.should eq 0.0
      angle.comment.should be_nil

      angle = params.angles[{"C223", "C267", "O268"}]?.should_not be_nil
      angle.force_constant.should eq 70
      angle.eq_value.should eq 108
      angle.penalty.should eq 264.5
      angle.comment.should eq "protonated C-terminal Gly, adm jr."

      params.dihedrals.size.should eq 1630

      dihedrals = params.dihedrals[{nil, "C145", "C145", nil}]?.should_not be_nil
      dihedrals.size.should eq 1
      dihedrals[0].force_constant.should eq 3.625
      dihedrals[0].multiplicity.should eq 2
      dihedrals[0].eq_value.should eq 180
      dihedrals[0].penalty.should eq 0.0
      dihedrals[0].comment.should be_nil

      dihedrals = params.dihedrals[{"C505", "C224", "C235", "N238"}]?.should_not be_nil
      dihedrals.size.should eq 3
      dihedrals[0].force_constant.should eq 0.8895
      dihedrals[0].multiplicity.should eq 1
      dihedrals[0].eq_value.should eq 0
      dihedrals[0].penalty.should eq 0.0
      dihedrals[0].comment.should be_nil
      dihedrals[1].force_constant.should eq 0.2095
      dihedrals[1].multiplicity.should eq 2
      dihedrals[1].eq_value.should eq 180
      dihedrals[1].penalty.should eq 0.0
      dihedrals[1].comment.should be_nil
      dihedrals[2].force_constant.should eq -0.0550
      dihedrals[2].multiplicity.should eq 3
      dihedrals[2].eq_value.should eq 0
      dihedrals[2].penalty.should eq 0.0
      dihedrals[2].comment.should be_nil

      params.impropers.size.should eq 291

      improper = params.impropers[{"O268", "C267", "C223", "O269"}]?.should_not be_nil
      improper.force_constant.should eq 10.5
      improper.eq_value.should eq 180
      improper.penalty.should eq 0.0
      improper.comment.should eq "Gly"

      params.atoms.values.count(&.lj).should eq 78
      atom = params.atoms["CLA"]?.should_not be_nil
      lj = atom.lj.should_not be_nil
      lj.epsilon.should eq -0.71
      lj.rmin.should eq 4.5122974
      lj = atom.lj14.should_not be_nil
      lj.epsilon.should eq -0.71
      lj.rmin.should eq 4.5122974
    end
  end
end
