COMMAND = /^(?:turn )?(on|off|toggle) (\d+),(\d+) through (\d+),(\d+)$/

Event = Struct.new('Event', :x, :y, :time, :command, :type) {
  include Comparable

  def <=>(other)
    [y, time] <=> [other.y, other.time]
  end
}

# These are also known as Fenwick trees
class BinaryIndexedTree
  def initialize(max_time)
    @toggles = Array.new(max_time, 0)
    @max_time = max_time
  end

  def value_before(time)
    ret = 0
    while time > 0
      ret += @toggles[time]
      time -= time & -time
    end
    ret
  end

  def add(time, val = 1)
    raise "time must be positive, can't be #{time}" if time <= 0
    while time < @max_time
      @toggles[time] += val
      time += time & -time
    end
  end

  def clear
    @toggles.fill(0)
  end
end

# used for on_off_times
class MaxArray
  attr_reader :max

  def initialize
    @vals = {}
    @max = nil
  end

  def <<(x)
    @vals[x] = true
    @max = x unless @max &.> x
  end

  def delete(x)
    @vals.delete(x)
    @max = @vals.keys.max if x == @max
  end
end

# A not-very-good sorted array.
# Used for events_y, negative_times.
# Required operations: insert (<<), delete, iterate sorted (each)
# SortedSet has, but is slow unless rbtree is installed.
# Attempted to implement a BST but naive without balancing was too slow.
# Balancing looked like too much work to do.
class SortedArray
  def initialize
    @array = []
  end

  def each(&block)
    @array.each(&block)
  end

  def <<(x)
    # Well, the search is O(log n)...
    # But splicing in an element at an index is probably expensive.
    if (add_index = index(x))
      @array.insert(add_index, x)
    else
      @array << x
    end
  end

  def concat(xs)
    xs.each { |x| self << x }
  end

  def delete(x)
    if (delete_index = index(x))
      return unless @array[delete_index] == x
      @array.delete_at(delete_index)
    end
  end

  def clear
    @array.clear
  end

  private

  def index(x)
    (0...@array.size).bsearch { |i| @array[i] >= x }
  end
end

def sweep_y(events_y, num_events, sorted_collection = SortedArray, max_collection = MaxArray)
  prev_y = 0

  lit_ys = 0
  total_toggles = 0
  toggles = BinaryIndexedTree.new(num_events + 1)
  on_off_state = {-1 => false}
  on_off_times = max_collection.new

  bright_ys = 0
  negative_times = sorted_collection.new
  positives = BinaryIndexedTree.new(num_events + 1)

  events_y.each { |event_y|
    if event_y.y != prev_y
      delta_y = event_y.y - prev_y

      # Get the most recent on/off state:
      most_recent_time = on_off_times.max || -1
      most_recent_state = on_off_state[most_recent_time]
      # We want to count the toggles since the most recent on/off.
      # That's total toggles minus toggles before that time.
      toggled = (total_toggles - toggles.value_before(most_recent_time)) % 2 == 1
      lit_ys += delta_y if most_recent_state ^ toggled

      slab_brightness = 0
      positives_already_seen = 0
      negative_times.each { |t|
        total_positives = positives.value_before(t)
        slab_brightness += total_positives - positives_already_seen
        slab_brightness = [slab_brightness - 1, 0].max
        positives_already_seen = total_positives
      }
      slab_brightness += positives.value_before(num_events) - positives_already_seen
      bright_ys += slab_brightness * delta_y
    end

    prev_y = event_y.y

    if event_y.command == :toggle
      # no matter whether a toggle is beginning or ending,
      # we can just increment toggles.
      total_toggles += 1
      toggles.add(event_y.time)
      positives.add(event_y.time, event_y.type == :begin ? 2 : -2)
    else
      if event_y.type == :begin
        on_off_state[event_y.time] = event_y.command == :on
        on_off_times << event_y.time
      elsif event_y.type == :end
        on_off_state.delete(event_y.time)
        on_off_times.delete(event_y.time)
      end

      if event_y.command == :on
        positives.add(event_y.time, event_y.type == :begin ? 1 : -1)
      elsif event_y.command == :off
        if event_y.type == :begin
          negative_times << event_y.time
        elsif event_y.type == :end
          negative_times.delete(event_y.time)
        end
      end
    end
  }

  [lit_ys, bright_ys]
end

def lights(events_x, sorted_collection = SortedArray, max_collection = MaxArray)
  lights_lit = 0
  brightness = 0

  prev_x = 0
  events_y = sorted_collection.new

  num_events = events_x.size / 2

  events_x.each { |event|
    if event.x != prev_x
      lit_ys, bright_ys = sweep_y(events_y, num_events, sorted_collection, max_collection)
      delta_x = event.x - prev_x
      lights_lit += lit_ys * delta_x
      brightness += bright_ys * delta_x
    end

    prev_x = event.x

    if event.type == :end
      events_y.delete(Event.new(nil, event.y.begin, event.time, nil, nil))
      events_y.delete(Event.new(nil,   event.y.end, event.time, nil, nil))
    else
      events_y.concat([
        Event.new(nil, event.y.begin, event.time, event.command, :begin),
        Event.new(nil,   event.y.end, event.time, event.command, :end),
      ])
    end
  }

  [lights_lit, brightness]
end

rects = []
events_x = []

ARGF.each_with_index { |l, i|
  captures = COMMAND.match(l).captures
  command = captures.shift.to_sym
  xmin, ymin, xmax, ymax = captures.map(&method(:Integer))
  rects << [command, xmin, xmax, ymin, ymax].freeze
  events_x << Event.new(xmin, ymin..(ymax + 1), i + 1, command, :begin)
  events_x << Event.new(xmax + 1, ymin..(ymax + 1), i + 1, command, :end)
}

rects.freeze
events_x.sort_by! { |e| [e.x, e.time] }.freeze

puts lights(events_x)

# export for benchmark
@rects = rects
@events_x = events_x
