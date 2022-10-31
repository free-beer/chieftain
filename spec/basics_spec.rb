require "spec_helper"

RSpec.describe Chieftain::Command do
  class BasicsTest < Chieftain::Command
    required :first, validations: [:not_nil]
    required :second, validations: [:not_nil]
    attr_reader :third

    def perform()
      @third = first + second
    end
  end

  describe "when the execute method is called" do
    describe "and the command is valid" do
      it "calls the perform method" do
        command = BasicsTest.new(first: 4, second: 6)
        result  = command.execute
        expect(result.success?).to be(true)
        expect(command.third).to eq(10)
      end
    end

    describe "and the command is valid" do
      it "does not call the perform method" do
        command = BasicsTest.new(first: 4, second: nil)
        result  = command.execute
        expect(result.success?).to be(false)
        expect(command.third).to be_nil
      end
    end
  end

  describe "when parameters" do
    describe "are defined" do
      subject {
        BasicsTest.new(first: "one", second: 222)
      }

      it "allows their values to be accessed directly" do
        expect(subject.first).to eq("one")
        expect(subject.second).to eq(222)
      end

      describe "that clash with an existing object method" do
        it "raises a parameter exception" do
          expect do
            class InvalidClass < Chieftain::Command
              parameter :to_s, required: true
            end
          end.to raise_error(Chieftain::ParameterError, "The 'to_s' parameter clashes with an existing class method.")
        end
      end
    end

    describe "that are required" do
      describe "are not specified" do
        subject {
          BasicsTest.new(first: "one")
        }

        it "fails execution" do
          result = subject.execute
          expect(result.failed?).to be(true)
        end

        it "sets an appropriate error message" do
          result = subject.execute
          expect(result.error_messages).to include("No value specified for the 'second' required parameter.")
        end
      end
    end

  end
end
