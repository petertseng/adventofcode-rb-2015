# I no longer remember where I got this idea,
# but I think it may have been Michael Abrash's Graphics Programming Black Book
# https://www.jagregory.com/abrash-black-book/#chapter-18-its-a-plain-wonderful-life
# There the idea of change lists is discussed.
# Or, the idea may have come from
# https://codereview.stackexchange.com/questions/42718/optimize-conways-game-of-life/42790#42790
class ActivityList
  def initialize(size, on, corners_stuck: false)
    @size = size
    @cells = Array.new(@size) { Array.new(@size, 0) }
    @active_cells = 0
    @active_xs = Array.new(@size * @size)
    @active_ys = Array.new(@size * @size)

    @corners_stuck = corners_stuck
    on |= [
      [0, 0],
      [0, @size - 1],
      [@size - 1, 0],
      [@size - 1, @size - 1],
    ] if corners_stuck

    # Format of each entry: 4 bit neighbour count, 1 bit live, 1 bit active
    on.each { |x, y|
      if @cells[y][x] & 1 == 0 && (!@corners_stuck || ![x, y].all? { |c| c == 0 || c == @size - 1 })
        @cells[y][x] += 1
        @active_xs[@active_cells] = x
        @active_ys[@active_cells] = y
        @active_cells += 1
      end

      # Increment neighbours.
      min_x = x == 0 ? x : x - 1
      min_y = y == 0 ? y : y - 1
      max_x = x == @size - 1 ? x : x + 1
      max_y = y == @size - 1 ? y : y + 1
      (min_y..max_y).each { |new_y|
        cells_y = @cells[new_y]
        (min_x..max_x).each { |new_x|
          cells_y[new_x] += 4
          if cells_y[new_x] & 1 == 0
            cells_y[new_x] += 1
            @active_xs[@active_cells] = new_x
            @active_ys[@active_cells] = new_y
            @active_cells += 1
          end
        }
      }
      # We incremented @cells[y][x] by 4 in the loop, but we just wanted 2.
      @cells[y][x] -= 2
    }
  end

  def live_size
    @cells.map { |row| row.count { |state| state & 2 == 2 } }.reduce(:+)
  end

  def step
    changed_cells = 0

    # Of all active cells, find those that will change.
    (0...@active_cells).each { |i|
      x = @active_xs[i]
      y = @active_ys[i]
      state = @cells[y][x]
      was_alive = state & 2 == 2
      # 10, 11 = 101x = alive with 2 neighbours
      # 12, 13 = 110x = dead with 3 neighbours
      # 14, 15 = 111x = alive with 3 neighbours
      is_alive = 10 <= state && state <= 15
      if was_alive != is_alive && (!@corners_stuck || ![x, y].all? { |c| c == 0 || c == @size - 1 })
        @active_xs[changed_cells] = x
        @active_ys[changed_cells] = y
        changed_cells += 1
      else
        # Not active anymore.
        @cells[y][x] -= 1
      end
    }

    @active_cells = changed_cells

    (0...changed_cells).each { |i|
      x = @active_xs[i]
      y = @active_ys[i]
      was_alive = @cells[y][x] & 2 == 2
      neighbour_change = was_alive ? -4 : 4

      min_x = x == 0 ? x : x - 1
      min_y = y == 0 ? y : y - 1
      max_x = x == @size - 1 ? x : x + 1
      max_y = y == @size - 1 ? y : y + 1
      (min_y..max_y).each { |new_y|
        cells_y = @cells[new_y]
        (min_x..max_x).each { |new_x|
          next if @corners_stuck && [new_x, new_y].all? { |c| c == 0 || c == @size - 1 }
          new_state = cells_y[new_x] + neighbour_change
          if new_state & 1 == 0
            @active_xs[@active_cells] = new_x
            @active_ys[@active_cells] = new_y
            @active_cells += 1
            new_state += 1
          end
          cells_y[new_x] = new_state
        }
      }
      # We adjusted @cells[y][x] by +/- 4 when it should be +/- 2.
      @cells[y][x] -= neighbour_change / 2
    }
  end
end
