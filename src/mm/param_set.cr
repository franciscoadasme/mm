class MM::ParameterSet
  @angle_types = {} of AngleType::Key => AngleType
  @atom_types = {} of String => AtomType
  @bond_types = {} of BondType::Key => BondType
  @dihedral_types = {} of DihedralType::Key => Array(DihedralType)
  @improper_types = {} of ImproperType::Key => ImproperType
  @patches = {} of String => Patch
  @residues = {} of String => ResidueType

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

  def angle_types : HashView(AngleType::Key, AngleType)
    HashView.new @angle_types
  end

  def atom_types : HashView(String, AtomType)
    HashView.new @atom_types
  end

  def bond_types : HashView(BondType::Key, BondType)
    HashView.new @bond_types
  end

  def dihedral_types : HashView(DihedralType::Key, DihedralType)
    HashView.new @dihedral_types
  end

  def improper_types : HashView(ImproperType::Key, ImproperType)
    HashView.new @improper_types
  end

  def patches : HashView(String, Patch)
    HashView.new @patches
  end

  def residues : HashView(String, ResidueType)
    HashView.new @residues
  end
end
