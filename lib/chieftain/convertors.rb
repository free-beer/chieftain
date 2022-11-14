module Chieftain
  # A convertor for boolean values.
  class BooleanConvertor
    VALID_TRUE_VALUES  = ["1", "on", "true", "y", "yes"]
    VALID_FALSE_VALUES = ["0", "false", "n", "no", "off"]
    VALID_VALUES       = VALID_FALSE_VALUES + VALID_TRUE_VALUES

    def convertible?(value)
      [FalseClass, TrueClass].include?(value.class) ||
      VALID_VALUES.include?(value.to_s.downcase)
    end

    def convert(value)
      VALID_TRUE_VALUES.include?(value.to_s.downcase)
    end
  end

  # A convertor floating point values.
  class FloatConvertor
    def convertible?(value)
      value.to_f.to_s == "#{value}"
    end

    def convert(value)
      value.to_f
    end
  end

  # A convertor for integer values.
  class IntegerConvertor
    def convertible?(value)
      value.to_i.to_s == "#{value}"
    end

    def convert(value)
      value.to_i
    end
  end

  # A convertor for string values.
  class StringConvertor
    def convertible?(value)
      true
    end

    def convert(value)
      value.to_s
    end
  end
end
