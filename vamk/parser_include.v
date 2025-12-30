module vamk

fn (mut p Parser) parse_include(optional bool) Include {
	if p.current_token.kind == .ident {
		file := p.current_token.value
		p.next_token()
		return Include{
			file:     file
			optional: optional
		}
	} else {
		return Include{
			file:     ''
			optional: optional
		}
	}
}
