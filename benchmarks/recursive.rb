require_relative "../lib/bench_helper"

def fib(n)
  return n if n < 2
  fib(n - 1) + fib(n - 2)
end

run_bench("Recursive (fib30)", n: 1) { fib(30) }
