import vamk

fn test_evaluator_conditional_ifdef() {
	mut evaluator := vamk.new_evaluator(false, false)
	evaluator.variables['DEBUG'] = '1'

	cond := vamk.Conditional{
		kind:       vamk.ConditionalType.ifdef
		condition:  'DEBUG'
		then_nodes: [
			vamk.Assignment{
				name:        'CFLAGS'
				value:       '-DDEBUG'
				assign_type: '='
			},
		]
		else_nodes: [
			vamk.Assignment{
				name:        'CFLAGS'
				value:       '-O2'
				assign_type: '='
			},
		]
	}

	evaluator.eval_conditional(cond)
	assert evaluator.variables['CFLAGS'] == '-DDEBUG'
}

fn test_evaluator_conditional_ifndef() {
	mut evaluator := vamk.new_evaluator(false, false)

	cond := vamk.Conditional{
		kind:       vamk.ConditionalType.ifndef
		condition:  'DEBUG'
		then_nodes: [
			vamk.Assignment{
				name:        'CFLAGS'
				value:       '-O2'
				assign_type: '='
			},
		]
		else_nodes: [
			vamk.Assignment{
				name:        'CFLAGS'
				value:       '-DDEBUG'
				assign_type: '='
			},
		]
	}

	evaluator.eval_conditional(cond)
	assert evaluator.variables['CFLAGS'] == '-O2'
}
