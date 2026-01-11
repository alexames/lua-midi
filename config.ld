-- LDoc configuration for midi
-- Run with: ldoc .

project = 'midi'
title = 'midi - MIDI File Library'
description = [[
A Lua library for reading, writing, and manipulating MIDI files.
Provides classes for MIDI files, tracks, events, instruments, and validation.
]]

-- Source files
file = {
  '.',
  exclude = {
    'tests',
  }
}

-- Output directory
dir = 'docs'

-- Use markdown for descriptions
format = 'markdown'

-- Sort alphabetically
sort = true

-- Include all documented items
all = true

-- Template (use default)
template = nil

-- Package display name
package = 'midi'

-- One file per module
one = false

-- Show source code links
no_return_or_parms = false
no_summary = false

-- Merge modules into single pages
merge = false

-- Custom tags
custom_tags = {
  {'example', title = 'Example', format = nil},
  {'usage', title = 'Usage', format = nil},
}
