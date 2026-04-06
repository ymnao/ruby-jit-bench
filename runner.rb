require "json"
require "open3"

MODES = {
  "default" => [],
  "YJIT"    => ["--yjit"],
  "ZJIT"    => ["--zjit"],
}

BENCH_DIR = File.join(__dir__, "benchmarks")
bench_files = Dir.glob("#{BENCH_DIR}/*.rb").sort

results = {}

bench_files.each do |file|
  MODES.each do |mode, flags|
    cmd = ["ruby", *flags, file]
    out, status = Open3.capture2(*cmd)
    unless status.success?
      warn "FAILED: #{cmd.join(' ')}"
      next
    end
    out.each_line do |line|
      data = JSON.parse(line) rescue next
      results[data["label"]] ||= {}
      results[data["label"]][mode] = data
    end
  end
end

puts "=== Ruby JIT Benchmark (#{RUBY_DESCRIPTION}) ==="
puts

header = "%-20s %10s %10s %10s %9s %9s" % ["Benchmark", "default", "YJIT", "ZJIT", "YJIT vs", "ZJIT vs"]
puts header
puts "-" * header.length

results.each do |label, modes|
  default_time = modes.dig("default", "time")
  next unless default_time

  vals = ["default", "YJIT", "ZJIT"].map { |m| modes.dig(m, "time") }
  time_strs = vals.map { |v| v ? ("%9.4fs" % v) : "     N/A " }

  yjit_ratio = vals[1] ? ("%.1fx" % (default_time / vals[1])) : "N/A"
  zjit_ratio = vals[2] ? ("%.1fx" % (default_time / vals[2])) : "N/A"

  puts "%-20s %s %s %s %9s %9s" % [label, *time_strs, yjit_ratio, zjit_ratio]
end
