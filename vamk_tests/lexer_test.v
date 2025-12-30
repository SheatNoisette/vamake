import vamk

fn test_lexer_basic_tokens() {
	input := 'target: dep1 dep2
	@echo "hello"
VAR = value
# comment
'
	mut lexer := vamk.new_lexer(input)

	// target:
	mut token := lexer.next_token()
	assert token.kind == .ident
	assert token.value == 'target:'

	// dep1
	token = lexer.next_token()
	assert token.kind == .ident
	assert token.value == 'dep1'

	// dep2
	token = lexer.next_token()
	assert token.kind == .ident
	assert token.value == 'dep2'

	// newline
	token = lexer.next_token()
	assert token.kind == .newline

	// tab
	token = lexer.next_token()
	assert token.kind == .tab

	// @echo "hello"
	token = lexer.next_token()
	assert token.kind == .ident
	assert token.value == '@echo'

	// "hello"
	token = lexer.next_token()
	assert token.kind == .string
	assert token.value == '"hello"'

	// newline
	token = lexer.next_token()
	assert token.kind == .newline

	// VAR
	token = lexer.next_token()
	assert token.kind == .ident
	assert token.value == 'VAR'

	// =
	token = lexer.next_token()
	assert token.kind == .equals

	// value
	token = lexer.next_token()
	assert token.kind == .ident
	assert token.value == 'value'

	// newline
	token = lexer.next_token()
	assert token.kind == .newline

	// # comment
	token = lexer.next_token()
	assert token.kind == .comment
	assert token.value == 'comment'

	// newline
	token = lexer.next_token()
	assert token.kind == .newline

	// eof
	token = lexer.next_token()
	assert token.kind == .eof
}

fn test_lexer_assignment_operators() {
	// Test VAR = value
	mut lexer1 := vamk.new_lexer('VAR = value')
	token1 := lexer1.next_token()
	assert token1.kind == .ident
	assert token1.value == 'VAR'
	token2 := lexer1.next_token()
	assert token2.kind == .equals
	token3 := lexer1.next_token()
	assert token3.kind == .ident
	assert token3.value == 'value'

	// Test VAR := value (colon equals)
	mut lexer2 := vamk.new_lexer('VAR := value')
	token4 := lexer2.next_token()
	assert token4.kind == .ident
	assert token4.value == 'VAR'
	token5 := lexer2.next_token()
	assert token5.kind == .colon_equals
	token6 := lexer2.next_token()
	assert token6.kind == .ident
	assert token6.value == 'value'
}

fn test_lexer_comments() {
	input := '# This is a comment
target: dep
	# Another comment
	command
'
	mut lexer := vamk.new_lexer(input)

	// comment
	mut token := lexer.next_token()
	assert token.kind == .comment
	assert token.value == 'This is a comment'

	// newline
	token = lexer.next_token()
	assert token.kind == .newline

	// target:
	token = lexer.next_token()
	assert token.kind == .ident
	assert token.value == 'target:'

	// dep
	token = lexer.next_token()
	assert token.kind == .ident
	assert token.value == 'dep'

	// newline
	token = lexer.next_token()
	assert token.kind == .newline

	// tab
	token = lexer.next_token()
	assert token.kind == .tab

	// # Another comment
	token = lexer.next_token()
	assert token.kind == .comment
	assert token.value == 'Another comment'

	// newline
	token = lexer.next_token()
	assert token.kind == .newline

	// tab
	token = lexer.next_token()
	assert token.kind == .tab

	// command
	token = lexer.next_token()
	assert token.kind == .ident
	assert token.value == 'command'
}

fn test_lexer_dash_in_ident() {
	// Test that -Wall is a single ident
	mut lexer := vamk.new_lexer('-Wall -O2')
	token1 := lexer.next_token()
	assert token1.kind == .ident
	assert token1.value == '-Wall'
	token2 := lexer.next_token()
	assert token2.kind == .ident
	assert token2.value == '-O2'
}

fn test_lexer_line_column_tracking() {
	input := 'a
b c'
	mut lexer := vamk.new_lexer(input)

	mut token := lexer.next_token()
	assert token.line == 1
	assert token.col == 0

	token = lexer.next_token()
	assert token.kind == .newline
	assert token.line == 1
	assert token.col == 1

	token = lexer.next_token()
	assert token.line == 2
	assert token.col == 0

	token = lexer.next_token()
	assert token.line == 2
	assert token.col == 2
}

fn test_lexer_unterminated_string() {
	// Test string that doesn't close
	input := '"unclosed string'
	mut lexer := vamk.new_lexer(input)

	token := lexer.next_token()
	assert token.kind == .string
	// Lexer handles unterminated string by adding closing quote
	assert token.value == '"unclosed string"'
}

fn test_lexer_empty_input() {
	input := ''
	mut lexer := vamk.new_lexer(input)

	token := lexer.next_token()
	assert token.kind == .eof
	assert token.line == 1
	assert token.col == 0
}

fn test_lexer_special_characters() {
	// Test various special characters that should be handled as ident
	input := '@$%^&*()[]{}|,.<>/?`~'
	mut lexer := vamk.new_lexer(input)

	// Should tokenize each character as ident
	for _ in 0 .. input.len {
		token := lexer.next_token()
		if token.kind == .eof {
			break
		}
		assert token.kind == .ident
	}
}

fn test_lexer_variable_references() {
	// Test $(VAR) tokenization
	input := '$(SRCS:.c=.o) $(TARGET) $($(VAR))'
	mut lexer := vamk.new_lexer(input)

	// $(SRCS:.c=.o)
	mut token := lexer.next_token()
	assert token.kind == .var_ref
	assert token.value == '$(SRCS:.c=.o)'

	// $(TARGET)
	token = lexer.next_token()
	assert token.kind == .var_ref
	assert token.value == '$(TARGET)'

	// $($(VAR))
	token = lexer.next_token()
	assert token.kind == .var_ref
	assert token.value == '$($(VAR))'
}
