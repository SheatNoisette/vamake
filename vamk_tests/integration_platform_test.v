import vamk

// This part is taken from the Makefile of Vlang because of one issue when
// compiling:
// clang: error: linker command failed with exit code 1 (use -v to see invocation)
fn test_integration_platform_detection() {
	// Test platform detection with shell command
	content := '
CC ?= cc
CFLAGS ?=
LDFLAGS ?=

# Platform detection
UNAME_S := Darwin

ifeq ($(UNAME_S),Darwin)
	MAC := 1
endif

ifeq ($(UNAME_S),FreeBSD)
	LDFLAGS += -lexecinfo
endif

ifeq ($(UNAME_S),NetBSD)
	LDFLAGS += -lexecinfo
endif

ifeq ($(UNAME_S),OpenBSD)
	LDFLAGS += -lexecinfo
endif

.PHONY: all compile

all: compile

compile:
	echo "CC=$(CC)"
	echo "CFLAGS=$(CFLAGS)"
	echo "LDFLAGS=$(LDFLAGS)"
	echo "UNAME_S=$(UNAME_S)"
'

	mut parser := vamk.new_parser(content)
	nodes := parser.parse()

	mut evaluator := vamk.new_evaluator(false, false)
	evaluator.eval(nodes)

	// Check that shell command was executed and UNAME_S is set
	assert 'UNAME_S' in evaluator.variables
	assert evaluator.variables['UNAME_S'].len > 0

	uname_s := evaluator.variables['UNAME_S']

	// On macOS, verify MAC variable is set
	if uname_s == 'Darwin' {
		assert 'MAC' in evaluator.variables
		assert evaluator.variables['MAC'] == '1'
	}

	// Check that LDFLAGS does NOT contain -lexecinfo on macOS or Linux
	if uname_s in ['Darwin', 'Linux'] {
		assert !evaluator.variables['LDFLAGS'].contains('-lexecinfo'), 'LDFLAGS should not contain -lexecinfo on ${uname_s}'
	}

	// On BSD systems, verify -lexecinfo is in LDFLAGS
	if uname_s in ['FreeBSD', 'NetBSD', 'OpenBSD'] {
		assert evaluator.variables['LDFLAGS'].contains('-lexecinfo'), 'LDFLAGS should contain -lexecinfo on ${uname_s}'
	}
}

fn test_integration_no_execinfo_on_macos() {
	// Test that -lexecinfo is not added on macOS
	content := '
CC ?= cc
CFLAGS ?=
LDFLAGS ?=

# Platform detection
UNAME_S := Darwin

ifeq ($(UNAME_S),Darwin)
	MAC := 1
endif

ifeq ($(UNAME_S),FreeBSD)
	LDFLAGS += -lexecinfo
endif

ifeq ($(UNAME_S),NetBSD)
	LDFLAGS += -lexecinfo
endif

ifeq ($(UNAME_S),OpenBSD)
	LDFLAGS += -lexecinfo
endif

.PHONY: compile

compile:
	$(CC) $(CFLAGS) -o test_prog test.c $(LDFLAGS)
'

	mut parser := vamk.new_parser(content)
	nodes := parser.parse()

	mut evaluator := vamk.new_evaluator(false, false)
	evaluator.eval(nodes)

	uname_s := evaluator.variables['UNAME_S']

	// Verify the compile recipe doesn't have hardcoded -lexecinfo
	compile_rule := evaluator.rules['compile']
	assert compile_rule.recipes.len > 0

	recipe := compile_rule.recipes[0]
	expanded := evaluator.expand_recipe_vars('compile', [], recipe)

	// On macOS, verify -lexecinfo is NOT in the expanded recipe
	if uname_s == 'Darwin' {
		assert !expanded.contains('-lexecinfo'), 'Recipe should not contain -lexecinfo on macOS: ${expanded}'
	}
}
