# frozen_string_literal: true

module SalesTaxes
  # Prices are kept as Integer cents so the math stays exact.
  # This module only turns text into cents and back.
  module Money
    # Digits, a dot and exactly two decimals: X.XX. The digits before the dot are optional,
    # so a price below one can be written as .XX.
    PRICE = /\A\d*\.\d{2}\z/

    def self.parse(text)
      raise InvalidValueError, "price must look like X.XX or .XX, got #{text.inspect}" unless PRICE.match?(text)

      text.delete(".").to_i
    end

    def self.format(cents)
      Kernel.format("%d.%02d", *cents.divmod(100))
    end
  end
end
