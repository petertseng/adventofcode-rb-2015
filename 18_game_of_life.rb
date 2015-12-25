# This sixteen-bit scan originated from askalski's solution to 2021 day 20 (Trench Map).
# The same idea can be applied here, but modified a bit,
# since outputs are no longer offset from inputs.
class SixteenBitScan
  # 0 3 6
  # 1 4 7
  # 2 5 8
  NEXT_STATE_9 = (0...(1 << 9)).map { |i|
    # You don't count as your own neighbour, and you are in bit 4 (020)
    bits_set = (0...9).count { |bit| bit != 4 && i & (1 << bit) != 0 }
    # 3 neighbours is always alive.
    # 2 neighbours is alive if you're alive (020 is set)
    bits_set == 3 || (i & 020 != 0) && bits_set == 2 ? 1 : 0
  }.freeze
  # 0 4 8 c
  # 1 5 9 d
  # 2 6 a e
  # 3 7 b f
  #
  # output in bits 0, 1, 4, 5
  NEXT_STATE_16 = (0...(1 << 16)).map { |i|
    ul = NEXT_STATE_9[(i & 0x700)  >> 2 | (i & 0x70)  >> 1 |  i & 0x7]
    ll = NEXT_STATE_9[(i & 0xe00)  >> 3 | (i & 0xe0)  >> 2 | (i & 0xe)  >> 1]
    ur = NEXT_STATE_9[(i & 0x7000) >> 6 | (i & 0x700) >> 5 | (i & 0x70) >> 4]
    lr = NEXT_STATE_9[(i & 0xe000) >> 7 | (i & 0xe00) >> 6 | (i & 0xe0) >> 5]

    lr << 5 | ur << 4 | ll << 1 | ul
  }.freeze

  def initialize(size, on, corners_stuck: false)
    raise "Could probably handle odd sizes, would just have to write code to handle it" if size.odd?
    @size = size / 2
    @pad_width = @size + 2
    @cells = Array.new(@pad_width ** 2, 0)
    @write = Array.new(@pad_width ** 2, 0)

    on.each { |x, y|
      yquad, y = y.divmod(2)
      xquad, x = x.divmod(2)
      shift = y * 1 + x * 4
      @cells[(yquad + 1) * @pad_width + xquad + 1] |= 1 << shift
    }

    set_corners if corners_stuck
    @corners_stuck = corners_stuck
  end

  def to_s
    (1..@size).map { |y|
      l1 = ''
      l2 = ''
      (1..@size).each { |x|
        v = @cells[y * @pad_width + x]
        l1 << ((v >> 0) & 1 != 0 ? ?# : ' ')
        l1 << ((v >> 4) & 1 != 0 ? ?# : ' ')
        l2 << ((v >> 1) & 1 != 0 ? ?# : ' ')
        l2 << ((v >> 5) & 1 != 0 ? ?# : ' ')
      }
      l1 + "\n" + l2
    }.join("\n")
  end

  def set_corners
    @cells[@pad_width + 1] |= 1
    @cells[@pad_width + @size] |= 1 << 4
    @cells[@size * @pad_width + 1] |= 1 << 1
    @cells[@size * @pad_width + @size] |= 1 << 5
  end

  def live_size
    @cells.sum { |x| x.to_s(2).count(?1) }
  end

  def step
    # To move right, we need four bits from the same row,
    # and two bits from rows above and below.
    #
    # AABBCC
    # DDXXEE
    # DDXXEE
    # FFGGHH
    #
    # 0 4  8 12 16
    # 1 5  9 13 17
    # 2 6 10 14 18
    # 3 7 11 15 19
    #
    # We'll read C, E, and H into the bits 12-19, but mask out 16-19 in lookup.
    (1..@size).each { |y|
      # Initial:
      # row above: bits 1 and 5 become 12 and 16
      # same row: bits, 0, 1, 4, 5 become 13, 14, 17, 18
      # row below: bits 0 and 4 become 15 and 19
      neighbours = (@cells[(y - 1) * @pad_width + 1] & 0x22) << 11 | @cells[y * @pad_width + 1] << 13 | (@cells[(y + 1) * @pad_width + 1] & 0x11) << 15
      (1..@size).each { |x|
        # move right: bits 8-19 become 0-11, new bits added at 12-19
        neighbours = neighbours >> 8 | (@cells[(y - 1) * @pad_width + x + 1] & 0x22) << 11 | @cells[y * @pad_width + x + 1] << 13 | (@cells[(y + 1) * @pad_width + x + 1] & 0x11) << 15
        @write[y * @pad_width + x] = NEXT_STATE_16[neighbours & 0xffff]
      }
    }
    @cells, @write = @write, @cells
    set_corners if @corners_stuck
  end
end

Grid = SixteenBitScan

points = ARGF.each_with_index.with_object(on: []) { |(line, y), h|
  line.chomp!
  size = line.size
  h[:size] ||= size
  raise "line #{y} has size #{size} expected #{h[:size]}" if h[:size] != size
  line.each_char.with_index { |char, x| h[:on] << [x, y] if char == ?# }
}.freeze

args = points.values_at(:size, :on).map(&:freeze).freeze
grids = [
  Grid.new(*args),
  Grid.new(*args, corners_stuck: true),
]

grids.each { |grid|
  100.times { grid.step }
  puts grid.live_size
}

# export for benchmark
@args = args
