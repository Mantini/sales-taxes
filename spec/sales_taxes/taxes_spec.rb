# frozen_string_literal: true

RSpec.describe SalesTaxes::Taxes do
  describe SalesTaxes::Taxes::Rounding do
    def tax(price_cents, rate_percent)
      described_class.tax_cents(price_cents:, rate_percent:)
    end

    it "rounds the tax up to the nearest 0.05" do
      expect(tax(1501, 10)).to eq(155) # 1.501 -> 1.55
      expect(tax(1013, 5)).to eq(55)   # 0.5065 -> 0.55
      expect(tax(2001, 5)).to eq(105)  # 1.0005 -> 1.05
      expect(tax(1, 10)).to eq(5)      # 0.001 -> 0.05
    end

    it "keeps an exact multiple of 0.05" do
      expect(tax(3000, 10)).to eq(300)
    end

    it "returns zero for a zero price or rate" do
      expect(tax(0, 10)).to eq(0)
      expect(tax(3007, 0)).to eq(0)
    end

    it "stays exact on large prices" do
      expect(tax(12_345_678_999, 10)).to eq(1_234_567_900)
    end

    # Prices come from validated products and rates are constants, so a negative value
    # here is a bug, not bad input. That's why it's ArgumentError, not a SalesTaxes::Error.
    it "rejects a negative price or rate" do
      expect { tax(-100, 10) }.to raise_error(ArgumentError)
      expect { tax(100, -5) }.to raise_error(ArgumentError)
    end
  end

  describe SalesTaxes::Taxes::BasicSalesTax do
    subject(:tax) { described_class.new }

    it "charges 10% on taxable goods" do
      expect(tax.amount_for(build_product("board game", 2001))).to eq(205)
    end

    it "does not charge books, food and medical products" do
      ["paperback novel", "loaf of bread", "box of vitamins"].each do |name|
        expect(tax.amount_for(build_product(name, 3333))).to eq(0), name
      end
    end

    it "ignores whether the product is imported" do
      expect(tax.amount_for(build_product("imported desk lamp", 3000, imported: true))).to eq(300)
      expect(tax.amount_for(build_product("imported cheese", 1999, imported: true))).to eq(0)
    end
  end

  describe SalesTaxes::Taxes::ImportDuty do
    subject(:duty) { described_class.new }

    it "charges 5% on imported goods, with no exemptions" do
      expect(duty.amount_for(build_product("imported desk lamp", 2001, imported: true))).to eq(105)
      expect(duty.amount_for(build_product("imported textbook", 2000, imported: true))).to eq(100)
    end

    it "does not charge local goods" do
      expect(duty.amount_for(build_product("desk lamp", 2001))).to eq(0)
    end
  end

  describe SalesTaxes::Taxes::Calculator do
    # 1.01 imported and taxable: 0.101 -> 0.15 plus 0.0505 -> 0.10 gives 0.25. Rounding the
    # combined 15% once would give 0.1515 -> 0.20, so this case tells the two readings apart.
    it "adds the taxes, each one rounded on its own" do
      calculator = described_class.default

      expect(calculator.unit_tax(build_product("imported desk lamp", 101, imported: true))).to eq(25)
      expect(calculator.unit_tax(build_product("desk lamp", 2001))).to eq(205)
      expect(calculator.unit_tax(build_product("imported cheese", 101, imported: true))).to eq(10)
      expect(calculator.unit_tax(build_product("paperback novel", 2001))).to eq(0)
    end

    it "accepts any tax rule that answers amount_for" do
      flat_fee = Class.new { def amount_for(_product) = 25 }.new
      calculator = described_class.new(rules: [flat_fee, flat_fee])

      expect(calculator.unit_tax(build_product("desk lamp", 1000))).to eq(50)
    end

    it "charges nothing without rules" do
      expect(described_class.new(rules: []).unit_tax(build_product("desk lamp", 2001))).to eq(0)
    end
  end
end
