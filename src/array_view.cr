struct ArrayView(T)
  include Comparable(Array(T))
  include Comparable(ArrayView(T))
  include Indexable(T)

  def initialize(@arr : Array(T), @offset : Int32 = 0)
    raise ArgumentError.new("Negative offset") if @offset.negative?
    raise IndexError.new unless @offset < @arr.size
  end

  def <=>(rhs : Array(T)) : Int32
    @arr <=> rhs
  end

  def <=>(rhs : self) : Int32
    @arr <=> rhs.to_a
  end

  def size : Int32
    @arr.size - @offset
  end

  def to_a : Array(T)
    @arr
  end

  def to_unsafe : Pointer(T)
    @arr.to_unsafe
  end

  @[AlwaysInline]
  def unsafe_fetch(index : Int) : T
    @arr.unsafe_fetch index + @offset
  end
end
