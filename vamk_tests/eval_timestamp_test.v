import vamk
import os

fn test_evaluator_timestamp_checking() {
	mut evaluator := vamk.new_evaluator(false, false)

	// Create test files
	test_target := 'test_timestamp_target.txt'
	test_dep := 'test_timestamp_dep.txt'
	test_dep2 := 'test_timestamp_dep2.txt'

	// Clean up any existing test files
	if os.exists(test_target) {
		os.rm(test_target)!
	}
	if os.exists(test_dep) {
		os.rm(test_dep)!
	}

	// Create dependency file
	os.write_file(test_dep, 'dependency content')!

	// Add a rule for the target
	rule := vamk.Rule{
		target:       test_target
		dependencies: [test_dep]
		recipes:      ['cp ${test_dep} ${test_target}']
		phony:        false
	}
	evaluator.eval_rule(rule)

	// Initially target should not exist
	assert !os.exists(test_target)

	// Build the target - should create it
	evaluator.build_target(test_target)!

	// Verify target was created
	assert os.exists(test_target)
	target_content := os.read_file(test_target)!
	assert target_content == 'dependency content'

	// Get timestamps
	target_mtime := os.file_last_mod_unix(test_target)
	dep_mtime := os.file_last_mod_unix(test_dep)

	// Target should be at least as new as dependency
	assert target_mtime >= dep_mtime

	// Build again - should be up-to-date and not rebuild
	// We'll capture the verbose output by setting verbose to true temporarily
	mut verbose_evaluator := vamk.new_evaluator(true, false)
	verbose_evaluator.rules[test_target] = rule
	verbose_evaluator.variables = evaluator.variables.clone()

	// This should not rebuild since target is up-to-date
	verbose_evaluator.build_target(test_target)!

	// Now delete the target and create a new dependency file to force rebuild
	os.rm(test_target)!
	os.write_file(test_dep2, 'newer dependency content')!

	// Create a new rule with the new dependency
	rule2 := vamk.Rule{
		target:       test_target
		dependencies: [test_dep2]
		recipes:      ['cp ${test_dep2} ${test_target}']
		phony:        false
	}
	verbose_evaluator.rules[test_target] = rule2

	// Build again - should rebuild because target doesn't exist
	verbose_evaluator.build_target(test_target)!

	// Verify target was updated
	updated_content := os.read_file(test_target)!
	assert updated_content == 'newer dependency content'

	// Test phony target always rebuilds
	phony_rule := vamk.Rule{
		target:       'phony_target'
		dependencies: [test_dep]
		recipes:      ['echo "phony built" > phony_output.txt']
		phony:        true
	}
	evaluator.eval_rule(phony_rule)

	// Mark as phony in the phony_targets list too
	evaluator.phony_targets << 'phony_target'

	// Phony targets should always rebuild
	verbose_evaluator.rules['phony_target'] = phony_rule
	verbose_evaluator.phony_targets = evaluator.phony_targets.clone()

	verbose_evaluator.build_target('phony_target')!

	// Clean up test files
	if os.exists(test_target) {
		os.rm(test_target)!
	}
	if os.exists(test_dep) {
		os.rm(test_dep)!
	}
	if os.exists(test_dep2) {
		os.rm(test_dep2)!
	}
	if os.exists('phony_output.txt') {
		os.rm('phony_output.txt')!
	}
}
