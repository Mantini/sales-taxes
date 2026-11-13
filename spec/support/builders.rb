# frozen_string_literal: true

# Builds products from a name, the same way the parser does, plus line items and receipts.
module Builders
  def build_product(name, price_cents)
    SalesTaxes::Catalog::Product.from_name(name, price_cents:)
  end

  def build_item(quantity, name, price_cents)
    SalesTaxes::Checkout::LineItem.new(quantity:, product: build_product(name, price_cents))
  end

  def build_receipt(*line_items)
    SalesTaxes::Checkout::Receipt.new(line_items:, calculator: SalesTaxes::Taxes::Calculator.default)
  end
end
