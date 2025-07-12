# frozen_string_literal: true

require_relative 'runner'
require_relative 'token_type'
require_relative 'token'

module Rblox
  class Scanner
    KEYWORDS = {
      'and' => TokenType::AND,
      'class' => TokenType::CLASS,
      'else' => TokenType::ELSE,
      'false' => TokenType::FALSE,
      'for' => TokenType::FOR,
      'fun' => TokenType::FUN,
      'if' => TokenType::IF,
      'nil' => TokenType::NIL,
      'or' => TokenType::OR,
      'print' => TokenType::PRINT,
      'return' => TokenType::RETURN,
      'super' => TokenType::SUPER,
      'this' => TokenType::THIS,
      'true' => TokenType::TRUE,
      'var' => TokenType::VAR,
      'while' => TokenType::WHILE
    }.freeze

    def initialize(runner, source)
      @runner = runner

      @source = source
      @tokens = []

      @start = 0
      @current = 0
      @line = 1
    end

    def scan_tokens
      until at_end?
        @start = @current
        scan_token
      end

      @tokens << Token.new(TokenType::EOF, '', nil, @line)
    end

    private

    def scan_token
      c = advance
      case c
      when '('
        add_token(TokenType::LEFT_PAREN)
      when ')'
        add_token(TokenType::RIGHT_PAREN)
      when '{'
        add_token(TokenType::LEFT_BRACE)
      when '}'
        add_token(TokenType::RIGHT_BRACE)
      when ','
        add_token(TokenType::COMMA)
      when '.'
        add_token(TokenType::DOT)
      when '-'
        add_token(TokenType::MINUS)
      when '+'
        add_token(TokenType::PLUS)
      when ';'
        add_token(TokenType::SEMICOLON)
      when '*'
        add_token(TokenType::STAR)
      when '!'
        add_token(match?('=') ? TokenType::BANG_EQUAL : TokenType::BANG)
      when '='
        add_token(match?('=') ? TokenType::EQUAL_EQUAL : TokenType::EQUAL)
      when '<'
        add_token(match?('=') ? TokenType::LESS_EQUAL : TokenType::LESS)
      when '>'
        add_token(match?('=') ? TokenType::GREATER_EQUAL : TokenType::GREATER)
      when '/'
        if match?('/')
          advance while peek != "\n" && !at_end?
        else
          add_token(TokenType::SLASH)
        end
      when ' ', "\r", "\t"
        # Ignore whitespace.
      when "\n"
        @line += 1
      when '"'
        string
      else
        if digit?(c)
          number
        elsif alpha?(c)
          identifier
        else
          @runner.error(@line, 'Unexpected character.')
        end
      end
    end

    def identifier
      advance while alpha_numeric?(peek)

      text = @source[@start...@current]
      type = KEYWORDS[text] || TokenType::IDENTIFIER
      add_token(type)
    end

    def number
      advance while digit?(peek)

      if peek == '.' && digit?(peek_next)
        advance
        advance while digit?(peek)
      end

      value = Float(@source[@start...@current])
      add_token(TokenType::NUMBER, value)
    end

    def string
      while peek != '"' && !at_end?
        @line += 1 if peek == "\n"
        advance
      end

      if at_end?
        @runner.error(@line, 'Unterminated string.')
        return
      end

      advance

      value = @source[(@start + 1)...(@current - 1)]
      add_token(TokenType::STRING, value)
    end

    def match?(expected)
      return false if at_end?
      return false if @source[@current] != expected

      @current += 1
      true
    end

    def peek
      return "\0" if at_end?

      @source[@current]
    end

    def peek_next
      return "\0" if (@current + 1) >= @source.size

      @source[@current + 1]
    end

    def alpha?(char) = char.between?('a', 'z') || char.between?('A', 'Z') || char == '_'

    def alpha_numeric?(char) = alpha?(char) || digit?(char)

    def digit?(char) = char.between?('0', '9')

    def at_end? = @current >= @source.size

    def advance
      char = @source[@current]
      @current += 1
      char
    end

    def add_token(type, literal = nil)
      text = @source[@start...@current]
      @tokens << Token.new(type, text, literal, @line)
    end
  end
end
