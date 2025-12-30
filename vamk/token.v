module vamk

// Token types
pub enum TokenKind {
	eof
	newline
	tab
	colon
	colon_equals
	equals
	question_equals
	plus_equals
	shell_start
	shell_end
	ident
	string
	comment
	var_ref
}

struct Token {
pub:
	kind  TokenKind
	value string
	line  int
	col   int
}
