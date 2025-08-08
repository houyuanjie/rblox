# frozen_string_literal: true

module Rblox
  class Resolver
    module FunctionType
      NONE = :fn_none
      FUNCTION = :fn_function
    end

    def initialize(runner, interpreter)
      @runner = runner

      @interpreter = interpreter
      @scopes = []
      @current_function = FunctionType::NONE
    end

    def resolve(expr_or_stmt)
      if expr_or_stmt.is_a?(Array)
        expr_or_stmt.each { |child| resolve(child) }
      else
        expr_or_stmt.accept(self)
      end
    end

    def visit_block_stmt(stmt)
      begin_scope
      resolve(stmt.statements)
      end_scope
    end

    def visit_class_stmt(stmt)
      declare(stmt.name)
      define(stmt.name)
    end

    def visit_expression_stmt(stmt) = resolve(stmt.expression)

    def visit_function_stmt(stmt)
      declare(stmt.name)
      define(stmt.name)

      resolve_function(stmt, FunctionType::FUNCTION)
    end

    def visit_if_stmt(stmt)
      resolve(stmt.condition)
      resolve(stmt.then_branch)
      resolve(stmt.else_branch) if stmt.else_branch
    end

    def visit_print_stmt(stmt) = resolve(stmt.expression)

    def visit_println_stmt(stmt) = resolve(stmt.expression)

    def visit_return_stmt(stmt)
      @runner.error(stmt.keyword, "Can't return from top-level code.") if @current_function == FunctionType::NONE

      resolve(stmt.value) if stmt.value
    end

    def visit_var_stmt(stmt)
      declare(stmt.name)
      resolve(stmt.initializer) if stmt.initializer
      define(stmt.name)
    end

    def visit_while_stmt(stmt)
      resolve(stmt.condition)
      resolve(stmt.body)
    end

    def visit_assign_expr(expr)
      resolve(expr.value)
      resolve_local(expr, expr.name)
    end

    def visit_binary_expr(expr)
      resolve(expr.left)
      resolve(expr.right)
    end

    def visit_call_expr(expr)
      resolve(expr.callee)
      resolve(expr.arguments)
    end

    def visit_get_expr(expr)
      resolve(expr.object)
    end

    def visit_grouping_expr(expr) = resolve(expr.expression)

    def visit_literal_expr(_) = nil

    def visit_logical_expr(expr)
      resolve(expr.left)
      resolve(expr.right)
    end

    def visit_set_expr(expr)
      resolve(expr.value)
      resolve(expr.object)
    end

    def visit_unary_expr(expr) = resolve(expr.right)

    def visit_variable_expr(expr)
      if !@scopes.empty? && @scopes.last[expr.name.lexeme] == false
        @runner.error(expr.name, "Can't read local variable in its own initializer.")
      end

      resolve_local(expr, expr.name)
    end

    private

    def resolve_function(function, type)
      enclosing_function = @current_function
      @current_function = type

      begin_scope

      function.params.each do |param|
        declare(param)
        define(param)
      end

      resolve(function.body)

      end_scope

      @current_function = enclosing_function
    end

    def begin_scope = @scopes << {}

    def end_scope = @scopes.pop

    def declare(name)
      return if @scopes.empty?

      scope = @scopes.last
      @runner.error(name, 'Already a variable with this name in this scope.') if scope.key?(name.lexeme)
      scope[name.lexeme] = false
    end

    def define(name)
      return if @scopes.empty?

      scope = @scopes.last
      scope[name.lexeme] = true
    end

    def resolve_local(expr, name)
      last_scope_index = @scopes.size - 1
      @scopes.each_with_index.reverse_each do |scope, index|
        next unless scope.key?(name.lexeme)

        @interpreter.resolve(expr, last_scope_index - index)
        break
      end
    end
  end
end
