# Sales Taxes

Prints shopping receipts with basic sales tax and import duty.

## Requirements

- Ruby 4.0 (tested with 4.0.9). The version is pinned in `.ruby-version`, so rbenv, asdf or chruby pick it up automatically.
- Bundler, which ships with Ruby.

There are no runtime dependencies. RSpec is the only gem, and it is used only for the tests.

## Proposal

The application reads a shopping basket and prints its receipt: each item with its price including taxes, then the total sales taxes paid and the total cost.

**Basket.** Each line is one purchase in the format `<quantity> <product name> at <price>`, for example `2 book of poems at 10.00`. A product is imported when its name contains the word "imported". The product type (book, food, medical or other) comes from keywords in the name, since the input does not state it.

**Taxes.**
- Basic sales tax: 10% on every product, except books, food and medical products.
- Import duty: 5% on every imported product, with no exemptions.
- Each tax is calculated on the unit price, rounded up to the nearest 0.05, and then multiplied by the quantity.

**Input.** A basket can come from a text file or be typed in the terminal, one line at a time, finishing with an empty line. Several files can be given at once; each one gets its own receipt under its file name.

**Errors.** A basket with a problem (a line in the wrong format, an invalid value such as a zero quantity, no items at all, or a file that cannot be read) prints a clear message instead of a receipt, because a receipt missing an item would be wrong. When several files are given, the others are still processed.

## Assumptions

- **Product type comes from keywords in the name.** The keywords cover the problem description's examples plus a few common words, and they live in one constant, so the list is easy to extend:
  - Books: book, novel, textbook, paperback, encyclopedia.
  - Food: chocolate, bread, cheese, coffee, tea, fruit.
  - Medical: pill, tablet, medicine, syrup, bandage, vitamin.

  Singular, plural (an added "s" or "es") and any letter case match, but only as whole words, so "notebook" is not a book and "pillow" is not medical. Any other product is taxed, because the problem description exempts only those three types. A real system would take the type from its product catalog.
- **"imported" is a whole word anywhere in the name**, in any letter case. The name is printed exactly as it was written.
- **Tax is calculated per unit, then multiplied by the quantity.** The problem description's third example needs it: 3 imported boxes of chocolates at 11.25 print 35.55, which is 3 × (11.25 + 0.60). Taxing the whole line (33.75 → 1.70) would print 35.45.
- **Each tax is rounded on its own**, then the two are added. The problem description gives the rule per tax rate ("for a tax rate of n%..."), and in practice each tax is a separate obligation. Rounding the combined 15% once would also match its examples, so this choice is stated here and covered by a test where the two readings differ.
- **Prices** have up to two decimals and must be greater than zero; `12`, `12.5` and `12.50` are accepted. A comma is not accepted as the decimal mark, because `1,000` would be ambiguous.
- **Quantities** are whole numbers greater than zero.
- **The last " at " separates the name from the price**, so names may contain "at" or numbers (`1 painting of a cat at night at 12.00`).
- **One invalid line rejects its whole basket**, because a receipt missing an item would be wrong.
- **Lines keep their input order**, and the same product on two lines prints as two lines.

## Setup

```bash
ruby -v          # should print ruby 4.0.x
bundle install
```

On Windows, Ruby 4.0 can be installed with [RubyInstaller](https://rubyinstaller.org/) (for example `winget install RubyInstallerTeam.Ruby.4.0`). On macOS or Linux, use your version manager, for example `rbenv install 4.0.9`.

## How to run

## How to test

```bash
bundle exec rspec
```

## Design

## How taxes are calculated

## Money representation

## What was left out

- Matching irregular plurals and other word forms (for example with `ActiveSupport::Inflector` or a stemmer). The problem description does not allow external libraries, and every keyword in the list has a regular plural, so an optional "s" or "es" is enough.
- Taking the product type from a product catalog, or from a category list kept by the business, instead of keywords in the name. The type is decided in one place, so its source can change without touching the rest of the code.
- Reporting every invalid line of a file at once (with a cap, so a badly formatted file does not flood the output). Today the first invalid line stops that file, and its error names the line, the product and the field.
