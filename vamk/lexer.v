module vamk

struct Lexer {
mut:
	input string
	pos   int
	line  int
	col   int
}

pub fn new_lexer(input string) Lexer {
	return Lexer{
		input: input
		pos:   0
		line:  1
		col:   0
	}
}

fn (mut l Lexer) peek() u8 {
	if l.pos >= l.input.len {
		return 0
	}
	return l.input[l.pos]
}

fn is_ident_start(c u8) bool {
	return c.is_letter() || c == `_` || c == `.` || c == `/` || c == `-`
}

fn (mut l Lexer) advance() u8 {
	if l.pos >= l.input.len {
		return 0
	}
	ch := l.input[l.pos]
	l.pos++
	l.col++
	if ch == `\n` {
		l.line++
		l.col = 0
	}
	return ch
}

fn (mut l Lexer) skip_whitespace_except_newline() {
	for l.peek() == ` ` && l.peek() != 0 {
		l.advance()
	}
}

fn (mut l Lexer) read_until_newline() string {
	start := l.pos
	for l.peek() != `\n` && l.peek() != 0 {
		if l.peek() == `\\` && l.pos + 1 < l.input.len && l.input[l.pos + 1] == `\n` {
			l.advance() // skip backslash
			l.advance() // skip newline
			continue
		}
		l.advance()
	}
	return l.input[start..l.pos].trim_space()
}

pub fn (mut l Lexer) next_token() Token {
	// FYI: Initially, the lexer handled special keywords (ifeq, include, etc.)
	// this was removed because it dependended of the previous context (ident and
	// surroundings), which was really messy to implement in the lexer.

	l.skip_whitespace_except_newline()

	if l.peek() == 0 {
		return Token{
			kind: .eof
			line: l.line
			col:  l.col
		}
	}

	start_col := l.col
	start_line := l.line

	ch := l.peek()

	// Check for variable reference $(...)
	if ch == `$` && l.pos + 1 < l.input.len && l.input[l.pos + 1] == `(` {
		return l.read_var_ref(start_line, start_col)
	}

	match ch {
		`#` {
			l.advance()
			comment := l.read_until_newline()
			return Token{
				kind:  .comment
				value: comment
				line:  start_line
				col:   start_col
			}
		}
		`\n` {
			l.advance()
			return Token{
				kind: .newline
				line: start_line
				col:  start_col
			}
		}
		`\t` {
			l.advance()
			return Token{
				kind:  .tab
				value: '\t'
				line:  start_line
				col:   start_col
			}
		}
		`:` {
			l.advance()
			if l.peek() == `=` {
				l.advance()
				return Token{
					kind:  .colon_equals
					value: token_str_colon_equals
					line:  start_line
					col:   start_col
				}
			} else {
				return Token{
					kind:  .colon
					value: ':'
					line:  start_line
					col:   start_col
				}
			}
		}
		`?` {
			l.advance()
			if l.peek() == `=` {
				l.advance()
				return Token{
					kind:  .question_equals
					value: token_str_question_equals
					line:  start_line
					col:   start_col
				}
			} else {
				// Fallback to ident
				l.pos--
				return l.read_identifier_or_string(start_line, start_col)
			}
		}
		`+` {
			l.advance()
			if l.peek() == `=` {
				l.advance()
				return Token{
					kind:  .plus_equals
					value: token_str_plus_equals
					line:  start_line
					col:   start_col
				}
			} else {
				// Fallback to ident
				l.pos--
				return l.read_identifier_or_string(start_line, start_col)
			}
		}
		`=` {
			l.advance()
			return Token{
				kind:  .equals
				value: token_str_equals
				line:  start_line
				col:   start_col
			}
		}
		`"` {
			return l.read_string(start_line, start_col)
		}
		else {
			return l.read_identifier_or_string(start_line, start_col)
		}
	}
}

fn (mut l Lexer) read_string(start_line int, start_col int) Token {
	l.advance() // skip opening quote
	start := l.pos
	for l.peek() != `"` && l.peek() != 0 {
		l.advance()
	}
	inner := l.input[start..l.pos]
	value := '"' + inner + '"'
	if l.peek() == `"` {
		l.advance() // skip closing quote
	}
	return Token{
		kind:  .string
		value: value
		line:  start_line
		col:   start_col
	}
}

fn (mut l Lexer) read_var_ref(start_line int, start_col int) Token {
	l.advance() // skip $
	l.advance() // skip (
	start := l.pos
	mut paren_depth := 1
	for l.peek() != 0 {
		if l.peek() == `(` {
			paren_depth++
		} else if l.peek() == `)` {
			paren_depth--
			if paren_depth == 0 {
				value := l.input[start..l.pos]
				l.advance() // skip )
				return Token{
					kind:  .var_ref
					value: '$(' + value + ')'
					line:  start_line
					col:   start_col
				}
			}
		}
		l.advance()
	}
	// If no matching ), treat as ident for fallback
	return Token{
		kind:  .ident
		value: l.input[start..l.pos]
		line:  start_line
		col:   start_col
	}
}

fn (mut l Lexer) read_identifier_or_string(start_line int, start_col int) Token {
	start := l.pos
	// Don't break at : and = to preserve URLs and flags like -std=gnu11....
	for l.peek() != 0 && l.peek() !in [` `, `\t`, `\n`, `#`, `"`] {
		l.advance()
	}
	value := l.input[start..l.pos]
	return Token{
		kind:  .ident
		value: value
		line:  start_line
		col:   start_col
	}
}
