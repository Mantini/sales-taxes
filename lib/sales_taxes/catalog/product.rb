# frozen_string_literal: true

module SalesTaxes
  module Catalog
    # A product as it was bought. The price must be greater than zero.
    Product = Data.define(:name, :price_cents, :imported, :category) do
      # The input states neither the product type nor where it comes from,
      # so both are taken from the name.
      def self.from_name(name, price_cents:)
        # The word "imported" anywhere in the name, in any letter case.
        imported = /\bimported\b/i.match?(name)
        new(name:, price_cents:, imported:, category: Category.for(name))
      end

      def initialize(name:, price_cents:, imported:, category:)
        raise InvalidValueError, "price must be greater than zero" unless price_cents.positive?

        super(name: name.dup.freeze, price_cents:, imported:, category:)
      end

      def imported? = imported
    end
  end
end
