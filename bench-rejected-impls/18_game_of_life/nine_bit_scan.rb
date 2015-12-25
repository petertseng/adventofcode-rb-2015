# Basic scan through a dense full grid array,
# but taking advantage of the fact that adjacent neighbourhoods share six cells.
class NineBitScan
  NEXT_STATE = (0...(1 << 9)).map { |i|
    # You don't count as your own neighbour, and you are in bit 4 (020)
    bits_set = (0...9).count { |bit| bit != 4 && i & (1 << bit) != 0 }
    # 3 neighbours is always alive.
    # 2 neighbours is alive if you're alive (020 is set)
    bits_set == 3 || (i & 020 != 0) && bits_set == 2 ? 1 : 0
  }.freeze

  def initialize(size, on, corners_stuck: false)
    @size = size
    @pad_width = size + 2
    @cells = Array.new((size + 2) ** 2, 0)
    @write = Array.new((size + 2) ** 2, 0)

    on.each { |x, y|
      @cells[(y + 1) * @pad_width + x + 1] = 1
    }

    set_corners if corners_stuck
    @corners_stuck = corners_stuck
  end

  def set_corners
    @cells[@pad_width + 1] = 1
    @cells[@pad_width + @size] = 1
    @cells[@size * @pad_width + 1] = 1
    @cells[@size * @pad_width + @size] = 1
  end

  def live_size
    @cells.sum
  end

  def step
    (1..@size).each { |y|
      # 0 3 6
      # 1 4 7
      # 2 5 8
      #
      # move right by shifting right 3
      neighbours = @cells[(y - 1) * @pad_width + 1] << 6 | @cells[y * @pad_width + 1] << 7 | @cells[(y + 1) * @pad_width + 1] << 8
      (1..@size).each { |x|
        neighbours = neighbours >> 3 | @cells[(y - 1) * @pad_width + x + 1] << 6 | @cells[y * @pad_width + x + 1] << 7 | @cells[(y + 1) * @pad_width + x + 1] << 8
        @write[y * @pad_width + x] = NEXT_STATE[neighbours]
      }
    }
    @cells, @write = @write, @cells
    set_corners if @corners_stuck
  end
end
