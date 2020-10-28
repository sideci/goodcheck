module Goodcheck
  class Glob
    FNM_FLAGS = File::FNM_PATHNAME | File::FNM_EXTGLOB | File::FNM_DOTMATCH

    attr_reader :pattern
    attr_reader :encoding
    attr_reader :exclude

    def initialize(pattern:, encoding:, exclude:)
      @pattern = pattern
      @encoding = encoding
      @exclude = exclude
    end

    def test(path)
      path.fnmatch?(pattern, FNM_FLAGS) && !excluded?(path)
    end

    def ==(other)
      other.is_a?(Glob) &&
        other.pattern == pattern &&
        other.encoding == encoding &&
        other.exclude == exclude
    end

    private

    def excluded?(path)
      Array(exclude).any? { |exc| path.fnmatch?(exc, FNM_FLAGS) }
    end
  end
end
