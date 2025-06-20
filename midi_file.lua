-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>
--
-- This module defines a `MidiFile` class for reading and writing MIDI files.
-- A MIDI file consists of a header (format, ticks per beat) and a list of tracks.
-- Each track contains MIDI events, such as notes, control changes, and metadata.

local llx = require 'llx'
local midi_io = require 'midi.io'
local midi_track = require 'midi.track'

local _ENV, _M = llx.environment.create_module_environment()
local class = llx.class

--- MidiFile class
-- @field format Format type (0, 1, or 2)
-- @field ticks Number of ticks per beat
-- @field tracks List of midi_track.Track objects
MidiFile = class 'MidiFile' {
  --- Constructor
  -- Accepts either positional arguments (format, ticks, tracks)
  -- or a single table with keys {format=, ticks=, tracks=}
  __init = function(self, args_or_format, ticks, tracks)
    if type(args_or_format) == 'table' then
      self.format = args_or_format.format or 1
      self.ticks = args_or_format.ticks or 92
      self.tracks = args_or_format.tracks or llx.List{}
    else
      self.format = args_or_format or 1
      self.ticks = ticks or 92
      self.tracks = tracks or llx.List{}
    end
  end,

  --- Internal function to read a MidiFile from an open file handle
  _read_file = function(file)
    local midi_file = MidiFile()
    assert(file:read(4) == 'MThd', 'Invalid MIDI file header')
    assert(midi_io.readUInt32be(file) == 0x00000006, 'Invalid MIDI header length')
    midi_file.format = midi_io.readUInt16be(file)
    local tracks_count = midi_io.readUInt16be(file)
    midi_file.ticks = midi_io.readUInt16be(file)
    for i=1, tracks_count do
      table.insert(midi_file.tracks, midi_track.Track.read(file))
    end
    return midi_file
  end,

  --- Public function to read a MidiFile from a filename or file handle
  read = function(file_or_filename)
    if type(file_or_filename) == 'string' then
      local file <close> = assert(io.open(file_or_filename, 'rb'))
      return MidiFile._read_file(file)
    else
      return MidiFile._read_file(file_or_filename)
    end
  end,

  --- Internal function to write a MidiFile to an open file handle
  _write_file = function(self, file)
    file:write('MThd')
    midi_io.writeUInt32be(file, 0x00000006)
    midi_io.writeUInt16be(file, self.format)
    midi_io.writeUInt16be(file, #self.tracks)
    midi_io.writeUInt16be(file, self.ticks)
    for _, track in ipairs(self.tracks) do
      track:write(file)
    end
  end,

  --- Public function to write a MidiFile to a filename or file handle
  write = function(self, file_or_filename)
    if type(file_or_filename) == 'string' then
      local file <close> = assert(io.open(file_or_filename, 'wb'))
      self:_write_file(file)
    else
      self:_write_file(file_or_filename)
    end
  end,

  --- Returns a human-readable representation of the MIDI file
  __tostring = function(self)
    local tracks_strings = {}
    for i, track in ipairs(self.tracks) do
      tracks_strings[i] = tostring(track)
    end
    return string.format(
      'MidiFile{format=%d, ticks=%d, tracks={%s}}',
      self.format, self.ticks, table.concat(tracks_strings, ', '))
  end,

  --- Returns the binary contents of the MIDI file as a Lua string
  __tobytes = function(self)
    local buffer = {}
    local file = {
      write = function(_, s) table.insert(buffer, s) end
    }
    self:_write_file(file)
    return table.concat(buffer)
  end,
}

--- Type coercion function
-- Returns a MidiFile if the object has a __tomidifile metamethod
function tomidifile(value)
  local __tomidifile = llx.getmetafield(value, '__tomidifile')
  return __tomidifile and __tomidifile(value) or nil
end

return _M
