require "spec_helper"

RSpec.describe Chieftain::Command do
  describe "when validations" do
    describe "are defined for a parameter" do
      class ValidationTest1 < Chieftain::Command
        required :first, validations: [:validation1, :validation2]
        required :second, validations: [:not_blank]

        def perform
        end

        add_validator(:validation1) do |name, value|
          error("Failed validation1.") if value > 5
        end

        add_validator(:validation2) do |name, value|
          error("Failed validation2.") if value % 2 != 0
        end

        add_validator(:validation3) do |name, value|
          error("Failed validation3.") if value.nil?
        end
      end

      it "runs all of the specified ones" do
        command = ValidationTest1.new(first: 7, second: "")
        result  = command.execute
        expect(result.failed?).to be(true)
        expect(result.error_messages).to include("Failed validation1.")
        expect(result.error_messages).to include("Failed validation2.")
        expect(result.error_messages).not_to include("Failed validation3.")
        expect(result.error_messages).to include("Blank value specified for the 'second' parameter.")
      end

      describe "where the parmeter value is" do
        describe "valid" do
          it "returns a success result" do
            command = ValidationTest1.new(first: 4, second: "blah")
            result  = command.execute
            expect(result.success?).to be(true)
            expect(result.errors.empty?).to be(true)
          end
        end

        describe "invalid" do
          it "returns a failed result" do
            command = ValidationTest1.new(first: 11, second: nil)
            result  = command.execute
            expect(result.failed?).to be(true)
            expect(result.errors.empty?).to be(false)
          end
        end
      end
    end

    describe "have the same name as a parameter" do
      class ValidationTest2 < Chieftain::Command
        required :first, validations: [:validation1]

        def perform
        end

        add_validator(:validation1) do |name, value|
          error("#{name} is too high.") if value > 5
        end

        validate(:first) do |name, value|
          error("#{name} is not even.") if value % 2 != 0
        end
      end

      it "gets invoked for the parameter along with any other defined validations" do
        command = ValidationTest2.new(first: 7)
        result  = command.execute
        expect(result.failed?).to be(true)
        expect(result.error_messages).to include("first is too high.")
        expect(result.error_messages).to include("first is not even.")
      end
    end
  end
end
