import vamk

fn test_integration_ifeq_makefile() {
	content := 'VARIABLE := 4

all:
ifeq ($(VARIABLE),0)
	@echo "KO"
else
	@echo "OK"
endif'

	mut parser := vamk.new_parser(content)
	nodes := parser.parse()

	mut evaluator := vamk.new_evaluator(false, false)
	evaluator.eval(nodes)

	assert evaluator.variables['VARIABLE'] == '4'
	assert 'all' in evaluator.rules
	// The recipe from the conditional should be added to all rule
	// Since VARIABLE=4 != 0, the else branch is taken
	assert evaluator.rules['all'].recipes.len >= 1
	assert evaluator.rules['all'].recipes[0] == '@echo "OK"'
}

fn test_integration_ifeq_with_variable_expansion() {
	content := 'VAR1 := hello
VAR2 := world

ifeq ($(VAR1),$(VAR2))
RESULT = different
else
RESULT = same
endif'

	mut parser := vamk.new_parser(content)
	nodes := parser.parse()

	mut evaluator := vamk.new_evaluator(false, false)
	evaluator.eval(nodes)

	// VAR1=hello, VAR2=world, they are not equal -> else branch is taken
	assert evaluator.variables['RESULT'] == 'same'
}

fn test_integration_ifeq_colon_parens() {
	content := 'ifeq ($(VARIABLE),0)
CFLAGS = -O0
else
CFLAGS = -O2
endif'

	mut parser := vamk.new_parser(content)
	nodes := parser.parse()

	mut evaluator := vamk.new_evaluator(false, false)
	evaluator.variables['VARIABLE'] = '0'
	evaluator.eval(nodes)

	assert evaluator.variables['CFLAGS'] == '-O0'
}

fn test_integration_deeply_nested_conditionals() {
	// Test deeply nested conditionals with else ifeq patterns
	// Copied from vlang makefile
	content := 'ARCH := arm64

ifeq ($(ARCH),x86_64)
	RESULT := amd64
else
ifneq ($(filter x86%,$(ARCH)),)
	RESULT := i386
else
ifeq ($(ARCH),arm64)
	RESULT := arm64
else
ifneq ($(filter arm%,$(ARCH)),)
	RESULT := arm
else
	RESULT := unknown
endif
endif
endif
endif'

	mut parser := vamk.new_parser(content)
	nodes := parser.parse()

	mut evaluator := vamk.new_evaluator(false, false)
	evaluator.eval(nodes)

	// ARCH=arm64 should match the third condition and set RESULT=arm64
	assert evaluator.variables['ARCH'] == 'arm64'
	assert evaluator.variables['RESULT'] == 'arm64'
}

fn test_integration_deeply_nested_with_recipes() {
	// Test deeply nested conditionals within a rule's recipe block, had few
	// issues to make this working
	content := 'VARIABLE := production

all:
ifeq ($(VARIABLE),development)
	@echo "Development build"
else
ifeq ($(VARIABLE),staging)
	@echo "Staging build"
else
ifeq ($(VARIABLE),production)
	@echo "Production build"
else
	@echo "Unknown build"
endif
endif
endif'

	mut parser := vamk.new_parser(content)
	nodes := parser.parse()

	mut evaluator := vamk.new_evaluator(false, false)
	evaluator.eval(nodes)

	assert evaluator.variables['VARIABLE'] == 'production'
	assert 'all' in evaluator.rules
	assert evaluator.rules['all'].recipes.len >= 1
	// Since VARIABLE=production, the third nested ifeq should match
	assert '@echo "Production build"' in evaluator.rules['all'].recipes
}
