module Goodcheck
  class Config
    DEFAULT_EXCLUDE_BINARY = false

    # https://www.iana.org/assignments/media-types/media-types.xhtml
    BINARY_MIME_TYPES = %w[
      audio
      font
      image
      model
      multipart
      video
    ].to_set.freeze
    BINARY_MIME_FULLTYPES = %w[
      application/gzip
      application/illustrator
      application/pdf
      application/zip
    ].to_set.freeze

    attr_reader :rules
    attr_reader :exclude_paths
    attr_reader :exclude_binary
    alias exclude_binary? exclude_binary

    def initialize(rules:, exclude_paths:, exclude_binary: DEFAULT_EXCLUDE_BINARY)
      @rules = rules
      @exclude_paths = exclude_paths
      @exclude_binary = exclude_binary.nil? ? DEFAULT_EXCLUDE_BINARY : exclude_binary
    end

    def each_rule(filter:, &block)
      if block_given?
        if filter.empty?
          rules.each(&block)
        else
          rules.each do |rule|
            if filter.any? {|rule_id| rule.id == rule_id || rule.id.start_with?("#{rule_id}.") }
              yield rule
            end
          end
        end
      else
        enum_for :each_rule, filter: filter
      end
    end

    def rules_for_path(path, rules_filter:)
      if block_given?
        each_rule(filter: rules_filter).map do |rule|
          rule.triggers.each do |trigger|
            globs = trigger.globs

            if globs.empty?
              yield [rule, nil, trigger]
            else
              glob = globs.find {|glob| glob.test(path) }
              if glob
                yield [rule, glob, trigger]
              end
            end
          end
        end
      else
        enum_for(:rules_for_path, path, rules_filter: rules_filter)
      end
    end

    def exclude_path?(path)
      excluded = exclude_paths.any? do |pattern|
        path.fnmatch?(pattern, File::FNM_PATHNAME | File::FNM_EXTGLOB)
      end

      return true if excluded
      return excluded unless exclude_binary?
      return excluded unless path.file?

      exclude_file_by_mime_type?(path)
    end

    private

    def exclude_file_by_mime_type?(file)
      # NOTE: Lazy load to save memory
      require "marcel"

      fulltype = Marcel::MimeType.for(file)
      type, subtype = fulltype.split("/")

      case
      when subtype.end_with?("+xml") # e.g. "image/svg+xml"
        false
      when BINARY_MIME_TYPES.include?(type)
        Goodcheck.logger.debug "Exclude file: #{file} (#{fulltype})"
        true
      when BINARY_MIME_FULLTYPES.include?(fulltype)
        Goodcheck.logger.debug "Exclude file: #{file} (#{fulltype})"
        true
      else
        false
      end
    end
  end
end
