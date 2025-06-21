-- test_midi_file.lua
-- Unit tests for midi.midi_file

local unit = require 'unit'
local EXPECT_EQ = unit.EXPECT_EQ
local EXPECT_TRUE = unit.EXPECT_TRUE

local MidiFile = require 'midi.midi_file'.MidiFile

unit.test_class 'MidiFileTests' {
  ['construct with positional args'] = function()
    local mf = MidiFile(1, 96)
    EXPECT_EQ(mf.format, 1)
    EXPECT_EQ(mf.ticks, 96)
    EXPECT_EQ(#mf.tracks, 0)
  end,

  ['construct with table args'] = function()
    local mf = MidiFile { format = 2, ticks = 120 }
    EXPECT_EQ(mf.format, 2)
    EXPECT_EQ(mf.ticks, 120)
    EXPECT_EQ(#mf.tracks, 0)
  end,

  ['tostring includes format and ticks'] = function()
    local mf = MidiFile(0, 480)
    local str = tostring(mf)
    EXPECT_TRUE(str:match('MidiFile'))
    EXPECT_TRUE(str:match('format=0'))
    EXPECT_TRUE(str:match('ticks=480'))
  end,

  ['tobytes returns binary data'] = function()
    local mf = MidiFile(1, 96)
    local bin = mf:__tobytes()
    EXPECT_TRUE(type(bin) == 'string')
    EXPECT_TRUE(#bin > 6)  -- Should at least include the MIDI header
  end,
}
