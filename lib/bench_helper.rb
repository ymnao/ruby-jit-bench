require "benchmark"
require "json"

def run_bench(label, n: (ENV["BENCH_N"] || 1_000_000).to_i, warmup: 3)
  warmup.times { n.times { yield } }

  GC.start
  alloc_before = GC.stat(:total_allocated_objects)
  gc_before = GC.count
  time = Benchmark.measure { n.times { yield } }.real
  alloc_after = GC.stat(:total_allocated_objects)
  gc_after = GC.count

  puts JSON.generate({
    label: label,
    time: time.round(4),
    allocations: alloc_after - alloc_before,
    gc_count: gc_after - gc_before,
  })
end
