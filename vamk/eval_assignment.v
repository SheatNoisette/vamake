module vamk

pub fn (mut e Evaluator) eval_assignment(assign Assignment) {
	mut value := assign.value
	if assign.assign_type == token_str_colon_equals {
		value = e.expand_vars(assign.value)
	}

	match assign.assign_type {
		token_str_question_equals {
			if assign.name !in e.variables {
				e.variables[assign.name] = e.expand_vars(assign.value)
			}
		}
		token_str_plus_equals {
			expanded_val := e.expand_vars(assign.value)
			if assign.name in e.variables {
				e.variables[assign.name] += ' ' + expanded_val
			} else {
				e.variables[assign.name] = expanded_val
			}
		}
		token_str_equals {
			e.variables[assign.name] = value
		}
		token_str_colon_equals {
			e.variables[assign.name] = value
		}
		else {
			panic('Unknown assignment type: ${assign.assign_type}')
		}
	}
}
