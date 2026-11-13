# frozen_string_literal: true

RSpec.describe SalesTaxes::Catalog do
  describe SalesTaxes::Catalog::Category do
    it "recognizes every keyword of books, food and medical products" do
      {
        described_class::BOOK => %w[book novel textbook paperback encyclopedia],
        described_class::FOOD => %w[chocolate bread cheese coffee tea fruit],
        described_class::MEDICAL => %w[pill capsule medicine syrup bandage vitamin]
      }.each do |category, keywords|
        keywords.each do |keyword|
          expect(described_class.for("one #{keyword} in a box")).to eq(category), keyword
        end
      end
    end

    it "matches singular, plural and any letter case" do
      expect(described_class.for("old BOOKS")).to eq(described_class::BOOK)
      expect(described_class.for("Cheeses")).to eq(described_class::FOOD)
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
      product = build(name: +"desk lamp", imported: true)

      expect([product.name, product.price_cents, product.imported?, product.category])
        .to eq(["desk lamp", 3007, true, category])
      expect([product, product.name]).to all(be_frozen)
    end

    it "requires a price greater than zero" do
      [0, -1].each do |price_cents|
        expect { build(price_cents:) }.to raise_error(SalesTaxes::InvalidValueError, /price/), price_cents.inspect
      end
    end

    describe ".from_name" do
      def from_name(name)
        described_class.from_name(name, price_cents: 1000)
      end

      it "takes the category from keywords in the name" do
        expect(from_name("bottle of pills").category).to eq(SalesTaxes::Catalog::Category::MEDICAL)
      end

      it "is imported when the name has the word 'imported', anywhere and in any case" do
        ["imported vase", "vase imported from Italy", "IMPORTED desk lamp"].each do |name|
          expect(from_name(name)).to be_imported, name
        end
      end

      it "is not imported without the word 'imported' on its own" do
        ["desk lamp", "unimported vase"].each do |name|
          expect(from_name(name)).not_to be_imported, name
        end
      end
    end
  end
end
