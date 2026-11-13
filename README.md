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

- **Product type comes from keywords in the name.** The keywords cover the problem description's examples plus a few common words, and they are all listed in `Catalog::Category`, so the list is easy to extend:
  - Books: book, novel, textbook, paperback, encyclopedia.
  - Food: chocolate, bread, cheese, coffee, tea, fruit.
  - Medical: pill, tablet, medicine, syrup, bandage, vitamin.

  A keyword matches in singular or plural (an added "s" or "es") and in any letter case, but only as a whole word:
  - "old BOOKS" is a book;
  - "notebook" is not a book, and "pillow" is not medical.

  Any other product is taxed, because the problem description exempts only these three types. A real system would take the type from its product catalog.
- **"imported" is a whole word anywhere in the name**, in any letter case. The name is printed exactly as it was written.
- **Tax is calculated per unit, then multiplied by the quantity.** The problem description's third example needs it. For 3 imported boxes of chocolates at 11.25:
  - per unit: 3 × (11.25 + 0.60) = 35.55, the expected output;
  - on the whole line: 33.75 + 1.70 = 35.45, which does not match.
- **Each tax is rounded on its own**, then the two are added. The problem description gives the rule per tax rate ("for a tax rate of n%..."), and in practice each tax is a separate obligation. Rounding the combined 15% once also matches its examples, but not every price. At 1.01:
  - each tax on its own: 0.15 + 0.10 = 0.25;
  - the combined 15% once: 0.1515, rounded to 0.20.

  A test covers this case.
- **Prices** have up to two decimals and must be greater than zero:
  - accepted: `12`, `12.5`, `12.50`;
  - rejected: `12.505`, `0`, `-1`, `12,50` (a comma would make `1,000` ambiguous).
- **Quantities** are whole numbers greater than zero.
- **The last " at " separates the name from the price**, so names may contain "at" or numbers, as in `1 painting of a cat at night at 12.00`.
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

The code is in `lib/sales_taxes`, one class per file, grouped by module:

| Module | Classes | Job |
|---|---|---|
| `Money` | | Turns price text into Integer cents and back |
| `Catalog` | `Category`, `Product` | What is being bought |
| `Taxes` | `Rounding`, `BasicSalesTax`, `ImportDuty`, `Calculator` | How much tax one unit pays |
| `Checkout` | `LineItem`, `Receipt`, `ReceiptFormatter` | The basket, its totals and the printed text |

Objects hold each other instead of inheriting from each other:
- a `Product` has a `Category`;
- a `LineItem` has a quantity and a `Product`;
- a `Receipt` is built from `LineItem`s and a `Calculator`;
- a `Calculator` has a list of tax rules.

**Tax rules are composed, not inherited.** Each rule is a small class that answers `amount_for(product)`, and `Calculator` adds up whatever rules it is given. A new tax is a new class passed to the calculator, with no change to the others. The two rules only share the rounding, which is already its own module (`Taxes::Rounding`), so a base class would save two lines and tie the rules together.

**Exemptions belong to the tax, not to the category.** `BasicSalesTax` keeps the list of exempt categories, because the exemption is part of that tax's rule. The import duty has no exemptions.

**Errors.** Every input problem the user can cause is a subclass of `SalesTaxes::Error` (`InputFileError`, `EmptyBasketError`, `MalformedLineError`, `InvalidValueError`). Anything else is a bug and is not rescued. For example, a negative value reaching `Taxes::Rounding` can only come from a bug, so it raises a plain `ArgumentError`.

**Thread safety.** Every object is frozen once it is built, inner lists included, and no object changes after that. The same calculator or receipt can be shared between threads without locks.

## How taxes are calculated

For each unit, every rule returns its tax already rounded up to the nearest 0.05, and `Calculator` adds them. In cents:

```
tax = (price × rate / 100) rounded up to a multiple of 5
    = (price × rate).ceildiv(500) × 5
```

`ceildiv` is Ruby's integer division that rounds up, so the whole calculation stays in integers. For an imported, taxable product at 1.01:

| Rule | Exact | Rounded |
|---|---|---|
| Basic sales tax (10%) | 0.101 | 0.15 |
| Import duty (5%) | 0.0505 | 0.10 |
| Tax for one unit | | 0.25 |

Each receipt line costs (unit price + unit tax) × quantity. Sales Taxes and Total are the sums of the lines.

## Money representation

Prices are Integer cents from the moment they are read until they are printed.

- **Float** cannot store most decimal values exactly (`0.1 + 0.2` is `0.30000000000000004`), and a receipt must be exact to the cent.
- **Rational** would be exact, but it is more than this problem needs. Prices have at most two decimals and taxes are rounded to 0.05, so every value is a whole number of cents.
- **BigDecimal** would also be exact, but since Ruby 3.4 it is a bundled gem that has to be added to the Gemfile, and the problem description asks for no external libraries.

`Money` is the only place that converts between text and cents, so the rest of the code only sees integers.

## What was left out

- Matching irregular plurals and other word forms (for example with `ActiveSupport::Inflector` or a stemmer). The problem description does not allow external libraries, and every keyword in the list has a regular plural, so an optional "s" or "es" is enough.
- Taking the product type from a product catalog, or from a category list kept by the business, instead of keywords in the name. The type is decided in one place, so its source can change without touching the rest of the code.
- Reporting every invalid line of a file at once (with a cap, so a badly formatted file does not flood the output). Today the first invalid line stops that file, and its error names the line, the product and the field.
