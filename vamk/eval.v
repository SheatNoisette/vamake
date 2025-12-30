module vamk

pub fn new_evaluator(verbose bool, dry_run bool) Evaluator {
	// @TODO: Replace verbose + dryrun by a struct ?
	return Evaluator{
		variables:     map[string]string{}
		rules:         map[string]Rule{}
		pattern_rules: []Rule{}
		phony_targets: []string{}
		verbose:       verbose
		dry_run:       dry_run
	}
}
