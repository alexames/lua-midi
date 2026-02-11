--- MIDI Validation Module.
-- This module provides validation utilities for MIDI values to ensure they
-- conform to the MIDI specification constraints.
--
-- All validate_* functions return (true) on success or (false, error_message) on failure.
-- All assert_* functions throw an error if validation fails.
--
-- @module midi.validation
-- @copyright 2024 Alexander Ames
-- @license MIT
-- @usage
-- local validation = require 'lua-midi.validation'
--
-- -- Validate values
-- local ok, err = validation.validate_channel(16)  -- false, "Channel must be 0-15, got 16"
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
    return false, string.format('%s must be %d-%d, got %d', name, min, max, value)
  end
  return true
end

--- Validate a MIDI event time delta.
-- Time deltas must be non-negative integers that fit in VLQ encoding (0-268435455).
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

return _M
