require "spec_helper"

describe Chieftain::BooleanConvertor do
  subject {
    Chieftain::BooleanConvertor.new
  }

  describe "#convertible?()" do
    it "returns true for the boolean value true" do
      expect(subject.convertible?(true)).to eq(true)
    end

    it "returns true for the boolean value false" do
      expect(subject.convertible?(false)).to eq(true)
    end

    it "returns true for any of the valid true value" do
      Chieftain::BooleanConvertor::VALID_TRUE_VALUES.each do |value|
        expect(subject.convertible?(value)).to eq(true)
      end
    end

    it "returns true for any of the valid false value" do
      Chieftain::BooleanConvertor::VALID_FALSE_VALUES.each do |value|
        expect(subject.convertible?(value)).to eq(true)
      end
    end

    it "is case insensitive for true values" do
      expect(subject.convertible?("On")).to eq(true)
      expect(subject.convertible?("YES")).to eq(true)
    end

    it "is case insensitive for false values" do
      expect(subject.convertible?("No")).to eq(true)
      expect(subject.convertible?("oFf")).to eq(true)
    end

    it "returns false for any other value" do
      expect(subject.convertible?("blah")).to eq(false)
      expect(subject.convertible?(3.14)).to eq(false)
      expect(subject.convertible?(101)).to eq(false)
    end
  end

  describe "#convert()" do
    it "returns true for the boolean value true" do
      expect(subject.convert(true)).to eq(true)
    end

    it "returns false for the boolean value false" do
      expect(subject.convert(false)).to eq(false)
    end

    it "returns true for any of the valid true value" do
      Chieftain::BooleanConvertor::VALID_TRUE_VALUES.each do |value|
        expect(subject.convert(value)).to eq(true)
      end
    end

    it "returns false for any of the valid false value" do
      Chieftain::BooleanConvertor::VALID_FALSE_VALUES.each do |value|
        expect(subject.convert(value)).to eq(false)
      end
    end

    it "is case insensitive for true values" do
      expect(subject.convert("On")).to eq(true)
      expect(subject.convert("YES")).to eq(true)
    end

    it "is case insensitive for false values" do
      expect(subject.convert("No")).to eq(false)
      expect(subject.convert("oFf")).to eq(false)
    end

    it "returns false for any other value" do
      expect(subject.convert("blah")).to eq(false)
      expect(subject.convert(3.14)).to eq(false)
      expect(subject.convert(101)).to eq(false)
    end
  end
end
