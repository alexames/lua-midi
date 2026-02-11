-- test_event.lua
-- Unit tests for midi.event module

local unit = require 'llx.unit'

local event = require 'lua-midi.event'
local NoteBeginEvent = event.NoteBeginEvent
local NoteEndEvent = event.NoteEndEvent
local ProgramChangeEvent = event.ProgramChangeEvent
local ChannelPressureChangeEvent = event.ChannelPressureChangeEvent
local MetaEvent = event.MetaEvent
local SetTempoEvent = event.SetTempoEvent
local EndOfTrackEvent = event.EndOfTrackEvent
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
    local e = SetTempoEvent(0, 0x0F, {0x07, 0xA1, 0x20})
    expect(tostring(e)).to.be_equal_to('SetTempoEvent(0, 15, 7, 161, 32)')
  end)

  it('should write correct bytes for SetTempoEvent', function()
    local buffer = {}
    local file = { write = function(_, x) table.insert(buffer, x) end }
    local e = SetTempoEvent(0, 0x0F, {0x07, 0xA1, 0x20})
    e:write(file, { previous_command_byte = 0 })
    local output = table.concat(buffer)
    -- Expected: delta(0x00), command(0xF0|0x0F=0xFF), meta_command(0x51), length(3), data(0x07, 0xA1, 0x20)
    expect(output:byte(1)).to.be_equal_to(0x00)   -- delta time
    expect(output:byte(2)).to.be_equal_to(0xFF)    -- command byte (0xF0 | 0x0F)
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

  it('should write correct bytes for ProgramChangeEvent (1-field schema)', function()
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

  it('should construct ChannelPressureChangeEvent with correct fields', function()
    local e = ChannelPressureChangeEvent(10, 0, 80)
    expect(e.time_delta).to.be_equal_to(10)
    expect(e.channel).to.be_equal_to(0)
    expect(e.channel_number).to.be_equal_to(80)
  end)

  it('should write correct bytes for ChannelPressureChangeEvent (1-field schema)', function()
    local buffer = {}
    local file = { write = function(_, s) table.insert(buffer, s) end }
    local e = ChannelPressureChangeEvent(0, 2, 64)
    e:write(file, { previous_command_byte = -1 })
    local output = table.concat(buffer)
    -- Expected: delta(0x00), command(0xD0|0x02=0xD2), pressure(64=0x40)
    expect(output:byte(1)).to.be_equal_to(0x00)    -- delta time
    expect(output:byte(2)).to.be_equal_to(0xD2)    -- channel pressure, channel 2
    expect(output:byte(3)).to.be_equal_to(64)      -- pressure value
    expect(#output).to.be_equal_to(3)
  end)
end)

describe('RoundTripTests', function()
  it('should round-trip a MIDI file with note events through write and read', function()
    local mf = MidiFile{format = 1, ticks = 96}
    local track = Track {
      NoteBeginEvent(0, 0, 60, 100),
      NoteEndEvent(96, 0, 60, 0),
      EndOfTrackEvent(0, 0x0F, {}),
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

  it('should round-trip a format 0 MIDI file with tempo and time signature', function()
    local mf = MidiFile{format = 0, ticks = 480}
    local tempo = SetTempoEvent(0, 0x0F, {})
    tempo:set_tempo(500000)  -- 120 BPM
    local track = Track {
      tempo,
      NoteBeginEvent(0, 0, 64, 80),
      NoteEndEvent(480, 0, 64, 0),
      EndOfTrackEvent(0, 0x0F, {}),
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

run_unit_tests()
