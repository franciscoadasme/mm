require "../src/mm"

params = MM::ParameterSet.from_charmm(
  "spec/data/top_opls_aam_M.inp",
  "spec/data/par_opls_aam_M.inp")
topology = Chem::Topology.read "spec/data/5yok_initial.psf"

missing_params = MM::ParameterSet.new
puts typeof(params.detect_missing(topology))
conns = params.detect_missing(topology)
conns.each do |conn|
  if param = MM.prompt_matching_param(params, conn)
    missing_params << param
  end
end

pp missing_params
