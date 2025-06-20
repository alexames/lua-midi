-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local llx = require 'llx'
local midi_io = require 'midi.io'
local midi_track = require 'midi.track'

local _ENV, _M = llx.environment.create_module_environment()

local class = llx.class

-- A class representing a Midi file. A midi file consists of a format, the
-- number of ticks per beat, and a list of tracks filled with midi events.
MidiFile = class 'MidiFile' {
  __init = function(self)
    self.format = 1
    self.ticks = 92
    self.tracks = llx.List{}
  end,

  _read_file = function(file)
    local midi_file = MidiFile()
    assert(file:read(4) == 'MThd')
    assert(midi_io.readUInt32be(file) == 0x00000006)
    midi_file.format = midi_io.readUInt16be(file)
    local tracks_count = midi_io.readUInt16be(file)
    midi_file.ticks = midi_io.readUInt16be(file)
    for i=1, tracks_count do
      table.insert(midi_file.tracks, midi_track.Track.read(file, midi_file.ticks))
    end
    return midi_file
  end,

  read = function(file_or_filename)
    -- print('MidiFile.read')
    if type(file_or_filename) == "string" then
      local file <close> = assert(io.open(file_or_filename, "rb"))
      return MidiFile._read_file(file)
    else
      return MidiFile._read_file(file_or_filename)
    end
  end,

  _write_file = function(self, file)
    file:write('MThd')
    midi_io.writeUInt32be(file, 0x00000006)
    midi_io.writeUInt16be(file, self.format)
    midi_io.writeUInt16be(file, #self.tracks)
    midi_io.writeUInt16be(file, self.ticks)
    for i, track in ipairs(self.tracks) do
      track:write(file, self.ticks)
    end
  end,

  write = function(self, file_or_filename)
    if type(file_or_filename) == "string" then
      local file <close> = assert(io.open(file_or_filename, "wb"))
      self:_write_file(file)
    else
      self:_write_file(file_or_filename)
    end
  end,

  __tostring = function(self)
    return 'TODO'
  end,
}

function tomidifile(value)
  local __tomidifile = llx.getmetafield(value, '__tomidifile')
  return __tomidifile and __tomidifile(value) or nil
end

return _M
