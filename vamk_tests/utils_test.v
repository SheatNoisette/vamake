import vamk

fn test_find_makefile_exists() {
	// Test in current directory which should have no makefile
	// (since we're in the vamake source directory)
	result := vamk.find_makefile() or {
		// Expected to fail since no makefile in current dir
		assert true
		return
	}
	// If it finds one, make sure it's a valid makefile name
	assert result.to_lower() in ['makefile', 'gnumakefile']
}

fn test_pretty_print_empty_nodes() {
	nodes := []vamk.ASTNode{}
	// This should not crash
	vamk.pretty_print(nodes)
}

fn test_pretty_print_various_nodes() {
	nodes := [
		vamk.ASTNode(vamk.Assignment{
			name:        'VAR'
			value:       'value'
			assign_type: '='
		}),
		vamk.ASTNode(vamk.Rule{
			target:       'all'
			dependencies: ['main.o']
			recipes:      ['gcc main.o -o main']
		}),
		vamk.ASTNode(vamk.Comment{
			text: 'This is a comment'
		}),
	]
	// This should not crash
	vamk.pretty_print(nodes)
}
