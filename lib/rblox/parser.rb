# frozen_string_literal: true

require_relative 'error'
require_relative 'token_type'
require_relative 'expr'
require_relative 'stmt'

module Rblox
  class Parser
    class ParseError < Error; end

    def initialize(runner, tokens)
      @runner = runner

      @tokens = tokens
      @current = 0
    end

    def parse
      statements = []
      statements << declaration until at_end?
      statements
    end

    private

    def declaration
      return var_declaration if match?(TokenType::VAR)

      statement
    rescue ParseError
      synchronize
      nil
    end

    def var_declaration
      name = consume(TokenType::IDENTIFIER, 'Expect variable name.')
      initializer = nil
      initializer = expression if match?(TokenType::EQUAL)
      consume(TokenType::SEMICOLON, "Expect ';' after variable declaration.")
      Stmt::Var.new(name, initializer)
    end

    def statement
      return print_statement if match?(TokenType::PRINT)
      return Stmt::Block.new(block) if match?(TokenType::LEFT_BRACE)

      expression_statement
    end

    def print_statement
      value = expression
      consume(TokenType::SEMICOLON, "Expect ';' after value.")
      Stmt::Print.new(value)
    end

    def expression_statement
      expr = expression
      consume(TokenType::SEMICOLON, "Expect ';' after expression.")
      Stmt::Expression.new(expr)
    end

    def block
      statements = []
      statements << declaration until checked?(TokenType::RIGHT_BRACE) || at_end?
      consume(TokenType::RIGHT_BRACE, "Expect '}' after block.")
      statements
    end

    def expression = assignment

    def assignment
      expr = equality

      if match?(TokenType::EQUAL)
        equals = previous
        value = assignment

        if expr.is_a?(Expr::Variable)
          name = expr.name
          return Expr::Assign.new(name, value)
        end

        error(equals, 'Invalid assignment target.')
      end

      expr
    end

    def equality
      expr = comparison

      while match?(TokenType::BANG_EQUAL, TokenType::EQUAL_EQUAL)
        operator = previous
        right = comparison
        expr = Expr::Binary.new(expr, operator, right)
      end

      expr
    end

    def comparison
      expr = term

      while match?(TokenType::GREATER, TokenType::GREATER_EQUAL, TokenType::LESS, TokenType::LESS_EQUAL)
        operator = previous
        right = term
        expr = Expr::Binary.new(expr, operator, right)
      end

      expr
    end

    def term
      expr = factor

      while match?(TokenType::MINUS, TokenType::PLUS)
        operator = previous
        right = factor
        expr = Expr::Binary.new(expr, operator, right)
      end

      expr
    end

    def factor
      expr = unary

      while match?(TokenType::SLASH, TokenType::STAR)
        operator = previous
        right = unary
        expr = Expr::Binary.new(expr, operator, right)
      end

      expr
    end

    def unary
      if match?(TokenType::BANG, TokenType::MINUS)
        operator = previous
        right = unary
        return Expr::Unary.new(operator, right)
      end

      primary
    end

    def primary
      if match?(TokenType::FALSE)
        Expr::Literal.new(false)
      elsif match?(TokenType::TRUE)
        Expr::Literal.new(true)
      elsif match?(TokenType::NIL)
        Expr::Literal.new(nil)
      elsif match?(TokenType::NUMBER, TokenType::STRING)
        Expr::Literal.new(previous.literal)
      elsif match?(TokenType::IDENTIFIER)
        Expr::Variable.new(previous)
      elsif match?(TokenType::LEFT_PAREN)
        expr = expression
        consume(TokenType::RIGHT_PAREN, "Expect ')' after expression.")
        Expr::Grouping.new(expr)
      else
        raise error(peek, 'Expect expression.')
      end
    end

    def match?(*types)
      types.each do |type|
        if checked?(type)
          advance
          return true
        end
      end

      false
    end

    def consume(type, message)
      return advance if checked?(type)

      raise error(peek, message)
    end

    def checked?(type)
      return false if at_end?

      peek.type == type
    end

    def advance
      @current += 1 unless at_end?

      previous
    end

    def at_end? = peek.type == TokenType::EOF

    def peek = @tokens[@current]

    def previous = @tokens[@current - 1]

    def error(token, message)
      @runner.parse_error(token, message)
      ParseError.new
    end

    def synchronize
      advance

      until at_end?
        return if previous.type == TokenType::SEMICOLON

        case peek.type
        when TokenType::CLASS,
            TokenType::FUN,
            TokenType::VAR,
            TokenType::FOR,
            TokenType::IF,
            TokenType::WHILE,
            TokenType::PRINT,
            TokenType::RETURN
          return
        end
      end

      advance
    end
  end
end
