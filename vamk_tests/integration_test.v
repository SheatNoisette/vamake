import vamk
import os

// -----------------------------------------------------------------------------
// These are just tests on real makefile, nothing fancy
// -----------------------------------------------------------------------------

fn test_integration_simple_makefile() {
	makefile_path := 'tests/simple_makefile'

	content := os.read_file(makefile_path) or {
		eprintln('Failed to read ${makefile_path}')
		return
	}

	mut parser := vamk.new_parser(content)
	nodes := parser.parse()

	mut evaluator := vamk.new_evaluator(false, false)
	evaluator.eval(nodes)

	// Check that variables were set
	assert evaluator.variables['CC'] == 'gcc'
	assert evaluator.variables['CFLAGS'] == '-Wall -O2'

	// Rules parsed ?
	assert evaluator.rules['all'].target == 'all'
	assert evaluator.rules['main'].target == 'main'
	assert evaluator.rules['main.o'].target == 'main.o'
	assert evaluator.rules['utils.o'].target == 'utils.o'
	assert evaluator.rules['clean'].target == 'clean'

	// Check rule details
	all_rule := evaluator.rules['all']
	assert all_rule.dependencies == ['main']
	assert all_rule.recipes.len == 0

	// Check main rule has the recipe
	main_rule := evaluator.rules['main']
	assert main_rule.dependencies == ['main.o', 'utils.o']
	assert main_rule.recipes[0] == '$(CC) $(CFLAGS) -o main main.o utils.o'

	// Check phony targets
	assert 'clean' in evaluator.phony_targets
	clean_rule := evaluator.rules['clean']
	assert clean_rule.phony == true
}

fn test_integration_phony_targets() {
	// comprehensive phony target functionality
	content := '
.PHONY: clean test all

all: main

main: main.o
	@echo "linking main"

main.o: main.c
	@echo "compiling main.c"

clean:
	@echo "cleaning"

test:
	@echo "testing"
'

	mut parser := vamk.new_parser(content)
	nodes := parser.parse()

	mut evaluator := vamk.new_evaluator(false, false)
	evaluator.eval(nodes)

	// Check that all declared phony targets are marked
	assert 'clean' in evaluator.phony_targets
	assert 'test' in evaluator.phony_targets
	assert 'all' in evaluator.phony_targets

	// Check that rules are marked as phony
	assert evaluator.rules['clean'].phony == true
	assert evaluator.rules['test'].phony == true
	assert evaluator.rules['all'].phony == true

	// Check that non-phony rules are not marked
	assert evaluator.rules['main'].phony == false
	assert evaluator.rules['main.o'].phony == false
}

fn test_integration_phony_pattern_rules() {
	// phony with pattern rules
	content := '
.PHONY: clean

%.o: %.c
	@echo "compiling $<"

clean:
	@echo "cleaning"
'

	mut parser := vamk.new_parser(content)
	nodes := parser.parse()

	mut evaluator := vamk.new_evaluator(false, false)
	evaluator.eval(nodes)

	// Check phony target
	assert 'clean' in evaluator.phony_targets
	assert evaluator.rules['clean'].phony == true

	// Check pattern rule (should not be phony by default)
	assert evaluator.pattern_rules.len == 1
	assert evaluator.pattern_rules[0].phony == false

	// expanding a pattern rule for a phony target
	content2 := '
.PHONY: clean test.o

%.o: %.c
	@echo "compiling $<"

clean:
	@echo "cleaning"
'

	mut parser2 := vamk.new_parser(content2)
	nodes2 := parser2.parse()

	mut evaluator2 := vamk.new_evaluator(false, false)
	evaluator2.eval(nodes2)

	// test.o should be phony
	assert 'test.o' in evaluator2.phony_targets

	// When we expand the pattern rule for test.o, it should be phony
	expanded_rule := evaluator2.expand_pattern_rule(evaluator2.pattern_rules[0], 'test.o')
	assert expanded_rule.phony == true
}

fn test_integration_conditional_makefile() {
	makefile_path := 'tests/conditional_makefile'

	content := os.read_file(makefile_path) or {
		eprintln('Failed to read ${makefile_path}')
		return
	}

	mut parser := vamk.new_parser(content)
	nodes := parser.parse()

	// println('Parsed nodes: ${nodes}')

	mut evaluator := vamk.new_evaluator(false, false)
	evaluator.eval(nodes)

	// Check basic variables
	assert evaluator.variables['CC'] == 'gcc'
	assert evaluator.variables['TARGET'] == 'myapp'

	// Check conditional logic (DEBUG not defined, so should use else branch)
	assert evaluator.variables['CFLAGS'] == '-Wall -O2'
	assert evaluator.variables['OPTIMIZE'] == '-O2'

	// Check rules
	assert evaluator.rules['all'].target == 'all'
	assert evaluator.rules['myapp'].target == 'myapp'
	assert evaluator.rules['clean'].target == 'clean'
}

fn test_integration_advanced_makefile() {
	makefile_path := 'tests/advanced_makefile'

	// Read and parse makefile
	content := os.read_file(makefile_path) or {
		eprintln('Failed to read ${makefile_path}')
		return
	}

	mut parser := vamk.new_parser(content)
	nodes := parser.parse()

	mut evaluator := vamk.new_evaluator(false, false)
	evaluator.eval(nodes)

	// Check that shell commands were evaluated
	assert evaluator.variables['SHELL'] == '/bin/bash'

	// DIR_NAME should contain some value (basename of current dir)
	assert evaluator.variables['DIR_NAME'].len > 0

	// Check rules exist
	assert evaluator.rules['all'].target == 'all'
	assert evaluator.rules['clean'].target == 'clean'
	assert evaluator.rules['install'].target == 'install'
	assert evaluator.rules['uninstall'].target == 'uninstall'

	// Check pattern rule exists
	assert evaluator.pattern_rules.len == 1
	assert evaluator.pattern_rules[0].target == '%.o'
	assert evaluator.pattern_rules[0].dependencies == ['%.c']
	assert evaluator.pattern_rules[0].recipes == ['$(CC) $(CFLAGS) -c $< -o $@']

	// that we can find a matching pattern rule for a target
	pattern_rule := evaluator.find_pattern_rule('main.o') or { vamk.Rule{} }
	assert pattern_rule.target == '%.o'

	// Pattern rule expansion
	expanded_rule := evaluator.expand_pattern_rule(pattern_rule, 'main.o')
	assert expanded_rule.target == 'main.o'
	assert expanded_rule.dependencies == ['main.c']
	assert expanded_rule.recipes == ['$(CC) $(CFLAGS) -c $< -o $@']
}

fn test_integration_vlang_makefile() {
	makefile_path := 'tests/vlang_makefile'

	content := os.read_file(makefile_path) or {
		eprintln('Failed to read ${makefile_path}')
		return
	}

	mut parser := vamk.new_parser(content)
	nodes := parser.parse()

	mut evaluator := vamk.new_evaluator(false, false)
	evaluator.eval(nodes)

	// Check basic variables
	assert evaluator.variables['CC'] == 'cc'
	assert evaluator.variables['VROOT'] == '.'
	assert evaluator.variables['VC'] == './vc'
	assert evaluator.variables['VEXE'] == './v'

	// Check shell command evaluation (we're not on actual system, chec if it was processed)
	// The _SYS variable should be set via shell command
	assert '_SYS' in evaluator.variables

	// Check that patsubst is expanded
	assert !evaluator.variables['_SYS'].contains('patsubst')

	// Check that basic conditional parsing works
	// Since make functions are evaluated, _SYS is set to uname output, and conditionals are evaluated properly
	assert 'LINUX' !in evaluator.variables
	assert 'MAC' in evaluator.variables
	assert 'WIN32' !in evaluator.variables

	// Check rules exist
	assert 'all' in evaluator.rules
	assert 'clean' in evaluator.rules
	assert 'rebuild' in evaluator.rules
	assert 'fresh_vc' in evaluator.rules

	// Check all rule has latest_vc latest_tcc latest_legacy dependencies
	all_rule := evaluator.rules['all']
	assert 'latest_vc' in all_rule.dependencies
	assert 'latest_tcc' in all_rule.dependencies
	assert 'latest_legacy' in all_rule.dependencies
}

// the full main function flow (without actally executing commands)
fn test_main_function_parsing() {
	// with simple makefile
	makefile_path := 'tests/simple_makefile'

	content := os.read_file(makefile_path) or {
		eprintln('Failed to read ${makefile_path}')
		return
	}

	// This simulates the main function logic
	mut parser := vamk.new_parser(content)
	nodes := parser.parse()

	mut evaluator := vamk.new_evaluator(false, false)
	evaluator.eval(nodes)

	// Check that we can access the target
	target := 'all'
	rule := evaluator.rules[target]
	assert rule.target == 'all'
	assert rule.dependencies == ['main']
}

fn test_integration_include_makefile() {
	makefile_path := 'tests/include_makefile'

	// Read and parse makefile
	content := os.read_file(makefile_path) or {
		eprintln('Failed to read ${makefile_path}')
		return
	}

	mut parser := vamk.new_parser(content)
	nodes := parser.parse()

	mut evaluator := vamk.new_evaluator(false, false)
	evaluator.eval(nodes)

	// Check that variables from included file were set
	assert evaluator.variables['CC'] == 'gcc'
	assert evaluator.variables['CFLAGS'] == '-Wall -O2'

	// Check that variables from main file were set
	assert evaluator.variables['TARGET'] == 'myapp'
	assert evaluator.variables['SOURCES'] == 'main.c utils.c'

	// Check that rules from included file were parsed
	assert evaluator.rules['all'].target == 'all'
	assert evaluator.rules['main'].target == 'main'
	assert evaluator.rules['main.o'].target == 'main.o'
	assert evaluator.rules['utils.o'].target == 'utils.o'
	assert evaluator.rules['clean'].target == 'clean'

	// Check that rules from main file were parsed
	assert evaluator.rules['install'].target == 'install'
	assert evaluator.rules['uninstall'].target == 'uninstall'

	// Check rule details
	main_rule := evaluator.rules['main']
	assert main_rule.dependencies == ['main.o', 'utils.o']
	assert main_rule.recipes[0] == '$(CC) $(CFLAGS) -o main main.o utils.o'
}

fn test_integration_invalid_makefile_content() {
	// Parsing completely invalid makefile content
	invalid_content := 'this is not a valid makefile syntax at all, WHATTT!!!'

	mut parser := vamk.new_parser(invalid_content)
	nodes := parser.parse()

	// Parser should handle invalid content and not crap the bed
	// It might produce some nodes or none
	assert true // Just ensure no crash
}

fn test_integration_build_nonexistent_target() {
	makefile_path := 'tests/simple_makefile'

	content := os.read_file(makefile_path) or {
		eprintln('Failed to read ${makefile_path}')
		return
	}

	mut parser := vamk.new_parser(content)
	nodes := parser.parse()

	mut evaluator := vamk.new_evaluator(false, false)
	evaluator.eval(nodes)

	// Try to build a target that doesn't exist
	evaluator.build_target('nonexistent_target') or {
		assert err.msg().contains('No rule to make target')
		return
	}

	// Should not reach here
	assert false, 'Expected error for nonexistent target'
}
