-- Copyright 2026 Alexander Ames <Alexander.Ames@gmail.com>
--
-- Holds every source in the checkout to the Lua versions that load it,
-- so a change that only one interpreter can parse fails on whichever
-- interpreter runs the suite. Shared code must parse on Lua 5.1 and
-- LuaJIT and reach version-specific library names only through
-- llx.compat; the files listed in FLOORS load on fewer interpreters
-- and may use what those interpreters provide.

local compat = require 'llx.compat'
local llx = require 'llx'
local unit = require 'llx.unit'

_ENV = unit.create_test_env(_ENV)

-- The checkout root, with a trailing separator, derived from this
-- file's own path so a run from the root and one from tests/ agree.
local function checkout_root()
  local source = debug.getinfo(1, 'S').source
  local path = source:match('^@(.*)$') or source
  local dir = path:match('^(.*[/\\])') or './'
  return dir .. '../'
end

-- Loaded by path rather than required: nothing installs tests/.
local lua_features =
    dofile(checkout_root() .. 'tests/support/lua_features.lua')

local ALL = lua_features.TARGETS

-- Path prefixes, relative to the checkout root, of the sources that
-- load on only some interpreters, with the interpreters they load on.
-- The first matching prefix wins; everything else loads everywhere.
local FLOORS = {
}

local LUA_ROCKSPEC = 'lua-midi-scm-1.rockspec'
local LUAJIT_ROCKSPEC = 'lua-midi-luajit-scm-1.rockspec'

-- Every .lua file under src/ and tests/, as paths relative to the
-- checkout root with forward slashes, sorted.
local function lua_sources(root)
  local is_windows = package.config:sub(1, 1) == '\\'
  local files = {}
  for _, top in ipairs({'src', 'tests'}) do
    local command
    if is_windows then
      local dir = (root .. top):gsub('/', '\\')
      command = 'dir /b /s "' .. dir .. '\\*.lua" 2>nul'
    else
      command = 'find "' .. root .. top .. '" -name "*.lua" 2>/dev/null'
    end
    local handle = io.popen(command)
    if handle then
      for line in handle:lines() do
        local normalized = line:gsub('\\', '/')
        local relative = normalized:match('/(' .. top .. '/.*)$')
        if relative then
          table.insert(files, relative)
        end
      end
      handle:close()
    end
  end
  table.sort(files)
  return files
end

local function starts_with(text, prefix)
  return text:sub(1, #prefix) == prefix
end

local function targets_for(path)
  for _, floor in ipairs(FLOORS) do
    if starts_with(path, floor[1]) then
      return floor[2]
    end
  end
  return ALL
end

local function violations(root)
  local found = {}
  for _, path in ipairs(lua_sources(root)) do
    local handle = io.open(root .. path, 'rb')
    local source = handle:read('*a')
    handle:close()
    local ok, features = pcall(lua_features.scan, source)
    if not ok then
      table.insert(found, path .. ': ' .. tostring(features))
    else
      for _, record in ipairs(features) do
        for _, target in ipairs(targets_for(path)) do
          if not lua_features.supports(record.feature, target) then
            table.insert(found, compat.format('%s:%d: %s (Lua %s)',
                path, record.line, record.feature, target))
          end
        end
      end
    end
  end
  return found
end

-- The build.modules table a rockspec declares, read in an empty
-- environment; nil and a message when it cannot be read.
local function rockspec_modules(path)
  local spec = {}
  local chunk, load_error = compat.loadfile(path, 't', spec)
  if not chunk then return nil, tostring(load_error) end
  local ran, run_error = pcall(chunk)
  if not ran then return nil, tostring(run_error) end
  return spec.build and spec.build.modules
end

local function sorted_entries(modules)
  local entries = {}
  for name, path in pairs(modules or {}) do
    table.insert(entries, name .. '=' .. path)
  end
  table.sort(entries)
  return table.concat(entries, '\n')
end

describe('portability', function()
  it('should ship the same modules from both rockspecs', function()
    local root = checkout_root()
    local lua_modules = rockspec_modules(root .. LUA_ROCKSPEC)
    local luajit_modules = rockspec_modules(root .. LUAJIT_ROCKSPEC)
    expect(lua_modules).to_not.be_nil()
    expect(sorted_entries(luajit_modules))
      .to.be_equal_to(sorted_entries(lua_modules))
  end)

  it('should ship every source under src', function()
    local root = checkout_root()
    local shipped = {}
    for _, path in pairs(rockspec_modules(root .. LUA_ROCKSPEC) or {}) do
      shipped[path] = true
    end
    local missing = {}
    for _, path in ipairs(lua_sources(root)) do
      if starts_with(path, 'src/') and not shipped[path] then
        table.insert(missing, path)
      end
    end
    expect(table.concat(missing, ', ')).to.be_equal_to('')
  end)

  it('should find the sources', function()
    local files = lua_sources(checkout_root())
    expect(#files > 15).to.be_true()
  end)

  it('should hold every source to the Lua versions that load it',
      function()
    expect(table.concat(violations(checkout_root()), '\n'))
      .to.be_equal_to('')
  end)
end)

if llx.main_file() then
  os.exit(run_unit_tests() == 0 and 0 or 1)
end
