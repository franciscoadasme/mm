module MM
  record LennardJones, epsilon : Float64, rmin : Float64, comment : String?

  module ParameterType
    getter force_constant : Float64
    getter eq_value : Float64
    getter penalty : Float64 = 0.0
    getter comment : String?

    def initialize(
      @force_constant : Float64,
      @eq_value : Float64,
      @penalty : Float64 = 0.0,
      @comment : String? = nil
    )
    end
  end

  struct BondType
    include ParameterType
  end

  struct AngleType
    include ParameterType
  end

  struct DihedralType
    include ParameterType

    getter multiplicity : Int32

    def initialize(
      @multiplicity : Int32,
      @force_constant : Float64,
      @eq_value : Float64,
      @penalty : Float64 = 0.0,
      @comment : String? = nil
    )
    end
  end

  struct ImproperType
    include ParameterType
  end
end
