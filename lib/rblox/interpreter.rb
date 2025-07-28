# frozen_string_literal: true

require_relative 'error'
require_relative 'token_type'
require_relative 'environment'
require_relative 'callable'

module Rblox
  class Interpreter
    attr_reader :globals

    def initialize(runner)
      @runner = runner

      @globals = Environment.new
      @environment = @globals

      @locals = {}

      @globals.define(:clock, Callable.new(0) { Time.now })
    end

    def interpret(statements)
      execute(statements)
    rescue Rblox::RuntimeError => e
      @runner.runtime_error(e)
    end

    def resolve(expr, depth) = @locals[expr] = depth

    def execute_block(statements, environment)
      previous = @environment
      @environment = environment

      begin
        execute(statements)
      ensure
        @environment = previous
      end
    end

    def visit_block_stmt(stmt) = execute_block(stmt.statements, Environment.new(@environment))

    def visit_expression_stmt(stmt) = evaluate(stmt.expression)

    def visit_function_stmt(stmt)
      function = Callable.function(stmt, @environment)
      @environment.define(stmt.name, function)
    end

    def visit_if_stmt(stmt)
      if truthy?(evaluate(stmt.condition))
        execute(stmt.then_branch)
      elsif stmt.else_branch
        execute(stmt.else_branch)
      end
    end

    def visit_print_stmt(stmt)
      value = evaluate(stmt.expression)
      print stringify(value)
    end

    def visit_println_stmt(stmt)
      value = evaluate(stmt.expression)
      puts stringify(value)
    end

    def visit_return_stmt(stmt)
      value = stmt.value ? evaluate(stmt.value) : nil

      raise Rblox::Return, value
    end

    def visit_var_stmt(stmt)
      value = stmt.initializer ? evaluate(stmt.initializer) : nil
      @environment.define(stmt.name, value)
    end

    def visit_while_stmt(stmt)
      execute(stmt.body) while truthy?(evaluate(stmt.condition))
    end

    def visit_assign_expr(expr)
      value = evaluate(expr.value)

      if (distance = @locals[expr])
        @environment.assign_at(distance, expr.name, value)
      else
        @globals.assign(expr.name, value)
      end

      value
    end

    # visit_binary_expr dispatches operators very dynamically,
    # let steep the type checker ignore it
    #
    # steep:ignore:start
    def visit_binary_expr(expr)
      left = evaluate(expr.left)
      right = evaluate(expr.right)

      case expr.operator.type
      when TokenType::BANG_EQUAL
        left != right
      when TokenType::EQUAL_EQUAL
        left == right
      when TokenType::GREATER
        check_number_operands(expr.operator, left, right)
        left > right
      when TokenType::GREATER_EQUAL
        check_number_operands(expr.operator, left, right)
        left >= right
      when TokenType::LESS
        check_number_operands(expr.operator, left, right)
        left < right
      when TokenType::LESS_EQUAL
        check_number_operands(expr.operator, left, right)
        left <= right
      when TokenType::MINUS
        check_number_operands(expr.operator, left, right)
        left - right
      when TokenType::PLUS
        both_float = left.is_a?(Float) && right.is_a?(Float)
        both_string = left.is_a?(String) && right.is_a?(String)

        unless both_float || both_string
          raise Rblox::RuntimeError.new(expr.operator, 'Operands must be two numbers or two strings.')
        end

        left + right
      when TokenType::SLASH
        check_number_operands(expr.operator, left, right)
        left / right
      when TokenType::STAR
        check_number_operands(expr.operator, left, right)
        left * right
      end
    end
    # steep:ignore:end

    def visit_call_expr(expr)
      callee = evaluate(expr.callee)
      arguments = expr.arguments.map { |arg| evaluate(arg) }

      raise Rblox::RuntimeError.new(expr.paren, 'Can only call functions and classes.') unless callee.is_a?(Callable)

      unless arguments.size == callee.arity
        raise Rblox::RuntimeError.new(expr.paren, "Expected #{callee.arity} arguments but got #{arguments.size}.")
      end

      callee.call(self, arguments)
    end

    def visit_grouping_expr(expr) = evaluate(expr.expression)

    def visit_literal_expr(expr) = expr.value || raise

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
      when TokenType::BANG
        !truthy?(right)
      when TokenType::MINUS
        check_number_operand(expr.operator, right)
        value = Float(right) || raise

        -value
      else
        raise
      end
    end

    def visit_variable_expr(expr) = look_up_variable(expr.name, expr)

    private

    def evaluate(expr) = expr.accept(self)

    def execute(stmt)
      if stmt.is_a?(Array)
        stmt.each { |s| execute(s) }
      else
        stmt.accept(self)
      end
    end

    def look_up_variable(name, expr)
      if (distance = @locals[expr])
        @environment.get_at(distance, name)
      else
        @globals.get(name)
      end
    end

    def check_number_operand(operator, operand)
      return if operand.is_a?(Float)

      raise Rblox::RuntimeError.new(operator, 'Operand must be a number.')
    end

    def check_number_operands(operator, left, right)
      return if left.is_a?(Float) && right.is_a?(Float)

      raise Rblox::RuntimeError.new(operator, 'Operands must be numbers.')
    end

    def truthy?(object)
      return false if object.nil?
      return object if object.is_a?(TrueClass) || object.is_a?(FalseClass)

      true
    end

    def stringify(object)
      return 'nil' if object.nil?
      return unescaped(object) if object.is_a?(String)
      return format '%g', object if object.is_a?(Float)

      object.to_s
    end

    def unescaped(string)
      unescapes = {
        '\\\\' => '\\',
        '\\"' => '"',
        '\\0' => "\0",
        '\\a' => "\a",
        '\\b' => "\b",
        '\\t' => "\t",
        '\\n' => "\n",
        '\\v' => "\v",
        '\\f' => "\f",
        '\\r' => "\r"
      }

      string.gsub(Regexp.union(unescapes.keys)) do |m|
        unescapes[m]
      end
    end
  end
end
