--- MIDI Event Module.
-- This module defines various MIDI event classes, including both regular MIDI
-- events (e.g. NoteOn, NoteOff, ControlChange) and meta events (e.g. Tempo,
-- Lyrics, EndOfTrack). Events support reading from and writing to binary MIDI
-- files, and are structured with a class hierarchy to handle polymorphic
-- behavior for each event type.
--
-- Event hierarchy:
--
-- * TimedEvent - Base class with delta time
--   * Event - Channel voice messages (note on/off, control change, etc.)
--     * NoteBeginEvent - Note on (0x90)
--     * NoteEndEvent - Note off (0x80)
--     * VelocityChangeEvent - Polyphonic aftertouch (0xA0)
--     * ControllerChangeEvent - Control change (0xB0)
--     * ProgramChangeEvent - Program change (0xC0)
--     * ChannelPressureChangeEvent - Channel aftertouch (0xD0)
--     * PitchWheelChangeEvent - Pitch bend (0xE0)
--     * MetaEvent - Meta events (0xFF)
--       * SetTempoEvent, TimeSignatureEvent, KeySignatureEvent, etc.
--   * SystemExclusiveEvent - SysEx messages (0xF0)
--   * System real-time messages (0xF8-0xFF)
--
-- @module midi.event
-- @copyright 2024 Alexander Ames
-- @license MIT
-- @usage
-- local event = require 'lua-midi.event'
--
-- -- Create a note on event at time 0, channel 0, note 60 (C4), velocity 100
-- local note_on = event.NoteBeginEvent(0, 0, 60, 100)
--
-- -- Create a note off event 480 ticks later
-- local note_off = event.NoteEndEvent(480, 0, 60, 0)

local llx = require 'llx'
local midi_io = require 'lua-midi.io'

local _ENV, _M = llx.environment.create_module_environment()
local class = llx.class

--- TimedEvent: Base class for all MIDI events with a time delta.
-- @type TimedEvent
-- @field time_delta number Delta time in ticks since the previous event
TimedEvent = class 'TimedEvent' {
  --- Create a new TimedEvent.
  -- @function TimedEvent:__init
  -- @param time_delta number Delta time in ticks since the previous event
  __init = function(self, time_delta)
    self.time_delta = time_delta
  end,

  --- Read a variable-length time delta from file.
  -- MIDI uses 7 bits per byte with MSB as continuation flag.
  -- @param file file Binary input file handle
  -- @return number Time delta value
  -- @local
  _read_event_time = function(file)
    local time_delta = 0
    repeat
      local byte = midi_io.readUInt8be(file)
      time_delta = (time_delta << 7) + (byte & 0x7F)
    until byte & 0x80 == 0
    return time_delta
  end,

  --- Write a variable-length time delta to file.
  -- @param file file Binary output file handle
  -- @param time_delta number Time delta value to write
  -- @local
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

  --- Read an event from file (placeholder for derived classes).
  -- @param file file Binary input file handle
  -- @local
  read = function(file)
  end,

  --- Write the event to file (default: only writes time delta).
  -- @function TimedEvent:write
  -- @param file file Binary output file handle
  write = function(self, file)
    TimedEvent._write_event_time(file, self.time_delta)
  end,
}

--- Event: Base class for channel voice messages.
-- Channel voice messages include note on/off, control changes, program changes, etc.
-- Each event has a channel (0-15) and a command byte that identifies the event type.
-- @type Event
-- @field time_delta number Delta time in ticks since the previous event
-- @field channel number MIDI channel (0-15)
-- @field command number Command byte (0x80-0xF0)
Event = class 'Event' {
  --- Create a new Event.
  -- @function Event:__init
  -- @param time_delta number Delta time in ticks since the previous event
  -- @param channel number MIDI channel (0-15)
  __init = function(self, time_delta, channel)
    TimedEvent.__init(self, time_delta)
    self.channel = channel
  end,

  --- Read an event from file using running status and registered event types.
  -- @param file file Binary input file handle
  -- @param context table Context with previous_command_byte for running status
  -- @return Event The parsed event
  read = function(file, context)
    local time_delta = TimedEvent._read_event_time(file)
    local command_byte = midi_io.readUInt8be(file)
    local event_byte = nil

    -- Handle 0xFF (Meta Event) - special case for MIDI files
    -- In MIDI files, 0xFF indicates a meta event, not system reset
    if command_byte == 0xFF then
      return MetaEvent.read(file, time_delta, 0x0F, context)
    end

    -- Handle System messages (0xF0-0xFE) - these don't use running status
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
    assert(EventType, string.format('Unknown event command: 0x%02X', command))

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

  --- Write an event to file, using running status optimization.
  -- @function Event:write
  -- @param file file Binary output file handle
  -- @param context table Context with previous_command_byte for running status
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

  --- String representation of the event for debugging/logging.
  -- @return string Human-readable event representation
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

--- Note Off event (0x80).
-- Signals the end of a note.
-- @type NoteEndEvent
-- @field time_delta number Delta time in ticks
-- @field channel number MIDI channel (0-15)
-- @field note_number number MIDI note number (0-127, 60 = middle C)
-- @field velocity number Release velocity (0-127)
NoteEndEvent = class 'NoteEndEvent' : extends(Event) {
  --- Create a new NoteEndEvent.
  -- @function NoteEndEvent:__init
  -- @param time_delta number Delta time in ticks
  -- @param channel number MIDI channel (0-15)
  -- @param note_number number MIDI note number (0-127)
  -- @param velocity number Release velocity (0-127)
  __init = function(self, time_delta, channel, note_number, velocity)
    self.Event.__init(self, time_delta, channel)
    self.note_number = note_number
    self.velocity = velocity
  end,
  schema = { 'note_number', 'velocity' },
  command = 0x80,
}

--- Note On event (0x90).
-- Signals the start of a note. A velocity of 0 is often used as note off.
-- @type NoteBeginEvent
-- @field time_delta number Delta time in ticks
-- @field channel number MIDI channel (0-15)
-- @field note_number number MIDI note number (0-127, 60 = middle C)
-- @field velocity number Attack velocity (0-127, 0 = note off)
NoteBeginEvent = class 'NoteBeginEvent' : extends(Event) {
  --- Create a new NoteBeginEvent.
  -- @function NoteBeginEvent:__init
  -- @param time_delta number Delta time in ticks
  -- @param channel number MIDI channel (0-15)
  -- @param note_number number MIDI note number (0-127)
  -- @param velocity number Attack velocity (0-127)
  __init = function(self, time_delta, channel, note_number, velocity)
    self.Event.__init(self, time_delta, channel)
    self.note_number = note_number
    self.velocity = velocity
  end,
  schema = { 'note_number', 'velocity' },
  command = 0x90,
}

--- Polyphonic Key Pressure (Aftertouch) event (0xA0).
-- Pressure applied to an individual note after it's been struck.
-- @type VelocityChangeEvent
-- @field time_delta number Delta time in ticks
-- @field channel number MIDI channel (0-15)
-- @field note_number number MIDI note number (0-127)
-- @field velocity number Pressure value (0-127)
VelocityChangeEvent = class 'VelocityChangeEvent' : extends(Event) {
  --- Create a new VelocityChangeEvent.
  -- @function VelocityChangeEvent:__init
  -- @param time_delta number Delta time in ticks
  -- @param channel number MIDI channel (0-15)
  -- @param note_number number MIDI note number (0-127)
  -- @param velocity number Pressure value (0-127)
  __init = function(self, time_delta, channel, note_number, velocity)
    self.Event.__init(self, time_delta, channel)
    self.note_number = note_number
    self.velocity = velocity
  end,
  schema = { 'note_number', 'velocity' },
  command = 0xA0,
}

--- Control Change event (0xB0).
-- Changes a controller value (e.g., modulation wheel, sustain pedal).
-- @type ControllerChangeEvent
-- @field time_delta number Delta time in ticks
-- @field channel number MIDI channel (0-15)
-- @field controller_number number Controller number (0-127)
-- @field velocity number Controller value (0-127)
ControllerChangeEvent = class 'ControllerChangeEvent' : extends(Event) {
  --- Create a new ControllerChangeEvent.
  -- @function ControllerChangeEvent:__init
  -- @param time_delta number Delta time in ticks
  -- @param channel number MIDI channel (0-15)
  -- @param controller_number number Controller number (0-127)
  -- @param velocity number Controller value (0-127)
  __init = function(self, time_delta, channel, controller_number, velocity)
    self.Event.__init(self, time_delta, channel)
    self.controller_number = controller_number
    self.velocity = velocity
  end,
  schema = { 'controller_number', 'velocity' },
  command = 0xB0,
}

--- Program Change event (0xC0).
-- Changes the instrument/patch on a channel.
-- @type ProgramChangeEvent
-- @field time_delta number Delta time in ticks
-- @field channel number MIDI channel (0-15)
-- @field new_program_number number Program/patch number (0-127)
ProgramChangeEvent = class 'ProgramChangeEvent' : extends(Event) {
  --- Create a new ProgramChangeEvent.
  -- @function ProgramChangeEvent:__init
  -- @param time_delta number Delta time in ticks
  -- @param channel number MIDI channel (0-15)
  -- @param new_program_number number Program/patch number (0-127)
  __init = function(self, time_delta, channel, new_program_number)
    self.Event.__init(self, time_delta, channel)
    self.new_program_number = new_program_number
  end,
  schema = { 'new_program_number' },
  command = 0xC0,
}

--- Channel Pressure (Aftertouch) event (0xD0).
-- Pressure applied to all notes on a channel.
-- @type ChannelPressureChangeEvent
-- @field time_delta number Delta time in ticks
-- @field channel number MIDI channel (0-15)
-- @field channel_number number Pressure value (0-127)
ChannelPressureChangeEvent = class 'ChannelPressureChangeEvent' : extends(Event) {
  --- Create a new ChannelPressureChangeEvent.
  -- @function ChannelPressureChangeEvent:__init
  -- @param time_delta number Delta time in ticks
  -- @param channel number MIDI channel (0-15)
  -- @param channel_number number Pressure value (0-127)
  __init = function(self, time_delta, channel, channel_number)
    self.Event.__init(self, time_delta, channel)
    self.channel_number = channel_number
  end,
  schema = { 'channel_number' },
  command = 0xD0,
}

--- Pitch Bend event (0xE0).
-- Changes the pitch of all notes on a channel.
-- @type PitchWheelChangeEvent
-- @field time_delta number Delta time in ticks
-- @field channel number MIDI channel (0-15)
-- @field bottom number LSB of pitch bend value (0-127)
-- @field top number MSB of pitch bend value (0-127)
PitchWheelChangeEvent = class 'PitchWheelChangeEvent' : extends(Event) {
  --- Create a new PitchWheelChangeEvent.
  -- @function PitchWheelChangeEvent:__init
  -- @param time_delta number Delta time in ticks
  -- @param channel number MIDI channel (0-15)
  -- @param bottom number LSB of pitch bend value (0-127)
  -- @param top number MSB of pitch bend value (0-127)
  __init = function(self, time_delta, channel, bottom, top)
    self.Event.__init(self, time_delta, channel)
    self.bottom = bottom
    self.top = top
  end,
  schema = { 'bottom', 'top' },
  command = 0xE0,
}

--- System Exclusive (SysEx) event (0xF0).
-- Manufacturer-specific data messages.
-- @type SystemExclusiveEvent
-- @field time_delta number Delta time in ticks
-- @field data table Array of data bytes
SystemExclusiveEvent = class 'SystemExclusiveEvent' : extends(TimedEvent) {
  --- Create a new SystemExclusiveEvent.
  -- @function SystemExclusiveEvent:__init
  -- @param time_delta number Delta time in ticks
  -- @param data table Array of data bytes (excluding 0xF0 and 0xF7)
  __init = function(self, time_delta, data)
    TimedEvent.__init(self, time_delta)
    self.data = data or {}
  end,

  --- Read a SysEx event from file.
  -- @param file file Binary input file handle
  -- @param time_delta number Delta time already read
  -- @return SystemExclusiveEvent The parsed event
  read = function(file, time_delta)
    local data = {}
    local byte = midi_io.readUInt8be(file)
    while byte ~= 0xF7 do
      table.insert(data, byte)
      byte = midi_io.readUInt8be(file)
    end
    return SystemExclusiveEvent(time_delta, data)
  end,

  --- Write a SysEx event to file.
  -- @function SystemExclusiveEvent:write
  -- @param file file Binary output file handle
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

--- MIDI Time Code Quarter Frame event (0xF1).
-- Used for synchronization with SMPTE time code.
-- @type MIDITimeCodeQuarterFrameEvent
-- @field time_delta number Delta time in ticks
-- @field message_type number Message type (0-7)
-- @field values number Values (0-15)
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

--- Song Position Pointer event (0xF2).
-- Indicates the position in the song to start playback.
-- @type SongPositionPointerEvent
-- @field time_delta number Delta time in ticks
-- @field position number Position in MIDI beats (14-bit value)
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

--- Song Select event (0xF3).
-- Selects a song/sequence to play.
-- @type SongSelectEvent
-- @field time_delta number Delta time in ticks
-- @field song_number number Song number (0-127)
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

--- Tune Request event (0xF6).
-- Requests that analog synthesizers tune their oscillators.
-- @type TuneRequestEvent
-- @field time_delta number Delta time in ticks
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

--- Timing Clock event (0xF8).
-- Sent 24 times per quarter note for synchronization.
-- @type TimingClockEvent
-- @field time_delta number Delta time in ticks
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

--- Start event (0xFA).
-- Starts playback from the beginning of the song.
-- @type StartEvent
-- @field time_delta number Delta time in ticks
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

--- Continue event (0xFB).
-- Resumes playback from the current position.
-- @type ContinueEvent
-- @field time_delta number Delta time in ticks
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

--- Stop event (0xFC).
-- Stops playback.
-- @type StopEvent
-- @field time_delta number Delta time in ticks
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

--- Active Sensing event (0xFE).
-- Sent periodically to indicate the connection is active.
-- @type ActiveSensingEvent
-- @field time_delta number Delta time in ticks
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

--- System Reset event (0xFF as real-time, not in files).
-- Resets all devices to power-on state.
-- Note: In MIDI files, 0xFF indicates a meta event, not system reset.
-- @type SystemResetEvent
-- @field time_delta number Delta time in ticks
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

--- Meta Event base class (0xFF).
-- Meta events contain non-MIDI data such as tempo, time signature, lyrics, etc.
-- They are only meaningful within MIDI files, not for real-time playback.
-- @type MetaEvent
-- @field time_delta number Delta time in ticks
-- @field channel number Always 0x0F for meta events
-- @field data table Event-specific data bytes
-- @field meta_command number Meta event type identifier
MetaEvent = class 'MetaEvent' : extends(Event) {
  --- Create a new MetaEvent.
  -- @function MetaEvent:__init
  -- @param time_delta number Delta time in ticks
  -- @param channel number Must be 0x0F
  -- @param data table Event data bytes
  __init = function(self, time_delta, channel, data)
    assert(channel == 0x0F)
    self.Event.__init(self, time_delta, channel)
    self.data = data
  end,

  --- Read a meta event from file.
  -- @param file file Binary input file handle
  -- @param time_delta number Delta time already read
  -- @param channel number Channel (should be 0x0F)
  -- @param context table Read context
  -- @return MetaEvent The parsed meta event
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

  --- Write the meta event to file.
  -- @function MetaEvent:write
  -- @param file file Binary output file handle
  -- @param context table Write context
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

--- Sequence Number meta event (0x00).
-- Optional event at the beginning of a track.
-- @type SetSequenceNumberEvent
SetSequenceNumberEvent = class 'SetSequenceNumberEvent' : extends(MetaEvent) {
  meta_command = 0x00,
}

--- Text meta event (0x01).
-- General-purpose text annotation.
-- @type TextEvent
TextEvent = class 'TextEvent' : extends(MetaEvent) {
  meta_command = 0x01,
}

--- Copyright meta event (0x02).
-- Copyright notice for the MIDI file.
-- @type CopywriteEvent
CopywriteEvent = class 'CopywriteEvent' : extends(MetaEvent) {
  meta_command = 0x02,
}

--- Sequence/Track Name meta event (0x03).
-- Name of the sequence or track.
-- @type SequenceNameEvent
SequenceNameEvent = class 'SequenceNameEvent' : extends(MetaEvent) {
  meta_command = 0x03,
}

--- Instrument Name meta event (0x04).
-- Name of the instrument used in the track.
-- @type TrackInstrumentNameEvent
TrackInstrumentNameEvent = class 'TrackInstrumentNameEvent' : extends(MetaEvent) {
  meta_command = 0x04,
}

--- Lyric meta event (0x05).
-- Lyrics/text to be sung at this time.
-- @type LyricEvent
LyricEvent = class 'LyricEvent' : extends(MetaEvent) {
  meta_command = 0x05,
}

--- Marker meta event (0x06).
-- Marks a significant point in the sequence.
-- @type MarkerEvent
MarkerEvent = class 'MarkerEvent' : extends(MetaEvent) {
  meta_command = 0x06,
}

--- Cue Point meta event (0x07).
-- Describes an event happening at this point in a video/film.
-- @type CueEvent
CueEvent = class 'CueEvent' : extends(MetaEvent) {
  meta_command = 0x07,
}

--- Program Name meta event (0x08).
-- Name of the program/patch used.
-- @type ProgramNameEvent
ProgramNameEvent = class 'ProgramNameEvent' : extends(MetaEvent) {
  meta_command = 0x08,
}

--- Device Name meta event (0x09).
-- Name of the MIDI device.
-- @type DeviceNameEvent
DeviceNameEvent = class 'DeviceNameEvent' : extends(MetaEvent) {
  meta_command = 0x09,
}

--- MIDI Channel Prefix meta event (0x20).
-- Associates following meta events with a specific channel.
-- @type PrefixAssignmentEvent
PrefixAssignmentEvent = class 'PrefixAssignmentEvent' : extends(MetaEvent) {
  meta_command = 0x20,
}

--- MIDI Port meta event (0x21).
-- Specifies the MIDI port to use.
-- @type PortChannelPrefixEvent
PortChannelPrefixEvent = class 'PortChannelPrefixEvent' : extends(MetaEvent) {
  meta_command = 0x21,
}

--- End of Track meta event (0x2F).
-- Required at the end of every track.
-- @type EndOfTrackEvent
EndOfTrackEvent = class 'EndOfTrackEvent' : extends(MetaEvent) {
  meta_command = 0x2F,
}

--- Set Tempo meta event (0x51).
-- Sets the tempo in microseconds per quarter note.
-- @type SetTempoEvent
SetTempoEvent = class 'SetTempoEvent' : extends(MetaEvent) {
  meta_command = 0x51,

  --- Get tempo in microseconds per quarter note.
  -- @return number|nil Tempo in microseconds, or nil if data is invalid
  get_tempo = function(self)
    if #self.data ~= 3 then return nil end
    return (self.data[1] << 16) | (self.data[2] << 8) | self.data[3]
  end,

  --- Set tempo in microseconds per quarter note.
  -- @function SetTempoEvent:set_tempo
  -- @param microseconds_per_quarter number Tempo value
  set_tempo = function(self, microseconds_per_quarter)
    self.data = {
      (microseconds_per_quarter >> 16) & 0xFF,
      (microseconds_per_quarter >> 8) & 0xFF,
      microseconds_per_quarter & 0xFF,
    }
  end,

  --- Get tempo in beats per minute.
  -- @return number|nil BPM, or nil if data is invalid
  get_bpm = function(self)
    local tempo = self:get_tempo()
    if not tempo then return nil end
    return 60000000 / tempo
  end,

  --- Set tempo in beats per minute.
  -- @function SetTempoEvent:set_bpm
  -- @param bpm number Beats per minute
  set_bpm = function(self, bpm)
    self:set_tempo(math.floor(60000000 / bpm))
  end,

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

--- SMPTE Offset meta event (0x54).
-- Specifies the SMPTE time at which the track should start.
-- @type SMPTEOffsetEvent
SMPTEOffsetEvent = class 'SMPTEOffsetEvent' : extends(MetaEvent) {
  meta_command = 0x54,

  --- Get SMPTE offset components.
  -- @return table|nil Table with hours, minutes, seconds, frames, fractional_frames, or nil if invalid
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

  --- Set SMPTE offset components.
  -- @function SMPTEOffsetEvent:set_offset
  -- @param hours number Hours (0-23)
  -- @param minutes number Minutes (0-59)
  -- @param seconds number Seconds (0-59)
  -- @param frames number Frames (0-29)
  -- @param fractional_frames number Sub-frames (default 0)
  set_offset = function(self, hours, minutes, seconds, frames, fractional_frames)
    self.data = { hours, minutes, seconds, frames, fractional_frames or 0 }
  end,
}

--- Time Signature meta event (0x58).
-- Defines the time signature (e.g., 4/4, 3/4, 6/8).
-- @type TimeSignatureEvent
TimeSignatureEvent = class 'TimeSignatureEvent' : extends(MetaEvent) {
  meta_command = 0x58,

  --- Get time signature components.
  -- @return table|nil Table with numerator, denominator, clocks_per_metronome_click, thirty_seconds_per_quarter, or nil if invalid
  get_time_signature = function(self)
    if #self.data ~= 4 then return nil end
    return {
      numerator = self.data[1],
      denominator = 2 ^ self.data[2],
      clocks_per_metronome_click = self.data[3],
      thirty_seconds_per_quarter = self.data[4],
    }
  end,

  --- Set time signature.
  -- @function TimeSignatureEvent:set_time_signature
  -- @param numerator number Beats per measure (e.g., 4 for 4/4)
  -- @param denominator number Note value per beat (must be power of 2, e.g., 4 for quarter note)
  -- @param clocks_per_click number MIDI clocks per metronome click (default 24)
  -- @param thirty_seconds_per_quarter number 32nd notes per quarter note (default 8)
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

--- Key Signature meta event (0x59).
-- Defines the key signature (sharps/flats and major/minor).
-- @type KeySignatureEvent
KeySignatureEvent = class 'KeySignatureEvent' : extends(MetaEvent) {
  meta_command = 0x59,

  --- Get key signature components.
  -- @return table|nil Table with sharps_flats (-7 to +7) and is_minor (boolean), or nil if invalid
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

  --- Set key signature.
  -- @function KeySignatureEvent:set_key_signature
  -- @param sharps_flats number Number of sharps (+) or flats (-), from -7 to +7
  -- @param is_minor boolean True for minor key, false for major
  set_key_signature = function(self, sharps_flats, is_minor)
    -- Convert from signed to unsigned
    local sf = sharps_flats
    if sf < 0 then
      sf = sf + 256
    end
    self.data = { sf, is_minor and 1 or 0 }
  end,
}

--- Sequencer Specific meta event (0x7F).
-- Manufacturer-specific sequencer data.
-- @type SequencerSpecificEvent
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
-- NOTE: 0xFF is intentionally NOT registered here. In MIDI files, 0xFF indicates
-- a meta event, not a system reset. System reset (0xFF) only exists in real-time
-- MIDI streams. Meta events are handled via Event.types[0xF0] -> MetaEvent.
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
-- system_event_types[0xFF] is NOT set - 0xFF in MIDI files is a meta event prefix

return _M

