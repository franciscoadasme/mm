class MM::ParameterSet
  alias BondKey = {String, String}
  alias AngleKey = {String, String, String}
  alias DihedralKey = {String?, String, String, String?}
  alias ImproperKey = {String, String?, String?, String}

  @angles = {} of AngleKey => AngleType
  @atoms = {} of String => AtomType
  @bonds = {} of BondKey => BondType
  @dihedrals = Hash(DihedralKey, Array(DihedralType)).new do |hash, key|
    hash[key] = [] of DihedralType
  end
  @impropers = {} of ImproperKey => ImproperType
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

  def angles : HashView(AngleKey, AngleType)
    HashView.new @angles
  end

  def atoms : HashView(String, AtomType)
    HashView.new @atoms
  end

  def bonds : HashView(BondKey, BondType)
    HashView.new @bonds
  end

  def dihedrals : HashView(DihedralKey, Array(DihedralType))
    HashView.new @dihedrals
  end

  def impropers : HashView(ImproperKey, ImproperType)
    HashView.new @impropers
  end

  def patches : HashView(String, Patch)
    HashView.new @patches
  end

  def residues : HashView(String, ResidueType)
    HashView.new @residues
  end
end
