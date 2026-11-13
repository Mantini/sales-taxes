# frozen_string_literal: true

module SalesTaxes
  module Taxes
    # 5% on all imported goods, with no exemptions.
    class ImportDuty
      RATE_PERCENT = 5

      def amount_for(product)
        return 0 unless product.imported?

        Rounding.tax_cents(price_cents: product.price_cents, rate_percent: RATE_PERCENT)
      end
    end
  end
end
