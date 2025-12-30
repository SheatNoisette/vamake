import vamk

fn test_parser_simple_rule() {
	input := 'target: dep1 dep2\n\tcommand1\n\tcommand2'
	mut parser := vamk.new_parser(input)
	nodes := parser.parse()

	assert nodes.len == 1
	assert nodes[0] is vamk.Rule

	rule := nodes[0] as vamk.Rule
	assert rule.target == 'target'
	assert rule.dependencies == ['dep1', 'dep2']
	assert rule.recipes == ['command1', 'command2']
}

fn test_parser_rule_without_dependencies() {
	input := 'clean:\n\trm -f *.o'
	mut parser := vamk.new_parser(input)
	nodes := parser.parse()

	assert nodes.len == 1
	assert nodes[0] is vamk.Rule

	rule := nodes[0] as vamk.Rule
	assert rule.target == 'clean'
	assert rule.dependencies.len == 0
	assert rule.recipes == ['rm -f *.o']
}

fn test_parser_multiple_rules_and_assignments() {
	input := 'CC = gcc\nCFLAGS = -Wall\n\nall: main.o utils.o\n\t$(CC) $(CFLAGS) -o main main.o utils.o\n\nmain.o: main.c\n\t$(CC) $(CFLAGS) -c main.c\n\nutils.o: utils.c\n\t$(CC) $(CFLAGS) -c utils.c\n\nclean:\n\trm -f *.o main'
	mut parser := vamk.new_parser(input)
	nodes := parser.parse()

	assert nodes.len == 6

	// Check assignments
	assert nodes[0] is vamk.Assignment
	assign1 := nodes[0] as vamk.Assignment
	assert assign1.name == 'CC'
	assert assign1.value == 'gcc'

	assert nodes[1] is vamk.Assignment
	assign2 := nodes[1] as vamk.Assignment
	assert assign2.name == 'CFLAGS'
	assert assign2.value == '-Wall'

	// Verify rules
	assert nodes[2] is vamk.Rule
	rule1 := nodes[2] as vamk.Rule
	assert rule1.target == 'all'
	assert rule1.dependencies == ['main.o', 'utils.o']

	assert nodes[3] is vamk.Rule
	rule2 := nodes[3] as vamk.Rule
	assert rule2.target == 'main.o'
	assert rule2.dependencies == ['main.c']

	assert nodes[4] is vamk.Rule
	rule3 := nodes[4] as vamk.Rule
	assert rule3.target == 'utils.o'
	assert rule3.dependencies == ['utils.c']

	assert nodes[5] is vamk.Rule
	rule4 := nodes[5] as vamk.Rule
	assert rule4.target == 'clean'
	assert rule4.dependencies.len == 0
}

fn test_parser_comments() {
	input := '# This is a comment\nVAR = value\n# NOTICE ME PLZ\ntarget: dep\n\tcommand'
	mut parser := vamk.new_parser(input)
	nodes := parser.parse()

	assert nodes.len == 4

	assert nodes[0] is vamk.Comment
	comment1 := nodes[0] as vamk.Comment
	assert comment1.text == 'This is a comment'

	assert nodes[1] is vamk.Assignment
	assign := nodes[1] as vamk.Assignment
	assert assign.name == 'VAR'

	assert nodes[2] is vamk.Comment
	comment2 := nodes[2] as vamk.Comment
	assert comment2.text == 'NOTICE ME PLZ'

	assert nodes[3] is vamk.Rule
	rule := nodes[3] as vamk.Rule
	assert rule.target == 'target'
}

fn test_parser_extremely_long_input() {
	// This is trival, sure, but test with very long input :)
	mut long_input := ''
	for i in 0 .. 10000 {
		long_input += 'VAR${i} = value${i}\n'
	}
	mut parser := vamk.new_parser(long_input)
	nodes := parser.parse()
	assert nodes.len == 10000 // Should parse all assignments without breaking
}

fn test_evaluator_conditional_with_parens_in_condition() {
	mut evaluator := vamk.new_evaluator(false, false)
	evaluator.variables['VAR'] = 'Darwin'

	cond := vamk.Conditional{
		kind:       vamk.ConditionalType.ifeq
		condition:  '($(VAR),Darwin)'
		then_nodes: [
			vamk.Assignment{
				name:        'RESULT'
				value:       'true'
				assign_type: '='
			},
		]
		else_nodes: [
			vamk.Assignment{
				name:        'RESULT'
				value:       'false'
				assign_type: '='
			},
		]
	}

	evaluator.eval_conditional(cond)
	assert evaluator.variables['RESULT'] == 'true'
}
