require "spec_helper"

describe Chieftain::StringConvertor do
  subject {
    Chieftain::StringConvertor.new
  }

  describe "#convertible?()" do
    it "always returns true" do
      expect(subject.convertible?(314)).to eq(true)
      expect(subject.convertible?(3.14)).to eq(true)
      expect(subject.convertible?("314")).to eq(true)
      expect(subject.convertible?(true)).to eq(true)
    end
  end

  describe "#convert()" do
    it "returns the string value for value it is given" do
      expect(subject.convert(314)).to eq("314")
      expect(subject.convert(3.14)).to eq("3.14")
      expect(subject.convert("314")).to eq("314")
      expect(subject.convert(true)).to eq("true")
    end
  end
end
