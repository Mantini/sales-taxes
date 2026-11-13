# frozen_string_literal: true

module SalesTaxes
  module Checkout
    # Turns a receipt into the text the problem description shows:
    # one line per item with its price including taxes, then Sales Taxes and Total.
    class ReceiptFormatter
      def format(receipt)
        items = receipt.lines.map { |line| "#{line.quantity} #{line.name}: #{Money.format(line.total_cents)}" }
        [
          *items,
          "Sales Taxes: #{Money.format(receipt.sales_taxes_cents)}",
          "Total: #{Money.format(receipt.total_cents)}"
        ].join("\n")
      end
    end
  end
end
