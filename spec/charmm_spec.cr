require "./spec_helper"

describe MM::CHARMM do
  describe ".read_topology" do
    it "reads a topology file" do
      params = MM::CHARMM.read_topology "spec/data/top_opls_aam_M.inp"
      params.atoms.size.should eq 79
      params.residues.size.should eq 25
      params.patches.size.should eq 18

      restype = params.residue?("ALA").should_not be_nil
      restype.name.should eq "ALA"
      restype.atoms.size.should eq 10
      restype.bonds.size.should eq 9
      restype.bonds.count(&.order.==(2)).should eq 1
      restype.link_bond.should eq MM::ResidueType::BondRecord.new("C", "N")
      restype.first_patch.should eq "NTER"
      restype.last_patch.should eq "CTER"
      restype.partial_charge.should eq 0

      patch = params.patch?("DISU").should_not be_nil
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

      params.bonds.size.should eq 159

      bond = params.bond?({"C223", "C267"}).should_not be_nil
      bond.force_constant.should eq 317
      bond.eq_value.should eq 1.522
      bond.penalty.should eq 0.0
      bond.comment.should eq "phosphorylated C-terminal Gly, adm jr."

      params.angles.size.should eq 437

      params.angle?({"C136", "C224", "C267"}).should be_nil # commented

      angle = params.angle?({"HT", "OT", "HT"}).should_not be_nil
      angle.force_constant.should eq 55
      angle.eq_value.should eq 104.52
      angle.penalty.should eq 0.0
      angle.comment.should be_nil

      angle = params.angle?({"C223", "C267", "O268"}).should_not be_nil
      angle.force_constant.should eq 70
      angle.eq_value.should eq 108
      angle.penalty.should eq 264.5
      angle.comment.should eq "protonated C-terminal Gly, adm jr."

      params.dihedrals.size.should eq 817

      dihedral_t = params.dihedral?({nil, "C145", "C145", nil}).should_not be_nil
      dihedral_t.phases.size.should eq 1
      dihedral_t.phases[0].force_constant.should eq 3.625
      dihedral_t.phases[0].multiplicity.should eq 2
      dihedral_t.phases[0].eq_value.should eq 180
      dihedral_t.penalty.should eq 0.0
      dihedral_t.comment.should be_nil

      dihedral_t = params.dihedral?({"C505", "C224", "C235", "N238"}).should_not be_nil
      dihedral_t.phases.size.should eq 3
      dihedral_t.phases[0].force_constant.should eq 0.8895
      dihedral_t.phases[0].multiplicity.should eq 1
      dihedral_t.phases[0].eq_value.should eq 0
      dihedral_t.phases[1].force_constant.should eq 0.2095
      dihedral_t.phases[1].multiplicity.should eq 2
      dihedral_t.phases[1].eq_value.should eq 180
      dihedral_t.phases[2].force_constant.should eq -0.0550
      dihedral_t.phases[2].multiplicity.should eq 3
      dihedral_t.phases[2].eq_value.should eq 0
      dihedral_t.penalty.should eq 0.0
      dihedral_t.comment.should be_nil

      params.impropers.size.should eq 54 # unique, 105 in total

      improper = params.improper?({"O268", "C267", "C223", "O269"}).should_not be_nil
      improper.force_constant.should eq 10.5
      improper.eq_value.should eq 180
      improper.penalty.should eq 0.0
      improper.comment.should eq "Gly"

      params.atoms.count(&.lj).should eq 78
      atom = params.atom?("CLA").should_not be_nil
      lj = atom.lj.should_not be_nil
      lj.epsilon.should eq -0.71
      lj.rmin.should eq 4.5122974
      lj = atom.lj14.should_not be_nil
      lj.epsilon.should eq -0.71
      lj.rmin.should eq 4.5122974
    end
  end

  describe ".write_prm" do
    it "writes parameters" do
      params = MM::ParameterSet.new
      params << MM::AtomType.new(
        "C",
        Chem::PeriodicTable::C,
        mass: 12.011,
        lj: MM::LennardJones.new(-0.11, 4, 65.21, "ALLOW   PEP POL ARO"),
        comment: "carbonyl C, peptide backbone")
      params << MM::AtomType.new(
        "HA",
        Chem::PeriodicTable::H,
        mass: 1.008,
        lj: MM::LennardJones.new(-0.022, 2.64, 0, "ALLOW PEP ALI POL SUL ARO PRO ALC"),
        comment: "nonpolar H")
      params << MM::AtomType.new(
        "H",
        Chem::PeriodicTable::H,
        mass: 1.008,
        lj: MM::LennardJones.new(-0.046, 0.449, 0, "ALLOW PEP POL SUL ARO ALC"),
        comment: "polar H")
      params << MM::AtomType.new(
        "CP1",
        Chem::PeriodicTable::C,
        mass: 12.011,
        lj: MM::LennardJones.new(-0.02, 4.55),
        lj14: MM::LennardJones.new(-0.01, 3.8),
        comment: "tetrahedral C (proline CA)")
      params << MM::BondType.new({"C", "CP1"}, 250.0, 1.49, 264.5, "ALLOW PRO")
      params << MM::AngleType.new({"C", "CP1", "H"}, 50, 111)
      params << MM::DihedralType.new({nil, "CP1", "CP1", nil}, [MM::Phase.new(3.625, 2, 180)])
      params << MM::DihedralType.new({"C", "CP1", "H", "C"}, [
        MM::Phase.new(0.65, 1, 0),
        MM::Phase.new(-0.1, 2, 180),
        MM::Phase.new(0.1, 3, 0),
      ])
      params << MM::ImproperType.new({"C", "CP1", "C", "H"}, 1.1, 180)

      io = IO::Memory.new
      MM::CHARMM.write_parameters(io, params)
      io.to_s.should eq <<-PRM
        ATOMS
        MASS     1 C       12.01100 ! carbonyl C, peptide backbone
        MASS     2 CP1     12.01100 ! tetrahedral C (proline CA)
        MASS     3 H        1.00800 ! polar H
        MASS     4 HA       1.00800 ! nonpolar H

        BONDS
        C     CP1    250.00    1.4900 ! ALLOW PRO penalty= 264.5

        ANGLES
        C     CP1   H       50.00  111.00

        DIHEDRALS
        X     CP1   CP1   X          3.6250 2  180.00
        C     CP1   H     C          0.6500 1    0.00
        C     CP1   H     C         -0.1000 2  180.00
        C     CP1   H     C          0.1000 3    0.00

        IMPROPERS
        C     CP1   C     H          1.1000 0  180.00

        NONBONDED nbxmod  5 atom cdiel shift vatom vdistance vswitch -
        cutnb 14.0 ctofnb 12.0 ctonnb 10.0 eps 1.0 e14fac 1.0 wmin 1.5

        C       0.00 -0.110000      2.000000 ! ALLOW   PEP POL ARO penalty=  65.2
        CP1     0.00 -0.020000      2.275000  0.00 -0.010000      1.900000
        H       0.00 -0.046000      0.224500 ! ALLOW PEP POL SUL ARO ALC
        HA      0.00 -0.022000      1.320000 ! ALLOW PEP ALI POL SUL ARO PRO ALC

        END

        PRM
    end
  end
end
