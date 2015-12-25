# Basic scan through a sparse array (only live cells),
# with flat coordinate y * width + x.
class OneCoord
  def initialize(size, on, corners_stuck: false)
    # I tend to like a sparse representation of live cells.
    # This makes it easier to increment live neighbour counts.
    @size = size
    @cells = {}
    on.each { |x, y| add(x, y) }
    @corners_stuck = corners_stuck
    add_corners if corners_stuck
  end

  def live_size
    @cells.size
  end

  def step
    counts = Array.new(@size) { Array.new(@size, 0) }
    @cells.each_key { |pos|
      y, x = pos.divmod(@size)
      # Increment neighbours.
      (-1..1).each { |dy|
        new_y = y + dy
        next if new_y < 0 || new_y >= @size
        counts_y = counts[new_y]
        (-1..1).each { |dx|
          # You aren't a neighbour of yourself.
          next if dx == 0 && dy == 0
          new_x = x + dx
          next if new_x < 0 || new_x >= @size
          counts_y[new_x] += 1
        }
      }
    }
    counts.each_with_index { |row, y| row.each_with_index { |count, x|
      add(x, y) if count == 3
    }}
    @cells.each_key { |pos|
      y, x = pos.divmod(@size)
      count = counts[y][x]
      @cells.delete(pos) if count != 2 && count != 3
    }

    add_corners if @corners_stuck
  end

  private

  def add_corners
    add(0, 0)
    add(0, @size - 1)
    add(@size - 1, 0)
    add(@size - 1, @size - 1)
  end

  def add(x, y)
    @cells[y * @size + x] = true
  end
end
