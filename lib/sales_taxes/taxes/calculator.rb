# frozen_string_literal: true

module SalesTaxes
  module Taxes
    # Sums the tax of one unit across its rules. A rule is any object with amount_for(product),
    # so adding a new tax means passing one more rule.
    class Calculator
      def self.default
        new(rules: [BasicSalesTax.new, ImportDuty.new])
      end

      def initialize(rules:)
        @rules = rules.dup.freeze
        freeze
      end

      def unit_tax(product)
        @rules.sum { |rule| rule.amount_for(product) }
      end
    end
  end
end
