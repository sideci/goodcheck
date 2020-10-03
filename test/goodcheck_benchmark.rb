require "minitest/autorun"
require "minitest/benchmark"
require "net/http"
require "tempfile"

require "goodcheck"
require "goodcheck/cli"

class GoodcheckBenchmark < Minitest::Benchmark
  def self.bench_range
    bench_exp 1, 100_000
  end

  def bench_cli_check
    assert_performance_linear 0.9 do |n|
      Goodcheck::CLI.new(stdout: $stdout, stderr: $stderr).run(["check", *create_sample_files(n)])
    end
  end

  private

  def create_sample_files(n)
    @sample_file_content ||= Net::HTTP.get(URI("https://raw.githubusercontent.com/ruby/ruby/0256e4f0f5e10f0a15cbba2cd64e252dfa864e4a/gc.c"))

    n.times.map do
      Tempfile.new("goodcheck-benchmark-")
        .tap { |f| f.write(@sample_file_content) }
        .to_path
    end
  end
end
