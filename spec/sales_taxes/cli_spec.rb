# frozen_string_literal: true

RSpec.describe "SalesTaxes::CLI" do
  describe "reading a file" do
    it "prints the receipt and exits with 0"
    it "accepts Windows line endings (CRLF)"
    it "reports an input error on stderr, exits with 1 and prints no receipt"
  end

  describe "file errors (InputFileError)" do
    it "reports a missing file"
    it "reports a directory given as a file"
    it "reports a file that is not valid text"
  end

  describe "reading several files" do
    it "reports how many files were read on stderr"
    it "prints each receipt under its file name, separated by a blank line"
    it "shows a failed file's error in place of its receipt, keeps the others and exits with 1"
  end

  describe "reading typed lines" do
    it "reads until an empty line or the end of the input"
    it "reports nothing typed or a bad line on stderr, exits with 1 and prints no receipt"
    it "exits quietly with 130 on Ctrl+C"
  end

  describe "error handling" do
    it "gives each kind of error its own message (file, empty basket, malformed line, invalid value)"
    it "rescues every expected error through the shared SalesTaxes::Error"
    it "does not hide unexpected errors (bugs)"
  end
end
