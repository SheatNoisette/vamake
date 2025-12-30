module vamk

fn (mut p Parser) parse_rule(initial_target string, colon_consumed bool) (Rule, string) {
	rule := p.parse_rule_with_deps(initial_target, [])
	return rule, rule.target
}

fn (mut p Parser) parse_rule_with_deps(initial_target string, initial_dependencies []string) Rule {
	mut target := initial_target
	mut dependencies := initial_dependencies.clone()

	// Collect any additional idents as part of target until colon
	if initial_dependencies.len == 0 {
		for p.current_token.kind == .ident {
			if target.len > 0 {
				target += ' ' + p.current_token.value
			} else {
				target = p.current_token.value
			}
			p.next_token()
		}

		// Expect colon (only if initial_dependencies is empty)
		if p.current_token.kind == .colon {
			p.next_token() // consume colon
		}

		// Collect dependencies
		for p.current_token.kind in [.ident, .var_ref] {
			dependencies << p.current_token.value
			p.next_token()
		}
	}

	// Handle extra colons and following tokens
	if p.current_token.kind == .colon {
		p.next_token() // consume extra :
		// consume any following idents until newline
		for p.current_token.kind == .ident {
			p.next_token()
		}
	}

	if p.current_token.kind == .newline {
		p.next_token()
	}

	mut recipes := []string{}
	for p.current_token.kind == .tab {
		p.next_token() // consume tab
		mut recipe := ''
		mut prev_token_was_var_ref := false
		for p.current_token.kind !in [.newline, .eof] {
			if p.current_token.kind == .var_ref {
				// Add space between two consecutive var_refs unless current starts with / or .
				if prev_token_was_var_ref && !(p.current_token.value.starts_with('/')
					|| p.current_token.value.starts_with('.')) {
					recipe += ' '
				}
				recipe += p.current_token.value
				prev_token_was_var_ref = true
			} else {
				value := p.current_token.value
				// @TODO: Handle this better
				// Add space before current token if previous was var_ref and current doesn't start with / or .
				// This handles $(VC)/$(VCFILE) correctly (no space)
				// but $(CC) $(CFLAGS) correctly (space between them)
				if prev_token_was_var_ref && !(value.starts_with('/') || value.starts_with('.')) {
					recipe += ' '
				}
				recipe += value + ' '
				prev_token_was_var_ref = false
			}
			p.next_token()
		}
		recipe_line := recipe.trim_space()
		recipes << recipe_line
		if p.current_token.kind == .newline {
			p.next_token()
		}
	}

	return Rule{
		target:       target
		dependencies: dependencies
		recipes:      recipes
		phony:        target == eval_rule_phony_target_name
	}
}
