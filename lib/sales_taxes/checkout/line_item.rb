# frozen_string_literal: true

module SalesTaxes
  module Checkout
    # One line of the basket: how many units of which product.
    LineItem = Data.define(:quantity, :product) do
      def initialize(quantity:, product:)
        unless quantity.is_a?(Integer) && quantity.positive?
          raise InvalidValueError, "quantity must be a whole number greater than zero"
        end

        super
      end
    end
  end
end
