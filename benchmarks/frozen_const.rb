require_relative "../lib/bench_helper"

class Point
  attr_reader :x, :y

  def initialize(x, y)
    @x = x; @y = y
  end
end

ORIGIN = Point.new(3, 4).freeze

def compute_frozen
  ORIGIN.x + ORIGIN.y + ORIGIN.x * ORIGIN.y
end

run_bench("Frozen const", n: 5_000_000) { compute_frozen }
