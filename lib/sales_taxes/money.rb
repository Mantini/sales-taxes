# frozen_string_literal: true

module SalesTaxes
  # Prices are kept as Integer cents so the math stays exact.
  # This module only turns text into cents and back.
  module Money
    # The whole text must be digits, optionally followed by a dot and one or two digits.
    # It captures the units and the decimals separately.
    PRICE = /\A(\d+)(?:\.(\d{1,2}))?\z/

    def self.parse(text)
      match = PRICE.match(text)
      unless match
        raise InvalidValueError, "invalid price #{text.inspect}: use digits with up to two decimals, like 12.50"
      end

      units, decimals = match.captures
      (Integer(units, 10) * 100) + decimals.to_s.ljust(2, "0").to_i
    end

    def self.format(cents)
      units, rest = cents.divmod(100)
      "#{units}.#{rest.to_s.rjust(2, "0")}"
    end
  end
end
