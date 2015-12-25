# https://dotat.at/prog/life/life.html
# https://dotat.at/cgi/cvsweb/things/life.c?rev=1.8
class ListLife
  NEXT_STATE = (0...(1 << 9)).map { |i|
    # You don't count as your own neighbour, and you are in bit 4 (020)
    bits_set = (0...9).count { |bit| bit != 4 && i & (1 << bit) != 0 }
    # 3 neighbours is always alive.
    # 2 neighbours is alive if you're alive (020 is set)
    bits_set == 3 || (i & 020 != 0) && bits_set == 2
  }.freeze

  def initialize(size, on, corners_stuck: false)
    @size = size

    on = (on + [
      [0, 0],
      [0, @size - 1],
      [@size - 1, 0],
      [@size - 1, @size - 1],
    ]).uniq if corners_stuck

    # Coordinates stored in a one-dimensional array in the following format:
    # A positive number indicates the Y coordinate of all following cells.
    # A negative number indicates an X coordinate of one cell.
    # Zero ends the array (not strictly necessary, but convenient).
    # Y coordinates are descending (100, 99, ..., 0), so that 0 comes last.
    # X coordinates are ascending (-100, -99, ..., -1).
    # Theoretically X coordinates could be descending too, so it was arbitrary.
    @cells = on.group_by { |_, y| y }.sort_by { |y, _| -y }.flat_map { |y, coords|
      [y + 1] + coords.map { |x, _| -x - 1 }.sort
    } << 0

    @corners_stuck = corners_stuck
  end

  def live_size
    @cells.count { |x| x < 0 }
  end

  def step
    prev_row_index = 0
    this_row_index = 0
    next_row_index = 0

    new_cells = [0]

    x = 0
    y = 0

    loop {
      if prev_row_index == next_row_index
        # This happens on init, or if some row is empty
        # (causing next_row_index to not increment).
        # At this point, this_row is on the first non-empty row after the gap.

        # There is no previous row, so we'll leave prev_row here.
        # It will be used next time, if the next row isn't empty.
        prev_row_index = this_row_index

        # We'll scan this row.
        y = @cells[this_row_index]
        break if y == 0
        this_row_index += 1

        # Move next_row to the row after this_row.
        next_row_index = @cells.index.with_index { |val, idx|
          idx > this_row_index && val >= 0
        }
      elsif y == 1
        # That's all the rows.
        break
      else
        # Move to next row.
        # If any row has the y value we expect,
        # increment its index so that we scan it.
        y -= 1
        prev_row_index += 1 if @cells[prev_row_index] == y + 1
        this_row_index += 1 if @cells[this_row_index] == y
      end
      next_row_index += 1 if @cells[next_row_index] == y - 1 && y > 1

      # Write new row coordinate
      if new_cells.last < 0
        new_cells << y
      else
        new_cells[-1] = y
      end

      corners_this_row = @corners_stuck && (y == 1 || y == @size)
      new_cells << -@size if corners_this_row

      neighbours = 0

      loop {
        # Skip to leftmost cell (most-negative value)
        x = [
          @cells[prev_row_index],
          @cells[this_row_index],
          @cells[next_row_index],
        ].min

        # If all three pointers are at a Y coordinate we are done with this row.
        if x >= 0
          new_cells << -1 if corners_this_row && new_cells.last != -1
          break
        end

        loop {
          # Add a column to the bitmap, at bit positions 6-8.
          if @cells[prev_row_index] == x
            neighbours |= 0100
            prev_row_index += 1
          end
          if @cells[this_row_index] == x
            neighbours |= 0200
            this_row_index += 1
          end
          if @cells[next_row_index] == x
            neighbours |= 0400
            next_row_index += 1
          end

          if NEXT_STATE[neighbours] && x > -@size
            new_cells << x - 1 unless corners_this_row && x - 1 == -@size
          elsif neighbours == 0
            # No neighbours means we should skip some x coordinates.
            break
          end

          # Move right by shifting a column (3 bits) out of the bitmap.
          # So, newest column is bits 6-8, second at 3-5, oldest at 0-2.
          neighbours >>= 3
          x += 1

          if x == 0
            # Checking for x - 1 == -@size here is only needed if @size == 1
            # But if @size == 1, then the single cell has no neighbours.
            # So we won't get to this point. So it's safe not to check.
            new_cells << x - 1 if NEXT_STATE[neighbours]
            break
          end
        }
      }
    }

    # Done with all the rows.
    if new_cells.last < 0
      new_cells << 0
    else
      new_cells[-1] = 0
    end

    @cells = new_cells
  end
end


