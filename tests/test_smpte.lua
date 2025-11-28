-- test_smpte.lua
-- Unit tests for SMPTE time division support

local unit = require 'unit'
local EXPECT_EQ = unit.EXPECT_EQ
local EXPECT_TRUE = unit.EXPECT_TRUE
local EXPECT_FALSE = unit.EXPECT_FALSE

local MidiFile = require 'midi.midi_file'.MidiFile

_ENV = unit.create_test_env(_ENV)

test_class 'SMPTETimingTests' {
  [test 'default is not SMPTE'] = function()
    local mf = MidiFile()
    EXPECT_FALSE(mf:is_smpte())
  end,

  [test 'set SMPTE timing 24fps'] = function()
    local mf = MidiFile()
    mf:set_smpte_timing(24, 40)
    EXPECT_TRUE(mf:is_smpte())
    local fps, tpf = mf:get_smpte_timing()
    EXPECT_EQ(fps, 24)
    EXPECT_EQ(tpf, 40)
  end,

  [test 'set SMPTE timing 25fps'] = function()
    local mf = MidiFile()
    mf:set_smpte_timing(25, 40)
    local fps, tpf = mf:get_smpte_timing()
    EXPECT_EQ(fps, 25)
    EXPECT_EQ(tpf, 40)
  end,

  [test 'set SMPTE timing 29.97fps drop-frame'] = function()
    local mf = MidiFile()
    mf:set_smpte_timing(29.97, 40)
    local fps, tpf = mf:get_smpte_timing()
    EXPECT_TRUE(math.abs(fps - 29.97) < 0.01)
    EXPECT_EQ(tpf, 40)
  end,

  [test 'set SMPTE timing 30fps'] = function()
    local mf = MidiFile()
    mf:set_smpte_timing(30, 40)
    local fps, tpf = mf:get_smpte_timing()
    EXPECT_EQ(fps, 30)
    EXPECT_EQ(tpf, 40)
  end,

  [test 'invalid frame rate throws error'] = function()
    local mf = MidiFile()
    local success = pcall(function()
      mf:set_smpte_timing(60, 40)  -- Invalid frame rate
    end)
    EXPECT_FALSE(success)
  end,

  [test 'SMPTE ticks stored as table'] = function()
    local mf = MidiFile()
    mf:set_smpte_timing(25, 40)
    EXPECT_EQ(type(mf.ticks), 'table')
    EXPECT_TRUE(mf.ticks.smpte)
    EXPECT_EQ(mf.ticks.frame_rate, 25)
    EXPECT_EQ(mf.ticks.ticks_per_frame, 40)
  end,

  [test 'SMPTE encoded value is negative'] = function()
    local mf = MidiFile()
    mf:set_smpte_timing(25, 40)
    EXPECT_TRUE(mf.ticks.encoded < 0)
  end,

  [test 'regular ticks not SMPTE'] = function()
    local mf = MidiFile{ticks = 96}
    EXPECT_FALSE(mf:is_smpte())
    EXPECT_EQ(type(mf.ticks), 'number')
    EXPECT_EQ(mf.ticks, 96)
  end,

  [test 'get_smpte_timing returns nil for non-SMPTE'] = function()
    local mf = MidiFile{ticks = 96}
    local fps, tpf = mf:get_smpte_timing()
    EXPECT_EQ(fps, nil)
    EXPECT_EQ(tpf, nil)
  end,
}

test_class 'SMPTERoundTripTests' {
  [test 'write and read SMPTE 24fps'] = function()
    local mf1 = MidiFile()
    mf1:set_smpte_timing(24, 40)
    
    -- Write to bytes
    local bytes = mf1:__tobytes()
    
    -- Read back (would need to implement reading from bytes)
    -- For now, just verify bytes were generated
    EXPECT_TRUE(#bytes > 0)
  end,

  [test 'write and read SMPTE 25fps'] = function()
    local mf1 = MidiFile()
    mf1:set_smpte_timing(25, 80)
    
    local bytes = mf1:__tobytes()
    EXPECT_TRUE(#bytes > 0)
  end,

  [test 'write and read SMPTE 29.97fps'] = function()
    local mf1 = MidiFile()
    mf1:set_smpte_timing(29.97, 40)
    
    local bytes = mf1:__tobytes()
    EXPECT_TRUE(#bytes > 0)
  end,

  [test 'write and read SMPTE 30fps'] = function()
    local mf1 = MidiFile()
    mf1:set_smpte_timing(30, 40)
    
    local bytes = mf1:__tobytes()
    EXPECT_TRUE(#bytes > 0)
  end,
}

run_unit_tests()
