-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>
--
-- This module defines a `MidiFile` class for reading and writing MIDI files.
-- A MIDI file consists of a header (format, ticks per beat) and a list of tracks.
-- Each track contains MIDI events, such as notes, control changes, and metadata.

local llx = require 'llx'
local midi_io = require 'midi.io'
local midi_track = require 'midi.track'

local _ENV, _M = llx.environment.create_module_environment()
local class = llx.class

--- MidiFile class
-- @field format Format type (0, 1, or 2)
-- @field ticks Number of ticks per beat
-- @field tracks List of midi_track.Track objects
MidiFile = class 'MidiFile' {
  --- Constructor
  -- Accepts either positional arguments (format, ticks, tracks)
  -- or a single table with keys {format=, ticks=, tracks=}
  __init = function(self, args_or_format, ticks, tracks)
    if type(args_or_format) == 'table' then
      self.format = args_or_format.format or 1
      self.ticks = args_or_format.ticks or 92
      self.tracks = args_or_format.tracks or llx.List{}
    else
      self.format = args_or_format or 1
      self.ticks = ticks or 92
      self.tracks = tracks or llx.List{}
    end
  end,

  --- Check if using SMPTE time division
  is_smpte = function(self)
    if type(self.ticks) == 'table' and self.ticks.smpte then
      return true
    elseif type(self.ticks) == 'number' and self.ticks < 0 then
      return true
    end
    return false
  end,

  --- Get SMPTE frame rate and ticks per frame
  -- @return frame_rate, ticks_per_frame or nil if not SMPTE
  get_smpte_timing = function(self)
    if type(self.ticks) == 'table' and self.ticks.smpte then
      return self.ticks.frame_rate, self.ticks.ticks_per_frame
    elseif self.ticks < 0 then
      -- Parse from negative value
      local frame_rate_code = (-self.ticks) >> 8
      local ticks_per_frame = (-self.ticks) & 0xFF
      local frame_rate_map = {
        [24] = 24,
        [25] = 25,
        [29] = 29.97,
        [30] = 30,
      }
      return frame_rate_map[frame_rate_code] or frame_rate_code, ticks_per_frame
    end
    return nil
  end,

  --- Set SMPTE timing
  -- @param frame_rate Frame rate (24, 25, 29.97, or 30)
  -- @param ticks_per_frame Ticks per frame
  set_smpte_timing = function(self, frame_rate, ticks_per_frame)
    local frame_rate_code
    if frame_rate == 24 then
      frame_rate_code = 24
    elseif frame_rate == 25 then
      frame_rate_code = 25
    elseif frame_rate == 29.97 then
      frame_rate_code = 29
    elseif frame_rate == 30 then
      frame_rate_code = 30
    else
      error(string.format('Invalid SMPTE frame rate: %f', frame_rate))
    end
    self.ticks = {
      smpte = true,
      frame_rate = frame_rate,
      ticks_per_frame = ticks_per_frame,
      encoded = -(frame_rate_code << 8 | ticks_per_frame),
    }
  end,

  --- Check if this is format 0 (single track)
  is_format_0 = function(self)
    return self.format == 0
  end,

  --- Check if this is format 1 (multi-track synchronous)
  is_format_1 = function(self)
    return self.format == 1
  end,

  --- Check if this is format 2 (multi-track asynchronous/pattern)
  is_format_2 = function(self)
    return self.format == 2
  end,

  --- Get human-readable format name
  get_format_name = function(self)
    if self.format == 0 then
      return 'Format 0 (Single Track)'
    elseif self.format == 1 then
      return 'Format 1 (Multi-Track Synchronous)'
    elseif self.format == 2 then
      return 'Format 2 (Multi-Track Asynchronous)'
    else
      return string.format('Unknown Format (%d)', self.format)
    end
  end,

  --- Validate that the MIDI file conforms to its format specification
  -- @return true if valid, false otherwise
  -- @return error message if invalid
  validate_format = function(self)
    -- Validate format number
    if self.format < 0 or self.format > 2 then
      return false, string.format('Invalid format number: %d (must be 0, 1, or 2)', self.format)
    end

    local track_count = #self.tracks

    -- Format 0: Must have exactly 1 track
    if self.format == 0 then
      if track_count ~= 1 then
        return false, string.format(
          'Format 0 requires exactly 1 track, but has %d track(s)',
          track_count
        )
      end
    end

    -- Format 1 and 2: Must have at least 1 track (0 is allowed for empty files)
    -- No additional constraints for format 1 and 2

    return true
  end,

  --- Assert that the MIDI file is valid, throws error if not
  assert_valid_format = function(self)
    local valid, err = self:validate_format()
    if not valid then
      error(err, 2)
    end
  end,

  --- Get a specific pattern/sequence (for format 2)
  -- @param index Pattern index (1-based)
  -- @return Track object or nil if index out of bounds
  get_pattern = function(self, index)
    if not self:is_format_2() then
      error('get_pattern() is only valid for Format 2 files', 2)
    end
    return self.tracks[index]
  end,

  --- Get the number of patterns/sequences (for format 2)
  -- @return Number of patterns
  get_pattern_count = function(self)
    if not self:is_format_2() then
      error('get_pattern_count() is only valid for Format 2 files', 2)
    end
    return #self.tracks
  end,

  --- Internal function to read a MidiFile from an open file handle
  _read_file = function(file)
    local midi_file = MidiFile()
    assert(file:read(4) == 'MThd', 'Invalid MIDI file header')
    assert(midi_io.readUInt32be(file) == 0x00000006, 'Invalid MIDI header length')
    midi_file.format = midi_io.readUInt16be(file)
    local tracks_count = midi_io.readUInt16be(file)
    local ticks_raw = midi_io.readUInt16be(file)
    
    -- Check if SMPTE format (MSB set)
    if ticks_raw & 0x8000 ~= 0 then
      -- Convert to signed 16-bit
      local signed_ticks = ticks_raw - 65536
      local frame_rate_code = (-signed_ticks) >> 8
      local ticks_per_frame = (-signed_ticks) & 0xFF
      local frame_rate_map = {
        [24] = 24,
        [25] = 25,
        [29] = 29.97,
        [30] = 30,
      }
      midi_file.ticks = {
        smpte = true,
        frame_rate = frame_rate_map[frame_rate_code] or frame_rate_code,
        ticks_per_frame = ticks_per_frame,
        encoded = signed_ticks,
      }
    else
      midi_file.ticks = ticks_raw
    end
    for i=1, tracks_count do
      table.insert(midi_file.tracks, midi_track.Track.read(file))
    end
    return midi_file
  end,

  --- Public function to read a MidiFile from a filename or file handle
  read = function(file_or_filename)
    if type(file_or_filename) == 'string' then
      local file <close> = assert(io.open(file_or_filename, 'rb'))
      return MidiFile._read_file(file)
    else
      return MidiFile._read_file(file_or_filename)
    end
  end,

  --- Internal function to write a MidiFile to an open file handle
  _write_file = function(self, file)
    -- Validate format before writing
    self:assert_valid_format()
    
    file:write('MThd')
    midi_io.writeUInt32be(file, 0x00000006)
    midi_io.writeUInt16be(file, self.format)
    midi_io.writeUInt16be(file, #self.tracks)
    
    -- Write ticks (handle SMPTE format)
    if type(self.ticks) == 'table' and self.ticks.smpte then
      -- Convert to unsigned 16-bit for writing
      local signed_value = self.ticks.encoded
      local unsigned_value = signed_value < 0 and (signed_value + 65536) or signed_value
      midi_io.writeUInt16be(file, unsigned_value)
    else
      midi_io.writeUInt16be(file, self.ticks)
    end
    for _, track in ipairs(self.tracks) do
      track:write(file)
    end
  end,

  --- Public function to write a MidiFile to a filename or file handle
  write = function(self, file_or_filename)
    if type(file_or_filename) == 'string' then
      local file <close> = assert(io.open(file_or_filename, 'wb'))
      self:_write_file(file)
    else
      self:_write_file(file_or_filename)
    end
  end,

  --- Returns a human-readable representation of the MIDI file
  __tostring = function(self)
    local tracks_strings = {}
    for i, track in ipairs(self.tracks) do
      tracks_strings[i] = tostring(track)
    end
    return string.format(
      'MidiFile{format=%d, ticks=%d, tracks={%s}}',
      self.format, self.ticks, table.concat(tracks_strings, ', '))
  end,

  --- Returns the binary contents of the MIDI file as a Lua string
  __tobytes = function(self)
    local buffer = {}
    local file = {
      write = function(_, s) table.insert(buffer, s) end
    }
    self:_write_file(file)
    return table.concat(buffer)
  end,
}

--- Type coercion function
-- Returns a MidiFile if the object has a __tomidifile metamethod
function tomidifile(value)
  local __tomidifile = llx.getmetafield(value, '__tomidifile')
  return __tomidifile and __tomidifile(value) or nil
end

return _M
