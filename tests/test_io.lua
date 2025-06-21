-- test_io.lua
-- Unit tests for midi.io (binary I/O operations)

local unit = require 'unit'
local EXPECT_EQ = unit.EXPECT_EQ
local EXPECT_TRUE = unit.EXPECT_TRUE

local io_util = require 'midi.io'

unit.test_class 'MidiIoTests' {
  ['writeUInt32be and readUInt32be'] = function()
    local buffer = {}
    local fake_file = {
      write = function(_, s) table.insert(buffer, s) end,
      read = function(_, n)
        local joined = table.concat(buffer)
        return joined:sub(1, n)
      end
    }

    io_util.writeUInt32be(fake_file, 0x12345678)
    local read = io_util.readUInt32be(fake_file)
    EXPECT_EQ(read, 0x12345678)
  end,

  ['writeUInt16be and readUInt16be'] = function()
    local buffer = {}
    local fake_file = {
      write = function(_, s) table.insert(buffer, s) end,
      read = function(_, n)
        local joined = table.concat(buffer)
        return joined:sub(1, n)
      end
    }

    io_util.writeUInt16be(fake_file, 0xABCD)
    local read = io_util.readUInt16be(fake_file)
    EXPECT_EQ(read, 0xABCD)
  end,

  ['writeUInt8be and readUInt8be'] = function()
    local buffer = {}
    local fake_file = {
      write = function(_, s) table.insert(buffer, s) end,
      read = function(_, n)
        local joined = table.concat(buffer)
        return joined:sub(1, n)
      end
    }

    io_util.writeUInt8be(fake_file, 0x7F)
    local read = io_util.readUInt8be(fake_file)
    EXPECT_EQ(read, 0x7F)
  end,
}
