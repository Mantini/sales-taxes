# frozen_string_literal: true

require_relative "sales_taxes/errors"
require_relative "sales_taxes/money"
require_relative "sales_taxes/catalog/category"
require_relative "sales_taxes/catalog/product"
require_relative "sales_taxes/taxes/rounding"
require_relative "sales_taxes/taxes/basic_sales_tax"
require_relative "sales_taxes/taxes/import_duty"
require_relative "sales_taxes/taxes/calculator"
require_relative "sales_taxes/checkout/line_item"
require_relative "sales_taxes/checkout/receipt"
require_relative "sales_taxes/checkout/receipt_formatter"

# Prints shopping receipts with basic sales tax and import duty.
module SalesTaxes
end
