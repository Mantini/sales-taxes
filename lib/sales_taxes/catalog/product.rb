# frozen_string_literal: true

module SalesTaxes
  module Catalog
    # A product as it was bought. It checks its values when created,
    # so the rest of the code can trust them.
    Product = Data.define(:name, :price_cents, :imported, :category) do
      def initialize(name:, price_cents:, imported:, category:)
        raise InvalidValueError, "product name must not be blank" if name.to_s.strip.empty?
        unless price_cents.is_a?(Integer) && price_cents.positive?
          raise InvalidValueError, "price must be greater than zero"
        end

        super(name: name.dup.freeze, price_cents:, imported:, category:)
      end

      def imported? = imported
    end
  end
end
