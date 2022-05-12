module MM::CHARMM
  PARAM_PENALTY_REGEX = /\s*penalty\s*=\s*([\d\.]+)/i
  WILDCARD_TYPE_NAME  = "X"

  def self.load_parameters(params : ParameterSet, parfile : Path | String) : Nil
    File.open(parfile) do |io|
      section = nil
      line = io.gets
      while line
        content, _, comment = line.partition(/\s*[!\*]\s*/)
        tokens = content.split
        comment = comment.presence
        if comment && comment =~ PARAM_PENALTY_REGEX
          penalty = $1.to_f? || raise "Invalid penalty"
          comment = comment.gsub PARAM_PENALTY_REGEX, ""
        else
          penalty = 0.0
        end

        case {section, tokens[0]?.try(&.upcase)}
        when {_, Nil}
          # comment line, do nothing
        when {_, "ATOM"}
          section = "atoms"
        when {_, "BOND"}
          section = "bonds"
        when {_, "ANGLE"}, {_, "THETA"}
          section = "angles"
        when {_, "DIHEDRAL"}, {_, "PHI"}
          section = "dihedrals"
        when {_, "IMPROPER"}, {_, "IMPHI"}
          section = "impropers"
        when {_, "NONBONDED"}
          section = "nonbonded"
        when {_, "CMAP"}, {_, "NBFIX"}, {_, "HBOND"}, {_, "THOLE"}, {_, "END"}
          section = nil
        when {"atoms", "MASS"}
          name = tokens[2]
          mass = tokens[3].to_f? || raise "Invalid mass"
          element = tokens[4].try { |sym| Chem::PeriodicTable[sym] }
          # Use element with the closest mass if missing
          element ||= Chem::PeriodicTable.elements.min_by &.mass.-(mass).abs
          params << AtomType.new(name, element, mass, comment: comment)
        when {"bonds", _}
          type1 = tokens[0].upcase
          type2 = tokens[1].upcase
          force_constant = tokens[2].to_f? || raise "Invalid force constant"
          eq_value = tokens[3].to_f? || raise "Invalid equilibrium value"
          new_type = BondType.new force_constant, eq_value, penalty, comment
          params[{type1, type2}] = new_type
        when {"angles", _}
          type1 = tokens[0].upcase
          type2 = tokens[1].upcase
          type3 = tokens[2].upcase
          force_constant = tokens[3].to_f? || raise "Invalid force constant"
          eq_value = tokens[4].to_f? || raise "Invalid equilibrium value"
          new_type = AngleType.new force_constant, eq_value, penalty, comment
          params[{type1, type2, type3}] = new_type
        when {"dihedrals", _}
          type1 = tokens[0].upcase
          type1 = nil if type1 == WILDCARD_TYPE_NAME
          type2 = tokens[1].upcase
          type3 = tokens[2].upcase
          type4 = tokens[3].upcase
          type4 = nil if type4 == WILDCARD_TYPE_NAME
          force_constant = tokens[4].to_f? || raise "Invalid force constant"
          multiplicity = tokens[5].to_i? || raise "Invalid multiplicity"
          eq_value = tokens[6].to_f? || raise "Invalid equilibrium value"
          new_type = DihedralType.new multiplicity, force_constant, eq_value, penalty, comment
          params[{type1, type2, type3, type4}] = new_type
        when {"impropers", _}
          type1 = tokens[0].upcase
          type2 = tokens[1].upcase
          type2 = nil if type2 == WILDCARD_TYPE_NAME
          type3 = tokens[2].upcase
          type3 = nil if type3 == WILDCARD_TYPE_NAME
          type4 = tokens[3].upcase
          force_constant = tokens[4].to_f? || raise "Invalid force constant"
          eq_value = tokens[6].to_f? || raise "Invalid equilibrium value"
          new_type = ImproperType.new force_constant, eq_value, penalty, comment
          params[{type1, type2, type3, type4}] = new_type
        when {"nonbonded", _}
          epsilon = tokens[2].to_f?
          rmin = tokens[3].to_f?.try &.*(2)
          if epsilon && rmin
            typename = tokens[0].upcase
            if (epsilon14 = tokens[5]?) && (rmin14 = tokens[6]?)
              epsilon14 = epsilon14.to_f? || raise "Invalid epsilon"
              rmin14 = rmin14.to_f?.try(&.*(2)) || raise "Invalid Rmin"
              if atom_type = params.atoms[typename]?
                atom_type.lj = LennardJones.new(epsilon, rmin, comment)
                atom_type.lj14 = LennardJones.new(epsilon14, rmin14, comment)
              else
                raise "Unknown atom type #{typename}"
              end
            end
          else # probably header
            # ignore for now
          end
        end
        line = io.gets
      end
    end
  end

  def self.load_topology(params : ParameterSet, topfile : Path | String) : Nil
    default_first_patch = default_last_patch = nil
    File.open(topfile) do |io|
      line = io.gets
      while line
        tokens = line.partition("!")[0].split
        case outer_key = tokens[0]?.try(&.upcase)
        when "MASS"
          name = tokens[2] || raise "Missing atom name"
          mass = tokens[3].to_f? || raise "Invalid mass"
          element = Chem::PeriodicTable[tokens[4]]
          comment = tokens[6..]?.try &.join(' ')
          params << AtomType.new(name, element, mass, comment: comment)
        when "DEFA"
          raise "Invalid DEFA record" unless tokens.size == 5
          tokens[1..].each_slice(2, reuse: true) do |(key, name)|
            name = nil if name.upcase == "NONE"
            case key[..3]
            when "FIRS" then default_first_patch = name
            when "LAST" then default_last_patch = name
            else             raise "Unknown key #{key} in DEFA record"
            end
          end
        when "RESI", "PRES"
          name = tokens[1].upcase
          atoms = {} of String => ResidueType::AtomRecord
          bonds = [] of ResidueType::BondRecord
          delete_atoms = [] of String
          first_patch = default_first_patch
          last_patch = default_last_patch
          link_bond = nil

          line = io.gets
          while line
            tokens = line.partition("!")[0].split
            case inner_key = tokens[0]?.try(&.upcase)
            when "ATOM"
              atom_name = tokens[1].upcase
              type_name = tokens[2].upcase
              charge = tokens[3].chomp('!').to_f? || raise "Invalid charge"
              atoms[atom_name] = ResidueType::AtomRecord.new(atom_name, type_name, charge)
            when "DELETE"
              next unless tokens[1].upcase == "ATOM"
              delete_atoms << tokens[2].upcase
            when "BOND", "DOUBLE"
              order = inner_key == "DOUBLE" ? 2 : 1
              tokens[1..].each_slice(2, reuse: true) do |(lhs, rhs)|
                case {lhs[0], rhs[0]}
                when {'-', _} then link_bond = ResidueType::BondRecord.new(lhs.lchop, rhs, order)
                when {'+', _} then link_bond = ResidueType::BondRecord.new(rhs, lhs.lchop, order)
                when {_, '-'} then link_bond = ResidueType::BondRecord.new(rhs.lchop, lhs, order)
                when {_, '+'} then link_bond = ResidueType::BondRecord.new(lhs, rhs.lchop, order)
                else               bonds << ResidueType::BondRecord.new(lhs, rhs, order)
                end
              end
            when "PATCH", "PATCHING"
              tokens[1..].each_slice(2, reuse: true) do |(key, name)|
                name = nil if name.upcase == "NONE"
                case key[..3]
                when "FIRS" then first_patch = name
                when "LAST" then last_patch = name
                else             raise "Unknown key #{key} in PATCH record"
                end
              end
            when "GROUP"
            when "CMAP"
            when "DONOR"
            when "ACCEPT"
            when "LONEPAIR"
            when "IC"
            when "IMPR", "IMPH"
            when "ANISOTROPY"
            when "RESI", "PRES", "MASS", "END"
              break
            end
            line = io.gets
          end

          case outer_key
          when "RESI" # residue
            params << ResidueType.new(name, atoms, bonds, link_bond, first_patch, last_patch)
          when "PRES" # patch
            params << Patch.new(name, atoms, bonds, delete_atoms)
          end

          next # skip reading another line at the end of the loop
        end
        line = io.gets
      end
    end
  end

  def self.read_parameters(parfile : Path | String) : ParameterSet
    ParameterSet.new.tap do |params|
      load_parameters params, parfile
    end
  end

  def self.read_topology(topfile : Path | String) : ParameterSet
    ParameterSet.new.tap do |params|
      load_topology params, topfile
    end
  end
end
