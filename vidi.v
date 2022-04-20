module vidi

pub type Callback = fn (buf []u8, timestamp f64, userdata voidptr)

pub struct Config {
pub mut:
	callback  Callback [required]
	user_data voidptr
	name      string
}

[noinit]
pub struct Context {
	ExtraContext
pub:
	cfg Config
}

struct PortInfo {
pub:
	idx          int
	name         string
	model        string
	manufacturer string
}
