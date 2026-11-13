# frozen_string_literal: true

# Builds objects the same way in every spec, with the category taken from the name.
module Builders
  def build_product(name, price_cents, imported: false)
    SalesTaxes::Catalog::Product.new(name:, price_cents:, imported:,
                                     category: SalesTaxes::Catalog::Category.for(name))
  end

  def build_item(quantity, name, price_cents, imported: false)
    SalesTaxes::Checkout::LineItem.new(quantity:, product: build_product(name, price_cents, imported:))
  end

  def build_receipt(*line_items)
    SalesTaxes::Checkout::Receipt.new(line_items:, calculator: SalesTaxes::Taxes::Calculator.default)
  end
end
