module vamk

pub struct Evaluator {
pub mut:
	variables        map[string]string
	rules            map[string]Rule
	pattern_rules    []Rule
	phony_targets    []string
	verbose          bool
	dry_run          bool
	last_rule_target string
}

pub fn (mut e Evaluator) eval(nodes []ASTNode) {
	for node in nodes {
		match node {
			Assignment {
				e.eval_assignment(node)
			}
			Rule {
				e.eval_rule(node)
			}
			Conditional {
				e.eval_conditional(node)
			}
			Include {
				e.eval_include(node)
			}
			ShellCommand {
				e.eval_shell_command(node)
			}
			Comment {}
		}
	}

	// Slight post-processing: Mark rules as phony based on .PHONY declarations
	e.mark_phony_rules()
}
