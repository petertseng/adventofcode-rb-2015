# I no longer remember where I got this idea,
# but I think it may have been Michael Abrash's Graphics Programming Black Book
# https://www.jagregory.com/abrash-black-book/#bringing-in-the-right-brain
# There the idea of storing the neighbour counts along with the on/off status is discussed.
# Or, the idea may have come from
# https://codereview.stackexchange.com/questions/42718/optimize-conways-game-of-life/42738#42738
class CacheNeighbourCounts
  def initialize(size, on, corners_stuck: false)
    # I tend to like a sparse representation of live cells.
    # This makes it easier to increment live neighbour counts.
    @size = size
    @cells = {}
    @neighbours = Array.new(@size) { Array.new(@size, 0) }
    on.each { |x, y| add(y * @size + x) }
    @corners_stuck = corners_stuck
    add_corners if corners_stuck
  end

  def live_size
    @cells.size
  end

  def step
    adds = @neighbours.flat_map.with_index { |row, y|
      row.each_with_index.select { |count, x|
        count == 3 && !live?(x, y)
      }.map { |_, x| y * @size + x }
    }

    deletes = @cells.keys.select { |pos|
      y, x = pos.divmod(@size)
      count = @neighbours[y][x]
      count != 2 && count != 3
    }

    adds.each { |pos| add(pos) }
    deletes.each { |pos| delete(pos) }

    add_corners if @corners_stuck
  end

  private

  def add_corners
    add(0) unless live?(0, 0)
    add(@size - 1) unless live?(@size - 1, 0)
    add((@size - 1) * @size) unless live?(0, @size - 1)
    add(@size * @size - 1) unless live?(@size - 1, @size - 1)
  end

  def live?(x, y)
    @cells[y * @size + x]
  end

  def add(pos)
    @cells[pos] = true
    y, x = pos.divmod(@size)
    # Increment neighbours.
    (-1..1).each { |dy|
      new_y = y + dy
      next if new_y < 0 || new_y >= @size
      neighbour_ys = @neighbours[new_y]
      (-1..1).each { |dx|
        # You aren't a neighbour of yourself.
        next if dx == 0 && dy == 0
        new_x = x + dx
        next if new_x < 0 || new_x >= @size
        neighbour_ys[new_x] += 1
      }
    }
  end

  def delete(pos)
    @cells.delete(pos)
    y, x = pos.divmod(@size)
    # Decrement neighbours.
    (-1..1).each { |dy|
      new_y = y + dy
      next if new_y < 0 || new_y >= @size
      neighbour_ys = @neighbours[new_y]
      (-1..1).each { |dx|
        # You aren't a neighbour of yourself.
        next if dx == 0 && dy == 0
        new_x = x + dx
        next if new_x < 0 || new_x >= @size
        neighbour_ys[new_x] -= 1
      }
    }
  end
end
