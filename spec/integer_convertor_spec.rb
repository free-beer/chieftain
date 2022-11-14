require "spec_helper"

describe Chieftain::IntegerConvertor do
  subject {
    Chieftain::IntegerConvertor.new
  }

  describe "#convertible?()" do
    it "returns true for integer values" do
      expect(subject.convertible?(314)).to eq(true)
    end

    it "returns true for string values that can be converted to a integer" do
      expect(subject.convertible?("314")).to eq(true)
    end

    it "returns false for non-covertible values" do
      expect(subject.convertible?("blah")).to eq(false)
    end
  end

  describe "#convert()" do
    it "returns the value for integer values" do
      expect(subject.convert(314)).to eq(314)
    end

    it "returns the value for strings that can be converted to integers" do
      expect(subject.convert("314")).to eq(314)
    end

    it "returns 0 for non-convertible values" do
      expect(subject.convert("blah")).to eq(0)
    end
  end
end
