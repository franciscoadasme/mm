class MM::ParameterSet
  alias BondKey = {String, String}
  alias AngleKey = {String, String, String}
  alias DihedralKey = {String?, String, String, String?}
  alias ImproperKey = {String, String?, String?, String}
  alias C = Chem::Bond | Chem::Angle | Chem::Dihedral | Chem::Improper

  @angles = [] of AngleType
  @atoms = [] of AtomType
  @bonds = [] of BondType
  @dihedrals = [] of Array(DihedralType)
  @impropers = [] of ImproperType
  @patches = [] of Patch
  @residues = [] of ResidueType

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

  {% for name in %w(angle atom bond improper patch residue).map(&.id) %}
    {% type = (name == "patch" ? "Patch" : "#{name.camelcase}Type").id %}
    {% plural_name = (name == "patch" ? "patches" : "#{name}s").id %}

    def <<({{name}}_t : {{type}}) : self
      if i = index({{name}}_t)
        @{{plural_name}}[i] = {{name}}_t
      else
        @{{plural_name}} << {{name}}_t
      end
      self
    end

    def index({{name}}_t : {{type}}) : Int32?
      @{{plural_name}}.index &.===({{name}}_t)
    end
  {% end %}

  def <<(dihedral_t : DihedralType) : self
    if i = index(dihedral_t)
      @dihedrals[i] << dihedral_t
    else
      @dihedrals << [dihedral_t]
    end
    self
  end

  def <<(dihedral_types : Array(DihedralType)) : self
    if i = index(dihedral_types)
      @dihedrals[i] = dihedral_t
    else
      @dihedrals << dihedral_t
    end
    self
  end

  {% for type in %w(bond angle dihedral improper).map(&.id) %}
    {% return_type = "#{type.camelcase}Type".id %}
    {% return_type = "Array(#{return_type})" if type == "dihedral" %}

    # Returns the {{type}} parameter type associated with *{{type}}*.
    # Raises `KeyError` if the parameter does not exists.
    #
    # It uses the typenames of the involved atoms as key to fetch the
    # parameter type. Raises `ArgumentError` if any atom does not have a
    # assigned type (`nil`).
    def []({{type}} : Chem::{{type.camelcase}}) : {{return_type.id}}
      self[{{type}}]? || raise KeyError.new("Missing parameter for #{{{type}}}")
    end

    # Returns the {{type}} parameter type associated with *{{type}}* if
    # exists, else `nil`
    #
    # It uses the typenames of the involved atoms as key to fetch the
    # parameter type. Raises `ArgumentError` if any atom does not have a
    # assigned type (`nil`).
    def []?({{type}} : Chem::{{type.camelcase}}) : {{return_type.id}}?
      typenames = {{type}}.atoms.map { |atom|
        atom.type || raise ArgumentError.new("#{atom} has no type")
      }
      {{type}}? typenames
    end
  {% end %}

  def angle?(typenames : {String, String, String}) : AngleType?
    @angles.find &.===(typenames)
  end

  def angles : Array::View(AngleType)
    @angles.view
  end

  def atom?(name : String) : AtomType?
    @atoms.find &.name.==(name.upcase)
  end

  def atoms : Array::View(AtomType)
    @atoms.view
  end

  def bond?(typenames : {String, String}) : BondType?
    @bonds.find &.===(typenames)
  end

  def bonds : Array::View(BondType)
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

  def dihedral?(typenames : {String?, String, String, String?}) : Array(DihedralType)?
    @dihedrals.find &.first.===(typenames)
  end

  def dihedrals : Array::View(Array(DihedralType))
    @dihedrals.view
  end

  def improper?(typenames : {String, String?, String?, String}) : ImproperType?
    @impropers.find &.===(typenames)
  end

  def impropers : Array::View(ImproperType)
    @impropers.view
  end

  def index(dihedral_t : DihedralType) : Int32?
    @dihedrals.index &.first.===(dihedral_t)
  end

  def index(dihedral_types : Array(DihedralType)) : Int32?
    if dihedrals.map(&.typenames).uniq!
      raise ArgumentError.new("Dihedrals have different atom types")
    end
    index dihedral_types.first
  end

  def patch?(name : String) : Patch?
    @patches.find &.name.==(name.upcase)
  end

  def patches : Array::View(Patch)
    @patches.view
  end

  def residue?(name : String) : ResidueType?
    @residues.find &.name.==(name.upcase)
  end

  def residues : Array::View(ResidueType)
    @residues.view
  end

  {% for type in %w(bond angle dihedral improper).map(&.id) %}
    {% return_type = type == "dihedral" ? Array(DihedralType) : "#{type.camelcase}Type".id %}
    def fuzzy_search(
      {{type}} : Chem::{{type.camelcase}}
    ) : Array({{return_type}})
      pattern = {{type}}.atoms.map do |atom|
        typename = atom.type || raise ArgumentError.new("#{atom} has no type")
        atom_type = atom?(typename) || raise KeyError.new("Unknown atom type #{typename}")
        resname = atom.residue.name
        restype = residue?(resname) || raise KeyError.new("Unknown residue type #{resname}")
        if typename == restype.atoms[atom.name]?.try(&.typename)
          typename
        else # atom was changed or added by a patch
          atom_type.element
        end
      end

      @{{type}}s.select do |{{type}}|
        {{type}}{% if type == "dihedral" %}[0]{% end %}.typenames.zip(pattern).all? { |typename, atom_pattern|
          if atom_type = typename.try { |typename| atom?(typename) }
            atom_type.matches?(atom_pattern)
          else # nil signals any atom (wildcard)
            true
          end
        }
      end
    end
  {% end %}
end
