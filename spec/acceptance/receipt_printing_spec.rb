# frozen_string_literal: true

RSpec.describe "bin/receipt" do
  it "prints the receipt for a basket file"
  it "prints the same receipt from piped input"
  it "gives the same result when many threads share the same objects"
  it "keeps shared objects and their inner lists (receipt lines, tax rules) frozen"
end
