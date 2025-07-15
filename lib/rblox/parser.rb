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
      initializer = match?(TokenType::EQUAL) ? expression : nil
      consume(TokenType::SEMICOLON, "Expect ';' after variable declaration.")

      Stmt::Var.new(name, initializer)
    end

    def statement
      return for_statement if match?(TokenType::FOR)
      return if_statement if match?(TokenType::IF)
      return print_statement if match?(TokenType::PRINT)
      return println_statement if match?(TokenType::PRINTLN)
      return while_statement if match?(TokenType::WHILE)
      return Stmt::Block.new(block) if match?(TokenType::LEFT_BRACE)

      expression_statement
    end

    def for_statement
      consume(TokenType::LEFT_PAREN, "Expect '(' after 'for'.")
      initializer = if match?(TokenType::SEMICOLON)
                      nil
                    elsif match?(TokenType::VAR)
                      var_declaration
                    else
                      expression_statement
                    end

      condition = checked?(TokenType::SEMICOLON) ? nil : expression
      consume(TokenType::SEMICOLON, "Expect ';' after loop condition.")

      increment = checked?(TokenType::RIGHT_PAREN) ? nil : expression
      consume(TokenType::RIGHT_PAREN, "Expect ')' after for clauses.")

      body = statement

      # desugaring

      body = Stmt::Block.new([body, Stmt::Expression.new(increment)]) if increment
      condition = Expr::Literal.new(true) if condition.nil?
      body = Stmt::While.new(condition, body)
      body = Stmt::Block.new([initializer, body]) if initializer

      body
    end

    def if_statement
      consume(TokenType::LEFT_PAREN, "Expect '(' after 'if'.")
      condition = expression
      consume(TokenType::RIGHT_PAREN, "Expect ')' after if condition.")

      then_branch = statement
      else_branch = match?(TokenType::ELSE) ? statement : nil

      Stmt::If.new(condition, then_branch, else_branch)
    end

    def print_statement
      value = expression
      consume(TokenType::SEMICOLON, "Expect ';' after value.")

      Stmt::Print.new(value)
    end

    def println_statement
      value = expression
      consume(TokenType::SEMICOLON, "Expect ';' after value.")

      Stmt::Println.new(value)
    end

    def while_statement
      consume(TokenType::LEFT_PAREN, "Expect '(' after 'while'.")
      condition = expression
      consume(TokenType::RIGHT_PAREN, "Expect ')' after condition.")
      body = statement

      Stmt::While.new(condition, body)
    end

    def block
      statements = []
      statements << declaration until checked?(TokenType::RIGHT_BRACE) || at_end?
      consume(TokenType::RIGHT_BRACE, "Expect '}' after block.")
      statements
    end

    def expression_statement
      expr = expression
      consume(TokenType::SEMICOLON, "Expect ';' after expression.")

      Stmt::Expression.new(expr)
    end

    def expression = parse_assignment_expr

    def parse_assignment_expr
      expr = parse_or_expr

      if match?(TokenType::EQUAL)
        equals = previous_token
        value = parse_assignment_expr

        if expr.is_a?(Expr::Variable)
          name = expr.name
          return Expr::Assign.new(name, value)
        end

        error(equals, 'Invalid assignment target.')
      end

      expr
    end

    def parse_or_expr
      expr = parse_and_expr

      while match?(TokenType::OR)
        operator = previous_token
        right = parse_and_expr
        expr = Expr::Logical.new(expr, operator, right)
      end

      expr
    end

    def parse_and_expr
      expr = parse_equality_expr

      while match?(TokenType::AND)
        operator = previous_token
        right = parse_equality_expr
        expr = Expr::Logical.new(expr, operator, right)
      end

      expr
    end

    def parse_equality_expr
      expr = parse_comparison_expr

      while match?(TokenType::BANG_EQUAL, TokenType::EQUAL_EQUAL)
        operator = previous_token
        right = parse_comparison_expr
        expr = Expr::Binary.new(expr, operator, right)
      end

      expr
    end

    def parse_comparison_expr
      expr = parse_term_expr

      while match?(TokenType::GREATER, TokenType::GREATER_EQUAL, TokenType::LESS, TokenType::LESS_EQUAL)
        operator = previous_token
        right = parse_term_expr
        expr = Expr::Binary.new(expr, operator, right)
      end

      expr
    end

    def parse_term_expr
      expr = parse_factor_expr

      while match?(TokenType::MINUS, TokenType::PLUS)
        operator = previous_token
        right = parse_factor_expr
        expr = Expr::Binary.new(expr, operator, right)
      end

      expr
    end

    def parse_factor_expr
      expr = parse_unary_expr

      while match?(TokenType::SLASH, TokenType::STAR)
        operator = previous_token
        right = parse_unary_expr
        expr = Expr::Binary.new(expr, operator, right)
      end

      expr
    end

    def parse_unary_expr
      if match?(TokenType::BANG, TokenType::MINUS)
        operator = previous_token
        right = parse_unary_expr
        return Expr::Unary.new(operator, right)
      end

      parse_primary_expr
    end

    def parse_primary_expr
      if match?(TokenType::FALSE)
        Expr::Literal.new(false)
      elsif match?(TokenType::TRUE)
        Expr::Literal.new(true)
      elsif match?(TokenType::NIL)
        Expr::Literal.new(nil)
      elsif match?(TokenType::NUMBER, TokenType::STRING)
        Expr::Literal.new(previous_token.literal)
      elsif match?(TokenType::IDENTIFIER)
        Expr::Variable.new(previous_token)
      elsif match?(TokenType::LEFT_PAREN)
        expr = expression
        consume(TokenType::RIGHT_PAREN, "Expect ')' after expression.")
        Expr::Grouping.new(expr)
      else
        raise error(current_token, 'Expect expression.')
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

      raise error(current_token, message)
    end

    def checked?(type)
      return false if at_end?

      current_token.type == type
    end

    def advance
      @current += 1 unless at_end?

      previous_token
    end

    def at_end? = current_token.type == TokenType::EOF

    # peek
    def current_token = @tokens[@current]

    def previous_token = @tokens[@current - 1]

    def error(token, message)
      @runner.parse_error(token, message)
      ParseError.new
    end

    def synchronize
      advance

      until at_end?
        return if previous_token.type == TokenType::SEMICOLON

        case current_token.type
        when TokenType::CLASS,
            TokenType::FUN,
            TokenType::VAR,
            TokenType::FOR,
            TokenType::IF,
            TokenType::WHILE,
            TokenType::PRINT,
            TokenType::PRINTLN,
            TokenType::RETURN
          return
        end
      end

      advance
    end
  end
end
