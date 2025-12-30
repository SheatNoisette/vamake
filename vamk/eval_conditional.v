module vamk

pub fn (mut e Evaluator) eval_conditional(cond Conditional) {
	should_exec := match cond.kind {
		.ifdef { cond.condition in e.variables }
		.ifndef { cond.condition !in e.variables }
		.ifeq { e.eval_condition(cond.condition) }
		.ifneq { !e.eval_condition(cond.condition) }
	}

	mut nodes := if should_exec { cond.then_nodes } else { cond.else_nodes }

	// Pre-processing, convert ShellCommands that look like assignments to Assignment nodes
	mut processed_nodes := []ASTNode{}
	for node in nodes {
		if node is ShellCommand {
			// Check if the command looks like an assignment
			// Assignments contain '=', but recipe commands usually don't heh
			if node.command.contains(token_str_equals) {
				// This looks like an assignment, parse it AGAIN
				mut parser := new_parser(node.command)
				assignment_nodes := parser.parse()
				for assign_node in assignment_nodes {
					processed_nodes << assign_node
				}
			} else {
				// This is a recipe command, keep it as-is
				processed_nodes << node
			}
		} else {
			processed_nodes << node
		}
	}
	nodes = processed_nodes.clone()

	// Check if this is a recipe-level conditional (inside a rule)
	if e.last_rule_target != '' && e.last_rule_target in e.rules {
		// Check if the nodes contain assignments or rules
		// If they contain assignments, this is a standalone conditional
		// If they only contain shell commands, this is a recipe-level conditional
		mut has_assignment := false
		mut has_rule := false
		mut has_shell_command := false

		for node in nodes {
			match node {
				Assignment { has_assignment = true }
				Rule { has_rule = true }
				ShellCommand { has_shell_command = true }
				Conditional { has_assignment = true }
				else {}
			}
		}

		if has_assignment || has_rule {
			// Standalone conditional with assignments/rules
			// Process like business as usual and reset last_rule_target
			e.eval(nodes)
			e.last_rule_target = ''
		} else if has_shell_command {
			// Recipe-level conditional
			// Add shell commands to the current rule's recipes
			mut rule := e.rules[e.last_rule_target]
			mut updated_recipes := rule.recipes.clone()
			for node in nodes {
				if node is ShellCommand {
					updated_recipes << node.command
				}
			}
			updated_rule := Rule{
				target:       rule.target
				dependencies: rule.dependencies
				recipes:      updated_recipes
				phony:        rule.phony
			}
			e.rules[e.last_rule_target] = updated_rule
		}
	} else {
		// No active rule
		e.eval(nodes)
	}
}

// @TODO: This should be parsed with a proper AST node
fn (mut e Evaluator) eval_condition(cond string) bool {
	mut c := cond.trim_space()
	if c.starts_with('(') && c.ends_with(')') {
		c = c[1..c.len - 1]
	}
	expanded_cond := e.expand_vars(c)

	if expanded_cond.contains(',') {
		parts := expanded_cond.split(',')
		if parts.len != 2 {
			return false
		}
		left := parts[0].trim_space()
		right := parts[1].trim_space()
		return left == right
	} else {
		return expanded_cond != ''
	}
}
