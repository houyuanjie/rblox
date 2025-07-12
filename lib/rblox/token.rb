# frozen_string_literal: true

module Rblox
  class Token
    attr_reader :type, :lexeme, :literal, :line

    def initialize(type, lexeme, literal, line)
      @type = type
      @lexeme = lexeme
      @literal = literal
      @line = line
    end

    def to_s
      "#{type} #{lexeme} #{literal}"
    end
  end
end
