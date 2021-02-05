module vidi

#flag -DWIN32_FULL
#flag -lwinmm

fn C.midiInGetNumDevs() u32
fn C.midiOutGetNumDevs() u32
fn C.midiInOpen(&voidptr, int, voidptr, voidptr, int) u32
fn C.midiInStart(voidptr) u32
fn C.midiInStop(voidptr) u32
fn C.midiInClose(voidptr) u32

struct ExtraContext {
mut:
	handle voidptr
}

pub fn input_count() int {
	return int(C.midiInGetNumDevs())
}

pub fn output_count() int {
	return int(C.midiOutGetNumDevs())
}

pub fn port_count() int {
	return input_count() + output_count()
}

pub fn port_info(port int) PortInfo {
	return PortInfo{}
}

pub fn new_ctx(cfg Config) ?&Context {
	return &Context {
		cfg: cfg
	}
}

[windows_stdcall]
fn callback_wrapper(handle voidptr, message_type int, ctx &Context, param1 voidptr, param2 voidptr) {
	match int(message_type) {
		C.MIM_DATA {
			message, timestamp := int(param1), f64(u32(param2))
			mut data := []byte{}

			for shift in 0..4 {
				data << byte(message >> (8 * shift))
			}

			ctx.cfg.callback(data, timestamp, ctx.cfg.user_data)
		}
		else {}
	}
}

pub fn (mut ctx Context) open(id int) ? {
	handle_err( C.midiInOpen(&ctx.handle, id, callback_wrapper, ctx, C.CALLBACK_FUNCTION) )?
	handle_err( C.midiInStart(ctx.handle) )?
}

pub fn (mut ctx Context) close() ? {
	handle_err( C.midiInStop(ctx.handle) )?
	handle_err( C.midiInClose(ctx.handle) )?
}

fn handle_err(err u32) ? {
	match int(err) {
		C.MMSYSERR_ALLOCATED { return error("the specified resource is already allocated") }
		C.MMSYSERR_BADDEVICEID { return error("the specified device is out of range") }
		C.MMSYSERR_INVALFLAG { return error("the specified flags are invalid") }
		C.MMSYSERR_INVALPARAM { return error("the specified pointer or structure is invalid") }
		C.MMSYSERR_NOMEM { return error("the specified device is in use") }
		C.MMSYSERR_INVALHANDLE { return error("the midi context is invalid") }
		C.MIDIERR_STILLPLAYING { return error("buffers are still in the queue") }
		else {}
	}
}
