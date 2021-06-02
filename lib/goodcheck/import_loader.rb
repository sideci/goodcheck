module Goodcheck
  class ImportLoader
    class UnexpectedSchemaError < Error
      attr_reader :uri

      def initialize(uri)
        super("Unexpected URI schema: #{uri.scheme}")
        @uri = uri
      end
    end

    class FileNotFound < Error
      attr_reader :path

      def initialize(path)
        super("No such a file: #{path}")
        @path = path
      end
    end

    attr_reader :cache_path
    attr_reader :expires_in
    attr_reader :force_download
    attr_reader :config_path

    def initialize(cache_path:, expires_in: 3 * 60, force_download:, config_path:)
      @cache_path = cache_path
      @expires_in = expires_in
      @force_download = force_download
      @config_path = config_path
    end

    def load(name, &block)
      uri = URI.parse(name)

      case uri.scheme
      when nil
        load_file name, &block
      when "file"
        load_file uri.path, &block
      when "http", "https"
        load_http uri, &block
      else
        raise UnexpectedSchemaError.new(uri)
      end
    end

    def load_file(path)
      files = Pathname.glob(File.join(config_path.parent.to_path, path), File::FNM_DOTMATCH | File::FNM_EXTGLOB).sort
      if files.empty?
        raise FileNotFound.new(path)
      else
        files.each do |file|
          Goodcheck.logger.info "Reading file: #{file}"
          content = file.read
          if unarchiver.tar_gz?(file)
            unarchiver.tar_gz(content) do |content, filename|
              yield content, filename
            end
          else
            yield content, file.to_path
          end
        end
      end
    end

    def cache_name(uri)
      Digest::SHA2.hexdigest(uri.to_s)
    end

    def load_http(uri)
      hash = cache_name(uri)
      path = cache_path + hash

      Goodcheck.logger.info "Calculated cache name: #{hash}"

      download = false

      if force_download
        Goodcheck.logger.debug "Downloading: force flag"
        download = true
      end

      if !download && !path.file?
        Goodcheck.logger.debug "Downloading: no cache found"
        download = true
      end

      if !download && path.mtime + expires_in < Time.now
        Goodcheck.logger.debug "Downloading: cache expired"
        download = true
      end

      if download
        path.rmtree if path.exist?
        Goodcheck.logger.info "Downloading content..."
        content = http_get uri
        if unarchiver.tar_gz?(uri.path)
          unarchiver.tar_gz(content) do |content, filename|
            yield content, filename
            write_cache "#{uri}/#{filename}", content
          end
        else
          yield content, uri.path
          write_cache uri, content
        end
      else
        Goodcheck.logger.info "Reading content from cache..."
        yield path.read, path.to_path
      end
    end

    def write_cache(uri, content)
      path = cache_path + cache_name(uri)
      path.write(content)
    end

    # @see https://ruby-doc.org/stdlib-2.7.0/libdoc/net/http/rdoc/Net/HTTP.html#class-Net::HTTP-label-Following+Redirection
    def http_get(uri, limit = 10)
      raise ArgumentError, "Too many HTTP redirects" if limit == 0

      res = Net::HTTP.get_response URI(uri)
      case res
      when Net::HTTPSuccess
        res.body
      when Net::HTTPRedirection
        location = res['Location']
        http_get location, limit - 1
      else
        raise "Error: HTTP GET #{uri.inspect} #{res.inspect}"
      end
    end

    private

    def unarchiver
      @unarchiver ||= Unarchiver.new
    end
  end
end
