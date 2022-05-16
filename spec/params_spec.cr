require "./spec_helper"

describe MM::ParameterType do
  describe "#copy_with" do
    it "copies a bond type" do
      bond_t = MM::BondType.new({"A", "B"}, 1.1, 2.1)
      other = bond_t.copy_with(typenames: {"B", "A"})
      other.should be_a MM::BondType
      other.typenames.should eq({"B", "A"})
      other.force_constant.should eq bond_t.force_constant
      other.eq_value.should eq bond_t.eq_value
      other.penalty.should eq bond_t.penalty
      other.comment.should eq bond_t.comment
    end

    it "copies a dihedral type" do
      dihedral_t = MM::DihedralType.new({"A", "B", "C", "D"}, 2, 1.1, 180)
      other = dihedral_t.copy_with(multiplicity: 1)
      other.should be_a MM::DihedralType
      other.typenames.should eq dihedral_t.typenames
      other.multiplicity.should eq 1
      other.force_constant.should eq dihedral_t.force_constant
      other.eq_value.should eq dihedral_t.eq_value
      other.penalty.should eq dihedral_t.penalty
      other.comment.should eq dihedral_t.comment
    end
  end
end
