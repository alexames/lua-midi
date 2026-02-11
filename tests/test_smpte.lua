-- test_smpte.lua
-- Unit tests for SMPTE time division support

local unit = require 'llx.unit'

local midi_file = require 'lua-midi.midi_file'
local MidiFile = midi_file.MidiFile
local SmpteDivision = midi_file.SmpteDivision

_ENV = unit.create_test_env(_ENV)

describe('SMPTETimingTests', function()
  it('should return false for is_smpte by default', function()
    local mf = MidiFile()
    expect(mf:is_smpte()).to.be_falsy()
  end)

  it('should return true for is_smpte when SMPTE timing is set to 24fps', function()
    local mf = MidiFile()
    mf:set_smpte_timing(24, 40)
    expect(mf:is_smpte()).to.be_truthy()
  end)

  it('should return correct fps when SMPTE timing is set to 24fps', function()
    local mf = MidiFile()
    mf:set_smpte_timing(24, 40)
    local fps, tpf = mf:get_smpte_timing()
    expect(fps).to.be_equal_to(24)
  end)

  it('should return correct ticks per frame when SMPTE timing is set to 24fps', function()
    local mf = MidiFile()
    mf:set_smpte_timing(24, 40)
    local fps, tpf = mf:get_smpte_timing()
    expect(tpf).to.be_equal_to(40)
  end)

  it('should return correct fps when SMPTE timing is set to 25fps', function()
    local mf = MidiFile()
    mf:set_smpte_timing(25, 40)
    local fps, tpf = mf:get_smpte_timing()
    expect(fps).to.be_equal_to(25)
  end)

  it('should return correct ticks per frame when SMPTE timing is set to 25fps', function()
    local mf = MidiFile()
    mf:set_smpte_timing(25, 40)
    local fps, tpf = mf:get_smpte_timing()
    expect(tpf).to.be_equal_to(40)
  end)

  it('should return correct fps when SMPTE timing is set to 29.97fps drop-frame', function()
    local mf = MidiFile()
    mf:set_smpte_timing(29.97, 40)
    local fps, tpf = mf:get_smpte_timing()
    expect(math.abs(fps - 29.97) < 0.01).to.be_truthy()
  end)

  it('should return correct ticks per frame when SMPTE timing is set to 29.97fps', function()
    local mf = MidiFile()
    mf:set_smpte_timing(29.97, 40)
    local fps, tpf = mf:get_smpte_timing()
    expect(tpf).to.be_equal_to(40)
  end)

  it('should return correct fps when SMPTE timing is set to 30fps', function()
    local mf = MidiFile()
    mf:set_smpte_timing(30, 40)
    local fps, tpf = mf:get_smpte_timing()
    expect(fps).to.be_equal_to(30)
  end)

  it('should return correct ticks per frame when SMPTE timing is set to 30fps', function()
    local mf = MidiFile()
    mf:set_smpte_timing(30, 40)
    local fps, tpf = mf:get_smpte_timing()
    expect(tpf).to.be_equal_to(40)
  end)

  it('should throw error when invalid frame rate is set', function()
    local mf = MidiFile()
    local success = pcall(function()
      mf:set_smpte_timing(60, 40)  -- Invalid frame rate
    end)
    expect(success).to.be_falsy()
  end)

  it('should store SMPTE ticks as SmpteDivision when SMPTE timing is set', function()
    local mf = MidiFile()
    mf:set_smpte_timing(25, 40)
    expect(mf:is_smpte()).to.be_truthy()
  end)

  it('should store frame rate when SMPTE timing is set', function()
    local mf = MidiFile()
    mf:set_smpte_timing(25, 40)
    expect(mf.ticks.frame_rate).to.be_equal_to(25)
  end)

  it('should store ticks per frame when SMPTE timing is set', function()
    local mf = MidiFile()
    mf:set_smpte_timing(25, 40)
    expect(mf.ticks.ticks_per_frame).to.be_equal_to(40)
  end)

  it('should encode SMPTE value as negative', function()
    local mf = MidiFile()
    mf:set_smpte_timing(25, 40)
    expect(mf.ticks.encoded < 0).to.be_truthy()
  end)

  it('should return false for is_smpte when regular ticks are used', function()
    local mf = MidiFile{ticks = 96}
    expect(mf:is_smpte()).to.be_falsy()
  end)

  it('should store regular ticks as number', function()
    local mf = MidiFile{ticks = 96}
    expect(type(mf.ticks) == 'number').to.be_truthy()
  end)

  it('should store correct value for regular ticks', function()
    local mf = MidiFile{ticks = 96}
    expect(mf.ticks).to.be_equal_to(96)
  end)

  it('should return nil fps when get_smpte_timing is called on non-SMPTE file', function()
    local mf = MidiFile{ticks = 96}
    local fps, tpf = mf:get_smpte_timing()
    expect(fps).to.be_nil()
  end)

  it('should return nil ticks per frame when get_smpte_timing is called on non-SMPTE file', function()
    local mf = MidiFile{ticks = 96}
    local fps, tpf = mf:get_smpte_timing()
    expect(tpf).to.be_nil()
  end)
end)

describe('SmpteDivisionTests', function()
  it('should create SmpteDivision with correct frame rate', function()
    local sd = SmpteDivision(25, 40)
    expect(sd.frame_rate).to.be_equal_to(25)
  end)

  it('should create SmpteDivision with correct ticks per frame', function()
    local sd = SmpteDivision(25, 40)
    expect(sd.ticks_per_frame).to.be_equal_to(40)
  end)

  it('should reject invalid frame rate', function()
    local ok = pcall(function() SmpteDivision(60, 40) end)
    expect(ok).to.be_falsy()
  end)

  it('should consider identical SmpteDivisions equal', function()
    local a = SmpteDivision(24, 40)
    local b = SmpteDivision(24, 40)
    expect(a == b).to.be_truthy()
  end)

  it('should consider SmpteDivisions with different frame rates unequal', function()
    local a = SmpteDivision(24, 40)
    local b = SmpteDivision(25, 40)
    expect(a == b).to.be_falsy()
  end)

  it('should consider SmpteDivisions with different ticks per frame unequal', function()
    local a = SmpteDivision(24, 40)
    local b = SmpteDivision(24, 80)
    expect(a == b).to.be_falsy()
  end)

  it('should clone SmpteDivision with equal values', function()
    local sd = SmpteDivision(30, 80)
    local c = sd:clone()
    expect(sd == c).to.be_truthy()
  end)

  it('should produce independent SmpteDivision clone', function()
    local sd = SmpteDivision(30, 80)
    local c = sd:clone()
    expect(rawequal(sd, c)).to.be_falsy()  -- different objects
  end)

  it('should convert SmpteDivision to readable string', function()
    local sd = SmpteDivision(25, 40)
    local str = tostring(sd)
    expect(str:match('SMPTE')).to.be_truthy()
    expect(str:match('25')).to.be_truthy()
    expect(str:match('40')).to.be_truthy()
  end)
end)

-- Helper: write a MidiFile to bytes, read it back, and return the parsed result.
local function write_and_read_back(mf)
  local bytes = mf:__tobytes()
  local tmp = io.tmpfile()
  tmp:write(bytes)
  tmp:seek('set', 0)
  local parsed = MidiFile.read(tmp)
  tmp:close()
  return parsed
end

describe('SMPTERoundTripTests', function()
  it('should round-trip SMPTE 24fps timing', function()
    local original = MidiFile()
    original:set_smpte_timing(24, 40)
    local parsed = write_and_read_back(original)
    expect(parsed:is_smpte()).to.be_truthy()
    local fps, tpf = parsed:get_smpte_timing()
    expect(fps).to.be_equal_to(24)
    expect(tpf).to.be_equal_to(40)
  end)

  it('should round-trip SMPTE 25fps timing', function()
    local original = MidiFile()
    original:set_smpte_timing(25, 80)
    local parsed = write_and_read_back(original)
    expect(parsed:is_smpte()).to.be_truthy()
    local fps, tpf = parsed:get_smpte_timing()
    expect(fps).to.be_equal_to(25)
    expect(tpf).to.be_equal_to(80)
  end)

  it('should round-trip SMPTE 29.97fps drop-frame timing', function()
    local original = MidiFile()
    original:set_smpte_timing(29.97, 40)
    local parsed = write_and_read_back(original)
    expect(parsed:is_smpte()).to.be_truthy()
    local fps, tpf = parsed:get_smpte_timing()
    expect(math.abs(fps - 29.97) < 0.01).to.be_truthy()
    expect(tpf).to.be_equal_to(40)
  end)

  it('should round-trip SMPTE 30fps timing', function()
    local original = MidiFile()
    original:set_smpte_timing(30, 40)
    local parsed = write_and_read_back(original)
    expect(parsed:is_smpte()).to.be_truthy()
    local fps, tpf = parsed:get_smpte_timing()
    expect(fps).to.be_equal_to(30)
    expect(tpf).to.be_equal_to(40)
  end)

  it('should preserve SMPTE equality through round-trip', function()
    local original = MidiFile()
    original:set_smpte_timing(25, 40)
    local parsed = write_and_read_back(original)
    expect(original == parsed).to.be_truthy()
  end)
end)

run_unit_tests()
