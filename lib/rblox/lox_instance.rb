# frozen_string_literal: true

require_relative 'error'

module Rblox
  class LoxInstance
    attr_reader :lox_class, :fields

    def initialize(lox_class)
      @lox_class = lox_class
      @fields = {}
    end

    def get(name)
      lexeme = name.lexeme
      return @fields[lexeme] if @fields.key?(lexeme)

      method = @lox_class.find_method(lexeme)
      return method.bind(self) if method

      raise Rblox::RuntimeError.new(name, "Undefined property '#{name.lexeme}'.")
    end

    def set(name, value) = @fields[name.lexeme] = value

    def to_s = "instance #{@lox_class.name}"
  end
end
