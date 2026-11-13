# frozen_string_literal: true

# Builds products the same way in every spec, with the category taken from the name.
module Builders
  def build_product(name, price_cents, imported: false)
    SalesTaxes::Catalog::Product.new(name:, price_cents:, imported:,
                                     category: SalesTaxes::Catalog::Category.for(name))
  end
end
