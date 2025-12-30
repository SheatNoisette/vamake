import vamk

fn test_evaluator_shell_commands() {
	mut evaluator := vamk.new_evaluator(false, false)

	result := evaluator.expand_vars('$(shell echo hello)')
	// This would actually execute shell command, but for testing we can check if it contains 'hello' :)
	assert result.contains('hello') || result == 'hello'
}

fn test_evaluator_shell_command_error() {
	mut evaluator := vamk.new_evaluator(false, false)

	// Test shell command that fails
	result := evaluator.eval_shell_commands('$(shell false)')

	// The command will fail but eval_shell_commands should handle it gracefully
	// os.execute returns empty output for failed commands
	assert result == ''
}
