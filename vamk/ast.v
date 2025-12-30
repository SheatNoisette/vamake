module vamk

pub type ASTNode = Assignment | Comment | Conditional | Include | Rule | ShellCommand

pub enum ConditionalType {
	ifdef
	ifndef
	ifeq
	ifneq
}

pub struct Assignment {
pub:
	name        string
	value       string
	assign_type string
}

pub struct Rule {
pub:
	target       string
	dependencies []string
	recipes      []string
	phony        bool
}

pub struct Conditional {
pub:
	kind       ConditionalType // token_str_ifdef, token_str_ifndef, token_str_ifeq, token_str_ifneq
	condition  string
	then_nodes []ASTNode
	else_nodes []ASTNode
}

pub struct Include {
pub:
	file     string
	optional bool
}

pub struct ShellCommand {
pub:
	command string
}

pub struct Comment {
pub:
	text string
}
