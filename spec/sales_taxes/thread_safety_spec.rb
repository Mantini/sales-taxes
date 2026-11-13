# frozen_string_literal: true

# Objects that hold data are frozen once built, and the others have no state at all,
# so the same objects can be shared between threads without locks.
RSpec.describe "Thread safety" do
  it "freezes the receipt, its lines and the calculator" do
    calculator = SalesTaxes::Taxes::Calculator.default
    items = SalesTaxes::InputParser.new.parse("2 paperback novel at 10.00\n1 imported desk lamp at 1.01\n")
    receipt = SalesTaxes::Checkout::Receipt.new(line_items: items, calculator:)

    expect([calculator, receipt, receipt.lines, *receipt.lines, *items]).to all(be_frozen)
  end
end
