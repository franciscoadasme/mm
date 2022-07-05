module MM
  record LennardJones,
    epsilon : Float64,
    rmin : Float64,
    penalty : Float64 = 0.0,
    comment : String? = nil

  record Phase, force_constant : Float64, multiplicity : Int32, eq_value : Float64

  abstract struct ParameterType(*T)
    getter penalty : Float64 = 0.0
    getter comment : String?
    getter typenames : Tuple(*T)

    def initialize(
      @typenames : Tuple(*T),
      @penalty : Float64 = 0.0,
      @comment : String? = nil
    )
    end

    def <=>(rhs : self) : Int32
      @typenames.map { |name| name || " " } <=> rhs.typenames.map { |name| name || " " }
    end

    def ==(typenames : Tuple(*T)) : Bool
      each_typename_permutation do |comb|
        return true if comb == typenames
      end
      false
    end

    def ===(rhs : self) : Bool
      self === rhs.typenames
    end

    def ===(typenames : Tuple(*T)) : Bool
      self == typenames
    end

    # Returns a copy but changing the given values.
    def copy_with(typenames : Tuple(*T)) : self
      self.class.new typenames, @penalty, @comment
    end

    def each_typename_permutation(& : Tuple(*T) ->) : Nil
      yield @typenames
      yield @typenames.reverse
    end

    def typename_permutations : Array(Tuple(*T))
      Array(Tuple(*T)).new.tap do |permutations|
        each_typename_permutation do |permutation|
          permutations << permutation
        end
      end
    end
  end

  abstract struct SimpleParameterType(*T) < ParameterType(*T)
    getter force_constant : Float64
    getter eq_value : Float64

    def initialize(
      @typenames : Tuple(*T),
      @force_constant : Float64,
      @eq_value : Float64,
      @penalty : Float64 = 0.0,
      @comment : String? = nil
    )
    end

    def ==(rhs : self) : Bool
      self == rhs.typenames &&
        @force_constant == rhs.force_constant &&
        @eq_value == rhs.eq_value
    end

    # Returns a copy but changing the given values.
    def copy_with(typenames : Tuple(*T))
      self.class.new typenames, @force_constant, @eq_value, @penalty, @comment
    end
  end

  struct BondType < SimpleParameterType(String, String)
  end

  struct AngleType < SimpleParameterType(String, String, String)
  end

  struct DihedralType < ParameterType(String?, String, String, String?)
    def initialize(
      @typenames : Tuple(String?, String, String, String?),
      @phases : Array(Phase),
      @penalty : Float64 = 0.0,
      @comment : String? = nil
    )
    end

    def ==(rhs : self) : Bool
      self == rhs.typenames && rhs.phases.equals?(@phases) { |x, y| x == y }
    end

    def ===(typenames : Tuple(String?, String, String, String?)) : Bool
      if {Nil, String, String, Nil} === typenames ||
         {Nil, String, String, Nil} === @typenames
        typenames[1..2].in?(@typenames[1..2], @typenames[1..2].reverse)
      else
        super
      end
    end

    def copy_with(typenames : Tuple(*T)) : self
      self.class.new typenames, @phases.dup, @penalty, @comment
    end

    def phases : Array::View(Phase)
      @phases.view
    end
  end

  struct ImproperType < SimpleParameterType(String, String?, String?, String)
    def ==(typenames : Tuple(String, String?, String?, String)) : Bool
      @typenames == typenames
    end

    def ===(typenames : Tuple(String, String?, String?, String)) : Bool
      if {String, Nil, Nil, String} === typenames ||
         {String, Nil, Nil, String} === @typenames
        {@typenames[0], @typenames[3]} == {typenames[0], typenames[3]}
      else
        each_typename_permutation do |other|
          return true if other == typenames
        end
        false
      end
    end

    def each_typename_permutation(& : {String, String?, String?, String} ->) : Nil
      a, b, c, d = @typenames
      {a, c, d}.each_permutation(reuse: true) do |(a, c, d)|
        yield({a, b, c, d}) if a && d
      end
    end
  end
end
