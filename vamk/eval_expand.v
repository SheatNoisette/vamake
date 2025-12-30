module vamk

// -----------------------------------------------------------------------------
// @TODO ! WARNING!
// @SheatNoisette: This is not a good way to handle this, you may need to do a
// post-parse expansion to handle the recursive expansion proprely.
// A LOT OF THINGS ARE HARDCODED FOR THE PARSING, THIS IS A TERRIBLE WAY TO
// HANDLE THIS ! DUPLICATE CODE BEWARE !
// -----------------------------------------------------------------------------

pub fn (mut e Evaluator) expand_vars(text string) string {
	mut result := text

	// Keep expanding stuff until no more changes
	for {
		old_result := result

		// Handle $(shell ...) commands
		if result.contains('$(shell') {
			result = e.eval_shell_commands(result)
		}

		// Handle substitution references $(VAR:old=new)
		result = e.expand_substitution_refs(result)

		// Handle patsubst $(patsubst pattern,replacement,text)
		result = e.expand_patsubst(result)

		// Handle filter $(filter pattern,text)
		result = e.expand_filter(result)

		// Handle variable references
		// HACK: Sort keys by length descending to avoid some collision issues
		mut keys := []string{}
		for key, _ in e.variables {
			keys << key
		}
		keys.sort_with_compare(fn (a &string, b &string) int {
			if a.len > b.len {
				return -1
			} else if a.len < b.len {
				return 1
			}
			return 0
		})

		for key in keys {
			value := e.variables[key]
			result = result.replace('\$(${key})', value)
			result = result.replace('\$\{${key}\}', value)
			result = result.replace('\$${key}', value)
		}

		// @TODO: Poor performance, but If no changes, we're done!
		if result == old_result {
			break
		}
	}

	return result
}

pub fn (mut e Evaluator) expand_recipe_vars(target string, prereqs []string, recipe string) string {
	mut result := recipe

	// Expand automatic variables
	result = result.replace('$@', target)
	if prereqs.len > 0 {
		result = result.replace('$<', prereqs[0])
		result = result.replace('$^', prereqs.join(' '))
		// For $?, we need timestamp checking for now, use all prereqs
		result = result.replace('$?', prereqs.join(' '))
	}

	// Extract stem for $*
	stem := e.extract_stem_from_target(target)
	result = result.replace('$*', stem)

	// Then expand user variables
	return e.expand_vars(result)
}

// Expand substitution references like $(VAR:old=new)
fn (e Evaluator) expand_substitution_refs(text string) string {
	mut result := text
	mut i := 0

	for i < result.len {
		// Look for $(VAR:old=new) pattern
		// @TODO: AVOID HARDCODING LIKE THIS!
		if i + 2 < result.len && result[i..i + 2] == '$(' {
			start := i
			end := e.find_matching_paren(result, i + 1) or {
				i++
				continue
			}

			content := result[start + 2..end]
			colon_pos := content.index(':') or {
				i = end + 1
				continue
			}

			var_name := content[..colon_pos]
			subst_part := content[colon_pos + 1..]

			equals_pos := subst_part.index(token_str_equals) or {
				i = end + 1
				continue
			}

			old_pattern := subst_part[..equals_pos]
			new_pattern := subst_part[equals_pos + 1..]

			// Get the variable value (undefined variables expand to empty string)
			var_value := if var_name in e.variables {
				e.variables[var_name]
			} else {
				''
			}

			// Perform substitution
			replaced_value := var_value.replace(old_pattern, new_pattern)

			// Replace in result
			result = result[..start] + replaced_value + result[end + 1..]
			i = start + replaced_value.len
		} else {
			i++
		}
	}

	return result
}

fn (mut e Evaluator) expand_patsubst(text string) string {
	mut result := text
	mut i := 0

	for i < result.len {
		// Look for $(patsubst ...) pattern
		if i + 11 < result.len && result[i..i + 11] == '$(patsubst ' {
			start := i
			end := e.find_matching_paren(result, i + 1) or {
				i++
				continue
			}

			content := result[start + 2..end] // remove $( and )
			args_str := content[9..] // remove 'patsubst '

			// Split by commas, but handle nested functions? For now, simple split
			args := args_str.split(',')
			if args.len != 3 {
				i = end + 1
				continue
			}

			pattern := args[0].trim_space()
			replacement := args[1].trim_space()
			text_arg := args[2].trim_space()

			// Expand the text argument (it may contain variables)
			expanded_text := e.expand_vars(text_arg)

			// Perform patsubst
			words := expanded_text.split(' ')
			mut new_words := []string{}
			for word in words {
				trimmed := word.trim_space()
				if trimmed == '' {
					continue
				}
				if e.matches_patsubst_pattern(pattern, trimmed) {
					stem := e.extract_patsubst_stem(pattern, trimmed)
					replaced := replacement.replace('%', stem)
					new_words << replaced
				} else {
					new_words << trimmed
				}
			}
			replaced_value := new_words.join(' ')

			// Replace in result
			result = result[..start] + replaced_value + result[end + 1..]
			i = start + replaced_value.len
		} else {
			i++
		}
	}

	return result
}

fn (mut e Evaluator) expand_filter(text string) string {
	mut result := text
	mut i := 0

	for i < result.len {
		// Look for $(filter ...) pattern
		if i + 9 < result.len && result[i..i + 9] == '$(filter ' {
			start := i
			end := e.find_matching_paren(result, i + 1) or {
				i++
				continue
			}

			content := result[start + 2..end] // remove $( and )
			args_str := content[7..] // remove 'filter '

			args := args_str.split(',')
			if args.len != 2 {
				i = end + 1
				continue
			}

			pattern := args[0].trim_space()
			text_arg := args[1].trim_space()

			// Expand the text argument
			expanded_text := e.expand_vars(text_arg)

			// @TODO: Refactor this into function!
			// Perform filter itself
			words := expanded_text.split(' ')
			mut filtered_words := []string{}
			for word in words {
				trimmed := word.trim_space()
				if trimmed == '' {
					continue
				}
				if e.matches_patsubst_pattern(pattern, trimmed) { // reuse the function
					filtered_words << trimmed
				}
			}
			replaced_value := filtered_words.join(' ')

			// Replace in result
			result = result[..start] + replaced_value + result[end + 1..]
			i = start + replaced_value.len
		} else {
			i++
		}
	}

	return result
}

pub fn (e Evaluator) expand_pattern_rule(pattern_rule Rule, target string) Rule {
	stem := e.extract_stem(pattern_rule.target, target)

	mut expanded_deps := []string{}
	for dep in pattern_rule.dependencies {
		expanded_dep := dep.replace('%', stem)
		expanded_deps << expanded_dep
	}

	mut expanded_recipes := []string{}
	for recipe in pattern_rule.recipes {
		expanded_recipe := recipe.replace('%', stem)
		expanded_recipes << expanded_recipe
	}

	return Rule{
		target:       target
		dependencies: expanded_deps
		recipes:      expanded_recipes
		phony:        pattern_rule.phony || target in e.phony_targets
	}
}

fn (e Evaluator) extract_stem_from_target(target string) string {
	// For pattern rules, the stem is the part that matched %
	// Since we expand patterns before building, we need to find if
	// this target was built from a pattern
	for pattern_rule in e.pattern_rules {
		if e.matches_pattern(pattern_rule.target, target) {
			return e.extract_stem(pattern_rule.target, target)
		}
	}
	return ''
}

pub fn (e Evaluator) extract_stem(pattern string, target string) string {
	parts := pattern.split('%')
	prefix := parts[0]
	suffix := parts[1]

	stem_start := prefix.len
	stem_end := target.len - suffix.len

	return target[stem_start..stem_end]
}

fn (e Evaluator) matches_patsubst_pattern(pattern string, word string) bool {
	if !pattern.contains('%') {
		return word == pattern
	}

	parts := pattern.split('%')
	if parts.len != 2 {
		return false
	}

	prefix := parts[0]
	suffix := parts[1]

	if !word.starts_with(prefix) {
		return false
	}
	if !word.ends_with(suffix) {
		return false
	}

	stem_len := word.len - prefix.len - suffix.len
	return stem_len >= 0
}

fn (e Evaluator) extract_patsubst_stem(pattern string, word string) string {
	parts := pattern.split('%')
	prefix := parts[0]
	suffix := parts[1]

	stem_start := prefix.len
	stem_end := word.len - suffix.len
	return word[stem_start..stem_end]
}
