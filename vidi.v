module vidi

pub type Callback = fn(buf []byte, timestamp f64, userdata voidptr)

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
    cfg      Config
}
