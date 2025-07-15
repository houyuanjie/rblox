# frozen_string_literal: true

require_relative 'error'
require_relative 'token_type'
require_relative 'environment'

module Rblox
  class Interpreter
    def initialize(runner)
      @runner = runner
      @environment = Environment.new
    end

    def interpret(statements)
      statements.each do |stmt|
        execute(stmt)
      end
    rescue RuntimeError => e
      @runner.runtime_error(e)
    end

    def visit_literal_expr(expr) = expr.value

    def visit_logical_expr(expr)
      left = evaluate(expr.left)

      operator_type = expr.operator.type
      return left if operator_type == TokenType::OR && truthy?(left)
      return left if operator_type == TokenType::AND && !truthy?(left)

      evaluate(expr.right)
    end

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

    def visit_variable_expr(expr) = @environment.get(expr.name)

    def visit_assign_expr(expr)
      value = evaluate(expr.value)
      @environment.assign(expr.name, value)
      value
    end

    def visit_var_stmt(stmt)
      value = stmt.initializer ? evaluate(stmt.initializer) : nil

      @environment.define(stmt.name.lexeme, value)
      nil
    end

    def visit_block_stmt(stmt)
      execute_block(stmt.statements, Environment.new(@environment))
      nil
    end

    def visit_expression_stmt(stmt)
      evaluate(stmt.expression)
      nil
    end

    def visit_print_stmt(stmt)
      value = evaluate(stmt.expression)
      print stringify(value)
      nil
    end

    def visit_println_stmt(stmt)
      value = evaluate(stmt.expression)
      puts stringify(value)
      nil
    end

    def visit_if_stmt(stmt)
      if truthy?(evaluate(stmt.condition))
        execute(stmt.then_branch)
      elsif !stmt.else_branch.nil?
        execute(stmt.else_branch)
      end
    end

    def visit_while_stmt(stmt)
      execute(stmt.body) while truthy?(evaluate(stmt.condition))
    end

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
      return eval %("#{object}"), binding, __FILE__, __LINE__ if object.is_a?(String) # "#{object}"
      return format '%g', object if object.is_a?(Float)

      object.to_s
    end

    def evaluate(expr) = expr.accept(self)

    def execute(stmt) = stmt.accept(self)

    def execute_block(statements, environment)
      previous = @environment
      @environment = environment

      statements.each do |stmt|
        execute(stmt)
      end
    ensure
      @environment = previous
    end
  end
end
