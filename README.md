# Sales Taxes

Prints shopping receipts with basic sales tax and import duty.

## Requirements

- Ruby 4.0 (tested with 4.0.9). The version is pinned in `.ruby-version`.
- Bundler.

There are no runtime dependencies. RSpec is used only for the tests.

## Proposal

The application reads a shopping basket and prints its receipt: each item with its price including taxes, then the total sales taxes and the total cost.

Basket: each line is one purchase, `<quantity> <product name> at <price>`, for example `2 book of poems at 10.00`. A product is imported when its name has the word "imported". The input does not say the product type (book, food, medical or other), so it comes from keywords in the name.

Taxes:
- Basic sales tax: 10% on every product, except books, food and medical products.
- Import duty: 5% on every imported product, with no exemptions.
- Each tax is rounded up to the nearest 0.05.

Input: a text file, or standard input when no file is given.

Errors: when the basket has a problem (a line in the wrong format, a zero quantity, no items, a file that cannot be read), the application prints an error and no receipt. One invalid line is enough to reject the basket, because a receipt with a missing item would be wrong.

## Assumptions

- The input must follow the format of the problem description: the quantity in digits, the name, " at " and a price with two decimals (`12.49`, or `.90` below one), all separated by single spaces. Extra spaces, tabs, `12.5` or `AT` are rejected with the line number. I chose not to guess, because a wrong guess prints a wrong receipt. Blank lines are skipped, lines can end in LF, CRLF or CR, and a byte order mark at the start is ignored.
- Quantities and prices must be greater than zero.
- The product type comes from keywords in the name, listed in `Catalog::Category`:
  - Books: book, novel, textbook, paperback, encyclopedia.
  - Food: chocolate, bread, cheese, coffee, tea, fruit.
  - Medical: pill, capsule, medicine, syrup, bandage, vitamin.

  A keyword matches as a whole word, in singular or plural (with an "s") and in any letter case. "old BOOKS" is a book, "notebook" is not. A hyphen splits words, so "e-book" is also a book. A product without a keyword is taxed, since only these three types are exempt.

  This is a simple guess and it can be wrong: "steaks" are taxed because "steak" is not a keyword, and "headache tablets" are taxed because I left "tablet" out, so a tablet computer is not exempt. A real system would get the type from a product catalog.
- "imported" must be a whole word, in any position and letter case. Negations are not understood, so "non-imported" still counts as imported.
- Tax is calculated for one unit and then multiplied by the quantity. The third example only works this way. For 3 imported boxes of chocolates at 11.25:
  - per unit: 3 × (11.25 + 0.60) = 35.55, the expected output;
  - for the whole line: 33.75 + 1.70 = 35.45, which is wrong.
- Each tax is rounded on its own and then added, because the rounding rule is given per tax rate ("for a tax rate of n%..."). Rounding the combined 15% gives the same results for the examples, but not for every price. At 1.01:
  - each tax on its own: 0.15 + 0.10 = 0.25;
  - the combined 15%: 0.1515, rounded to 0.20.

  The Calculator spec has a test for this case.
- The price comes after the last " at ", so a name can contain "at" or numbers, like `1 painting of a cat at night at 12.00`.
- Lines are printed in the input order, and the same product on two lines prints as two lines.

## Setup

```bash
ruby -v          # should print ruby 4.0.x
bundle install
```

On Windows, install Ruby 4.0 with [RubyInstaller](https://rubyinstaller.org/). On macOS or Linux, use a version manager, like `rbenv install 4.0.9`.

## How to run

The `input` folder has the three baskets from the problem description.

```bash
bin/receipt input/basket_1.txt
```

```
2 book: 24.98
1 music CD: 16.49
1 chocolate bar: 0.85
Sales Taxes: 1.50
Total: 42.32
```

Without a file, the basket is read from standard input:
- piped: `cat input/basket_2.txt | bin/receipt`;
- typed: run `bin/receipt`, type one item per line and finish with an empty line. A hint on stderr says so.

On Windows cmd or PowerShell, run it with Ruby: `ruby bin/receipt input/basket_1.txt`.

The receipt goes to stdout and errors go to stderr. The exit status is 0 when the receipt is printed and 1 when the input has an error. With more than one file, it prints the usage.

To save the receipt to a file, redirect stdout: `bin/receipt input/basket_1.txt > receipt.txt`.

## How to test

```bash
bundle exec rspec
```

`spec/sales_taxes` follows the structure of `lib`, plus `thread_safety_spec.rb`. `spec/acceptance` runs `bin/receipt` as a real process, including the three sample baskets.

## Design

The code is in `lib/sales_taxes`. Each class or module has its own file, except the error classes, which are together in `errors.rb`.

| Module | Classes | Job |
|---|---|---|
| `Money` | | Turns price text into Integer cents and back |
| `Catalog` | `Category`, `Product` | What is being bought, with its type and origin taken from the name |
| `Taxes` | `Rounding`, `BasicSalesTax`, `ImportDuty`, `Calculator` | How much tax one unit pays |
| `Checkout` | `LineItem`, `Receipt`, `ReceiptFormatter` | The basket, its totals and the printed text |
| `SalesTaxes` (top level) | `InputParser` | Turns the basket text into line items |
| `SalesTaxes` (top level) | `CLI` | Reads a file or standard input and prints the receipt |

The objects use composition, not inheritance:
- `Product` has a `Category`;
- `LineItem` has a quantity and a `Product`;
- `Receipt` is built from `LineItem`s and a `Calculator`;
- `Calculator` has a list of tax rules;
- `CLI` gets a parser, a calculator and a formatter in its constructor, with defaults, so the tests can replace them.

Tax rules: each rule has `amount_for(product)`, and `Calculator` adds the results. A new tax is a new rule passed to the calculator. There is no base class, because the rules only share the rounding, which is in `Taxes::Rounding`.

Exemptions: the exempt categories are listed in `BasicSalesTax`, because the exemption belongs to that tax. The import duty has none.

Errors: input problems are subclasses of `SalesTaxes::Error`, and `CLI` rescues that class. `InputParser` checks the line format, `Money` the price format, and `Product` and `LineItem` that values are greater than zero. Any other error is a bug and is not rescued.

Thread safety: products, line items, receipts and their lines, and the calculator and its list of rules are frozen after they are built. The parser, the formatter and the tax rules have no state. So these objects can be shared between threads without locks. `CLI` cannot, because it holds the input and output streams.

## How taxes are calculated

Each rule returns the tax for one unit, already rounded up to 0.05, and `Calculator` adds them. In cents:

```
tax = (price × rate / 100) rounded up to a multiple of 5
    = (price × rate).ceildiv(500) × 5
```

`ceildiv` divides and rounds up, so the math stays in integers. For an imported, taxable product at 1.01:

| Rule | Exact | Rounded |
|---|---|---|
| Basic sales tax (10%) | 0.101 | 0.15 |
| Import duty (5%) | 0.0505 | 0.10 |
| Tax for one unit | | 0.25 |

## Money representation

I store money as Integer cents, from reading the price to printing the receipt. `Money` is the only place that converts text to cents and back.

I chose Integer over the other numeric types Ruby has for money:

- Float: most decimal values are not exact (`0.1 + 0.2` is `0.30000000000000004`), and a receipt must be exact to the cent.
- Rational: exact, but more than needed here. Prices have two decimals and taxes are rounded to 0.05, so every value is a whole number of cents.
- BigDecimal: also exact, but since Ruby 3.4 it is a bundled gem that must be added to the Gemfile, and the problem description asks for no external libraries.

## What was left out

What I would add with more time, or in a real system:

- A product catalog. Today the type and the import flag are guessed from the name in `Catalog::Product.from_name`, and a catalog lookup would replace that method.
- Irregular plurals and other word forms, for example with `ActiveSupport::Inflector`. It is an external library, which the problem description does not allow, and all keywords today have a regular plural.
- Decimal tax rates, like 2.5%. Today the rates are whole percentages.
- A more forgiving input format, with extra spaces, tabs or prices like `12.5`. Today the input must follow the format of the problem description exactly.
- Several files in one call. Today a shell loop does the same: `for f in input/*.txt; do bin/receipt "$f"; done`.
- `--help` and Ctrl+C handling.
- Reporting all invalid lines at once. Today the first invalid line stops the basket, and the error shows its line number.
