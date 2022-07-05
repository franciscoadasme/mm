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

  {% for name in %w(angle atom bond dihedral improper patch residue) %}
    {% plural_name = (name == "patch" ? "patches" : "#{name.id}s") %}
    {% type = (name == "patch" ? "Patch" : "#{name.camelcase.id}Type") %}
    {% key = %w(atom patch residue).includes?(name) ? "name" : "typenames" %}
    {% return_type = name == "dihedral" ? "Array::View(#{type.id})" : type %}

    def {{plural_name.id}} : Array::View({{return_type.id}})
      @{{plural_name.id}}.view
    end

    def <<({{name.id}}_t : {{type.id}}) : self
      if i = @{{plural_name.id}}.index(&.==({{name.id}}_t.{{key.id}}))
        @{{plural_name.id}}[i] = {{name.id}}_t
      else
        @{{plural_name.id}} << {{name.id}}_t
      end
      self
    end

    {% if %w(angle bond dihedral improper).includes?(name) %}
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

        @{{name.id}}s.select do |{{name.id}}|
          {{name.id}}{% if name == "dihedral" %}[0]{% end %}.typename_permutations.any? do |typenames|
            typenames.zip(pattern).all? { |typename, atom_pattern|
              if atom_type = typename.try { |typename| atom?(typename) }
                atom_type.matches?(atom_pattern)
              else # nil signals any atom (wildcard)
                true
              end
            }
          end
        end{% if name == "dihedral" %}.map(&.view){% end %}
      end
    {% end %}
  {% end %}

  def <<(dihedral_t : DihedralType) : self
    if i = @dihedrals.index(&.[0].==(dihedral_t.typenames))
      @dihedrals[i] << dihedral_t
    else
      @dihedrals << [dihedral_t]
    end
    self
  end

  def <<(dihedral_types : Enumerable(DihedralType)) : self
    if i = @dihedrals.index(&.[0].==(dihedral_types[0].typenames))
      @dihedrals[i] = dihedral_types.to_a
    else
      @dihedrals << dihedral_types.to_a
    end
    self
  end

  def angle?(typenames : {String, String, String}) : AngleType?
    @angles.find &.===(typenames)
  end

  def atom?(name : String) : AtomType?
    @atoms.find &.name.==(name.upcase)
  end

  def bond?(typenames : {String, String}) : BondType?
    @bonds.find &.===(typenames)
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

  def dihedral?(typenames : {String?, String, String, String?}) : Array::View(DihedralType)?
    @dihedrals.find(&.first.===(typenames)).try(&.view)
  end

  def dihedrals : Array::View(Array::View(DihedralType))
    @dihedrals.map(&.view).view
  end

  def improper?(typenames : {String, String?, String?, String}) : ImproperType?
    @impropers.find &.===(typenames)
  end

  def patch?(name : String) : Patch?
    @patches.find &.name.==(name.upcase)
  end

  def residue?(name : String) : ResidueType?
    @residues.find &.name.==(name.upcase)
  end

  def to_prm(output : IO | Path | String) : Nil
    CHARMM.write_parameters(output, self)
  end
end
