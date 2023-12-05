require 'llx'
local midi_io = require 'midi/io'

-- A re representing a Midi file. A midi file consists of a format, the
-- number of ticks per beat, and a list of tracks filled with midi events.
local MidiFile = class 'MidiFile' {
  __init = function(self)
    self.format = 1
    self.ticks = 92
    self.tracks = List{}
  end;

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
  end
}

return MidiFile