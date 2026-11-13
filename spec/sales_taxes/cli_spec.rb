# frozen_string_literal: true

require "stringio"
require "tmpdir"

RSpec.describe SalesTaxes::CLI do
  let(:basket) { "1 desk lamp at 20.01\n1 paperback novel at 10.00\n" }
  # The desk lamp pays 2.001 -> 2.05 of tax, and the novel is exempt.
  let(:receipt) { "1 desk lamp: 22.06\n1 paperback novel: 10.00\nSales Taxes: 2.05\nTotal: 32.06\n" }

  # Runs the CLI and returns [exit status, stdout, stderr]. A person typing is a tty.
  def run(paths = [], stdin: "", tty: false, **collaborators)
    input = StringIO.new(stdin)
    input.define_singleton_method(:tty?) { tty }
    stdout = StringIO.new
    stderr = StringIO.new
    status = described_class.new(stdin: input, stdout:, stderr:, **collaborators).run(paths)
    [status, stdout.string, stderr.string]
  end

  # Writes a basket file to a temporary folder and yields its path.
  def with_file(content)
    Dir.mktmpdir do |dir|
      path = File.join(dir, "basket.txt")
      File.binwrite(path, content)
      yield path
    end
  end

  describe "reading a file" do
    it "prints the receipt and exits with 0" do
      with_file(basket) { |path| expect(run([path])).to eq([0, receipt, ""]) }
    end

    it "accepts the byte order mark some Windows editors put at the start" do
      with_file("\uFEFF#{basket}") { |path| expect(run([path])).to eq([0, receipt, ""]) }
    end

    it "reports a file that is not UTF-8 text, such as Latin-1 or UTF-16" do
      ["1 caf\xE9 at 1.00\n".b, "\xFF\xFE1\x00 \x00b\x00".b].each do |content|
        with_file(content) { |path| expect(run([path])).to match([1, "", /not valid UTF-8 text/]) }
      end
    end
  end

  describe "file errors (InputFileError)" do
    it "reports a missing file" do
      expect(run(["does/not/exist.txt"])).to eq([1, "", "Error: \"does/not/exist.txt\" was not found\n"])
    end

    it "reports a directory given as a file" do
      Dir.mktmpdir { |dir| expect(run([dir])).to match([1, "", /is a directory, not a file/]) }
    end

    it "reports a file the system refuses to read" do
      allow(File).to receive(:read).and_raise(Errno::EACCES)

      expect(run(["locked.txt"])).to match([1, "", /"locked\.txt" could not be read \(Permission denied/])
    end
  end

  describe "reading standard input" do
    it "reads piped input to the end, past blank lines" do
      expect(run(stdin: "1 desk lamp at 20.01\n\n1 paperback novel at 10.00\n")).to eq([0, receipt, ""])
    end

    # Empty lines before the first item are ignored; the first empty line after it ends the basket.
    it "shows a hint on stderr and stops at the empty line after the items when someone types" do
      typed = "\n1 paperback novel at 10.00\n  \n1 desk lamp at 20.01\n"

      expect(run(stdin: typed, tty: true)).to eq(
        [0, "1 paperback novel: 10.00\nSales Taxes: 0.00\nTotal: 10.00\n", "#{described_class::TYPING_HINT}\n"]
      )
    end

    it "reports a typed line that is not valid text instead of crashing" do
      expect(run(stdin: "1 caf\xC3 at 1.00\n\n".b, tty: true)).to match([1, "", /not valid UTF-8 text/])
    end
  end

  # The machine's default encoding may not be UTF-8 (LANG=C), so stdin is read as UTF-8 explicitly.
  it "reads standard input as UTF-8 whatever the machine's default encoding" do
    status, output, = run(stdin: "1 caf\xC3\xA9 at 1.00\n".b)

    expect([status, output.lines.first]).to eq([0, "1 café: 1.10\n"])
  end

  it "shows the usage on stderr and exits with 1 for more than one file" do
    expect(run(["a.txt", "b.txt"])).to eq([1, "", "#{described_class::USAGE}\n"])
  end

  describe "error handling" do
    it "prints each input error to stderr and exits with 1" do
      expect(run(stdin: "\n")).to eq([1, "", "Error: the basket has no items\n"])
      expect(run(stdin: "1 desk lamp 20.01")).to eq(
        [1, "", "Error: line 1 should look like \"<quantity> <product name> at <price>\", got \"1 desk lamp 20.01\"\n"]
      )
      expect(run(stdin: "1 desk lamp at 0.00")).to eq([1, "", "Error: line 1 (desk lamp): price must be greater than zero\n"])
    end

    it "reports any SalesTaxes::Error as an input error" do
      new_error = Class.new(SalesTaxes::Error)
      parser = Object.new
      parser.define_singleton_method(:parse) { |_text| raise new_error, "a new kind of input error" }

      expect(run(stdin: basket, parser:)).to eq([1, "", "Error: a new kind of input error\n"])
    end

    it "does not hide unexpected errors (bugs)" do
      parser = Object.new
      def parser.parse(_text) = raise(NoMethodError, "a bug")

      expect { run(stdin: basket, parser:) }.to raise_error(NoMethodError, "a bug")
    end
  end
end
