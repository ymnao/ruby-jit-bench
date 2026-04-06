require_relative "../lib/bench_helper"

class Obj
  def initialize
    @v0 = 1; @v1 = 2; @v3 = 3; @levar = 1
  end

  def set_value_loop
    @levar = 1
    @levar = 1
    @levar = 1
    @levar = 1
    @levar = 1
    @levar = 1
    @levar = 1
    @levar = 1
    @levar = 1
    @levar = 1
  end
end

obj = Obj.new

run_bench("Setivar", n: 1_000_000) { obj.set_value_loop }
