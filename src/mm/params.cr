module MM
  module ParameterType
    abstract def atom_types : Indexable(AtomType)

    def to_s(io : IO) : Nil
      atom_types.join('-', &.name)
    end

    def typenames : Indexable(String)
      atom_types.map(&.name)
    end
  end

  record BondType,
    atom_types : {AtomType, AtomType},
    force_constant : Float64,
    eq_value : Float64 do
    include ParameterType
    alias Key = {String, String}
  end

  record AngleType,
    atom_types : {AtomType, AtomType, AtomType},
    force_constant : Float64,
    eq_value : Float64 do
    include ParameterType
    alias Key = {String, String, String}
  end

  record DihedralType,
    atom_types : {AtomType, AtomType, AtomType, AtomType},
    multiplicity : Int32,
    force_constant : Float64,
    phase : Float64 do
    include ParameterType
    alias Key = {String, String, String, String}
  end

  record ImproperType,
    atom_types : {AtomType, AtomType, AtomType, AtomType},
    force_constant : Float64,
    eq_value : Float64 do
    include ParameterType
    alias Key = {String, String, String, String}
  end
end
