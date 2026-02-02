--- MIDI Track Module.
-- This module defines the `Track` class, which represents a single track in a MIDI file.
-- A MIDI track is a sequence of events (notes, control changes, meta info, etc.),
-- each with its own delta time. Tracks are serialized with a byte length and written
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

  --- Calculate the total byte length of the track (excluding 'MTrk' and length field).
  -- This is needed for writing the track to a MIDI file.
  -- @return number Byte length of the track data
  -- @local
  _get_track_byte_length = function(self)
    local length = 0
    local previous_command_byte = 0

    for i, event in ipairs(self.events) do
      -- Account for the size of the delta time (variable length quantity)
      local time_delta = event.time_delta
      if time_delta > (0x7F * 0x7F * 0x7F) then
        length = length + 4
      elseif time_delta > (0x7F * 0x7F) then
        length = length + 3
      elseif time_delta > 0x7F then
        length = length + 2
      else
        length = length + 1
      end

      -- Determine if command byte must be written (running status optimization)
      local commandByte = event.command | event.channel
      if commandByte ~= previous_command_byte
         or event.command == midi_event.MetaEvent.command then
        length = length + 1
        previous_command_byte = commandByte
      end

      -- Account for the size of the event data
      if event.command == midi_event.ProgramChangeEvent.command
         or event.command == midi_event.ChannelPressureChangeEvent.command then
        length = length + 1
      elseif event.command == midi_event.NoteEndEvent.command
          or event.command == midi_event.NoteBeginEvent.command
          or event.command == midi_event.VelocityChangeEvent.command
          or event.command == midi_event.ControllerChangeEvent.command
          or event.command == midi_event.PitchWheelChangeEvent.command then
        length = length + 2
      elseif event.command == midi_event.MetaEvent.command then
        -- Meta events have: 1 byte (meta ID) + 1 byte (length) + payload
        length = length + 2 + #event.data
      end
    end

    return length
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
    local context = { previous_command_byte = 0 }
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
  -- Includes the 'MTrk' header and track length.
  -- @function Track:write
  -- @param file file A binary output file handle
  write = function(self, file)
    file:write('MTrk')
    midi_io.writeUInt32be(file, self:_get_track_byte_length())

    local context = { previous_command_byte = 0 }
    for i, event in ipairs(self.events) do
      event:write(file, context)
    end
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
