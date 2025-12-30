import vamk

fn test_evaluator_rule_storage() {
	mut evaluator := vamk.new_evaluator(false, false)
	rule := vamk.Rule{
		target:       'main'
		dependencies: ['main.o', 'utils.o']
		recipes:      ['$(CC) $(CFLAGS) -o $@ $^']
	}

	evaluator.eval_rule(rule)
	assert 'main' in evaluator.rules
	stored_rule := evaluator.rules['main']
	assert stored_rule.target == 'main'
	assert stored_rule.dependencies == ['main.o', 'utils.o']
	assert stored_rule.recipes == ['$(CC) $(CFLAGS) -o $@ $^']
}

fn test_evaluator_substitution_references() {
	mut evaluator := vamk.new_evaluator(false, false)
	evaluator.variables['SRCS'] = 'main.c utils.c'
	evaluator.variables['FILES'] = 'file1.txt file2.txt'

	// Test basic substitution
	result := evaluator.expand_vars('$(SRCS:.c=.o)')
	assert result == 'main.o utils.o'

	// Test substitution with empty old pattern
	result2 := evaluator.expand_vars('$(FILES:.txt=)')
	assert result2 == 'file1 file2'

	// Test substitution that doesn't match
	result3 := evaluator.expand_vars('$(SRCS:.cpp=.o)')
	assert result3 == 'main.c utils.c'

	// Test with undefined variable
	result4 := evaluator.expand_vars('$(UNDEFINED:.c=.o)')
	assert result4 == ''
}

fn test_evaluator_multiple_nodes() {
	mut evaluator := vamk.new_evaluator(false, false)

	nodes := [
		vamk.ASTNode(vamk.Assignment{
			name:        'CC'
			value:       'gcc'
			assign_type: '='
		}),
		vamk.ASTNode(vamk.Assignment{
			name:        'CFLAGS'
			value:       '-Wall'
			assign_type: '+='
		}),
		vamk.ASTNode(vamk.Rule{
			target:       'all'
			dependencies: ['main.o']
			recipes:      ['$(CC) $(CFLAGS) -o main main.o']
		}),
	]

	evaluator.eval(nodes)

	assert evaluator.variables['CC'] == 'gcc'
	assert evaluator.variables['CFLAGS'] == '-Wall'
	assert evaluator.rules['all'].target == 'all'
}

fn test_evaluator_pattern_rules() {
	mut evaluator := vamk.new_evaluator(false, false)

	pattern_rule := vamk.Rule{
		target:       '%.o'
		dependencies: ['%.c']
		recipes:      ['gcc -c $< -o $@']
	}

	evaluator.eval_rule(pattern_rule)

	// Check that it's stored as a pattern rule
	assert evaluator.pattern_rules.len == 1
	assert evaluator.pattern_rules[0].target == '%.o'

	// Pattern matching
	assert evaluator.matches_pattern('%.o', 'main.o')
	assert evaluator.matches_pattern('%.o', 'utils.o')
	assert !evaluator.matches_pattern('%.o', 'main.c')
	assert !evaluator.matches_pattern('lib%.so', 'library')

	// Test stem extraction
	assert evaluator.extract_stem('%.o', 'main.o') == 'main'
	assert evaluator.extract_stem('lib%.so', 'libfoo.so') == 'foo'

	// Test pattern rule expansion
	expanded := evaluator.expand_pattern_rule(pattern_rule, 'main.o')
	assert expanded.target == 'main.o'
	assert expanded.dependencies == ['main.c']
	assert expanded.recipes == ['gcc -c $< -o $@']

	// Test finding pattern rule
	found_rule := evaluator.find_pattern_rule('main.o') or { vamk.Rule{} }
	assert found_rule.target == '%.o'

	// Test $*
	evaluator.pattern_rules << pattern_rule // Make sure it's there, hopefully
	result := evaluator.expand_recipe_vars('main.o', ['main.c'], 'echo $*')
	assert result == 'echo main'
}
