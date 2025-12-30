import vamk

fn test_parser_simple_assignment() {
	input := 'VAR = hello world'
	mut parser := vamk.new_parser(input)
	nodes := parser.parse()

	assert nodes.len == 1
	assert nodes[0] is vamk.Assignment

	assign := nodes[0] as vamk.Assignment
	assert assign.name == 'VAR'
	assert assign.value == 'hello world'
	assert assign.assign_type == '='
}

fn test_parser_conditional_assignment() {
	// Test ?=
	mut parser1 := vamk.new_parser('VAR ?= value')
	nodes1 := parser1.parse()
	assert nodes1[0] is vamk.Assignment
	assign1 := nodes1[0] as vamk.Assignment
	assert assign1.name == 'VAR'
	assert assign1.value == 'value'
	assert assign1.assign_type == '?='

	// Test +=
	mut parser2 := vamk.new_parser('VAR += value')
	nodes2 := parser2.parse()
	assert nodes2[0] is vamk.Assignment
	assign2 := nodes2[0] as vamk.Assignment
	assert assign2.name == 'VAR'
	assert assign2.value == 'value'
	assert assign2.assign_type == '+='

	// Test :=
	mut parser3 := vamk.new_parser('VAR := value')
	nodes3 := parser3.parse()
	assert nodes3[0] is vamk.Assignment
	assign3 := nodes3[0] as vamk.Assignment
	assert assign3.name == 'VAR'
	assert assign3.value == 'value'
	assert assign3.assign_type == ':='
}

fn test_parser_malformed_assignment() {
	// Test assignment with no value
	mut parser1 := vamk.new_parser('VAR =')
	nodes1 := parser1.parse()
	assert nodes1.len == 1
	assert nodes1[0] is vamk.Assignment
	assign1 := nodes1[0] as vamk.Assignment
	assert assign1.name == 'VAR'
	assert assign1.value == ''
	assert assign1.assign_type == '='

	// Test assignment with no name
	mut parser2 := vamk.new_parser('= value')
	nodes2 := parser2.parse()
	assert nodes2.len == 1 // Parser still creates assignment with empty name
	assert nodes2[0] is vamk.Assignment
	assign2 := nodes2[0] as vamk.Assignment
	assert assign2.name == ''
	assert assign2.value == 'value'
}

fn test_parser_assignment_with_dashes() {
	// Test parsing assignment with dashes like -Wall
	input := 'CFLAGS = -Wall -O2'
	mut parser := vamk.new_parser(input)
	nodes := parser.parse()
	assert nodes.len == 1
	assert nodes[0] is vamk.Assignment
	assign := nodes[0] as vamk.Assignment
	assert assign.name == 'CFLAGS'
	assert assign.value == '-Wall -O2'
	assert assign.assign_type == '='
}

fn test_parser_assignment_no_value() {
	// Test assignment with no value after '='
	input := 'VAR='
	mut parser := vamk.new_parser(input)
	nodes := parser.parse()
	assert nodes.len == 1
	assert nodes[0] is vamk.Assignment
	assign := nodes[0] as vamk.Assignment
	assert assign.name == 'VAR'
	assert assign.value == ''
}

fn test_parser_assignment_with_var_ref() {
	// Test assignment with variable reference
	input := 'VAR = $(OTHER)'
	mut parser := vamk.new_parser(input)
	nodes := parser.parse()
	assert nodes.len == 1
	assert nodes[0] is vamk.Assignment
	assign := nodes[0] as vamk.Assignment
	assert assign.name == 'VAR'
	assert assign.value == '$(OTHER)'
	assert assign.assign_type == '='
}

fn test_parser_assignment_with_multiple_spaces() {
	// Test assignment with multiple spaces around operator
	input := 'VAR    =     value'
	mut parser := vamk.new_parser(input)
	nodes := parser.parse()
	assert nodes.len == 1
	assert nodes[0] is vamk.Assignment
	assign := nodes[0] as vamk.Assignment
	assert assign.name == 'VAR'
	assert assign.value == 'value'
	assert assign.assign_type == '='
}

fn test_parser_assignment_inline_format() {
	// Test inline assignment format like CC=gcc
	input := 'CC=gcc'
	mut parser := vamk.new_parser(input)
	nodes := parser.parse()
	assert nodes.len == 1
	assert nodes[0] is vamk.Assignment
	assign := nodes[0] as vamk.Assignment
	assert assign.name == 'CC'
	assert assign.value == 'gcc'
	assert assign.assign_type == '='
}

fn test_parser_assignment_with_special_chars() {
	// Test assignment with special characters in value
	input := 'VAR = /path/to/file*.c'
	mut parser := vamk.new_parser(input)
	nodes := parser.parse()
	assert nodes.len == 1
	assert nodes[0] is vamk.Assignment
	assign := nodes[0] as vamk.Assignment
	assert assign.name == 'VAR'
	assert assign.value == '/path/to/file*.c'
	assert assign.assign_type == '='
}

fn test_parser_assignment_with_quotes() {
	// Test assignment with quoted values (quotes are preserved)
	input := 'VAR = "hello world"'
	mut parser := vamk.new_parser(input)
	nodes := parser.parse()
	assert nodes.len == 1
	assert nodes[0] is vamk.Assignment
	assign := nodes[0] as vamk.Assignment
	assert assign.name == 'VAR'
	assert assign.value == '"hello world"'
	assert assign.assign_type == '='
}

fn test_parser_assignment_with_concatenated_vars() {
	// Test assignment with concatenated variable references
	input := 'VAR = $(DIR)/$(FILE)'
	mut parser := vamk.new_parser(input)
	nodes := parser.parse()
	assert nodes.len == 1
	assert nodes[0] is vamk.Assignment
	assign := nodes[0] as vamk.Assignment
	assert assign.name == 'VAR'
	assert assign.value == '$(DIR)/$(FILE)'
	assert assign.assign_type == '='
}

fn test_parser_multiple_assignments() {
	// Test multiple assignments in sequence
	input := 'VAR1 = value1
VAR2 = value2'
	mut parser := vamk.new_parser(input)
	nodes := parser.parse()
	assert nodes.len == 2

	assign1 := nodes[0] as vamk.Assignment
	assert assign1.name == 'VAR1'
	assert assign1.value == 'value1'

	assign2 := nodes[1] as vamk.Assignment
	assert assign2.name == 'VAR2'
	assert assign2.value == 'value2'
}

fn test_parser_assignment_with_equals_in_value() {
	// Test assignment where value contains equals sign
	input := 'VAR = prog1=prog2'
	mut parser := vamk.new_parser(input)
	nodes := parser.parse()
	assert nodes.len == 1
	assert nodes[0] is vamk.Assignment
	assign := nodes[0] as vamk.Assignment
	assert assign.name == 'VAR'
	assert assign.value == 'prog1=prog2'
	assert assign.assign_type == '='
}

fn test_parser_assignment_whitespace_value() {
	// Test assignment with only whitespace in value
	input := 'VAR =    '
	mut parser := vamk.new_parser(input)
	nodes := parser.parse()
	assert nodes.len == 1
	assert nodes[0] is vamk.Assignment
	assign := nodes[0] as vamk.Assignment
	assert assign.name == 'VAR'
	assert assign.value == ''
	assert assign.assign_type == '='
}

fn test_parser_assignment_append_empty() {
	// Test append to empty variable
	input := 'VAR +='
	mut parser := vamk.new_parser(input)
	nodes := parser.parse()
	assert nodes.len == 1
	assert nodes[0] is vamk.Assignment
	assign := nodes[0] as vamk.Assignment
	assert assign.name == 'VAR'
	assert assign.value == ''
	assert assign.assign_type == '+='
}

fn test_parser_assignment_conditional_empty() {
	// Test conditional assignment with empty value
	input := 'VAR ?='
	mut parser := vamk.new_parser(input)
	nodes := parser.parse()
	assert nodes.len == 1
	assert nodes[0] is vamk.Assignment
	assign := nodes[0] as vamk.Assignment
	assert assign.name == 'VAR'
	assert assign.value == ''
	assert assign.assign_type == '?='
}

fn test_parser_assignment_immediate_empty() {
	// Test immediate assignment with empty value
	input := 'VAR :='
	mut parser := vamk.new_parser(input)
	nodes := parser.parse()
	assert nodes.len == 1
	assert nodes[0] is vamk.Assignment
	assign := nodes[0] as vamk.Assignment
	assert assign.name == 'VAR'
	assert assign.value == ''
	assert assign.assign_type == ':='
}

fn test_parser_assignment_with_path() {
	// Test assignment with path value
	input := 'PREFIX = /usr/local'
	mut parser := vamk.new_parser(input)
	nodes := parser.parse()
	assert nodes.len == 1
	assert nodes[0] is vamk.Assignment
	assign := nodes[0] as vamk.Assignment
	assert assign.name == 'PREFIX'
	assert assign.value == '/usr/local'
	assert assign.assign_type == '='
}

fn test_parser_assignment_with_colons() {
	// Test assignment with colons in value (like path lists)
	input := 'PATH = /usr/bin:/bin:/usr/local/bin'
	mut parser := vamk.new_parser(input)
	nodes := parser.parse()
	assert nodes.len == 1
	assert nodes[0] is vamk.Assignment
	assign := nodes[0] as vamk.Assignment
	assert assign.name == 'PATH'
	assert assign.value == '/usr/bin:/bin:/usr/local/bin'
	assert assign.assign_type == '='
}
