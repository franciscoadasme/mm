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
    self[atom.name] = atom
    self
  end

  def <<(restype : ResidueType) : self
    self[restype.name] = restype
    self
  end

  def <<(patch : Patch) : self
    self[patch.name] = patch
    self
  end

  def []=(typenames : BondKey, bond : BondType) : BondType
    @bonds[typenames] = @bonds[typenames.reverse] = bond
  end

  def []=(typenames : AngleKey, angle : AngleType) : AngleType
    @angles[typenames] = @angles[typenames.reverse] = angle
  end

  def []=(typenames : DihedralKey, dihedral : DihedralType) : DihedralType
    @dihedrals[typenames] << dihedral
    if (rtypenames = typenames.reverse) != typenames # avoid duplication
      @dihedrals[rtypenames] << dihedral
    end
    dihedral
  end

  def []=(typenames : ImproperKey, improper : ImproperType) : ImproperType
    @impropers[typenames] = @impropers[typenames.reverse] = improper
  end

  def []=(name : String, atom : AtomType) : AtomType
    @atoms[name] = atom
  end

  def []=(name : String, restype : ResidueType) : ResidueType
    @residues[name] = restype
  end

  def []=(name : String, patch : Patch) : Patch
    @patches[name] = patch
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
