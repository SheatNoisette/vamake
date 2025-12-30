module main

import vamk
import os
import v.vmod
import flag

fn main() {
	vm := vmod.decode(@VMOD_FILE) or { panic(err) }
	mut fp := flag.new_flag_parser(os.args)
	fp.version('v${vm.version}')
	fp.application('${vm.name}')
	fp.description('(c) SheatNoisette 2025 - Licensed under MIT license - ${vm.description}')
	fp.skip_executable()

	makefile_flag := fp.string('makefile', `f`, '', 'path to makefile (optional, auto-detected if not specified)')
	verbose_flag := fp.bool('verbose', `v`, false, 'enable verbose output')
	dry_run_flag := fp.bool('dry-run', `n`, false, 'print commands without executing them')
	directory_flag := fp.string('directory', `C`, '', 'change to directory before reading makefile')
	ast_flag := fp.bool('ast', `a`, false, 'print AST and exit without building')

	fp.finalize() or {
		eprintln(err)
		eprintln(fp.usage())
		exit(1)
	}

	// Change directory if -C flag is provided
	if directory_flag != '' {
		os.chdir(directory_flag) or {
			eprintln('Error changing to directory "${directory_flag}": ${err}')
			exit(1)
		}
	}

	// Get positional arguments
	args := fp.remaining_parameters()

	target := if args.len > 0 { args[0] } else { 'all' }
	makefile_path := if makefile_flag != '' {
		makefile_flag
	} else if args.len > 1 {
		args[1]
	} else {
		vamk.find_makefile() or {
			eprintln('No makefile found in current directory')
			exit(1)
		}
	}

	content := os.read_file(makefile_path) or {
		eprintln('Error reading ${makefile_path}: ${err}')
		exit(1)
	}

	mut parser := vamk.new_parser(content)
	nodes := parser.parse()

	mut evaluator := vamk.new_evaluator(verbose_flag, dry_run_flag)
	evaluator.eval(nodes)

	// If AST flag is set, exit here without building
	if ast_flag {
		println('Variables:')
		for key, value in evaluator.variables {
			println('  ${key} = ${value}')
		}
		vamk.pretty_print(nodes)
		return
	}

	// Build target
	evaluator.build_target(target) or {
		eprintln('${err}')
		exit(1)
	}
}
