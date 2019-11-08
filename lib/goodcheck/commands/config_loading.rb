module Goodcheck
  module Commands
    module ConfigLoading
      attr_reader :config

      def load_config!(force_download:, cache_path:)
        import_loader = ImportLoader.new(cache_path: cache_path, force_download: force_download, config_path: config_path)
        content = JSON.parse(JSON.dump(YAML.load(config_path.read, filename: config_path.to_s)), symbolize_names: true)
        loader = ConfigLoader.new(path: config_path, content: content, stderr: stderr, import_loader: import_loader)
        @config = loader.load
      end

      def handle_config_errors(stderr)
        begin
          yield

        rescue Psych::Exception => exn
          stderr.puts "Unexpected error happens while loading YAML file: #{exn.inspect}"
          exn.backtrace.each do |trace_loc|
            stderr.puts "  #{trace_loc}"
          end
          1
        rescue StrongJSON::Type::TypeError, StrongJSON::Type::UnexpectedAttributeError => exn
          stderr.puts "Invalid config: #{exn.message}"
          stderr.puts StrongJSON::ErrorReporter.new(path: exn.path).to_s
          1
        rescue Errno::ENOENT => exn
          stderr.puts "#{exn}"
          1
        end
      end
    end
  end
end
