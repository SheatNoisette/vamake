module vamk

import os

pub fn (mut e Evaluator) eval_include(include Include) {
	file := e.expand_vars(include.file)
	content := os.read_file(file) or {
		if include.optional {
			return
		} else {
			panic('Error reading include file ${file}: ${err}')
		}
	}

	mut sub_parser := new_parser(content)
	sub_nodes := sub_parser.parse()
	e.eval(sub_nodes)
}
