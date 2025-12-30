module vamk

fn print_assignment(assign Assignment, index int) {
	println('[${index}] Assignment: ${assign.name} ${assign.assign_type} ${assign.value}')
}

fn print_rule(rule Rule, index int) {
	println('[${index}] Rule: ${rule.target}')
	if rule.dependencies.len > 0 {
		println('      Deps: ${rule.dependencies.join(', ')}')
	}
	if rule.recipes.len > 0 {
		println('      Recipes: ${rule.recipes.len} command(s)')
		for j, recipe in rule.recipes {
			println('        [${j}] ${recipe}')
		}
	}
}

fn print_conditional(cond Conditional, index int) {
	println('[${index}] Conditional: ${cond.kind} ${cond.condition}')
	println('      Then: ${cond.then_nodes.len}')
	pretty_print_nodes(cond.then_nodes, '      ')
	println('      Else: ${cond.else_nodes.len}')
	pretty_print_nodes(cond.else_nodes, '      ')
}

fn pretty_print_nodes(nodes []ASTNode, prefix string) {
	for i, node in nodes {
		match node {
			Assignment {
				print_assignment(node, i)
			}
			Rule {
				print_rule(node, i)
			}
			Conditional {
				print_conditional(node, i)
			}
			Comment {
				print_comment(node, i)
			}
			ShellCommand {
				println('[${i}] ShellCommand: ${node.command}')
			}
			else {}
		}
	}
}

fn print_comment(comment Comment, index int) {
	println('[${index}] Comment: ${comment.text}')
}

fn print_unknown(index int) {
	println('[${index}] Unknown node type')
}

pub fn pretty_print(nodes []ASTNode) {
	for i, node in nodes {
		match node {
			Assignment {
				print_assignment(node, i)
			}
			Rule {
				print_rule(node, i)
			}
			Conditional {
				print_conditional(node, i)
			}
			Comment {
				print_comment(node, i)
			}
			else {
				print_unknown(i)
			}
		}
	}
}
