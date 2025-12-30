import vamk

fn test_evaluator_recursive_vs_simple_expansion() {
	mut evaluator := vamk.new_evaluator(false, false)

	assign_b := vamk.Assignment{
		name:        'B'
		value:       'hello'
		assign_type: '='
	}
	evaluator.eval_assignment(assign_b)

	// Test :=  --> Expansion which expands at def time
	assign_a_simple := vamk.Assignment{
		name:        'A_SIMPLE'
		value:       '$(B) world'
		assign_type: ':='
	}
	evaluator.eval_assignment(assign_a_simple)
	// Should expand now, so A_SIMPLE should contain "hello world"
	assert evaluator.variables['A_SIMPLE'] == 'hello world'

	// Test = --> recursive expansion,must expands at reference time
	assign_a_recursive := vamk.Assignment{
		name:        'A_RECURSIVE'
		value:       '$(B) world'
		assign_type: '='
	}
	evaluator.eval_assignment(assign_a_recursive)
	// Should store raw value "$(B) world"
	assert evaluator.variables['A_RECURSIVE'] == '$(B) world'

	// Now change B
	assign_b_new := vamk.Assignment{
		name:        'B'
		value:       'goodbye'
		assign_type: '='
	}
	evaluator.eval_assignment(assign_b_new)

	// A_SIMPLE should still be "hello world" (expanded at definition time)
	assert evaluator.variables['A_SIMPLE'] == 'hello world'

	// A_RECURSIVE should now expand to "goodbye world" when referenced
	expanded_recursive := evaluator.expand_vars('$(A_RECURSIVE)')
	assert expanded_recursive == 'goodbye world'
}

fn test_evaluator_variable_expansion() {
	// Most basic expansion and the most used one

	mut evaluator := vamk.new_evaluator(false, false)
	evaluator.variables['CC'] = 'gcc'
	evaluator.variables['CFLAGS'] = '-Wall -O2'

	result := evaluator.expand_vars('$(CC) $(CFLAGS) -o main main.c')
	assert result == 'gcc -Wall -O2 -o main main.c'

	result2 := evaluator.expand_vars(r'${CC} ${CFLAGS}')
	assert result2 == 'gcc -Wall -O2'
}
