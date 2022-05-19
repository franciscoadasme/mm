class MM::AtomType
  getter comment : String?
  getter element : Chem::Element
  getter mass : Float64
  getter name : String
  property lj : LennardJones?
  property lj14 : LennardJones?

  def initialize(
    @name : String,
    @element : Chem::Element,
    @mass : Float64 = element.mass,
    @lj : LennardJones? = nil,
    @lj14 : LennardJones? = nil,
    @comment : String? = nil
  )
  end

  def <=>(rhs : self) : Int32
    @name <=> rhs.name
  end

  def matches?(pattern : Chem::Element | String) : Bool
    case pattern
    in Chem::Element
      @element == pattern
    in String
      @name == pattern
    end
  end
end
