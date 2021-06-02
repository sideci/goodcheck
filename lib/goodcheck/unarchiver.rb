module Goodcheck
  class Unarchiver
    def tar_gz?(filename)
      name = filename.to_s.downcase
      ext = ".tar.gz"
      name.end_with?(ext) && name != ext
    end

    def tar_gz(content)
      require "rubygems/package"

      Gem::Package::TarReader.new(StringIO.new(gz(content))) do |tar_reader|
        tar_reader.each do |file|
          if file.file?
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
