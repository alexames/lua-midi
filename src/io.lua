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
  assert(i >= 0 and i <= 0xFFFFFFFF, 'writeUInt32be: value out of range')
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
  assert(i >= 0 and i <= 0xFFFF, 'writeUInt16be: value out of range')
  file:write(
    string.char(
      (i >> 8) & 0xFF,
      (i >> 0) & 0xFF))
end

--- Write an 8-bit unsigned integer to a file.
-- @param file file An open file handle for writing
-- @param i number The integer to write (0 <= i <= 0xFF)
function writeUInt8be(file, i)
  assert(i >= 0 and i <= 0xFF, 'writeUInt8be: value out of range')
  file:write(
    string.char(
      (i >> 0) & 0xFF))  -- Single byte
end

--- Read exactly n bytes from a file, or error on short/EOF read.
-- @param file file An open file handle for reading
-- @param n number The number of bytes to read
-- @return string The bytes read
-- @raise error if fewer than n bytes are available
-- @local
local function _read_bytes(file, n)
  local bytes = file:read(n)
  if not bytes or #bytes ~= n then
    error(string.format(
      'Unexpected end of MIDI data (wanted %d bytes, got %d)',
      n, bytes and #bytes or 0), 3)
  end
  return bytes
end

--- Read a 32-bit unsigned integer from a file in big-endian byte order.
-- @param file file An open file handle for reading
-- @return number The 32-bit integer value
-- @raise error on unexpected EOF
function readUInt32be(file)
  local a, b, c, d = _read_bytes(file, 4):byte(1, 4)
  return (a << 24)
       | (b << 16)
       | (c << 8)
       | (d << 0)
end

--- Read a 16-bit unsigned integer from a file in big-endian byte order.
-- @param file file An open file handle for reading
-- @return number The 16-bit integer value
-- @raise error on unexpected EOF
function readUInt16be(file)
  local a, b = _read_bytes(file, 2):byte(1, 2)
  return (a << 8)
       | (b << 0)
end

--- Read an 8-bit unsigned integer from a file.
-- @param file file An open file handle for reading
-- @return number The 8-bit integer value
-- @raise error on unexpected EOF
function readUInt8be(file)
  return _read_bytes(file, 1):byte(1)
end

--- Write a 14-bit value as two 7-bit bytes, LSB first.
-- Used by MIDI pitch bend and song position pointer.
-- @param file file An open file handle for writing
-- @param i number The value to write (0 <= i <= 16383)
function writeUInt14le(file, i)
  assert(i >= 0 and i <= 0x3FFF, 'writeUInt14le: value out of range')
  writeUInt8be(file, i & 0x7F)
  writeUInt8be(file, (i >> 7) & 0x7F)
end

--- Read a 14-bit value from two 7-bit bytes, LSB first.
-- Used by MIDI pitch bend and song position pointer.
-- @param file file An open file handle for reading
-- @return number The 14-bit value (0-16383)
-- @raise error on unexpected EOF
function readUInt14le(file)
  local lsb = readUInt8be(file)
  local msb = readUInt8be(file)
  return (msb << 7) | lsb
end

--- Create a counting writer that tallies bytes written without storing them.
-- The returned object has a file-like `write` method and a `count` field.
-- @return table A counting writer with write(self, s) and count fields
function counting_writer()
  return {
    count = 0,
    write = function(self, s)
      self.count = self.count + #s
    end,
  }
end

return _M
