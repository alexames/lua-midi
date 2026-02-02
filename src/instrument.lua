--- MIDI Instrument Module.
-- Defines the General MIDI (GM) instrument program numbers as an enumeration.
-- These correspond to the standard 128 GM program numbers (0-127).
--
-- @module midi.instrument
-- @copyright 2024 Alexander Ames
-- @license MIT
-- @usage
-- local midi = require 'lua-midi'
--
-- -- Use instrument names
-- local piano = midi.instrument.acoustic_grand  -- 0
-- local violin = midi.instrument.violin         -- 40
--
-- -- Set program change
-- local event = midi.event.ProgramChangeEvent(0, 0, midi.instrument.acoustic_grand)

local llx = require 'llx'

local _ENV, _M = llx.environment.create_module_environment()

--- General MIDI instrument enumeration.
-- Maps instrument names to program numbers (0-127).
-- @table instrument
instrument = llx.enum 'instrument' {
  -- Piano
  [0] = 'acoustic_grand',
  'bright_acoustic',
  'electric_grand',
  'honky_tonk',
  'electric_piano_1',
  'electric_piano_2',
  'harpsichord',
  'clav',

  -- Chrome Percussion
  'celesta',
  'glockenspiel',
  'music_box',
  'vibraphone',
  'marimba',
  'xylophone',
  'tubular_bells',
  'dulcimer',

  -- Organ
  'drawbar_organ',
  'percussive_organ',
  'rock_organ',
  'church_organ',
  'reed_organ',
  'accoridan',
  'harmonica',
  'tango_accordian',

  -- Guitar
  'acoustic_guitar_nylon',
  'acoustic_guitar_steel',
  'electric_guitar_jazz',
  'electric_guitar_clean',
  'electric_guitar_muted',
  'overdriven_guitar',
  'distortion_guitar',
  'guitar_harmonics',

  -- Bass
  'acoustic_bass',
  'electric_bassfinger',
  'electric_basspick',
  'fretless_bass',
  'slap_bass_1',
  'slap_bass_2',
  'synth_bass_1',
  'synth_bass_2',

  -- Strings
  'violin',
  'viola',
  'cello',
  'contrabass',
  'tremolo_strings',
  'pizzicato_strings',
  'orchestral_strings',
  'timpani',

  -- Ensemble
  'string_ensemble_1',
  'string_ensemble_2',
  'synth_strings_1',
  'synth_strings_2',
  'choir_aahs',
  'voice_oohs',
  'synth_voice',
  'orchestra_hit',

  -- Brass
  'trumpet',
  'trombone',
  'tuba',
  'muted_trumpet',
  'french_horn',
  'brass_section',
  'synthbrass_1',
  'synthbrass_2',

  -- Reed
  'soprano_sax',
  'alto_sax',
  'tenor_sax',
  'baritone_sax',
  'oboe',
  'english_horn',
  'bassoon',
  'clarinet',

  -- Pipe
  'piccolo',
  'flute',
  'recorder',
  'pan_flute',
  'blown_bottle',
  'skakuhachi',
  'whistle',
  'ocarina',

  -- Synth Lead
  'lead_1_square',
  'lead_2_sawtooth',
  'lead_3_calliope',
  'lead_4_chiff',
  'lead_5_charang',
  'lead_6_voice',
  'lead_7_fifths',
  'lead_8_bass_lead',

  -- Synth Pad
  'pad_1_new_age',
  'pad_2_warm',
  'pad_3_polysynth',
  'pad_4_choir',
  'pad_5_bowed',
  'pad_6_metallic',
  'pad_7_halo',
  'pad_8_sweep',

  -- Synth Effects
  'fx_1_rain',
  'fx_2_soundtrack',
  'fx_3_crystal',
  'fx_4_atmosphere',
  'fx_5_brightness',
  'fx_6_goblins',
  'fx_7_echoes',
  'fx_8_scifi',

  -- Ethnic
  'sitar',
  'banjo',
  'shamisen',
  'koto',
  'kalimba',
  'bagpipe',
  'fiddle',
  'shanai',

  -- Percussive
  'tinkle_bell',
  'agogo',
  'steel_drums',
  'woodblock',
  'taiko_drum',
  'melodic_tom',
  'synth_drum',
  'reverse_cymbal',

  -- Sound Effects
  'guitar_fret_noise',
  'breath_noise',
  'seashore',
  'bird_tweet',
  'telephone_ring',
  'helicopter',
  'applause',
  'gunshot',
}

return _M
