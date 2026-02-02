-- test_meta_events.lua
-- Unit tests for structured meta event parsing

local unit = require 'llx.unit'

local event = require 'lua-midi.event'
local SetTempoEvent = event.SetTempoEvent
local TimeSignatureEvent = event.TimeSignatureEvent
local KeySignatureEvent = event.KeySignatureEvent
local SMPTEOffsetEvent = event.SMPTEOffsetEvent
local ProgramNameEvent = event.ProgramNameEvent
local DeviceNameEvent = event.DeviceNameEvent

_ENV = unit.create_test_env(_ENV)

describe('SetTempoEventTests', function()
  it('should set and get tempo in microseconds correctly', function()
    local tempo = SetTempoEvent(0, 0x0F, {})
    tempo:set_tempo(500000)  -- 500,000 microseconds per quarter note
    expect(tempo:get_tempo()).to.be_equal_to(500000)
  end)

  it('should set and get tempo in BPM correctly', function()
    local tempo = SetTempoEvent(0, 0x0F, {})
    tempo:set_bpm(120)
    local bpm = tempo:get_bpm()
    expect(math.abs(bpm - 120) < 0.01).to.be_truthy()
  end)

  it('should convert BPM accurately for 90 BPM', function()
    local tempo = SetTempoEvent(0, 0x0F, {})
    tempo:set_bpm(90)
    expect(math.abs(tempo:get_bpm() - 90) < 0.01).to.be_truthy()
  end)

  it('should convert BPM accurately for 140 BPM', function()
    local tempo = SetTempoEvent(0, 0x0F, {})
    tempo:set_bpm(140)
    expect(math.abs(tempo:get_bpm() - 140) < 0.01).to.be_truthy()
  end)

  it('should encode tempo data with correct length', function()
    local tempo = SetTempoEvent(0, 0x0F, {})
    tempo:set_tempo(0x07A120)  -- 500,000 in hex
    expect(#tempo.data).to.be_equal_to(3)
  end)

  it('should encode tempo data with correct first byte', function()
    local tempo = SetTempoEvent(0, 0x0F, {})
    tempo:set_tempo(0x07A120)  -- 500,000 in hex
    expect(tempo.data[1]).to.be_equal_to(0x07)
  end)

  it('should encode tempo data with correct second byte', function()
    local tempo = SetTempoEvent(0, 0x0F, {})
    tempo:set_tempo(0x07A120)  -- 500,000 in hex
    expect(tempo.data[2]).to.be_equal_to(0xA1)
  end)

  it('should encode tempo data with correct third byte', function()
    local tempo = SetTempoEvent(0, 0x0F, {})
    tempo:set_tempo(0x07A120)  -- 500,000 in hex
    expect(tempo.data[3]).to.be_equal_to(0x20)
  end)
end)

describe('TimeSignatureEventTests', function()
  it('should set and get 4/4 time signature numerator', function()
    local ts = TimeSignatureEvent(0, 0x0F, {})
    ts:set_time_signature(4, 4, 24, 8)
    local sig = ts:get_time_signature()
    expect(sig.numerator).to.be_equal_to(4)
  end)

  it('should set and get 4/4 time signature denominator', function()
    local ts = TimeSignatureEvent(0, 0x0F, {})
    ts:set_time_signature(4, 4, 24, 8)
    local sig = ts:get_time_signature()
    expect(sig.denominator).to.be_equal_to(4)
  end)

  it('should set and get 4/4 time signature clocks per metronome click', function()
    local ts = TimeSignatureEvent(0, 0x0F, {})
    ts:set_time_signature(4, 4, 24, 8)
    local sig = ts:get_time_signature()
    expect(sig.clocks_per_metronome_click).to.be_equal_to(24)
  end)

  it('should set and get 4/4 time signature thirty seconds per quarter', function()
    local ts = TimeSignatureEvent(0, 0x0F, {})
    ts:set_time_signature(4, 4, 24, 8)
    local sig = ts:get_time_signature()
    expect(sig.thirty_seconds_per_quarter).to.be_equal_to(8)
  end)

  it('should set and get 3/4 time signature numerator', function()
    local ts = TimeSignatureEvent(0, 0x0F, {})
    ts:set_time_signature(3, 4)
    local sig = ts:get_time_signature()
    expect(sig.numerator).to.be_equal_to(3)
  end)

  it('should set and get 3/4 time signature denominator', function()
    local ts = TimeSignatureEvent(0, 0x0F, {})
    ts:set_time_signature(3, 4)
    local sig = ts:get_time_signature()
    expect(sig.denominator).to.be_equal_to(4)
  end)

  it('should set and get 6/8 time signature numerator', function()
    local ts = TimeSignatureEvent(0, 0x0F, {})
    ts:set_time_signature(6, 8)
    local sig = ts:get_time_signature()
    expect(sig.numerator).to.be_equal_to(6)
  end)

  it('should set and get 6/8 time signature denominator', function()
    local ts = TimeSignatureEvent(0, 0x0F, {})
    ts:set_time_signature(6, 8)
    local sig = ts:get_time_signature()
    expect(sig.denominator).to.be_equal_to(8)
  end)

  it('should encode denominator as power of 2 for 7/8 time', function()
    local ts = TimeSignatureEvent(0, 0x0F, {})
    ts:set_time_signature(7, 8)  -- 7/8 time
    expect(ts.data[2]).to.be_equal_to(3)  -- 2^3 = 8
  end)
end)

describe('KeySignatureEventTests', function()
  it('should set and get C major with no sharps or flats', function()
    local ks = KeySignatureEvent(0, 0x0F, {})
    ks:set_key_signature(0, false)
    local key = ks:get_key_signature()
    expect(key.sharps_flats).to.be_equal_to(0)
  end)

  it('should set and get C major as not minor', function()
    local ks = KeySignatureEvent(0, 0x0F, {})
    ks:set_key_signature(0, false)
    local key = ks:get_key_signature()
    expect(key.is_minor).to.be_falsy()
  end)

  it('should set and get D major with 2 sharps', function()
    local ks = KeySignatureEvent(0, 0x0F, {})
    ks:set_key_signature(2, false)
    local key = ks:get_key_signature()
    expect(key.sharps_flats).to.be_equal_to(2)
  end)

  it('should set and get D major as not minor', function()
    local ks = KeySignatureEvent(0, 0x0F, {})
    ks:set_key_signature(2, false)
    local key = ks:get_key_signature()
    expect(key.is_minor).to.be_falsy()
  end)

  it('should set and get B flat major with 2 flats', function()
    local ks = KeySignatureEvent(0, 0x0F, {})
    ks:set_key_signature(-2, false)
    local key = ks:get_key_signature()
    expect(key.sharps_flats).to.be_equal_to(-2)
  end)

  it('should set and get B flat major as not minor', function()
    local ks = KeySignatureEvent(0, 0x0F, {})
    ks:set_key_signature(-2, false)
    local key = ks:get_key_signature()
    expect(key.is_minor).to.be_falsy()
  end)

  it('should set and get A minor with no sharps or flats', function()
    local ks = KeySignatureEvent(0, 0x0F, {})
    ks:set_key_signature(0, true)
    local key = ks:get_key_signature()
    expect(key.sharps_flats).to.be_equal_to(0)
  end)

  it('should set and get A minor as minor', function()
    local ks = KeySignatureEvent(0, 0x0F, {})
    ks:set_key_signature(0, true)
    local key = ks:get_key_signature()
    expect(key.is_minor).to.be_truthy()
  end)

  it('should set and get F sharp minor with 3 sharps', function()
    local ks = KeySignatureEvent(0, 0x0F, {})
    ks:set_key_signature(3, true)
    local key = ks:get_key_signature()
    expect(key.sharps_flats).to.be_equal_to(3)
  end)

  it('should set and get F sharp minor as minor', function()
    local ks = KeySignatureEvent(0, 0x0F, {})
    ks:set_key_signature(3, true)
    local key = ks:get_key_signature()
    expect(key.is_minor).to.be_truthy()
  end)
end)

describe('SMPTEOffsetEventTests', function()
  it('should set and get SMPTE offset hours', function()
    local smpte = SMPTEOffsetEvent(0, 0x0F, {})
    smpte:set_offset(1, 30, 45, 12, 50)
    local offset = smpte:get_offset()
    expect(offset.hours).to.be_equal_to(1)
  end)

  it('should set and get SMPTE offset minutes', function()
    local smpte = SMPTEOffsetEvent(0, 0x0F, {})
    smpte:set_offset(1, 30, 45, 12, 50)
    local offset = smpte:get_offset()
    expect(offset.minutes).to.be_equal_to(30)
  end)

  it('should set and get SMPTE offset seconds', function()
    local smpte = SMPTEOffsetEvent(0, 0x0F, {})
    smpte:set_offset(1, 30, 45, 12, 50)
    local offset = smpte:get_offset()
    expect(offset.seconds).to.be_equal_to(45)
  end)

  it('should set and get SMPTE offset frames', function()
    local smpte = SMPTEOffsetEvent(0, 0x0F, {})
    smpte:set_offset(1, 30, 45, 12, 50)
    local offset = smpte:get_offset()
    expect(offset.frames).to.be_equal_to(12)
  end)

  it('should set and get SMPTE offset fractional frames', function()
    local smpte = SMPTEOffsetEvent(0, 0x0F, {})
    smpte:set_offset(1, 30, 45, 12, 50)
    local offset = smpte:get_offset()
    expect(offset.fractional_frames).to.be_equal_to(50)
  end)

  it('should default fractional frames to 0 when not provided', function()
    local smpte = SMPTEOffsetEvent(0, 0x0F, {})
    smpte:set_offset(0, 0, 0, 0)
    local offset = smpte:get_offset()
    expect(offset.fractional_frames).to.be_equal_to(0)
  end)
end)

describe('NewMetaEventTests', function()
  it('should create ProgramNameEvent with correct meta command', function()
    local pn = ProgramNameEvent(0, 0x0F, {0x50, 0x69, 0x61, 0x6E, 0x6F})  -- "Piano"
    expect(pn.meta_command).to.be_equal_to(0x08)
  end)

  it('should create ProgramNameEvent with correct data length', function()
    local pn = ProgramNameEvent(0, 0x0F, {0x50, 0x69, 0x61, 0x6E, 0x6F})  -- "Piano"
    expect(#pn.data).to.be_equal_to(5)
  end)

  it('should create DeviceNameEvent with correct meta command', function()
    local dn = DeviceNameEvent(0, 0x0F, {0x53, 0x79, 0x6E, 0x74, 0x68})  -- "Synth"
    expect(dn.meta_command).to.be_equal_to(0x09)
  end)

  it('should create DeviceNameEvent with correct data length', function()
    local dn = DeviceNameEvent(0, 0x0F, {0x53, 0x79, 0x6E, 0x74, 0x68})  -- "Synth"
    expect(#dn.data).to.be_equal_to(5)
  end)
end)

run_unit_tests()
