class MM::ParameterSet
  alias BondKey = {String, String}
  alias AngleKey = {String, String, String}
  alias DihedralKey = {String?, String, String, String?}
  alias ImproperKey = {String, String?, String?, String}
  alias C = Chem::Bond | Chem::Angle | Chem::Dihedral | Chem::Improper

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

  def detect_missing(top : Chem::Topology) : Array(C)
    missing_params = {} of String => C
    {% for name in %w(bond angle dihedral improper) %}
      top.{{name.id}}s.each do |{{name.id}}|
        next if self[{{name.id}}]?
        key = {{name.id}}.atoms.join('-', &.type)
        missing_params[key] ||= {{name.id}}
      end
    {% end %}
    missing_params.values
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

  {% for type in %w(bond angle dihedral improper).map(&.id) %}
    {% return_type = type == "dihedral" ? Array(DihedralType) : "#{type.camelcase}Type".id %}
    def fuzzy_search(
      {{type}} : Chem::{{type.camelcase}}
    ) : Hash({{type.camelcase}}Key, {{return_type}})
      pattern = {{type}}.atoms.map do |atom|
        typename = atom.type || raise ArgumentError.new("#{atom} has no type")
        atom_type = @atoms[typename]? || raise KeyError.new("Unknown atom type #{typename}")
        resname = atom.residue.name
        restype = @residues[resname]? || raise KeyError.new("Unknown residue type #{resname}")
        if typename == restype.atoms[atom.name]?.try(&.typename)
          typename
        else # atom was changed or added by a patch
          atom_type.element
        end
      end

      @{{type}}s.select do |typenames, {{type}}|
        typenames.zip(pattern).all? { |typename, atom_pattern|
          if atom_type = @atoms[typename]?
            atom_type.matches?(atom_pattern)
          else # nil signals any atom (wildcard)
            true
          end
        }
      end
    end
  {% end %}
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
