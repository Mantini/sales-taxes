# frozen_string_literal: true

module SalesTaxes
  # Parent of every input error we expect, so the CLI rescues them in one place.
  # Anything else is a bug and should not be rescued.
  class Error < StandardError; end

  # The file is missing, is a directory or is not valid text.
  class InputFileError < Error; end

  # The input has no items.
  class EmptyBasketError < Error; end

  # A line does not follow "<quantity> <product name> at <price>".
  class MalformedLineError < Error; end

  # A line has the right shape, but a value is not allowed (a zero quantity, a bad price).
  class InvalidValueError < Error; end
end
