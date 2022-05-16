module MM
  record LennardJones, epsilon : Float64, rmin : Float64, comment : String?

  abstract struct ParameterType(*T)
    getter force_constant : Float64
    getter eq_value : Float64
    getter penalty : Float64 = 0.0
    getter comment : String?
    getter typenames : Tuple(*T)

    def initialize(
      @typenames : Tuple(*T),
      @force_constant : Float64,
      @eq_value : Float64,
      @penalty : Float64 = 0.0,
      @comment : String? = nil
    )
    end

    # Returns a copy but changing the given values.
    def copy_with(
      typenames : Tuple(*T) = @typenames,
      force_constant : Float64 = @force_constant,
      eq_value : Float64 = @eq_value,
      penalty : Float64 = @penalty,
      comment : String? = @comment
    )
      self.class.new typenames, force_constant, eq_value, penalty, comment
    end
  end

  struct BondType < ParameterType(String, String)
  end

  struct AngleType < ParameterType(String, String, String)
  end

  struct DihedralType < ParameterType(String?, String, String, String?)
    getter multiplicity : Int32

    def initialize(
      @typenames : Tuple(String?, String, String, String?),
      @multiplicity : Int32,
      @force_constant : Float64,
      @eq_value : Float64,
      @penalty : Float64 = 0.0,
      @comment : String? = nil
    )
    end

    def copy_with(
      typenames : Tuple(*T) = @typenames,
      multiplicity : Int32 = @multiplicity,
      force_constant : Float64 = @force_constant,
      eq_value : Float64 = @eq_value,
      penalty : Float64 = @penalty,
      comment : String? = @comment
    ) : self
      self.class.new typenames, multiplicity, force_constant, eq_value, penalty, comment
    end
  end

  struct ImproperType < ParameterType(String, String?, String?, String)
  end
end
