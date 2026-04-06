require_relative "../lib/bench_helper"

def arithmetic(a, b, c, d)
  a + b * c - d
end

run_bench("Type-stable", n: 5_000_000) { arithmetic(1, 2, 3, 4) }
