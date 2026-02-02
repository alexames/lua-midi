--- MIDI I/O Module.
-- This module provides low-level I/O functions for reading and writing
-- unsigned integers in big-endian format (network byte order).
-- These functions are used for reading/writing MIDI file headers and events.
--
-- @module midi.io
-- @copyright 2024 Alexander Ames
-- @license MIT

local llx = require 'llx'

-- Set up module environment
local _ENV, _M = llx.environment.create_module_environment()

--- Write a 32-bit unsigned integer to a file in big-endian byte order.
-- @param file file An open file handle for writing
-- @param i number The integer to write (0 <= i <= 0xFFFFFFFF)
function writeUInt32be(file, i)
  file:write(
    string.char(
      (i >> 24) & 0xFF,
      (i >> 16) & 0xFF,
      (i >> 8) & 0xFF,
      (i >> 0) & 0xFF))
end

--- Write a 16-bit unsigned integer to a file in big-endian byte order.
-- @param file file An open file handle for writing
-- @param i number The integer to write (0 <= i <= 0xFFFF)
function writeUInt16be(file, i)
  file:write(
    string.char(
      (i >> 8) & 0xFF,
      (i >> 0) & 0xFF))
end

--- Write an 8-bit unsigned integer to a file.
-- @param file file An open file handle for writing
-- @param i number The integer to write (0 <= i <= 0xFF)
function writeUInt8be(file, i)
  file:write(
    string.char(
      (i >> 0) & 0xFF))  -- Single byte
end

--- Read a 32-bit unsigned integer from a file in big-endian byte order.
-- @param file file An open file handle for reading
-- @return number The 32-bit integer value
function readUInt32be(file)
  local a, b, c, d = file:read(4):byte(1, 4)
  return (a << 24)
       | (b << 16)
       | (c << 8)
       | (d << 0)
end

--- Read a 16-bit unsigned integer from a file in big-endian byte order.
-- @param file file An open file handle for reading
-- @return number The 16-bit integer value
function readUInt16be(file)
  local a, b = file:read(2):byte(1, 2)
  return (a << 8)
       | (b << 0)
end

--- Read an 8-bit unsigned integer from a file.
-- @param file file An open file handle for reading
-- @return number The 8-bit integer value
function readUInt8be(file)
  return file:read(1):byte(1)
end

return _M
