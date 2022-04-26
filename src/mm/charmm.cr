module MM::CHARMM
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
          atoms = [] of ResidueType::AtomRecord
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
              partial_charge = tokens[3].chomp('!').to_f? || raise "Invalid charge"
              atoms << ResidueType::AtomRecord.new(atom_name, type_name, partial_charge)
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

  def self.read_topology(topfile : Path | String) : ParameterSet
    ParameterSet.new.tap do |params|
      load_topology params, topfile
    end
  end
end
