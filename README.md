# vamake

vamake (V Atto Make) is a "minimal" `make` utility written in VLang.

> This program exists for the sole purpose of making a minimal OS distribution
> whose userland is composed exclusively of VLang programs. It is deliberately
> feature-incomplete: any missing convenience is intentional. See this as
> a friendly nudge toward a cleaner, better reimplementation. Bugs may be fixed
> and some basic features may (not) be added.

Few shortcuts was made, as the make syntax is surprisingly complex and ridded
with edge cases and weird post-processing steps. For reference, GNU make is
45K+ LoC and this implementation is less than 2K LoC and barely implement the
minimum to build complex makefiles.

The objective was to be able to build the vlang compiler using the provided
`Makefile` and if possible the `GNUMakefile`.

**BUILDING PROJECTS WITH THIS REIMPLEMENTATION IS DISCOURAGED !**

- Parses and executes BSD and GNU-ish makefiles
- Supports variables, rules, dependencies and recipes
- Pattern rules (e.g., `%.o: %.c`)
- Conditional directives (ifdef, ifndef, etc.)
- Include directive
- Basic Shell command execution with `$(shell ...)`, `$(filter ...)` and `$(patsubst ...)`
- Recursive variable expansion
- Phony targets with `.PHONY` directive

Current limitations:
- No built-in make functions except `$(shell ...)`, etc.
- Only simple `ifeq` and `ifdef` condition parsing is supported
- Dodgy conditional support
- Phony directive is a bit of a hack
- No export/unexport of variables
- No override modifier
- Basic variable expansion, simple replace-until-nothing-more-is-expanded
- Perfomance (Lot of string manipulation in parser/lexer)
- Bugs

## Building

Ensure you have [V installed](https://vlang.io/) on your system.

```bash
$ v -prod .
```

Or:
```bash
$ make
# Or if you built it once and like being meta:
$ ./vamake
```

## Usage

```
vamake [options] [target] [makefile]
```

### Options

- `-f, --makefile <FILE>`: Specify makefile path (auto-detected if not provided)
- `-C, --directory <DIR>`: Change to directory before reading makefile
- `-a, --ast`: Print AST and variables, then exit without building
- `-v, --verbose`: Enable verbose output
- `-n, --dry-run`: Print commands without executing them

### Examples

The CLI is similar to GNU Make, but REALLY simplified.

Build the default target (usually 'all'):
```bash
$ ./vamake
```

Build a specific target:
```bash
$ ./vamake clean
```

Use a specific makefile:
```bash
$ ./vamake -f mymakefile target
```

Print AST for debugging of makefile in the current directory:

```bash
$ ./vamake -a
```

## Tests

See [vamk_tests/README.md](vamk_tests/README.md) for an overview of the tests.

To run them:
```bash
$ make test
```

**NOTE**: The tests are not deterministic sadly, as testing a build system
without modifying file system is a bit difficult. Tests may fails on your
platform.

## License

MIT License, see `LICENSE` for more details.
