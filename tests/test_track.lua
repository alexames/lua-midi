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

  it('should produce string output when track write is called', function()
    local buffer = {}
    local file = { write = function(_, s) table.insert(buffer, s) end }
    local e = NoteBeginEvent(0, 0, 60, 100)
    local track = Track { e }
    track:write(file)
    local out = table.concat(buffer)
    expect(type(out) == 'string').to.be_truthy()
  end)

  it('should produce output longer than 4 bytes when track write is called', function()
    local buffer = {}
    local file = { write = function(_, s) table.insert(buffer, s) end }
    local e = NoteBeginEvent(0, 0, 60, 100)
    local track = Track { e }
    track:write(file)
    local out = table.concat(buffer)
    expect(#out > 4).to.be_truthy() -- should include 'MTrk' and length
  end)
end)

run_unit_tests()