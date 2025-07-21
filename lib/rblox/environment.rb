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
      name = lexeme_or(name)

      if @values.key?(name)
        @values[name]
      elsif @enclosing
        @enclosing.get(name)
      else
        raise Rblox::RuntimeError.new(name, "Undefined variable '#{name}'.")
      end
    end

    def assign(name, value)
      name = lexeme_or(name)

      if @values.key?(name)
        @values[name] = value
      elsif @enclosing
        @enclosing.assign(name, value)
      else
        raise Rblox::RuntimeError.new(name, "Undefined variable '#{name}'.")
      end
    end

    def define(name, value) = @values[lexeme_or(name)] = value

    def ancestor(distance)
      environment = self

      distance.times do
        environment = environment.enclosing
      end

      environment
    end

    def get_at(distance, name) = ancestor(distance).values[lexeme_or(name)]

    def assign_at(distance, name, value) = ancestor(distance).values[lexeme_or(name)] = value

    def to_s = "Environment(values = #{@values}, enclosing = #{@enclosing})"

    protected

    attr_reader :values

    private

    def lexeme_or(name) = name.respond_to?(:lexeme) ? name.lexeme : name
  end
end
