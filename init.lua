--- MIDI Library.
-- A comprehensive library for reading, writing, and manipulating MIDI files.
--
-- This module re-exports all public symbols from:
--
-- * `midi.midi_file` - MidiFile class for reading/writing MIDI files
-- * `midi.track` - Track class for MIDI tracks
-- * `midi.event` - All MIDI event classes (available as `midi.event.*`)
-- * `midi.instrument` - General MIDI instrument definitions
-- * `midi.validation` - MIDI file validation utilities
--
-- @module midi
-- @copyright 2024 Alexander Ames
-- @license MIT
-- @usage
-- local midi = require 'midi'
--
-- -- Read a MIDI file
-- local song = midi.MidiFile.read('song.mid')
-- print(song:get_format_name())
--
-- -- Create events
-- local note_on = midi.event.NoteBeginEvent(0, 0, 60, 100)

local llx = require 'llx'

local lock <close> = llx.lock_global_table()

return require 'llx.flatten_submodules' {
  require 'midi.midi_file',
  require 'midi.track',
  require 'midi.instrument',
  require 'midi.validation',
  event=require 'midi.event',
}