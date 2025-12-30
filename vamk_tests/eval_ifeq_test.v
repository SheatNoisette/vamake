import vamk

fn test_evaluator_ifeq_true() {
	mut evaluator := vamk.new_evaluator(false, false)
	evaluator.variables['VARIABLE'] = '4'

	cond := vamk.Conditional{
		kind:       vamk.ConditionalType.ifeq
		condition:  '$(VARIABLE),4'
		then_nodes: [vamk.ShellCommand{
			command: '@echo "MATCH"'
		}]
		else_nodes: [vamk.ShellCommand{
			command: '@echo "NO MATCH"'
		}]
	}

	evaluator.eval_conditional(cond)
	// Should not set any variables since the nodes are recipes, not assignments
	assert evaluator.variables.len == 1
}

fn test_evaluator_ifeq_false() {
	mut evaluator := vamk.new_evaluator(false, false)
	evaluator.variables['VARIABLE'] = '4'

	cond := vamk.Conditional{
		kind:       vamk.ConditionalType.ifeq
		condition:  '$(VARIABLE),0'
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
	assert evaluator.variables['CFLAGS'] == '-O2'
}

fn test_evaluator_ifeq_with_expansion() {
	mut evaluator := vamk.new_evaluator(false, false)
	evaluator.variables['VARIABLE'] = '0'

	cond := vamk.Conditional{
		kind:       vamk.ConditionalType.ifeq
		condition:  '$(VARIABLE),0'
		then_nodes: [
			vamk.Assignment{
				name:        'RESULT'
				value:       'TRUE'
				assign_type: '='
			},
		]
		else_nodes: [
			vamk.Assignment{
				name:        'RESULT'
				value:       'FALSE'
				assign_type: '='
			},
		]
	}

	evaluator.eval_conditional(cond)
	assert evaluator.variables['RESULT'] == 'TRUE'
}

fn test_evaluator_ifneq_true() {
	mut evaluator := vamk.new_evaluator(false, false)
	evaluator.variables['VARIABLE'] = '4'

	cond := vamk.Conditional{
		kind:       vamk.ConditionalType.ifneq
		condition:  '$(VARIABLE),0'
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

fn test_evaluator_ifneq_false() {
	mut evaluator := vamk.new_evaluator(false, false)
	evaluator.variables['VARIABLE'] = '0'

	cond := vamk.Conditional{
		kind:       vamk.ConditionalType.ifneq
		condition:  '$(VARIABLE),0'
		then_nodes: [
			vamk.Assignment{
				name:        'RESULT'
				value:       'TRUE'
				assign_type: '='
			},
		]
		else_nodes: [
			vamk.Assignment{
				name:        'RESULT'
				value:       'FALSE'
				assign_type: '='
			},
		]
	}

	evaluator.eval_conditional(cond)
	assert evaluator.variables['RESULT'] == 'FALSE'
}
