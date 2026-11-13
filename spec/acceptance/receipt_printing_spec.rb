# frozen_string_literal: true

require "open3"
require "rbconfig"
require "tmpdir"

# Runs the real executable, with one basket that mixes every case: exempt and taxable,
# local and imported, a quantity above one, and prices whose rounding only comes out right
# with tax per unit and each tax rounded on its own.
RSpec.describe "bin/receipt" do
  let(:executable) { File.expand_path("../../bin/receipt", __dir__) }

  let(:basket) do
    <<~BASKET
      2 paperback novel at 10.00
      1 imported desk lamp at 1.01
      3 imported cheeses at 1.01
      1 desk lamp at 20.01
    BASKET
  end

  # paperback novel: exempt and local     2 x 10.00          = 20.00
  # imported desk lamp: 0.15 + 0.10       1.01 + 0.25        =  1.26
  # imported cheeses: 0.10 per unit       3 x (1.01 + 0.10)  =  3.33
  # desk lamp: 2.001 -> 2.05              20.01 + 2.05       = 22.06
  let(:receipt) do
    <<~RECEIPT
      2 paperback novel: 20.00
      1 imported desk lamp: 1.26
      3 imported cheeses: 3.33
      1 desk lamp: 22.06
      Sales Taxes: 2.60
      Total: 46.65
    RECEIPT
  end

  # Runs the real executable and returns [exit status, stdout, stderr], like the CLI spec.
  def run_receipt(*args, stdin: "")
    out, err, status = Open3.capture3(RbConfig.ruby, executable, *args, stdin_data: stdin)
    [status.exitstatus, out, err]
  end

  it "prints the receipt for a basket file" do
    Dir.mktmpdir do |dir|
      path = File.join(dir, "basket.txt")
      File.write(path, basket)

      expect(run_receipt(path)).to eq([0, receipt, ""])
    end
  end

  it "prints the same receipt from piped input" do
    expect(run_receipt(stdin: basket)).to eq([0, receipt, ""])
  end

  it "prints the error on stderr and exits with 1 for a bad basket" do
    expect(run_receipt(stdin: "1 desk lamp 20.01\n")).to match([1, "", /\AError: line 1 /])
  end

  # The problem description asks, as a minimum, for the supplied test data to work.
  # These are its three inputs (in input/) and its three expected outputs, word for word.
  {
    "basket_1.txt" => <<~RECEIPT,
      2 book: 24.98
      1 music CD: 16.49
      1 chocolate bar: 0.85
      Sales Taxes: 1.50
      Total: 42.32
    RECEIPT
    "basket_2.txt" => <<~RECEIPT,
      1 imported box of chocolates: 10.50
      1 imported bottle of perfume: 54.65
      Sales Taxes: 7.65
      Total: 65.15
    RECEIPT
    "basket_3.txt" => <<~RECEIPT
      1 imported bottle of perfume: 32.19
      1 bottle of perfume: 20.89
      1 packet of headache pills: 9.75
      3 imported boxes of chocolates: 35.55
      Sales Taxes: 7.90
      Total: 98.38
    RECEIPT
  }.each do |file, expected|
    it "prints the expected receipt for the supplied #{file}" do
      expect(run_receipt(File.expand_path("../../input/#{file}", __dir__))).to eq([0, expected, ""])
    end
  end
end
