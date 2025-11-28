-- test_system_messages.lua
-- Unit tests for System Common and System Real-Time messages

local unit = require 'unit'
local EXPECT_EQ = unit.EXPECT_EQ
local EXPECT_TRUE = unit.EXPECT_TRUE
local EXPECT_FALSE = unit.EXPECT_FALSE

local event = require 'midi.event'
local SystemExclusiveEvent = event.SystemExclusiveEvent
local MIDITimeCodeQuarterFrameEvent = event.MIDITimeCodeQuarterFrameEvent
local SongPositionPointerEvent = event.SongPositionPointerEvent
local SongSelectEvent = event.SongSelectEvent
local TuneRequestEvent = event.TuneRequestEvent
local TimingClockEvent = event.TimingClockEvent
local StartEvent = event.StartEvent
local ContinueEvent = event.ContinueEvent
local StopEvent = event.StopEvent
local ActiveSensingEvent = event.ActiveSensingEvent
local SystemResetEvent = event.SystemResetEvent

_ENV = unit.create_test_env(_ENV)

test_class 'SystemCommonMessageTests' {
  [test 'SystemExclusiveEvent creation'] = function()
    local sysex = SystemExclusiveEvent(0, {0x41, 0x10, 0x42, 0x12})
    EXPECT_EQ(sysex.time_delta, 0)
    EXPECT_EQ(#sysex.data, 4)
    EXPECT_EQ(sysex.data[1], 0x41)
  end,

  [test 'SystemExclusiveEvent tostring'] = function()
    local sysex = SystemExclusiveEvent(120, {0x41, 0x10, 0x42})
    local str = tostring(sysex)
    EXPECT_TRUE(str:match('SystemExclusiveEvent'))
    EXPECT_TRUE(str:match('120'))
    EXPECT_TRUE(str:match('3 bytes'))
  end,

  [test 'MIDITimeCodeQuarterFrameEvent creation'] = function()
    local mtc = MIDITimeCodeQuarterFrameEvent(0, 3, 15)
    EXPECT_EQ(mtc.time_delta, 0)
    EXPECT_EQ(mtc.message_type, 3)
    EXPECT_EQ(mtc.values, 15)
  end,

  [test 'MIDITimeCodeQuarterFrameEvent tostring'] = function()
    local mtc = MIDITimeCodeQuarterFrameEvent(10, 2, 8)
    local str = tostring(mtc)
    EXPECT_TRUE(str:match('MIDITimeCodeQuarterFrameEvent'))
    EXPECT_TRUE(str:match('type=2'))
    EXPECT_TRUE(str:match('values=8'))
  end,

  [test 'SongPositionPointerEvent creation'] = function()
    local spp = SongPositionPointerEvent(0, 1024)
    EXPECT_EQ(spp.time_delta, 0)
    EXPECT_EQ(spp.position, 1024)
  end,

  [test 'SongPositionPointerEvent tostring'] = function()
    local spp = SongPositionPointerEvent(5, 2048)
    local str = tostring(spp)
    EXPECT_TRUE(str:match('SongPositionPointerEvent'))
    EXPECT_TRUE(str:match('position=2048'))
  end,

  [test 'SongSelectEvent creation'] = function()
    local ss = SongSelectEvent(0, 42)
    EXPECT_EQ(ss.time_delta, 0)
    EXPECT_EQ(ss.song_number, 42)
  end,

  [test 'SongSelectEvent tostring'] = function()
    local ss = SongSelectEvent(15, 7)
    local str = tostring(ss)
    EXPECT_TRUE(str:match('SongSelectEvent'))
    EXPECT_TRUE(str:match('song=7'))
  end,

  [test 'TuneRequestEvent creation'] = function()
    local tr = TuneRequestEvent(0)
    EXPECT_EQ(tr.time_delta, 0)
  end,

  [test 'TuneRequestEvent tostring'] = function()
    local tr = TuneRequestEvent(20)
    local str = tostring(tr)
    EXPECT_TRUE(str:match('TuneRequestEvent'))
    EXPECT_TRUE(str:match('20'))
  end,
}

test_class 'SystemRealTimeMessageTests' {
  [test 'TimingClockEvent creation'] = function()
    local clock = TimingClockEvent(0)
    EXPECT_EQ(clock.time_delta, 0)
  end,

  [test 'TimingClockEvent tostring'] = function()
    local clock = TimingClockEvent(100)
    EXPECT_EQ(tostring(clock), 'TimingClockEvent(100)')
  end,

  [test 'StartEvent creation'] = function()
    local start = StartEvent(0)
    EXPECT_EQ(start.time_delta, 0)
  end,

  [test 'StartEvent tostring'] = function()
    local start = StartEvent(50)
    EXPECT_EQ(tostring(start), 'StartEvent(50)')
  end,

  [test 'ContinueEvent creation'] = function()
    local cont = ContinueEvent(0)
    EXPECT_EQ(cont.time_delta, 0)
  end,

  [test 'ContinueEvent tostring'] = function()
    local cont = ContinueEvent(75)
    EXPECT_EQ(tostring(cont), 'ContinueEvent(75)')
  end,

  [test 'StopEvent creation'] = function()
    local stop = StopEvent(0)
    EXPECT_EQ(stop.time_delta, 0)
  end,

  [test 'StopEvent tostring'] = function()
    local stop = StopEvent(200)
    EXPECT_EQ(tostring(stop), 'StopEvent(200)')
  end,

  [test 'ActiveSensingEvent creation'] = function()
    local as = ActiveSensingEvent(0)
    EXPECT_EQ(as.time_delta, 0)
  end,

  [test 'ActiveSensingEvent tostring'] = function()
    local as = ActiveSensingEvent(300)
    EXPECT_EQ(tostring(as), 'ActiveSensingEvent(300)')
  end,

  [test 'SystemResetEvent creation'] = function()
    local reset = SystemResetEvent(0)
    EXPECT_EQ(reset.time_delta, 0)
  end,

  [test 'SystemResetEvent tostring'] = function()
    local reset = SystemResetEvent(1000)
    EXPECT_EQ(tostring(reset), 'SystemResetEvent(1000)')
  end,
}

run_unit_tests()
