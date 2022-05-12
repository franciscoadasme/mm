class MM::Patch
  getter name : String

  def initialize(
    @name : String,
    @atoms : Array(ResidueType::AtomRecord),
    @bonds : Array(ResidueType::BondRecord),
    @delete_atoms : Array(String)
  )
  end

  def atoms : Indexable(ResidueType::AtomRecord)
    @atoms.view
  end

  def bonds : Array::View(ResidueType::BondRecord)
    @bonds.view
  end

  def delete_atoms : Array::View(String)
    @delete_atoms.view
  end

  def partial_charge : Float64
    @atoms.sum &.partial_charge
  end
end
