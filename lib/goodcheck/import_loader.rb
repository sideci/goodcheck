module Goodcheck
  class ImportLoader
    class UnexpectedSchemaError < StandardError
      attr_reader :uri

      def initialize(uri)
        @uri = uri
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
      when nil, "file"
        load_file uri, &block
      when "http", "https"
        load_http uri, &block
      else
        raise UnexpectedSchemaError.new("Unexpected URI schema: #{uri.class.name}")
      end
    end

    def load_file(uri)
      path = (config_path.parent + uri.path)

      begin
        yield path.read
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
        Goodcheck.logger.debug "Downloaded content: #{content[0, 1024].inspect}#{content.size > 1024 ? "..." : ""}"
        yield content
        write_cache uri, content
      else
        Goodcheck.logger.info "Reading content from cache..."
        yield path.read
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
  end
end
