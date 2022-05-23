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
          params << BondType.new({type1, type2}, force_constant, eq_value, penalty, comment)
        when {"angles", _}
          type1 = tokens[0].upcase
          type2 = tokens[1].upcase
          type3 = tokens[2].upcase
          force_constant = tokens[3].to_f? || raise "Invalid force constant"
          eq_value = tokens[4].to_f? || raise "Invalid equilibrium value"
          params << AngleType.new({type1, type2, type3}, force_constant, eq_value, penalty, comment)
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
          params << DihedralType.new({type1, type2, type3, type4}, multiplicity, force_constant, eq_value, penalty, comment)
        when {"impropers", _}
          type1 = tokens[0].upcase
          type2 = tokens[1].upcase
          type2 = nil if type2 == WILDCARD_TYPE_NAME
          type3 = tokens[2].upcase
          type3 = nil if type3 == WILDCARD_TYPE_NAME
          type4 = tokens[3].upcase
          force_constant = tokens[4].to_f? || raise "Invalid force constant"
          eq_value = tokens[6].to_f? || raise "Invalid equilibrium value"
          params << ImproperType.new({type1, type2, type3, type4}, force_constant, eq_value, penalty, comment)
        when {"nonbonded", _}
          epsilon = tokens[2].to_f?
          rmin = tokens[3].to_f?.try &.*(2)
          if epsilon && rmin
            typename = tokens[0].upcase
            if (epsilon14 = tokens[5]?) && (rmin14 = tokens[6]?)
              epsilon14 = epsilon14.to_f? || raise "Invalid epsilon"
              rmin14 = rmin14.to_f?.try(&.*(2)) || raise "Invalid Rmin"
              if atom_type = params.atom?(typename)
                atom_type.lj = LennardJones.new(epsilon, rmin, penalty, comment)
                atom_type.lj14 = LennardJones.new(epsilon14, rmin14, penalty, comment)
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

  def self.write_parameters(path : Path | String, params : ParameterSet) : Nil
    File.open(path, "w") do |io|
      write_prm(io, params)
    end
  end

  def self.write_parameters(io : IO, params : ParameterSet) : Nil
    io.puts "ATOMS"
    params.atoms.to_a.sort!.each_with_index(1) do |atom_t, i|
      io.printf "MASS %5d %-6s %9.5f",
        i, atom_t.name, atom_t.mass, atom_t.element.symbol
      io << " ! " << atom_t.comment if atom_t.comment
      io.puts
    end
    io.puts

    io.puts "BONDS"
    params.bonds.to_a.sort!.each do |bond_t|
      io.printf "%-6s%-6s%7.2f%10.4f",
        *bond_t.typenames, bond_t.force_constant, bond_t.eq_value
      write_parameter_comment io, bond_t
      io.puts
    end
    io.puts

    io.puts "ANGLES"
    params.angles.to_a.sort!.each do |angle_t|
      io.printf "%-6s%-6s%-6s%7.2f%8.2f",
        *angle_t.typenames, angle_t.force_constant, angle_t.eq_value
      write_parameter_comment io, angle_t
      io.puts
    end
    io.puts

    io.puts "DIHEDRALS"
    params.dihedrals.to_a.sort_by!(&.first).each do |dihedral_types|
      dihedral_types.each do |tor|
        io.printf "%-6s%-6s%-6s%-6s%11.4f%2d%8.2f",
          *tor.typenames.map { |x| x || 'X' }, tor.force_constant, tor.multiplicity, tor.eq_value
        write_parameter_comment io, tor
        io.puts
      end
    end
    io.puts

    io.puts "IMPROPERS"
    params.impropers.to_a.sort!.each do |improper_t|
      io.printf "%-6s%-6s%-6s%-6s%11.4f%2d%8.2f",
        *improper_t.typenames, improper_t.force_constant, 0, improper_t.eq_value
      write_parameter_comment io, improper_t
      io.puts
    end
    io.puts

    comb_rule = nil # " GEOM" if params.combining_rule.geometric?
    scee = 1.0
    io.puts "NONBONDED nbxmod  5 atom cdiel shift vatom vdistance vswitch -\n\
             cutnb 14.0 ctofnb 12.0 ctonnb 10.0 eps 1.0 e14fac #{1/scee} \
             wmin 1.5#{comb_rule}"
    io.puts
    params.atoms.each do |atom_t|
      next unless lj = atom_t.lj
      io.printf "%-6s%6.2f%10.6f%14.6f",
        atom_t.name, 0, lj.epsilon, lj.rmin * 0.5
      if lj14 = atom_t.lj14
        io.printf "%6.2f%10.6f%14.6f", 0, lj14.epsilon, lj14.rmin * 0.5
      end
      write_parameter_comment io, lj
      io.puts
    end
    io.puts

    io.puts "END"
  end

  private def self.write_parameter_comment(io, param)
    io << " !" if param.comment || param.penalty != 0.0
    param.comment.try { |comment| io << ' ' << comment }
    io.printf " penalty=%6.1f", param.penalty if param.penalty != 0.0
  end
end
