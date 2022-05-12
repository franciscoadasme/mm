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
      when ".par", ".prm"
        CHARMM.load_parameters(params, path)
      when ".inp"
        case path.basename
        when .includes?("top")
          CHARMM.load_topology(params, path)
        when .includes?("par")
          CHARMM.load_parameters(params, path)
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

  def angles : Hash::View(AngleKey, AngleType)
    @angles.view
  def atoms : Hash::View(String, AtomType)
    @atoms.view
  def bonds : Hash::View(BondKey, BondType)
    @bonds.view
  end

  end

  def patches : Hash::View(String, Patch)
    @patches.view
  end

  def dihedrals : HashView(DihedralKey, Array(DihedralType))
    HashView.new @dihedrals
  def residues : Hash::View(String, ResidueType)
    @residues.view
  end

  def impropers : HashView(ImproperKey, ImproperType)
    HashView.new @impropers
  end

  end

  end
end
