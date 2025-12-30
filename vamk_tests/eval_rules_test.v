import vamk

fn test_evaluator_rule_with_variable_dependencies() {
	mut evaluator := vamk.new_evaluator(false, false)

	evaluator.variables['SRCS'] = 'main.c utils.c'
	evaluator.variables['TARGET'] = 'hello'

	// Variable references in target and dependencies
	rule := vamk.Rule{
		target:       '$(TARGET)'
		dependencies: ['$(SRCS:.c=.o)']
		recipes:      ['gcc -o $@ $^']
	}

	evaluator.eval_rule(rule)

	// Expanded ?
	assert 'hello' in evaluator.rules
	stored_rule := evaluator.rules['hello']
	assert stored_rule.target == 'hello'
	assert stored_rule.dependencies == ['main.o', 'utils.o'] // split on space
	assert stored_rule.recipes == ['gcc -o $@ $^']
}

fn test_evaluator_build_target_missing_rule() {
	mut evaluator := vamk.new_evaluator(false, false)

	// Try to build a target that doesn't exist
	evaluator.build_target('nonexistent') or {
		assert err.msg() == 'No rule to make target: nonexistent'
		return
	}

	// Should not reach here
	assert false, 'Expected error for missing target'
}
