class MM::ResidueType
  record AtomRecord, name : String, typename : String, partial_charge : Float64
  record BondRecord, lhs : String, rhs : String, order : Int32 = 1

  getter first_patch : String?
  getter last_patch : String?
  getter link_bond : BondRecord?
  getter name : String

  def initialize(
    @name : String,
    @atoms : Array(AtomRecord),
    @bonds : Array(BondRecord),
    @link_bond : BondRecord? = nil,
    @first_patch : String? = nil,
    @last_patch : String? = nil
  )
  end

  def atoms : Indexable(AtomRecord)
    ArrayView.new @atoms
  end

  def bonds : Indexable(BondRecord)
    ArrayView.new @bonds
  end

  def partial_charge : Float64
    @atoms.sum &.partial_charge
  end
end
