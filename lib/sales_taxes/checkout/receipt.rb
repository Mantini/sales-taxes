# frozen_string_literal: true

module SalesTaxes
  module Checkout
    # The basket with its taxes worked out. Tax is calculated for one unit and then
    # multiplied by the quantity, and each basket line stays its own receipt line.
    class Receipt
      Line = Data.define(:quantity, :name, :tax_cents, :total_cents)

      attr_reader :lines

      def initialize(line_items:, calculator:)
        @lines = line_items.map { |item| line_for(item, calculator) }.freeze
        freeze
      end

      def sales_taxes_cents
        lines.sum(&:tax_cents)
      end

      def total_cents
        lines.sum(&:total_cents)
      end

      private

      def line_for(item, calculator)
        tax_cents = calculator.unit_tax(item.product) * item.quantity
        total_cents = (item.product.price_cents * item.quantity) + tax_cents
        Line.new(quantity: item.quantity, name: item.product.name, tax_cents:, total_cents:)
      end
    end
  end
end
