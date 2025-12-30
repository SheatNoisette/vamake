import vamk

fn test_evaluator_simple_assignment() {
	mut evaluator := vamk.new_evaluator(false, false)
	assign := vamk.Assignment{
		name:        'VAR'
		value:       'hello'
		assign_type: '='
	}

	evaluator.eval_assignment(assign)
	assert evaluator.variables['VAR'] == 'hello'
}

fn test_evaluator_conditional_assignment() {
	mut evaluator := vamk.new_evaluator(false, false)

	// ?=
	assign1 := vamk.Assignment{
		name:        'VAR'
		value:       'value1'
		assign_type: '?='
	}
	evaluator.eval_assignment(assign1)
	assert evaluator.variables['VAR'] == 'value1'

	// Second ?= SHOULD NOT OVERRIDE
	assign2 := vamk.Assignment{
		name:        'VAR'
		value:       'value2'
		assign_type: '?='
	}
	evaluator.eval_assignment(assign2)
	assert evaluator.variables['VAR'] == 'value1'

	// +=
	assign3 := vamk.Assignment{
		name:        'VAR'
		value:       'value3'
		assign_type: '+='
	}
	evaluator.eval_assignment(assign3)
	assert evaluator.variables['VAR'] == 'value1 value3'
}
