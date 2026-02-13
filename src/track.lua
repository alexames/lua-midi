--- MIDI Track Module.
-- This module defines the `Track` class, which represents
-- a single track in a MIDI file.
-- A MIDI track is a sequence of events (notes, control
-- changes, meta info, etc.),
-- each with its own delta time. Tracks are serialized with
-- a byte length and written
-- with the 'MTrk' header prefix.
--
-- @module midi.track
-- @copyright 2024 Alexander Ames
-- @license MIT
-- @usage
-- local track = require 'lua-midi.track'
-- local event = require 'lua-midi.event'
--
-- -- Create a new track with events
-- local t = track.Track()
-- table.insert(t.events, event.NoteBeginEvent(0, 0, 60, 100))
-- table.insert(t.events, event.NoteEndEvent(480, 0, 60, 0))

local llx = require 'llx'
local midi_io = require 'lua-midi.io'
local midi_event = require 'lua-midi.event'

local _ENV, _M = llx.environment.create_module_environment()
local class = llx.class

--- Create a fresh running-status context for reading or writing events.
-- @local
local function _new_context()
  return { previous_command_byte = 0 }
end

--- Track class representing a single MIDI track.
-- A track contains a list of MIDI events with delta times.
-- @type Track
-- @field events List List of MIDI events
Track = class 'Track' {
  --- Create a new Track.
  -- @function Track:__init
  -- @param events List Optional list of MIDI events (default: empty list)
  -- @return Track A new Track instance
  __init = function(self, events)
    self.events = events or llx.List{}
  end,

  --- Serialize track event data to a string buffer.
  -- @return string The serialized track data
  -- @local
  _serialize_events = function(self)
    local parts = {}
    local buffer = {
      write = function(_, s) parts[#parts + 1] = s end
    }
    local context = _new_context()
    for _, event in ipairs(self.events) do
      event:write(buffer, context)
    end
    return table.concat(parts)
  end,

  --- Read a Track from the given file handle.
  -- Expects the 'MTrk' chunk header at the current file position.
  -- @param file file A binary input file handle
  -- @return Track A Track object populated with parsed events
  -- @raise error if 'MTrk' header is missing or track is malformed
  read = function(file)
    local track = Track()
    assert(file:read(4) == 'MTrk', "Expected 'MTrk' chunk")

    local track_byte_length = midi_io.readUInt32be(file)
    local context = _new_context()
    local end_of_track = file:seek() + track_byte_length

    -- Read events until the declared byte length is consumed
    while file:seek() ~= end_of_track do
      assert(
        file:seek() < end_of_track,
        string.format(
          'Read too many bytes for track (got %i, expected %i)',
          file:seek(), end_of_track))
      table.insert(track.events, midi_event.Event.read(file, context))
    end

    return track
  end,

  --- Write a Track to the given file handle.
  -- Serializes events to a buffer in a single pass, then
  -- writes the header with the correct byte length.
  -- @function Track:write
  -- @param file file A binary output file handle
  write = function(self, file)
    local track_data = self:_serialize_events()
    file:write('MTrk')
    midi_io.writeUInt32be(file, #track_data)
    file:write(track_data)
  end,

  --- Equality comparison for tracks.
  -- Two tracks are equal if they have the same number of
  -- events and all events are equal.
  -- @param other Track The track to compare with
  -- @return boolean True if equal
  __eq = function(self, other)
    if self.class ~= other.class then return false end
    if #self.events ~= #other.events then return false end
    for i = 1, #self.events do
      if self.events[i] ~= other.events[i] then return false end
    end
    return true
  end,

  --- Create an independent copy of this track.
  -- Clones all events so the copy shares no mutable state.
  -- @return Track A new track equal to this one
  clone = function(self)
    local cloned_events = llx.List{}
    for _, event in ipairs(self.events) do
      table.insert(cloned_events, event:clone())
    end
    return Track(cloned_events)
  end,

  --- Returns a human-readable string representation of the track.
  -- Includes all events in order.
  -- @return string String representation of the track
  __tostring = function(self)
    local event_strings = {}
    for i, event in ipairs(self.events) do
      event_strings[i] = tostring(event)
    end
    return string.format('Track{events={%s}}',
                         table.concat(event_strings, ', '))
  end,
}

return _M
