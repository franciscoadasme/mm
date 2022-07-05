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
      dihedral_t = MM::DihedralType.new({"A", "B", "C", "D"}, [MM::Phase.new(1.1, 2, 180)])
      other = dihedral_t.copy_with({"A", "C", "B", "D"})
      other.should be_a MM::DihedralType
      other.typenames.should eq({"A", "C", "B", "D"})
      other.phases[0].should eq dihedral_t.phases[0]
      other.penalty.should eq dihedral_t.penalty
      other.comment.should eq dihedral_t.comment
    end
  end
end

describe MM::BondType do
  describe "#==" do
    it "compares with a bond type" do
      bond_t = MM::BondType.new({"A", "B"}, 1.1, 2.1)
      bond_t.should eq bond_t
      bond_t.should eq MM::BondType.new({"B", "A"}, 1.1, 2.1)
      bond_t.should_not eq MM::BondType.new({"A", "B"}, 1.5, 2.1)
      bond_t.should_not eq MM::BondType.new({"A", "C"}, 1.1, 2.1)
    end

    it "compares with typenames" do
      bond_t = MM::BondType.new({"A", "B"}, 1.1, 2.1)
      bond_t.should eq({"A", "B"})
      bond_t.should eq({"B", "A"})
      bond_t.should_not eq({"A", "C"})
    end
  end

  describe "#===" do
    it "compares with a bond type" do
      bond_t = MM::BondType.new({"A", "B"}, 1.1, 2.1)
      (bond_t === bond_t).should be_true
      (bond_t === MM::BondType.new({"B", "A"}, 1.1, 2.1)).should be_true
      (bond_t === MM::BondType.new({"A", "C"}, 1.1, 2.1)).should be_false
      (bond_t === MM::BondType.new({"A", "B"}, 1.5, 2.1)).should be_true
    end

    it "compares with typenames" do
      bond_t = MM::BondType.new({"A", "B"}, 1.1, 2.1)
      (bond_t === {"A", "B"}).should be_true
      (bond_t === {"B", "A"}).should be_true
      (bond_t === {"A", "C"}).should be_false
    end
  end

  describe "#typename_permutations" do
    it "returns all permutations of the typenames" do
      bond_t = MM::BondType.new({"A", "B"}, 1.1, 180)
      bond_t.typename_permutations.should eq [
        {"A", "B"},
        {"B", "A"},
      ]
    end
  end
end

describe MM::AngleType do
  describe "#==" do
    it "compares with an angle type" do
      angle_t = MM::AngleType.new({"A", "B", "C"}, 1.1, 180)
      angle_t.should eq angle_t
      angle_t.should eq MM::AngleType.new({"C", "B", "A"}, 1.1, 180)
      angle_t.should_not eq MM::AngleType.new({"A", "C", "D"}, 1.1, 180)
      angle_t.should_not eq MM::AngleType.new({"B", "C", "A"}, 1.1, 180)
      angle_t.should_not eq MM::AngleType.new({"A", "B", "C"}, 1.5, 180)
    end

    it "compares with typenames" do
      angle_t = MM::AngleType.new({"A", "B", "C"}, 1.1, 180)
      angle_t.should eq({"A", "B", "C"})
      angle_t.should eq({"C", "B", "A"})
      angle_t.should_not eq({"B", "C", "A"})
      angle_t.should_not eq({"A", "C", "D"})
    end
  end

  describe "#===" do
    it "compares with an angle type" do
      angle_t = MM::AngleType.new({"A", "B", "C"}, 1.1, 180)
      (angle_t === angle_t).should be_true
      (angle_t === MM::AngleType.new({"C", "B", "A"}, 1.1, 180)).should be_true
      (angle_t === MM::AngleType.new({"A", "C", "D"}, 1.1, 180)).should be_false
      (angle_t === MM::AngleType.new({"A", "B", "C"}, 1.5, 180)).should be_true
    end

    it "compares with typenames" do
      angle_t = MM::AngleType.new({"A", "B", "C"}, 1.1, 180)
      (angle_t === {"A", "B", "C"}).should be_true
      (angle_t === {"C", "B", "A"}).should be_true
      (angle_t === {"B", "A", "C"}).should be_false
      (angle_t === {"A", "C", "D"}).should be_false
    end
  end

  describe "#typename_permutations" do
    it "returns all permutations of the typenames" do
      angle_t = MM::AngleType.new({"A", "B", "C"}, 1.1, 180)
      angle_t.typename_permutations.should eq [
        {"A", "B", "C"},
        {"C", "B", "A"},
      ]
    end
  end
end

describe MM::DihedralType do
  describe "#==" do
    it "compares with a dihedral type" do
      dihedral_t = MM::DihedralType.new({"A", "B", "C", "D"}, [MM::Phase.new(1.1, 2, 180)])
      dihedral_t.should eq dihedral_t
      dihedral_t.should eq MM::DihedralType.new({"D", "C", "B", "A"}, [MM::Phase.new(1.1, 2, 180)])
      dihedral_t.should_not eq MM::DihedralType.new({"A", "C", "D", "E"}, [MM::Phase.new(1.1, 2, 180)])
      dihedral_t.should_not eq MM::DihedralType.new({"A", "B", "C", "D"}, [MM::Phase.new(1.5, 1, 180)])
      dihedral_t.should_not eq MM::DihedralType.new({nil, "B", "C", nil}, [MM::Phase.new(1.5, 1, 180)])

      dihedral_t = MM::DihedralType.new({nil, "B", "C", nil}, [MM::Phase.new(1.1, 2, 180)])
      dihedral_t.should eq dihedral_t
      dihedral_t.should eq MM::DihedralType.new({nil, "C", "B", nil}, [MM::Phase.new(1.1, 2, 180)])
      dihedral_t.should_not eq MM::DihedralType.new({"A", "B", "C", "D"}, [MM::Phase.new(1.1, 2, 180)])
      dihedral_t.should_not eq MM::DihedralType.new({"D", "C", "B", "A"}, [MM::Phase.new(1.1, 2, 180)])
      dihedral_t.should_not eq MM::DihedralType.new({"A", "C", "D", "E"}, [MM::Phase.new(1.1, 2, 180)])
      dihedral_t.should_not eq MM::DihedralType.new({"A", "B", "C", "D"}, [MM::Phase.new(1.5, 1, 180)])
      dihedral_t.should_not eq MM::DihedralType.new({nil, "B", "C", nil}, [MM::Phase.new(1.5, 1, 180)])
    end

    it "compares with typenames" do
      dihedral_t = MM::DihedralType.new({"A", "B", "C", "D"}, [MM::Phase.new(1.1, 2, 180)])
      dihedral_t.should eq({"A", "B", "C", "D"})
      dihedral_t.should eq({"D", "C", "B", "A"})
      dihedral_t.should_not eq({"A", "C", "D", "E"})
      dihedral_t.should_not eq({nil, "B", "C", nil})

      dihedral_t = MM::DihedralType.new({nil, "B", "C", nil}, [MM::Phase.new(1.1, 2, 180)])
      dihedral_t.should eq({nil, "B", "C", nil})
      dihedral_t.should eq({nil, "C", "B", nil})
      dihedral_t.should_not eq({"A", "B", "C", "D"})
      dihedral_t.should_not eq({"D", "C", "B", "A"})
      dihedral_t.should_not eq({"A", "C", "D", "E"})
    end
  end

  describe "#===" do
    it "compares with a dihedral type" do
      dihedral_t = MM::DihedralType.new({"A", "B", "C", "D"}, [MM::Phase.new(1.1, 2, 180)])
      (dihedral_t === dihedral_t).should be_true
      (dihedral_t === MM::DihedralType.new({"D", "C", "B", "A"}, [MM::Phase.new(1.1, 2, 180)])).should be_true
      (dihedral_t === MM::DihedralType.new({"A", "C", "D", "E"}, [MM::Phase.new(1.1, 2, 180)])).should be_false
      (dihedral_t === MM::DihedralType.new({"A", "B", "C", "D"}, [MM::Phase.new(1.5, 1, 180)])).should be_true
      (dihedral_t === MM::DihedralType.new({nil, "B", "C", nil}, [MM::Phase.new(1.1, 2, 180)])).should be_true
      (dihedral_t === MM::DihedralType.new({nil, "C", "B", nil}, [MM::Phase.new(1.1, 2, 180)])).should be_true
      (dihedral_t === MM::DihedralType.new({nil, "B", "D", nil}, [MM::Phase.new(1.1, 2, 180)])).should be_false

      dihedral_t = MM::DihedralType.new({nil, "B", "C", nil}, [MM::Phase.new(1.1, 2, 180)])
      (dihedral_t === dihedral_t).should be_true
      (dihedral_t === MM::DihedralType.new({nil, "B", "C", nil}, [MM::Phase.new(1.1, 2, 180)])).should be_true
      (dihedral_t === MM::DihedralType.new({nil, "B", "C", nil}, [MM::Phase.new(1.5, 1, 180)])).should be_true
      (dihedral_t === MM::DihedralType.new({nil, "C", "B", nil}, [MM::Phase.new(1.1, 2, 180)])).should be_true
      (dihedral_t === MM::DihedralType.new({"A", "B", "C", "D"}, [MM::Phase.new(1.1, 2, 180)])).should be_true
      (dihedral_t === MM::DihedralType.new({"D", "C", "B", "A"}, [MM::Phase.new(1.1, 2, 180)])).should be_true
      (dihedral_t === MM::DihedralType.new({nil, "B", "D", nil}, [MM::Phase.new(1.1, 2, 180)])).should be_false
      (dihedral_t === MM::DihedralType.new({"A", "C", "D", "E"}, [MM::Phase.new(1.1, 2, 180)])).should be_false
    end

    it "compares with typenames" do
      dihedral_t = MM::DihedralType.new({"A", "B", "C", "D"}, [MM::Phase.new(1.1, 2, 180)])
      (dihedral_t === {"A", "B", "C", "D"}).should be_true
      (dihedral_t === {"D", "C", "B", "A"}).should be_true
      (dihedral_t === {"B", "A", "D", "C"}).should be_false
      (dihedral_t === {"A", "C", "D", "E"}).should be_false
      (dihedral_t === {nil, "B", "C", nil}).should be_true
      (dihedral_t === {nil, "C", "B", nil}).should be_true
      (dihedral_t === {nil, "B", "D", nil}).should be_false

      dihedral_t = MM::DihedralType.new({nil, "B", "C", nil}, [MM::Phase.new(1.1, 2, 180)])
      (dihedral_t === {"A", "B", "C", "D"}).should be_true
      (dihedral_t === {"D", "C", "B", "A"}).should be_true
      (dihedral_t === {"B", "A", "D", "C"}).should be_false
      (dihedral_t === {"A", "C", "D", "E"}).should be_false
      (dihedral_t === {nil, "B", "C", nil}).should be_true
      (dihedral_t === {nil, "C", "B", nil}).should be_true
      (dihedral_t === {nil, "B", "D", nil}).should be_false
    end
  end

  describe "#typename_permutations" do
    it "returns all permutations of the typenames" do
      dihedral_t = MM::DihedralType.new({"A", "B", "C", "D"}, [MM::Phase.new(1.1, 2, 180)])
      dihedral_t.typename_permutations.should eq [
        {"A", "B", "C", "D"},
        {"D", "C", "B", "A"},
      ]
    end
  end
end

describe MM::ImproperType do
  describe "#==" do
    it "compares with an improper type" do
      improper_t = MM::ImproperType.new({"A", "B", "C", "D"}, 1.1, 180)
      improper_t.should eq improper_t
      improper_t.should_not eq MM::ImproperType.new({"D", "C", "B", "A"}, 1.1, 180)
      improper_t.should_not eq MM::ImproperType.new({"A", "C", "D", "E"}, 1.1, 180)
      improper_t.should_not eq MM::ImproperType.new({"A", "B", "C", "D"}, 1.5, 180)
      improper_t.should_not eq MM::ImproperType.new({"A", nil, nil, "D"}, 1.1, 180)

      improper_t = MM::ImproperType.new({"A", nil, nil, "D"}, 1.1, 180)
      improper_t.should eq improper_t
      improper_t.should_not eq MM::ImproperType.new({"D", nil, nil, "A"}, 1.1, 180)
      improper_t.should_not eq MM::ImproperType.new({"C", nil, nil, "B"}, 1.1, 180)
      improper_t.should_not eq MM::ImproperType.new({"A", "C", "D", "D"}, 1.1, 180)
      improper_t.should_not eq MM::ImproperType.new({"D", "B", "A", "C"}, 1.1, 180)
      improper_t.should_not eq MM::ImproperType.new({"A", "B", "C", "D"}, 1.5, 180)
    end

    it "compares with typenames" do
      improper_t = MM::ImproperType.new({"A", "B", "C", "D"}, 1.1, 180)
      improper_t.should eq({"A", "B", "C", "D"})
      improper_t.should_not eq({"D", "C", "B", "A"})
      improper_t.should_not eq({"A", "C", "D", "E"})
      improper_t.should_not eq({"A", nil, nil, "D"})

      improper_t = MM::ImproperType.new({"A", nil, nil, "D"}, 1.1, 180)
      improper_t.should eq({"A", nil, nil, "D"})
      improper_t.should_not eq({"D", nil, nil, "A"})
      improper_t.should_not eq({"A", "B", "C", "D"})
      improper_t.should_not eq({"A", "C", "B", "D"})
      improper_t.should_not eq({"D", "B", "A", "C"})
      improper_t.should_not eq({"C", nil, nil, "B"})
    end
  end

  describe "#===" do
    it "compares with an improper type" do
      improper_t = MM::ImproperType.new({"A", "B", "C", "D"}, 1.1, 180)
      (improper_t === improper_t).should be_true
      (improper_t === MM::ImproperType.new({"A", "B", "D", "C"}, 1.1, 180)).should be_true
      (improper_t === MM::ImproperType.new({"C", "B", "A", "D"}, 1.1, 180)).should be_true
      (improper_t === MM::ImproperType.new({"C", "B", "D", "A"}, 1.1, 180)).should be_true
      (improper_t === MM::ImproperType.new({"D", "B", "A", "C"}, 1.1, 180)).should be_true
      (improper_t === MM::ImproperType.new({"D", "B", "C", "A"}, 1.1, 180)).should be_true
      (improper_t === MM::ImproperType.new({"D", "C", "B", "A"}, 1.1, 180)).should be_false
      (improper_t === MM::ImproperType.new({"A", "C", "D", "E"}, 1.1, 180)).should be_false
      (improper_t === MM::ImproperType.new({"A", "B", "C", "D"}, 1.5, 180)).should be_true
      (improper_t === MM::ImproperType.new({"A", nil, nil, "D"}, 1.1, 180)).should be_true
      (improper_t === MM::ImproperType.new({"A", nil, nil, "C"}, 1.1, 180)).should be_false

      improper_t = MM::ImproperType.new({"A", nil, nil, "D"}, 1.1, 180)
      (improper_t === improper_t).should be_true
      (improper_t === MM::ImproperType.new({"A", "C", "B", "D"}, 1.1, 180)).should be_true
      (improper_t === MM::ImproperType.new({"A", "B", "D", "C"}, 1.1, 180)).should be_false
      (improper_t === MM::ImproperType.new({"C", "B", "A", "D"}, 1.1, 180)).should be_false
      (improper_t === MM::ImproperType.new({"C", "B", "D", "A"}, 1.1, 180)).should be_false
      (improper_t === MM::ImproperType.new({"D", "B", "A", "C"}, 1.1, 180)).should be_false
      (improper_t === MM::ImproperType.new({"D", "B", "C", "A"}, 1.1, 180)).should be_false
      (improper_t === MM::ImproperType.new({"D", "C", "B", "A"}, 1.1, 180)).should be_false
      (improper_t === MM::ImproperType.new({"A", "C", "D", "E"}, 1.1, 180)).should be_false
      (improper_t === MM::ImproperType.new({"A", "B", "C", "D"}, 1.5, 180)).should be_true
      (improper_t === MM::ImproperType.new({"D", nil, nil, "A"}, 1.1, 180)).should be_false
      (improper_t === MM::ImproperType.new({"A", nil, nil, "C"}, 1.1, 180)).should be_false
    end

    it "compares with typenames" do
      improper_t = MM::ImproperType.new({"A", "B", "C", "D"}, 1.1, 180)
      (improper_t === {"A", "B", "C", "D"}).should be_true
      (improper_t === {"A", "B", "D", "C"}).should be_true
      (improper_t === {"C", "B", "A", "D"}).should be_true
      (improper_t === {"C", "B", "D", "A"}).should be_true
      (improper_t === {"D", "B", "A", "C"}).should be_true
      (improper_t === {"D", "B", "C", "A"}).should be_true
      (improper_t === {"A", "C", "B", "D"}).should be_false
      (improper_t === {"D", "C", "B", "A"}).should be_false
      (improper_t === {"A", "C", "D", "E"}).should be_false
      (improper_t === {"A", nil, nil, "D"}).should be_true
      (improper_t === {"D", nil, nil, "A"}).should be_false
      (improper_t === {"A", nil, nil, "C"}).should be_false

      improper_t = MM::ImproperType.new({"A", nil, nil, "D"}, 1.1, 180)
      (improper_t === {"A", "B", "C", "D"}).should be_true
      (improper_t === {"A", "B", "D", "C"}).should be_false
      (improper_t === {"C", "B", "A", "D"}).should be_false
      (improper_t === {"C", "B", "D", "A"}).should be_false
      (improper_t === {"D", "B", "A", "C"}).should be_false
      (improper_t === {"D", "B", "C", "A"}).should be_false
      (improper_t === {"A", "C", "B", "D"}).should be_true
      (improper_t === {"D", "C", "B", "A"}).should be_false
      (improper_t === {"A", "C", "D", "E"}).should be_false
      (improper_t === {"A", nil, nil, "D"}).should be_true
      (improper_t === {"D", nil, nil, "A"}).should be_false
      (improper_t === {"A", nil, nil, "C"}).should be_false
    end
  end

  describe "#typename_permutations" do
    it "returns all permutations of the typenames" do
      improper_t = MM::ImproperType.new({"A", "B", "C", "D"}, 1.1, 180)
      improper_t.typename_permutations.should eq [
        {"A", "B", "C", "D"},
        {"A", "B", "D", "C"},
        {"C", "B", "A", "D"},
        {"C", "B", "D", "A"},
        {"D", "B", "A", "C"},
        {"D", "B", "C", "A"},
      ]
    end
  end
end
