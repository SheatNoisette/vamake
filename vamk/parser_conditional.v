module vamk

fn (mut p Parser) parse_conditional(kind string) Conditional {
	condition := p.parse_condition()

	then_nodes := p.parse_conditional_block()
	else_nodes := p.parse_else_block()

	result := Conditional{
		kind:       p.string_to_conditional_type(kind)
		condition:  condition
		then_nodes: then_nodes
		else_nodes: else_nodes
	}
	return result
}

fn (mut p Parser) parse_condition() string {
	mut condition := ''
	for p.current_token.kind !in [.newline, .eof] {
		condition += p.current_token.value + ' '
		p.next_token()
	}

	if p.current_token.kind == .newline {
		p.next_token()
	}

	return condition.trim_space()
}

fn (mut p Parser) parse_else_block() []ASTNode {
	if !p.is_else_directive() {
		return []
	}

	p.next_token() // consume 'else'

	// Handle 'else if' pattern
	if kind := p.get_conditional_kind() {
		p.next_token() // consume conditional keyword
		return [p.parse_conditional(kind)]
	}

	// Regular else block
	return p.parse_conditional_block()
}

fn (mut p Parser) parse_conditional_block() []ASTNode {
	mut nodes := []ASTNode{}
	mut depth := 1

	for p.current_token.kind != .eof && depth > 0 {
		// Handle endif
		if p.is_token(token_str_endif) {
			p.next_token()
			depth--
			if depth == 0 {
				break
			}
			continue
		}

		// Handle else at current depth
		if p.is_else_directive() && depth == 1 {
			break
		}

		// Track depth for nested structures
		if p.is_else_directive() {
			p.next_token()
			if p.get_conditional_kind() != none {
				depth++
			}
			continue
		}

		// Handle nested conditionals
		if kind := p.get_conditional_kind() {
			p.next_token()
			nodes << p.parse_conditional(kind)
			continue
		}

		// Parse regular nodes
		if node := p.parse_next_node() {
			nodes << node
		}
	}

	return nodes
}

fn (p &Parser) is_token(value string) bool {
	return p.current_token.kind == .ident && p.current_token.value == value
}

fn (p &Parser) is_else_directive() bool {
	return p.is_token(token_str_else)
}

fn (p &Parser) get_conditional_kind() ?string {
	if p.current_token.kind != .ident {
		return none
	}

	if p.current_token.value in [token_str_ifdef, token_str_ifndef, token_str_ifeq, token_str_ifneq] {
		return p.current_token.value
	}

	return none
}

fn (p &Parser) string_to_conditional_type(kind string) ConditionalType {
	return match kind {
		token_str_ifdef { ConditionalType.ifdef }
		token_str_ifndef { ConditionalType.ifndef }
		token_str_ifeq { ConditionalType.ifeq }
		token_str_ifneq { ConditionalType.ifneq }
		else { panic('Unknown conditional kind: ${kind}') }
	}
}
