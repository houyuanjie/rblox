# frozen_string_literal: true

require_relative 'scanner'
require_relative 'parser'
require_relative 'resolver'
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
        line = $stdin.gets&.chomp
        break if line.nil? || %w[exit quit].include?(line)

        run(line)

        @had_error = false
      end
    end

    def run(source)
      scanner = Scanner.new(self, source)
      tokens = scanner.scan_tokens
      parser = Parser.new(self, tokens)
      statements = parser.parse

      return if @had_error

      resolver = Resolver.new(self, @interpreter)
      resolver.resolve(statements)

      return if @had_error

      @interpreter.interpret(statements)
    end

    def error(token_or_line, message)
      if token_or_line.is_a?(Token)
        lexeme = token_or_line.type == TokenType::EOF ? 'end' : token_or_line.lexeme
        report(token_or_line.line, " at '#{lexeme}'", message)
      else
        report(token_or_line, '', message)
      end
    end

    def runtime_error(error)
      puts "#{error.message}\n[line #{error.token.line}]"
      @had_runtime_error = true
    end

    private

    def report(line, where, message)
      puts "[line #{line}] Error#{where}: #{message}"
      @had_error = true
    end
  end
end
