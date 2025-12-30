import vamk

fn test_evaluator_recipe_level_conditionals() {
	// Test case from vlang/v/GNUmakefile on which conditionals within recipe
	// blocks. These should be filtered out, not executed as shell commands !

	// This was causing: "ifdef LEGACY: command not found" errors :(
	makefile := '
all: main.o
ifdef LEGACY
	$(MAKE) -C legacy_dir
endif
	gcc -o $@ $^
'

	mut parser := vamk.new_parser(makefile)
	nodes := parser.parse()
	mut evaluator := vamk.new_evaluator(false, false)

	// This should not cause "ifdef: command not found" error
	evaluator.eval(nodes)

	// Rule should exist without errors
	assert 'all' in evaluator.rules
	rule := evaluator.rules['all']

	// Conditional directive should be filtered out, only actual recipes remain
	assert rule.recipes.len == 1
	assert rule.recipes[0] == 'gcc -o $@ $^'
}
