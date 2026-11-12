# frozen_string_literal: true

RSpec.describe "SalesTaxes::Taxes" do
  describe "Rounding" do
    it "rounds the tax up to the nearest 0.05"
    it "keeps an exact multiple of 0.05"
    it "returns zero for a zero price or rate"
    it "stays exact on large prices"
    it "rejects a negative price or rate"
  end

  describe "BasicSalesTax" do
    it "charges 10% on taxable goods"
    it "does not charge books, food and medical products"
    it "ignores whether the product is imported"
  end

  describe "ImportDuty" do
    it "charges 5% on imported goods, with no exemptions"
    it "does not charge local goods"
  end

  describe "Calculator" do
    it "adds the taxes, each one rounded on its own"
    it "accepts any tax rule that answers amount_for"
    it "charges nothing without rules"
  end
end
