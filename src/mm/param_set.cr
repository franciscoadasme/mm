class MM::ParameterSet
  getter atom_types = {} of String => AtomType
  getter bond_types = {} of BondType::Key => BondType
  getter angle_types = {} of AngleType::Key => AngleType
  getter dihedral_types = {} of DihedralType::Key => Array(DihedralType)
  getter improper_types = {} of ImproperType::Key => ImproperType
  getter residues = {} of String => ResidueType
  getter patches = {} of String => Patch

  def self.from_charmm(*paths : Path | String) : self
    params = new
    paths.each do |path|
      case (path = Path.new(path)).extension
      when ".rtf", ".top"
        CHARMM.load_topology(params, path)
      when ".inp"
        case path.basename
        when .includes?("top")
          CHARMM.load_topology(params, path)
        else
          raise ArgumentError.new("Unrecognized file type: #{path}")
        end
      else
        raise ArgumentError.new("Unrecognized file type: #{path}")
      end
    end
    params
  end

  def <<(atom : AtomType) : self
    @atom_types[atom.name] = atom
    self
  end

  def <<(bond : BondType) : self
    @bond_types[bond.typenames] = bond
    self
  end

  def <<(angle : AngleType) : self
    @angle_types[angle.typenames] = angle
    self
  end

  def <<(dihedral : DihedralType) : self
    @dihedral_types[dihedral.typenames] = dihedral
    self
  end

  def <<(improper : ImproperType) : self
    @improper_types[improper.typenames] = improper
    self
  end

  def <<(restype : ResidueType) : self
    @residues[restype.name] = restype
    self
  end

  def <<(patch : Patch) : self
    @patches[patch.name] = patch
    self
  end
end
