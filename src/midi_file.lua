--- MIDI File Module.
-- This module defines a `MidiFile` class for reading and writing MIDI files.
-- A MIDI file consists of a header (format, ticks per beat) and a list of tracks.
-- Each track contains MIDI events, such as notes, control changes, and metadata.
--
-- MIDI file formats:
--
-- * Format 0: Single track containing all MIDI data
-- * Format 1: Multiple tracks, played synchronously (most common)
-- * Format 2: Multiple independent patterns/sequences
--
-- @module midi.midi_file
-- @copyright 2024 Alexander Ames
-- @license MIT
-- @usage
-- local midi_file = require 'lua-midi.midi_file'
--
-- -- Read an existing MIDI file
-- local song = midi_file.MidiFile.read('song.mid')
-- print(song:get_format_name())
-- print('Tracks:', #song.tracks)
--
-- -- Create a new MIDI file
-- local new_song = midi_file.MidiFile{format=1, ticks=480}
-- new_song:write('output.mid')

local llx = require 'llx'
local midi_io = require 'lua-midi.io'
local midi_track = require 'lua-midi.track'

local _ENV, _M = llx.environment.create_module_environment()
local class = llx.class

-- SMPTE frame rate lookup tables
local _frame_rate_to_code = {
  [24] = 24,
  [25] = 25,
  [29.97] = 29,
  [30] = 30,
}

local _code_to_frame_rate = {
  [24] = 24,
  [25] = 25,
  [29] = 29.97,
  [30] = 30,
}

--- SMPTE time division.
-- Represents SMPTE-based timing (frames per second + ticks per frame)
-- as a proper value type with equality, cloning, and string conversion.
-- @type SmpteDivision
-- @field frame_rate number Frame rate (24, 25, 29.97, or 30)
-- @field ticks_per_frame number Ticks per frame (sub-frame resolution)
-- @field encoded number Signed 16-bit encoding for the MIDI header
SmpteDivision = class 'SmpteDivision' {
  --- Create a new SmpteDivision.
  -- @function SmpteDivision:__init
  -- @param frame_rate number Frame rate (24, 25, 29.97, or 30)
  -- @param ticks_per_frame number Ticks per frame
  -- @raise error if frame_rate is not a valid SMPTE rate
  __init = function(self, frame_rate, ticks_per_frame)
    local frame_rate_code = _frame_rate_to_code[frame_rate]
    if not frame_rate_code then
      error(string.format('Invalid SMPTE frame rate: %g', frame_rate))
    end
    self.frame_rate = frame_rate
    self.ticks_per_frame = ticks_per_frame
    self.encoded = -(frame_rate_code << 8 | ticks_per_frame)
  end,

  __eq = function(self, other)
    return self.class == other.class
       and self.frame_rate == other.frame_rate
       and self.ticks_per_frame == other.ticks_per_frame
  end,

  clone = function(self)
    return SmpteDivision(self.frame_rate, self.ticks_per_frame)
  end,

  __tostring = function(self)
    return string.format('SMPTE(%g fps, %d tpf)', self.frame_rate, self.ticks_per_frame)
  end,
}

--- Decode a raw 16-bit ticks value into a SmpteDivision.
-- @param ticks_raw number The raw unsigned 16-bit value from the MIDI header
-- @return SmpteDivision SMPTE timing object
-- @local
local function _decode_smpte(ticks_raw)
  local signed_ticks = ticks_raw - 65536
  local frame_rate_code = (-signed_ticks) >> 8
  local ticks_per_frame = (-signed_ticks) & 0xFF
  local frame_rate = _code_to_frame_rate[frame_rate_code] or frame_rate_code
  return SmpteDivision(frame_rate, ticks_per_frame)
end

--- MidiFile class for reading and writing Standard MIDI Files (SMF).
-- @type MidiFile
-- @field format number Format type (0, 1, or 2)
-- @field ticks number|table Number of ticks per beat, or SMPTE timing table
-- @field tracks List List of Track objects
MidiFile = class 'MidiFile' {
  --- Create a new MidiFile.
  -- Accepts either positional arguments (format, ticks, tracks)
  -- or a single table with keys {format=, ticks=, tracks=}.
  -- @function MidiFile:__init
  -- @param args_or_format number|table Either the format number (0, 1, or 2), or a table with keys
  -- @param ticks number Number of ticks per quarter note (default 92)
  -- @param tracks List List of Track objects (default empty)
  -- @return MidiFile A new MidiFile instance
  -- @usage
  -- -- Table constructor
  -- local midi = MidiFile{format=1, ticks=480}
  -- -- Positional arguments
  -- local midi = MidiFile(1, 480)
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

  --- Check if using SMPTE time division.
  -- SMPTE timing uses absolute time (frames) rather than musical time (beats).
  -- @return boolean True if SMPTE timing is used
  is_smpte = function(self)
    return SmpteDivision:__isinstance(self.ticks)
  end,

  --- Get SMPTE frame rate and ticks per frame.
  -- @return number|nil Frame rate (24, 25, 29.97, or 30), or nil if not SMPTE
  -- @return number|nil Ticks per frame, or nil if not SMPTE
  get_smpte_timing = function(self)
    if SmpteDivision:__isinstance(self.ticks) then
      return self.ticks.frame_rate, self.ticks.ticks_per_frame
    end
    return nil
  end,

  --- Set SMPTE timing mode.
  -- Configures the MIDI file to use SMPTE time division instead of musical beats.
  -- @function MidiFile:set_smpte_timing
  -- @param frame_rate number Frame rate (24, 25, 29.97, or 30)
  -- @param ticks_per_frame number Ticks per frame (sub-frame resolution)
  -- @raise error if frame_rate is invalid
  set_smpte_timing = function(self, frame_rate, ticks_per_frame)
    self.ticks = SmpteDivision(frame_rate, ticks_per_frame)
  end,

  --- Check if this is format 0 (single track).
  -- Format 0 files contain all MIDI data in a single track.
  -- @return boolean True if format 0
  is_format_0 = function(self)
    return self.format == 0
  end,

  --- Check if this is format 1 (multi-track synchronous).
  -- Format 1 files have multiple tracks that play simultaneously.
  -- This is the most common MIDI file format.
  -- @return boolean True if format 1
  is_format_1 = function(self)
    return self.format == 1
  end,

  --- Check if this is format 2 (multi-track asynchronous/pattern).
  -- Format 2 files contain independent patterns or sequences.
  -- @return boolean True if format 2
  is_format_2 = function(self)
    return self.format == 2
  end,

  --- Get human-readable format name.
  -- @return string Description of the format (e.g., "Format 1 (Multi-Track Synchronous)")
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

  --- Validate that the MIDI file conforms to its format specification.
  -- Checks format number validity and track count constraints.
  -- @return boolean True if valid, false otherwise
  -- @return string|nil Error message if invalid
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

  --- Assert that the MIDI file is valid, throws error if not.
  -- @raise error if validation fails
  assert_valid_format = function(self)
    local valid, err = self:validate_format()
    if not valid then
      error(err, 2)
    end
  end,

  --- Get a specific pattern/sequence (for format 2).
  -- @function MidiFile:get_pattern
  -- @param index number Pattern index (1-based)
  -- @return Track|nil Track object or nil if index out of bounds
  -- @raise error if not a format 2 file
  get_pattern = function(self, index)
    if not self:is_format_2() then
      error('get_pattern() is only valid for Format 2 files', 2)
    end
    return self.tracks[index]
  end,

  --- Get the number of patterns/sequences (for format 2).
  -- @return number Number of patterns
  -- @raise error if not a format 2 file
  get_pattern_count = function(self)
    if not self:is_format_2() then
      error('get_pattern_count() is only valid for Format 2 files', 2)
    end
    return #self.tracks
  end,

  --- Internal function to read a MidiFile from an open file handle.
  -- @param file file File handle opened in binary read mode
  -- @return MidiFile Parsed MIDI file
  -- @local
  _read_file = function(file)
    local midi_file = MidiFile()
    assert(file:read(4) == 'MThd', 'Invalid MIDI file header')
    assert(midi_io.readUInt32be(file) == 0x00000006, 'Invalid MIDI header length')
    midi_file.format = midi_io.readUInt16be(file)
    local tracks_count = midi_io.readUInt16be(file)
    local ticks_raw = midi_io.readUInt16be(file)
    
    -- Check if SMPTE format (MSB set)
    if ticks_raw & 0x8000 ~= 0 then
      midi_file.ticks = _decode_smpte(ticks_raw)
    else
      midi_file.ticks = ticks_raw
    end
    for i=1, tracks_count do
      table.insert(midi_file.tracks, midi_track.Track.read(file))
    end
    return midi_file
  end,

  --- Read a MidiFile from a filename or file handle.
  -- @param file_or_filename string|file Either a filename string or an open file handle
  -- @return MidiFile Parsed MIDI file
  -- @raise error if file is invalid or cannot be read
  -- @usage
  -- local song = MidiFile.read('song.mid')
  -- -- or with file handle
  -- local f = io.open('song.mid', 'rb')
  -- local song = MidiFile.read(f)
  -- f:close()
  read = function(file_or_filename)
    if type(file_or_filename) == 'string' then
      local file <close> = assert(io.open(file_or_filename, 'rb'))
      return MidiFile._read_file(file)
    else
      return MidiFile._read_file(file_or_filename)
    end
  end,

  --- Internal function to write a MidiFile to an open file handle.
  -- @function MidiFile:_write_file
  -- @param file file File handle opened in binary write mode
  -- @local
  _write_file = function(self, file)
    -- Validate format before writing
    self:assert_valid_format()
    
    file:write('MThd')
    midi_io.writeUInt32be(file, 0x00000006)
    midi_io.writeUInt16be(file, self.format)
    midi_io.writeUInt16be(file, #self.tracks)
    
    -- Write ticks (handle SMPTE format)
    if SmpteDivision:__isinstance(self.ticks) then
      -- Convert signed encoding to unsigned 16-bit for writing
      midi_io.writeUInt16be(file, self.ticks.encoded + 65536)
    else
      midi_io.writeUInt16be(file, self.ticks)
    end
    for _, track in ipairs(self.tracks) do
      track:write(file)
    end
  end,

  --- Write a MidiFile to a filename or file handle.
  -- @function MidiFile:write
  -- @param file_or_filename string|file Either a filename string or an open file handle
  -- @raise error if format validation fails
  -- @usage
  -- song:write('output.mid')
  -- -- or with file handle
  -- local f = io.open('output.mid', 'wb')
  -- song:write(f)
  -- f:close()
  write = function(self, file_or_filename)
    if type(file_or_filename) == 'string' then
      local file <close> = assert(io.open(file_or_filename, 'wb'))
      self:_write_file(file)
    else
      self:_write_file(file_or_filename)
    end
  end,

  --- Returns a human-readable representation of the MIDI file.
  -- @return string String representation of the MIDI file
  __tostring = function(self)
    local tracks_strings = {}
    for i, track in ipairs(self.tracks) do
      tracks_strings[i] = tostring(track)
    end
    local ticks_str = tostring(self.ticks)
    return string.format(
      'MidiFile{format=%d, ticks=%s, tracks={%s}}',
      self.format, ticks_str, table.concat(tracks_strings, ', '))
  end,

  --- Equality comparison for MIDI files.
  -- Two MIDI files are equal if they have the same format, ticks, and tracks.
  -- @param other MidiFile The MIDI file to compare with
  -- @return boolean True if equal
  __eq = function(self, other)
    if self.class ~= other.class then return false end
    if self.format ~= other.format then return false end
    if self.ticks ~= other.ticks then return false end
    -- Compare tracks
    if #self.tracks ~= #other.tracks then return false end
    for i = 1, #self.tracks do
      if self.tracks[i] ~= other.tracks[i] then return false end
    end
    return true
  end,

  --- Create an independent copy of this MIDI file.
  -- Clones all tracks and events so the copy shares no mutable state.
  -- @return MidiFile A new MIDI file equal to this one
  clone = function(self)
    local cloned_tracks = llx.List{}
    for _, track in ipairs(self.tracks) do
      table.insert(cloned_tracks, track:clone())
    end
    local ticks = SmpteDivision:__isinstance(self.ticks) and self.ticks:clone() or self.ticks
    return MidiFile(self.format, ticks, cloned_tracks)
  end,

  --- Returns the binary contents of the MIDI file as a Lua string.
  -- Useful for in-memory manipulation or network transmission.
  -- @return string Binary MIDI file data
  __tobytes = function(self)
    local buffer = {}
    local file = {
      write = function(_, s) table.insert(buffer, s) end
    }
    self:_write_file(file)
    return table.concat(buffer)
  end,
}

--- Type coercion function.
-- Attempts to convert a value to a MidiFile using the __tomidifile metamethod.
-- @param value any Value to convert
-- @return MidiFile|nil MidiFile if conversion succeeds, nil otherwise
-- @function tomidifile
function tomidifile(value)
  local __tomidifile = llx.getmetafield(value, '__tomidifile')
  return __tomidifile and __tomidifile(value) or nil
end

return _M
