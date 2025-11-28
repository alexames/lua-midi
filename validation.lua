-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>
--
-- This module provides validation utilities for MIDI values to ensure they
-- conform to the MIDI specification constraints.

local llx = require 'llx'

local _ENV, _M = llx.environment.create_module_environment()

--- Validates a MIDI channel number (0-15)
-- @param channel The channel number to validate
-- @return true if valid, false otherwise
-- @return error message if invalid
function validate_channel(channel)
  if type(channel) ~= 'number' then
    return false, 'Channel must be a number'
  end
  if channel < 0 or channel > 15 then
    return false, string.format('Channel must be 0-15, got %d', channel)
  end
  if channel ~= math.floor(channel) then
    return false, string.format('Channel must be an integer, got %f', channel)
  end
  return true
end

--- Validates a MIDI note number (0-127)
-- @param note The note number to validate
-- @return true if valid, false otherwise
-- @return error message if invalid
function validate_note(note)
  if type(note) ~= 'number' then
    return false, 'Note must be a number'
  end
  if note < 0 or note > 127 then
    return false, string.format('Note must be 0-127, got %d', note)
  end
  if note ~= math.floor(note) then
    return false, string.format('Note must be an integer, got %f', note)
  end
  return true
end

--- Validates a MIDI velocity (0-127)
-- @param velocity The velocity to validate
-- @return true if valid, false otherwise
-- @return error message if invalid
function validate_velocity(velocity)
  if type(velocity) ~= 'number' then
    return false, 'Velocity must be a number'
  end
  if velocity < 0 or velocity > 127 then
    return false, string.format('Velocity must be 0-127, got %d', velocity)
  end
  if velocity ~= math.floor(velocity) then
    return false, string.format('Velocity must be an integer, got %f', velocity)
  end
  return true
end

--- Validates a MIDI controller number (0-127)
-- @param controller The controller number to validate
-- @return true if valid, false otherwise
-- @return error message if invalid
function validate_controller(controller)
  if type(controller) ~= 'number' then
    return false, 'Controller must be a number'
  end
  if controller < 0 or controller > 127 then
    return false, string.format('Controller must be 0-127, got %d', controller)
  end
  if controller ~= math.floor(controller) then
    return false, string.format('Controller must be an integer, got %f', controller)
  end
  return true
end

--- Validates a MIDI program number (0-127)
-- @param program The program number to validate
-- @return true if valid, false otherwise
-- @return error message if invalid
function validate_program(program)
  if type(program) ~= 'number' then
    return false, 'Program must be a number'
  end
  if program < 0 or program > 127 then
    return false, string.format('Program must be 0-127, got %d', program)
  end
  if program ~= math.floor(program) then
    return false, string.format('Program must be an integer, got %f', program)
  end
  return true
end

--- Validates a MIDI pitch bend value (0-16383, center is 8192)
-- @param value The pitch bend value to validate
-- @return true if valid, false otherwise
-- @return error message if invalid
function validate_pitch_bend(value)
  if type(value) ~= 'number' then
    return false, 'Pitch bend must be a number'
  end
  if value < 0 or value > 16383 then
    return false, string.format('Pitch bend must be 0-16383, got %d', value)
  end
  if value ~= math.floor(value) then
    return false, string.format('Pitch bend must be an integer, got %f', value)
  end
  return true
end

--- Validates a 7-bit data value (0-127)
-- @param value The value to validate
-- @param name Optional name for error messages
-- @return true if valid, false otherwise
-- @return error message if invalid
function validate_7bit(value, name)
  name = name or 'Value'
  if type(value) ~= 'number' then
    return false, name .. ' must be a number'
  end
  if value < 0 or value > 127 then
    return false, string.format('%s must be 0-127, got %d', name, value)
  end
  if value ~= math.floor(value) then
    return false, string.format('%s must be an integer, got %f', name, value)
  end
  return true
end

--- Asserts that a channel is valid, throws error if not
-- @param channel The channel to validate
function assert_channel(channel)
  local valid, err = validate_channel(channel)
  if not valid then error(err, 2) end
end

--- Asserts that a note is valid, throws error if not
-- @param note The note to validate
function assert_note(note)
  local valid, err = validate_note(note)
  if not valid then error(err, 2) end
end

--- Asserts that a velocity is valid, throws error if not
-- @param velocity The velocity to validate
function assert_velocity(velocity)
  local valid, err = validate_velocity(velocity)
  if not valid then error(err, 2) end
end

--- Asserts that a controller is valid, throws error if not
-- @param controller The controller to validate
function assert_controller(controller)
  local valid, err = validate_controller(controller)
  if not valid then error(err, 2) end
end

--- Asserts that a program is valid, throws error if not
-- @param program The program to validate
function assert_program(program)
  local valid, err = validate_program(program)
  if not valid then error(err, 2) end
end

--- Asserts that a pitch bend value is valid, throws error if not
-- @param value The pitch bend value to validate
function assert_pitch_bend(value)
  local valid, err = validate_pitch_bend(value)
  if not valid then error(err, 2) end
end

return _M
