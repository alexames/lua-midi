--- MIDI Percussion Module.
-- Defines the General MIDI (GM) percussion note numbers as an enumeration.
-- These correspond to the standard GM percussion map on MIDI channel 10
-- (note numbers 27-87).
--
-- @module midi.percussion
-- @copyright 2024 Alexander Ames
-- @license MIT
-- @usage
-- local midi = require 'lua-midi'
--
-- -- Use percussion names
-- local kick = midi.percussion.bass_drum_1
-- local snare = midi.percussion.acoustic_snare
-- local hat = midi.percussion.closed_hi_hat
--
-- -- Use in note events on channel 9 (0-indexed)
-- local event = midi.event.NoteBeginEvent(
--   0, 9, midi.percussion.acoustic_snare, 100)

local llx = require 'llx'

local _ENV, _M = llx.environment.create_module_environment()

--- General MIDI percussion enumeration.
-- Maps percussion instrument names to MIDI note numbers (27-87).
-- @table percussion
percussion = llx.enum 'percussion' {
  -- 27-34: Miscellaneous
  [27] = 'high_q',
  'slap',
  'scratch_push',
  'scratch_pull',
  'sticks',
  'square_click',
  'metronome_click',
  'metronome_bell',

  -- 35-40: Kick and Snare
  'acoustic_bass_drum',
  'bass_drum_1',
  'side_stick',
  'acoustic_snare',
  'hand_clap',
  'electric_snare',

  -- 41-46: Toms and Hi-Hat
  'low_floor_tom',
  'closed_hi_hat',
  'high_floor_tom',
  'pedal_hi_hat',
  'low_tom',
  'open_hi_hat',

  -- 47-51: Toms and Cymbals
  'low_mid_tom',
  'hi_mid_tom',
  'crash_cymbal_1',
  'high_tom',
  'ride_cymbal_1',

  -- 52-56: Cymbals
  'chinese_cymbal',
  'ride_bell',
  'tambourine',
  'splash_cymbal',
  'cowbell',

  -- 57-59: Cymbals and Vibraslap
  'crash_cymbal_2',
  'vibraslap',
  'ride_cymbal_2',

  -- 60-64: Bongo and Conga
  'hi_bongo',
  'low_bongo',
  'mute_hi_conga',
  'open_hi_conga',
  'low_conga',

  -- 65-69: Timbale and Agogo
  'high_timbale',
  'low_timbale',
  'high_agogo',
  'low_agogo',
  'cabasa',

  -- 70-74: Maracas and Whistle
  'maracas',
  'short_whistle',
  'long_whistle',
  'short_guiro',
  'long_guiro',

  -- 75-79: Claves and Woodblock
  'claves',
  'hi_wood_block',
  'low_wood_block',
  'mute_cuica',
  'open_cuica',

  -- 80-84: Triangle and Shaker
  'mute_triangle',
  'open_triangle',
  'shaker',
  'jingle_bell',
  'bell_tree',

  -- 85-87: Castanets and Surdo
  'castanets',
  'mute_surdo',
  'open_surdo',
}

return _M
