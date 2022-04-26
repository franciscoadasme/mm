class MM::Patch
  getter name : String

  def initialize(
    @name : String,
    @atoms : Array(ResidueType::AtomRecord),
    @bonds : Array(ResidueType::BondRecord),
    @delete_atoms : Array(String)
  )
  end

  def atoms : Indexable(AtomRecord)
    ArrayView.new @atoms
  end

  def bonds : Indexable(BondRecord)
    ArrayView.new @bonds
  end

  def delete_atoms : Indexable(String)
    ArrayView.new @delete_atoms
  end
end
