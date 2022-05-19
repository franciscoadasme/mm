module MM
  {% for type in %w(bond angle dihedral improper).map(&.id) %}
    {% return_type = type == "dihedral" ? Array(DihedralType) : "#{type.camelcase}Type".id %}
    def self.prompt_matching_param(
      params : ParameterSet,
      conn : Chem::{{type.camelcase}}
    ) : {{return_type}}?
      printf "Missing %s between %s [%s]\n",
        conn.class.name.split("::").last.underscore.split('_').first,
        conn.atoms.join(", "),
        conn.atoms.join('-', &.type),

      matching_params = params.fuzzy_search(conn)
      case matching_params.size
      when 0
        puts "No matching paramater found"
        prompt_exit
      when 1
        param = matching_params[0]
        param = param[0] if param.is_a?(Array)
        puts "Found match #{param.typenames.join('-')}"
        matching_params[0]
      else
        prompt_match(matching_params)
      end
      puts
    end
  {% end %}
end

private def prompt_exit : Nil
  loop do
    print "Enter either (c)ontinue or (e)xit [c]: "
    case gets
    when "e", "exit"
      abort
    when Nil, "c", "continue"
      return
    else
      puts "error: Invalid option"
    end
  end
end

private def prompt_match(params : Array(V)) : V forall V
  puts "Found matches:"
  params.each_with_index(offset: 1) do |param, i|
    param = param.is_a?(Array) ? param[0] : param
    puts "  #{i}. #{param.typenames.join('-')}"
  end

  selected_i = nil
  until selected_i && selected_i.in?(0...params.size)
    print "Enter the best option: "
    selected_i = gets.try(&.to_i?) || puts "error: Invalid option"
  end
  params[selected_i]
end
