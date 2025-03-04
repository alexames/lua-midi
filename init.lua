-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local llx = require 'llx'

local lock <close> = llx.lock_global_table()

return require 'llx.flatten_submodules' {
  require 'midi.midi_file',
  require 'midi.track',
  event=require 'midi.event',
  instrument=require 'midi.instrument',
}