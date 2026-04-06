require_relative "../lib/bench_helper"

def compute_heavy(x)
  a = 2 + 1
  b = a * 10
  c = b + 7
  d = c * c
  dead1 = a * b * c
  dead2 = d + dead1
  x + d
end

run_bench("Constant fold", n: 5_000_000) { compute_heavy(42) }
