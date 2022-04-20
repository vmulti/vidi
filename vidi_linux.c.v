module vidi

pub fn port_count() int {
	return 0
}

pub fn input_count() int {
	return 0
}

pub fn output_count() int {
	return 0
}

pub fn port_info(port int) PortInfo {
	return PortInfo{}
}

// Extra `Context` data; contains fields that are specific to one implementation
struct ExtraContext {
}

pub fn new_ctx(cfg Config) ?&Context {
	mut c := &Context{
		cfg: cfg
	}
	return c
}

pub fn (mut c Context) open(idx int) ? {
	return error('unimplemented')
}

pub fn (mut c Context) close() ? {
	// TODO
	return error('unimplemented')
}
