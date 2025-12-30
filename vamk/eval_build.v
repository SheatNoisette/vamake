module vamk

import os

fn (e Evaluator) target_needs_rebuild(target string, rule Rule) bool {
	// Phony targets always need rebuilding
	if rule.phony {
		return true
	}

	// If target file doesn't exist, it needs building, duh
	if !os.exists(target) {
		return true
	}

	target_mtime := os.file_last_mod_unix(target)

	// Check if any dependency is newer than the target
	for dep in rule.dependencies {
		// If dependency doesn't exist as a file, check if it has a rule
		// Dependencies without files but with rules need to be built first
		if !os.exists(dep) {
			if dep in e.rules || e.find_pattern_rule(dep) != none {
				// Dependency has a rule but no file yet, so target needs rebuilding
				return true
			}
			// Dependency doesn't exist and has no rule - this is an error case
			// but we'll let build_target handle it
			continue
		}

		// Dependency exists, check its modification time
		dep_mtime := os.file_last_mod_unix(dep)
		if dep_mtime > target_mtime {
			return true
		}
	}

	// Up to date !
	return false
}

pub fn (mut e Evaluator) build_target(target string) ! {
	mut rule := Rule{}

	if target in e.rules {
		rule = e.rules[target]
	} else if pattern_rule := e.find_pattern_rule(target) {
		rule = e.expand_pattern_rule(pattern_rule, target)
		// Cache the expanded rule because we may use it later
		e.rules[target] = rule
	} else {
		return error('No rule to make target: ${target}')
	}

	// Dependencies first
	for dep in rule.dependencies {
		if dep in e.rules || e.find_pattern_rule(dep) != none {
			e.build_target(dep)!
		}
	}

	// Check if target needs rebuilding
	if !e.target_needs_rebuild(target, rule) {
		if e.verbose {
			println('=> Target ${target} is up-to-date')
		}
		return
	}

	// Build now
	if e.verbose {
		println('=> Building target: ${target}')
	}

	for recipe in rule.recipes {
		expanded := e.expand_recipe_vars(rule.target, rule.dependencies, recipe)

		clean_cmd, silent, ignore_errors, force_run := e.parse_recipe_prefixes(expanded)

		if e.dry_run || !silent {
			println(clean_cmd)
			os.flush()
		}

		// Skip execution if dry run and not forced
		if e.dry_run && !force_run {
			continue
		}

		// @TODO: Make a compile flag macro to enable shell or not
		// Execute through shell to support shell operators like ||, &&, etc
		// Use single quotes for the shell command to avoid conflicts with
		// double quotes in the recipe and break the intent!
		shell_cmd := '/bin/sh -c \'${clean_cmd}\''
		if e.verbose {
			eprintln("Executing: \"${shell_cmd}\"")
		}

		exit_code := os.system(shell_cmd)

		if exit_code != 0 && !ignore_errors {
			eprintln('Error executing: ${clean_cmd}')
			return error('Command failed: ${clean_cmd}')
		}
	}
}

// Parse recipe prefixes and return cleaned command with flags
fn (e Evaluator) parse_recipe_prefixes(recipe string) (string, bool, bool, bool) {
	mut clean_recipe := recipe
	mut silent := false
	mut ignore_errors := false
	mut force_run := false

	// Check for prefixes in any order (though typically only one is used? Maybe?)
	for clean_recipe.len > 0
		&& (clean_recipe[0] == `@` || clean_recipe[0] == `-` || clean_recipe[0] == `+`) {
		match clean_recipe[0] {
			`@` { silent = true }
			`-` { ignore_errors = true }
			`+` { force_run = true }
			else {}
		}
		clean_recipe = clean_recipe[1..]
	}

	return clean_recipe, silent, ignore_errors, force_run
}
