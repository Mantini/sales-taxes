# frozen_string_literal: true

RSpec.describe SalesTaxes::Money do
  describe ".parse" do
    it "reads a price with two decimals as cents" do
      expect(described_class.parse("3.07")).to eq(307)
    end

    it "reads a price below one unit" do
      expect(described_class.parse("0.09")).to eq(9)
    end

    it "reads a whole number or a single decimal" do
      expect(described_class.parse("7")).to eq(700)
      expect(described_class.parse("7.5")).to eq(750)
    end

    it "keeps large values exact" do
      expect(described_class.parse("123456789.99")).to eq(12_345_678_999)
    end

    it "rejects empty text, letters and symbols" do
      ["", "   ", "abc", "$3.07"].each do |text|
        expect { described_class.parse(text) }.to raise_error(SalesTaxes::InvalidValueError), text.inspect
      end
    end

    it "rejects more than two decimals" do
      expect { described_class.parse("3.071") }.to raise_error(SalesTaxes::InvalidValueError)
    end

    it "rejects comma decimals and thousands separators" do
      ["3,07", "1,000.00"].each do |text|
        expect { described_class.parse(text) }.to raise_error(SalesTaxes::InvalidValueError), text.inspect
      end
    end

    it "rejects negative prices and explicit signs" do
      ["-1.00", "+1.00"].each do |text|
        expect { described_class.parse(text) }.to raise_error(SalesTaxes::InvalidValueError), text.inspect
      end
    end

    it "rejects scientific notation and incomplete numbers (.50, 3.)" do
      ["1e3", ".50", "3."].each do |text|
        expect { described_class.parse(text) }.to raise_error(SalesTaxes::InvalidValueError), text.inspect
      end
    end
  end

  describe ".format" do
    it "always prints two decimals" do
      expect(described_class.format(307)).to eq("3.07")
      expect(described_class.format(4210)).to eq("42.10")
      expect(described_class.format(9)).to eq("0.09")
    end

    it "prints zero as 0.00" do
      expect(described_class.format(0)).to eq("0.00")
    end

    it "keeps large values exact" do
      expect(described_class.format(12_345_678_999)).to eq("123456789.99")
    end
  end
end
