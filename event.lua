-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local llx = require 'llx'
local midi_io = require 'midi.io'

local _ENV, _M = llx.environment.create_module_environment()

local class = llx.class

TimedEvent = class 'TimedEvent' {
  __init = function(self, time_delta)
    self.time_delta = time_delta
  end,

  _read_event_time = function(file)
    local time_delta = 0
    repeat
      local byte = midi_io.readUInt8be(file)
      time_delta = (time_delta << 7) + (byte & 0x7F)
    until byte & 0x80 == 0
    return time_delta
  end,

  _write_event_time = function(file, time_delta)
    if time_delta > (0x7F * 0x7F * 0x7F) then
      midi_io.writeUInt8be(file, (time_delta >> 21) | 0x80)
    elseif time_delta > (0x7F * 0x7F) then
      midi_io.writeUInt8be(file, (time_delta >> 14) | 0x80)
    elseif time_delta > (0x7F) then
      midi_io.writeUInt8be(file, (time_delta >> 7) | 0x80)
    end
    midi_io.writeUInt8be(file, time_delta & 0x7F)
  end,

  read = function(file)
    
  end,

  write = function(self, file)
    TimedEvent._write_event_time(file, self.time_delta)
  end,
}

-- A midi event represents one of many commands a midi file can run.
-- Only regular events (i.e. not Meta events) are significant to the midi file
-- playback
Event = class 'Event' {
  __init = function(self, time_delta, channel)
    TimedEvent.__init(self, time_delta)
    self.channel = channel
  end,

  read = function(file, context)
    local time_delta = TimedEvent._read_event_time(file)
    local command_byte = midi_io.readUInt8be(file)
    local event_byte = nil
    if command_byte < 0x80 then
      event_byte = command_byte
      command_byte = context.previous_command_byte
    else
      context.previous_command_byte = command_byte
    end
    local channel = command_byte & 0x0F
    local command = command_byte & 0xF0
    local EventType = Event.types[command]
    if EventType.schema then
      local args = {}
      for _=1, #EventType.schema do
        table.insert(args, event_byte or midi_io.readUInt8be(file))
        event_byte = nil
      end
      return EventType(time_delta, channel, table.unpack(args))
    else
      return EventType.read(file, time_delta, channel, context)
    end
  end,

  write = function(self, file, context)
    TimedEvent._write_event_time(file, self.time_delta)
    local command_byte = self.command | self.channel
    if command_byte ~= context.previous_command_byte
       or self.command == 0xF0 then
      midi_io.writeUInt8be(file, command_byte)
      context.previous_command_byte = command_byte
    end
    if self.schema then
      for _, field in ipairs(self.schema) do
        local byte = assert(self[field],
                            string.format('No field %s on Event', field))
        midi_io.writeUInt8be(file, byte)
      end
    end
  end,

  __tostring = function(self)
    local argument_strings = {
      self.time_delta,
      self.channel
    }
    if self.schema then
      for _, field in ipairs(self.schema) do
        local arguement = assert(self[field], string.format('No field %s on Event', field))
        table.insert(argument_strings, arguement)
      end
    end
    return string.format(
      '%s(%s)', self.class.__name, table.concat(argument_strings, ', '))
  end,
}

NoteEndEvent = class 'NoteEndEvent' : extends(Event) {
  __init = function(self, time_delta, channel, note_number, velocity)
    self.Event.__init(self, time_delta, channel)
    self.note_number = note_number
    self.velocity = velocity
  end,

  schema = {
    'note_number',
    'velocity',
  },

  command = 0x80,
}

NoteBeginEvent = class 'NoteBeginEvent' : extends(Event) {
  __init = function(self, time_delta, channel, note_number, velocity)
    self.Event.__init(self, time_delta, channel)
    self.note_number = note_number
    self.velocity = velocity
  end,

  schema = {
    'note_number',
    'velocity',
  },

  command = 0x90,
}

VelocityChangeEvent = class 'VelocityChangeEvent' : extends(Event) {
  __init = function(self, time_delta, channel, note_number, velocity)
    self.Event.__init(self, time_delta, channel)
    self.note_number = note_number
    self.velocity = velocity
  end,

  schema = {
    'note_number',
    'velocity',
  },

  command = 0xA0,
}

ControllerChangeEvent = class 'ControllerChangeEvent' : extends(Event) {
  __init = function(self, time_delta, channel, controller_number, velocity)
    self.Event.__init(self, time_delta, channel)
    self.controller_number = controller_number
    self.velocity = velocity
  end,

  schema = {
    'controller_number',
    'velocity',
  },

  command = 0xB0,
}

ProgramChangeEvent = class 'ProgramChangeEvent' : extends(Event) {
  __init = function(self, time_delta, channel, new_program_number)
    self.Event.__init(self, time_delta, channel)
    self.new_program_number = new_program_number
  end,

  schema = {
    'new_program_number',
  },

  command = 0xC0,
}

ChannelPressureChangeEvent = class 'ChannelPressureChangeEvent' : extends(Event) {
  __init = function(self, time_delta, channel, channel_number)
    self.Event.__init(self, time_delta, channel)
    self.channel_number = channel_number
  end,

  schema = {
    'channel_number',
  },

  command = 0xD0,
}

PitchWheelChangeEvent = class 'PitchWheelChangeEvent' : extends(Event) {
  __init = function(self, time_delta, channel, bottom, top)
    self.Event.__init(self, time_delta, channel)
    self.bottom = bottom
    self.top = top
  end,

  schema = {
    'bottom',
    'top',
  },

  command = 0xE0,
}

MetaEvent = class 'MetaEvent' : extends(Event) {
  __init = function(self, time_delta, channel, data)
    self.Event.__init(self, time_delta, channel)
    self.data = data
  end,

  read = function(file, time_delta, channel, context)
    local meta_command = midi_io.readUInt8be(file)
    local length = midi_io.readUInt8be(file)
    local data = {}
    for i=1, length do
      table.insert(data, midi_io.readUInt8be(file))
    end
    local meta_event = MetaEvent.types[meta_command]
    assert(meta_event,
           string.format('Meta event %02X not recognized', meta_command))
    return meta_event(time_delta, channel, data)
  end,

  write = function(self, file, context)
    self.Event.write(self, file, context)
    midi_io.writeUInt8be(file, self.meta_command)
    local data = self.data
    midi_io.writeUInt8be(file, #data)
    for i=1, #data do
      midi_io.writeUInt8be(file, data[i])
    end
  end,

  __tostring = Event.__tostring,

  -- command = 0xFF,
  command = 0xF0,
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

SequenceNameEvent = class 'SequenceNameEvent' : extends(MetaEvent) {
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

local event_type_list = {
  NoteEndEvent,
  NoteBeginEvent,
  VelocityChangeEvent,
  ControllerChangeEvent,
  ProgramChangeEvent,
  ChannelPressureChangeEvent,
  PitchWheelChangeEvent,
  MetaEvent,
}

local event_types = {}
Event.types = event_types
for i, v in ipairs(event_type_list) do
  event_types[v.command] = v
end

local meta_event_type_list = {
  SetSequenceNumberEvent,
  TextEvent,
  CopywriteEvent,
  SequenceNameEvent,
  TrackInstrumentNameEvent,
  LyricEvent,
  MarkerEvent,
  CueEvent,
  PrefixAssignmentEvent,
  EndOfTrackEvent,
  SetTempoEvent,
  SMPTEOffsetEvent,
  TimeSignatureEvent,
  KeySignatureEvent,
  SequencerSpecificEvent,
}

local meta_event_types = {}
MetaEvent.types = meta_event_types
for i, v in ipairs(meta_event_type_list) do
  meta_event_types[v.meta_command] = v
end

return _M
