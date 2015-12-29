class SortedOnDemandArray
  def initialize
    @array = []
    @sorted = false
  end

  def each(&block)
    unless @sorted
      @array.sort!
      @sorted = true
    end
    @array.each(&block)
  end

  def <<(x)
    @array << x
    @sorted = false
  end

  def concat(xs)
    @array.concat(xs)
    @sorted = false
  end

  def delete(x)
    # OK not to change sortedness; deletion keeps sortedness the same.
    @array.delete(x)
  end

  def clear
    @array.clear
  end
end
