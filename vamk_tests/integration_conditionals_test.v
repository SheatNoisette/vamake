import vamk

fn test_integration_simple_conditional_with_parens() {
	content := 'all:
	@echo "test"

VARIABLE := Darwin
ifeq ($(VARIABLE),Darwin)
MAC := 1
TCCOS := macos
else
MAC := 0
TCCOS := other
endif'

	mut parser := vamk.new_parser(content)
	nodes := parser.parse()

	assert nodes[2] is vamk.Conditional
	cond := nodes[2] as vamk.Conditional
	println('Condition: "${cond.condition}"')
	println('Then nodes: ${cond.then_nodes.len}')
	println('Else nodes: ${cond.else_nodes.len}')

	mut evaluator := vamk.new_evaluator(false, false)
	evaluator.eval(nodes)

	println('Variables after eval: ${evaluator.variables}')
	assert evaluator.variables['MAC'] == '1'
	assert evaluator.variables['TCCOS'] == 'macos'
}
