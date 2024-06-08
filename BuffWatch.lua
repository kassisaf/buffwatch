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

windower.register_event('load', function()
  defaults = {
    background = {
      visible = true,
      alpha = 128
    },
    pos = {
      x = 146,
      y = 85
    },
    profiles = {},
    text = {
      font = 'Arial',
      size = 11,
      stroke = {
        width = 2,
        transparency = 192
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
  settings:save('all')
end)

windower.register_event('prerender', function()
  buff_ids = windower.ffxi.get_player().buffs

  -- image:text(table.concat(buff_ids, ', '))
  image:text('')
  for i, buff_id in ipairs(buff_ids) do
    buff = res.buffs[buff_id]
    if buff ~= nil then
      image:append(colors.red .. buff_id .. ': ' .. buff.en .. '\n' .. colors.white)
      -- image:append(buff_id .. ': ' .. buff.en .. '\n')
    end
  end

  image:visible(true)
end)

windower.register_event('addon command', function(...)
  cmd = {
    ...
  }
  if cmd[1] == 'help' then
    -- TODO: Add help text
  elseif cmd[1] == 'add' then
    if cmd[2] == nil or cmd[3] == nil then
      error('Invalid command. Try `bw add <profile> <buff>`')
    else
      add_buff(cmd[2], cmd[3])
    end
  elseif cmd[1] == 'remove' or cmd[1] == 'rm' then
    if cmd[2] == nil or cmd[3] == nil then
      error('Invalid command. Try `bw remove <profile> <buff>`')
    else
      remove_buff(cmd[2], cmd[3])
    end
  end
end)

function get_buff_id(buff_name)
  if res.buffs:with('en', buff_name) ~= nil then
    return res.buffs:with('en', buff_name).id
  end
  return nil
end

function add_buff(profile_name, buff_name)
  -- Create profile if it doesn't already exist
  if settings.profiles[profile_name] == nil then
    settings.profiles[profile_name] = {}
    log('Profile `' .. profile_name .. '` created')
  end
  -- Validate buff name
  buff_id = get_buff_id(buff_name)
  if buff_id == nil then
    error('Invalid buff name: ' .. buff_name .. ' (case sensitive)')
    return
  end
  -- Add buff to profile
  if settings.profiles[profile_name]['_' .. buff_id] == nil then
    settings.profiles[profile_name]['_' .. buff_id] = buff_name
    log('Added ' .. buff_name .. ' (' .. buff_id .. ')' .. '` to profile `' .. profile_name .. '`')
    settings:save('profiles')
  else
    log(buff_name .. ' (' .. buff_id .. ')' .. ' already exists in profile `' .. profile_name .. '`')
  end
end

function remove_buff(profile_name, buff_name)
  settings = config.load()

  buff_id = get_buff_id(buff_name)
  if buff_id == nil then
    error('Invalid buff name: ' .. buff_name .. ' (case sensitive)')
    return
  end

  if settings.profiles[profile_name]['_' .. buff_id] ~= nil then
    -- Remove buff from profile
    settings.profiles[profile_name]['_' .. buff_id] = nil
    log(buff_name .. ' (' .. buff_id .. ')' .. '` removed from profile `' .. profile_name .. '`')
    -- TODO: Remove profile if empty (getn doesn't work here)
    if settings.profiles[profile_name]:length() == 0 then
      settings.profiles[profile_name] = nil
      log('Profile `' .. profile_name .. '` removed because it was empty')
    end
    settings:save('profiles')
  else
    log('Buff `' .. buff_name .. '` not found in profile `' .. profile_name .. '`')
  end
end
