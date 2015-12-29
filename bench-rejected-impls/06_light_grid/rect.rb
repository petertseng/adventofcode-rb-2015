module RangeOps
  module_function

  def rangeinter(a, b)
    [a.begin, b.begin].max..[b.end, a.end].min
  end

  def rangeinter?(a, b)
    a.begin <= b.end && b.begin <= a.end
  end

  def rangesuper?(a, b)
    a.begin <= b.begin && b.end <= a.end
  end
end

Rect = Struct.new(:x, :y) {
  def intersects?(c)
    RangeOps.rangeinter?(x, c.x) && RangeOps.rangeinter?(y, c.y)
  end

  def &(c)
    Rect.new(RangeOps.rangeinter(x, c.x), RangeOps.rangeinter(y, c.y))
  end

  def superset?(c)
    RangeOps.rangesuper?(x, c.x) && RangeOps.rangesuper?(y, c.y)
  end

  def size
    x.size * y.size
  end

  def -(r)
    return [self] unless intersects?(r)

    inter = self & r

    cands = []
    # X out, Y all
    cands << Rect.new(x.begin..(inter.x.begin - 1), y) if x.begin < inter.x.begin
    cands << Rect.new((inter.x.end + 1)..x.end, y) if x.end > inter.x.end
    # X in, Y out
    cands << Rect.new(inter.x, y.begin..(inter.y.begin - 1)) if y.begin < inter.y.begin
    cands << Rect.new(inter.x, (inter.y.end + 1)..y.end) if y.end > inter.y.end
    cands
  end
}
