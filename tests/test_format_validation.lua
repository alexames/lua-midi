-- test_format_validation.lua
-- Unit tests for MIDI format validation

local unit = require 'unit'
local EXPECT_EQ = unit.EXPECT_EQ
local EXPECT_TRUE = unit.EXPECT_TRUE
local EXPECT_FALSE = unit.EXPECT_FALSE

local MidiFile = require 'midi.midi_file'.MidiFile
local Track = require 'midi.track'.Track

_ENV = unit.create_test_env(_ENV)

test_class 'FormatHelperTests' {
  [test 'is_format_0 returns true for format 0'] = function()
    local mf = MidiFile{format = 0}
    EXPECT_TRUE(mf:is_format_0())
    EXPECT_FALSE(mf:is_format_1())
    EXPECT_FALSE(mf:is_format_2())
  end,

  [test 'is_format_1 returns true for format 1'] = function()
    local mf = MidiFile{format = 1}
    EXPECT_FALSE(mf:is_format_0())
    EXPECT_TRUE(mf:is_format_1())
    EXPECT_FALSE(mf:is_format_2())
  end,

  [test 'is_format_2 returns true for format 2'] = function()
    local mf = MidiFile{format = 2}
    EXPECT_FALSE(mf:is_format_0())
    EXPECT_FALSE(mf:is_format_1())
    EXPECT_TRUE(mf:is_format_2())
  end,

  [test 'get_format_name for format 0'] = function()
    local mf = MidiFile{format = 0}
    EXPECT_EQ(mf:get_format_name(), 'Format 0 (Single Track)')
  end,

  [test 'get_format_name for format 1'] = function()
    local mf = MidiFile{format = 1}
    EXPECT_EQ(mf:get_format_name(), 'Format 1 (Multi-Track Synchronous)')
  end,

  [test 'get_format_name for format 2'] = function()
    local mf = MidiFile{format = 2}
    EXPECT_EQ(mf:get_format_name(), 'Format 2 (Multi-Track Asynchronous)')
  end,

  [test 'get_format_name for unknown format'] = function()
    local mf = MidiFile{format = 99}
    local name = mf:get_format_name()
    EXPECT_TRUE(name:match('Unknown'))
    EXPECT_TRUE(name:match('99'))
  end,
}

test_class 'Format0ValidationTests' {
  [test 'format 0 with 1 track is valid'] = function()
    local mf = MidiFile{format = 0}
    table.insert(mf.tracks, Track())
    local valid, err = mf:validate_format()
    EXPECT_TRUE(valid)
    EXPECT_EQ(err, nil)
  end,

  [test 'format 0 with 0 tracks is invalid'] = function()
    local mf = MidiFile{format = 0}
    local valid, err = mf:validate_format()
    EXPECT_FALSE(valid)
    EXPECT_TRUE(err:match('exactly 1 track'))
    EXPECT_TRUE(err:match('0 track'))
  end,

  [test 'format 0 with 2 tracks is invalid'] = function()
    local mf = MidiFile{format = 0}
    table.insert(mf.tracks, Track())
    table.insert(mf.tracks, Track())
    local valid, err = mf:validate_format()
    EXPECT_FALSE(valid)
    EXPECT_TRUE(err:match('exactly 1 track'))
    EXPECT_TRUE(err:match('2 track'))
  end,

  [test 'format 0 assert_valid_format throws on invalid'] = function()
    local mf = MidiFile{format = 0}
    table.insert(mf.tracks, Track())
    table.insert(mf.tracks, Track())
    local success = pcall(function()
      mf:assert_valid_format()
    end)
    EXPECT_FALSE(success)
  end,
}

test_class 'Format1ValidationTests' {
  [test 'format 1 with 0 tracks is valid'] = function()
    local mf = MidiFile{format = 1}
    local valid = mf:validate_format()
    EXPECT_TRUE(valid)
  end,

  [test 'format 1 with 1 track is valid'] = function()
    local mf = MidiFile{format = 1}
    table.insert(mf.tracks, Track())
    local valid = mf:validate_format()
    EXPECT_TRUE(valid)
  end,

  [test 'format 1 with multiple tracks is valid'] = function()
    local mf = MidiFile{format = 1}
    table.insert(mf.tracks, Track())
    table.insert(mf.tracks, Track())
    table.insert(mf.tracks, Track())
    local valid = mf:validate_format()
    EXPECT_TRUE(valid)
  end,
}

test_class 'Format2ValidationTests' {
  [test 'format 2 with 0 tracks is valid'] = function()
    local mf = MidiFile{format = 2}
    local valid = mf:validate_format()
    EXPECT_TRUE(valid)
  end,

  [test 'format 2 with multiple tracks is valid'] = function()
    local mf = MidiFile{format = 2}
    table.insert(mf.tracks, Track())
    table.insert(mf.tracks, Track())
    local valid = mf:validate_format()
    EXPECT_TRUE(valid)
  end,

  [test 'get_pattern returns correct track'] = function()
    local mf = MidiFile{format = 2}
    local track1 = Track()
    local track2 = Track()
    table.insert(mf.tracks, track1)
    table.insert(mf.tracks, track2)
    
    EXPECT_EQ(mf:get_pattern(1), track1)
    EXPECT_EQ(mf:get_pattern(2), track2)
  end,

  [test 'get_pattern_count returns correct count'] = function()
    local mf = MidiFile{format = 2}
    table.insert(mf.tracks, Track())
    table.insert(mf.tracks, Track())
    table.insert(mf.tracks, Track())
    
    EXPECT_EQ(mf:get_pattern_count(), 3)
  end,

  [test 'get_pattern throws for non-format-2'] = function()
    local mf = MidiFile{format = 1}
    table.insert(mf.tracks, Track())
    
    local success = pcall(function()
      mf:get_pattern(1)
    end)
    EXPECT_FALSE(success)
  end,

  [test 'get_pattern_count throws for non-format-2'] = function()
    local mf = MidiFile{format = 1}
    
    local success = pcall(function()
      mf:get_pattern_count()
    end)
    EXPECT_FALSE(success)
  end,
}

test_class 'InvalidFormatTests' {
  [test 'negative format number is invalid'] = function()
    local mf = MidiFile{format = -1}
    local valid, err = mf:validate_format()
    EXPECT_FALSE(valid)
    EXPECT_TRUE(err:match('Invalid format number'))
  end,

  [test 'format number > 2 is invalid'] = function()
    local mf = MidiFile{format = 3}
    local valid, err = mf:validate_format()
    EXPECT_FALSE(valid)
    EXPECT_TRUE(err:match('Invalid format number'))
  end,
}

test_class 'WriteValidationTests' {
  [test 'write validates format before writing'] = function()
    local mf = MidiFile{format = 0}
    -- Format 0 with 0 tracks is invalid
    
    local success = pcall(function()
      local bytes = mf:__tobytes()
    end)
    EXPECT_FALSE(success)
  end,

  [test 'write succeeds for valid format'] = function()
    local mf = MidiFile{format = 0}
    table.insert(mf.tracks, Track())
    
    local bytes = mf:__tobytes()
    EXPECT_TRUE(#bytes > 0)
  end,
}

run_unit_tests()
