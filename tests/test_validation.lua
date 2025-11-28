-- test_validation.lua
-- Unit tests for MIDI validation utilities

local unit = require 'unit'
local EXPECT_EQ = unit.EXPECT_EQ
local EXPECT_TRUE = unit.EXPECT_TRUE
local EXPECT_FALSE = unit.EXPECT_FALSE

local validation = require 'midi.validation'

_ENV = unit.create_test_env(_ENV)

test_class 'ValidationTests' {
  [test 'validate_channel accepts valid channels'] = function()
    EXPECT_TRUE(validation.validate_channel(0))
    EXPECT_TRUE(validation.validate_channel(7))
    EXPECT_TRUE(validation.validate_channel(15))
  end,

  [test 'validate_channel rejects invalid channels'] = function()
    local valid, err = validation.validate_channel(-1)
    EXPECT_FALSE(valid)
    EXPECT_TRUE(err:match('0%-15'))
    
    valid, err = validation.validate_channel(16)
    EXPECT_FALSE(valid)
    
    valid, err = validation.validate_channel(5.5)
    EXPECT_FALSE(valid)
    EXPECT_TRUE(err:match('integer'))
  end,

  [test 'validate_note accepts valid notes'] = function()
    EXPECT_TRUE(validation.validate_note(0))
    EXPECT_TRUE(validation.validate_note(60))  -- Middle C
    EXPECT_TRUE(validation.validate_note(127))
  end,

  [test 'validate_note rejects invalid notes'] = function()
    local valid, err = validation.validate_note(-1)
    EXPECT_FALSE(valid)
    
    valid, err = validation.validate_note(128)
    EXPECT_FALSE(valid)
    EXPECT_TRUE(err:match('0%-127'))
    
    valid, err = validation.validate_note(60.5)
    EXPECT_FALSE(valid)
  end,

  [test 'validate_velocity accepts valid velocities'] = function()
    EXPECT_TRUE(validation.validate_velocity(0))
    EXPECT_TRUE(validation.validate_velocity(64))
    EXPECT_TRUE(validation.validate_velocity(127))
  end,

  [test 'validate_velocity rejects invalid velocities'] = function()
    local valid, err = validation.validate_velocity(-1)
    EXPECT_FALSE(valid)
    
    valid, err = validation.validate_velocity(200)
    EXPECT_FALSE(valid)
  end,

  [test 'validate_controller accepts valid controllers'] = function()
    EXPECT_TRUE(validation.validate_controller(0))
    EXPECT_TRUE(validation.validate_controller(64))
    EXPECT_TRUE(validation.validate_controller(127))
  end,

  [test 'validate_controller rejects invalid controllers'] = function()
    local valid, err = validation.validate_controller(128)
    EXPECT_FALSE(valid)
  end,

  [test 'validate_program accepts valid programs'] = function()
    EXPECT_TRUE(validation.validate_program(0))
    EXPECT_TRUE(validation.validate_program(64))
    EXPECT_TRUE(validation.validate_program(127))
  end,

  [test 'validate_program rejects invalid programs'] = function()
    local valid, err = validation.validate_program(-1)
    EXPECT_FALSE(valid)
    
    valid, err = validation.validate_program(128)
    EXPECT_FALSE(valid)
  end,

  [test 'validate_pitch_bend accepts valid values'] = function()
    EXPECT_TRUE(validation.validate_pitch_bend(0))
    EXPECT_TRUE(validation.validate_pitch_bend(8192))  -- Center
    EXPECT_TRUE(validation.validate_pitch_bend(16383))
  end,

  [test 'validate_pitch_bend rejects invalid values'] = function()
    local valid, err = validation.validate_pitch_bend(-1)
    EXPECT_FALSE(valid)
    
    valid, err = validation.validate_pitch_bend(16384)
    EXPECT_FALSE(valid)
    EXPECT_TRUE(err:match('0%-16383'))
  end,

  [test 'validate_7bit accepts valid values'] = function()
    EXPECT_TRUE(validation.validate_7bit(0))
    EXPECT_TRUE(validation.validate_7bit(64))
    EXPECT_TRUE(validation.validate_7bit(127))
  end,

  [test 'validate_7bit rejects invalid values'] = function()
    local valid, err = validation.validate_7bit(128)
    EXPECT_FALSE(valid)
  end,

  [test 'validate_7bit custom name in error'] = function()
    local valid, err = validation.validate_7bit(200, 'CustomValue')
    EXPECT_FALSE(valid)
    EXPECT_TRUE(err:match('CustomValue'))
  end,
}

test_class 'AssertValidationTests' {
  [test 'assert_channel throws on invalid'] = function()
    local success = pcall(function()
      validation.assert_channel(20)
    end)
    EXPECT_FALSE(success)
  end,

  [test 'assert_note throws on invalid'] = function()
    local success = pcall(function()
      validation.assert_note(200)
    end)
    EXPECT_FALSE(success)
  end,

  [test 'assert_velocity throws on invalid'] = function()
    local success = pcall(function()
      validation.assert_velocity(150)
    end)
    EXPECT_FALSE(success)
  end,

  [test 'assert functions pass on valid values'] = function()
    -- Should not throw
    validation.assert_channel(5)
    validation.assert_note(60)
    validation.assert_velocity(100)
    validation.assert_controller(7)
    validation.assert_program(42)
    validation.assert_pitch_bend(8192)
  end,
}

run_unit_tests()
