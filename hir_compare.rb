require "open3"

SAMPLES = [
  {
    label: "型特殊化 (Type Specialization)",
    target: "add",
    code: <<~'RUBY',
      def add(a, b); a + b; end
      100.times { add(1, 2) }
    RUBY
  },
  {
    label: "冗長ロード除去 (Load Elimination)",
    target: "compute",
    code: <<~'RUBY',
      class Point
        def initialize; @x = 1; @y = 2; end
        def compute; @x + @y + @x * @y; end
      end
      p = Point.new
      100.times { p.compute }
    RUBY
  },
  {
    label: "定数畳み込み + DCE (Constant Fold + DCE)",
    target: "heavy",
    code: <<~'RUBY',
      def heavy(x)
        a = 2 + 1; b = a * 10; c = b + 7
        dead = a * b * c
        x + c
      end
      100.times { heavy(42) }
    RUBY
  },
  {
    label: "Cメソッドインライン (C Method Inline)",
    target: "succ_chain",
    code: <<~'RUBY',
      def succ_chain(n); n.succ.succ.succ; end
      100.times { succ_chain(0) }
    RUBY
  },
]

def extract_fn(output, fn_name)
  lines = output.lines
  result = []
  capturing = false

  lines.each do |line|
    if line.match?(/^fn #{Regexp.escape(fn_name)}[\s@(]/)
      capturing = true
      result << line
    elsif capturing
      break if line.match?(/^fn\s/)
      result << line
    end
  end

  result.empty? ? "  (該当関数が見つかりません)\n" : result.join
end

def run_zjit(code, *flags)
  out, err, = Open3.capture3("ruby", "--zjit", *flags, "-e", code)
  out + "\n" + err
end

puts "=== ZJIT HIR 最適化比較 (#{RUBY_DESCRIPTION}) ==="
puts

SAMPLES.each do |sample|
  puts "=" * 60
  puts "  #{sample[:label]}"
  puts "=" * 60

  before = run_zjit(sample[:code], "--zjit-dump-hir-init")
  after  = run_zjit(sample[:code], "--zjit-dump-hir")

  puts "\n--- 最適化前 HIR ---"
  puts extract_fn(before, sample[:target])

  puts "--- 最適化後 HIR ---"
  puts extract_fn(after, sample[:target])

  puts
end
