import vamk

fn test_parser_malformed_rule() {
	// Test rule with no target
	mut parser1 := vamk.new_parser(': dep\n\tcommand')
	nodes1 := parser1.parse()
	assert nodes1.len == 1 // Parser still creates rule with empty target
	assert nodes1[0] is vamk.Rule
	rule1 := nodes1[0] as vamk.Rule
	assert rule1.target == ''
	assert rule1.dependencies == ['dep']

	// Malformed target
	mut parser2 := vamk.new_parser('target dep:\n\tcommand')
	nodes2 := parser2.parse()
	assert nodes2.len == 1
	assert nodes2[0] is vamk.Rule
	rule2 := nodes2[0] as vamk.Rule
	assert rule2.target == 'target dep'
	assert rule2.dependencies.len == 0
}

fn test_parser_rule_multiple_colons() {
	// Multiple colons
	input := 'target:dep:extra\n\tcommand'
	mut parser := vamk.new_parser(input)
	nodes := parser.parse()
	assert nodes.len == 1
	assert nodes[0] is vamk.Rule
	rule := nodes[0] as vamk.Rule
	assert rule.target == 'target'
	assert rule.dependencies == ['dep'] // Parser splits on all :, so deps up to first :
}
