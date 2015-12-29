class SortedBucketArray
  module EventToI refine Event do
    def to_i
      y
    end
  end end

  using EventToI

  def initialize
    @array = []
    @sorted = true
  end

  def each(&block)
    compacted = @array.compact
    compacted.each(&:sort!) unless @sorted
    compacted.flatten.each(&block)
  end

  def <<(x)
    @sorted = false
    @array[x.to_i] ||= []
    @array[x.to_i] << x
  end

  def concat(xs)
    @sorted = false
    xs.each { |x| self << x }
  end

  def delete(x)
    @array[x.to_i].delete(x)
  end

  def clear
    @array.clear
  end
end
