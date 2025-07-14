# frozen_string_literal: true

require_relative 'scanner'
require_relative 'parser'
require_relative 'interpreter'

module Rblox
  class Runner
    attr_reader :had_error, :had_runtime_error

    def initialize
      @interpreter = Interpreter.new(self)

      @had_error = false
      @had_runtime_error = false
    end

    def run_file(path)
      source = File.read(path)
      run(source)

      exit 65 if @had_error
      exit 70 if @had_runtime_error
    end

    def run_prompt
      loop do
        print '> '
        line = $stdin.gets.chomp
        break if line == 'exit'

        run(line)

        @had_error = false
      end
    end

    def run(source)
      scanner = Scanner.new(self, source)
      tokens = scanner.scan_tokens
      parser = Parser.new(self, tokens)
      expression = parser.parse

      return if @had_error

      @interpreter.interpret(expression)
    end

    def error(line, message)
      report(line, '', message)
    end

    def report(line, where, message)
      puts "[line #{line}] Error#{where}: #{message}"
      @had_error = true
    end

    def parse_error(token, message)
      if token.type == TokenType::EOF
        report(token.line, ' at end', message)
      else
        report(token.line, " at '#{token.lexeme}'", message)
      end
    end

    def runtime_error(error)
      puts "#{error.message}\n[line #{error.token.line}]"
      @had_runtime_error = true
    end
  end
end
