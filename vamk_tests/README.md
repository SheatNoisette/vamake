# Vamake tests

In this folder, you will find every tests written for the lexer/parser/evaluator
and more. Sadly, the V compiler is not flexible enough to put tests everywhere
you want.

So, a lot of vamake functions are marked as pub just to make them available for
external tests to use them.

A lot of tests were written to cover as much as possible of the parser and
evaluator. It is **really, really, really easy** to break some unrelated part
of the parser by adding a feature or moving functions around. The parser was
rewritten at least two times just because of unplanned corner-cases of the GNU
Make syntax, like ifeq inside recipe in the Vlang compiler
GNUMakefile for example.

**You have been warned.**

## Test Description

There's all of the tests used to well, test vamake:
- eval*.v : Evaluator tests
- lexer*.v : Lexer tests
- parser*.v : Parser tests

The list of the tests are the following:

### Evaluator

- eval_assignment_test.v: assignment operators (=, +=, ?=, :=)
- eval_conditional_test.v: conditionals within recipe blocks to prevent them from being executed as shell commands
- eval_expansion_test.v: recursive vs simple variable expansion behavior
- eval_ifdef_test.v: evaluation of ifdef and ifndef conditional
- eval_ifeq_test.v: evaluation of ifeq and ifneq conditional directives with variable comparisons
- eval_includes_test.v: evaluation of include directives, including handling missing optional files
- eval_rules_test.v: evaluating rules with variable references in targets and dependencies
- eval_shell_test.v: shell command execution and expansion using $(shell ...) syntax
- eval_timestamp_test.v: timestamp-based rebuild logic and phony target handling
- eval_variables_test.v: expansion of automatic variables like $@, $<, $^, and $?, as well as variable collision handling
- evaluator_test.v: evaluating AST nodes, storing rules, expanding variables, and handling pattern rules

### Integration (Tests on real makefiles)

/!\ THESE TESTS MAY FAIL ON SOME SYSTEM AS THEY INTERACT WITH THE FS !

- integration_conditionals_test.v: integration of conditional directives in real makefile scenarios
- integration_ifeq_test.v: ifeq conditionals with variable expansion in makefiles
- integration_platform_test.v: integration of platform-specific makefile features!
- integration_realproject_test.v: integration tests on a real project with include and conditional logic. **THIS TEST IS DISABLED FOR NOW AS THIS CRASH THE CODE GENERATION FOR SOME REASON!**
- integration_test.v: and evaluating real makefiles from the tests/ directory

### Lexer

- lexer_test.v: the lexer functionality for tokenizing makefile syntax into tokens like identifiers, colons, strings, ...

### Parser

- parser_assignement_test.v: various assignment types including =, +=, ?=, and := operators
- parser_conditionals_test.v: conditional directives like ifdef, ifndef, ifeq, etc
- parser_edges_case_test.v: Edge cases and malformed syntax
- parser_ifeq_test.v: ifeq and ifneq conditional directives with argument parsing
- parser_includes_test.v: include and -include directives
- parser_rules_test.v: makefile rules, including malformed cases
- parser_test.v: Tokens into AST nodes including rules, assignments and comments
- utils_test.v: Utility functions, other
