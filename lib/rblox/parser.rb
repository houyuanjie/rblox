# frozen_string_literal: true

require_relative 'error'
require_relative 'token_type'
require_relative 'expr'

module Rblox
  class Parser
    class ParseError < Error; end

    def initialize(runner, tokens)
      @runner = runner

      @tokens = tokens
      @current = 0
    end

    def parse
      expression
    rescue ParseError
      nil
    end

    private

    def expression = equality

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
      advance if checked?(type)

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
