module vidi

#include <CoreAudio/HostTime.h>
#include <CoreMIDI/MIDIServices.h>
#include <CoreFoundation/CFRunLoop.h>
#flag -framework CoreAudio -framework CoreMIDI -framework CoreFoundation

[typedef]
struct C.MIDIPacket {
	timeStamp u64
	length    u16
	data      [256]byte
}

[typedef]
struct C.MIDIPacketList {
	numPackets u32
	packet     &C.MIDIPacket
}

fn C.AudioGetCurrentHostTime() u64

fn C.MIDIGetNumberOfDevices() u32
fn C.MIDIGetNumberOfSources() u32
fn C.MIDIGetNumberOfDestinations() u32

fn C.MIDIGetDevice(u32) u32
fn C.MIDIGetSource(u32) u32
fn C.MIDIGetDestination(u32) u32

fn C.MIDIClientCreate(voidptr, voidptr, voidptr, &u32) int
fn C.MIDIInputPortCreate(u32, voidptr, voidptr, voidptr, &u32) int
fn C.MIDIPortConnectSource(u32, u32, voidptr) int

fn C.MIDIPacketNext(&C.MIDIPacket) &C.MIDIPacket

fn C.MIDIObjectGetStringProperty(u32, voidptr, &voidptr) int
fn C.CFStringGetCString(voidptr, charptr, int, u32)
fn C.CFRelease(voidptr)
fn C.CFSTR(charptr) voidptr
fn C.CFStringCreateWithCString(voidptr, charptr, u32) voidptr

pub fn port_count() int {
	return int(C.MIDIGetNumberOfDevices())
}

pub fn input_count() int {
	return int(C.MIDIGetNumberOfSources())
}

pub fn output_count() int {
	return int(C.MIDIGetNumberOfDestinations())
}

struct PortInfo {
	idx          int
	name         string
	model        string
	manufacturer string
}

pub fn port_info(port int) PortInfo {
	dev := C.MIDIGetDevice(port)

	mut pname := voidptr(0)
	mut pmanuf := voidptr(0)
	mut pmodel := voidptr(0)

	mut name := [128]byte{}
	mut manuf := [128]byte{}
	mut model := [128]byte{}

	C.MIDIObjectGetStringProperty(dev, C.kMIDIPropertyName, &pname)
	C.MIDIObjectGetStringProperty(dev, C.kMIDIPropertyManufacturer, &pmanuf)
	C.MIDIObjectGetStringProperty(dev, C.kMIDIPropertyModel, &pmodel)

	C.CFStringGetCString(pname, charptr(name), sizeof(name), 0)
	C.CFStringGetCString(pmanuf, charptr(manuf), sizeof(manuf), 0)
	C.CFStringGetCString(pmodel, charptr(model), sizeof(model), 0)
	C.CFRelease(pname)
	C.CFRelease(pmanuf)
	C.CFRelease(pmodel)

	return PortInfo {
		idx: port
		name: tos_clone(byteptr(name))
		model: tos_clone(byteptr(model))
		manufacturer: tos_clone(byteptr(manuf))
	}
}

// Extra `Context` data; contains fields that are specific to one implementation
struct ExtraContext {
mut:
	client   u32
	in_port  u32
	out_port u32
	start    f64
}

fn callback_wrapper(packets &C.MIDIPacketList, c &Context, something_else voidptr) {
	if c == 0 { return }
	mut packet := packets.packet
	for _ in 0 .. packets.numPackets {
		mut buf := []byte{ len: int(packet.length) }
		unsafe { C.memcpy(buf.data, packet.data, packet.length) }
		timestamp := (f64(packet.timeStamp) - c.start) / 1e6 // in milliseconds

		// fix double packets being captured as just one
		// TODO: this is ugly and probably super buggy; figure out what's wrong instead
		for buf.len > 3 && buf[0] != 0xF0 {
			c.cfg.callback(buf[..3], timestamp, c.cfg.user_data)
			buf = buf[3..]
		}

		c.cfg.callback(buf, timestamp, c.cfg.user_data)

		packet = C.MIDIPacketNext(packet)
	}
}

pub fn new_ctx(cfg Config) ?&Context {
	mut c := &Context{ cfg: cfg }
	c.start = f64(C.AudioGetCurrentHostTime())
	if C.MIDIClientCreate(C.CFStringCreateWithCString(0, c.cfg.name.str, 0), 0, 0, &c.client) != C.noErr {
		return error('failed to create client')
	}
	return c
}

pub fn (mut c Context) open(idx int) ? {
	if c.callback == voidptr(0) {
		return error('callback is unset')
	}
	if c.in_port == 0 {
		if C.MIDIInputPortCreate(c.client, C.CFStringCreateWithCString(0, c.cfg.name.str, 0), callback_wrapper, c, &c.in_port) != C.noErr {
			return error('failed to open port $idx')
		}
	}
	src := C.MIDIGetSource(idx)
	if C.MIDIPortConnectSource(c.in_port, src, 0) != C.noErr {
		return error('failed to open port $idx')
	}
}

pub fn (mut c Context) close() ? {
	// TODO
}