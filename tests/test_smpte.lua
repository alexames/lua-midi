-- test_smpte.lua
-- Unit tests for SMPTE time division support

local unit = require 'llx.unit'

local MidiFile = require 'lua-midi.midi_file'.MidiFile

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

  it('should store SMPTE ticks as table when SMPTE timing is set', function()
    local mf = MidiFile()
    mf:set_smpte_timing(25, 40)
    expect(type(mf.ticks) == 'table').to.be_truthy()
  end)

  it('should set smpte flag to true when SMPTE timing is set', function()
    local mf = MidiFile()
    mf:set_smpte_timing(25, 40)
    expect(mf.ticks.smpte).to.be_truthy()
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

describe('SMPTERoundTripTests', function()
  it('should generate bytes when writing SMPTE 24fps file', function()
    local mf1 = MidiFile()
    mf1:set_smpte_timing(24, 40)
    
    -- Write to bytes
    local bytes = mf1:__tobytes()
    
    -- Read back (would need to implement reading from bytes)
    -- For now, just verify bytes were generated
    expect(#bytes > 0).to.be_truthy()
  end)

  it('should generate bytes when writing SMPTE 25fps file', function()
    local mf1 = MidiFile()
    mf1:set_smpte_timing(25, 80)
    
    local bytes = mf1:__tobytes()
    expect(#bytes > 0).to.be_truthy()
  end)

  it('should generate bytes when writing SMPTE 29.97fps file', function()
    local mf1 = MidiFile()
    mf1:set_smpte_timing(29.97, 40)
    
    local bytes = mf1:__tobytes()
    expect(#bytes > 0).to.be_truthy()
  end)

  it('should generate bytes when writing SMPTE 30fps file', function()
    local mf1 = MidiFile()
    mf1:set_smpte_timing(30, 40)
    
    local bytes = mf1:__tobytes()
    expect(#bytes > 0).to.be_truthy()
  end)
end)

run_unit_tests()
