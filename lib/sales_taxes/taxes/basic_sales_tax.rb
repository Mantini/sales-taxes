# frozen_string_literal: true

module SalesTaxes
  module Taxes
    # 10% on all goods, except books, food and medical products.
    class BasicSalesTax
      RATE_PERCENT = 10
      EXEMPT = [Catalog::Category::BOOK, Catalog::Category::FOOD, Catalog::Category::MEDICAL].freeze

      def amount_for(product)
        return 0 if EXEMPT.include?(product.category)

        Rounding.tax_cents(price_cents: product.price_cents, rate_percent: RATE_PERCENT)
      end
    end
  end
end
