# frozen_string_literal: true

module SalesTaxes
  module Checkout
    # One line of the basket: how many units of which product.
    LineItem = Data.define(:quantity, :product) do
      def initialize(quantity:, product:)
        raise InvalidValueError, "quantity must be greater than zero" unless quantity.positive?

        super
      end
    end
  end
end
