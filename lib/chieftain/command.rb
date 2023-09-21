require "ostruct"

module Chieftain
  # An implementation of the Command design pattern that aims to take some
  # advantage of Ruby's enhanced capabilities.
  class Command
    # The type associated with errors that prevent a Command from executing.
    class Error
      def initialize(message, code=nil)
        @code    = code
        @message = message
      end
      attr_reader :code, :message
      alias :to_s :message

      def to_s
      end
    end

    # The type returned by a Command class when it is executed.
    class Result
      def initialize(value, errors=[])
        @errors = errors
        @value  = value
      end
      attr_reader :errors, :value

      def error_codes
        errors.map(&:code)
      end

      def error_messages
        errors.map(&:message)
      end

      def failed?
        !success?
      end
      alias :error? :failed?

      def success?
        errors.empty?
      end
    end

    @@convertors = {self => {}}
    @@parameters = {self => {}}
    @@validators = {self => {}}

    def initialize(parameters={})
      @convertors = Command.convertors_for(self.class)
      @errors     = []
      @parameters = {}.merge(parameters).inject({}) {|t,v| t[v[0].to_s.to_sym] = v[1]; t}
      @settings   = Command.parameters(self.class)
      @validators = Command.validators_for(self.class)
    end
    attr_reader :convertors, :errors, :parameters, :settings, :validators

    # Test whether a given value is convertible for a named parameter. This will
    # return true if the parameter is expected and either has no type specified
    # or the value given can be converted to the parameters specified type.
    def convertible?(name, value)
      result = false
      if expects?(name)
        result   = true
        settings = @settings[name]
        if settings.type
          result = get_convertor(settings.type).convertible?(value)
        end
      end
      result
    end

    # Register an error with the execution of the current Command.
    def error(message, code=nil)
      @errors << Error.new(message, code)
    end

    # Invokes the #perform() method if and only if the Command instance tests as
    # valid. This method should be the one invoked to run a Command instance.
    def execute
      @errors = []
      value   = nil
      value = perform if valid?
      Result.new(value, errors)
    end

    # Returns a list of the expected parameters configured for a Command
    # instance.
    def expected_parameter_names
      @settings ? @settings.values.map(&:name) : []
    end

    # Tests whether a parameter name is among the parameters specified for the
    # Command instance.
    def expects?(parameter)
      expected_parameter_names.include?(parameter)
    end

    # Retrieve the value for a named parameter. The value will be run through an
    # applicable converted prior to being returned. An exception will be raised
    # if conversion fails. If the parameter is optional and has not be specified
    # then conversion will not be attempted and nil will be returned.
    def get_parameter_value(name)
      if expects?(name)
        settings = settings_for(name)
        if settings[:required] && !provided?(name)
          raise ParameterError.new("A value has not been provided for the '#{name}' parameter.", name)
        end

        if settings[:required]
          raw_value = get_raw_parameter_value(name)
          if settings[:type]
            convertor = get_convertor(settings.type)
            if !convertor.convertible?(raw_value)
              raise ParameterError.new("The value of the '#{name}' parameter cannot be converted to the '#{settings.type}' type.", name)
            end
            convertor.convert(raw_value)
          else
            raw_value
          end

        else
          raw_value = nil
          if provided?(name)
            raw_value = get_raw_parameter_value(name)
            raw_value = settings[:default] if raw_value.nil?
          else
            raw_value = settings[:default]
          end

          if provided?(name)
            if settings[:type]
              convertor = get_convertor(settings.type)
              if !convertor.convertible?(raw_value)
                raise ParameterError.new("The value of the '#{name}' parameter cannot be converted to the '#{settings.type}' type.", name)
              end
              convertor.convert(raw_value)
            else
              raw_value
            end
          else
            raw_value
          end
        end
      else
        raise ParameterError.new("Unknown parameter '#{name}' requested from a '#{self.class.name}' command instance.")
      end
    end

    # Fetches a name convertor from the list for the Command instance, raises
    # an exception if one cannot be found.
    def get_convertor(type)
      if !has_convertor?(type)
        raise CommandError.new("Unable to locate the '#{type}' parameter convertor.")
      end
      @convertors[type]
    end

    # Fetches the raw, unaltered value specified for a name parameter to the
    # Command instance. Returns nil if the specified parameter has not been
    # given an explicit value. Raises an exception if an unknown parameter is
    # specified.
    def get_raw_parameter_value(name)
      raise ParameterError.new("Unknown parameter '#{name}' requested in command.", name) if !expects?(name)
      @parameters[name]
    end

    # This method tests whether a named convertor is available to a Command
    # instance.
    def has_convertor?(name)
      @convertors.include?(name)
    end

    # An implementation of the #method_missing method for the Command class that
    # checks whether a parameter is being requested and, if so, returns it's value
    # or delegates handling to the parent class implementation.
    def method_missing(name, *arguments, &block)
      if expects?(name)
        get_parameter_value(name)
      else
        super
      end
    end

    # Returns a list of the names of the commands optional parameters.
    def optional_parameter_names
      settings.values.filter {|p| !p.required}.map(&:name)
    end

    # Returns a list of the names of the parameters specified to the Command
    # instance.
    def parameter_names
      @settings.keys
    end

    # Derived command classes should override this method to do the work for the
    # command. This method will only get invoked if the command is valid. This
    # default implementation raises an exception.
    def perform
      raise CommandError.new("The #{self.class.name} command class has not overridden the #perform() method.")
    end

    # This method checks whether a name parameter is among those provided to a
    # Command instance.
    def provided?(name)
      @parameters.include?(name)
    end

    # Returns a list of the names of the commands required parameters. Note a
    # required parameter must have a value specified for it when the command
    # is executed.
    def required_parameter_names
      settings.values.filter {|p| p.required}.map(&:name)
    end

    # Retrieves the parameter settings for a named parameter. Raises an
    # exception if an unknown parameter is specified.
    def settings_for(name)
      raise ParameterError("Unknown parameter '#{name}' requested in command.", name) if !expects?(name)
      entry = @settings.find {|entry| entry[1].name == name}
      entry ? entry[1] : nil
    end

    # Performs validation of the parameters passed to a command. Deriving classes
    # should ensure this method is invoked in any custom #validate method their
    # class provides.
    def validate
      @settings.values.each do |parameter|
        if provided?(parameter.name)
          if parameter.type
            # Check conversion.
            if has_convertor?(parameter.type)
              convertor = get_convertor(parameter.type)
              if !convertor.convertible?(get_raw_parameter_value(parameter.name))
                error("The value of the '#{parameter.name}' parameter cannot be converted to the '#{parameter.type}' type.")
              end
            else
              error("Invalid type '#{parameter.type}' specified for the '#{parameter.name}' parameter.")
            end
          end

          # Run validations.
          if convertible?(parameter.name, get_raw_parameter_value(parameter.name))
            value = get_parameter_value(parameter.name)
            validations_for(parameter.name).each do |validation|
              self.instance_exec(parameter.name, value, &validation)
            end
          else
            error("The value of the '#{parameter.name}' parameter cannot be converted to the '#{parameter.type}' type.")
          end
        else
          if parameter.required
            error("No value specified for the '#{parameter.name}' required parameter.")
          end
        end
      end
    end

    # Invokes the validate command and then checks that there are no errors
    # registered for the command.
    def valid?
      @errors = []
      validate
      @errors.empty?
    end

    # Returns a list of the validators that apply to a named parameter. This
    # will be a combination of validators explicitly declared on the parameter
    # and class validators with the same name as the parameter. The method
    # raises an exception if given the name of a parameter that the Command
    # instance does not expect. It can also raise an exception if a parameter
    # has an unknown validator specified for it.
    def validations_for(name)
      if !expects?(name)
        raise ParameterError.new("Validators requested for unknown parameter '#{name}'.", name)
      end
      settings = @settings[name]
      names    = []
      names << name if @validators.include?(name)
      names = names.concat(settings.validations) if settings.validations
      names.uniq.map do |key|
        if !@validators.include?(key)
          raise ParameterError.new("Unknown validation '#{key}' requested for the '#{name}' parameter.", name)
        end
        @validators[key]
      end
    end

    # Registers a convertor for a Command class. A convertor is any class that
    # can be constructed using a default constructor and responds to the
    # #convertible?() and #convert() methods. Both of these methods take a
    # single parameter which is the value to undergo conversion. The
    # #convertible?() method returns true if it's possible to convert the value
    # to the convertors output type. The #convert() method performs the actual
    # conversion, returning the result.
    def self.add_convertor(name, convertor_class)
      @@convertors[self] = {} if !@@convertors.include?(self)
      if @@convertors[self].include?(name)
        raise CommandError.new("Duplicate convertor '#{name}' specified for the #{self.name} class.")
      end

      @@convertors[self][name] = convertor_class
    end

    # Registers a validator for a Command class. A validator has to be registered
    # with a block that will be invoked for the relevant parameters. This block
    # should take 3 parameters. The first is the command object being executed.
    # The second is the name of the parameter being validated. The third is the
    # value of the parameter being validated. Validators can register errors by
    # invoking the #error() method on the command they are passed.
    def self.add_validator(name, &block)
      @@validators[self] = {} if !@@validators.include?(self)
      if @@validators[self].include?(name)
        raise CommandError.new("Duplicate validator '#{name}' specified for the #{self.name} class.")
      end

      if !block
        raise CommandError.new("No block specified for the '#{name}' validator in the #{self.name} class.")
      end

      @@validators[self][name] = block
    end

    # This method scans the class hierarchy for a Command instance and assembles
    # a list of the registered convertors for it. Convertors registered in classes
    # lower in the hierarchy (i.e. derived classes) override those registered in
    # parent classes.
    def self.convertors_for(command_class)
      hierarchy = [command_class]
      while !hierarchy.last.superclass.nil?
        hierarchy << hierarchy.last.superclass
      end

      convertors = {}
      hierarchy.reverse.each do |c|
        convertors.merge!(@@convertors[c]) if @@convertors.include?(c)
      end
      convertors.inject({}) {|list, entry| list[entry[0]] = entry[1].new; list}
    end

    # Registers an optional parameter for the command. See the #parameter() method
    # for details of the parameters this method accepts.
    def self.optional(name, settings={}, &block)
      parameter(name, {}.merge(settings, {required: false}), &block)
    end

    # Register a new parameter for a Command class. The first method parameter
    # specifies the new parameters name. This can be followed by a Hash of
    # settings value for the parameter. All keys in this Hash should be symbols
    # and the following keys are currently recognised - :required, :types and
    # :validators. You can also register a block for a parameter. This block
    # will be invoked with the raw parameter value and the return value from this
    # block will become the actual parameter value used.
    def self.parameter(name, settings={}, &block)
      if self.method_defined?(name)
        raise ParameterError.new("The '#{name}' parameter clashes with an existing class method.", name)
      end
      @@parameters[self]       = {} if !@@parameters.include?(self)
      @@parameters[self][name] = OpenStruct.new({}.merge(settings, {name: name, block: block}))
    end

    # Fetches the parameter list registered for a specific Command class
    # instance.
    def self.parameters(command_class)
      @@parameters[command_class] || {}
    end

    # Registers an optional parameter for the command. See the #parameter() method
    # for details of the parameters this method accepts.
    def self.required(name, settings={}, &block)
      parameter(name, {}.merge(settings, {required: true}), &block)
    end

    # A synomym for the #add_validator() method that is intended for use with
    # a validator that matches a parameter name.
    def self.validate(name, &block)
      add_validator(name, &block)
    end

    # This method scans the class hierarchy for a Command instance and assembles
    # a list of the registered validators for it. Validators registered in classes
    # lower in the hierarchy (i.e. derived classes) override those registered in
    # parent classes.
    def self.validators_for(command_class)
      hierarchy = [command_class]
      while !hierarchy.last.superclass.nil?
        hierarchy << hierarchy.last.superclass
      end

      validators = {}
      hierarchy.reverse.each do |c|
        validators.merge!(@@validators[c]) if @@validators.include?(c)
      end
      validators
    end

    # ----------------------------------------------------------------------------
    # Add default library validators
    # ----------------------------------------------------------------------------
    add_validator(:not_blank) do |name, value|
      if [nil, ""].include?("#{value}".strip)
        error("Blank value specified for the '#{name}' parameter.")
      end
    end

    add_validator(:not_nil) do |name, value|
      error("Nil value specified for the '#{name}' parameter.") if value.nil?
    end

    # ----------------------------------------------------------------------------
    # Add default library convertors
    # ----------------------------------------------------------------------------
    add_convertor :boolean, Chieftain::BooleanConvertor
    add_convertor :float, Chieftain::FloatConvertor
    add_convertor :integer, Chieftain::IntegerConvertor
    add_convertor :string, Chieftain::StringConvertor
  end
end