require "json"
require "open3"

MODES = {
  "default" => [],
  "YJIT"    => ["--yjit"],
  "ZJIT"    => ["--zjit"],
}

ITERATIONS = (ENV["BENCH_ITER"] || 5).to_i
abort "BENCH_ITER must be a positive integer" unless ITERATIONS.positive?

BENCH_DIR = File.join(__dir__, "benchmarks")
bench_files = Dir.glob("#{BENCH_DIR}/*.rb").sort

results = {}
failures = []
total = bench_files.size * MODES.size * ITERATIONS
count = 0

bench_files.each do |file|
  bench_name = File.basename(file, ".rb")
  MODES.each do |mode, flags|
    runs = []
    ITERATIONS.times do |i|
      count += 1
      $stderr.print "\r[%d/%d] %-20s %-8s (%d/%d)" % [count, total, bench_name, mode, i + 1, ITERATIONS]
      cmd = ["ruby", *flags, file]
      out, err, status = Open3.capture3(*cmd)
      unless status.success?
        warn "\nFAILED: #{cmd.join(' ')}"
        warn "  #{err.lines.first&.chomp}" unless err.empty?
        failures << "#{bench_name} (#{mode})"
        next
      end
      out.each_line do |line|
        data = JSON.parse(line) rescue next
        runs << data
      end
    end

    next if runs.empty?

    sorted = runs.sort_by { |d| d["time"] }
    median = sorted[sorted.size / 2]
    results[median["label"]] ||= {}
    results[median["label"]][mode] = median
  end
end

$stderr.puts "\n"

puts "=== Ruby JIT Benchmark (#{RUBY_DESCRIPTION}) ==="
puts "(#{ITERATIONS} runs, median)"
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

unless failures.empty?
  warn "\nFailed: #{failures.uniq.join(', ')}"
  exit 1
end
