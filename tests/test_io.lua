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

  it('should write and read UInt14le correctly at center value', function()
    local pos = 0
    local buffer = {}
    local fake_file = {
      write = function(_, s) table.insert(buffer, s) end,
      read = function(_, n)
        local joined = table.concat(buffer)
        local result = joined:sub(pos + 1, pos + n)
        pos = pos + n
        return result
      end
    }
    io_util.writeUInt14le(fake_file, 8192)
    local read = io_util.readUInt14le(fake_file)
    expect(read).to.be_equal_to(8192)
  end)

  it('should write and read UInt14le correctly at boundaries', function()
    for _, value in ipairs({0, 1, 127, 128, 8192, 16383}) do
      local pos = 0
      local buffer = {}
      local fake_file = {
        write = function(_, s) table.insert(buffer, s) end,
        read = function(_, n)
          local joined = table.concat(buffer)
          local result = joined:sub(pos + 1, pos + n)
          pos = pos + n
          return result
        end
      }
      io_util.writeUInt14le(fake_file, value)
      local read = io_util.readUInt14le(fake_file)
      expect(read).to.be_equal_to(value)
    end
  end)
end)

describe('WriteRangeValidationTests', function()
  local function null_file()
    return { write = function() end }
  end

  it('should reject writeUInt8be with value > 255', function()
    local ok = pcall(io_util.writeUInt8be, null_file(), 256)
    expect(ok).to.be_falsy()
  end)

  it('should reject writeUInt8be with negative value', function()
    local ok = pcall(io_util.writeUInt8be, null_file(), -1)
    expect(ok).to.be_falsy()
  end)

  it('should accept writeUInt8be at boundaries', function()
    io_util.writeUInt8be(null_file(), 0)
    io_util.writeUInt8be(null_file(), 255)
  end)

  it('should reject writeUInt16be with value > 65535', function()
    local ok = pcall(io_util.writeUInt16be, null_file(), 65536)
    expect(ok).to.be_falsy()
  end)

  it('should reject writeUInt16be with negative value', function()
    local ok = pcall(io_util.writeUInt16be, null_file(), -1)
    expect(ok).to.be_falsy()
  end)

  it('should accept writeUInt16be at boundaries', function()
    io_util.writeUInt16be(null_file(), 0)
    io_util.writeUInt16be(null_file(), 65535)
  end)

  it('should reject writeUInt32be with value > 0xFFFFFFFF', function()
    local ok = pcall(io_util.writeUInt32be, null_file(), 0x100000000)
    expect(ok).to.be_falsy()
  end)

  it('should reject writeUInt32be with negative value', function()
    local ok = pcall(io_util.writeUInt32be, null_file(), -1)
    expect(ok).to.be_falsy()
  end)

  it('should accept writeUInt32be at boundaries', function()
    io_util.writeUInt32be(null_file(), 0)
    io_util.writeUInt32be(null_file(), 0xFFFFFFFF)
  end)

  it('should reject writeUInt14le with value > 16383', function()
    local ok = pcall(io_util.writeUInt14le, null_file(), 16384)
    expect(ok).to.be_falsy()
  end)

  it('should reject writeUInt14le with negative value', function()
    local ok = pcall(io_util.writeUInt14le, null_file(), -1)
    expect(ok).to.be_falsy()
  end)

  it('should accept writeUInt14le at boundaries', function()
    io_util.writeUInt14le(null_file(), 0)
    io_util.writeUInt14le(null_file(), 16383)
  end)
end)

run_unit_tests()
