-- test_midi_file.lua
-- Unit tests for midi.midi_file

local unit = require 'llx.unit'

local MidiFile = require 'lua-midi.midi_file'.MidiFile
local Track = require 'lua-midi.track'.Track
local event = require 'lua-midi.event'
local NoteBeginEvent = event.NoteBeginEvent
local NoteEndEvent = event.NoteEndEvent
local EndOfTrackEvent = event.EndOfTrackEvent

_ENV = unit.create_test_env(_ENV)

describe('MidiFileTests', function()
  it('should set format when constructed with positional args', function()
    local mf = MidiFile(1, 96)
    expect(mf.format).to.be_equal_to(1)
  end)

  it('should set ticks when constructed with positional args', function()
    local mf = MidiFile(1, 96)
    expect(mf.ticks).to.be_equal_to(96)
  end)

  it('should have zero tracks when constructed with positional args', function()
    local mf = MidiFile(1, 96)
    expect(#mf.tracks).to.be_equal_to(0)
  end)

  it('should set format when constructed with table args', function()
    local mf = MidiFile { format = 2, ticks = 120 }
    expect(mf.format).to.be_equal_to(2)
  end)

  it('should set ticks when constructed with table args', function()
    local mf = MidiFile { format = 2, ticks = 120 }
    expect(mf.ticks).to.be_equal_to(120)
  end)

  it('should have zero tracks when constructed with table args', function()
    local mf = MidiFile { format = 2, ticks = 120 }
    expect(#mf.tracks).to.be_equal_to(0)
  end)

  it('should include MidiFile in tostring', function()
    local mf = MidiFile(0, 480)
    local str = tostring(mf)
    expect(str:match('MidiFile')).to.be_truthy()
  end)

  it('should include format in tostring', function()
    local mf = MidiFile(0, 480)
    local str = tostring(mf)
    expect(str:match('format=0')).to.be_truthy()
  end)

  it('should include ticks in tostring', function()
    local mf = MidiFile(0, 480)
    local str = tostring(mf)
    expect(str:match('ticks=480')).to.be_truthy()
  end)

  it('should return string type when tobytes is called', function()
    local mf = MidiFile(1, 96)
    local bin = mf:__tobytes()
    expect(type(bin) == 'string').to.be_truthy()
  end)

  it('should return binary data longer than 6 bytes when tobytes is called', function()
    local mf = MidiFile(1, 96)
    local bin = mf:__tobytes()
    expect(#bin > 6).to.be_truthy()  -- Should at least include the MIDI header
  end)

  it('should not crash tostring for SMPTE timing', function()
    local mf = MidiFile(1, 96)
    mf:set_smpte_timing(25, 40)
    local str = tostring(mf)
    expect(str:match('MidiFile')).to.be_truthy()
    expect(str:match('SMPTE')).to.be_truthy()
    expect(str:match('25')).to.be_truthy()
  end)
end)

describe('MidiFileEqualityTests', function()
  it('should consider identical MidiFiles equal', function()
    local a = MidiFile(1, 96)
    local b = MidiFile(1, 96)
    expect(a == b).to.be_truthy()
  end)

  it('should consider MidiFiles with different formats unequal', function()
    local a = MidiFile(0, 96)
    local b = MidiFile(1, 96)
    expect(a == b).to.be_falsy()
  end)

  it('should consider MidiFiles with different ticks unequal', function()
    local a = MidiFile(1, 96)
    local b = MidiFile(1, 480)
    expect(a == b).to.be_falsy()
  end)

  it('should consider MidiFiles with identical tracks equal', function()
    local a = MidiFile(1, 96)
    table.insert(a.tracks, Track {
      NoteBeginEvent(0, 0, 60, 100),
      NoteEndEvent(96, 0, 60, 0),
      EndOfTrackEvent(0, 0x0F, {}),
    })
    local b = MidiFile(1, 96)
    table.insert(b.tracks, Track {
      NoteBeginEvent(0, 0, 60, 100),
      NoteEndEvent(96, 0, 60, 0),
      EndOfTrackEvent(0, 0x0F, {}),
    })
    expect(a == b).to.be_truthy()
  end)

  it('should consider MidiFiles with different track counts unequal', function()
    local a = MidiFile(1, 96)
    table.insert(a.tracks, Track { NoteBeginEvent(0, 0, 60, 100) })
    local b = MidiFile(1, 96)
    expect(a == b).to.be_falsy()
  end)

  it('should consider SMPTE MidiFiles with identical timing equal', function()
    local a = MidiFile(1, 96)
    a:set_smpte_timing(25, 40)
    local b = MidiFile(1, 96)
    b:set_smpte_timing(25, 40)
    expect(a == b).to.be_truthy()
  end)

  it('should consider SMPTE MidiFiles with different frame rates unequal', function()
    local a = MidiFile(1, 96)
    a:set_smpte_timing(25, 40)
    local b = MidiFile(1, 96)
    b:set_smpte_timing(30, 40)
    expect(a == b).to.be_falsy()
  end)

  it('should reject ticks of zero', function()
    local ok = pcall(function() MidiFile(1, 0) end)
    expect(ok).to.be_falsy()
  end)

  it('should reject negative ticks', function()
    local ok = pcall(function() MidiFile(1, -1) end)
    expect(ok).to.be_falsy()
  end)

  it('should reject ticks exceeding 15-bit max', function()
    local ok = pcall(function() MidiFile(1, 0x8000) end)
    expect(ok).to.be_falsy()
  end)

  it('should accept ticks at boundaries', function()
    local mf1 = MidiFile(1, 1)
    expect(mf1.ticks).to.be_equal_to(1)
    local mf2 = MidiFile(1, 0x7FFF)
    expect(mf2.ticks).to.be_equal_to(0x7FFF)
  end)

  it('should reject ticks of zero with table constructor', function()
    local ok = pcall(function() MidiFile{format=1, ticks=0} end)
    expect(ok).to.be_falsy()
  end)

  it('should consider MidiFile equal after write-read round-trip', function()
    local original = MidiFile{format = 1, ticks = 96}
    table.insert(original.tracks, Track {
      NoteBeginEvent(0, 0, 60, 100),
      NoteEndEvent(96, 0, 60, 0),
      EndOfTrackEvent(0, 0x0F, {}),
    })

    local bytes = original:__tobytes()
    local tmp = io.tmpfile()
    tmp:write(bytes)
    tmp:seek('set', 0)
    local parsed = MidiFile.read(tmp)
    tmp:close()

    expect(original == parsed).to.be_truthy()
  end)
end)

run_unit_tests()
