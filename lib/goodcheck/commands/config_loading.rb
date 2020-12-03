module Goodcheck
  module Commands
    module ConfigLoading
      include ExitStatus

      class ConfigFileNotFound < Error
        attr_reader :path

        def initialize(path:)
          super(path.to_s)
          @path = path
        end
      end

      attr_reader :config

      def load_config!(force_download:, cache_path:)
        config_content =
          begin
            config_path.read
          rescue Errno::ENOENT
            raise ConfigFileNotFound.new(path: config_path)
          end

        import_loader = ImportLoader.new(cache_path: cache_path, force_download: force_download, config_path: config_path)
        content = JSON.parse(JSON.dump(YAML.safe_load(config_content, filename: config_path.to_s)), symbolize_names: true)
        loader = ConfigLoader.new(path: config_path, content: content, stderr: stderr, import_loader: import_loader)
        @config = loader.load
      end

      def handle_config_errors(stderr)
        begin
          yield
        rescue ConfigFileNotFound => exn
          stderr.puts "Configuration file not found: #{exn.path}"
          EXIT_ERROR
        rescue Psych::Exception => exn
          stderr.puts "Unexpected error happens while loading YAML file: #{exn.inspect}"
          exn.backtrace.each do |trace_loc|
            stderr.puts "  #{trace_loc}"
          end
          EXIT_ERROR
        rescue StrongJSON::Type::TypeError, StrongJSON::Type::UnexpectedAttributeError => exn
          stderr.puts "Invalid config: #{exn.message}"
          stderr.puts StrongJSON::ErrorReporter.new(path: exn.path).to_s
          EXIT_ERROR
        rescue Errno::ENOENT => exn
          stderr.puts "#{exn}"
          EXIT_ERROR
        end
      end
    end
  end
end
