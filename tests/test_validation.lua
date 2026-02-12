-- test_validation.lua
-- Unit tests for MIDI validation utilities

local unit = require 'llx.unit'

local validation = require 'lua-midi.validation'

_ENV = unit.create_test_env(_ENV)

describe('ValidationTests', function()
  it('should accept channel 0 as valid', function()
    expect(validation.validate_channel(0)).to.be_truthy()
  end)

  it('should accept channel 7 as valid', function()
    expect(validation.validate_channel(7)).to.be_truthy()
  end)

  it('should accept channel 15 as valid', function()
    expect(validation.validate_channel(15)).to.be_truthy()
  end)

  it('should reject channel -1 as invalid', function()
    local valid, err = validation.validate_channel(-1)
    expect(valid).to.be_falsy()
  end)

  it('should include range in error message for channel -1', function()
    local valid, err = validation.validate_channel(-1)
    expect(err:match('0%-15')).to.be_truthy()
  end)

  it('should reject channel 16 as invalid', function()
    local valid, err = validation.validate_channel(16)
    expect(valid).to.be_falsy()
  end)

  it('should reject channel 5.5 as invalid', function()
    local valid, err = validation.validate_channel(5.5)
    expect(valid).to.be_falsy()
  end)

  it('should include integer in error message for channel 5.5', function()
    local valid, err = validation.validate_channel(5.5)
    expect(err:match('integer')).to.be_truthy()
  end)

  it('should report integer error for out-of-range float 15.5', function()
    local valid, err = validation.validate_channel(15.5)
    expect(valid).to.be_falsy()
    expect(err:match('integer')).to.be_truthy()
  end)

  it('should report integer error for negative float -0.5', function()
    local valid, err = validation.validate_note(-0.5)
    expect(valid).to.be_falsy()
    expect(err:match('integer')).to.be_truthy()
  end)

  it('should accept time delta 0 as valid', function()
    expect(validation.validate_time_delta(0)).to.be_truthy()
  end)

  it('should accept time delta at VLQ max as valid', function()
    expect(validation.validate_time_delta(0x0FFFFFFF)).to.be_truthy()
  end)

  it('should reject negative time delta', function()
    local valid, err = validation.validate_time_delta(-1)
    expect(valid).to.be_falsy()
  end)

  it('should reject time delta exceeding VLQ max', function()
    local valid, err = validation.validate_time_delta(0x10000000)
    expect(valid).to.be_falsy()
  end)

  it('should reject non-integer time delta', function()
    local valid, err = validation.validate_time_delta(1.5)
    expect(valid).to.be_falsy()
    expect(err:match('integer')).to.be_truthy()
  end)

  it('should accept note 0 as valid', function()
    expect(validation.validate_note(0)).to.be_truthy()
  end)

  it('should accept note 60 as valid', function()
    expect(validation.validate_note(60)).to.be_truthy()  -- Middle C
  end)

  it('should accept note 127 as valid', function()
    expect(validation.validate_note(127)).to.be_truthy()
  end)

  it('should reject note -1 as invalid', function()
    local valid, err = validation.validate_note(-1)
    expect(valid).to.be_falsy()
  end)

  it('should reject note 128 as invalid', function()
    local valid, err = validation.validate_note(128)
    expect(valid).to.be_falsy()
  end)

  it('should include range in error message for note 128', function()
    local valid, err = validation.validate_note(128)
    expect(err:match('0%-127')).to.be_truthy()
  end)

  it('should reject note 60.5 as invalid', function()
    local valid, err = validation.validate_note(60.5)
    expect(valid).to.be_falsy()
  end)

  it('should accept velocity 0 as valid', function()
    expect(validation.validate_velocity(0)).to.be_truthy()
  end)

  it('should accept velocity 64 as valid', function()
    expect(validation.validate_velocity(64)).to.be_truthy()
  end)

  it('should accept velocity 127 as valid', function()
    expect(validation.validate_velocity(127)).to.be_truthy()
  end)

  it('should reject velocity -1 as invalid', function()
    local valid, err = validation.validate_velocity(-1)
    expect(valid).to.be_falsy()
  end)

  it('should reject velocity 200 as invalid', function()
    local valid, err = validation.validate_velocity(200)
    expect(valid).to.be_falsy()
  end)

  it('should accept controller 0 as valid', function()
    expect(validation.validate_controller(0)).to.be_truthy()
  end)

  it('should accept controller 64 as valid', function()
    expect(validation.validate_controller(64)).to.be_truthy()
  end)

  it('should accept controller 127 as valid', function()
    expect(validation.validate_controller(127)).to.be_truthy()
  end)

  it('should reject controller 128 as invalid', function()
    local valid, err = validation.validate_controller(128)
    expect(valid).to.be_falsy()
  end)

  it('should accept program 0 as valid', function()
    expect(validation.validate_program(0)).to.be_truthy()
  end)

  it('should accept program 64 as valid', function()
    expect(validation.validate_program(64)).to.be_truthy()
  end)

  it('should accept program 127 as valid', function()
    expect(validation.validate_program(127)).to.be_truthy()
  end)

  it('should reject program -1 as invalid', function()
    local valid, err = validation.validate_program(-1)
    expect(valid).to.be_falsy()
  end)

  it('should reject program 128 as invalid', function()
    local valid, err = validation.validate_program(128)
    expect(valid).to.be_falsy()
  end)

  it('should accept pitch bend 0 as valid', function()
    expect(validation.validate_pitch_bend(0)).to.be_truthy()
  end)

  it('should accept pitch bend 8192 as valid', function()
    expect(validation.validate_pitch_bend(8192)).to.be_truthy()  -- Center
  end)

  it('should accept pitch bend 16383 as valid', function()
    expect(validation.validate_pitch_bend(16383)).to.be_truthy()
  end)

  it('should reject pitch bend -1 as invalid', function()
    local valid, err = validation.validate_pitch_bend(-1)
    expect(valid).to.be_falsy()
  end)

  it('should reject pitch bend 16384 as invalid', function()
    local valid, err = validation.validate_pitch_bend(16384)
    expect(valid).to.be_falsy()
  end)

  it('should include range in error message for pitch bend 16384', function()
    local valid, err = validation.validate_pitch_bend(16384)
    expect(err:match('0%-16383')).to.be_truthy()
  end)

  it('should accept 7-bit value 0 as valid', function()
    expect(validation.validate_7bit(0)).to.be_truthy()
  end)

  it('should accept 7-bit value 64 as valid', function()
    expect(validation.validate_7bit(64)).to.be_truthy()
  end)

  it('should accept 7-bit value 127 as valid', function()
    expect(validation.validate_7bit(127)).to.be_truthy()
  end)

  it('should reject 7-bit value 128 as invalid', function()
    local valid, err = validation.validate_7bit(128)
    expect(valid).to.be_falsy()
  end)

  it('should include custom name in error message'
    .. ' for 7-bit validation',
  function()
    local valid, err = validation.validate_7bit(200, 'CustomValue')
    expect(valid).to.be_falsy()
  end)

  it('should include CustomValue in error message', function()
    local valid, err = validation.validate_7bit(200, 'CustomValue')
    expect(err:match('CustomValue')).to.be_truthy()
  end)
end)

describe('AssertValidationTests', function()
  it('should throw error when assert_channel is called'
    .. ' with invalid channel',
  function()
    local success = pcall(function()
      validation.assert_channel(20)
    end)
    expect(success).to.be_falsy()
  end)

  it('should throw error when assert_note is called'
    .. ' with invalid note',
  function()
    local success = pcall(function()
      validation.assert_note(200)
    end)
    expect(success).to.be_falsy()
  end)

  it('should throw error when assert_velocity is called'
    .. ' with invalid velocity',
  function()
    local success = pcall(function()
      validation.assert_velocity(150)
    end)
    expect(success).to.be_falsy()
  end)

  it('should not throw when assert_channel is called'
    .. ' with valid channel',
  function()
    -- Should not throw
    validation.assert_channel(5)
  end)

  it('should not throw when assert_note is called with valid note', function()
    -- Should not throw
    validation.assert_note(60)
  end)

  it('should not throw when assert_velocity is called'
    .. ' with valid velocity',
  function()
    -- Should not throw
    validation.assert_velocity(100)
  end)

  it('should throw error when assert_controller is called'
    .. ' with invalid controller',
  function()
    local success = pcall(function()
      validation.assert_controller(200)
    end)
    expect(success).to.be_falsy()
  end)

  it('should not throw when assert_controller is called'
    .. ' with valid controller',
  function()
    -- Should not throw
    validation.assert_controller(7)
  end)

  it('should throw error when assert_program is called'
    .. ' with invalid program',
  function()
    local success = pcall(function()
      validation.assert_program(200)
    end)
    expect(success).to.be_falsy()
  end)

  it('should not throw when assert_program is called'
    .. ' with valid program',
  function()
    -- Should not throw
    validation.assert_program(42)
  end)

  it('should throw error when assert_pitch_bend is called'
    .. ' with invalid pitch bend',
  function()
    local success = pcall(function()
      validation.assert_pitch_bend(20000)
    end)
    expect(success).to.be_falsy()
  end)

  it('should not throw when assert_pitch_bend is called'
    .. ' with valid pitch bend',
  function()
    -- Should not throw
    validation.assert_pitch_bend(8192)
  end)

  it('should throw error when assert_tempo is called with zero', function()
    local success = pcall(function() validation.assert_tempo(0) end)
    expect(success).to.be_falsy()
  end)

  it('should not throw when assert_tempo is called with valid tempo', function()
    validation.assert_tempo(500000)
  end)

  it('should accept tempo at boundaries', function()
    validation.assert_tempo(1)
    validation.assert_tempo(0xFFFFFF)
  end)

  it('should reject tempo exceeding 3-byte max', function()
    local success = pcall(function() validation.assert_tempo(0xFFFFFF + 1) end)
    expect(success).to.be_falsy()
  end)

  it('should throw error when assert_sharps_flats is called'
    .. ' with out-of-range value',
  function()
    local success = pcall(function() validation.assert_sharps_flats(8) end)
    expect(success).to.be_falsy()
  end)

  it('should not throw when assert_sharps_flats is called'
    .. ' with valid value',
  function()
    validation.assert_sharps_flats(-7)
    validation.assert_sharps_flats(0)
    validation.assert_sharps_flats(7)
  end)

  it('should throw error when assert_boolean is called'
    .. ' with non-boolean',
  function()
    local success = pcall(function() validation.assert_boolean(1, 'test') end)
    expect(success).to.be_falsy()
  end)

  it('should not throw when assert_boolean is called with boolean', function()
    validation.assert_boolean(true, 'test')
    validation.assert_boolean(false, 'test')
  end)

  it('should throw error when assert_denominator is called'
    .. ' with non-power-of-2',
  function()
    local success = pcall(function() validation.assert_denominator(3) end)
    expect(success).to.be_falsy()
  end)

  it('should throw error when assert_denominator is called'
    .. ' with zero',
  function()
    local success = pcall(function() validation.assert_denominator(0) end)
    expect(success).to.be_falsy()
  end)

  it('should not throw when assert_denominator is called'
    .. ' with valid power of 2',
  function()
    for _, d in ipairs({1, 2, 4, 8, 16, 32, 64, 128, 256}) do
      validation.assert_denominator(d)
    end
  end)

  it('should throw error when assert_ticks is called with zero', function()
    local success = pcall(function() validation.assert_ticks(0) end)
    expect(success).to.be_falsy()
  end)

  it('should not throw when assert_ticks is called with valid value', function()
    validation.assert_ticks(1)
    validation.assert_ticks(480)
    validation.assert_ticks(0x7FFF)
  end)

  it('should reject ticks exceeding 15-bit max', function()
    local success = pcall(function() validation.assert_ticks(0x8000) end)
    expect(success).to.be_falsy()
  end)
end)

describe('SMPTEValidationTests', function()
  it('should accept valid SMPTE hours', function()
    validation.assert_smpte_hours(0)
    validation.assert_smpte_hours(23)
  end)

  it('should reject SMPTE hours out of range', function()
    local ok = pcall(function() validation.assert_smpte_hours(24) end)
    expect(ok).to.be_falsy()
    ok = pcall(function() validation.assert_smpte_hours(-1) end)
    expect(ok).to.be_falsy()
  end)

  it('should accept valid SMPTE minutes', function()
    validation.assert_smpte_minutes(0)
    validation.assert_smpte_minutes(59)
  end)

  it('should reject SMPTE minutes out of range', function()
    local ok = pcall(function() validation.assert_smpte_minutes(60) end)
    expect(ok).to.be_falsy()
  end)

  it('should accept valid SMPTE seconds', function()
    validation.assert_smpte_seconds(0)
    validation.assert_smpte_seconds(59)
  end)

  it('should reject SMPTE seconds out of range', function()
    local ok = pcall(function() validation.assert_smpte_seconds(60) end)
    expect(ok).to.be_falsy()
  end)

  it('should accept valid SMPTE frames', function()
    validation.assert_smpte_frames(0)
    validation.assert_smpte_frames(29)
  end)

  it('should reject SMPTE frames out of range', function()
    local ok = pcall(function() validation.assert_smpte_frames(30) end)
    expect(ok).to.be_falsy()
  end)

  it('should accept valid SMPTE fractional frames', function()
    validation.assert_smpte_fractional_frames(0)
    validation.assert_smpte_fractional_frames(99)
  end)

  it('should reject SMPTE fractional frames out of range', function()
    local ok = pcall(function()
      validation.assert_smpte_fractional_frames(100)
    end)
    expect(ok).to.be_falsy()
  end)
end)

run_unit_tests()
