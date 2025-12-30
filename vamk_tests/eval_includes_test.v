import vamk

fn test_evaluator_eval_include_missing_file_optional() {
	mut evaluator := vamk.new_evaluator(false, false)

	include := vamk.Include{
		file:     'nonexistent_file.mk'
		optional: true
	}

	// This should not panic, just return silently
	evaluator.eval_include(include)

	// Variables should remain unchanged
	assert evaluator.variables.len == 0
}
