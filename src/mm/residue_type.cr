class MM::ResidueType
  record AtomRecord, name : String, typename : String, partial_charge : Float64
  record BondRecord, lhs : String, rhs : String, order : Int32 = 1

  getter first_patch : String?
  getter last_patch : String?
  getter link_bond : BondRecord?
  getter name : String

  def initialize(
    @name : String,
    @atoms : Hash(String, AtomRecord),
    @bonds : Array(BondRecord),
    @link_bond : BondRecord? = nil,
    @first_patch : String? = nil,
    @last_patch : String? = nil
  )
  end

  def <=>(rhs : self) : Int32
    @name <=> rhs.name
  end

  def atoms : Hash::View(String, AtomRecord)
    @atoms.view
  end

  def bonds : Array::View(BondRecord)
    @bonds.view
  end

  def partial_charge : Float64
    @atoms.sum &.[1].partial_charge
  end
end
