--[[
Copyright © 2024, Zuri
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of BuffWatch nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
]] --
_addon.name = 'BuffWatch'
_addon.author = 'Zuri'
_addon.version = '0.1'
_addon.commands = {
  'buffwatch',
  'bw'
}

require('logger')
config = require('config')
res = require('resources')
texts = require('texts')

image = texts.new()
colors = {
  white = '\\cs(255,255,255)',
  red = '\\cs(255,0,0)',
  green = '\\cs(0,255,0)',
  blue = '\\cs(0,0,255)',
  yellow = '\\cs(255,255,0)',
  cyan = '\\cs(0,255,255)',
  magenta = '\\cs(255,0,255)',
  black = '\\cs(0,0,0)'
}
active_profile = nil

windower.register_event('load', function()
  defaults = {
    background = {
      visible = false,
      alpha = 128
    },
    text = {
      font = 'Arial',
      size = 11,
      stroke = {
        width = 2,
        transparency = 192
      }
    },
    pos = {
      x = 141,
      y = 83
    },
    profiles = {
      global = {
        _618 = {
          id = 618,
          en = "Emporox's Gift",
          label = "Potpourri"
        }
      },
      pld = {
        _116 = {
          id = 116,
          en = "Phalanx",
          label = "Phalanx"
        },
        _93 = {
          id = 93,
          en = "Defense Boost",
          label = "Cocoon"
        },
        _289 = {
          id = 289,
          en = "Enmity Boost",
          label = "Crusade"
        }
      }
    }
  }
  settings = config.load(defaults)
  settings:save('all')

  image:bg_visible(settings.background.visible)
  image:bg_alpha(settings.background.alpha)
  image:pos_x(settings.pos.x)
  image:pos_y(settings.pos.y)
  image:font(settings.text.font)
  image:size(settings.text.size)
  image:stroke_width(settings.text.stroke.width)
  image:stroke_transparency(settings.text.stroke.transparency)
  image:right_justified(false)
end)

windower.register_event('unload', function()
  settings = config.load()
  settings.pos.x = image:pos_x()
  settings.pos.y = image:pos_y()
  settings:save('pos')
end)

windower.register_event('prerender', function()
  update_text()
end)

function update_text()
  local buff_ids = windower.ffxi.get_player().buffs

  image:text('')
  for i, buff_id in ipairs(buff_ids) do
    local buff = res.buffs[buff_id]
    local color = colors.white

    if buff ~= nil then
      -- TODO: Make line red if buff is missing/inactive
      if (i % 2 == 0) then
        color = colors.red
      end
      -- TODO: Replace placeholder text with buffs from active profile
      local line = string.format(' %s%s: %s\n', color, buff_id, buff.en)
      image:append(line)
    end
  end

  image:visible(true)
end

function get_buff_id(buff_name)
  if res.buffs:with('en', buff_name) == nil then
    error(string.format('Invalid buff name: `%s` (case sensitive)', buff_name))
    return nil
  end
  return res.buffs:with('en', buff_name).id
end

function add_buff(profile_name, buff_name, label)
  settings = config.load()
  -- Validate buff name
  local buff_id = get_buff_id(buff_name)
  if buff_id == nil then
    return
  end
  -- Create profile if it doesn't already exist
  if settings.profiles[profile_name] == nil then
    settings.profiles[profile_name] = {}
    log(string.format('Profile `%s` created', profile_name))
  end
  -- Add buff to profile
  label = label or buff_name
  settings.profiles[profile_name]['_' .. buff_id] = {
    id = buff_id,
    en = buff_name,
    label = label
  }
  local line = string.format('Added %s (%d) to profile `%s`', buff_name, buff_id, profile_name)
  if label ~= buff_name then
    line = string.format('%s with a label of `%s`', line, label)
  end
  log(line)
  settings:save('profiles')
end

function remove_buff(profile_name, buff_name)
  settings = config.load()
  -- Validate buff name
  local buff_id = get_buff_id(buff_name)
  if buff_id == nil then
    return
  end

  if settings.profiles[profile_name]['_' .. buff_id] ~= nil then
    -- Remove buff from profile
    settings.profiles[profile_name]['_' .. buff_id] = nil
    log(string.format('Removed %s (%d) from profile `%s`', buff_name, buff_id, profile_name))
    -- Remove profile if empty
    if settings.profiles[profile_name]:length() == 0 then
      settings.profiles[profile_name] = nil
      log(string.format('Profile `%s` removed because it was empty', profile_name))
    end
    settings:save('profiles')
  else
    error(string.format('Buff `%s` not found in profile `%s`', buff_name, profile_name))
  end
end

function set_active_profile(profile_name)
  settings = config.load()
  if settings.profiles[profile_name] == nil then
    error(string.format('Profile `%s` not found', profile_name))
    return
  end
  active_profile = profile_name
  log(string.format('Active profile set to `%s`', profile_name))
end

function list_profiles()
  settings = config.load()
  log('Available profiles and number of buffs tracked:')
  for profile_name, profile in pairs(settings.profiles) do
    local line = string.format(' %s [%d]', profile_name, profile:length())
    if profile_name == active_profile then
      line = line .. ' (active)'
    end
    log(line)
  end
end

function print_active_buffs()
  player = windower.ffxi.get_player()
  if table.length(player.buffs) == 0 then
    log('No active buffs to display')
    return
  end
  log('Currently active buffs:')
  for i, buff_id in ipairs(player.buffs) do
    local buff = res.buffs[buff_id]
    if buff ~= nil then
      log(string.format(' %d: %s', buff_id, buff.en))
    end
  end
end

function search(buff_name)
  local found = false
  for i, buff in pairs(res.buffs) do
    if buff.en:lower():find(buff_name:lower()) then
      log(string.format('%d: %s', buff.id, buff.en))
      found = true
    end
  end
  if not found then
    log(string.format('No buffs found matching `%s`', buff_name))
  end
end

windower.register_event('addon command', function(...)
  cmd = {
    ...
  }

  if cmd[1] == 'help' then
    -- TODO: Document available commands once things are more stable
    log('Available commands:\n...\nj/k lol')

  elseif cmd[1] == 'add' or cmd[1] == 'a' then
    if cmd[2] == nil or cmd[3] == nil then
      error('Invalid command. Try `bw <add|a> <profile> <buff>`')
    else
      add_buff(cmd[2], cmd[3], cmd[4] or nil)
    end

  elseif cmd[1] == 'remove' or cmd[1] == 'r' then
    if cmd[2] == nil or cmd[3] == nil then
      error('Invalid command. Try `bw <remove|r> <profile> <buff>`')
    else
      remove_buff(cmd[2], cmd[3])
    end

  elseif cmd[1] == 'set' or cmd[1] == 's' then
    if cmd[2] == nil then
      error('Invalid command. Try `bw <set|s> <profile>`')
    else
      set_active_profile(cmd[2])
    end

  elseif cmd[1] == 'list' or cmd[1] == 'l' then
    list_profiles()

  elseif cmd[1] == 'buffs' then
    print_active_buffs()

  elseif cmd[1] == 'find' or cmd[1] == 'search' then
    if cmd[2] == nil then
      error('Invalid command. Try `bw <find|search> <buff>`')
    else
      -- TODO slice the table 2:last to allow search terms with spaces and no quotes
      search(cmd[2])
    end

  end
end)
