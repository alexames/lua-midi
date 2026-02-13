-- test_event.lua
-- Unit tests for midi.event module

local unit = require 'llx.unit'

local event = require 'lua-midi.event'
local NoteBeginEvent = event.NoteBeginEvent
local NoteEndEvent = event.NoteEndEvent
local ProgramChangeEvent = event.ProgramChangeEvent
local ChannelPressureChangeEvent = event.ChannelPressureChangeEvent
local ControllerChangeEvent = event.ControllerChangeEvent
local PitchWheelChangeEvent = event.PitchWheelChangeEvent
local MetaEvent = event.MetaEvent
local SetTempoEvent = event.SetTempoEvent
local EndOfTrackEvent = event.EndOfTrackEvent
local midi_io = require 'lua-midi.io'
local MidiFile = require 'lua-midi.midi_file'.MidiFile
local Track = require 'lua-midi.track'.Track

_ENV = unit.create_test_env(_ENV)

describe('EventTests', function()
  it('should convert note begin event to string correctly', function()
    local e = NoteBeginEvent(120, 1, 60, 127)
    expect(tostring(e)).to.be_equal_to('NoteBeginEvent(120, 1, 60, 127)')
  end)

  it('should convert note end event to string correctly', function()
    local e = NoteEndEvent(60, 2, 62, 100)
    expect(tostring(e)).to.be_equal_to('NoteEndEvent(60, 2, 62, 100)')
  end)

  it('should convert meta event to string correctly', function()
    local e = SetTempoEvent(0, {0x07, 0xA1, 0x20})
    expect(tostring(e)).to.be_equal_to('SetTempoEvent(0, tempo=500000)')
  end)

  it('should write correct bytes for SetTempoEvent', function()
    local buffer = {}
    local file = { write = function(_, x) table.insert(buffer, x) end }
    local e = SetTempoEvent(0, {0x07, 0xA1, 0x20})
    e:write(file, { previous_command_byte = 0 })
    local output = table.concat(buffer)
    -- Expected: delta(0x00), command(0xFF),
    -- meta_command(0x51), length(3),
    -- data(0x07, 0xA1, 0x20)
    expect(output:byte(1)).to.be_equal_to(0x00)   -- delta time
    expect(output:byte(2)).to.be_equal_to(0xFF)    -- command byte
    expect(output:byte(3)).to.be_equal_to(0x51)    -- meta command (set tempo)
    expect(output:byte(4)).to.be_equal_to(3)       -- data length
    expect(output:byte(5)).to.be_equal_to(0x07)    -- data byte 1
    expect(output:byte(6)).to.be_equal_to(0xA1)    -- data byte 2
    expect(output:byte(7)).to.be_equal_to(0x20)    -- data byte 3
    expect(#output).to.be_equal_to(7)
  end)

  it('should write correct bytes for NoteBeginEvent', function()
    local bytes = {}
    local file = {
      write = function(_, s) table.insert(bytes, s) end
    }
    local e = NoteBeginEvent(0, 0, 60, 100)
    e:write(file, { previous_command_byte = -1 })
    local output = table.concat(bytes)
    -- Expected: delta(0x00), command(0x90), note(60=0x3C), velocity(100=0x64)
    expect(output:byte(1)).to.be_equal_to(0x00)   -- delta time
    expect(output:byte(2)).to.be_equal_to(0x90)    -- note on, channel 0
    expect(output:byte(3)).to.be_equal_to(60)      -- note number (middle C)
    expect(output:byte(4)).to.be_equal_to(100)     -- velocity
    expect(#output).to.be_equal_to(4)
  end)
end)

describe('ChannelVoiceEventTests', function()
  it('should construct ProgramChangeEvent with correct fields', function()
    local e = ProgramChangeEvent(0, 3, 42)
    expect(e.time_delta).to.be_equal_to(0)
    expect(e.channel).to.be_equal_to(3)
    expect(e.new_program_number).to.be_equal_to(42)
  end)

  it('should write correct bytes for ProgramChangeEvent'
    .. ' (1-field schema)',
  function()
    local buffer = {}
    local file = { write = function(_, s) table.insert(buffer, s) end }
    local e = ProgramChangeEvent(0, 5, 42)
    e:write(file, { previous_command_byte = -1 })
    local output = table.concat(buffer)
    -- Expected: delta(0x00), command(0xC0|0x05=0xC5), program(42=0x2A)
    expect(output:byte(1)).to.be_equal_to(0x00)    -- delta time
    expect(output:byte(2)).to.be_equal_to(0xC5)    -- program change, channel 5
    expect(output:byte(3)).to.be_equal_to(42)      -- program number
    expect(#output).to.be_equal_to(3)
  end)

  it('should construct ChannelPressureChangeEvent'
    .. ' with correct fields',
  function()
    local e = ChannelPressureChangeEvent(10, 0, 80)
    expect(e.time_delta).to.be_equal_to(10)
    expect(e.channel).to.be_equal_to(0)
    expect(e.pressure).to.be_equal_to(80)
  end)

  it('should write correct bytes for'
    .. ' ChannelPressureChangeEvent (1-field schema)',
  function()
    local buffer = {}
    local file = { write = function(_, s) table.insert(buffer, s) end }
    local e = ChannelPressureChangeEvent(0, 2, 64)
    e:write(file, { previous_command_byte = -1 })
    local output = table.concat(buffer)
    -- Expected: delta(0x00), command(0xD0|0x02=0xD2), pressure(64=0x40)
    expect(output:byte(1)).to.be_equal_to(0x00)    -- delta time
    expect(output:byte(2)).to.be_equal_to(0xD2)
    -- channel pressure, channel 2
    expect(output:byte(3)).to.be_equal_to(64)      -- pressure value
    expect(#output).to.be_equal_to(3)
  end)
end)

describe('VLQRoundTripTests', function()
  -- Helper: write VLQ then read it back, verifying round-trip
  local function vlq_round_trip(value)
    local buffer = {}
    local pos = 0
    local file = {
      write = function(_, s) table.insert(buffer, s) end,
      read = function(_, n)
        local joined = table.concat(buffer)
        local result = joined:sub(pos + 1, pos + n)
        pos = pos + n
        return result
      end,
    }
    midi_io.writeVLQ(file, value)
    local read_back = midi_io.readVLQ(file)
    return read_back, table.concat(buffer)
  end

  it('should round-trip 1-byte VLQ values (0-127)', function()
    local result, bytes = vlq_round_trip(0)
    expect(result).to.be_equal_to(0)
    expect(#bytes).to.be_equal_to(1)

    result, bytes = vlq_round_trip(127)
    expect(result).to.be_equal_to(127)
    expect(#bytes).to.be_equal_to(1)
  end)

  it('should round-trip 2-byte VLQ values (128-16383)', function()
    local result, bytes = vlq_round_trip(128)
    expect(result).to.be_equal_to(128)
    expect(#bytes).to.be_equal_to(2)

    result, bytes = vlq_round_trip(16383)
    expect(result).to.be_equal_to(16383)
    expect(#bytes).to.be_equal_to(2)
  end)

  it('should round-trip 3-byte VLQ values (16384-2097151)', function()
    local result, bytes = vlq_round_trip(16384)
    expect(result).to.be_equal_to(16384)
    expect(#bytes).to.be_equal_to(3)

    result, bytes = vlq_round_trip(2097151)
    expect(result).to.be_equal_to(2097151)
    expect(#bytes).to.be_equal_to(3)
  end)

  it('should round-trip 4-byte VLQ values (2097152+)', function()
    local result, bytes = vlq_round_trip(2097152)
    expect(result).to.be_equal_to(2097152)
    expect(#bytes).to.be_equal_to(4)

    result, bytes = vlq_round_trip(0x0FFFFFFF)
    expect(result).to.be_equal_to(0x0FFFFFFF)
    expect(#bytes).to.be_equal_to(4)
  end)

  it('should round-trip previous bug boundary values (16130, 16383)', function()
    -- These values were incorrectly encoded before the VLQ fix
    local result = vlq_round_trip(16130)
    expect(result).to.be_equal_to(16130)

    result = vlq_round_trip(16383)
    expect(result).to.be_equal_to(16383)
  end)
end)

describe('RoundTripTests', function()
  it('should round-trip a MIDI file with note events'
    .. ' through write and read',
  function()
    local mf = MidiFile{format = 1, ticks = 96}
    local track = Track {
      NoteBeginEvent(0, 0, 60, 100),
      NoteEndEvent(96, 0, 60, 0),
      EndOfTrackEvent(0, {}),
    }
    table.insert(mf.tracks, track)

    local bytes = mf:__tobytes()
    local tmp = io.tmpfile()
    tmp:write(bytes)
    tmp:seek('set', 0)
    local parsed = MidiFile.read(tmp)
    tmp:close()

    expect(parsed.format).to.be_equal_to(1)
    expect(parsed.ticks).to.be_equal_to(96)
    expect(#parsed.tracks).to.be_equal_to(1)
    expect(#parsed.tracks[1].events).to.be_equal_to(3)

    local e1 = parsed.tracks[1].events[1]
    expect(e1.time_delta).to.be_equal_to(0)
    expect(e1.channel).to.be_equal_to(0)
    expect(e1.note_number).to.be_equal_to(60)
    expect(e1.velocity).to.be_equal_to(100)

    local e2 = parsed.tracks[1].events[2]
    expect(e2.time_delta).to.be_equal_to(96)
    expect(e2.channel).to.be_equal_to(0)
    expect(e2.note_number).to.be_equal_to(60)
    expect(e2.velocity).to.be_equal_to(0)
  end)

  it('should round-trip a format 0 MIDI file'
    .. ' with tempo and time signature',
  function()
    local mf = MidiFile{format = 0, ticks = 480}
    local tempo = SetTempoEvent(0, {})
    tempo:set_tempo(500000)  -- 120 BPM
    local track = Track {
      tempo,
      NoteBeginEvent(0, 0, 64, 80),
      NoteEndEvent(480, 0, 64, 0),
      EndOfTrackEvent(0, {}),
    }
    table.insert(mf.tracks, track)

    local bytes = mf:__tobytes()
    local tmp = io.tmpfile()
    tmp:write(bytes)
    tmp:seek('set', 0)
    local parsed = MidiFile.read(tmp)
    tmp:close()

    expect(parsed.format).to.be_equal_to(0)
    expect(parsed.ticks).to.be_equal_to(480)
    expect(#parsed.tracks).to.be_equal_to(1)
    expect(#parsed.tracks[1].events).to.be_equal_to(4)

    local parsed_tempo = parsed.tracks[1].events[1]
    expect(parsed_tempo:get_tempo()).to.be_equal_to(500000)
  end)
end)

describe('LargeDeltaTimeRoundTripTests', function()
  it('should round-trip a MIDI file with a large delta time'
    .. ' (16384 ticks)',
  function()
    local mf = MidiFile{format = 1, ticks = 96}
    local track = Track {
      NoteBeginEvent(0, 0, 60, 100),
      NoteEndEvent(16384, 0, 60, 0),
      EndOfTrackEvent(0, {}),
    }
    table.insert(mf.tracks, track)

    local bytes = mf:__tobytes()
    local tmp = io.tmpfile()
    tmp:write(bytes)
    tmp:seek('set', 0)
    local parsed = MidiFile.read(tmp)
    tmp:close()

    local e2 = parsed.tracks[1].events[2]
    expect(e2.time_delta).to.be_equal_to(16384)
  end)

  it('should round-trip a MIDI file with a very large'
    .. ' delta time (2097152 ticks)',
  function()
    local mf = MidiFile{format = 1, ticks = 96}
    local track = Track {
      NoteBeginEvent(0, 0, 60, 100),
      NoteEndEvent(2097152, 0, 60, 0),
      EndOfTrackEvent(0, {}),
    }
    table.insert(mf.tracks, track)

    local bytes = mf:__tobytes()
    local tmp = io.tmpfile()
    tmp:write(bytes)
    tmp:seek('set', 0)
    local parsed = MidiFile.read(tmp)
    tmp:close()

    local e2 = parsed.tracks[1].events[2]
    expect(e2.time_delta).to.be_equal_to(2097152)
  end)
end)

describe('EqualityTests', function()
  it('should consider identical NoteBeginEvents equal', function()
    local a = NoteBeginEvent(0, 0, 60, 100)
    local b = NoteBeginEvent(0, 0, 60, 100)
    expect(a == b).to.be_truthy()
  end)

  it('should consider NoteBeginEvents with different fields unequal', function()
    local a = NoteBeginEvent(0, 0, 60, 100)
    local b = NoteBeginEvent(0, 0, 60, 127)
    expect(a == b).to.be_falsy()
  end)

  it('should consider NoteBeginEvent and NoteEndEvent unequal', function()
    local a = NoteBeginEvent(0, 0, 60, 100)
    local b = NoteEndEvent(0, 0, 60, 100)
    expect(a == b).to.be_falsy()
  end)

  it('should consider identical SetTempoEvents equal', function()
    local a = SetTempoEvent(0, {0x07, 0xA1, 0x20})
    local b = SetTempoEvent(0, {0x07, 0xA1, 0x20})
    expect(a == b).to.be_truthy()
  end)

  it('should consider SetTempoEvents with different data unequal', function()
    local a = SetTempoEvent(0, {0x07, 0xA1, 0x20})
    local b = SetTempoEvent(0, {0x07, 0xA1, 0x21})
    expect(a == b).to.be_falsy()
  end)

  it('should consider identical EndOfTrackEvents equal', function()
    local a = EndOfTrackEvent(0, {})
    local b = EndOfTrackEvent(0, {})
    expect(a == b).to.be_truthy()
  end)

  it('should consider identical ProgramChangeEvents equal', function()
    local a = ProgramChangeEvent(0, 3, 42)
    local b = ProgramChangeEvent(0, 3, 42)
    expect(a == b).to.be_truthy()
  end)

  it('should consider ProgramChangeEvents with different'
    .. ' channels unequal',
  function()
    local a = ProgramChangeEvent(0, 3, 42)
    local b = ProgramChangeEvent(0, 5, 42)
    expect(a == b).to.be_falsy()
  end)

  it('should consider events equal after write-read round-trip', function()
    local mf = MidiFile{format = 1, ticks = 96}
    local original_events = {
      NoteBeginEvent(0, 0, 60, 100),
      NoteEndEvent(96, 0, 60, 0),
      EndOfTrackEvent(0, {}),
    }
    local track = Track(original_events)
    table.insert(mf.tracks, track)

    local bytes = mf:__tobytes()
    local tmp = io.tmpfile()
    tmp:write(bytes)
    tmp:seek('set', 0)
    local parsed = MidiFile.read(tmp)
    tmp:close()

    for i, original in ipairs(original_events) do
      expect(parsed.tracks[1].events[i] == original).to.be_truthy()
    end
  end)
end)

describe('MalformedInputTests', function()
  it('should error on invalid MIDI header', function()
    local tmp = io.tmpfile()
    tmp:write('NOPE\0\0\0\6\0\0\0\1\0\96')
    tmp:seek('set', 0)
    local success = pcall(function()
      MidiFile.read(tmp)
    end)
    tmp:close()
    expect(success).to.be_falsy()
  end)

  it('should error on truncated MIDI header', function()
    local tmp = io.tmpfile()
    tmp:write('MThd\0\0')
    tmp:seek('set', 0)
    local success = pcall(function()
      MidiFile.read(tmp)
    end)
    tmp:close()
    expect(success).to.be_falsy()
  end)

  it('should error on missing MTrk chunk', function()
    -- Valid MThd header claiming 1 track, but no MTrk follows
    local tmp = io.tmpfile()
    tmp:write('MThd\0\0\0\6\0\0\0\1\0\96NOPE')
    tmp:seek('set', 0)
    local success = pcall(function()
      MidiFile.read(tmp)
    end)
    tmp:close()
    expect(success).to.be_falsy()
  end)
end)

describe('ConstructorValidationTests', function()
  it('should reject NoteBeginEvent with channel out of range', function()
    local ok = pcall(function() NoteBeginEvent(0, 16, 60, 100) end)
    expect(ok).to.be_falsy()
  end)

  it('should reject NoteBeginEvent with note out of range', function()
    local ok = pcall(function() NoteBeginEvent(0, 0, 128, 100) end)
    expect(ok).to.be_falsy()
  end)

  it('should reject NoteBeginEvent with velocity out of range', function()
    local ok = pcall(function() NoteBeginEvent(0, 0, 60, 200) end)
    expect(ok).to.be_falsy()
  end)

  it('should reject NoteEndEvent with invalid channel', function()
    local ok = pcall(function() NoteEndEvent(0, -1, 60, 0) end)
    expect(ok).to.be_falsy()
  end)

  it('should reject ProgramChangeEvent with invalid program number', function()
    local ok = pcall(function() ProgramChangeEvent(0, 0, 128) end)
    expect(ok).to.be_falsy()
  end)

  it('should reject ChannelPressureChangeEvent'
    .. ' with invalid pressure',
  function()
    local ok = pcall(function() ChannelPressureChangeEvent(0, 0, 200) end)
    expect(ok).to.be_falsy()
  end)

  it('should reject ControllerChangeEvent with invalid controller', function()
    local ok = pcall(function() ControllerChangeEvent(0, 0, 128, 64) end)
    expect(ok).to.be_falsy()
  end)

  it('should reject ControllerChangeEvent with invalid value', function()
    local ok = pcall(function() ControllerChangeEvent(0, 0, 7, 128) end)
    expect(ok).to.be_falsy()
  end)

  it('should reject PitchWheelChangeEvent'
    .. ' with value exceeding 14-bit range',
  function()
    local ok = pcall(function() PitchWheelChangeEvent(0, 0, 16384) end)
    expect(ok).to.be_falsy()
  end)

  it('should reject PitchWheelChangeEvent with negative value', function()
    local ok = pcall(function() PitchWheelChangeEvent(0, 0, -1) end)
    expect(ok).to.be_falsy()
  end)

  it('should accept PitchWheelChangeEvent at center value', function()
    local pw = PitchWheelChangeEvent(0, 0, 8192)
    expect(pw.value).to.be_equal_to(8192)
  end)

  it('should accept PitchWheelChangeEvent at boundary values', function()
    PitchWheelChangeEvent(0, 0, 0)
    PitchWheelChangeEvent(0, 0, 16383)
  end)

  it('should accept valid NoteBeginEvent at boundaries', function()
    -- Should not throw
    NoteBeginEvent(0, 0, 0, 0)
    NoteBeginEvent(0, 15, 127, 127)
  end)

  it('should reject negative time delta', function()
    local ok = pcall(function() NoteBeginEvent(-1, 0, 60, 100) end)
    expect(ok).to.be_falsy()
  end)

  it('should reject non-integer time delta', function()
    local ok = pcall(function() NoteBeginEvent(1.5, 0, 60, 100) end)
    expect(ok).to.be_falsy()
  end)

  it('should reject time delta exceeding VLQ max', function()
    local ok = pcall(function() NoteBeginEvent(0x10000000, 0, 60, 100) end)
    expect(ok).to.be_falsy()
  end)

  it('should accept time delta at VLQ max boundary', function()
    NoteBeginEvent(0x0FFFFFFF, 0, 60, 100)
  end)
end)

describe('CloneTests', function()
  it('should clone a NoteBeginEvent with equal values', function()
    local original = NoteBeginEvent(120, 1, 60, 100)
    local copy = original:clone()
    expect(copy == original).to.be_truthy()
  end)

  it('should produce an independent NoteBeginEvent clone', function()
    local original = NoteBeginEvent(120, 1, 60, 100)
    local copy = original:clone()
    copy.time_delta = 240
    expect(original.time_delta).to.be_equal_to(120)
  end)

  it('should clone a SetTempoEvent with equal values', function()
    local original = SetTempoEvent(0, {0x07, 0xA1, 0x20})
    local copy = original:clone()
    expect(copy == original).to.be_truthy()
    expect(copy.tempo).to.be_equal_to(original.tempo)
  end)

  it('should produce an independent SetTempoEvent clone', function()
    local original = SetTempoEvent(0, {0x07, 0xA1, 0x20})
    local copy = original:clone()
    copy:set_tempo(1000000)
    expect(original.tempo).to.be_equal_to(500000)
  end)

  it('should clone a PitchWheelChangeEvent with equal values', function()
    local original = PitchWheelChangeEvent(0, 0, 8192)
    local copy = original:clone()
    expect(copy == original).to.be_truthy()
    expect(copy.value).to.be_equal_to(8192)
  end)
end)

run_unit_tests()
