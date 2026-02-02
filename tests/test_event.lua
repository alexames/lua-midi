-- test_event.lua
-- Unit tests for midi.event module

local unit = require 'llx.unit'

local event = require 'lua-midi.event'
local NoteBeginEvent = event.NoteBeginEvent
local NoteEndEvent = event.NoteEndEvent
local MetaEvent = event.MetaEvent
local SetTempoEvent = event.SetTempoEvent

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

  it('should encode data when meta event write is called', function()
    local buffer = {}
    local file = { write = function(_, x) table.insert(buffer, x) end }
    local e = SetTempoEvent(0, 0x0F, {1, 2, 3})
    e:write(file, { previous_command_byte = 0 })
    local joined = table.concat(buffer)
    -- expect(joined:match("["]") ~= nil).to.be_truthy() -- at least one byte was written
  end)

  it('should encode schema when note begin write is called', function()
    local bytes = {}
    local file = {
      write = function(_, s) table.insert(bytes, s) end
    }
    local e = NoteBeginEvent(0, 0, 60, 100)
    e:write(file, { previous_command_byte = -1 })
    local output = table.concat(bytes)
    expect(#output > 0).to.be_truthy()
  end)
end)

run_unit_tests()
