require 'benchmark'

class Deer
  attr_reader :distance, :points, :time_in_state

  def initialize((vel, run_time, rest_time))
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

  def timeskip
    !@running && @time_in_state
  end

  def award_point(n = 1)
    @points += n
  end

  def to_s
    "#@name at #@distance km with #@points points"
  end
end

DEER = /^[A-Za-z]+ can fly (\d+) km\/s for (\d+) seconds, but then must rest for (\d+) seconds\.$/
TIME = 2503

deer = ARGF.map { |line|
  DEER.match(line).captures.map(&method(:Integer)).freeze
}.freeze

bench_candidates = []

bench_candidates << def use_dist_at(deer)
  points = Array.new(deer.size, 0)
  TIME.times { |t|
    dists = deer.map { |vel, run_time, rest_time|
      full, part = (t + 1).divmod(run_time + rest_time)
      vel * (run_time * full + (part > run_time ? run_time : part))
    }
    maxdist = dists.max
    dists.each_with_index { |d, i| points[i] += 1 if d == maxdist }
  }
  points.max
end

bench_candidates << def use_dist_at_cache_cycle_time(deer)
  points = Array.new(deer.size, 0)
  deer = deer.map { |v, run, rest| [v, run, run + rest] }
  TIME.times { |t|
    dists = deer.map { |vel, run_time, cycle_time|
      full, part = (t + 1).divmod(cycle_time)
      vel * (run_time * full + (part > run_time ? run_time : part))
    }
    maxdist = dists.max
    dists.each_with_index { |d, i| points[i] += 1 if d == maxdist }
  }
  points.max
end

bench_candidates << def sim_each_second(deer)
  deer = deer.map { |d| Deer.new(d) }
  TIME.times { |t|
    max_distance = deer.map(&:run).max
    deer.each { |d| d.award_point if d.distance == max_distance }
  }
  deer.map(&:points).max
end

# combines the query of should skip? along with how much time to skip
bench_candidates << def skip_if_all_resting_combined_query(deer)
  deer = deer.map { |d| Deer.new(d) }
  t = 0
  max_distance = 0
  while t < TIME
    skips = deer.map(&:timeskip)
    if skips.all?
      # don't skip past end of time (not needed for my input, but theoretically could)
      skips << TIME - t
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
  deer.map(&:points).max
end

# unlike combined_query, only queries time_in_state if none are running.
bench_candidates << def skip_if_all_resting_two_query(deer)
  deer = deer.map { |d| Deer.new(d) }
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
  deer.map(&:points).max
end

bench_candidates << def skip_if_all_resting_two_query_cache_leader(deer)
  deer = deer.map { |d| Deer.new(d) }
  t = 0
  leader = []
  while t < TIME
    if deer.none?(&:running?)
      # don't skip past end of time (not needed for my input, but theoretically could)
      skips = deer.map(&:time_in_state) << TIME - t
      skip = skips.min
      deer.each { |d| d.advance(skip) }
      leader.each { |d| d.award_point(skip) }
      t += skip
    else
      max_distance = deer.map(&:run).max
      leader = deer.select { |d| d.distance == max_distance }
      leader.each { |d| d.award_point }
      t += 1
    end
  end
  deer.map(&:points).max
end

results = {}

Benchmark.bmbm { |bm|
  bench_candidates.each { |f|
    bm.report(f) { 50.times { results[f] = send(f, deer) }}
  }
}

# Obviously the benchmark would be useless if they got different answers.
if results.values.uniq.size != 1
  results.each { |k, v| puts "#{k} #{v}" }
  raise 'differing answers'
end
