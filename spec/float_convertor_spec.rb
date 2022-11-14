require "spec_helper"

describe Chieftain::FloatConvertor do
  subject {
    Chieftain::FloatConvertor.new
  }

  describe "#convertible?()" do
    it "returns true for float values" do
      expect(subject.convertible?(3.14)).to eq(true)
    end

    it "returns true for string values that can be converted to a float" do
      expect(subject.convertible?("3.14")).to eq(true)
    end

    it "returns false for non-covertible values" do
      expect(subject.convertible?("blah")).to eq(false)
    end
  end

  describe "#convert()" do
    it "returns the value for float values" do
      expect(subject.convert(3.14)).to eq(3.14)
    end

    it "returns the value for strings that can be converted to floats" do
      expect(subject.convert("3.14")).to eq(3.14)
    end

    it "returns 0.0 for non-convertible values" do
      expect(subject.convert("blah")).to eq(0.0)
    end
  end
end
