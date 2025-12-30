module vamk

fn (mut p Parser) parse_assignment(name string) Assignment {
	// Handle inline assignment (like CC=gcc)
	if name.contains(token_str_equals) && !name.ends_with(token_str_equals) {
		return p.parse_inline_assignment(name)
	}

	// Extract variable name and assignment type
	var_name, assign_type := p.extract_assignment_parts(name)

	// Collect value tokens
	value := p.collect_assignment_value()

	return Assignment{
		name:        var_name
		value:       value
		assign_type: assign_type
	}
}

fn (mut p Parser) parse_inline_assignment(name string) Assignment {
	parts := name.split_nth(token_str_equals, 2)
	return Assignment{
		name:        parts[0].trim_space()
		value:       parts[1].trim_space()
		assign_type: token_str_equals
	}
}

fn (mut p Parser) extract_assignment_parts(name string) (string, string) {
	operators := [token_str_colon_equals, token_str_plus_equals, token_str_question_equals,
		token_str_equals]

	// Check if operator is part of the name
	for op in operators {
		if name.ends_with(op) {
			return name[..name.len - op.len].trim_space(), op
		}
	}

	// Operator is a separate token
	assign_type := match p.current_token.kind {
		.colon_equals { token_str_colon_equals }
		.plus_equals { token_str_plus_equals }
		.question_equals { token_str_question_equals }
		.equals { token_str_equals }
		else { panic('Expected assignment operator') }
	}
	p.next_token()

	return name, assign_type
}

fn (mut p Parser) collect_assignment_value() string {
	mut value := ''

	for p.current_token.kind !in [.newline, .eof] {
		value += p.current_token.value

		// Add space separator unless it's a var_ref (for concatenation)
		if p.current_token.kind !in [.string, .var_ref] {
			value += ' '
		}

		p.next_token()
	}

	if p.current_token.kind == .newline {
		p.next_token()
	}

	return value.trim_space()
}
