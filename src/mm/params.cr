module MM
  module ParameterType

    end
  end

  record BondType,
    force_constant : Float64,
    eq_value : Float64 do
    include ParameterType
    alias Key = {String, String}
  end

  record AngleType,
    force_constant : Float64,
    eq_value : Float64 do
    include ParameterType
    alias Key = {String, String, String}
  end

  record DihedralType,
    multiplicity : Int32,
    force_constant : Float64,
    phase : Float64 do
    include ParameterType
    alias Key = {String, String, String, String}
  end

  record ImproperType,
    force_constant : Float64,
    eq_value : Float64 do
    include ParameterType
    alias Key = {String, String, String, String}
  end
end
