-- test_meta_events.lua
-- Unit tests for structured meta event parsing

local unit = require 'unit'
local EXPECT_EQ = unit.EXPECT_EQ
local EXPECT_TRUE = unit.EXPECT_TRUE
local EXPECT_FALSE = unit.EXPECT_FALSE

local event = require 'midi.event'
local SetTempoEvent = event.SetTempoEvent
local TimeSignatureEvent = event.TimeSignatureEvent
local KeySignatureEvent = event.KeySignatureEvent
local SMPTEOffsetEvent = event.SMPTEOffsetEvent
local ProgramNameEvent = event.ProgramNameEvent
local DeviceNameEvent = event.DeviceNameEvent

_ENV = unit.create_test_env(_ENV)

test_class 'SetTempoEventTests' {
  [test 'set and get tempo in microseconds'] = function()
    local tempo = SetTempoEvent(0, 0x0F, {})
    tempo:set_tempo(500000)  -- 500,000 microseconds per quarter note
    EXPECT_EQ(tempo:get_tempo(), 500000)
  end,

  [test 'set and get tempo in BPM'] = function()
    local tempo = SetTempoEvent(0, 0x0F, {})
    tempo:set_bpm(120)
    local bpm = tempo:get_bpm()
    EXPECT_TRUE(math.abs(bpm - 120) < 0.01)
  end,

  [test 'BPM conversion accuracy'] = function()
    local tempo = SetTempoEvent(0, 0x0F, {})
    tempo:set_bpm(90)
    EXPECT_TRUE(math.abs(tempo:get_bpm() - 90) < 0.01)
    tempo:set_bpm(140)
    EXPECT_TRUE(math.abs(tempo:get_bpm() - 140) < 0.01)
  end,

  [test 'tempo data encoding'] = function()
    local tempo = SetTempoEvent(0, 0x0F, {})
    tempo:set_tempo(0x07A120)  -- 500,000 in hex
    EXPECT_EQ(#tempo.data, 3)
    EXPECT_EQ(tempo.data[1], 0x07)
    EXPECT_EQ(tempo.data[2], 0xA1)
    EXPECT_EQ(tempo.data[3], 0x20)
  end,
}

test_class 'TimeSignatureEventTests' {
  [test 'set and get 4/4 time'] = function()
    local ts = TimeSignatureEvent(0, 0x0F, {})
    ts:set_time_signature(4, 4, 24, 8)
    local sig = ts:get_time_signature()
    EXPECT_EQ(sig.numerator, 4)
    EXPECT_EQ(sig.denominator, 4)
    EXPECT_EQ(sig.clocks_per_metronome_click, 24)
    EXPECT_EQ(sig.thirty_seconds_per_quarter, 8)
  end,

  [test 'set and get 3/4 time'] = function()
    local ts = TimeSignatureEvent(0, 0x0F, {})
    ts:set_time_signature(3, 4)
    local sig = ts:get_time_signature()
    EXPECT_EQ(sig.numerator, 3)
    EXPECT_EQ(sig.denominator, 4)
  end,

  [test 'set and get 6/8 time'] = function()
    local ts = TimeSignatureEvent(0, 0x0F, {})
    ts:set_time_signature(6, 8)
    local sig = ts:get_time_signature()
    EXPECT_EQ(sig.numerator, 6)
    EXPECT_EQ(sig.denominator, 8)
  end,

  [test 'denominator power of 2 encoding'] = function()
    local ts = TimeSignatureEvent(0, 0x0F, {})
    ts:set_time_signature(7, 8)  -- 7/8 time
    EXPECT_EQ(ts.data[2], 3)  -- 2^3 = 8
  end,
}

test_class 'KeySignatureEventTests' {
  [test 'C major (no sharps or flats)'] = function()
    local ks = KeySignatureEvent(0, 0x0F, {})
    ks:set_key_signature(0, false)
    local key = ks:get_key_signature()
    EXPECT_EQ(key.sharps_flats, 0)
    EXPECT_FALSE(key.is_minor)
  end,

  [test 'D major (2 sharps)'] = function()
    local ks = KeySignatureEvent(0, 0x0F, {})
    ks:set_key_signature(2, false)
    local key = ks:get_key_signature()
    EXPECT_EQ(key.sharps_flats, 2)
    EXPECT_FALSE(key.is_minor)
  end,

  [test 'B flat major (2 flats)'] = function()
    local ks = KeySignatureEvent(0, 0x0F, {})
    ks:set_key_signature(-2, false)
    local key = ks:get_key_signature()
    EXPECT_EQ(key.sharps_flats, -2)
    EXPECT_FALSE(key.is_minor)
  end,

  [test 'A minor (no sharps or flats)'] = function()
    local ks = KeySignatureEvent(0, 0x0F, {})
    ks:set_key_signature(0, true)
    local key = ks:get_key_signature()
    EXPECT_EQ(key.sharps_flats, 0)
    EXPECT_TRUE(key.is_minor)
  end,

  [test 'F sharp minor (3 sharps)'] = function()
    local ks = KeySignatureEvent(0, 0x0F, {})
    ks:set_key_signature(3, true)
    local key = ks:get_key_signature()
    EXPECT_EQ(key.sharps_flats, 3)
    EXPECT_TRUE(key.is_minor)
  end,
}

test_class 'SMPTEOffsetEventTests' {
  [test 'set and get SMPTE offset'] = function()
    local smpte = SMPTEOffsetEvent(0, 0x0F, {})
    smpte:set_offset(1, 30, 45, 12, 50)
    local offset = smpte:get_offset()
    EXPECT_EQ(offset.hours, 1)
    EXPECT_EQ(offset.minutes, 30)
    EXPECT_EQ(offset.seconds, 45)
    EXPECT_EQ(offset.frames, 12)
    EXPECT_EQ(offset.fractional_frames, 50)
  end,

  [test 'fractional frames default to 0'] = function()
    local smpte = SMPTEOffsetEvent(0, 0x0F, {})
    smpte:set_offset(0, 0, 0, 0)
    local offset = smpte:get_offset()
    EXPECT_EQ(offset.fractional_frames, 0)
  end,
}

test_class 'NewMetaEventTests' {
  [test 'ProgramNameEvent creation'] = function()
    local pn = ProgramNameEvent(0, 0x0F, {0x50, 0x69, 0x61, 0x6E, 0x6F})  -- "Piano"
    EXPECT_EQ(pn.meta_command, 0x08)
    EXPECT_EQ(#pn.data, 5)
  end,

  [test 'DeviceNameEvent creation'] = function()
    local dn = DeviceNameEvent(0, 0x0F, {0x53, 0x79, 0x6E, 0x74, 0x68})  -- "Synth"
    EXPECT_EQ(dn.meta_command, 0x09)
    EXPECT_EQ(#dn.data, 5)
  end,
}

run_unit_tests()
