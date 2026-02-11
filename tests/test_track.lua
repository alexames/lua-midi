-- test_track.lua
-- Unit tests for midi.track

local unit = require 'llx.unit'

local Track = require 'lua-midi.track'.Track
local NoteBeginEvent = require 'lua-midi.event'.NoteBeginEvent

_ENV = unit.create_test_env(_ENV)

describe('TrackTests', function()
  it('should construct empty track with zero events', function()
    local track = Track()
    expect(#track.events).to.be_equal_to(0)
  end)

  it('should include Track in tostring when track has events', function()
    local e = NoteBeginEvent(0, 0, 60, 100)
    local track = Track { e }
    local str = tostring(track)
    expect(str:match('Track{events={')).to.be_truthy()
  end)

  it('should include NoteBeginEvent in tostring when track has events', function()
    local e = NoteBeginEvent(0, 0, 60, 100)
    local track = Track { e }
    local str = tostring(track)
    expect(str:match('NoteBeginEvent')).to.be_truthy()
  end)

  it('should write MTrk header and correct length', function()
    local buffer = {}
    local file = { write = function(_, s) table.insert(buffer, s) end }
    local e = NoteBeginEvent(0, 0, 60, 100)
    local track = Track { e }
    track:write(file)
    local out = table.concat(buffer)
    -- MTrk header (4 bytes) + length (4 bytes) + event data
    expect(out:sub(1, 4)).to.be_equal_to('MTrk')
    -- NoteBeginEvent(0, 0, 60, 100) = delta(1) + command(1) + note(1) + velocity(1) = 4 bytes
    -- Track length should be 4, stored as big-endian UInt32
    expect(out:byte(5)).to.be_equal_to(0)
    expect(out:byte(6)).to.be_equal_to(0)
    expect(out:byte(7)).to.be_equal_to(0)
    expect(out:byte(8)).to.be_equal_to(4)
    -- Total output: 4 (MTrk) + 4 (length) + 4 (event) = 12 bytes
    expect(#out).to.be_equal_to(12)
  end)
end)

run_unit_tests()