# frozen_string_literal: true

module SalesTaxes
  module Catalog
    # The input doesn't say the product type, so we take it from keywords in the name.
    # A keyword matches as a whole word, singular or plural, in any letter case.
    class Category
      attr_reader :name

      def self.for(product_name)
        KNOWN.find { |category| category.matches?(product_name) } || OTHER
      end

      def initialize(name, keywords = [])
        @name = name
        # Any of the keywords as a whole word (so "notebook" is not "book"), with an optional
        # "s" or "es" at the end for the plural. The "i" at the end ignores letter case.
        @pattern = /\b(?:#{keywords.join("|")})(?:e?s)?\b/i unless keywords.empty?
        freeze
      end

      def matches?(product_name)
        @pattern&.match?(product_name) || false
      end

      BOOK = new(:book, %w[book novel textbook paperback encyclopedia])
      FOOD = new(:food, %w[chocolate bread cheese coffee tea fruit])
      MEDICAL = new(:medical, %w[pill tablet medicine syrup bandage vitamin])
      OTHER = new(:other)
      KNOWN = [BOOK, FOOD, MEDICAL].freeze
    end
  end
end
