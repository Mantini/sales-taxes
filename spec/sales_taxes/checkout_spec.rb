# frozen_string_literal: true

RSpec.describe SalesTaxes::Checkout do
  describe SalesTaxes::Checkout::LineItem do
    it "requires a quantity greater than zero" do
      product = build_product("desk lamp", 1000)

      expect(described_class.new(quantity: 2, product:).quantity).to eq(2)
      [0, -1].each do |quantity|
        expect { described_class.new(quantity:, product:) }
          .to raise_error(SalesTaxes::InvalidValueError, /quantity/), quantity.inspect
      end
    end
  end

  describe SalesTaxes::Checkout::Receipt do
    # One imported cheese at 1.01 pays 0.0505 -> 0.10 of tax, so three pay 0.30 and cost 3.33.
    # Taxing the whole line instead (3.03 -> 0.1515 -> 0.20) would give 3.23.
    it "taxes each unit and multiplies by the quantity" do
      receipt = build_receipt(build_item(3, "imported cheese", 101))

      expect(receipt.lines.first.total_cents).to eq(333)
      expect(receipt.sales_taxes_cents).to eq(30)
    end

    it "totals prices and taxes across lines" do
      receipt = build_receipt(
        build_item(2, "paperback novel", 1000),   # no tax: 20.00
        build_item(1, "imported desk lamp", 101), # 0.25 of tax: 1.26
        build_item(1, "desk lamp", 2001)          # 2.05 of tax: 22.06
      )

      expect(receipt.lines.map(&:total_cents)).to eq([2000, 126, 2206])
      expect(receipt.sales_taxes_cents).to eq(230)
      expect(receipt.total_cents).to eq(4332)
    end

    it "keeps repeated products as separate lines, in order, each with its own price" do
      receipt = build_receipt(
        build_item(1, "desk lamp", 1000),
        build_item(1, "paperback novel", 500),
        build_item(2, "desk lamp", 2000)
      )

      expect(receipt.lines.map(&:name)).to eq(["desk lamp", "paperback novel", "desk lamp"])
      expect(receipt.lines.map(&:total_cents)).to eq([1100, 500, 4400])
    end
  end

  describe SalesTaxes::Checkout::ReceiptFormatter do
    subject(:formatter) { described_class.new }

    it "prints each line, then Sales Taxes and Total" do
      receipt = build_receipt(build_item(2, "paperback novel", 1000),
                              build_item(1, "imported desk lamp", 101))

      expect(formatter.format(receipt)).to eq(<<~TEXT.chomp)
        2 paperback novel: 20.00
        1 imported desk lamp: 1.26
        Sales Taxes: 0.25
        Total: 21.26
      TEXT
    end
  end
end
