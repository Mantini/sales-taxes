# frozen_string_literal: true

RSpec.describe SalesTaxes::InputParser do
  subject(:parser) { described_class.new }

  def parse(*lines)
    parser.parse(lines.join("\n"))
  end

  def parse_one(line)
    parse(line).first
  end

  describe "valid lines" do
    it "reads quantity, name and price" do
      item = parse_one("4 desk lamp at 3.07")

      expect([item.quantity, item.product.name, item.product.price_cents]).to eq([4, "desk lamp", 307])
    end

    # A leading zero must not make Ruby read the quantity as an octal number.
    it "reads a quantity with a leading zero as a decimal number" do
      expect(parse_one("010 desk lamp at 3.07").quantity).to eq(10)
    end

    # How the name is classified is covered in catalog_spec; this checks the parser uses it.
    it "takes the category and the import flag from the name" do
      product = parse_one("1 imported bottle of pills at 4.20").product

      expect([product.category, product.imported?]).to eq([SalesTaxes::Catalog::Category::MEDICAL, true])
    end

    it "keeps the product name as written" do
      expect(parse_one("1 Imported Desk LAMP at 30.07").product.name).to eq("Imported Desk LAMP")
    end

    it "uses the last ' at ' to find the price" do
      item = parse_one("1 painting of a cat at night at 12.00")

      expect([item.product.name, item.product.price_cents]).to eq(["painting of a cat at night", 1200])
    end

    it "reads names that contain numbers" do
      expect(parse_one("3 pack of 12 pencils at 4.50").product.name).to eq("pack of 12 pencils")
    end

    it "skips blank lines, even with spaces, and keeps the input order" do
      items = parse("", "1 desk lamp at 30.07", "   ", "2 paperback novel at 3.00", "")

      expect(items.map { |item| item.product.name }).to eq(["desk lamp", "paperback novel"])
    end

    it "ignores the byte order mark some Windows editors put at the start" do
      expect(parser.parse("\uFEFF1 desk lamp at 30.07\n").first.quantity).to eq(1)
    end

    it "accepts LF, CRLF and lone CR line endings" do
      ["\n", "\r\n", "\r"].each do |line_end|
        text = "1 desk lamp at 30.07#{line_end}2 paperback novel at 3.00#{line_end}"

        expect(parser.parse(text).map(&:quantity)).to eq([1, 2]), line_end.inspect
      end
    end
  end

  describe "malformed lines (MalformedLineError)" do
    it "rejects a line that does not follow the format exactly" do
      [
        "2 desk lamp 3.07",          # no " at "
        "desk lamp at 3.07",         # no quantity
        "2 at 3.07",                 # no name
        "2 desk lamp at",            # no price
        "2 desk lamp at 3.07 each",  # text after the price
        "-2 desk lamp at 3.07",      # a sign in the quantity
        "2  desk lamp at 3.07",      # two spaces before the name
        "2 desk  lamp at 3.07",      # two spaces inside the name
        "2 desk\tlamp at 3.07",      # a tab inside the name
        "2 desk lamp at 3.07 ",      # a trailing space
        "2\tdesk lamp at 3.07",      # a tab
        "2 desk lamp AT 3.07"        # "at" in capitals
      ].each do |line|
        expect { parse(line) }.to raise_error(SalesTaxes::MalformedLineError), line.inspect
      end
    end

    it "names the line number and shows the whole line" do
      expect { parse("1 desk lamp at 30.07", "", "2 board game 20.01") }
        .to raise_error(SalesTaxes::MalformedLineError, /line 3 .*"2 board game 20\.01"/)
    end

    it "rejects input that is not valid UTF-8 text" do
      expect { parser.parse("1 caf\xC3 at 1.00".b.force_encoding("UTF-8")) }
        .to raise_error(SalesTaxes::MalformedLineError, /not valid UTF-8 text/)
    end
  end

  describe "invalid values (InvalidValueError)" do
    it "rejects a zero quantity" do
      expect { parse("0 desk lamp at 3.07") }.to raise_error(SalesTaxes::InvalidValueError, /quantity/)
    end

    # The price format itself is covered in money_spec; this checks it reaches the parser.
    it "rejects a zero or badly written price" do
      ["2 desk lamp at 0.00", "2 desk lamp at 3.5"].each do |line|
        expect { parse(line) }.to raise_error(SalesTaxes::InvalidValueError, /price/), line
      end
    end

    it "names the line number, the product and the field" do
      expect { parse("1 desk lamp at 30.07", "", "0 board game at 20.01") }
        .to raise_error(SalesTaxes::InvalidValueError, "line 3 (board game): quantity must be greater than zero")
    end
  end

  describe "empty input (EmptyBasketError)" do
    it "rejects input with no items, only blank lines included" do
      expect { parser.parse("") }.to raise_error(SalesTaxes::EmptyBasketError)
      expect { parser.parse("\n\r\n\n") }.to raise_error(SalesTaxes::EmptyBasketError)
    end
  end
end
