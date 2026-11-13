# frozen_string_literal: true

module SalesTaxes
  # Turns a basket text, one "<quantity> <product name> at <price>" line per item, into line items.
  class InputParser
    # Quantity in digits, the name and the price, separated by single spaces. The name is one
    # or more words, so it can contain "at" or numbers. The price is the word after the last " at ".
    LINE = /\A(?<quantity>\d+) (?<name>[[:graph:]]+(?: [[:graph:]]+)*) at (?<price>\S+)\z/

    FORMAT = "<quantity> <product name> at <price>"

    def parse(text)
      raise MalformedLineError, "the input is not valid UTF-8 text" unless text.valid_encoding?

      # Some Windows editors start the text with an invisible byte order mark.
      text = text.delete_prefix("\uFEFF")
      # A line ends in LF, CRLF or a lone CR, so text from any system splits the same way.
      items = text.split(/\r\n?|\n/).each.with_index(1).filter_map do |line, number|
        parse_line(line, number) unless line.strip.empty?
      end
      raise EmptyBasketError, "the basket has no items" if items.empty?

      items
    end

    private

    def parse_line(line, number)
      match = LINE.match(line)
      raise MalformedLineError, "line #{number} should look like \"#{FORMAT}\", got #{line.inspect}" unless match

      product = Catalog::Product.from_name(match[:name], price_cents: Money.parse(match[:price]))
      Checkout::LineItem.new(quantity: match[:quantity].to_i, product:)
    rescue InvalidValueError => e
      raise InvalidValueError, "line #{number} (#{match[:name]}): #{e.message}"
    end
  end
end
