rockspec_format = "3.0"
package = "lua-midi-luajit"
version = "scm-1"

source = {
   url = "git+https://github.com/alexames/lua-midi.git",
   branch = "main",
}

description = {
   summary = "MIDI file reading, parsing, and writing for LuaJIT",
   detailed = [[
A comprehensive library for reading, writing, and manipulating MIDI files.
Supports all standard MIDI events, tracks, instruments, and file formats.

The same sources as the lua-midi rock, declared against LuaJIT 2.x.
   ]],
   homepage = "https://github.com/alexames/lua-midi",
   license = "MIT",
   maintainer = "Alexander Ames <Alexander.Ames@gmail.com>",
   labels = {
      "midi",
      "music",
      "audio",
   },
}

dependencies = {
   "luajit >= 2.0",
   "llx-luajit >= 3.0",
}

test = {
   type = "command",
   command = "cd tests && for f in test_*.lua; do echo \"=== $f ===\"; luajit \"$f\" || exit 1; done",
}

build = {
   type = "builtin",
   modules = {
      ["lua-midi"] = "src/init.lua",
      ["lua-midi.event"] = "src/event.lua",
      ["lua-midi.instrument"] = "src/instrument.lua",
      ["lua-midi.io"] = "src/io.lua",
      ["lua-midi.percussion"] = "src/percussion.lua",
      ["lua-midi.midi_file"] = "src/midi_file.lua",
      ["lua-midi.track"] = "src/track.lua",
      ["lua-midi.validation"] = "src/validation.lua",
   },
}
