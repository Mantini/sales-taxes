# frozen_string_literal: true

RSpec.describe "SalesTaxes::Checkout" do
  describe "LineItem" do
    it "requires a positive whole quantity"
  end

  describe "Receipt" do
    it "taxes each unit and multiplies by the quantity"
    it "totals prices and taxes across lines"
    it "keeps repeated products as separate lines, in order"
    it "handles an empty basket"
  end

  describe "ReceiptFormatter" do
    it "prints each line, then Sales Taxes and Total"
    it "keeps the product name as written"
    it "always prints two decimals"
  end
end
