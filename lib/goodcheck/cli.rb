require "optparse"

Version = Goodcheck::VERSION

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
      pattern: "Print regexp for rules",
      version: "Print version",
      help: "Show help and quit"
    }


    def run(args)
      command = args.shift&.to_sym

      if COMMANDS.key?(command)
        __send__(command, args)
      elsif command == :"--version"
        version(args)
      else
        stderr.puts "Invalid command: #{command}" if command
        help(args)
        1
      end
    rescue => exn
      stderr.puts exn.inspect
      exn.backtrace.each do |bt|
        stderr.puts "  #{bt}"
      end
      1
    end

    def home_path
      if (path = ENV["GOODCHECK_HOME"])
        Pathname(path)
      else
        Pathname(Dir.home) + ".goodcheck"
      end
    end

    def check(args)
      config_path = Pathname("goodcheck.yml")
      targets = []
      rules = []
      format = nil
      loglevel = Logger::ERROR
      force_download = false

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
        opts.on("-v", "--verbose") do
          loglevel = Logger::INFO
        end
        opts.on("-d", "--debug") do
          loglevel = Logger::DEBUG
        end
        opts.on("--force") do
          force_download = true
        end
      end.parse!(args)

      Goodcheck.logger.level = loglevel

      if args.empty?
        targets << Pathname(".")
      else
        args.each {|arg| targets << Pathname(arg) }
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

      Goodcheck.logger.info "Configuration = #{config_path}"
      Goodcheck.logger.info "Rules = [#{rules.join(", ")}]"
      Goodcheck.logger.info "Format = #{format}"
      Goodcheck.logger.info "Targets = [#{targets.join(", ")}]"
      Goodcheck.logger.info "Force download = #{force_download}"
      Goodcheck.logger.info "Home path = #{home_path}"

      Commands::Check.new(reporter: reporter, config_path: config_path, rules: rules, targets: targets, stderr: stderr, force_download: force_download, home_path: home_path).run
    end

    def test(args)
      config_path = Pathname("goodcheck.yml")
      loglevel = Logger::ERROR
      force_download = false

      OptionParser.new("Usage: goodcheck test [options]") do |opts|
        opts.on("-c CONFIG", "--config=CONFIG") do |config|
          config_path = Pathname(config)
        end
        opts.on("-v", "--verbose") do
          loglevel = Logger::INFO
        end
        opts.on("-d", "--debug") do
          loglevel = Logger::DEBUG
        end
        opts.on("--force") do
          force_download = true
        end
      end.parse!(args)

      Goodcheck.logger.level = loglevel

      Goodcheck.logger.info "Configuration = #{config_path}"
      Goodcheck.logger.info "Force download = #{force_download}"
      Goodcheck.logger.info "Home path = #{home_path}"

      Commands::Test.new(stdout: stdout, stderr: stderr, config_path: config_path, force_download: force_download, home_path: home_path).run
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

    def pattern(args)
      config_path = Pathname("goodcheck.yml")

      OptionParser.new("Usage: goodcheck pattern [options] ids...") do |opts|
        opts.on("-c CONFIG", "--config=CONFIG") do |config|
          config_path = Pathname(config)
        end
      end.parse!(args)

      Commands::Pattern.new(stdout: stdout, stderr: stderr, path: config_path, ids: Set.new(args), home_path: home_path).run
    end
  end
end
