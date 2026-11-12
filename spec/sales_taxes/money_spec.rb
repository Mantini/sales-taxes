# frozen_string_literal: true

RSpec.describe "SalesTaxes::Money" do
  describe ".parse" do
    it "reads a price with two decimals as cents"
    it "reads a price below one unit"
    it "reads a whole number or a single decimal"
    it "keeps large values exact"
    it "rejects empty text, letters and symbols"
    it "rejects more than two decimals"
    it "rejects comma decimals and thousands separators"
    it "rejects negative prices and explicit signs"
    it "rejects scientific notation and incomplete numbers (.50, 3.)"
  end

  describe ".format" do
    it "always prints two decimals"
    it "prints zero as 0.00"
    it "keeps large values exact"
  end
end
