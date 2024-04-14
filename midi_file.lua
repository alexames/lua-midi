-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local llx = require 'llx'
local midi_io = require 'midi/io'

local _ENV, _M = llx.environment.create_module_environment()

local class = llx.class

-- A re representing a Midi file. A midi file consists of a format, the
-- number of ticks per beat, and a list of tracks filled with midi events.
MidiFile = class 'MidiFile' {
  __init = function(self)
    self.format = 1
    self.ticks = 92
    self.tracks = llx.List{}
  end,

  write = function(self, file)
    if type(file) == "string" then
      file = io.open(file, "w")
    end
    file:write('MThd')
    midi_io.writeUInt32be(file, 0x0006)
    midi_io.writeUInt16be(file, self.format)
    midi_io.writeUInt16be(file, #self.tracks)
    midi_io.writeUInt16be(file, self.ticks)
    for i, track in ipairs(self.tracks) do
      track:write(file, self.ticks)
    end
  end,
}

function tomidifile(value)
  local __tomidifile = llx.getmetafield(value, '__tomidifile')
  return __tomidifile and __tomidifile(value) or nil
end

return _M
