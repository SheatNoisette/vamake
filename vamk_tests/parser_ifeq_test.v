import vamk

fn test_parser_ifeq() {
	input := 'VARIABLE := 4
all:
ifeq ($(VARIABLE),0)
	@echo "KO"
else
	@echo "OK"
endif'
	mut parser := vamk.new_parser(input)
	nodes := parser.parse()

	assert nodes.len == 3
	assert nodes[0] is vamk.Assignment
	assert nodes[1] is vamk.Rule
	assert nodes[2] is vamk.Conditional

	cond := nodes[2] as vamk.Conditional
	assert cond.kind == vamk.ConditionalType.ifeq
	assert cond.condition == '($(VARIABLE),0)'
	assert cond.then_nodes.len == 1
	assert cond.else_nodes.len == 1
	then_node := cond.then_nodes[0]
	assert then_node is vamk.ShellCommand
	then_cmd := then_node as vamk.ShellCommand
	assert then_cmd.command == '@echo "KO"'
	else_node := cond.else_nodes[0]
	assert else_node is vamk.ShellCommand
	else_cmd := else_node as vamk.ShellCommand
	assert else_cmd.command == '@echo "OK"'
}
