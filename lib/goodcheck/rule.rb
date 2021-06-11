module Goodcheck
  class Rule
    attr_reader :id
    attr_reader :triggers
    attr_reader :message
    attr_reader :justifications
    attr_reader :severity

    def initialize(id:, triggers:, message:, justifications:, severity: nil)
      @id = id
      @triggers = triggers
      @message = message
      @justifications = justifications
      @severity = severity
    end
  end
end
