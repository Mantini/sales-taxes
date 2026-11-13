# frozen_string_literal: true

RSpec.describe SalesTaxes::Catalog do
  describe SalesTaxes::Catalog::Category do
    it "recognizes books, food and medical products by keywords in the name" do
      expect(described_class.for("paperback novel")).to eq(described_class::BOOK)
      expect(described_class.for("dark chocolate bar")).to eq(described_class::FOOD)
      expect(described_class.for("cough syrup")).to eq(described_class::MEDICAL)
    end

    it "matches singular, plural and any letter case" do
      expect(described_class.for("old BOOKS")).to eq(described_class::BOOK)
      expect(described_class.for("Cheeses")).to eq(described_class::FOOD)
      expect(described_class.for("box of bandages")).to eq(described_class::MEDICAL)
    end

    it "does not match a keyword inside another word" do
      %w[notebook bookshelf pillow teapot].each do |name|
        expect(described_class.for(name)).to eq(described_class::OTHER), name
      end
    end

    it "returns OTHER for an unknown product" do
      expect(described_class.for("garden hose")).to eq(described_class::OTHER)
    end
  end

  describe SalesTaxes::Catalog::Product do
    let(:category) { SalesTaxes::Catalog::Category::OTHER }

    def build(**overrides)
      described_class.new(name: "desk lamp", price_cents: 3007, imported: false, category:, **overrides)
    end

    it "keeps its values and is frozen, name included" do
      product = build(imported: true)

      expect([product.name, product.price_cents, product.imported?, product.category])
        .to eq(["desk lamp", 3007, true, category])
      expect([product, product.name]).to all(be_frozen)
    end

    it "requires a name and a positive price in cents" do
      ["", "   ", nil].each do |name|
        expect { build(name:) }.to raise_error(SalesTaxes::InvalidValueError, /name/), name.inspect
      end
      [0, -1, 30.07, "3007", nil].each do |price_cents|
        expect { build(price_cents:) }.to raise_error(SalesTaxes::InvalidValueError, /price/), price_cents.inspect
      end
    end
  end
end
