# frozen_string_literal: true

RSpec.describe SalesTaxes::Money do
  describe ".parse" do
    it "reads a price with two decimals as cents" do
      expect(described_class.parse("12.49")).to eq(1249)
      expect(described_class.parse("0.09")).to eq(9)
      expect(described_class.parse(".90")).to eq(90)
    end

    # A Float would lose the last cent of this value.
    it "keeps large values exact" do
      expect(described_class.parse("90071992547409.93")).to eq(9_007_199_254_740_993)
    end

    it "rejects anything other than digits, a dot and two decimals" do
      ["", "12", "12.5", ".5", ".", "12.499", "12,49", "-1.00", "$12.49", "1e3"].each do |text|
        expect { described_class.parse(text) }.to raise_error(SalesTaxes::InvalidValueError), text.inspect
      end
    end
  end

  describe ".format" do
    it "always prints two decimals" do
      expect([1249, 4210, 9, 0].map { |cents| described_class.format(cents) }).to eq(["12.49", "42.10", "0.09", "0.00"])
    end

    it "keeps large values exact" do
      expect(described_class.format(9_007_199_254_740_993)).to eq("90071992547409.93")
    end
  end
end
