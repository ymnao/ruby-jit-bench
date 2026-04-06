require "json"
require "open3"

WORKLOAD = <<~'RUBY'
  require_relative "lib/bench_helper"

  class Counter
    def initialize = @x = 0
    def step = @x = @x + 1
  end

  class Dog;  def speak = "woof"; end
  class Cat;  def speak = "meow"; end
  class Bird; def speak = "tweet"; end

  animals = [Dog.new, Cat.new, Bird.new]
  counter = Counter.new

  500_000.times do
    animals.each { |a| a.speak }
    counter.step
  end
RUBY

WORKLOAD_FILE = File.join(__dir__, ".stats_workload.rb")
File.write(WORKLOAD_FILE, WORKLOAD)

yjit_script = <<~RUBY
  #{WORKLOAD}
  require "json"
  stats = RubyVM::YJIT.runtime_stats
  puts JSON.generate({
    compiled_methods: stats[:compiled_iseq_count],
    compile_time_ms: (stats[:compile_time_ns] / 1_000_000.0).round(1),
    code_size: stats[:inline_code_size] + stats[:outlined_code_size],
    side_exits: stats[:side_exit_count],
  })
RUBY

zjit_script = <<~RUBY
  #{WORKLOAD}
  require "json"
  stats = RubyVM::ZJIT.stats
  puts JSON.generate({
    compiled_methods: stats[:compiled_iseq_count],
    compile_time_ms: (stats[:compile_time_ns] / 1_000_000.0).round(1),
    code_size: stats[:code_region_bytes],
    side_exits: stats[:side_exit_count],
  })
RUBY

def run_stats(label, script, flags)
  out, err, status = Open3.capture3("ruby", *flags, "-e", script, chdir: __dir__)
  unless status.success?
    warn "#{label} failed: #{err}"
    return nil
  end
  lines = out.lines.map(&:strip).reject(&:empty?)
  JSON.parse(lines.last)
end

yjit = run_stats("YJIT", yjit_script, ["--yjit", "--yjit-stats"])
zjit = run_stats("ZJIT", zjit_script, ["--zjit", "--zjit-stats"])

File.delete(WORKLOAD_FILE) if File.exist?(WORKLOAD_FILE)

exit 1 unless yjit && zjit

puts "=== JIT Compilation Stats ==="
puts

header = "%-24s %12s %12s" % ["Metric", "YJIT", "ZJIT"]
puts header
puts "-" * header.length

metrics = {
  "Compiled methods" => "compiled_methods",
  "Compile time"     => "compile_time_ms",
  "Code size"        => "code_size",
  "Side exits"       => "side_exits",
}

metrics.each do |label, key|
  yv = yjit[key]
  zv = zjit[key]

  fmt = ->(v, suffix) {
    case v
    when Float then "%s%s" % [v, suffix]
    when Integer then v.to_s.gsub(/(\d)(?=(\d{3})+$)/, '\1,') + suffix
    else v.to_s
    end
  }

  suffix = key == "compile_time_ms" ? "ms" : key == "code_size" ? "b" : ""
  puts "%-24s %12s %12s" % [label, fmt.(yv, suffix), fmt.(zv, suffix)]
end
