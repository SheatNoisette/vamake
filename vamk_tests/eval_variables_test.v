import vamk

fn test_evaluator_automatic_variables() {
	mut evaluator := vamk.new_evaluator(false, false)

	// automatic variables expansion
	result := evaluator.expand_recipe_vars('target', ['dep1', 'dep2'], 'echo $@ $< $^ $?')
	assert result == 'echo target dep1 dep1 dep2 dep1 dep2'

	// with some variables mixed in a blender
	evaluator.variables['CC'] = 'gcc'
	result2 := evaluator.expand_recipe_vars('program', ['main.o', 'utils.o'], '$(CC) -o $@ $^')
	assert result2 == 'gcc -o program main.o utils.o'

	// ... with single dependency
	result3 := evaluator.expand_recipe_vars('obj.o', ['obj.c'], '$(CC) -c $< -o $@')
	assert result3 == 'gcc -c obj.c -o obj.o'
}

fn test_evaluator_automatic_variable_qmark() {
	mut evaluator := vamk.new_evaluator(false, false)

	// $? automatic variable
	result := evaluator.expand_recipe_vars('target', ['dep1', 'dep2', 'dep3'], 'echo $?')
	assert result == 'echo dep1 dep2 dep3'

	result2 := evaluator.expand_recipe_vars('target', ['dep1'], 'echo $?')
	assert result2 == 'echo dep1'

	// No dependencies (should not replace $?)
	result3 := evaluator.expand_recipe_vars('target', [], 'echo $?')
	assert result3 == 'echo $?'
}

fn test_evaluator_variable_collision() {
	mut evaluator := vamk.new_evaluator(false, false)

	// Set up variables where one is a prefix of another
	evaluator.variables['FOO'] = 'bar'
	evaluator.variables['FOOBAR'] = 'baz'

	// Expansion which force a collision bug from the other day
	result := evaluator.expand_vars(r'$(FOO) $(FOOBAR)')
	assert result == 'bar baz'

	result2 := evaluator.expand_vars(r'${FOO} ${FOOBAR}')
	assert result2 == 'bar baz'

	result3 := evaluator.expand_vars(r'$FOO $FOOBAR')
	assert result3 == 'bar baz'

	// More !
	evaluator.variables['A'] = 'value_a'
	evaluator.variables['AB'] = 'value_ab'
	evaluator.variables['ABC'] = 'value_abc'

	result4 := evaluator.expand_vars(r'$(A) $(AB) $(ABC)')
	assert result4 == 'value_a value_ab value_abc'
}
