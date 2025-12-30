module vamk

pub struct Parser {
mut:
	lexer         Lexer
	current_token Token
	variables     map[string]string
}

// Identifier type detection
struct IdentifierType {
	is_rule       bool
	is_assignment bool
	is_directive  bool
}

pub fn new_parser(input string) Parser {
	mut lexer := new_lexer(input)
	current_token := lexer.next_token()
	return Parser{
		lexer:         lexer
		current_token: current_token
		variables:     map[string]string{}
	}
}

fn (mut p Parser) is_assignment_operator() bool {
	return p.current_token.kind in [.equals, .question_equals, .plus_equals, .colon_equals]
}

fn (mut p Parser) skip_whitespace() {
	for p.current_token.kind in [.newline, .tab] {
		p.next_token()
	}
}

fn (mut p Parser) consume_until_newline() string {
	mut result := ''
	for p.current_token.kind !in [.newline, .eof] {
		result += p.current_token.value + ' '
		p.next_token()
	}
	return result.trim_space()
}

fn (mut p Parser) collect_full_identifier(initial string) string {
	mut full_ident := initial
	for p.current_token.kind in [.ident, .var_ref] {
		full_ident += ' ' + p.current_token.value
		p.next_token()
	}
	return full_ident
}

fn analyze_identifier(ident string) IdentifierType {
	has_colon_assign := ident.contains(token_str_colon_equals)
	has_plus_assign := ident.contains(token_str_plus_equals)
	has_question_assign := ident.contains(token_str_question_equals)
	has_equals := ident.contains(token_str_equals) && !has_colon_assign && !has_plus_assign
		&& !has_question_assign
	has_colon := ident.contains(':') && !has_colon_assign

	return IdentifierType{
		is_rule:       has_colon && !has_colon_assign
		is_assignment: has_colon_assign || has_plus_assign || has_question_assign || has_equals
		is_directive:  false
	}
}

// Parse directives (ifdef, ifndef, include, etc.)
fn (mut p Parser) handle_directive(ident string) ?ASTNode {
	return match ident {
		token_str_ifdef, token_str_ifndef, token_str_ifeq, token_str_ifneq {
			p.parse_conditional(ident)
		}
		token_str_include {
			p.parse_include(false)
		}
		token_str_minclude {
			p.parse_include(true)
		}
		token_str_endif, token_str_else {
			none
		}
		else {
			none
		}
	}
}

// Parse rule with dependencies from a colon-separated string
fn (mut p Parser) extract_rule_parts(full_ident string) (string, []string) {
	parts := full_ident.split(':')

	mut target := ''
	mut dependencies := []string{}

	if parts.len >= 1 {
		target = parts[0].trim_space()
	}

	if parts.len >= 2 {
		// Only take the first part after the colon as dependencies
		// Ignore additional colons (malformed syntax like target:dep:extra)
		deps_str := parts[1].trim_space()
		if deps_str.len > 0 {
			for dep in deps_str.split(' ') {
				trimmed := dep.trim_space()
				if trimmed.len > 0 {
					dependencies << trimmed
				}
			}
		}
	}

	return target, dependencies
}

fn (mut p Parser) parse_next_node() ?ASTNode {
	// Handle simple token types first
	match p.current_token.kind {
		.comment {
			return p.handle_comment()
		}
		.newline {
			p.next_token()
			return none
		}
		.tab {
			return p.handle_shell_command()
		}
		.colon {
			rule, _ := p.parse_rule('', false)
			return rule
		}
		else {}
	}

	// Assignment operators without ANY identifier
	if p.is_assignment_operator() {
		return p.parse_assignment('')
	}

	// Identifiers and variable refs
	if p.current_token.kind in [.ident, .var_ref] {
		return p.handle_identifier()
	}

	p.next_token()
	return none
}

fn (mut p Parser) handle_comment() ?ASTNode {
	node := Comment{
		text: p.current_token.value
	}
	p.next_token()
	return node
}

fn (mut p Parser) handle_shell_command() ?ASTNode {
	p.next_token()
	command := p.consume_until_newline()

	if command.len > 0 {
		return ShellCommand{
			command: command
		}
	}
	return none
}

fn (mut p Parser) handle_identifier() ?ASTNode {
	ident := p.current_token.value
	p.next_token()

	// Check for directives first
	if node := p.handle_directive(ident) {
		return node
	}

	full_ident := p.collect_full_identifier(ident)
	id_type := analyze_identifier(full_ident)

	if id_type.is_rule {
		target, dependencies := p.extract_rule_parts(full_ident)
		return p.parse_rule_with_deps(target, dependencies)
	} else if id_type.is_assignment {
		return p.parse_assignment(full_ident)
	}

	// Check current token for other operators stuff
	match p.current_token.kind {
		.equals, .question_equals, .plus_equals, .colon_equals {
			return p.parse_assignment(full_ident)
		}
		.colon {
			rule, _ := p.parse_rule(full_ident, false)
			return rule
		}
		else {}
	}

	return none
}

pub fn (mut p Parser) parse() []ASTNode {
	mut nodes := []ASTNode{}

	for p.current_token.kind != .eof {
		if node := p.parse_next_node() {
			nodes << node
		}
	}

	return nodes
}
