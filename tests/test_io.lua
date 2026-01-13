-- test_io.lua
-- Unit tests for midi.io (binary I/O operations)

local unit = require 'unit'

local io_util = require 'lua-midi.io'

_ENV = unit.create_test_env(_ENV)

describe('MidiIoTests', function()
  it('should write and read UInt32be correctly', function()
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
    expect(read).to.be_equal_to(0x12345678)
  end)

  it('should write and read UInt16be correctly', function()
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
    expect(read).to.be_equal_to(0xABCD)
  end)

  it('should write and read UInt8be correctly', function()
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
    expect(read).to.be_equal_to(0x7F)
  end)
end)

run_unit_tests()
