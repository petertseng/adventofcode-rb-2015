COMMAND = /^(?:turn )?(on|off|toggle) (\d+),(\d+) through (\d+),(\d+)$/

def new_grid; Array.new(1000) { Array.new(1000, 0) }; end

puts ARGF.each_line.with_object([new_grid, new_grid]) { |l, (on_off_grid, bright_grid)|
  captures = COMMAND.match(l).captures
  command = captures.shift.to_sym
  xmin, ymin, xmax, ymax = captures.map(&method(:Integer))

  case command
  when :on
    on_off_result = ->(_) { 1 }
    bright_result = ->(x) { x + 1 }
  when :off
    on_off_result = ->(_) { 0 }
    bright_result = ->(x) { x == 0 ? 0 : x - 1 }
  when :toggle
    on_off_result = ->(x) { 1 - x }
    bright_result = ->(x) { x + 2 }
  end

  yrange = ymin..ymax
  (xmin..xmax).each { |x|
    on_off_grid[x][yrange] = on_off_grid[x][yrange].map(&on_off_result)
    bright_grid[x][yrange] = bright_grid[x][yrange].map(&bright_result)
  }
}.map { |a| a.flatten.sum }
