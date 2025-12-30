import vamk

fn test_parser_unclosed_conditional() {
	// Test conditional without endif
	input := 'ifdef DEBUG\nVAR = debug\nelse\nVAR = release'
	mut parser := vamk.new_parser(input)
	nodes := parser.parse()

	// Parser should still parse the conditional even without endif
	assert nodes.len == 1
	assert nodes[0] is vamk.Conditional
}

fn test_parser_malformed_conditional_short() {
	// Test conditional with short line to cause potential index out of bounds
	input := 'ifdef\nVAR = value'
	mut parser := vamk.new_parser(input)
	nodes := parser.parse()
	// Should not crash, perhaps skip or parse as conditional with empty condition
	assert nodes.len >= 0 // Just ensure no panic
}

fn test_parser_assignment_only_equals() {
	// Test line with only '='
	input := '='
	mut parser := vamk.new_parser(input)
	nodes := parser.parse()
	assert nodes.len >= 0 // Should not crash
}

fn test_parser_malformed_conditional_incomplete() {
	// Test incomplete conditional keywords
	input := 'if\nVAR = value'
	mut parser := vamk.new_parser(input)
	nodes := parser.parse()
	assert nodes.len >= 0 // Ensure no crash
}

fn test_parse_conditional_block_simple() {
	// Test basic conditional block with assignments
	input := 'ifdef DEBUG\nVAR1 = value1\nVAR2 = value2\nendif'
	mut parser := vamk.new_parser(input)
	nodes := parser.parse()

	assert nodes.len == 1
	assert nodes[0] is vamk.Conditional

	cond := nodes[0] as vamk.Conditional
	assert cond.then_nodes.len == 2
	assert cond.then_nodes[0] is vamk.Assignment
	assert cond.then_nodes[1] is vamk.Assignment

	assign1 := cond.then_nodes[0] as vamk.Assignment
	assert assign1.name == 'VAR1'
	assert assign1.value == 'value1'

	assign2 := cond.then_nodes[1] as vamk.Assignment
	assert assign2.name == 'VAR2'
	assert assign2.value == 'value2'
}

fn test_parse_conditional_block_with_rules() {
	// Test conditional block with rules
	input := 'ifdef DEBUG\nall:\n\techo debug\nclean:\n\trm -f *.o\nendif'
	mut parser := vamk.new_parser(input)
	nodes := parser.parse()

	assert nodes.len == 1
	assert nodes[0] is vamk.Conditional

	cond := nodes[0] as vamk.Conditional
	assert cond.then_nodes.len == 2
	assert cond.then_nodes[0] is vamk.Rule
	assert cond.then_nodes[1] is vamk.Rule

	rule1 := cond.then_nodes[0] as vamk.Rule
	assert rule1.target == 'all'

	rule2 := cond.then_nodes[1] as vamk.Rule
	assert rule2.target == 'clean'
}

fn test_parse_conditional_block_with_shell_commands() {
	// Test conditional block with shell commands
	input := 'ifdef DEBUG\n\techo "building debug"\n\tgcc -g -o main main.c\nendif'
	mut parser := vamk.new_parser(input)
	nodes := parser.parse()

	assert nodes.len == 1
	assert nodes[0] is vamk.Conditional

	cond := nodes[0] as vamk.Conditional
	assert cond.then_nodes.len == 2
	assert cond.then_nodes[0] is vamk.ShellCommand
	assert cond.then_nodes[1] is vamk.ShellCommand

	cmd1 := cond.then_nodes[0] as vamk.ShellCommand
	assert cmd1.command == 'echo "building debug"'

	cmd2 := cond.then_nodes[1] as vamk.ShellCommand
	assert cmd2.command == 'gcc -g -o main main.c'
}

fn test_parse_conditional_block_nested() {
	// nested conditionals
	input := 'ifdef DEBUG\nVAR1 = outer\nifdef VERBOSE\nVAR2 = inner\nendif\nVAR3 = outer_again\nendif'
	mut parser := vamk.new_parser(input)
	nodes := parser.parse()

	assert nodes.len == 1
	assert nodes[0] is vamk.Conditional

	outer_cond := nodes[0] as vamk.Conditional
	assert outer_cond.then_nodes.len == 3
	assert outer_cond.then_nodes[0] is vamk.Assignment
	assert outer_cond.then_nodes[1] is vamk.Conditional
	assert outer_cond.then_nodes[2] is vamk.Assignment

	assign1 := outer_cond.then_nodes[0] as vamk.Assignment
	assert assign1.name == 'VAR1'

	inner_cond := outer_cond.then_nodes[1] as vamk.Conditional
	assert inner_cond.then_nodes.len == 1
	assert inner_cond.then_nodes[0] is vamk.Assignment

	assign2 := inner_cond.then_nodes[0] as vamk.Assignment
	assert assign2.name == 'VAR2'

	assign3 := outer_cond.then_nodes[2] as vamk.Assignment
	assert assign3.name == 'VAR3'
}

fn test_parse_conditional_block_multiple_nested() {
	// Multiple levels of nesting
	input := 'ifdef LEVEL1\nVAR1 = l1\nifdef LEVEL2\nVAR2 = l2\nifdef LEVEL3\nVAR3 = l3\nendif\nVAR4 = l2_end\nendif\nVAR5 = l1_end\nendif'
	mut parser := vamk.new_parser(input)
	nodes := parser.parse()

	assert nodes.len == 1
	assert nodes[0] is vamk.Conditional

	level1 := nodes[0] as vamk.Conditional
	assert level1.then_nodes.len == 3
	assert level1.then_nodes[0] is vamk.Assignment
	assert level1.then_nodes[1] is vamk.Conditional
	assert level1.then_nodes[2] is vamk.Assignment

	level2 := level1.then_nodes[1] as vamk.Conditional
	assert level2.then_nodes.len == 3
	assert level2.then_nodes[0] is vamk.Assignment
	assert level2.then_nodes[1] is vamk.Conditional
	assert level2.then_nodes[2] is vamk.Assignment

	level3 := level2.then_nodes[1] as vamk.Conditional
	assert level3.then_nodes.len == 1
	assert level3.then_nodes[0] is vamk.Assignment
	assert (level3.then_nodes[0] as vamk.Assignment).name == 'VAR3'
}

fn test_parse_conditional_block_with_comments() {
	// Test conditional block with comments
	input := 'ifdef DEBUG\n# This is a debug build\nVAR = debug\n# End debug section\nendif'
	mut parser := vamk.new_parser(input)
	nodes := parser.parse()

	assert nodes.len == 1
	assert nodes[0] is vamk.Conditional

	cond := nodes[0] as vamk.Conditional
	assert cond.then_nodes.len == 3
	assert cond.then_nodes[0] is vamk.Comment
	assert cond.then_nodes[1] is vamk.Assignment
	assert cond.then_nodes[2] is vamk.Comment

	comment1 := cond.then_nodes[0] as vamk.Comment
	assert comment1.text == 'This is a debug build'

	assign := cond.then_nodes[1] as vamk.Assignment
	assert assign.name == 'VAR'

	comment2 := cond.then_nodes[2] as vamk.Comment
	assert comment2.text == 'End debug section'
}

fn test_parse_conditional_block_mixed_nodes() {
	// Test conditional block with mixed node types
	input := 'ifdef DEBUG\nCC = gcc\n# Compiler\nCFLAGS = -Wall\nall:\n\t$(CC) $(CFLAGS) -o main main.c\nendif'
	mut parser := vamk.new_parser(input)
	nodes := parser.parse()

	assert nodes.len == 1
	assert nodes[0] is vamk.Conditional

	cond := nodes[0] as vamk.Conditional
	assert cond.then_nodes.len == 4
	assert cond.then_nodes[0] is vamk.Assignment
	assert cond.then_nodes[1] is vamk.Comment
	assert cond.then_nodes[2] is vamk.Assignment
	assert cond.then_nodes[3] is vamk.Rule
}

fn test_parse_conditional_block_without_else() {
	// Test conditional block that ends with endif (no else)
	input := 'ifdef DEBUG\nVAR = debug\nendif'
	mut parser := vamk.new_parser(input)
	nodes := parser.parse()

	assert nodes.len == 1
	assert nodes[0] is vamk.Conditional

	cond := nodes[0] as vamk.Conditional
	assert cond.then_nodes.len == 1
	assert cond.else_nodes.len == 0

	assign := cond.then_nodes[0] as vamk.Assignment
	assert assign.name == 'VAR'
	assert assign.value == 'debug'
}

fn test_parse_conditional_block_empty() {
	// Test empty conditional block
	input := 'ifdef DEBUG\nendif'
	mut parser := vamk.new_parser(input)
	nodes := parser.parse()

	assert nodes.len == 1
	assert nodes[0] is vamk.Conditional

	cond := nodes[0] as vamk.Conditional
	assert cond.then_nodes.len == 0
	assert cond.else_nodes.len == 0
}

fn test_parse_conditional_block_with_else() {
	// Test conditional block with else
	input := 'ifdef DEBUG\nVAR = debug\nelse\nVAR = release\nendif'
	mut parser := vamk.new_parser(input)
	nodes := parser.parse()

	assert nodes.len == 1
	assert nodes[0] is vamk.Conditional

	cond := nodes[0] as vamk.Conditional
	assert cond.then_nodes.len == 1
	assert cond.else_nodes.len == 1
	assert cond.then_nodes[0] is vamk.Assignment
	assert cond.else_nodes[0] is vamk.Assignment

	then_assign := cond.then_nodes[0] as vamk.Assignment
	assert then_assign.name == 'VAR'
	assert then_assign.value == 'debug'

	else_assign := cond.else_nodes[0] as vamk.Assignment
	assert else_assign.name == 'VAR'
	assert else_assign.value == 'release'
}

fn test_parse_conditional_block_else_if() {
	// Test else if pattern
	input := 'ifeq ($(VAR),debug\n\techo "debug"\nelse ifeq ($(VAR),release\n\techo "release"\nendif'
	mut parser := vamk.new_parser(input)
	nodes := parser.parse()

	assert nodes.len == 1
	assert nodes[0] is vamk.Conditional

	cond := nodes[0] as vamk.Conditional
	assert cond.then_nodes.len == 1
	assert cond.else_nodes.len == 1
	assert cond.then_nodes[0] is vamk.ShellCommand
	assert cond.else_nodes[0] is vamk.Conditional

	else_cond := cond.else_nodes[0] as vamk.Conditional
	assert else_cond.then_nodes.len == 1
	assert else_cond.then_nodes[0] is vamk.ShellCommand
}

fn test_parse_conditional_block_nested_with_else() {
	// Nested conditionals with else at different depths
	input := 'ifdef OUTER\nVAR1 = outer\nifdef INNER\nVAR2 = inner\nelse\nVAR3 = inner_else\nendif\nVAR4 = outer_end\nendif'
	mut parser := vamk.new_parser(input)
	nodes := parser.parse()

	assert nodes.len == 1
	assert nodes[0] is vamk.Conditional

	outer_cond := nodes[0] as vamk.Conditional
	assert outer_cond.then_nodes.len == 3

	inner_cond := outer_cond.then_nodes[1] as vamk.Conditional
	assert inner_cond.then_nodes.len == 1
	assert inner_cond.else_nodes.len == 1

	assert inner_cond.then_nodes[0] is vamk.Assignment
	assert inner_cond.else_nodes[0] is vamk.Assignment
}

fn test_parse_conditional_block_multiple_assignments() {
	// block with many assignments
	input := 'ifdef DEBUG\nVAR1 = val1\nVAR2 = val2\nVAR3 = val3\nVAR4 = val4\nVAR5 = val5\nendif'
	mut parser := vamk.new_parser(input)
	nodes := parser.parse()

	assert nodes.len == 1
	assert nodes[0] is vamk.Conditional

	cond := nodes[0] as vamk.Conditional
	assert cond.then_nodes.len == 5

	for i in 0 .. 5 {
		assert cond.then_nodes[i] is vamk.Assignment
		assign := cond.then_nodes[i] as vamk.Assignment
		assert assign.name == 'VAR${i + 1}'
		assert assign.value == 'val${i + 1}'
	}
}

fn test_parse_conditional_block_rules_and_assignments() {
	// Conditional block with rules and assignments mixed
	input := 'ifdef DEBUG\nCC = gcc\nall:\n\t$(CC) -o prog main.c\nCFLAGS = -g\ninstall:\n\tcp prog /usr/local/bin\nendif'
	mut parser := vamk.new_parser(input)
	nodes := parser.parse()

	assert nodes.len == 1
	assert nodes[0] is vamk.Conditional

	cond := nodes[0] as vamk.Conditional
	assert cond.then_nodes.len == 4
	assert cond.then_nodes[0] is vamk.Assignment
	assert cond.then_nodes[1] is vamk.Rule
	assert cond.then_nodes[2] is vamk.Assignment
	assert cond.then_nodes[3] is vamk.Rule

	rule1 := cond.then_nodes[1] as vamk.Rule
	assert rule1.target == 'all'

	rule2 := cond.then_nodes[3] as vamk.Rule
	assert rule2.target == 'install'
}
