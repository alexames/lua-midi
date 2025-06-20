-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local llx = require 'llx'

local _ENV, _M = llx.environment.create_module_environment()

function writeUInt32be(file, i)
  file:write(
    string.char(
      (i >> 24) & 0xFF,
      (i >> 16) & 0xFF,
      (i >> 8) & 0xFF,
      (i >> 0) & 0xFF))
end

function writeUInt16be(file, i)
  file:write(
    string.char(
      (i >> 8) & 0xFF,
      (i >> 0) & 0xFF))
end

function writeUInt8be(file, i)
  file:write(
    string.char(
      (i >> 0) & 0xFF))
end

function readUInt32be(file)
  local a, b, c, d = file:read(4):byte(1, 4)
  return (a << 24)
       | (b << 16)
       | (c << 8)
       | (d << 0)
end

function readUInt16be(file)
  local a, b = file:read(2):byte(1, 2)
  return (a << 8)
       | (b << 0)
end

function readUInt8be(file)
  return file:read(1):byte(1)
end

return _M
