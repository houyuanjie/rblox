# frozen_string_literal: true

require_relative 'scanner'

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

      tokens.each do |token|
        puts token
      end
    end

    def error(line, message)
      report(line, '', message)
    end

    def report(line, where, message)
      puts "[line #{line}] Error#{where}: #{message}"
      @had_error = true
    end
  end
end
