module vamk

pub fn (e Evaluator) matches_pattern(pattern string, target string) bool {
	if !pattern.contains('%') {
		return false
	}

	// Simple pattern matching: split by % and check if target starts/ends with the parts
	parts := pattern.split('%')
	if parts.len != 2 {
		return false
	}

	prefix := parts[0]
	suffix := parts[1]

	if prefix.len > 0 && !target.starts_with(prefix) {
		return false
	}
	if suffix.len > 0 && !target.ends_with(suffix) {
		return false
	}

	// Check that the stem is non-empty if both prefix and suffix exist
	stem_start := prefix.len
	stem_end := target.len - suffix.len
	if stem_start >= stem_end {
		return false
	}

	return true
}

pub fn (e Evaluator) find_pattern_rule(target string) ?Rule {
	for pattern_rule in e.pattern_rules {
		if e.matches_pattern(pattern_rule.target, target) {
			return pattern_rule
		}
	}
	return none
}
