require "./spec_helper"

describe MM::CHARMM do
  describe ".read_topology" do
    it "reads a topology file" do
      params = MM::CHARMM.read_topology "spec/data/top_opls_aam_M.inp"
      params.atom_types.size.should eq 79
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
end
