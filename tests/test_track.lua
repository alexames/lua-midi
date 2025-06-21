-- test_track.lua
-- Unit tests for midi.track

local unit = require 'unit'
local EXPECT_EQ = unit.EXPECT_EQ
local EXPECT_TRUE = unit.EXPECT_TRUE

local Track = require 'midi.track'.Track
local NoteBeginEvent = require 'midi.event'.NoteBeginEvent

unit.test_class 'TrackTests' {
  ['construct empty track'] = function()
    local track = Track()
    EXPECT_EQ(#track.events, 0)
  end,

  ['track tostring with events'] = function()
    local e = NoteBeginEvent(0, 0, 60, 100)
    local track = Track { e }
    local str = tostring(track)
    EXPECT_TRUE(str:match('Track{events={'))
    EXPECT_TRUE(str:match('NoteBeginEvent'))
  end,

  ['track write produces output'] = function()
    local buffer = {}
    local file = { write = function(_, s) table.insert(buffer, s) end }
    local e = NoteBeginEvent(0, 0, 60, 100)
    local track = Track { e }
    track:write(file)
    local out = table.concat(buffer)
    EXPECT_TRUE(type(out) == 'string')
    EXPECT_TRUE(#out > 4) -- should include 'MTrk' and length
  end,
}
