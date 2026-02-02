-- test_format_validation.lua
-- Unit tests for MIDI format validation

local unit = require 'llx.unit'

local MidiFile = require 'lua-midi.midi_file'.MidiFile
local Track = require 'lua-midi.track'.Track

_ENV = unit.create_test_env(_ENV)

describe('FormatHelperTests', function()
  it('should return true for is_format_0 when format is 0', function()
    local mf = MidiFile{format = 0}
    expect(mf:is_format_0()).to.be_truthy()
  end)

  it('should return false for is_format_1 when format is 0', function()
    local mf = MidiFile{format = 0}
    expect(mf:is_format_1()).to.be_falsy()
  end)

  it('should return false for is_format_2 when format is 0', function()
    local mf = MidiFile{format = 0}
    expect(mf:is_format_2()).to.be_falsy()
  end)

  it('should return false for is_format_0 when format is 1', function()
    local mf = MidiFile{format = 1}
    expect(mf:is_format_0()).to.be_falsy()
  end)

  it('should return true for is_format_1 when format is 1', function()
    local mf = MidiFile{format = 1}
    expect(mf:is_format_1()).to.be_truthy()
  end)

  it('should return false for is_format_2 when format is 1', function()
    local mf = MidiFile{format = 1}
    expect(mf:is_format_2()).to.be_falsy()
  end)

  it('should return false for is_format_0 when format is 2', function()
    local mf = MidiFile{format = 2}
    expect(mf:is_format_0()).to.be_falsy()
  end)

  it('should return false for is_format_1 when format is 2', function()
    local mf = MidiFile{format = 2}
    expect(mf:is_format_1()).to.be_falsy()
  end)

  it('should return true for is_format_2 when format is 2', function()
    local mf = MidiFile{format = 2}
    expect(mf:is_format_2()).to.be_truthy()
  end)

  it('should return correct format name for format 0', function()
    local mf = MidiFile{format = 0}
    expect(mf:get_format_name()).to.be_equal_to('Format 0 (Single Track)')
  end)

  it('should return correct format name for format 1', function()
    local mf = MidiFile{format = 1}
    expect(mf:get_format_name()).to.be_equal_to('Format 1 (Multi-Track Synchronous)')
  end)

  it('should return correct format name for format 2', function()
    local mf = MidiFile{format = 2}
    expect(mf:get_format_name()).to.be_equal_to('Format 2 (Multi-Track Asynchronous)')
  end)

  it('should include Unknown in format name for unknown format', function()
    local mf = MidiFile{format = 99}
    local name = mf:get_format_name()
    expect(name:match('Unknown')).to.be_truthy()
  end)

  it('should include format number in format name for unknown format', function()
    local mf = MidiFile{format = 99}
    local name = mf:get_format_name()
    expect(name:match('99')).to.be_truthy()
  end)
end)

describe('Format0ValidationTests', function()
  it('should validate format 0 with 1 track as valid', function()
    local mf = MidiFile{format = 0}
    table.insert(mf.tracks, Track())
    local valid, err = mf:validate_format()
    expect(valid).to.be_truthy()
  end)

  it('should return nil error for valid format 0', function()
    local mf = MidiFile{format = 0}
    table.insert(mf.tracks, Track())
    local valid, err = mf:validate_format()
    expect(err).to.be_nil()
  end)

  it('should validate format 0 with 0 tracks as invalid', function()
    local mf = MidiFile{format = 0}
    local valid, err = mf:validate_format()
    expect(valid).to.be_falsy()
  end)

  it('should include exactly 1 track in error message for format 0 with 0 tracks', function()
    local mf = MidiFile{format = 0}
    local valid, err = mf:validate_format()
    expect(err:match('exactly 1 track')).to.be_truthy()
  end)

  it('should include 0 track in error message for format 0 with 0 tracks', function()
    local mf = MidiFile{format = 0}
    local valid, err = mf:validate_format()
    expect(err:match('0 track')).to.be_truthy()
  end)

  it('should validate format 0 with 2 tracks as invalid', function()
    local mf = MidiFile{format = 0}
    table.insert(mf.tracks, Track())
    table.insert(mf.tracks, Track())
    local valid, err = mf:validate_format()
    expect(valid).to.be_falsy()
  end)

  it('should include exactly 1 track in error message for format 0 with 2 tracks', function()
    local mf = MidiFile{format = 0}
    table.insert(mf.tracks, Track())
    table.insert(mf.tracks, Track())
    local valid, err = mf:validate_format()
    expect(err:match('exactly 1 track')).to.be_truthy()
  end)

  it('should include 2 track in error message for format 0 with 2 tracks', function()
    local mf = MidiFile{format = 0}
    table.insert(mf.tracks, Track())
    table.insert(mf.tracks, Track())
    local valid, err = mf:validate_format()
    expect(err:match('2 track')).to.be_truthy()
  end)

  it('should throw error when assert_valid_format is called on invalid format 0', function()
    local mf = MidiFile{format = 0}
    table.insert(mf.tracks, Track())
    table.insert(mf.tracks, Track())
    local success = pcall(function()
      mf:assert_valid_format()
    end)
    expect(success).to.be_falsy()
  end)
end)

describe('Format1ValidationTests', function()
  it('should validate format 1 with 0 tracks as valid', function()
    local mf = MidiFile{format = 1}
    local valid = mf:validate_format()
    expect(valid).to.be_truthy()
  end)

  it('should validate format 1 with 1 track as valid', function()
    local mf = MidiFile{format = 1}
    table.insert(mf.tracks, Track())
    local valid = mf:validate_format()
    expect(valid).to.be_truthy()
  end)

  it('should validate format 1 with multiple tracks as valid', function()
    local mf = MidiFile{format = 1}
    table.insert(mf.tracks, Track())
    table.insert(mf.tracks, Track())
    table.insert(mf.tracks, Track())
    local valid = mf:validate_format()
    expect(valid).to.be_truthy()
  end)
end)

describe('Format2ValidationTests', function()
  it('should validate format 2 with 0 tracks as valid', function()
    local mf = MidiFile{format = 2}
    local valid = mf:validate_format()
    expect(valid).to.be_truthy()
  end)

  it('should validate format 2 with multiple tracks as valid', function()
    local mf = MidiFile{format = 2}
    table.insert(mf.tracks, Track())
    table.insert(mf.tracks, Track())
    local valid = mf:validate_format()
    expect(valid).to.be_truthy()
  end)

  it('should return correct track when get_pattern is called with index 1', function()
    local mf = MidiFile{format = 2}
    local track1 = Track()
    local track2 = Track()
    table.insert(mf.tracks, track1)
    table.insert(mf.tracks, track2)
    
    expect(mf:get_pattern(1)).to.be_equal_to(track1)
  end)

  it('should return correct track when get_pattern is called with index 2', function()
    local mf = MidiFile{format = 2}
    local track1 = Track()
    local track2 = Track()
    table.insert(mf.tracks, track1)
    table.insert(mf.tracks, track2)
    
    expect(mf:get_pattern(2)).to.be_equal_to(track2)
  end)

  it('should return correct count when get_pattern_count is called', function()
    local mf = MidiFile{format = 2}
    table.insert(mf.tracks, Track())
    table.insert(mf.tracks, Track())
    table.insert(mf.tracks, Track())
    
    expect(mf:get_pattern_count()).to.be_equal_to(3)
  end)

  it('should throw error when get_pattern is called for non-format-2', function()
    local mf = MidiFile{format = 1}
    table.insert(mf.tracks, Track())
    
    local success = pcall(function()
      mf:get_pattern(1)
    end)
    expect(success).to.be_falsy()
  end)

  it('should throw error when get_pattern_count is called for non-format-2', function()
    local mf = MidiFile{format = 1}
    
    local success = pcall(function()
      mf:get_pattern_count()
    end)
    expect(success).to.be_falsy()
  end)
end)

describe('InvalidFormatTests', function()
  it('should validate negative format number as invalid', function()
    local mf = MidiFile{format = -1}
    local valid, err = mf:validate_format()
    expect(valid).to.be_falsy()
  end)

  it('should include Invalid format number in error message for negative format', function()
    local mf = MidiFile{format = -1}
    local valid, err = mf:validate_format()
    expect(err:match('Invalid format number')).to.be_truthy()
  end)

  it('should validate format number greater than 2 as invalid', function()
    local mf = MidiFile{format = 3}
    local valid, err = mf:validate_format()
    expect(valid).to.be_falsy()
  end)

  it('should include Invalid format number in error message for format > 2', function()
    local mf = MidiFile{format = 3}
    local valid, err = mf:validate_format()
    expect(err:match('Invalid format number')).to.be_truthy()
  end)
end)

describe('WriteValidationTests', function()
  it('should throw error when write is called on invalid format', function()
    local mf = MidiFile{format = 0}
    -- Format 0 with 0 tracks is invalid
    
    local success = pcall(function()
      local bytes = mf:__tobytes()
    end)
    expect(success).to.be_falsy()
  end)

  it('should succeed when write is called on valid format', function()
    local mf = MidiFile{format = 0}
    table.insert(mf.tracks, Track())
    
    local bytes = mf:__tobytes()
    expect(#bytes > 0).to.be_truthy()
  end)
end)

run_unit_tests()
