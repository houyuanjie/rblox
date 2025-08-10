# frozen_string_literal: true

require_relative 'error'
require_relative 'token'

module Rblox
  class Environment
    attr_reader :enclosing, :values

    def initialize(enclosing = nil)
      @enclosing = enclosing
      @values = {}
    end

    def get(name)
      lexeme = lexeme_or(name)

      if values.key?(lexeme)
        values[lexeme]
      elsif enclosing
        enclosing.get(name)
      else
        raise Rblox::RuntimeError.new(name, "Undefined variable '#{name}'.")
      end
    end

    def assign(name, value)
      lexeme = lexeme_or(name)

      if values.key?(lexeme)
        values[lexeme] = value
      elsif enclosing
        enclosing.assign(name, value)
      else
        raise Rblox::RuntimeError.new(name, "Undefined variable '#{name}'.")
      end
    end

    def define(name, value) = values[lexeme_or(name)] = value

    def ancestor(distance)
      # @type var environment: Environment
      environment = self

      distance.times do
        environment = environment.enclosing || raise
      end

      environment
    end

    def get_at(distance, name) = ancestor(distance).values[lexeme_or(name)]

    def assign_at(distance, name, value) = ancestor(distance).values[lexeme_or(name)] = value

    def to_s = "Environment(values = #{values}, enclosing = #{enclosing})"

    private

    def lexeme_or(name) = name.is_a?(Token) ? name.lexeme : name.to_s
  end
end
