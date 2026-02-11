-- test_io.lua
-- Unit tests for midi.io (binary I/O operations)

local unit = require 'llx.unit'

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

  it('should error on EOF when reading UInt32be', function()
    local fake_file = { read = function() return nil end }
    local ok, err = pcall(io_util.readUInt32be, fake_file)
    expect(ok).to.be_falsy()
    expect(tostring(err):match('Unexpected end of MIDI data')).to.be_truthy()
  end)

  it('should error on short read for UInt16be', function()
    local fake_file = { read = function() return '\x00' end }
    local ok, err = pcall(io_util.readUInt16be, fake_file)
    expect(ok).to.be_falsy()
    expect(tostring(err):match('Unexpected end of MIDI data')).to.be_truthy()
  end)

  it('should error on EOF when reading UInt8be', function()
    local fake_file = { read = function() return nil end }
    local ok, err = pcall(io_util.readUInt8be, fake_file)
    expect(ok).to.be_falsy()
    expect(tostring(err):match('Unexpected end of MIDI data')).to.be_truthy()
  end)
end)

run_unit_tests()
