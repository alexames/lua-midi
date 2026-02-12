-- test_system_messages.lua
-- Unit tests for System Common and System Real-Time messages

local unit = require 'llx.unit'

local event = require 'lua-midi.event'
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

describe('SystemCommonMessageTests', function()
  it('should create SystemExclusiveEvent with correct time delta', function()
    local sysex = SystemExclusiveEvent(0, {0x41, 0x10, 0x42, 0x12})
    expect(sysex.time_delta).to.be_equal_to(0)
  end)

  it('should create SystemExclusiveEvent with correct data length', function()
    local sysex = SystemExclusiveEvent(0, {0x41, 0x10, 0x42, 0x12})
    expect(#sysex.data).to.be_equal_to(4)
  end)

  it('should create SystemExclusiveEvent with correct'
    .. ' first data byte',
  function()
    local sysex = SystemExclusiveEvent(0, {0x41, 0x10, 0x42, 0x12})
    expect(sysex.data[1]).to.be_equal_to(0x41)
  end)

  it('should include SystemExclusiveEvent in tostring', function()
    local sysex = SystemExclusiveEvent(120, {0x41, 0x10, 0x42})
    local str = tostring(sysex)
    expect(str:match('SystemExclusiveEvent')).to.be_truthy()
  end)

  it('should include time delta in SystemExclusiveEvent tostring', function()
    local sysex = SystemExclusiveEvent(120, {0x41, 0x10, 0x42})
    local str = tostring(sysex)
    expect(str:match('120')).to.be_truthy()
  end)

  it('should include byte count in SystemExclusiveEvent tostring', function()
    local sysex = SystemExclusiveEvent(120, {0x41, 0x10, 0x42})
    local str = tostring(sysex)
    expect(str:match('3 bytes')).to.be_truthy()
  end)

  it('should create MIDITimeCodeQuarterFrameEvent'
    .. ' with correct time delta',
  function()
    local mtc = MIDITimeCodeQuarterFrameEvent(0, 3, 15)
    expect(mtc.time_delta).to.be_equal_to(0)
  end)

  it('should create MIDITimeCodeQuarterFrameEvent'
    .. ' with correct message type',
  function()
    local mtc = MIDITimeCodeQuarterFrameEvent(0, 3, 15)
    expect(mtc.message_type).to.be_equal_to(3)
  end)

  it('should create MIDITimeCodeQuarterFrameEvent'
    .. ' with correct values',
  function()
    local mtc = MIDITimeCodeQuarterFrameEvent(0, 3, 15)
    expect(mtc.values).to.be_equal_to(15)
  end)

  it('should include MIDITimeCodeQuarterFrameEvent in tostring', function()
    local mtc = MIDITimeCodeQuarterFrameEvent(10, 2, 8)
    local str = tostring(mtc)
    expect(str:match('MIDITimeCodeQuarterFrameEvent')).to.be_truthy()
  end)

  it('should include message type in'
    .. ' MIDITimeCodeQuarterFrameEvent tostring',
  function()
    local mtc = MIDITimeCodeQuarterFrameEvent(10, 2, 8)
    local str = tostring(mtc)
    expect(str:match('type=2')).to.be_truthy()
  end)

  it('should include values in'
    .. ' MIDITimeCodeQuarterFrameEvent tostring',
  function()
    local mtc = MIDITimeCodeQuarterFrameEvent(10, 2, 8)
    local str = tostring(mtc)
    expect(str:match('values=8')).to.be_truthy()
  end)

  it('should create SongPositionPointerEvent'
    .. ' with correct time delta',
  function()
    local spp = SongPositionPointerEvent(0, 1024)
    expect(spp.time_delta).to.be_equal_to(0)
  end)

  it('should create SongPositionPointerEvent with correct position', function()
    local spp = SongPositionPointerEvent(0, 1024)
    expect(spp.position).to.be_equal_to(1024)
  end)

  it('should include SongPositionPointerEvent in tostring', function()
    local spp = SongPositionPointerEvent(5, 2048)
    local str = tostring(spp)
    expect(str:match('SongPositionPointerEvent')).to.be_truthy()
  end)

  it('should include position in SongPositionPointerEvent tostring', function()
    local spp = SongPositionPointerEvent(5, 2048)
    local str = tostring(spp)
    expect(str:match('position=2048')).to.be_truthy()
  end)

  it('should create SongSelectEvent with correct time delta', function()
    local ss = SongSelectEvent(0, 42)
    expect(ss.time_delta).to.be_equal_to(0)
  end)

  it('should create SongSelectEvent with correct song number', function()
    local ss = SongSelectEvent(0, 42)
    expect(ss.song_number).to.be_equal_to(42)
  end)

  it('should include SongSelectEvent in tostring', function()
    local ss = SongSelectEvent(15, 7)
    local str = tostring(ss)
    expect(str:match('SongSelectEvent')).to.be_truthy()
  end)

  it('should include song number in SongSelectEvent tostring', function()
    local ss = SongSelectEvent(15, 7)
    local str = tostring(ss)
    expect(str:match('song=7')).to.be_truthy()
  end)

  it('should create TuneRequestEvent with correct time delta', function()
    local tr = TuneRequestEvent(0)
    expect(tr.time_delta).to.be_equal_to(0)
  end)

  it('should include TuneRequestEvent in tostring', function()
    local tr = TuneRequestEvent(20)
    local str = tostring(tr)
    expect(str:match('TuneRequestEvent')).to.be_truthy()
  end)

  it('should include time delta in TuneRequestEvent tostring', function()
    local tr = TuneRequestEvent(20)
    local str = tostring(tr)
    expect(str:match('20')).to.be_truthy()
  end)
end)

describe('SystemRealTimeMessageTests', function()
  it('should create TimingClockEvent with correct time delta', function()
    local clock = TimingClockEvent(0)
    expect(clock.time_delta).to.be_equal_to(0)
  end)

  it('should convert TimingClockEvent to string correctly', function()
    local clock = TimingClockEvent(100)
    expect(tostring(clock)).to.be_equal_to('TimingClockEvent(100)')
  end)

  it('should create StartEvent with correct time delta', function()
    local start = StartEvent(0)
    expect(start.time_delta).to.be_equal_to(0)
  end)

  it('should convert StartEvent to string correctly', function()
    local start = StartEvent(50)
    expect(tostring(start)).to.be_equal_to('StartEvent(50)')
  end)

  it('should create ContinueEvent with correct time delta', function()
    local cont = ContinueEvent(0)
    expect(cont.time_delta).to.be_equal_to(0)
  end)

  it('should convert ContinueEvent to string correctly', function()
    local cont = ContinueEvent(75)
    expect(tostring(cont)).to.be_equal_to('ContinueEvent(75)')
  end)

  it('should create StopEvent with correct time delta', function()
    local stop = StopEvent(0)
    expect(stop.time_delta).to.be_equal_to(0)
  end)

  it('should convert StopEvent to string correctly', function()
    local stop = StopEvent(200)
    expect(tostring(stop)).to.be_equal_to('StopEvent(200)')
  end)

  it('should create ActiveSensingEvent with correct time delta', function()
    local as = ActiveSensingEvent(0)
    expect(as.time_delta).to.be_equal_to(0)
  end)

  it('should convert ActiveSensingEvent to string correctly', function()
    local as = ActiveSensingEvent(300)
    expect(tostring(as)).to.be_equal_to('ActiveSensingEvent(300)')
  end)

  it('should create SystemResetEvent with correct time delta', function()
    local reset = SystemResetEvent(0)
    expect(reset.time_delta).to.be_equal_to(0)
  end)

  it('should convert SystemResetEvent to string correctly', function()
    local reset = SystemResetEvent(1000)
    expect(tostring(reset)).to.be_equal_to('SystemResetEvent(1000)')
  end)

  it('should defensively copy SysEx data table', function()
    local data = {0x41, 0x10, 0x42}
    local sysex = SystemExclusiveEvent(0, data)
    data[1] = 0xFF
    expect(sysex.data[1]).to.be_equal_to(0x41)
  end)
end)

describe('SystemMessageValidationTests', function()
  it('should reject MIDITimeCodeQuarterFrameEvent'
    .. ' with message type out of range',
  function()
    local ok = pcall(function() MIDITimeCodeQuarterFrameEvent(0, 8, 0) end)
    expect(ok).to.be_falsy()
  end)

  it('should reject MIDITimeCodeQuarterFrameEvent'
    .. ' with negative message type',
  function()
    local ok = pcall(function() MIDITimeCodeQuarterFrameEvent(0, -1, 0) end)
    expect(ok).to.be_falsy()
  end)

  it('should reject MIDITimeCodeQuarterFrameEvent'
    .. ' with values out of range',
  function()
    local ok = pcall(function() MIDITimeCodeQuarterFrameEvent(0, 0, 16) end)
    expect(ok).to.be_falsy()
  end)

  it('should accept MIDITimeCodeQuarterFrameEvent'
    .. ' at boundary values',
  function()
    MIDITimeCodeQuarterFrameEvent(0, 0, 0)
    MIDITimeCodeQuarterFrameEvent(0, 7, 15)
  end)

  it('should reject SongPositionPointerEvent'
    .. ' with position out of range',
  function()
    local ok = pcall(function() SongPositionPointerEvent(0, 16384) end)
    expect(ok).to.be_falsy()
  end)

  it('should reject SongPositionPointerEvent with negative position', function()
    local ok = pcall(function() SongPositionPointerEvent(0, -1) end)
    expect(ok).to.be_falsy()
  end)

  it('should accept SongPositionPointerEvent at boundary values', function()
    SongPositionPointerEvent(0, 0)
    SongPositionPointerEvent(0, 16383)
  end)

  it('should reject SongSelectEvent with song number out of range', function()
    local ok = pcall(function() SongSelectEvent(0, 128) end)
    expect(ok).to.be_falsy()
  end)

  it('should reject SongSelectEvent with negative song number', function()
    local ok = pcall(function() SongSelectEvent(0, -1) end)
    expect(ok).to.be_falsy()
  end)

  it('should accept SongSelectEvent at boundary values', function()
    SongSelectEvent(0, 0)
    SongSelectEvent(0, 127)
  end)
end)

run_unit_tests()
