# frozen_string_literal: true

require_relative 'error'
require_relative 'token_type'

module Rblox
  class Interpreter
    def initialize(runner)
      @runner = runner
    end

    def interpret(expression)
      value = evaluate(expression)
      puts stringify(value)
    rescue RuntimeError => e
      @runner.runtime_error(e)
    end

    def visit_literal_expr(expr) = expr.value

    def visit_unary_expr(expr)
      right = evaluate(expr.right)

      case expr.operator.type
      when TokenType::MINUS
        check_number_operand(expr.operator, right)
        return -Float(right)
      when TokenType::BANG
        return !truthy?(right)
      end

      nil
    end

    def visit_binary_expr(expr)
      left = evaluate(expr.left)
      right = evaluate(expr.right)

      case expr.operator.type
      when TokenType::BANG_EQUAL
        return left != right
      when TokenType::EQUAL_EQUAL
        return left == right
      when TokenType::GREATER
        check_number_operands(expr.operator, left, right)
        return left > right
      when TokenType::GREATER_EQUAL
        check_number_operands(expr.operator, left, right)
        return left >= right
      when TokenType::LESS
        check_number_operands(expr.operator, left, right)
        return left < right
      when TokenType::LESS_EQUAL
        check_number_operands(expr.operator, left, right)
        return left <= right
      when TokenType::MINUS
        check_number_operands(expr.operator, left, right)
        return left - right
      when TokenType::PLUS
        checked_left = left.is_a?(Float) || left.is_a?(String)
        checked_right = right.is_a?(Float) || right.is_a?(String)

        unless checked_left && checked_right
          raise RuntimeError.new(expr.operator, 'Operands must be two numbers or two strings.')
        end

        return left + right
      when TokenType::SLASH
        check_number_operands(expr.operator, left, right)
        return left / right
      when TokenType::STAR
        check_number_operands(expr.operator, left, right)
        return left * right
      end

      nil
    end

    def visit_grouping_expr(expr) = evaluate(expr.expression)

    private

    def check_number_operand(operator, operand)
      return if operand.is_a?(Float)

      raise RuntimeError.new(operator, 'Operand must be a number.')
    end

    def check_number_operands(operator, left, right)
      return if left.is_a?(Float) && right.is_a?(Float)

      raise RuntimeError.new(operator, 'Operands must be numbers.')
    end

    def truthy?(object)
      return false if object.nil?
      return object if object.is_a?(TrueClass) || object.is_a?(FalseClass)

      true
    end

    def stringify(object)
      return 'nil' if object.nil?
      return format('%g', object) if object.is_a?(Float)

      object.to_s
    end

    def evaluate(expr) = expr.accept(self)
  end
end
