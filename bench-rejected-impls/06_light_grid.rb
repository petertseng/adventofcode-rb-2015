require 'benchmark'

require_relative '../06_light_grid'
require_relative '06_light_grid/bst'
require_relative '06_light_grid/sorted_array_plus_max'
require_relative '06_light_grid/sorted_bucket_array'
require_relative '06_light_grid/sorted_on_demand_array'
require_relative '06_light_grid/rect'

events_candidates = [
  [SortedArray, MaxArray],
  # candidates for SortedArray
  [SortedBucketArray, MaxArray],
  [SortedOnDemandArray, MaxArray],
  [Bst, MaxArray],
  # candidates for MaxArray
  [SortedArray, SortedArrayPlusMax],
  [SortedArray, Bst],
]

p1_rects_candidates = []
p2_rects_candidates = []

# Inclusion-exclusion works fine for part 1.
# But it has no real way to do part 2,
# since part 2 is no longer just about on/off.
p1_rects_candidates << def inclusion_exclusion(rectinsts)
  rects = Hash.new(0)
  rectinsts.each { |command, xmin, xmax, ymin, ymax|
    rect = Rect.new(xmin..xmax, ymin..ymax)
    update = Hash.new(0)
    rects.each { |k, v|
      next unless k.intersects?(rect)
      update[k & rect] -= v * (command == :toggle ? 2 : 1)
    }
    update[rect] += 1 if command != :off
    rects.merge!(update) { |_, v1, v2| v1 + v2 }
    rects.select! { |k, v| v != 0 }
  }
  rects.sum { |k, v| k.size * v }
end

# Could probably adapt this to part 2 as well,
# but it's too much work and already slower than sweep line for part 1 alone,
# so I don't want to bother.
p1_rects_candidates << def split1(rectinsts)
  rects = []
  rectinsts.each { |command, xmin, xmax, ymin, ymax|
    rect = Rect.new(xmin..xmax, ymin..ymax)
    case command
    when :on
      unless (inters = rects.select { |r| r.intersects?(rect) }).empty?
        # Subtract intersections with this rect before adding.
        # Thus, rects only contains non-intersection rects.
        rects.concat(inters.reduce([rect]) { |rs, r|
          rs.flat_map { |rr| rr - r }
        })
      else
        # Can just add it (no intersections).
        rects << rect
      end
    when :off
      # Subtract from all.
      intersected, rects = rects.partition { |r| r.intersects?(rect) }
      rects.concat(intersected.flat_map { |r| r - rect })
    when :toggle
      intersected, rects = rects.partition { |r| r.intersects?(rect) }
      unless intersected.empty?
        to_adds = [rect]
        intersected.each { |existing|
          inters2 = to_adds.map { |ta| ta & existing }
          # Add back existing - new
          rects.concat(inters2.reduce([existing]) { |rs, r|
            rs.flat_map { |rr| rr - r }
          })
          # new -= existing
          to_adds = to_adds.zip(inters2).flat_map { |ta, i|
            ta - i
          }
        }
        rects.concat(to_adds)
      else
        # Can just add it (no intersections).
        rects << rect
      end
    else
      raise "bad #{command}"
    end
  }
  rects.sum(&:size)
end

p1_rects_candidates << def remap1(rectinsts)
  coord = ->i {
    points = rectinsts.flat_map { |r| [r[i], r[i + 1] + 1] }.sort.uniq
    idx = points.each_with_index.to_h
    [points.freeze, idx.freeze]
  }
  xval, xidx = coord[1]
  yval, yidx = coord[3]
  width = xval.size
  grid = Array.new(yval.size - 1) { Array.new(width - 1, false) }
  rectinsts.each { |command, xmin, xmax, ymin, ymax|
    xr = xidx[xmin]...xidx[xmax + 1]
    yr = yidx[ymin]...yidx[ymax + 1]
    case command
    when :on; yr.each { |y| grid[y].fill(true, xr) }
    when :off; yr.each { |y| grid[y].fill(false, xr) }
    when :toggle
      yr.each { |y|
        row = grid[y]
        xr.each { |x| row[x] = !row[x] }
      }
    else raise "bad #{command}"
    end
  }
  grid.each_with_index.sum { |row, y|
    ysz = yval[y + 1] - yval[y]
    row.each_with_index.sum { |c, x|
      c ? ysz * (xval[x + 1] - xval[x]) : 0
    }
  }
end

p2_rects_candidates << def remap2(rectinsts)
  coord = ->i {
    points = rectinsts.flat_map { |r| [r[i], r[i + 1] + 1] }.sort.uniq
    idx = points.each_with_index.to_h
    [points.freeze, idx.freeze]
  }
  xval, xidx = coord[1]
  yval, yidx = coord[3]
  width = xval.size
  grid = Array.new(yval.size - 1) { Array.new(width - 1, 0) }
  rectinsts.each { |command, xmin, xmax, ymin, ymax|
    xr = xidx[xmin]...xidx[xmax + 1]
    yr = yidx[ymin]...yidx[ymax + 1]
    case command
    when :on
      yr.each { |y|
        row = grid[y]
        xr.each { |x| row[x] += 1 }
      }
    when :off
      yr.each { |y|
        row = grid[y]
        xr.each { |x| row[x] -= 1 if row[x] > 0 }
      }
    when :toggle
      yr.each { |y|
        row = grid[y]
        xr.each { |x| row[x] += 2 }
      }
    else raise "bad #{command}"
    end
  }
  grid.each_with_index.sum { |row, y|
    ysz = yval[y + 1] - yval[y]
    row.each_with_index.sum { |c, x|
      c * ysz * (xval[x + 1] - xval[x])
    }
  }
end

results = {}

Benchmark.bmbm { |bm|
  events_candidates.each { |cs|
    bm.report(cs) {
      results[cs] = lights(@events_x, *cs)
    }
  }
}

# Obviously the benchmark would be useless if they got different answers.
if results.values.uniq.size != 1
  results.each { |k, v| puts "#{k} #{v}" }
  raise 'differing answers'
end

puts 'part 1 candidates (compare times with above accordingly)'

results1 = results.transform_values(&:first)
results2 = results.transform_values(&:last)

Benchmark.bmbm { |bm|
  p1_rects_candidates.each { |c|
    bm.report(c) {
      results1[c] = send(c, @rects)
    }
  }
}

if results1.values.uniq.size != 1
  results1.each { |k, v| puts "#{k} #{v}" }
  raise 'differing answers'
end

puts 'part 2 candidates (compare times with above accordingly)'

Benchmark.bmbm { |bm|
  p2_rects_candidates.each { |c|
    bm.report(c) {
      results2[c] = send(c, @rects)
    }
  }
}

if results2.values.uniq.size != 1
  results2.each { |k, v| puts "#{k} #{v}" }
  raise 'differing answers'
end
