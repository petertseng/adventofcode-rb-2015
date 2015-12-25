class Deer
  attr_reader :distance, :points, :time_in_state

  def initialize(name, vel, run_time, rest_time)
    @name = name
    @vel = vel
    @run_time = run_time
    @rest_time = rest_time
    @distance = 0
    @points = 0
    @running = true
    @time_in_state = run_time
  end

  def running?
    @running
  end

  def run
    @distance += @vel if @running
    # this is advance(1), but sim_each_second shouldn't be penalised by a method call
    @time_in_state -= 1
    if @time_in_state == 0
      @running = !@running
      @time_in_state = @running ? @run_time : @rest_time
    end
    @distance
  end

  def advance(t)
    # I think in reasonable code I would check that t <= @time_in_state
    @time_in_state -= t
    if @time_in_state == 0
      @running = !@running
      @time_in_state = @running ? @run_time : @rest_time
    end
  end

  def dist_at(t)
    full, part = (t + 1).divmod(@run_time + @rest_time)
    @vel * (@run_time * full + (part > @run_time ? @run_time : part))
  end

  def award_point(n = 1)
    @points += n
  end

  def to_s
    "#@name at #@distance km with #@points points"
  end
end

DEER = /^([A-Za-z]+) can fly (\d+) km\/s for (\d+) seconds, but then must rest for (\d+) seconds\.$/
TIME = 2503

verbose = ARGV.delete('-v')

deer = ARGF.map { |line|
  captures = DEER.match(line).captures
  name = captures.shift
  Deer.new(name, *captures.map(&method(:Integer)))
}.freeze

puts deer.map { |d| d.dist_at(TIME) }.max

# Thinking of eliminating deer that can't catch up in points?
# Can't do that!
# Deer that can't catch up in points can still take the distance lead,
# thereby preventing the points leader from gaining points.
# If I eliminated deer that can't catch up, I wouldn't know when this happened.
#
# Skipping times where all deer are resting, on the other hand, works fine.
t = 0
max_distance = 0
while t < TIME
  if deer.none?(&:running?)
    # don't skip past end of time (not needed for my input, but theoretically could)
    skips = deer.map(&:time_in_state) << TIME - t
    skip = skips.min
    deer.each { |d|
      d.award_point(skip) if d.distance == max_distance
      d.advance(skip)
    }
    t += skip
  else
    max_distance = deer.map(&:run).max
    deer.each { |d| d.award_point if d.distance == max_distance }
    t += 1
  end
end

puts deer if verbose

puts deer.map(&:points).max
