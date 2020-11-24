module Goodcheck
  def self.logger
    @logger ||= Logger.new(
      STDERR, level: Logger::ERROR,
      formatter: ->(severity, time, progname, msg) { "[#{severity}] #{msg}\n" }
    )
  end
end
