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

return _M
