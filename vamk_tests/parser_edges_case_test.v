import vamk

fn test_parser_empty_lines() {
	input := '\nVAR = value\n\ntarget: dep\n\n\tcommand\n'
	mut parser := vamk.new_parser(input)
	nodes := parser.parse()

	assert nodes.len == 3

	assert nodes[0] is vamk.Assignment
	assert nodes[1] is vamk.Rule
	assert nodes[2] is vamk.ShellCommand
}

fn test_parser_empty_input() {
	// Test parsing empty input to check for crashes
	input := ''
	mut parser := vamk.new_parser(input)
	nodes := parser.parse()
	assert nodes.len == 0
}

fn test_parser_rule_only_colon() {
	// Test line with only ':'
	input := ':'
	mut parser := vamk.new_parser(input)
	nodes := parser.parse()
	assert nodes.len == 1
	assert nodes[0] is vamk.Rule
	rule := nodes[0] as vamk.Rule
	assert rule.target == ''
	assert rule.dependencies.len == 0
}
