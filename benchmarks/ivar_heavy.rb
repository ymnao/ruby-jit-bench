require_relative "../lib/bench_helper"

class Point
  def initialize
    @x = 1
    @y = 2
  end

  def compute
    # @x, @y を複数回読む → ZJITは冗長なロードを除去できる
    @x + @y + @x * @y + @x - @y
  end
end

point = Point.new

run_bench("Ivar load-store", n: 5_000_000) { point.compute }
