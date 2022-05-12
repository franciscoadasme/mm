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

  {% for type in %w(bond angle dihedral improper).map(&.id) %}
    # Returns the {{type}} parameter type associated with *{{type}}*.
    # Raises `KeyError` if the parameter does not exists.
    #
    # It uses the typenames of the involved atoms as key to fetch the
    # parameter type. Raises `ArgumentError` if any atom does not have a
    # assigned type (`nil`).
    def [](
      {{type}} : Chem::{{type.camelcase}}
    ) : {% if type == "dihedral" %}Array(DihedralType){% else %}{{type.camelcase}}Type{% end %}
      self[{{type}}]? || raise KeyError.new("Missing parameter for #{{{type}}}")
    end

    # Returns the {{type}} parameter type associated with *{{type}}* if
    # exists, else `nil`
    #
    # It uses the typenames of the involved atoms as key to fetch the
    # parameter type. Raises `ArgumentError` if any atom does not have a
    # assigned type (`nil`).
    def []?(
      {{type}} : Chem::{{type.camelcase}}
    ) : {% if type == "dihedral" %}Array(DihedralType)?{% else %}{{type.camelcase}}Type?{% end %}
      typenames = {{type}}.atoms.map { |atom|
        atom.type || raise ArgumentError.new("#{atom} has no type")
      }
      {{type}}s[typenames]?
    end
  {% end %}

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
    a, b, c, d = typenames
    {a, c, d}.each_permutation(reuse: true) do |(a, c, d)|
      @impropers[{a, b, c, d}] = improper if a && d
    end
    improper
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
  end

  def atoms : Hash::View(String, AtomType)
    @atoms.view
  end

  def bonds : Hash::View(BondKey, BondType)
    @bonds.view
  end

  def dihedrals : DihedralHashView
    DihedralHashView.new(@dihedrals)
  end

  def impropers : ImproperHashView
    ImproperHashView.new(@impropers)
  end

  def patches : Hash::View(String, Patch)
    @patches.view
  end

  def residues : Hash::View(String, ResidueType)
    @residues.view
  end


struct MM::DihedralHashView
  alias K = {String?, String, String, String?}
  alias V = Array(DihedralType)

  include Hash::Wrapper(K, V)

  def [](key : K) : V?
    fetch(key) { raise KeyError.new("Missing dihedral angle between #{key.join(' ')}") }
  end

  def []?(key : K) : V?
    fetch(key, nil)
  end

  def fetch(key : K, default : T) : V | T forall T
    fetch(key) { default }
  end

  def fetch(key : K, & : K -> T) : V | T forall T
    @wrapped[key]? || @wrapped[{nil, key[1], key[2], nil}]? || yield key
  end
end

struct MM::ImproperHashView
  alias K = {String, String?, String?, String}
  alias V = ImproperType

  include Hash::Wrapper(K, V)

  def [](key : K) : V?
    fetch(key) { raise KeyError.new("Missing improper dihedral angle between #{key.join(' ')}") }
  end

  def []?(key : K) : V?
    fetch(key, nil)
  end

  def fetch(key : K, default : T) : V | T forall T
    fetch(key) { default }
  end

  def fetch(key : K, & : K -> T) : V | T forall T
    @wrapped[key]? || @wrapped[{key[0], nil, nil, key[3]}]? || yield key
  end
end
