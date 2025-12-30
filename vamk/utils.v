module vamk

import os

pub fn find_makefile() ?string {
	files := os.ls('.') or { return none }
	for file in files {
		lower := file.to_lower()
		if lower == 'makefile' || lower == 'gnumakefile' {
			return file
		}
	}
	return none
}

// Find the matching closing parenthesis for a $( starting at open_pos
fn (e Evaluator) find_matching_paren(s string, open_pos int) ?int {
	mut paren_count := 0
	for i := open_pos; i < s.len; i++ {
		match s[i] {
			`(` {
				paren_count++
			}
			`)` {
				paren_count--
				if paren_count == 0 {
					return i
				}
			}
			else {}
		}
	}
	return none
}
