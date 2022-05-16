module MM
  {% for type in %w(bond angle dihedral improper).map(&.id) %}
    {% return_type = type == "dihedral" ? Array(DihedralType) : "#{type.camelcase}Type".id %}
    def self.prompt_matching_param(
      params : ParameterSet, 
      conn : Chem::{{type.camelcase}}
    ) : {{return_type}}?
      conn_type = conn.class.name.underscore.split('_')[0]
      typenames = conn.atoms.join('-', &.type)
      puts "Missing #{conn_type} between #{conn.atoms.join('-')} [#{typenames}]"

      matching_params = params.fuzzy_search(conn)
      case matching_params.size
      when 0
        puts "No matching paramater found"
        prompt_exit
      when 1
        puts "Found match #{matching_params.first_key.join('-')}"
        matching_params.first_value
      else
        prompt_match(matching_params)
      end
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

private def prompt_match(params : Hash(K, V)) : V forall K, V
  puts "Found matches:"
  params.keys.each_with_index(offset: 1) do |typenames, i|
    puts "  #{i}. #{typenames.join('-')}"
  end

  selected_i = nil
  until selected_i && selected_i.in?(0...params.size)
    print "Enter the best option: "
    selected_i = gets.try(&.to_i?) || puts "error: Invalid option"
  end
  params[selected_i]
end
