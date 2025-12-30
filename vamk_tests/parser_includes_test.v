import vamk

fn test_parser_include_short() {
	// Test include with short line
	input := vamk.token_str_include
	mut parser := vamk.new_parser(input)
	nodes := parser.parse()
	assert nodes.len >= 0 // Should not crash
}

fn test_parser_include_empty() {
	// Test include with empty file (should not panic, which happened once :( )
	input := vamk.token_str_include
	mut parser := vamk.new_parser(input)
	nodes := parser.parse()
	// Just ensure no crash, even if not parsed
	assert true
}

fn test_parser_include() {
	input := 'include common.mk'
	mut parser := vamk.new_parser(input)
	nodes := parser.parse()

	assert nodes.len == 1
	assert nodes[0] is vamk.Include

	include_node := nodes[0] as vamk.Include
	assert include_node.file == 'common.mk'
	assert include_node.optional == false
}

fn test_parser_include_optional() {
	input := '-include common.mk'
	mut parser := vamk.new_parser(input)
	nodes := parser.parse()

	assert nodes.len == 1
	assert nodes[0] is vamk.Include

	include_node := nodes[0] as vamk.Include
	assert include_node.file == 'common.mk'
	assert include_node.optional == true
}
