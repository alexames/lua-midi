--- MIDI Validation Module.
-- This module provides validation utilities for MIDI values to ensure they
-- conform to the MIDI specification constraints.
--
-- All validate_* functions return (true) on success or
-- (false, error_message) on failure.
-- All assert_* functions throw an error if validation fails.
--
-- @module midi.validation
-- @copyright 2024 Alexander Ames
-- @license MIT
-- @usage
-- local validation = require 'lua-midi.validation'
--
-- -- Validate values
-- local ok, err = validation.validate_channel(16)
-- -- false, "Channel must be 0-15, got 16"
--
-- -- Assert values (throws on invalid)
-- validation.assert_note(60)  -- OK
-- validation.assert_note(128) -- Error!

local llx = require 'llx'

local _ENV, _M = llx.environment.create_module_environment()

--- Validate that a value is an integer within a given range.
-- @param value any The value to validate
-- @param name string Human-readable name for error messages
-- @param min number Minimum allowed value (inclusive)
-- @param max number Maximum allowed value (inclusive)
-- @return boolean True if valid, false otherwise
-- @return string|nil Error message if invalid
-- @local
local function _validate_integer_range(value, name, min, max)
  if type(value) ~= 'number' then
    return false, name .. ' must be a number'
  end
  if value ~= math.floor(value) then
    return false, string.format('%s must be an integer, got %g', name, value)
  end
  if value < min or value > max then
    return false, string.format(
      '%s must be %d-%d, got %d', name, min, max, value)
  end
  return true
end

--- Validate a MIDI event time delta.
-- Time deltas must be non-negative integers that fit in
-- VLQ encoding (0-268435455).
-- @param time_delta number The time delta to validate
-- @return boolean True if valid, false otherwise
-- @return string|nil Error message if invalid
function validate_time_delta(time_delta)
  return _validate_integer_range(time_delta, 'Time delta', 0, 0x0FFFFFFF)
end

--- Validate a MIDI channel number (0-15).
-- @param channel number The channel number to validate
-- @return boolean True if valid, false otherwise
-- @return string|nil Error message if invalid
function validate_channel(channel)
  return _validate_integer_range(channel, 'Channel', 0, 15)
end

--- Validate a MIDI note number (0-127).
-- @param note number The note number to validate
-- @return boolean True if valid, false otherwise
-- @return string|nil Error message if invalid
function validate_note(note)
  return _validate_integer_range(note, 'Note', 0, 127)
end

--- Validate a MIDI velocity (0-127).
-- @param velocity number The velocity to validate
-- @return boolean True if valid, false otherwise
-- @return string|nil Error message if invalid
function validate_velocity(velocity)
  return _validate_integer_range(velocity, 'Velocity', 0, 127)
end

--- Validate a MIDI controller number (0-127).
-- @param controller number The controller number to validate
-- @return boolean True if valid, false otherwise
-- @return string|nil Error message if invalid
function validate_controller(controller)
  return _validate_integer_range(controller, 'Controller', 0, 127)
end

--- Validate a MIDI program number (0-127).
-- @param program number The program number to validate
-- @return boolean True if valid, false otherwise
-- @return string|nil Error message if invalid
function validate_program(program)
  return _validate_integer_range(program, 'Program', 0, 127)
end

--- Validate a MIDI pitch bend value (0-16383, center is 8192).
-- @param value number The pitch bend value to validate
-- @return boolean True if valid, false otherwise
-- @return string|nil Error message if invalid
function validate_pitch_bend(value)
  return _validate_integer_range(value, 'Pitch bend', 0, 16383)
end

--- Validate a 14-bit data value (0-16383).
-- @param value number The value to validate
-- @param name string Optional name for error messages (default "Value")
-- @return boolean True if valid, false otherwise
-- @return string|nil Error message if invalid
function validate_14bit(value, name)
  return _validate_integer_range(value, name or 'Value', 0, 16383)
end

--- Validate a 4-bit data value (0-15).
-- @param value number The value to validate
-- @param name string Optional name for error messages (default "Value")
-- @return boolean True if valid, false otherwise
-- @return string|nil Error message if invalid
function validate_4bit(value, name)
  return _validate_integer_range(value, name or 'Value', 0, 15)
end

--- Validate a 3-bit data value (0-7).
-- @param value number The value to validate
-- @param name string Optional name for error messages (default "Value")
-- @return boolean True if valid, false otherwise
-- @return string|nil Error message if invalid
function validate_3bit(value, name)
  return _validate_integer_range(value, name or 'Value', 0, 7)
end

--- Validate a 7-bit data value (0-127).
-- @param value number The value to validate
-- @param name string Optional name for error messages (default "Value")
-- @return boolean True if valid, false otherwise
-- @return string|nil Error message if invalid
function validate_7bit(value, name)
  return _validate_integer_range(value, name or 'Value', 0, 127)
end

--- Assert that a time delta is valid, throws error if not.
-- @param time_delta number The time delta to validate
-- @raise error if time delta is invalid
function assert_time_delta(time_delta)
  local valid, err = validate_time_delta(time_delta)
  if not valid then error(err, 2) end
end

--- Assert that a channel is valid, throws error if not.
-- @param channel number The channel to validate
-- @raise error if channel is invalid
function assert_channel(channel)
  local valid, err = validate_channel(channel)
  if not valid then error(err, 2) end
end

--- Assert that a note is valid, throws error if not.
-- @param note number The note to validate
-- @raise error if note is invalid
function assert_note(note)
  local valid, err = validate_note(note)
  if not valid then error(err, 2) end
end

--- Assert that a velocity is valid, throws error if not.
-- @param velocity number The velocity to validate
-- @raise error if velocity is invalid
function assert_velocity(velocity)
  local valid, err = validate_velocity(velocity)
  if not valid then error(err, 2) end
end

--- Assert that a controller is valid, throws error if not.
-- @param controller number The controller to validate
-- @raise error if controller is invalid
function assert_controller(controller)
  local valid, err = validate_controller(controller)
  if not valid then error(err, 2) end
end

--- Assert that a program is valid, throws error if not.
-- @param program number The program to validate
-- @raise error if program is invalid
function assert_program(program)
  local valid, err = validate_program(program)
  if not valid then error(err, 2) end
end

--- Assert that a 7-bit value is valid, throws error if not.
-- @param value number The value to validate
-- @param name string Optional name for error messages (default "Value")
-- @raise error if value is invalid
function assert_7bit(value, name)
  local valid, err = validate_7bit(value, name)
  if not valid then error(err, 2) end
end

--- Assert that a pitch bend value is valid, throws error if not.
-- @param value number The pitch bend value to validate
-- @raise error if pitch bend value is invalid
function assert_pitch_bend(value)
  local valid, err = validate_pitch_bend(value)
  if not valid then error(err, 2) end
end

--- Assert that a 14-bit value is valid, throws error if not.
-- @param value number The value to validate
-- @param name string Optional name for error messages (default "Value")
-- @raise error if value is invalid
function assert_14bit(value, name)
  local valid, err = validate_14bit(value, name)
  if not valid then error(err, 2) end
end

--- Assert that a 4-bit value is valid, throws error if not.
-- @param value number The value to validate
-- @param name string Optional name for error messages (default "Value")
-- @raise error if value is invalid
function assert_4bit(value, name)
  local valid, err = validate_4bit(value, name)
  if not valid then error(err, 2) end
end

--- Assert that a 3-bit value is valid, throws error if not.
-- @param value number The value to validate
-- @param name string Optional name for error messages (default "Value")
-- @raise error if value is invalid
function assert_3bit(value, name)
  local valid, err = validate_3bit(value, name)
  if not valid then error(err, 2) end
end

--- Validate a MIDI tempo value in microseconds per quarter note.
-- Must fit in 3 bytes (1-16777215).
-- @param tempo number The tempo value to validate
-- @return boolean True if valid, false otherwise
-- @return string|nil Error message if invalid
function validate_tempo(tempo)
  return _validate_integer_range(tempo, 'Tempo', 1, 0xFFFFFF)
end

--- Assert that a tempo value is valid, throws error if not.
-- @param tempo number The tempo value to validate
-- @raise error if tempo is invalid
function assert_tempo(tempo)
  local valid, err = validate_tempo(tempo)
  if not valid then error(err, 2) end
end

--- Validate a key signature sharps/flats value (-7 to +7).
-- @param sharps_flats number Number of sharps (positive) or flats (negative)
-- @return boolean True if valid, false otherwise
-- @return string|nil Error message if invalid
function validate_sharps_flats(sharps_flats)
  return _validate_integer_range(sharps_flats, 'Sharps/flats', -7, 7)
end

--- Assert that a sharps/flats value is valid, throws error if not.
-- @param sharps_flats number The sharps/flats value to validate
-- @raise error if value is invalid
function assert_sharps_flats(sharps_flats)
  local valid, err = validate_sharps_flats(sharps_flats)
  if not valid then error(err, 2) end
end

--- Validate that a value is a boolean.
-- @param value any The value to validate
-- @param name string Human-readable name for error messages
-- @return boolean True if valid, false otherwise
-- @return string|nil Error message if invalid
function validate_boolean(value, name)
  if type(value) ~= 'boolean' then
    return false, (name or 'Value') .. ' must be a boolean'
  end
  return true
end

--- Assert that a value is a boolean, throws error if not.
-- @param value any The value to validate
-- @param name string Human-readable name for error messages
-- @raise error if value is not a boolean
function assert_boolean(value, name)
  local valid, err = validate_boolean(value, name)
  if not valid then error(err, 2) end
end

--- Validate that a time signature denominator is a power of 2 (1-256).
-- @param denominator number The denominator to validate
-- @return boolean True if valid, false otherwise
-- @return string|nil Error message if invalid
function validate_denominator(denominator)
  if type(denominator) ~= 'number' then
    return false, 'Denominator must be a number'
  end
  if denominator ~= math.floor(denominator) then
    return false, string.format(
      'Denominator must be an integer, got %g', denominator)
  end
  if denominator < 1 or denominator > 256 then
    return false, string.format(
      'Denominator must be 1-256, got %d', denominator)
  end
  if denominator & (denominator - 1) ~= 0 then
    return false, string.format(
      'Denominator must be a power of 2, got %d', denominator)
  end
  return true
end

--- Assert that a time signature denominator is valid, throws error if not.
-- @param denominator number The denominator to validate
-- @raise error if denominator is invalid
function assert_denominator(denominator)
  local valid, err = validate_denominator(denominator)
  if not valid then error(err, 2) end
end

--- Validate a SMPTE hours value (0-23).
-- @param hours number The hours value to validate
-- @return boolean True if valid, false otherwise
-- @return string|nil Error message if invalid
function validate_smpte_hours(hours)
  return _validate_integer_range(hours, 'SMPTE hours', 0, 23)
end

--- Assert that a SMPTE hours value is valid, throws error if not.
-- @param hours number The hours value to validate
-- @raise error if hours is invalid
function assert_smpte_hours(hours)
  local valid, err = validate_smpte_hours(hours)
  if not valid then error(err, 2) end
end

--- Validate a SMPTE minutes value (0-59).
-- @param minutes number The minutes value to validate
-- @return boolean True if valid, false otherwise
-- @return string|nil Error message if invalid
function validate_smpte_minutes(minutes)
  return _validate_integer_range(minutes, 'SMPTE minutes', 0, 59)
end

--- Assert that a SMPTE minutes value is valid, throws error if not.
-- @param minutes number The minutes value to validate
-- @raise error if minutes is invalid
function assert_smpte_minutes(minutes)
  local valid, err = validate_smpte_minutes(minutes)
  if not valid then error(err, 2) end
end

--- Validate a SMPTE seconds value (0-59).
-- @param seconds number The seconds value to validate
-- @return boolean True if valid, false otherwise
-- @return string|nil Error message if invalid
function validate_smpte_seconds(seconds)
  return _validate_integer_range(seconds, 'SMPTE seconds', 0, 59)
end

--- Assert that a SMPTE seconds value is valid, throws error if not.
-- @param seconds number The seconds value to validate
-- @raise error if seconds is invalid
function assert_smpte_seconds(seconds)
  local valid, err = validate_smpte_seconds(seconds)
  if not valid then error(err, 2) end
end

--- Validate a SMPTE frames value (0-29).
-- Valid for all SMPTE frame rates (24, 25, 29.97, 30 fps).
-- @param frames number The frames value to validate
-- @return boolean True if valid, false otherwise
-- @return string|nil Error message if invalid
function validate_smpte_frames(frames)
  return _validate_integer_range(frames, 'SMPTE frames', 0, 29)
end

--- Assert that a SMPTE frames value is valid, throws error if not.
-- @param frames number The frames value to validate
-- @raise error if frames is invalid
function assert_smpte_frames(frames)
  local valid, err = validate_smpte_frames(frames)
  if not valid then error(err, 2) end
end

--- Validate a SMPTE fractional frames value (0-99).
-- Represents 1/100ths of a frame.
-- @param fractional_frames number The fractional frames value to validate
-- @return boolean True if valid, false otherwise
-- @return string|nil Error message if invalid
function validate_smpte_fractional_frames(fractional_frames)
  return _validate_integer_range(
    fractional_frames, 'SMPTE fractional frames', 0, 99)
end

--- Assert that a SMPTE fractional frames value is valid, throws error if not.
-- @param fractional_frames number The fractional frames value to validate
-- @raise error if fractional frames is invalid
function assert_smpte_fractional_frames(fractional_frames)
  local valid, err = validate_smpte_fractional_frames(fractional_frames)
  if not valid then error(err, 2) end
end

--- Validate a MIDI ticks-per-quarter-note value (1-32767).
-- @param ticks number The ticks value to validate
-- @return boolean True if valid, false otherwise
-- @return string|nil Error message if invalid
function validate_ticks(ticks)
  return _validate_integer_range(ticks, 'Ticks per quarter note', 1, 0x7FFF)
end

--- Assert that a ticks-per-quarter-note value is valid, throws error if not.
-- @param ticks number The ticks value to validate
-- @raise error if ticks is invalid
function assert_ticks(ticks)
  local valid, err = validate_ticks(ticks)
  if not valid then error(err, 2) end
end

return _M
