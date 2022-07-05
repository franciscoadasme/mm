class MM::ParameterSet
  alias C = Chem::Bond | Chem::Angle | Chem::Dihedral | Chem::Improper

  @angles = {} of {String, String, String} => AngleType
  @atoms = {} of String => AtomType
  @bonds = {} of {String, String} => BondType
  @dihedrals = {} of {String?, String, String, String?} => Array(DihedralType)
  @impropers = {} of {String, String?, String?, String} => ImproperType
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

  {% for name in %w(angle atom bond dihedral improper patch residue) %}
    {% plural_name = (name == "patch" ? "patches" : "#{name.id}s") %}
    {% type = (name == "patch" ? "Patch" : "#{name.camelcase.id}Type") %}
    {% key = %w(atom patch residue).includes?(name) ? "name" : "typenames" %}
    {% return_type = name == "dihedral" ? "Array::View(#{type.id})" : type %}

    def {{plural_name.id}} : Array::View
      @{{plural_name.id}}.values.uniq!.view
    end

    {% if %w(angle bond dihedral improper).includes?(name) %}
      def <<({{name.id}}_t : {{type.id}}) : self
        {{name.id}}_t.each_typename_permutation do |typenames|
          @{{plural_name.id}}[typenames] = {{name.id}}_t
        end
        self
      end

      # Returns the {{name.id}} parameter type associated with *{{name.id}}*.
      # Raises `KeyError` if the parameter does not exists.
      #
      # It uses the typenames of the involved atoms as key to fetch the
      # parameter type. Raises `ArgumentError` if any atom does not have a
      # assigned type (`nil`).
      def []({{name.id}} : Chem::{{name.id.camelcase}}) : {{return_type.id}}
        self[{{name.id}}]? || raise KeyError.new("Missing parameter for #{{{name.id}}}")
      end

      # Returns the {{name.id}} parameter type associated with *{{name.id}}* if
      # exists, else `nil`.
      #
      # It uses the typenames of the involved atoms as key to fetch the
      # parameter type. Raises `ArgumentError` if any atom does not have a
      # assigned type (`nil`).
      def []?({{name.id}} : Chem::{{name.id.camelcase}}) : {{return_type.id}}?
        typenames = {{name.id}}.atoms.map { |atom|
          atom.typename || raise ArgumentError.new("#{atom} has no type")
        }
        {{name.id}}? typenames
      end

      def fuzzy_search({{name.id}} : Chem::{{name.id.camelcase}}) : Array({{return_type.id}})
        pattern = {{name.id}}.atoms.map do |atom|
          typename = atom.typename || raise ArgumentError.new("#{atom} has no type")
          atom_type = atom?(typename) || raise KeyError.new("Unknown atom type #{typename}")
          resname = atom.residue.name
          restype = residue?(resname) || raise KeyError.new("Unknown residue type #{resname}")
          if typename == restype.atoms[atom.name]?.try(&.typename)
            typename
          else # atom was changed or added by a patch
            atom_type.element
          end
        end

        {{name.id}}_types = Set({{return_type.id}}).new
        @{{plural_name.id}}.each_value do |{{name.id}}_t|
          matches = {{name.id}}_t{% if name == "dihedral" %}[0]{% end %}.typename_permutations.any? do |typenames|
            typenames.zip(pattern).all? { |typename, atom_pattern|
              if atom_type = typename.try { |typename| atom?(typename) }
                atom_type.matches?(atom_pattern)
              else # nil signals any atom (wildcard)
                true
              end
            }
          end
          {{name.id}}_types << {{name.id}}_t{% if name == "dihedral" %}.view{% end %} if matches
        end
        {{name.id}}_types.to_a.sort!
      end
    {% else %}
      def <<({{name.id}} : {{type.id}}) : self
        @{{plural_name.id}}[{{name.id}}.name] = {{name.id}}
        self
      end
    {% end %}
  {% end %}

  def <<(dihedral_t : DihedralType) : self
    dihedral_t.each_typename_permutation do |typenames|
      @dihedrals[typenames] ||= [] of DihedralType
      @dihedrals[typenames] << dihedral_t unless dihedral_t.in?(@dihedrals[typenames])
    end
    self
  end

  def <<(dihedral_types : Indexable(DihedralType)) : self
    size = dihedral_types.size
    dihedral_types[0].each_typename_permutation do |typenames|
      @dihedrals[typenames] ||= [] of DihedralType
      dihedral_types.each(within: ...size) do |dihedral_t|
        @dihedrals[typenames] << dihedral_t
      end
    end
    self
  end

  def angle?(typenames : {String, String, String}) : AngleType?
    @angles[typenames]?
  end

  def atom?(name : String) : AtomType?
    @atoms[name.upcase]?
  end

  def bond?(typenames : {String, String}) : BondType?
    @bonds[typenames]?
  end

  def detect_missing(top : Chem::Topology) : Array(C)
    missing_params = {} of String => C
    {% for name in %w(bond angle dihedral improper) %}
      top.{{name.id}}s.each do |{{name.id}}|
        next if self[{{name.id}}]?
        key = {{name.id}}.atoms.join('-', &.typename)
        missing_params[key] ||= {{name.id}}
      end
    {% end %}
    missing_params.values
  end

  def dihedral?(typenames : {String, String, String, String}) : Array::View(DihedralType)?
    if dihedral_t = @dihedrals[typenames]?
      dihedral_t.view
    else
      typenames = {nil, typenames[1], typenames[2], nil}
      @dihedrals.each do |key, dihedral_t|
        return dihedral_t.view if key == typenames
      end
    end
  end

  def dihedral?(typenames : {Nil, String, String, Nil}) : Array::View(DihedralType)?
    @dihedrals[typenames]?.try &.view
  end

  def dihedrals : Array::View(Array::View(DihedralType))
    @dihedrals.values.uniq!.map(&.view).view
  end

  def improper?(typenames : {String, String, String, String}) : ImproperType?
    if improper_t = @impropers[typenames]?
      improper_t
    else
      typenames = {typenames[0], nil, nil, typenames[3]}
      @impropers.each do |key, improper_t|
        return improper_t if key == typenames
      end
    end
  end

  def patch?(name : String) : Patch?
    @patches[name.upcase]?
  end

  def residue?(name : String) : ResidueType?
    @residues[name.upcase]?
  end

  def to_prm(output : IO | Path | String) : Nil
    CHARMM.write_parameters(output, self)
  end
end
