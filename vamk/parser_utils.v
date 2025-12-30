module vamk

fn (mut p Parser) next_token() {
	p.current_token = p.lexer.next_token()
}

fn (mut p Parser) peek() Token {
	return p.current_token
}

fn (mut p Parser) expect(kind TokenKind) Token {
	if p.current_token.kind != kind {
		panic('Expected ${kind}, got ${p.current_token.kind}')
	}
	token := p.current_token
	p.next_token()
	return token
}
