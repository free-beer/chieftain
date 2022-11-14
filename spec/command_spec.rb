require "spec_helper"

describe Chieftain::Command do
  describe "#convertible?()" do
    subject {
      class ConvertibleTest < Chieftain::Command
        optional :booler, type: :boolean
        optional :floater, type: :float
        optional :number, type: :integer
      end
      ConvertibleTest.new
    }

    it "returns true for values that can be dealt with by built in convertors" do
      expect(subject.convertible?(:booler, "On")).to eq(true)
      expect(subject.convertible?(:floater, "3.14")).to eq(true)
      expect(subject.convertible?(:number, "1234")).to eq(true)
    end

    it "returns false for values that cannot be dealt with by built in convertors" do
      expect(subject.convertible?(:booler, "ningy")).to eq(false)
      expect(subject.convertible?(:floater, "#=")).to eq(false)
      expect(subject.convertible?(:number, "blah")).to eq(false)
    end

    it "returns false for parameters that do not exist" do
      expect(subject.convertible?(:nope, "ningy")).to eq(false)
    end
  end

  describe "#error() & #errors()" do
    subject {
      class ErrorTest < Chieftain::Command
      end
      ErrorTest.new
    }

    it "sets an error on the command" do
      subject.error("This is an error message!")
      expect(subject.errors.map(&:message)).to include("This is an error message!")
    end
  end

  describe "#expected_parameter_names()" do
    subject {
      class ExpectedParameterNamesTest < Chieftain::Command
        optional :booler, type: :boolean
        required :floater, type: :float
        optional :number, type: :integer
      end
      ExpectedParameterNamesTest.new
    }

    it "returns an array of the parameter names configured" do
      names = subject.expected_parameter_names
      expect(names.class).to eq(Array)
      expect(names.length).to eq(3)
      expect(names).to include(:booler)
      expect(names).to include(:floater)
      expect(names).to include(:number)
    end
  end

  describe "#expects?()" do
    subject {
      class ExpectsTest < Chieftain::Command
        optional :booler, type: :boolean
        required :floater, type: :float
        optional :number, type: :integer
      end
      ExpectsTest.new
    }

    it "returns true for configured parameter names" do
      expect(subject.expects?(:booler)).to eq(true)
      expect(subject.expects?(:floater)).to eq(true)
      expect(subject.expects?(:number)).to eq(true)
    end

    it "returns false for names that are not configured" do
      expect(subject.expects?(:other)).to eq(false)
    end
  end

  describe "#get_parameter_value()" do
    subject {
      class GetParameterValueTest < Chieftain::Command
        optional :booler, type: :boolean
        required :floater, type: :float
        optional :number, type: :integer
        required :missing, type: :string
      end
      GetParameterValueTest.new(floater: "3.14", number: "314")
    }

    it "returns an appropriate value for available values" do
      expect(subject.get_parameter_value(:floater)).to eq(3.14)
      expect(subject.get_parameter_value(:number)).to eq(314)
    end

    it "returns nil for optional parameters that have not been specified" do
      expect(subject.get_parameter_value(:booler)).to be_nil
    end

    it "raises an exception for required parameters that have not been specified" do
      expect {
        subject.get_parameter_value(:missing)
      }.to raise_error(Chieftain::ParameterError, "A value has not been provided for the 'missing' parameter.")
    end

    describe "when given unconvertible parameter values" do
      subject {
        class GetParameterValueUnconvertibleTest < Chieftain::Command
          required :floater, type: :float
          optional :number, type: :integer
        end
        GetParameterValueUnconvertibleTest.new(floater: "blah", number: "ningy")
      }

      it "raises an exception for required parameters" do
        expect {
          subject.get_parameter_value(:floater)
        }.to raise_error(Chieftain::ParameterError, "The value of the 'floater' parameter cannot be converted to the 'float' type.")
      end

      it "raises an exception for optional parameters" do
        expect {
          subject.get_parameter_value(:number)
        }.to raise_error(Chieftain::ParameterError, "The value of the 'number' parameter cannot be converted to the 'integer' type.")
      end
    end
  end

  describe "#get_convertor()" do
    subject {
      class GetConvertorTest < Chieftain::Command
        required :booler, type: :boolean
        required :floater, type: :float
        optional :number, type: :integer
        optional :other
      end
      GetConvertorTest.new()
    }

    it "returns a convertor of the appropriate type" do
      expect(subject.get_convertor(:boolean)).to be_instance_of(Chieftain::BooleanConvertor)
      expect(subject.get_convertor(:float)).to be_instance_of(Chieftain::FloatConvertor)
      expect(subject.get_convertor(:integer)).to be_instance_of(Chieftain::IntegerConvertor)
      expect(subject.get_convertor(:string)).to be_instance_of(Chieftain::StringConvertor)
    end

    it "raises an exception for unknown types" do
      expect {
        subject.get_convertor(:blah)
      }.to raise_error(Chieftain::CommandError, "Unable to locate the 'blah' parameter convertor.")
    end
  end

  describe "#get_raw_parameter_value()" do
    subject {
      class GetRawParameterValueTest < Chieftain::Command
        required :booler, type: :boolean
        required :floater, type: :float
        optional :number, type: :integer
        optional :other
      end
      GetRawParameterValueTest.new(booler: "OFF", floater: "3.14", number: "1234")
    }

    it "returns the raw parameter value for available values" do
      expect(subject.get_raw_parameter_value(:booler)).to eq("OFF")
      expect(subject.get_raw_parameter_value(:floater)).to eq("3.14")
      expect(subject.get_raw_parameter_value(:number)).to eq("1234")
    end

    it "returns nil for parameter values that are not specified" do
      expect(subject.get_raw_parameter_value(:other)).to be_nil
    end

    it "raises an exception if an unknown parameter is requested" do
      expect {
        subject.get_raw_parameter_value(:ningy)
      }.to raise_error(Chieftain::ParameterError, "Unknown parameter 'ningy' requested in command.")
    end
  end

  describe "#has_convertor?()" do
    subject {
      class HasConvertorTest < Chieftain::Command
      end
      HasConvertorTest.new()
    }

    it "returns true for the basic types" do
      expect(subject.has_convertor?(:boolean)).to eq(true)
      expect(subject.has_convertor?(:float)).to eq(true)
      expect(subject.has_convertor?(:integer)).to eq(true)
      expect(subject.has_convertor?(:string)).to eq(true)
    end

    it "returns false for unknown types" do
      expect(subject.has_convertor?(:irky)).to eq(false)
    end
  end

  describe "#optional_parameter_names()" do
    subject {
      class OptionalParameterNamesTest < Chieftain::Command
        required :booler, type: :boolean
        required :floater, type: :float
        optional :number, type: :integer
        optional :other
      end
      OptionalParameterNamesTest.new(booler: "OFF", floater: "3.14", number: "1234")
    }

    it "returns an array containing the names of optional parameters" do
      names = subject.optional_parameter_names
      expect(names).not_to be_nil
      expect(names.length).to eq(2)
      expect(names).to include(:number)
      expect(names).to include(:other)
    end
  end

  describe "#parameter_names()" do
    subject {
      class ParameterNamesTest < Chieftain::Command
        required :booler, type: :boolean
        required :floater, type: :float
        optional :number, type: :integer
        optional :other
      end
      ParameterNamesTest.new(booler: "OFF", floater: "3.14", number: "1234")
    }

    it "returns an array containing the names of all parameters" do
      names = subject.parameter_names
      expect(names).not_to be_nil
      expect(names.length).to eq(4)
      expect(names).to include(:booler)
      expect(names).to include(:floater)
      expect(names).to include(:number)
      expect(names).to include(:other)
    end
  end

  describe "#provided?()" do
    subject {
      class ProvidedTest < Chieftain::Command
        optional :number, type: :integer
        optional :other
      end
      ProvidedTest.new(number: "1234")
    }

    it "returns true where a parameter value has been specified" do
      expect(subject.provided?(:number)).to eq(true)
    end

    it "returns false where a parameter value has not been specified" do
      expect(subject.provided?(:other)).to eq(false)
    end

    it "returns false where the named parameter does not exist" do
      expect(subject.provided?(:blah)).to eq(false)
    end
  end

  describe "#required_parameter_names()" do
    subject {
      class RequiredParameterNamesTest < Chieftain::Command
        required :booler, type: :boolean
        required :floater, type: :float
        optional :number, type: :integer
        optional :other
      end
      RequiredParameterNamesTest.new()
    }

    it "returns an array containing the names of optional parameters" do
      names = subject.required_parameter_names
      expect(names).not_to be_nil
      expect(names.length).to eq(2)
      expect(names).to include(:booler)
      expect(names).to include(:floater)
    end
  end

  describe "#settings_for()" do
    subject {
      class SettingsForTest < Chieftain::Command
        required :booler, type: :boolean
        optional :number, type: :integer
      end
      SettingsForTest.new()
    }

    it "returns a list of settings for the named class required parameter" do
      settings = subject.settings_for(:booler)
      expect(settings.name).to eq(:booler)
      expect(settings.required).to eq(true)
      expect(settings.type).to eq(:boolean)
    end

    it "returns a list of settings for the named class optional parameter" do
      settings = subject.settings_for(:number)
      expect(settings.name).to eq(:number)
      expect(settings.required).to eq(false)
      expect(settings.type).to eq(:integer)
    end
  end
end
