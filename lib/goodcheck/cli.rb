require "optparse"

module Goodcheck
  class CLI
    attr_reader :stdout
    attr_reader :stderr

    def initialize(stdout:, stderr:)
      @stdout = stdout
      @stderr = stderr
    end

    COMMANDS = {
      init: "Generate a sample configuration file",
      check: "Run check with a configuration",
      test: "Test your configuration",
      version: "Print version",
      help: "Show goodcheck version and quit"
    }


    def run(args)
      command = args.shift&.to_sym

      if COMMANDS.key?(command)
        __send__(command, args)
      else
        help(args)
      end
    rescue => exn
      stderr.puts exn.inspect
      exn.backtrace.each do |bt|
        stderr.puts "  #{bt}"
      end
      1
    end

    def check(args)
      config_path = Pathname("goodcheck.yml")
      targets = []
      rules = []
      format = nil

      OptionParser.new("Usage: goodcheck check [options] dirs...") do |opts|
        opts.on("-c CONFIG", "--config=CONFIG") do |config|
          config_path = Pathname(config)
        end
        opts.on("-R RULE", "--rule=RULE") do |rule|
          rules << rule
        end
        opts.on("--format=<text|json> [default: 'text']") do |f|
          format = f
        end
      end.parse!(args)

      if args.empty?
        Dir.glob("**/*").select do |fname|
          Pathname(fname).file? && !Pathname(fname).symlink?
          end.map { |arg| targets.push Pathname(arg) }
      else
        targets.push *args.map {|arg| Pathname(arg) }
      end

      reporter = case format
                 when "text", nil
                   Reporters::Text.new(stdout: stdout)
                 when "json"
                   Reporters::JSON.new(stdout: stdout, stderr: stderr)
                 else
                   stderr.puts "Unknown format: #{format}"
                   return 1
                 end

      Commands::Check.new(reporter: reporter, config_path: config_path, rules: rules, targets: targets, stderr: stderr).run
    end

    def test(args)
      config_path = Pathname("goodcheck.yml")

      OptionParser.new("Usage: goodcheck test [options]") do |opts|
        opts.on("-c CONFIG", "--config=CONFIG") do |config|
          config_path = Pathname(config)
        end
      end.parse!(args)

      Commands::Test.new(stdout: stdout, stderr: stderr, config_path: config_path).run
    end

    def init(args)
      config_path = Pathname("goodcheck.yml")
      force = false

      OptionParser.new("Usage: goodcheck init [options]") do |opts|
        opts.on("-c CONFIG", "--config=CONFIG") do |config|
          config_path = Pathname(config)
        end
        opts.on("--force") do
          force = true
        end
      end.parse!(args)

      Commands::Init.new(stdout: stdout, stderr: stderr, path: config_path, force: force).run
    end

    def version(args)
      stdout.puts "goodcheck #{VERSION}"
      0
    end

    def help(args)
      stdout.puts "Usage: goodcheck <command> [options] [args...]"
      stdout.puts ""
      stdout.puts "Commands:"
      COMMANDS.each do |c, msg|
        stdout.puts "  goodcheck #{c}\t#{msg}"
      end
      0
    end
  end
end
