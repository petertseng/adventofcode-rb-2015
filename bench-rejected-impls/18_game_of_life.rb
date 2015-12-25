require 'benchmark'

require_relative '../18_game_of_life'
require_relative '18_game_of_life/activity_list'
require_relative '18_game_of_life/cache_neighbour_counts'
require_relative '18_game_of_life/list_life'
require_relative '18_game_of_life/nine_bit_scan'
require_relative '18_game_of_life/one_coord'
require_relative '18_game_of_life/set_per_row'
require_relative '18_game_of_life/single_set'

bench_candidates = [
  ActivityList,
  CacheNeighbourCounts,
  ListLife,
  NineBitScan,
  OneCoord,
  SetPerRow,
  SingleSet,
  SixteenBitScan,
]

[false, true].each { |corners_stuck|
  puts "corners#{' not' unless corners_stuck} stuck"
  results = {}

  Benchmark.bmbm { |bm|
    bench_candidates.each { |c|
      bm.report(c) {
        g = c.new(*@args, corners_stuck: corners_stuck)
        100.times { g.step }
        results[c] = g.live_size
      }
    }
  }

  # Obviously the benchmark would be useless if they got different answers.
  if results.values.uniq.size != 1
    results.each { |k, v| puts "#{k} #{v}" }
    raise 'differing answers'
  end
}
