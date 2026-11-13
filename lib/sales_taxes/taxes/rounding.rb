# frozen_string_literal: true

module SalesTaxes
  module Taxes
    # Rule from the problem description: "for a tax rate of n%, a shelf price of p contains
    # (np/100 rounded up to the nearest 0.05) amount of sales tax".
    module Rounding
      STEP_CENTS = 5

      # Integer math only. price * rate / 100 is the tax in cents, and ceildiv
      # rounds it up to the next 5 cents in the same step.
      def self.tax_cents(price_cents:, rate_percent:)
        raise ArgumentError, "price and rate must not be negative" if price_cents.negative? || rate_percent.negative?

        (price_cents * rate_percent).ceildiv(100 * STEP_CENTS) * STEP_CENTS
      end
    end
  end
end
