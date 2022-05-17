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

    def ===(rhs : self) : Bool
      self === rhs.typenames
    end

    def ===(typenames : Tuple(*T)) : Bool
      typenames.in?(@typenames, @typenames.reverse)
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

    def ===(typenames : Tuple(String?, String, String, String?)) : Bool
      super || super({nil, typenames[1], typenames[2], nil})
    end
  end

  struct ImproperType < ParameterType(String, String?, String?, String)
    def ===(typenames : Tuple(String, String?, String?, String)) : Bool
      a, b, c, d = typenames
      {a, c, d}.each_permutation(reuse: true) do |(a, c, d)|
        return true if {a, b, c, d} == @typenames
      end
      false
    end
  end
end
