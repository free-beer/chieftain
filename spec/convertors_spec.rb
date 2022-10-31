require "spec_helper"

RSpec.describe Chieftain::Command do
  class TestConvertor
    def convertible?(value)
      value.to_s.split("=").length == 2
    end

    def convert(value)
      parts = value.to_s.split("=").map(&:strip)
      {name: parts[0], value: parts[1]}
    end
  end

  class ConvertorTest < Chieftain::Command
    optional :number, type: :integer
    optional :pair, type: :pair

    add_convertor :pair, TestConvertor
  end

  describe "when a default type is specified for a parameter" do
    describe "and the parameter value" do
      describe "can be converted to the type" do
        it "returns the parameter value as the appropriate type" do
          command = ConvertorTest.new(number: "4321")
          expect(command.number).to eq(4321)
        end
      end

      describe "can't be converted to the type" do
        it "makes the command invalid" do
          command = ConvertorTest.new(number: "abcde")
          expect(command.valid?).to be(false)
        end
      end
    end
  end

  describe "when a custom type is specified for a parameter" do
    describe "and the parameter value" do
      describe "can be converted to the type" do
        it "returns the parameter value as the appropriate type" do
          command = ConvertorTest.new(pair: "first = 1")
          expect(command.pair).not_to be_nil
          expect(command.pair[:name]).to eq("first")
          expect(command.pair[:value]).to eq("1")
        end
      end

      describe "can't be converted to the type" do
        it "makes the command invalid" do
          command = ConvertorTest.new(number: "first = 1 = second")
          expect(command.valid?).to be(false)
        end
      end
    end
  end
end