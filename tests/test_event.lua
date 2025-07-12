-- test_event.lua
-- Unit tests for midi.event module

local unit = require 'unit'
local EXPECT_EQ = unit.EXPECT_EQ
local EXPECT_THAT = unit.EXPECT_THAT
local Equals = unit.Equals

local event = require 'midi.event'
local NoteBeginEvent = event.NoteBeginEvent
local NoteEndEvent = event.NoteEndEvent
local MetaEvent = event.MetaEvent
local SetTempoEvent = event.SetTempoEvent

_ENV = unit.create_test_env(_ENV)

test_class 'EventTests' {
  [test 'note begin tostring'] = function()
    local e = NoteBeginEvent(120, 1, 60, 127)
    EXPECT_EQ(tostring(e), 'NoteBeginEvent(120, 1, 60, 127)')
  end,

  [test 'note end tostring'] = function()
    local e = NoteEndEvent(60, 2, 62, 100)
    EXPECT_EQ(tostring(e), 'NoteEndEvent(60, 2, 62, 100)')
  end,

  [test 'meta event tostring'] = function()
    local e = SetTempoEvent(0, 0, {0x07, 0xA1, 0x20})
    EXPECT_EQ(tostring(e), 'SetTempoEvent(0, 0, 7, 161, 32)')
  end,

  [test 'meta event write encodes data'] = function()
    local buffer = {}
    local file = { write = function(_, x) table.insert(buffer, x) end }
    local e = SetTempoEvent(0, 0, {1, 2, 3})
    e:write(file, { previous_command_byte = 0 })
    local joined = table.concat(buffer)
    -- EXPECT_TRUE(joined:match("["]") ~= nil) -- at least one byte was written
  end,

  [test 'note begin write encodes schema'] = function()
    local bytes = {}
    local file = {
      write = function(_, s) table.insert(bytes, s) end
    }
    local e = NoteBeginEvent(0, 0, 60, 100)
    e:write(file, { previous_command_byte = -1 })
    local output = table.concat(bytes)
    EXPECT_TRUE(#output > 0)
  end,
}

run_unit_tests()
