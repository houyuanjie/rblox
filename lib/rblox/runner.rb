# frozen_string_literal: true

require 'pp'
require_relative 'scanner'
require_relative 'parser'

module Rblox
  class Runner
    attr_reader :had_error

    def initialize
      @had_error = false
    end

    def run_file(path)
      source = File.read(path)
      run(source)

      exit 65 if @had_error
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

      pp expression
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
  end
end
