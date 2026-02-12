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
    local tempo = SetTempoEvent(0, {})
    tempo:set_tempo(500000)  -- 500,000 microseconds per quarter note
    expect(tempo:get_tempo()).to.be_equal_to(500000)
  end)

  it('should set and get tempo in BPM correctly', function()
    local tempo = SetTempoEvent(0, {})
    tempo:set_bpm(120)
    local bpm = tempo:get_bpm()
    expect(math.abs(bpm - 120) < 0.01).to.be_truthy()
  end)

  it('should convert BPM accurately for 90 BPM', function()
    local tempo = SetTempoEvent(0, {})
    tempo:set_bpm(90)
    expect(math.abs(tempo:get_bpm() - 90) < 0.01).to.be_truthy()
  end)

  it('should convert BPM accurately for 140 BPM', function()
    local tempo = SetTempoEvent(0, {})
    tempo:set_bpm(140)
    expect(math.abs(tempo:get_bpm() - 140) < 0.01).to.be_truthy()
  end)

  it('should encode tempo data with correct length', function()
    local tempo = SetTempoEvent(0, {})
    tempo:set_tempo(0x07A120)  -- 500,000 in hex
    expect(#tempo:_get_data()).to.be_equal_to(3)
  end)

  it('should encode tempo data with correct first byte', function()
    local tempo = SetTempoEvent(0, {})
    tempo:set_tempo(0x07A120)  -- 500,000 in hex
    expect(tempo:_get_data()[1]).to.be_equal_to(0x07)
  end)

  it('should encode tempo data with correct second byte', function()
    local tempo = SetTempoEvent(0, {})
    tempo:set_tempo(0x07A120)  -- 500,000 in hex
    expect(tempo:_get_data()[2]).to.be_equal_to(0xA1)
  end)

  it('should encode tempo data with correct third byte', function()
    local tempo = SetTempoEvent(0, {})
    tempo:set_tempo(0x07A120)  -- 500,000 in hex
    expect(tempo:_get_data()[3]).to.be_equal_to(0x20)
  end)
end)

describe('TimeSignatureEventTests', function()
  it('should set and get 4/4 time signature numerator', function()
    local ts = TimeSignatureEvent(0, {})
    ts:set_time_signature(4, 4, 24, 8)
    local sig = ts:get_time_signature()
    expect(sig.numerator).to.be_equal_to(4)
  end)

  it('should set and get 4/4 time signature denominator', function()
    local ts = TimeSignatureEvent(0, {})
    ts:set_time_signature(4, 4, 24, 8)
    local sig = ts:get_time_signature()
    expect(sig.denominator).to.be_equal_to(4)
  end)

  it('should set and get 4/4 time signature'
    .. ' clocks per metronome click',
  function()
    local ts = TimeSignatureEvent(0, {})
    ts:set_time_signature(4, 4, 24, 8)
    local sig = ts:get_time_signature()
    expect(sig.clocks_per_metronome_click).to.be_equal_to(24)
  end)

  it('should set and get 4/4 time signature'
    .. ' thirty seconds per quarter',
  function()
    local ts = TimeSignatureEvent(0, {})
    ts:set_time_signature(4, 4, 24, 8)
    local sig = ts:get_time_signature()
    expect(sig.thirty_seconds_per_quarter).to.be_equal_to(8)
  end)

  it('should set and get 3/4 time signature numerator', function()
    local ts = TimeSignatureEvent(0, {})
    ts:set_time_signature(3, 4)
    local sig = ts:get_time_signature()
    expect(sig.numerator).to.be_equal_to(3)
  end)

  it('should set and get 3/4 time signature denominator', function()
    local ts = TimeSignatureEvent(0, {})
    ts:set_time_signature(3, 4)
    local sig = ts:get_time_signature()
    expect(sig.denominator).to.be_equal_to(4)
  end)

  it('should set and get 6/8 time signature numerator', function()
    local ts = TimeSignatureEvent(0, {})
    ts:set_time_signature(6, 8)
    local sig = ts:get_time_signature()
    expect(sig.numerator).to.be_equal_to(6)
  end)

  it('should set and get 6/8 time signature denominator', function()
    local ts = TimeSignatureEvent(0, {})
    ts:set_time_signature(6, 8)
    local sig = ts:get_time_signature()
    expect(sig.denominator).to.be_equal_to(8)
  end)

  it('should encode denominator as power of 2 for 7/8 time', function()
    local ts = TimeSignatureEvent(0, {})
    ts:set_time_signature(7, 8)  -- 7/8 time
    expect(ts:_get_data()[2]).to.be_equal_to(3)  -- 2^3 = 8
  end)

  it('should encode all power-of-two denominators correctly', function()
    local ts = TimeSignatureEvent(0, {})
    for power = 0, 5 do
      local denom = 2 ^ power
      ts:set_time_signature(4, denom)
      expect(ts:_get_data()[2]).to.be_equal_to(power)
    end
  end)

  it('should store denominator as integer'
    .. ' when constructed from raw bytes',
  function()
    -- In Lua 5.4, 2^n returns a float; 1<<n returns
    -- an integer. The denominator must be integer for
    -- regularity with set_time_signature.
    local ts = TimeSignatureEvent(0, {4, 2, 24, 8})
    -- 4/4 time (denominator_power=2)
    expect(math.type(ts.denominator)).to.be_equal_to('integer')
  end)

  it('should produce equal events from raw bytes'
    .. ' and set_time_signature',
  function()
    local from_bytes = TimeSignatureEvent(0, {4, 2, 24, 8})
    local from_setter = TimeSignatureEvent(0, {})
    from_setter:set_time_signature(4, 4, 24, 8)
    expect(from_bytes == from_setter).to.be_truthy()
  end)
end)

describe('KeySignatureEventTests', function()
  it('should set and get C major with no sharps or flats', function()
    local ks = KeySignatureEvent(0, {})
    ks:set_key_signature(0, false)
    local key = ks:get_key_signature()
    expect(key.sharps_flats).to.be_equal_to(0)
  end)

  it('should set and get C major as not minor', function()
    local ks = KeySignatureEvent(0, {})
    ks:set_key_signature(0, false)
    local key = ks:get_key_signature()
    expect(key.is_minor).to.be_falsy()
  end)

  it('should set and get D major with 2 sharps', function()
    local ks = KeySignatureEvent(0, {})
    ks:set_key_signature(2, false)
    local key = ks:get_key_signature()
    expect(key.sharps_flats).to.be_equal_to(2)
  end)

  it('should set and get D major as not minor', function()
    local ks = KeySignatureEvent(0, {})
    ks:set_key_signature(2, false)
    local key = ks:get_key_signature()
    expect(key.is_minor).to.be_falsy()
  end)

  it('should set and get B flat major with 2 flats', function()
    local ks = KeySignatureEvent(0, {})
    ks:set_key_signature(-2, false)
    local key = ks:get_key_signature()
    expect(key.sharps_flats).to.be_equal_to(-2)
  end)

  it('should set and get B flat major as not minor', function()
    local ks = KeySignatureEvent(0, {})
    ks:set_key_signature(-2, false)
    local key = ks:get_key_signature()
    expect(key.is_minor).to.be_falsy()
  end)

  it('should set and get A minor with no sharps or flats', function()
    local ks = KeySignatureEvent(0, {})
    ks:set_key_signature(0, true)
    local key = ks:get_key_signature()
    expect(key.sharps_flats).to.be_equal_to(0)
  end)

  it('should set and get A minor as minor', function()
    local ks = KeySignatureEvent(0, {})
    ks:set_key_signature(0, true)
    local key = ks:get_key_signature()
    expect(key.is_minor).to.be_truthy()
  end)

  it('should set and get F sharp minor with 3 sharps', function()
    local ks = KeySignatureEvent(0, {})
    ks:set_key_signature(3, true)
    local key = ks:get_key_signature()
    expect(key.sharps_flats).to.be_equal_to(3)
  end)

  it('should set and get F sharp minor as minor', function()
    local ks = KeySignatureEvent(0, {})
    ks:set_key_signature(3, true)
    local key = ks:get_key_signature()
    expect(key.is_minor).to.be_truthy()
  end)
end)

describe('SMPTEOffsetEventTests', function()
  it('should set and get SMPTE offset hours', function()
    local smpte = SMPTEOffsetEvent(0, {})
    smpte:set_offset(1, 30, 45, 12, 50)
    local offset = smpte:get_offset()
    expect(offset.hours).to.be_equal_to(1)
  end)

  it('should set and get SMPTE offset minutes', function()
    local smpte = SMPTEOffsetEvent(0, {})
    smpte:set_offset(1, 30, 45, 12, 50)
    local offset = smpte:get_offset()
    expect(offset.minutes).to.be_equal_to(30)
  end)

  it('should set and get SMPTE offset seconds', function()
    local smpte = SMPTEOffsetEvent(0, {})
    smpte:set_offset(1, 30, 45, 12, 50)
    local offset = smpte:get_offset()
    expect(offset.seconds).to.be_equal_to(45)
  end)

  it('should set and get SMPTE offset frames', function()
    local smpte = SMPTEOffsetEvent(0, {})
    smpte:set_offset(1, 30, 45, 12, 50)
    local offset = smpte:get_offset()
    expect(offset.frames).to.be_equal_to(12)
  end)

  it('should set and get SMPTE offset fractional frames', function()
    local smpte = SMPTEOffsetEvent(0, {})
    smpte:set_offset(1, 30, 45, 12, 50)
    local offset = smpte:get_offset()
    expect(offset.fractional_frames).to.be_equal_to(50)
  end)

  it('should default fractional frames to 0 when not provided', function()
    local smpte = SMPTEOffsetEvent(0, {})
    smpte:set_offset(0, 0, 0, 0)
    local offset = smpte:get_offset()
    expect(offset.fractional_frames).to.be_equal_to(0)
  end)
end)

describe('CanonicalFieldTests', function()
  it('should expose tempo as a named field'
    .. ' after construction from raw bytes',
  function()
    local tempo = SetTempoEvent(0, {0x07, 0xA1, 0x20})
    expect(tempo.tempo).to.be_equal_to(500000)
  end)

  it('should update tempo field when set_tempo is called', function()
    local tempo = SetTempoEvent(0, {})
    tempo:set_tempo(600000)
    expect(tempo.tempo).to.be_equal_to(600000)
  end)

  it('should expose time signature fields after set_time_signature', function()
    local ts = TimeSignatureEvent(0, {})
    ts:set_time_signature(3, 8, 24, 8)
    expect(ts.numerator).to.be_equal_to(3)
    expect(ts.denominator).to.be_equal_to(8)
    expect(ts.clocks_per_metronome_click).to.be_equal_to(24)
  end)

  it('should parse time signature fields from raw bytes', function()
    -- 4/4 time: numerator=4, denominator_power=2, clocks=24, 32nds=8
    local ts = TimeSignatureEvent(0, {4, 2, 24, 8})
    expect(ts.numerator).to.be_equal_to(4)
    expect(ts.denominator).to.be_equal_to(4)
  end)

  it('should expose key signature fields after set_key_signature', function()
    local ks = KeySignatureEvent(0, {})
    ks:set_key_signature(-3, true)
    expect(ks.sharps_flats).to.be_equal_to(-3)
    expect(ks.is_minor).to.be_truthy()
  end)

  it('should parse key signature fields from raw bytes', function()
    -- 2 sharps, major: data = {2, 0}
    local ks = KeySignatureEvent(0, {2, 0})
    expect(ks.sharps_flats).to.be_equal_to(2)
    expect(ks.is_minor).to.be_falsy()
  end)

  it('should expose SMPTE offset fields after set_offset', function()
    local smpte = SMPTEOffsetEvent(0, {})
    smpte:set_offset(2, 15, 30, 10, 25)
    expect(smpte.hours).to.be_equal_to(2)
    expect(smpte.minutes).to.be_equal_to(15)
    expect(smpte.seconds).to.be_equal_to(30)
    expect(smpte.frames).to.be_equal_to(10)
    expect(smpte.fractional_frames).to.be_equal_to(25)
  end)

  it('should parse SMPTE offset fields from raw bytes', function()
    local smpte = SMPTEOffsetEvent(0, {1, 30, 45, 12, 50})
    expect(smpte.hours).to.be_equal_to(1)
    expect(smpte.minutes).to.be_equal_to(30)
    expect(smpte.seconds).to.be_equal_to(45)
    expect(smpte.frames).to.be_equal_to(12)
    expect(smpte.fractional_frames).to.be_equal_to(50)
  end)
end)

describe('NewMetaEventTests', function()
  it('should create ProgramNameEvent with correct meta command', function()
    local pn = ProgramNameEvent(0, {0x50, 0x69, 0x61, 0x6E, 0x6F})  -- "Piano"
    expect(pn.meta_command).to.be_equal_to(0x08)
  end)

  it('should create ProgramNameEvent with correct data length', function()
    local pn = ProgramNameEvent(0, {0x50, 0x69, 0x61, 0x6E, 0x6F})  -- "Piano"
    expect(#pn.data).to.be_equal_to(5)
  end)

  it('should create DeviceNameEvent with correct meta command', function()
    local dn = DeviceNameEvent(0, {0x53, 0x79, 0x6E, 0x74, 0x68})  -- "Synth"
    expect(dn.meta_command).to.be_equal_to(0x09)
  end)

  it('should create DeviceNameEvent with correct data length', function()
    local dn = DeviceNameEvent(0, {0x53, 0x79, 0x6E, 0x74, 0x68})  -- "Synth"
    expect(#dn.data).to.be_equal_to(5)
  end)

  it('should defensively copy meta event data table', function()
    local data = {0x07, 0xA1, 0x20}
    local tempo = SetTempoEvent(0, data)
    data[1] = 0xFF
    -- original value, unaffected by mutation
    expect(tempo.tempo).to.be_equal_to(500000)
  end)

  it('should not retain stale data on SetTempoEvent', function()
    local tempo = SetTempoEvent(0, {0x07, 0xA1, 0x20})
    expect(tempo.data).to.be_equal_to(nil)
  end)

  it('should not retain stale data on TimeSignatureEvent', function()
    local ts = TimeSignatureEvent(0, {4, 2, 24, 8})
    expect(ts.data).to.be_equal_to(nil)
  end)

  it('should not retain stale data on KeySignatureEvent', function()
    local ks = KeySignatureEvent(0, {2, 0})
    expect(ks.data).to.be_equal_to(nil)
  end)

  it('should not retain stale data on SMPTEOffsetEvent', function()
    local smpte = SMPTEOffsetEvent(0, {1, 30, 45, 12, 50})
    expect(smpte.data).to.be_equal_to(nil)
  end)

  it('should serialize tempo from canonical field'
    .. ' after direct mutation',
  function()
    local tempo = SetTempoEvent(0, {0x07, 0xA1, 0x20})  -- 500000 us
    tempo.tempo = 1000000  -- Change canonical field directly
    local data = tempo:_get_data()
    -- 1000000 = 0x0F4240
    expect(data[1]).to.be_equal_to(0x0F)
    expect(data[2]).to.be_equal_to(0x42)
    expect(data[3]).to.be_equal_to(0x40)
  end)

  it('should serialize time signature from canonical fields'
    .. ' after set',
  function()
    local ts = TimeSignatureEvent(0, {4, 2, 24, 8})  -- 4/4
    ts:set_time_signature(3, 4)  -- Change to 3/4
    local data = ts:_get_data()
    expect(data[1]).to.be_equal_to(3)   -- numerator
    expect(data[2]).to.be_equal_to(2)   -- log2(4) = 2
    expect(data[3]).to.be_equal_to(24)  -- default clocks
    expect(data[4]).to.be_equal_to(8)   -- default 32nds
  end)

  it('should serialize key signature from canonical fields'
    .. ' after set',
  function()
    local ks = KeySignatureEvent(0, {0, 0})  -- C major
    ks:set_key_signature(-3, true)  -- Eb minor
    local data = ks:_get_data()
    expect(data[1]).to.be_equal_to(253)  -- -3 as unsigned byte
    expect(data[2]).to.be_equal_to(1)    -- minor
  end)
end)

describe('MalformedMetaEventDataTests', function()
  it('should error on SetTempoEvent with wrong data length', function()
    local ok = pcall(function() SetTempoEvent(0, {0x07, 0xA1}) end)
    expect(ok).to.be_falsy()
  end)

  it('should accept SetTempoEvent with empty data', function()
    local t = SetTempoEvent(0, {})
    expect(t.tempo).to.be_equal_to(500000)
  end)

  it('should error on TimeSignatureEvent with wrong data length', function()
    local ok = pcall(function() TimeSignatureEvent(0, {4, 2, 24}) end)
    expect(ok).to.be_falsy()
  end)

  it('should accept TimeSignatureEvent with empty data', function()
    local ts = TimeSignatureEvent(0, {})
    expect(ts.numerator).to.be_equal_to(4)
    expect(ts.denominator).to.be_equal_to(4)
  end)

  it('should error on KeySignatureEvent with wrong data length', function()
    local ok = pcall(function() KeySignatureEvent(0, {0}) end)
    expect(ok).to.be_falsy()
  end)

  it('should accept KeySignatureEvent with empty data', function()
    local ks = KeySignatureEvent(0, {})
    expect(ks.sharps_flats).to.be_equal_to(0)
    expect(ks.is_minor).to.be_falsy()
  end)

  it('should error on SMPTEOffsetEvent with wrong data length', function()
    local ok = pcall(function() SMPTEOffsetEvent(0, {1, 2, 3}) end)
    expect(ok).to.be_falsy()
  end)

  it('should accept SMPTEOffsetEvent with empty data', function()
    local s = SMPTEOffsetEvent(0, {})
    expect(s.hours).to.be_equal_to(0)
  end)
end)

describe('SetterValidationTests', function()
  it('should reject set_tempo with zero', function()
    local t = SetTempoEvent(0, {})
    local ok = pcall(function() t:set_tempo(0) end)
    expect(ok).to.be_falsy()
  end)

  it('should reject set_tempo with negative value', function()
    local t = SetTempoEvent(0, {})
    local ok = pcall(function() t:set_tempo(-1) end)
    expect(ok).to.be_falsy()
  end)

  it('should reject set_tempo with value exceeding 3-byte max', function()
    local t = SetTempoEvent(0, {})
    local ok = pcall(function() t:set_tempo(0xFFFFFF + 1) end)
    expect(ok).to.be_falsy()
  end)

  it('should accept set_tempo at boundaries', function()
    local t = SetTempoEvent(0, {})
    t:set_tempo(1)
    expect(t.tempo).to.be_equal_to(1)
    t:set_tempo(0xFFFFFF)
    expect(t.tempo).to.be_equal_to(0xFFFFFF)
  end)

  it('should reject set_bpm with zero', function()
    local t = SetTempoEvent(0, {})
    local ok = pcall(function() t:set_bpm(0) end)
    expect(ok).to.be_falsy()
  end)

  it('should reject set_bpm with negative value', function()
    local t = SetTempoEvent(0, {})
    local ok = pcall(function() t:set_bpm(-10) end)
    expect(ok).to.be_falsy()
  end)

  it('should reject set_time_signature'
    .. ' with non-power-of-2 denominator',
  function()
    local ts = TimeSignatureEvent(0, {})
    local ok = pcall(function() ts:set_time_signature(4, 3) end)
    expect(ok).to.be_falsy()
  end)

  it('should reject set_time_signature with zero denominator', function()
    local ts = TimeSignatureEvent(0, {})
    local ok = pcall(function() ts:set_time_signature(4, 0) end)
    expect(ok).to.be_falsy()
  end)

  it('should accept set_time_signature'
    .. ' with valid power-of-2 denominators',
  function()
    local ts = TimeSignatureEvent(0, {})
    for _, d in ipairs({1, 2, 4, 8, 16, 32, 64, 128, 256}) do
      ts:set_time_signature(4, d)
      expect(ts.denominator).to.be_equal_to(d)
    end
  end)

  it('should reject set_key_signature'
    .. ' with sharps_flats out of range',
  function()
    local ks = KeySignatureEvent(0, {})
    local ok = pcall(function() ks:set_key_signature(8, false) end)
    expect(ok).to.be_falsy()
  end)

  it('should reject set_key_signature with non-boolean is_minor', function()
    local ks = KeySignatureEvent(0, {})
    local ok = pcall(function() ks:set_key_signature(0, 1) end)
    expect(ok).to.be_falsy()
  end)

  it('should accept set_key_signature at boundaries', function()
    local ks = KeySignatureEvent(0, {})
    ks:set_key_signature(-7, true)
    expect(ks.sharps_flats).to.be_equal_to(-7)
    ks:set_key_signature(7, false)
    expect(ks.sharps_flats).to.be_equal_to(7)
  end)

  it('should reject set_offset with out-of-range hours', function()
    local s = SMPTEOffsetEvent(0, {})
    local ok = pcall(function() s:set_offset(24, 0, 0, 0) end)
    expect(ok).to.be_falsy()
  end)

  it('should reject set_offset with negative minutes', function()
    local s = SMPTEOffsetEvent(0, {})
    local ok = pcall(function() s:set_offset(0, -1, 0, 0) end)
    expect(ok).to.be_falsy()
  end)

  it('should reject set_offset with out-of-range minutes', function()
    local s = SMPTEOffsetEvent(0, {})
    local ok = pcall(function() s:set_offset(0, 60, 0, 0) end)
    expect(ok).to.be_falsy()
  end)

  it('should reject set_offset with out-of-range seconds', function()
    local s = SMPTEOffsetEvent(0, {})
    local ok = pcall(function() s:set_offset(0, 0, 60, 0) end)
    expect(ok).to.be_falsy()
  end)

  it('should reject set_offset with out-of-range frames', function()
    local s = SMPTEOffsetEvent(0, {})
    local ok = pcall(function() s:set_offset(0, 0, 0, 30) end)
    expect(ok).to.be_falsy()
  end)

  it('should reject set_offset with out-of-range fractional frames', function()
    local s = SMPTEOffsetEvent(0, {})
    local ok = pcall(function() s:set_offset(0, 0, 0, 0, 100) end)
    expect(ok).to.be_falsy()
  end)

  it('should accept set_offset at boundary values', function()
    local s = SMPTEOffsetEvent(0, {})
    s:set_offset(23, 59, 59, 29, 99)
    expect(s.hours).to.be_equal_to(23)
    expect(s.minutes).to.be_equal_to(59)
    expect(s.seconds).to.be_equal_to(59)
    expect(s.frames).to.be_equal_to(29)
    expect(s.fractional_frames).to.be_equal_to(99)
  end)

  it('should accept set_offset with valid values', function()
    local s = SMPTEOffsetEvent(0, {})
    s:set_offset(1, 30, 45, 12, 50)
    expect(s.hours).to.be_equal_to(1)
    expect(s.minutes).to.be_equal_to(30)
    expect(s.seconds).to.be_equal_to(45)
    expect(s.frames).to.be_equal_to(12)
    expect(s.fractional_frames).to.be_equal_to(50)
  end)
end)

run_unit_tests()
