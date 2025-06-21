-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>
--
-- This module defines the `Track` class, which represents a single track in a MIDI file.
-- A MIDI track is a sequence of events (notes, control changes, meta info, etc.), 
-- each with its own delta time. Tracks are serialized with a byte length and written 
-- with the 'MTrk' header prefix.

local llx = require 'llx'
local midi_io = require 'midi.io'
local midi_event = require 'midi.event'

local _ENV, _M = llx.environment.create_module_environment()
local class = llx.class

-- Track class: Represents a single MIDI track containing a list of events
Track = class 'Track' {
  --- Constructor
  -- @param events A list of MIDI events (default: empty llx.List)
  __init = function(self, events)
    self.events = events or llx.List{}
  end,

  --- Calculates the total byte length of the track (excluding 'MTrk' and length field)
  -- This is needed for writing the track to a MIDI file.
  _get_track_byte_length = function(self)
    local length = 0
    local previous_command_byte = 0

    for i, event in self.events do
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

  --- Reads a Track from the given file handle (starting after 'MTrk')
  -- @param file A binary input file
  -- @return A Track object populated with parsed events
  read = function(file)
    local track = Track()
    assert(file:read(4) == 'MTrk', "Expected 'MTrk' chunk")

    local track_byte_length = midi_io.readUInt32be(file)
    local context = { previous_command_byte = 0 }
    local end_of_track = file:seek() + track_byte_length

    -- Read events until the declared byte length is consumed
    while file:seek() ~= end_of_track do
      assert(file:seek() < end_of_track,
             ('Read too many bytes for track (got %i, expected %i)'):format(
               file:seek(), end_of_track))
      table.insert(track.events, midi_event.Event.read(file, context))
    end

    return track
  end,

  --- Writes a Track to the given file handle
  -- Includes the 'MTrk' header and track length
  write = function(self, file)
    file:write('MTrk')
    midi_io.writeUInt32be(file, self:_get_track_byte_length())

    local context = { previous_command_byte = 0 }
    for i, event in ipairs(self.events) do
      event:write(file, context)
    end
  end,

  --- Returns a human-readable string representation of the track
  -- Includes all events in order
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
