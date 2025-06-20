-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local llx = require 'llx'
local midi_io = require 'midi.io'
local midi_event = require 'midi.event'

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
      if commandByte ~= previous_command_byte or event.command == midi_event.MetaEvent.command then
        length = length + 1
        previous_command_byte = commandByte
      end

      -- One data byte
      if event.command == midi_event.ProgramChangeEvent.command
         or event.command == midi_event.ChannelPressureChangeEvent.command then
        length = length + 1
      -- Two data bytes
      elseif event.command == midi_event.NoteEndEvent.command
             or event.command == midi_event.NoteBeginEvent.command
             or event.command == midi_event.VelocityChangeEvent.command
             or event.command == midi_event.ControllerChangeEvent.command
             or event.command == midi_event.PitchWheelChangeEvent.command then
        length = length + 2
      -- Variable data bytes
      elseif event.command == midi_event.MetaEvent.command then
        length = length + 2 + #event.data
      end
    end
    return length
  end,

  read = function(file, ticks)
    -- print('Track.read')
    local track = Track()
    assert(file:read(4) == 'MTrk')
    local track_byte_length = midi_io.readUInt32be(file)
    local context = {previous_command_byte = 0}
    local end_of_track = file:seek() + track_byte_length
    while file:seek() ~= end_of_track do
      assert(file:seek() < end_of_track, 
             ('Read too many bytes for track (got %i, expected %i)'):format(
                 file:seek(), end_of_track))
      table.insert(track.events, midi_event.Event.read(file, context, ticks))
    end
    return track
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
