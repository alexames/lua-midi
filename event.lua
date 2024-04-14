-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local llx = require 'llx'
local midi_io = require 'midi/io'

local _ENV, _M = llx.environment.create_module_environment()

local class = llx.class

-- A midi event represents one of many commands a midi file can run. The Event
-- re is a union of all possible events.
-- Only regular events (i.e. not Meta events) are significant to the midi file
-- playback
Event = class 'Event' {
  __init = function(self, time_delta, channel)
    self.time_delta = time_delta
    self.channel = channel
  end,

  _write_event_time = function(self, file, time_delta, ticks)
    time_delta = math.floor(time_delta * ticks)
    if time_delta > (0x7F * 0x7F * 0x7F) then
      midi_io.writeUInt8be(file, (time_delta >> 21) | 0x80)
    elseif time_delta > (0x7F * 0x7F) then
      midi_io.writeUInt8be(file, (time_delta >> 14) | 0x80)
    elseif time_delta > (0x7F) then
      midi_io.writeUInt8be(file, (time_delta >> 7) | 0x80)
    end
    midi_io.writeUInt8be(file, time_delta & 0x7F)
  end,

  write = function(self, file, context, ticks)
    self:_write_event_time(file, self.time_delta, ticks)
    local command_byte = self.command | self.channel
    if command_byte ~= context.previous_command_byte
       or self.command == self.class.Meta then
      midi_io.writeUInt8be(file, command_byte)
      context.previous_command_byte = command_byte
    end
  end,
}

NoteEndEvent = class 'NoteEndEvent' : extends(Event) {
  __init = function(self, time_delta, channel, note_number, velocity)
    self.Event.__init(self, time_delta, channel)
    self.note_number = note_number
    self.velocity = velocity
  end,

  write = function(self, file, context, ticks)
    self.Event.write(self, file, context, ticks)
    midi_io.writeUInt8be(file, self.note_number)
    midi_io.writeUInt8be(file, self.velocity)
  end,

  command = 0x80,
}

NoteBeginEvent = class 'NoteBeginEvent' : extends(Event) {
  __init = function(self, time_delta, channel, note_number, velocity)
    self.Event.__init(self, time_delta, channel)
    self.note_number = note_number
    self.velocity = velocity
  end,

  write = function(self, file, context, ticks)
    self.Event.write(self, file, context, ticks)
    midi_io.writeUInt8be(file, self.note_number)
    midi_io.writeUInt8be(file, self.velocity)
  end,

  command = 0x90,
}

VelocityChangeEvent = class 'VelocityChangeEvent' : extends(Event) {
  __init = function(self, time_delta, channel, note_number, velocity)
    self.Event.__init(self, time_delta, channel)
    self.note_number = note_number
    self.velocity = velocity
  end,

  write = function(self, file, context, ticks)
    self.Event.write(self, file, context, ticks)
    midi_io.writeUInt8be(file, self.note_number)
    midi_io.writeUInt8be(file, self.velocity)
  end,

  command = 0xA0,
}

ControllerChangeEvent = class 'ControllerChangeEvent' : extends(Event) {
  __init = function(self, time_delta, channel, controller_number, velocity)
    self.Event.__init(self, time_delta, channel)
    self.controller_number = controller_number
    self.velocity = velocity
  end,

  write = function(self, file, context, ticks)
    self.Event.write(self, file, context, ticks)
    midi_io.writeUInt8be(file, self.controller_number)
    midi_io.writeUInt8be(file, self.velocity)
  end,

  command = 0xB0,
}

ProgramChangeEvent = class 'ProgramChangeEvent' : extends(Event) {
  __init = function(self, time_delta, channel, new_program_number)
    self.Event.__init(self, time_delta, channel)
    self.new_program_number = new_program_number
  end,

  write = function(self, file, context, ticks)
    self.Event.write(self, file, context, ticks)
    midi_io.writeUInt8be(file, self.new_program_number)
  end,

  command = 0xC0,
}

ChannelPressureChangeEvent = class 'ChannelPressureChangeEvent' : extends(Event) {
  __init = function(self, time_delta, channel, channel_number)
    self.Event.__init(self, time_delta, channel)
    self.channel_number = channel_number
  end,

  write = function(self, file, context, ticks)
    self.Event.write(self, file, context, ticks)
    midi_io.writeUInt8be(file, self.channel_number)
  end,

  command = 0xD0,
}

PitchWheelChangeEvent = class 'PitchWheelChangeEvent' : extends(Event) {
  __init = function(self, time_delta, channel, bottom, top)
    self.Event.__init(self, time_delta, channel)
    self.bottom = bottom
    self.top = top
  end,

  write = function(self, file, context, ticks)
    self.Event.write(self, file, context, ticks)
    midi_io.writeUInt8be(file, self.bottom)
    midi_io.writeUInt8be(file, self.top)
  end,

  command = 0xE0,
}

MetaEvent = class 'MetaEvent' : extends(Event) {
  __init = function(self, time_delta, channel)
    self.Event.__init(self, time_delta, channel)
  end,

  write = function(self, file, context, ticks)
    self.Event.write(self, file, context, ticks)
    midi_io.writeUInt8be(file, self.meta_command)
    midi_io.writeUInt8be(file, self.length)
  end,

  command = 0xFF,
}

SetSequenceNumberEvent = class 'SetSequenceNumberEvent' : extends(MetaEvent) {
  meta_command = 0x00,
}

TextEvent = class 'TextEvent' : extends(MetaEvent) {
  meta_command = 0x01,
}

CopywriteEvent = class 'CopywriteEvent' : extends(MetaEvent) {
  meta_command = 0x02,
}

SequnceNameEvent = class 'SequnceNameEvent' : extends(MetaEvent) {
  meta_command = 0x03,
}

TrackInstrumentNameEvent = class 'TrackInstrumentNameEvent' : extends(MetaEvent) {
  meta_command = 0x04,
}

LyricEvent = class 'LyricEvent' : extends(MetaEvent) {
  meta_command = 0x05,
}

MarkerEvent = class 'MarkerEvent' : extends(MetaEvent) {
  meta_command = 0x06,
}

CueEvent = class 'CueEvent' : extends(MetaEvent) {
  meta_command = 0x07,
}

PrefixAssignmentEvent = class 'PrefixAssignmentEvent' : extends(MetaEvent) {
  meta_command = 0x20,
}

EndOfTrackEvent = class 'EndOfTrackEvent' : extends(MetaEvent) {
  meta_command = 0x2F,
}

SetTempoEvent = class 'SetTempoEvent' : extends(MetaEvent) {
  meta_command = 0x51,
}

SMPTEOffsetEvent = class 'SMPTEOffsetEvent' : extends(MetaEvent) {
  meta_command = 0x54,
}

TimeSignatureEvent = class 'TimeSignatureEvent' : extends(MetaEvent) {
  meta_command = 0x58,
}

KeySignatureEvent = class 'KeySignatureEvent' : extends(MetaEvent) {
  meta_command = 0x59,
}

SequencerSpecificEvent = class 'SequencerSpecificEvent' : extends(MetaEvent) {
  meta_command = 0x7F,
}

return _M
