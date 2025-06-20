local llx = require 'llx'
local unit = require 'unit'
local types = require 'llx.types.matchers'
local midi_event = require 'midi.event'

test_class 'ReadEvent' {
  [test 'NoteEndEvent'] = function()
    local bytes = ''
    local expectedEvent = midi_event.NoteEndEvent()
    EXPECT_EQ(result_branch, 'Foo')
    EXPECT_THAT(result_ex, IsOfType(FooException))
  end,
  [test 'NoteBeginEvent'] = function()
    EXPECT_EQ(result_branch, 'Foo')
    EXPECT_THAT(result_ex, IsOfType(FooException))
  end,
  [test 'VelocityChangeEvent'] = function()
    EXPECT_EQ(result_branch, 'Foo')
    EXPECT_THAT(result_ex, IsOfType(FooException))
  end,
  [test 'ControllerChangeEvent'] = function()
    EXPECT_EQ(result_branch, 'Foo')
    EXPECT_THAT(result_ex, IsOfType(FooException))
  end,
  [test 'ProgramChangeEvent'] = function()
    EXPECT_EQ(result_branch, 'Foo')
    EXPECT_THAT(result_ex, IsOfType(FooException))
  end,
  [test 'ChannelPressureChangeEvent'] = function()
    EXPECT_EQ(result_branch, 'Foo')
    EXPECT_THAT(result_ex, IsOfType(FooException))
  end,
  [test 'PitchWheelChangeEvent'] = function()
    EXPECT_EQ(result_branch, 'Foo')
    EXPECT_THAT(result_ex, IsOfType(FooException))
  end,
  [test 'MetaEvent'] = function()
    EXPECT_EQ(result_branch, 'Foo')
    EXPECT_THAT(result_ex, IsOfType(FooException))
  end,
}

test_class 'WriteEvent' {
  [test 'NoteEndEvent'] = function()
    EXPECT_EQ(result_branch, 'Foo')
    EXPECT_THAT(result_ex, IsOfType(FooException))
  end,
  [test 'NoteBeginEvent'] = function()
    EXPECT_EQ(result_branch, 'Foo')
    EXPECT_THAT(result_ex, IsOfType(FooException))
  end,
  [test 'VelocityChangeEvent'] = function()
    EXPECT_EQ(result_branch, 'Foo')
    EXPECT_THAT(result_ex, IsOfType(FooException))
  end,
  [test 'ControllerChangeEvent'] = function()
    EXPECT_EQ(result_branch, 'Foo')
    EXPECT_THAT(result_ex, IsOfType(FooException))
  end,
  [test 'ProgramChangeEvent'] = function()
    EXPECT_EQ(result_branch, 'Foo')
    EXPECT_THAT(result_ex, IsOfType(FooException))
  end,
  [test 'ChannelPressureChangeEvent'] = function()
    EXPECT_EQ(result_branch, 'Foo')
    EXPECT_THAT(result_ex, IsOfType(FooException))
  end,
  [test 'PitchWheelChangeEvent'] = function()
    EXPECT_EQ(result_branch, 'Foo')
    EXPECT_THAT(result_ex, IsOfType(FooException))
  end,
  [test 'MetaEvent'] = function()
    EXPECT_EQ(result_branch, 'Foo')
    EXPECT_THAT(result_ex, IsOfType(FooException))
  end,
}


if llx.main_file() then
  unit.run_unit_tests()
end
