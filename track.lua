require 'llx'
local midi_io = require 'midi/io'
local events = require 'midi/events'

local Track = class 'Track' {
  __init = function(self)
    self.events = List{}
  end;

  _getTrackByteLength = function(self, ticks)
    local length = 0
    local previousCommandByte = 0
    for event in self.events:ivalues() do
      -- Time delta
      local timeDelta = event.timeDelta * 92
      if timeDelta > (0x7f * 0x7f * 0x7f) then
        length = length + 4
      elseif timeDelta > (0x7f * 0x7f) then
        length = length + 3
      elseif timeDelta > (0x7f) then
        length = length + 2
      else
        length = length + 1
      end

      -- Command
      local commandByte = event.command | event.channel
      if commandByte ~= previousCommandByte or event.command == events.MetaEvent.command then
        length = length + 1
        previousCommandByte = commandByte
      end

      -- One data byte
      if event.command == events.ProgramChangeEvent.command then
      elseif event.command == events.ChannelPressureChangeEvent.command then
        length = length + 1
      -- Two data bytes
      elseif event.command == events.NoteEndEvent.command
             or event.command == events.NoteBeginEvent.command
             or event.command == events.VelocityChangeEvent.command
             or event.command == events.ControllerChangeEvent.command
             or event.command == events.PitchWheelChangeEvent.command then
        length = length + 2
      -- Variable data bytes
      elseif event.command == Meta.command then
        length = length + 2 + event.meta.length
      end
    end
    return length
  end;

  write = function(self, file, ticks)
    file:write('MTrk')
    midi_io.writeUInt32be(file, self:_getTrackByteLength())
    local context = {previousCommandByte = 0}
    for event in self.events:ivalues() do
      event:write(file, context, ticks)
    end
  end;
}

return Track