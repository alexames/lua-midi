-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>
--
-- This module defines various MIDI event classes, including both regular MIDI
-- events (e.g. NoteOn, NoteOff, ControlChange) and meta events (e.g. Tempo,
-- Lyrics, EndOfTrack). Events support reading from and writing to binary MIDI
-- files, and are structured with a class hierarchy to handle polymorphic
-- behavior for each event type.

local llx = require 'llx'
local midi_io = require 'midi.io'

local _ENV, _M = llx.environment.create_module_environment()
local class = llx.class

-- TimedEvent: Base class for all MIDI events with a time delta
TimedEvent = class 'TimedEvent' {
  __init = function(self, time_delta)
    self.time_delta = time_delta
  end,

  -- Reads a variable-length time delta from file (7 bits per byte, MSB as continue flag)
  _read_event_time = function(file)
    local time_delta = 0
    repeat
      local byte = midi_io.readUInt8be(file)
      time_delta = (time_delta << 7) + (byte & 0x7F)
    until byte & 0x80 == 0
    return time_delta
  end,

  -- Writes a variable-length time delta to file
  _write_event_time = function(file, time_delta)
    -- Emit continuation bytes as needed (MSB = 1)
    if time_delta > (0x7F * 0x7F * 0x7F) then
      midi_io.writeUInt8be(file, (time_delta >> 21) | 0x80)
    elseif time_delta > (0x7F * 0x7F) then
      midi_io.writeUInt8be(file, (time_delta >> 14) | 0x80)
    elseif time_delta > (0x7F) then
      midi_io.writeUInt8be(file, (time_delta >> 7) | 0x80)
    end
    -- Final byte (MSB = 0)
    midi_io.writeUInt8be(file, time_delta & 0x7F)
  end,

  -- Placeholder for derived read implementations
  read = function(file)
  end,

  -- Default write: only writes time delta
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

  -- Reads an event from file using running status and registered event types
  read = function(file, context)
    local time_delta = TimedEvent._read_event_time(file)
    local command_byte = midi_io.readUInt8be(file)
    local event_byte = nil

    -- Handle System messages (0xF0-0xFF) - these don't use running status
    if command_byte >= 0xF0 then
      local SystemEventType = Event.system_types[command_byte]
      if SystemEventType then
        return SystemEventType.read(file, time_delta)
      else
        error(string.format('Unknown system message: 0x%02X', command_byte))
      end
    end

    -- Handle running status: reuse previous command byte if MSB is not set
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
      -- Read arguments from file according to schema (e.g. note_number, velocity)
      local args = {}
      for _ = 1, #EventType.schema do
        table.insert(args, event_byte or midi_io.readUInt8be(file))
        event_byte = nil
      end
      return EventType(time_delta, channel, table.unpack(args))
    else
      -- Use custom read function if defined
      return EventType.read(file, time_delta, channel, context)
    end
  end,

  -- Writes an event to file, using running status optimization
  write = function(self, file, context)
    TimedEvent._write_event_time(file, self.time_delta)
    local command_byte = self.command | self.channel

    if command_byte ~= context.previous_command_byte or self.command == 0xF0 then
      midi_io.writeUInt8be(file, command_byte)
      context.previous_command_byte = command_byte
    end

    if self.schema then
      for _, field in ipairs(self.schema) do
        local byte = assert(self[field], string.format('No field %s on Event', field))
        midi_io.writeUInt8be(file, byte)
      end
    end
  end,

  -- String representation of the event for debugging/logging
  __tostring = function(self)
    local argument_strings = { self.time_delta, self.channel }
    if self.schema then
      for _, field in ipairs(self.schema) do
        local value = assert(self[field], string.format('No field %s on Event', field))
        table.insert(argument_strings, value)
      end
    end
    return string.format('%s(%s)', self.class.__name, table.concat(argument_strings, ', '))
  end,
}

NoteEndEvent = class 'NoteEndEvent' : extends(Event) {
  __init = function(self, time_delta, channel, note_number, velocity)
    self.Event.__init(self, time_delta, channel)
    self.note_number = note_number
    self.velocity = velocity
  end,
  schema = { 'note_number', 'velocity' },
  command = 0x80,
}

NoteBeginEvent = class 'NoteBeginEvent' : extends(Event) {
  __init = function(self, time_delta, channel, note_number, velocity)
    self.Event.__init(self, time_delta, channel)
    self.note_number = note_number
    self.velocity = velocity
  end,
  schema = { 'note_number', 'velocity' },
  command = 0x90,
}

VelocityChangeEvent = class 'VelocityChangeEvent' : extends(Event) {
  __init = function(self, time_delta, channel, note_number, velocity)
    self.Event.__init(self, time_delta, channel)
    self.note_number = note_number
    self.velocity = velocity
  end,
  schema = { 'note_number', 'velocity' },
  command = 0xA0,
}

ControllerChangeEvent = class 'ControllerChangeEvent' : extends(Event) {
  __init = function(self, time_delta, channel, controller_number, velocity)
    self.Event.__init(self, time_delta, channel)
    self.controller_number = controller_number
    self.velocity = velocity
  end,
  schema = { 'controller_number', 'velocity' },
  command = 0xB0,
}

ProgramChangeEvent = class 'ProgramChangeEvent' : extends(Event) {
  __init = function(self, time_delta, channel, new_program_number)
    self.Event.__init(self, time_delta, channel)
    self.new_program_number = new_program_number
  end,
  schema = { 'new_program_number' },
  command = 0xC0,
}

ChannelPressureChangeEvent = class 'ChannelPressureChangeEvent' : extends(Event) {
  __init = function(self, time_delta, channel, channel_number)
    self.Event.__init(self, time_delta, channel)
    self.channel_number = channel_number
  end,
  schema = { 'channel_number' },
  command = 0xD0,
}

PitchWheelChangeEvent = class 'PitchWheelChangeEvent' : extends(Event) {
  __init = function(self, time_delta, channel, bottom, top)
    self.Event.__init(self, time_delta, channel)
    self.bottom = bottom
    self.top = top
  end,
  schema = { 'bottom', 'top' },
  command = 0xE0,
}

-- System Common Messages
SystemExclusiveEvent = class 'SystemExclusiveEvent' : extends(TimedEvent) {
  __init = function(self, time_delta, data)
    TimedEvent.__init(self, time_delta)
    self.data = data or {}
  end,

  read = function(file, time_delta)
    local data = {}
    local byte = midi_io.readUInt8be(file)
    while byte ~= 0xF7 do
      table.insert(data, byte)
      byte = midi_io.readUInt8be(file)
    end
    return SystemExclusiveEvent(time_delta, data)
  end,

  write = function(self, file)
    TimedEvent._write_event_time(file, self.time_delta)
    midi_io.writeUInt8be(file, 0xF0)
    for _, byte in ipairs(self.data) do
      midi_io.writeUInt8be(file, byte)
    end
    midi_io.writeUInt8be(file, 0xF7)
  end,

  __tostring = function(self)
    return string.format('SystemExclusiveEvent(%d, %d bytes)', self.time_delta, #self.data)
  end,
}

MIDITimeCodeQuarterFrameEvent = class 'MIDITimeCodeQuarterFrameEvent' : extends(TimedEvent) {
  __init = function(self, time_delta, message_type, values)
    TimedEvent.__init(self, time_delta)
    self.message_type = message_type
    self.values = values
  end,

  read = function(file, time_delta)
    local data = midi_io.readUInt8be(file)
    local message_type = (data >> 4) & 0x07
    local values = data & 0x0F
    return MIDITimeCodeQuarterFrameEvent(time_delta, message_type, values)
  end,

  write = function(self, file)
    TimedEvent._write_event_time(file, self.time_delta)
    midi_io.writeUInt8be(file, 0xF1)
    local data = ((self.message_type & 0x07) << 4) | (self.values & 0x0F)
    midi_io.writeUInt8be(file, data)
  end,

  __tostring = function(self)
    return string.format('MIDITimeCodeQuarterFrameEvent(%d, type=%d, values=%d)', 
                         self.time_delta, self.message_type, self.values)
  end,
}

SongPositionPointerEvent = class 'SongPositionPointerEvent' : extends(TimedEvent) {
  __init = function(self, time_delta, position)
    TimedEvent.__init(self, time_delta)
    self.position = position
  end,

  read = function(file, time_delta)
    local lsb = midi_io.readUInt8be(file)
    local msb = midi_io.readUInt8be(file)
    local position = (msb << 7) | lsb
    return SongPositionPointerEvent(time_delta, position)
  end,

  write = function(self, file)
    TimedEvent._write_event_time(file, self.time_delta)
    midi_io.writeUInt8be(file, 0xF2)
    midi_io.writeUInt8be(file, self.position & 0x7F)
    midi_io.writeUInt8be(file, (self.position >> 7) & 0x7F)
  end,

  __tostring = function(self)
    return string.format('SongPositionPointerEvent(%d, position=%d)', self.time_delta, self.position)
  end,
}

SongSelectEvent = class 'SongSelectEvent' : extends(TimedEvent) {
  __init = function(self, time_delta, song_number)
    TimedEvent.__init(self, time_delta)
    self.song_number = song_number
  end,

  read = function(file, time_delta)
    local song_number = midi_io.readUInt8be(file)
    return SongSelectEvent(time_delta, song_number)
  end,

  write = function(self, file)
    TimedEvent._write_event_time(file, self.time_delta)
    midi_io.writeUInt8be(file, 0xF3)
    midi_io.writeUInt8be(file, self.song_number)
  end,

  __tostring = function(self)
    return string.format('SongSelectEvent(%d, song=%d)', self.time_delta, self.song_number)
  end,
}

TuneRequestEvent = class 'TuneRequestEvent' : extends(TimedEvent) {
  __init = function(self, time_delta)
    TimedEvent.__init(self, time_delta)
  end,

  read = function(file, time_delta)
    return TuneRequestEvent(time_delta)
  end,

  write = function(self, file)
    TimedEvent._write_event_time(file, self.time_delta)
    midi_io.writeUInt8be(file, 0xF6)
  end,

  __tostring = function(self)
    return string.format('TuneRequestEvent(%d)', self.time_delta)
  end,
}

-- System Real-Time Messages
TimingClockEvent = class 'TimingClockEvent' : extends(TimedEvent) {
  __init = function(self, time_delta)
    TimedEvent.__init(self, time_delta)
  end,

  read = function(file, time_delta)
    return TimingClockEvent(time_delta)
  end,

  write = function(self, file)
    TimedEvent._write_event_time(file, self.time_delta)
    midi_io.writeUInt8be(file, 0xF8)
  end,

  __tostring = function(self)
    return string.format('TimingClockEvent(%d)', self.time_delta)
  end,
}

StartEvent = class 'StartEvent' : extends(TimedEvent) {
  __init = function(self, time_delta)
    TimedEvent.__init(self, time_delta)
  end,

  read = function(file, time_delta)
    return StartEvent(time_delta)
  end,

  write = function(self, file)
    TimedEvent._write_event_time(file, self.time_delta)
    midi_io.writeUInt8be(file, 0xFA)
  end,

  __tostring = function(self)
    return string.format('StartEvent(%d)', self.time_delta)
  end,
}

ContinueEvent = class 'ContinueEvent' : extends(TimedEvent) {
  __init = function(self, time_delta)
    TimedEvent.__init(self, time_delta)
  end,

  read = function(file, time_delta)
    return ContinueEvent(time_delta)
  end,

  write = function(self, file)
    TimedEvent._write_event_time(file, self.time_delta)
    midi_io.writeUInt8be(file, 0xFB)
  end,

  __tostring = function(self)
    return string.format('ContinueEvent(%d)', self.time_delta)
  end,
}

StopEvent = class 'StopEvent' : extends(TimedEvent) {
  __init = function(self, time_delta)
    TimedEvent.__init(self, time_delta)
  end,

  read = function(file, time_delta)
    return StopEvent(time_delta)
  end,

  write = function(self, file)
    TimedEvent._write_event_time(file, self.time_delta)
    midi_io.writeUInt8be(file, 0xFC)
  end,

  __tostring = function(self)
    return string.format('StopEvent(%d)', self.time_delta)
  end,
}

ActiveSensingEvent = class 'ActiveSensingEvent' : extends(TimedEvent) {
  __init = function(self, time_delta)
    TimedEvent.__init(self, time_delta)
  end,

  read = function(file, time_delta)
    return ActiveSensingEvent(time_delta)
  end,

  write = function(self, file)
    TimedEvent._write_event_time(file, self.time_delta)
    midi_io.writeUInt8be(file, 0xFE)
  end,

  __tostring = function(self)
    return string.format('ActiveSensingEvent(%d)', self.time_delta)
  end,
}

SystemResetEvent = class 'SystemResetEvent' : extends(TimedEvent) {
  __init = function(self, time_delta)
    TimedEvent.__init(self, time_delta)
  end,

  read = function(file, time_delta)
    return SystemResetEvent(time_delta)
  end,

  write = function(self, file)
    TimedEvent._write_event_time(file, self.time_delta)
    midi_io.writeUInt8be(file, 0xFF)
  end,

  __tostring = function(self)
    return string.format('SystemResetEvent(%d)', self.time_delta)
  end,
}

MetaEvent = class 'MetaEvent' : extends(Event) {
  __init = function(self, time_delta, channel, data)
    assert(channel == 0x0F)
    self.Event.__init(self, time_delta, channel)
    self.data = data
  end,

  -- Custom read function for meta events: reads meta type, length, and payload
  read = function(file, time_delta, channel, context)
    local meta_command = midi_io.readUInt8be(file)
    local length = midi_io.readUInt8be(file)
    local data = {}
    for i = 1, length do
      table.insert(data, midi_io.readUInt8be(file))
    end
    local meta_event = MetaEvent.types[meta_command]
    assert(meta_event, string.format('Meta event %02X not recognized', meta_command))
    return meta_event(time_delta, channel, data)
  end,

  -- Write the meta event to file
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

  -- Meta event marker (not standard 0xFF to allow reuse of Event.write)
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

ProgramNameEvent = class 'ProgramNameEvent' : extends(MetaEvent) {
  meta_command = 0x08,
}

DeviceNameEvent = class 'DeviceNameEvent' : extends(MetaEvent) {
  meta_command = 0x09,
}

PrefixAssignmentEvent = class 'PrefixAssignmentEvent' : extends(MetaEvent) {
  meta_command = 0x20,
}

PortChannelPrefixEvent = class 'PortChannelPrefixEvent' : extends(MetaEvent) {
  meta_command = 0x21,
}

EndOfTrackEvent = class 'EndOfTrackEvent' : extends(MetaEvent) {
  meta_command = 0x2F,
}

SetTempoEvent = class 'SetTempoEvent' : extends(MetaEvent) {
  meta_command = 0x51,

  -- Get tempo in microseconds per quarter note
  get_tempo = function(self)
    if #self.data ~= 3 then return nil end
    return (self.data[1] << 16) | (self.data[2] << 8) | self.data[3]
  end,

  -- Set tempo in microseconds per quarter note
  set_tempo = function(self, microseconds_per_quarter)
    self.data = {
      (microseconds_per_quarter >> 16) & 0xFF,
      (microseconds_per_quarter >> 8) & 0xFF,
      microseconds_per_quarter & 0xFF,
    }
  end,

  -- Get tempo in BPM
  get_bpm = function(self)
    local tempo = self:get_tempo()
    if not tempo then return nil end
    return 60000000 / tempo
  end,

  -- Set tempo in BPM
  set_bpm = function(self, bpm)
    self:set_tempo(math.floor(60000000 / bpm))
  end,

  -- Custom tostring to include data array
  __tostring = function(self)
    local argument_strings = { self.time_delta, self.channel }
    if self.data then
      for i = 1, #self.data do
        table.insert(argument_strings, self.data[i])
      end
    end
    return string.format('%s(%s)', self.class.__name, table.concat(argument_strings, ', '))
  end,
}

SMPTEOffsetEvent = class 'SMPTEOffsetEvent' : extends(MetaEvent) {
  meta_command = 0x54,

  -- Get SMPTE offset components
  get_offset = function(self)
    if #self.data ~= 5 then return nil end
    return {
      hours = self.data[1],
      minutes = self.data[2],
      seconds = self.data[3],
      frames = self.data[4],
      fractional_frames = self.data[5],
    }
  end,

  -- Set SMPTE offset components
  set_offset = function(self, hours, minutes, seconds, frames, fractional_frames)
    self.data = { hours, minutes, seconds, frames, fractional_frames or 0 }
  end,
}

TimeSignatureEvent = class 'TimeSignatureEvent' : extends(MetaEvent) {
  meta_command = 0x58,

  -- Get time signature components
  get_time_signature = function(self)
    if #self.data ~= 4 then return nil end
    return {
      numerator = self.data[1],
      denominator = 2 ^ self.data[2],
      clocks_per_metronome_click = self.data[3],
      thirty_seconds_per_quarter = self.data[4],
    }
  end,

  -- Set time signature (e.g., 4/4, 3/4, 6/8)
  set_time_signature = function(self, numerator, denominator, clocks_per_click, thirty_seconds_per_quarter)
    -- Denominator must be a power of 2
    local denominator_power = math.floor(math.log(denominator) / math.log(2))
    self.data = {
      numerator,
      denominator_power,
      clocks_per_click or 24,
      thirty_seconds_per_quarter or 8,
    }
  end,
}

KeySignatureEvent = class 'KeySignatureEvent' : extends(MetaEvent) {
  meta_command = 0x59,

  -- Get key signature components
  get_key_signature = function(self)
    if #self.data ~= 2 then return nil end
    local sharps_flats = self.data[1]
    -- Convert from unsigned to signed
    if sharps_flats > 127 then
      sharps_flats = sharps_flats - 256
    end
    return {
      sharps_flats = sharps_flats,  -- -7 (7 flats) to +7 (7 sharps)
      is_minor = self.data[2] == 1,
    }
  end,

  -- Set key signature
  set_key_signature = function(self, sharps_flats, is_minor)
    -- Convert from signed to unsigned
    local sf = sharps_flats
    if sf < 0 then
      sf = sf + 256
    end
    self.data = { sf, is_minor and 1 or 0 }
  end,
}

SequencerSpecificEvent = class 'SequencerSpecificEvent' : extends(MetaEvent) {
  meta_command = 0x7F,
}

-- Register regular MIDI events by command
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
for _, v in ipairs(event_type_list) do
  event_types[v.command] = v
end

-- Register meta events by meta command
local meta_event_type_list = {
  SetSequenceNumberEvent,
  TextEvent,
  CopywriteEvent,
  SequenceNameEvent,
  TrackInstrumentNameEvent,
  LyricEvent,
  MarkerEvent,
  CueEvent,
  ProgramNameEvent,
  DeviceNameEvent,
  PrefixAssignmentEvent,
  PortChannelPrefixEvent,
  EndOfTrackEvent,
  SetTempoEvent,
  SMPTEOffsetEvent,
  TimeSignatureEvent,
  KeySignatureEvent,
  SequencerSpecificEvent,
}

local meta_event_types = {}
MetaEvent.types = meta_event_types
for _, v in ipairs(meta_event_type_list) do
  meta_event_types[v.meta_command] = v
end

-- Register System Common and System Real-Time messages
local system_event_types = {}
Event.system_types = system_event_types
system_event_types[0xF0] = SystemExclusiveEvent
system_event_types[0xF1] = MIDITimeCodeQuarterFrameEvent
system_event_types[0xF2] = SongPositionPointerEvent
system_event_types[0xF3] = SongSelectEvent
system_event_types[0xF6] = TuneRequestEvent
system_event_types[0xF8] = TimingClockEvent
system_event_types[0xFA] = StartEvent
system_event_types[0xFB] = ContinueEvent
system_event_types[0xFC] = StopEvent
system_event_types[0xFE] = ActiveSensingEvent
system_event_types[0xFF] = SystemResetEvent

return _M

