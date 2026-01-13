-- test_validation.lua
-- Unit tests for MIDI validation utilities

local unit = require 'unit'

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

  it('should include custom name in error message for 7-bit validation', function()
    local valid, err = validation.validate_7bit(200, 'CustomValue')
    expect(valid).to.be_falsy()
  end)

  it('should include CustomValue in error message', function()
    local valid, err = validation.validate_7bit(200, 'CustomValue')
    expect(err:match('CustomValue')).to.be_truthy()
  end)
end)

describe('AssertValidationTests', function()
  it('should throw error when assert_channel is called with invalid channel', function()
    local success = pcall(function()
      validation.assert_channel(20)
    end)
    expect(success).to.be_falsy()
  end)

  it('should throw error when assert_note is called with invalid note', function()
    local success = pcall(function()
      validation.assert_note(200)
    end)
    expect(success).to.be_falsy()
  end)

  it('should throw error when assert_velocity is called with invalid velocity', function()
    local success = pcall(function()
      validation.assert_velocity(150)
    end)
    expect(success).to.be_falsy()
  end)

  it('should not throw when assert_channel is called with valid channel', function()
    -- Should not throw
    validation.assert_channel(5)
  end)

  it('should not throw when assert_note is called with valid note', function()
    -- Should not throw
    validation.assert_note(60)
  end)

  it('should not throw when assert_velocity is called with valid velocity', function()
    -- Should not throw
    validation.assert_velocity(100)
  end)

  it('should not throw when assert_controller is called with valid controller', function()
    -- Should not throw
    validation.assert_controller(7)
  end)

  it('should not throw when assert_program is called with valid program', function()
    -- Should not throw
    validation.assert_program(42)
  end)

  it('should not throw when assert_pitch_bend is called with valid pitch bend', function()
    -- Should not throw
    validation.assert_pitch_bend(8192)
  end)
end)

run_unit_tests()
