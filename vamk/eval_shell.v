module vamk

import os

fn (mut e Evaluator) eval_shell_command(cmd ShellCommand) {
	if e.last_rule_target != '' && e.last_rule_target in e.rules {
		mut rule := e.rules[e.last_rule_target]
		mut updated_recipes := rule.recipes.clone()
		updated_recipes << cmd.command
		updated_rule := Rule{
			target:       rule.target
			dependencies: rule.dependencies
			recipes:      updated_recipes
			phony:        rule.phony
		}
		e.rules[e.last_rule_target] = updated_rule
	}
}

pub fn (mut e Evaluator) eval_shell_commands(text string) string {
	mut result := text
	for result.contains('$(shell') {
		start := result.index('$(shell') or { break }
		end := e.find_matching_paren(result, start + 1) or { break }

		// Ugh, split to shell
		cmd := result[start + 8..end].trim_space()
		output := os.execute(cmd)

		result = result[..start] + output.output.trim_space() + result[end + 1..]
	}
	return result
}
