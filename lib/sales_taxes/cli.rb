# frozen_string_literal: true

module SalesTaxes
  # The command line. It reads one basket from a file, or from standard input when no file
  # is given, prints its receipt and returns the exit status: 0 when it worked, 1 when not.
  class CLI
    USAGE = "Usage: bin/receipt [basket file]. With no file, it reads the basket from standard input."
    TYPING_HINT = "Type one item per line as \"#{InputParser::FORMAT}\", with the price as X.XX or .XX, " \
                  "and an empty line to finish."

    def initialize(stdin: $stdin, stdout: $stdout, stderr: $stderr, parser: InputParser.new,
                   calculator: Taxes::Calculator.default, formatter: Checkout::ReceiptFormatter.new)
      @stdin = stdin
      @stdout = stdout
      @stderr = stderr
      @parser = parser
      @calculator = calculator
      @formatter = formatter
    end

    def run(paths)
      case paths
      in [] then print_receipt { stdin_text }
      in [path] then print_receipt { file_text(path) }
      else
        @stderr.puts USAGE
        1
      end
    end

    private

    # The receipt goes to stdout, or the error goes to stderr.
    def print_receipt
      receipt = Checkout::Receipt.new(line_items: @parser.parse(yield), calculator: @calculator)
      @stdout.puts @formatter.format(receipt)
      0
    rescue Error => e
      @stderr.puts "Error: #{e.message}"
      1
    end

    # Someone typing at a terminal finishes with an empty line after the items. Piped input is
    # read to the end, so a blank line inside a piped file does not cut the basket short.
    def stdin_text
      return @stdin.read.force_encoding(Encoding::UTF_8) unless @stdin.tty?

      @stderr.puts TYPING_HINT
      typed = @stdin.each_line.lazy.drop_while { |line| empty_line?(line) }.take_while { |line| !empty_line?(line) }
      typed.to_a.join.force_encoding(Encoding::UTF_8)
    end

    # Checks the raw bytes, so a typed line that is not valid text still reaches the parser's error.
    def empty_line?(line)
      line.b.strip.empty?
    end

    def file_text(path)
      raise InputFileError, "\"#{path}\" is a directory, not a file" if File.directory?(path)

      File.read(path, encoding: "UTF-8")
    rescue Errno::ENOENT
      raise InputFileError, "\"#{path}\" was not found"
    rescue SystemCallError => e
      raise InputFileError, "\"#{path}\" could not be read (#{e.message})"
    end
  end
end
