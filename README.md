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

- [Lua](https://www.lua.org/) >= 5.4
- [llx](https://github.com/alexames/llx) -- Lua extensions library

## Documentation

API documentation is generated with [LDoc](https://github.com/lunarmodules/LDoc)
and published to [GitHub Pages](https://alexames.github.io/lua-midi).

To generate locally:

```sh
luarocks install ldoc
ldoc .
```

## Running Tests

```sh
cd tests
lua5.4 test_event.lua
```

## License

[MIT](LICENSE)
