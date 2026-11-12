# frozen_string_literal: true

RSpec.describe "SalesTaxes::Catalog" do
  describe "Category" do
    it "recognizes books, food and medical products by keywords in the name"
    it "matches singular, plural and any letter case"
    it "does not match a keyword inside another word"
    it "treats unknown products as taxable"
    it "exempts only books, food and medical products"
  end

  describe "Product" do
    it "requires a name and a positive price in cents"
  end
end
