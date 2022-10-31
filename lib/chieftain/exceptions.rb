module Chieftain
  # The root exception class used by the Chieftain class hierarchy.
  class CommandError < StandardError
    def initialize(message)
      super(message)
    end
  end

  # A command error class relating specifically to a parameter.
  class ParameterError < CommandError
    def initialize(message, parameter)
      super(message)
      @parameter = parameter
    end
    attr_reader :parameter
  end
end
