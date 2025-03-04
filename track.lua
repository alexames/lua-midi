-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local llx = require 'llx'
local midi_io = require 'midi.io'
local events = require 'midi.event'

local _ENV, _M = llx.environment.create_module_environment()

local class = llx.class

Track = class 'Track' {
  __init = function(self)
    self.events = llx.List{}
  end,

  _get_track_byte_length = function(self, ticks)
    local length = 0
    local previous_command_byte = 0
    for i, event in self.events do
      -- Time delta
      local time_delta = event.time_delta * ticks
      if time_delta > (0x7f * 0x7f * 0x7f) then
        length = length + 4
      elseif time_delta > (0x7f * 0x7f) then
        length = length + 3
      elseif time_delta > (0x7f) then
        length = length + 2
      else
        length = length + 1
      end

      -- Command
      local commandByte = event.command | event.channel
      if commandByte ~= previous_command_byte or event.command == events.MetaEvent.command then
        length = length + 1
        previous_command_byte = commandByte
      end

      -- One data byte
      if event.command == events.ProgramChangeEvent.command
         or event.command == events.ChannelPressureChangeEvent.command then
        length = length + 1
      -- Two data bytes
      elseif event.command == events.NoteEndEvent.command
             or event.command == events.NoteBeginEvent.command
             or event.command == events.VelocityChangeEvent.command
             or event.command == events.ControllerChangeEvent.command
             or event.command == events.PitchWheelChangeEvent.command then
        length = length + 2
      -- Variable data bytes
      elseif event.command == Meta.meta_command then
        length = length + 2 + event.meta.length
      end
    end
    return length
  end,

  write = function(self, file, ticks)
    file:write('MTrk')
    midi_io.writeUInt32be(file, self:_get_track_byte_length(ticks))
    local context = {previous_command_byte = 0}
    for i, event in ipairs(self.events) do
      event:write(file, context, ticks)
    end
  end,
}

return _M
