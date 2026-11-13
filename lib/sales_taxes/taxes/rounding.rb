# frozen_string_literal: true

module SalesTaxes
  module Taxes
    # Rule from the problem description: "for a tax rate of n%, a shelf price of p contains
    # (np/100 rounded up to the nearest 0.05) amount of sales tax".
    module Rounding
      STEP_CENTS = 5

      # price * rate / 100 is the tax in cents. ceildiv rounds that division up to the
      # next multiple of 5 cents, so the whole calculation stays in integers.
      def self.tax_cents(price_cents:, rate_percent:)
        (price_cents * rate_percent).ceildiv(100 * STEP_CENTS) * STEP_CENTS
      end
    end
  end
end
