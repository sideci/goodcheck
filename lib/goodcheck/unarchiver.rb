module Goodcheck
  class Unarchiver
    attr_reader :file_filter

    def initialize(file_filter: ->(_filename) { true })
      @file_filter = file_filter
    end

    def tar_gz?(filename)
      name = filename.to_s.downcase
      ext = ".tar.gz"
      name.end_with?(ext) && name != ext
    end

    def tar_gz(content)
      require "rubygems/package"

      Gem::Package::TarReader.new(StringIO.new(gz(content))) do |tar_reader|
        tar_reader.each do |file|
          if file.file? && file_filter.call(file.full_name)
            yield file.read, file.full_name
          end
        end
      end
    end

    private

    def gz(content)
      require "zlib"

      io = Zlib::GzipReader.new(StringIO.new(content))
      begin
        io.read
      ensure
        io.close
      end
    end
  end
end
