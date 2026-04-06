require_relative "../lib/bench_helper"

def succ_chain(n)
  n.succ.succ.succ.succ.succ
end

run_bench("C method inline", n: 5_000_000) { succ_chain(0) }
