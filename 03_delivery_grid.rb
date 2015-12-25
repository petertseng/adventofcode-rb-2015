require 'set'

# Unknown grid size
# we'll assume they won't exceed approx 1<<29 in each direction.
# Two coordinates; (1<<60).object_id indicates it is still Fixnum, not Bignum.
COORD = 30
Y = 1 << 30
ORIGIN = (Y / 2) << COORD | (Y / 2)

class Santa
  def initialize
    @pos = ORIGIN
  end

  def move(c)
    case c
    when ?^; @pos += Y
    when ?v; @pos -= Y
    when ?>; @pos += 1
    when ?<; @pos -= 1
    when "\n"; @pos
    else raise "bad char #{c}"
    end
  end
end

class Trip
  def initialize(num_santas)
    @santas = Array.new(num_santas) { Santa.new }
    @visits = Set.new([ORIGIN])
  end

  def move(c)
    @visits.add(@santas.first.move(c))
    @santas.rotate!
    self
  end

  def size
    @visits.size
  end
end

puts ARGF.each_char.with_object([Trip.new(1), Trip.new(2)]) { |char, trips|
  trips.each { |trip| trip.move(char) }
}.map(&:size)
