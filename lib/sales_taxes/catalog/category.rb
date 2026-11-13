# frozen_string_literal: true

module SalesTaxes
  module Catalog
    # The input doesn't say the product type, so we take it from keywords in the name.
    class Category
      attr_reader :name

      def self.for(product_name)
        KNOWN.find { |category| category.matches?(product_name) } || OTHER
      end

      def initialize(name, keywords = [])
        @name = name
        # Any keyword as a whole word, singular or plural, in any letter case.
        @pattern = /\b(#{keywords.join("|")})s?\b/i unless keywords.empty?
        freeze
      end

      def matches?(product_name)
        @pattern&.match?(product_name)
      end

      BOOK = new(:book, %w[book novel textbook paperback encyclopedia])
      FOOD = new(:food, %w[chocolate bread cheese coffee tea fruit])
      MEDICAL = new(:medical, %w[pill capsule medicine syrup bandage vitamin])
      OTHER = new(:other)
      KNOWN = [BOOK, FOOD, MEDICAL].freeze
    end
  end
end
