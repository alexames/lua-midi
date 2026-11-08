# lua-midi

MIDI file reading, parsing, and writing for Lua.

A comprehensive library for reading, writing, and manipulating MIDI files.
Supports all standard MIDI events, tracks, instruments, and file formats.

## Installation

```sh
luarocks install --server=https://alexames.github.io/luarocks-repository lua-midi
```

## Usage

```lua
local midi = require 'lua-midi'

-- Read a MIDI file
local song = midi.MidiFile.read('song.mid')
print(song:get_format_name())

-- Create events
local note_on = midi.event.NoteBeginEvent(0, 0, 60, 100)
```

## Dependencies

- [Lua](https://www.lua.org/) 5.1 through 5.5, or [LuaJIT](https://luajit.org/) 2.x
- [llx](https://github.com/alexames/llx) >= 3.0 -- Lua extensions library

`lua-midi-scm-1.rockspec` declares Lua 5.1 through 5.5;
`lua-midi-luajit-scm-1.rockspec` ships the same modules against LuaJIT and
`llx-luajit`.

## Supported Lua Versions

lua-midi runs unchanged on Lua 5.1, 5.2, 5.3, 5.4, 5.5 and LuaJIT. Its
sources are written in the Lua 5.1 syntax subset: the byte packing uses
`llx.compat`'s `band`, `bor`, `lshift` and `rshift` rather than the 5.3
integer operators, and files are closed through `llx.contextlib.with`
rather than `<close>`. `tests/test_portability.lua` fails on any source
that uses syntax or a library name one of those interpreters lacks.

## Documentation

API documentation is generated with [LDoc](https://github.com/lunarmodules/LDoc)
and published to [GitHub Pages](https://alexames.github.io/lua-midi).

To generate locally:

```sh
luarocks install ldoc
ldoc .
```

## Running Tests

Each test file runs on its own, with llx and lua-midi on the package path,
on any supported interpreter:

```sh
cd tests
lua5.4 test_event.lua
luajit test_portability.lua
```

## License

[MIT](LICENSE)
