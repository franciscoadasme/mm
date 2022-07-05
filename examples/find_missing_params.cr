require "../src/mm"

params = MM::ParameterSet.from_charmm(
  "spec/data/top_opls_aam_M.inp",
  "spec/data/par_opls_aam_M.inp")
topology = Chem::Topology.read "spec/data/5yok_initial.psf"

missing_params = MM::ParameterSet.new
conns = params.detect_missing(topology)
conns.each do |conn|
  case {param = MM.prompt_matching_param(params, conn), conn}
  when {MM::BondType, Chem::Bond}
    missing_params << param.copy_with(typenames: conn.atoms.map(&.typename.not_nil!))
  when {MM::AngleType, Chem::Angle}
    missing_params << param.copy_with(typenames: conn.atoms.map(&.typename.not_nil!))
  when {Enumerable(MM::DihedralType), Chem::Dihedral}
    missing_params << param.map(&.copy_with(typenames: conn.atoms.map(&.typename.not_nil!)))
  when {MM::ImproperType, Chem::Improper}
    missing_params << param.copy_with(typenames: conn.atoms.map(&.typename.not_nil!))
  end
end

p! missing_params.angles.size
p! missing_params.dihedrals.size
