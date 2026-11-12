# frozen_string_literal: true

RSpec.describe "SalesTaxes::InputParser" do
  describe "valid lines" do
    it "reads quantity, name and price"
    it "flags imported products wherever the word appears, in any case"
    it "does not flag words that only contain 'imported'"
    it "keeps the product name as written"
    it "assigns the category from the name"
    it "accepts a price without decimals or with one decimal"
    it "tolerates extra spaces, tabs and Windows line endings"
    it "uses the last ' at ' to find the price"
    it "reads names that contain numbers"
    it "skips blank lines and keeps the input order"
  end

  describe "malformed lines (MalformedLineError)" do
    it "rejects a line without ' at '"
    it "rejects a line without quantity, name or price"
    it "rejects text after the price"
    it "names the line number and shows the whole line"
  end

  describe "invalid values (InvalidValueError)" do
    it "rejects a zero, negative or fractional quantity"
    it "rejects a zero or negative price"
    it "rejects a price with more than two decimals or a comma decimal"
    it "names the line number, the product and the field"
  end

  describe "empty input (EmptyBasketError)" do
    it "rejects input with no items, only blank lines included"
  end
end
