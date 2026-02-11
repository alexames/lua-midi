-- test_midi_file.lua
-- Unit tests for midi.midi_file

local unit = require 'llx.unit'

local MidiFile = require 'lua-midi.midi_file'.MidiFile

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

run_unit_tests()
