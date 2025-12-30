module vamk

const eval_rule_phony_target_name = '.PHONY'

pub fn (mut e Evaluator) eval_rule(rule Rule) {
	mut expanded_target := e.expand_vars(rule.target)
	mut expanded_dependencies := rule.dependencies.map(e.expand_vars(it))
	// Split dependencies on spaces as in make dependencies are space-separated!
	mut flattened_deps := []string{}
	for dep in expanded_dependencies {
		for word in dep.split(' ') {
			if word.trim_space().len > 0 {
				flattened_deps << word.trim_space()
			}
		}
	}
	expanded_dependencies = flattened_deps.clone()

	// Track last rule for recipe additions
	if expanded_target != eval_rule_phony_target_name && !expanded_target.contains('%') {
		e.last_rule_target = expanded_target
	}

	if expanded_target == eval_rule_phony_target_name {
		// Yup, special handling for .PHONY target, mark dependencies as phony
		for dep in expanded_dependencies {
			if dep !in e.phony_targets {
				e.phony_targets << dep
			}
		}
	} else if expanded_target.contains('%') {
		expanded_rule := Rule{
			target:       expanded_target
			dependencies: expanded_dependencies
			recipes:      rule.recipes
			phony:        rule.phony
		}
		e.pattern_rules << expanded_rule
	} else {
		// If a rule with this target already exists, merge the recipes
		if expanded_target in e.rules {
			mut existing_rule := e.rules[expanded_target]
			mut merged_recipes := existing_rule.recipes.clone()
			for recipe in rule.recipes {
				merged_recipes << recipe
			}
			merged_rule := Rule{
				target:       expanded_target
				dependencies: expanded_dependencies
				recipes:      merged_recipes
				phony:        rule.phony
			}
			e.rules[expanded_target] = merged_rule
		} else {
			expanded_rule := Rule{
				target:       expanded_target
				dependencies: expanded_dependencies
				recipes:      rule.recipes
				phony:        rule.phony
			}
			e.rules[expanded_target] = expanded_rule
		}
	}
}

fn (mut e Evaluator) mark_phony_rules() {
	for target, rule in e.rules {
		if target in e.phony_targets {
			phony_rule := Rule{
				target:       rule.target
				dependencies: rule.dependencies
				recipes:      rule.recipes
				phony:        true
			}
			e.rules[target] = phony_rule
		}
	}

	// Also mark pattern rules as phony if needed
	for i, pattern_rule in e.pattern_rules {
		if pattern_rule.target in e.phony_targets {
			phony_pattern_rule := Rule{
				target:       pattern_rule.target
				dependencies: pattern_rule.dependencies
				recipes:      pattern_rule.recipes
				phony:        true
			}
			e.pattern_rules[i] = phony_pattern_rule
		}
	}
}
