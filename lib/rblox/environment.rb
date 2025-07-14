# frozen_string_literal: true

require_relative 'error'

module Rblox
  class Environment
    attr_reader :enclosing

    def initialize(enclosing = nil)
      @enclosing = enclosing
      @values = {}
    end

    def get(name)
      if @values.key?(name.lexeme)
        @values[name.lexeme]
      elsif @enclosing
        @enclosing.get(name)
      else
        raise RuntimeError.new(name, "Undefined variable '#{name.lexeme}'.")
      end
    end

    def assign(name, value)
      if @values.key?(name.lexeme)
        @values[name.lexeme] = value
        nil
      elsif @enclosing
        @enclosing.assign(name, value)
      else
        raise RuntimeError.new(name, "Undefined variable '#{name.lexeme}'.")
      end
    end

    def define(name, value) = @values[name] = value
  end
end
