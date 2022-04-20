module vidi

import os

// Copyright @henrixounez: https://github.com/Henrixounez/v-midi
pub fn parse_file(filename string) ?Midi {
	file := os.read_file(filename) or { return none }
	mut midi := read_chunks(file.bytes()) or { return none }
	midi.time_division()
	for i in 0 .. midi.tracks.len {
		midi.tracks[i].nb = i
	}
	return midi
}

pub struct NoteOff {
pub:
	delta_time u64
	channel    u8
	note       u8
	velocity   u8
}

pub struct NoteOn {
pub:
	delta_time u64
	channel    u8
	note       u8
	velocity   u8
}

pub struct NoteAftertouch {
pub:
	delta_time u64
	channel    u8
	note       u8
	amount     u8
}

pub struct Controller {
pub:
	delta_time      u64
	channel         u8
	controller_type u8
	value           u8
}

pub struct ProgramChange {
pub:
	delta_time     u64
	channel        u8
	program_number u8
}

pub struct ChannelAftertouch {
pub:
	delta_time u64
	channel    u8
	amount     u8
}

pub struct PitchBend {
pub:
	delta_time u64
	channel    u8
	lsb        u8
	msb        u8
}

fn read_midi_event(file []u8, mut index_track &int, delta_time u64, mut last_status &u8) ?TrkData {
	mut index := *index_track
	use_curr_status := u8(file[index] & 0xf0) >> 4 >= 0x08
	status_byte := if use_curr_status { file[index] } else { *last_status }

	event_type := u8(status_byte & 0xf0) >> 4
	midi_channel := u8(status_byte & 0x0f)
	if use_curr_status {
		unsafe {
			*last_status = file[index]
		}
		index++
	}
	mut event := TrkData(Marker{})
	match event_type {
		0x08 {
			event = NoteOff{
				delta_time: delta_time
				channel: midi_channel
				note: file[index]
				velocity: file[index + 1]
			}
		}
		0x09 {
			event = NoteOn{
				delta_time: delta_time
				channel: midi_channel
				note: file[index]
				velocity: file[index + 1]
			}
		}
		0x0a {
			event = NoteAftertouch{
				delta_time: delta_time
				channel: midi_channel
				note: file[index]
				amount: file[index + 1]
			}
		}
		0x0b {
			event = Controller{
				delta_time: delta_time
				channel: midi_channel
				controller_type: file[index]
				value: file[index + 1]
			}
		}
		0x0c {
			event = ProgramChange{
				delta_time: delta_time
				channel: midi_channel
				program_number: file[index]
			}
		}
		0x0d {
			event = ChannelAftertouch{
				delta_time: delta_time
				channel: midi_channel
				amount: file[index]
			}
		}
		0x0e {
			event = PitchBend{
				delta_time: delta_time
				channel: midi_channel
				lsb: file[index]
				msb: file[index + 1]
			}
		}
		else {
			return none
		}
	}
	index++
	if event_type != 0x0c && event_type != 0x0d {
		index++
	}
	unsafe {
		*index_track = index
	}
	return event
}

pub struct SequenceNumber {
pub:
	delta_time u64
	msb        u8
	lsb        u8
}

pub struct TextEvent {
pub:
	delta_time u64
	text       string
}

pub struct CopyrightNotice {
pub:
	delta_time u64
	text       string
}

pub struct TrackName {
pub:
	delta_time u64
	text       string
}

pub struct InstrumentName {
pub:
	delta_time u64
	text       string
}

pub struct Lyrics {
pub:
	delta_time u64
	text       string
}

pub struct Marker {
pub:
	delta_time u64
	text       string
}

pub struct CuePoint {
pub:
	delta_time u64
	text       string
}

pub struct DeviceName {
pub:
	delta_time u64
	text       string
}

pub struct MidiChannelPrefix {
pub:
	delta_time u64
	channel    u8
}

pub struct EndOfTrack {
pub:
	delta_time u64
}

pub struct SetTempo {
pub:
	delta_time   u64
	microseconds int
}

pub struct SMPTEOffset {
pub:
	delta_time u64
	hour       u8
	min        u8
	sec        u8
	fr         u8
	subfr      u8
}

pub struct TimeSignature {
pub:
	delta_time u64
	numer      u8
	denom      u8
	metro      u8
	nds        u8
}

pub struct KeySignature {
pub:
	delta_time u64
	key        u8
	scale      u8
}

pub struct SequencerSpecific {
pub:
	delta_time u64
	data       []u8
}

fn read_meta(file []u8, mut index_track &int, delta_time u64) ?TrkData {
	mut index := *index_track + 1

	meta_type := file[index]
	index++
	length := get_variable_length_value(file, mut &index)
	data := file[index..index + int(length)].clone()
	index += int(length)
	mut meta := TrkData(Marker{})
	match meta_type {
		0x00 {
			meta = SequenceNumber{
				delta_time: delta_time
				msb: data[0]
				lsb: data[1]
			}
		}
		0x01 {
			meta = TextEvent{
				delta_time: delta_time
				text: data.bytestr()
			}
		}
		0x02 {
			meta = CopyrightNotice{
				delta_time: delta_time
				text: data.bytestr()
			}
		}
		0x03 {
			meta = TrackName{
				delta_time: delta_time
				text: data.bytestr()
			}
		}
		0x04 {
			meta = InstrumentName{
				delta_time: delta_time
				text: data.bytestr()
			}
		}
		0x05 {
			meta = Lyrics{
				delta_time: delta_time
				text: data.bytestr()
			}
		}
		0x06 {
			meta = Marker{
				delta_time: delta_time
				text: data.bytestr()
			}
		}
		0x07 {
			meta = CuePoint{
				delta_time: delta_time
				text: data.bytestr()
			}
		}
		0x09 {
			meta = DeviceName{
				delta_time: delta_time
				text: data.bytestr()
			}
		}
		0x20 {
			meta = MidiChannelPrefix{
				delta_time: delta_time
				channel: data[0]
			}
		}
		0x21 { // Obsolete MIDI Port
		}
		0x2f {
			meta = EndOfTrack{}
			delta_time:
			delta_time
		}
		0x51 {
			meta = SetTempo{
				delta_time: delta_time
				microseconds: byte_to_int(data)
			}
		}
		0x54 {
			meta = SMPTEOffset{
				delta_time: delta_time
				hour: data[0]
				min: data[1]
				sec: data[2]
				fr: data[3]
				subfr: data[4]
			}
		}
		0x58 {
			meta = TimeSignature{
				delta_time: delta_time
				numer: data[0]
				denom: data[1]
				metro: data[2]
				nds: data[3]
			}
		}
		0x59 {
			meta = KeySignature{
				delta_time: delta_time
				key: data[0]
				scale: data[1]
			}
		}
		0x7f {
			meta = SequencerSpecific{
				delta_time: delta_time
				data: data
			}
		}
		else {
			println('UNKNOWN META $meta_type.hex()')

			// return none
		}
	}
	unsafe {
		*index_track = index
	}
	return meta
}

fn read_track(file []u8, index int, chunk_size int) ?Track {
	mut track := Track{}
	mut index_track := index
	mut divide_sysex := []u8{}
	mut last_status := u8(0)

	for index_track < index + chunk_size {
		delta_time := get_variable_length_value(file, mut &index_track)
		match file[index_track] {
			0xF0, 0xF7 { // SYSEX
				sysex := read_sysex(file, mut &index_track, delta_time, mut divide_sysex)
				if sysex.data.len != 0 {
					track.data << sysex
				}
			}
			0xFF { // META EVENT
				meta := read_meta(file, mut &index_track, delta_time) or { return none }
				track.data << meta
			}
			else {
				event := read_midi_event(file, mut &index_track, delta_time, mut &last_status) or {
					return none
				}
				track.data << event
			}
		}
	}
	return track
}

fn read_chunks(file []u8) ?Midi {
	mut midi := Midi{}
	mut index := 0
	for index < file.len {
		chunk_name := [file[index], file[index + 1], file[index + 2], file[index + 3]].bytestr()
		index += 4
		chunk_size := byte_to_int(file[index..index + 4].clone())
		index += 4
		match chunk_name {
			'MThd' {
				midi.format_type = byte_to_int(file[index..index + 2].clone())
				midi.number_tracks = byte_to_int(file[index + 2..index + 4].clone())
				midi.time_division_ = byte_to_int(file[index + 4..index + 6].clone())
			}
			'MTrk' {
				track := read_track(file, index, chunk_size) or { return none }
				midi.tracks << track
			}
			else {
				println('Unknown chunk $chunk_name')
				return none
			}
		}
		index += chunk_size
	}
	return midi
}

pub struct SysEx {
pub:
	delta_time u64
	data       []u8
}

fn read_sysex(file []u8, mut index_track &int, delta_time u64, mut divide_sysex []u8) SysEx {
	mut index := *index_track

	// sysex_type := file[index]
	index++
	length := get_variable_length_value(file, mut &index)
	data := file[index..index + int(length)].clone()

	unsafe { divide_sysex.push_many(data, data.len) }
	if data[data.len - 1] != 0xF7 {
		return SysEx{
			data: []u8{}
		}
	}
	index += int(length)
	unsafe {
		*index_track = index
	}
	sysex := SysEx{
		data: divide_sysex
	}
	divide_sysex.clear()
	return sysex
}

pub type TrkData = ChannelAftertouch
	| Controller
	| CopyrightNotice
	| CuePoint
	| DeviceName
	| EndOfTrack
	| InstrumentName
	| KeySignature
	| Lyrics
	| Marker
	| MidiChannelPrefix
	| NoteAftertouch
	| NoteOff
	| NoteOn
	| PitchBend
	| ProgramChange
	| SMPTEOffset
	| SequenceNumber
	| SequencerSpecific
	| SetTempo
	| SysEx
	| TextEvent
	| TimeSignature
	| TrackName

pub type Meta = CopyrightNotice
	| CuePoint
	| EndOfTrack
	| InstrumentName
	| KeySignature
	| Lyrics
	| Marker
	| MidiChannelPrefix
	| SMPTEOffset
	| SequenceNumber
	| SequencerSpecific
	| SetTempo
	| TextEvent
	| TimeSignature
	| TrackName

pub struct Track {
pub mut:
	nb   int
	data []TrkData
}

pub struct Midi {
mut:
	time_division_ int
pub mut:
	format_type     int
	number_tracks   int
	tracks          []Track
	micros_per_tick int
}

fn byte_to_int(bytes []u8) int {
	mut res := 0
	for i in 0 .. bytes.len {
		res += bytes[bytes.len - (i + 1)] << (i << 3)
	}
	return res
}

fn get_variable_length_value(bytes []u8, mut shift_index &int) u64 {
	mut value := u64(0)
	mut index := 0

	for {
		value += bytes[index + *shift_index] & 0x7f
		if int(bytes[index + *shift_index] >> 7) == 0 {
			break
		}
		value <<= 7
		index++
	}
	unsafe {
		*shift_index += index + 1
	}
	return value
}

fn (mut midi Midi) time_division() {
	mut mpqn := 500000

	for event in midi.tracks[0].data {
		match event {
			SetTempo {
				mpqn = event.microseconds
				break
			}
			else {}
		}
	}

	midi.micros_per_tick = midi.mpqn(mpqn)
}

pub fn (midi &Midi) mpqn(mpqn int) int {
	if midi.time_division_ & 0x8000 == 0 {
		ticks_per_beat := midi.time_division_ & 0x7FFFF
		return mpqn / ticks_per_beat
	} else {
		fps := midi.time_division_ & 0x7F00
		tpf := midi.time_division_ & 0x00FF
		return 1000000 / (fps * tpf)
	}
}

fn (data TrkData) is_event() bool {
	return match data {
		NoteOff, NoteOn, NoteAftertouch, Controller, ProgramChange, ChannelAftertouch, PitchBend { true }
		else { false }
	}
}
