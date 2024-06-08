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
texts = require('texts')

image = texts.new()

windower.register_event('load', function()
  defaults = {
    profiles = {},
    bg_alpha = 128,
    pos = {
      x = 200,
      y = 440
    },
    text = {
      font = 'Consolas',
      size = 12
    }
  }
  settings = config.load(defaults)
  player = windower.ffxi.get_player()

  image:bg_alpha(settings.bg_alpha)
  image:pos_x(settings.pos.x)
  image:pos_y(settings.pos.y)
  image:font(settings.text.font)
  image:size(settings.text.size)
end)

windower.register_event('load', function()
  defaults = {
    profiles = {},
    bg_alpha = 180,
    pos = {
      x = 200,
      y = 440
    },
    text = {
      font = 'Consolas',
      size = 12
    }
  }
  settings = config.load(defaults)
  player = windower.ffxi.get_player()

  image:bg_alpha(settings.bg_alpha)
  image:pos_x(settings.pos.x)
  image:pos_y(settings.pos.y)
  image:font(settings.text.font)
  image:size(settings.text.size)
end)

windower.register_event('unload', function()
  settings = config.load()
  settings.pos.x = image:pos_x()
  settings.pos.y = image:pos_y()
  settings:save('all')
end)

function refresh_display()
  image:text('test')
  image:visible(true)
end

refresh_display()

windower.register_event('prerender', function()
  -- image:visible(true)
end)

windower.register_event('addon command', function(...)
  cmd = {
    ...
  }
  if cmd[1] == 'help' then
    -- windower.add_to_chat(207, 'BuffWatch: //bw help')
    -- windower.add_to_chat(207, 'BuffWatch: //bw list')
    -- windower.add_to_chat(207, 'BuffWatch: //bw add <buff>')
    -- windower.add_to_chat(207, 'BuffWatch: //bw remove <buff>')
  elseif cmd[1] == 'add' then
    if cmd[2] == nil or cmd[3] == nil then
      error('Invalid command. Try `//bw add <profile> <buff>`')
    else
      add_buff(cmd[2], cmd[3])
    end
  elseif cmd[1] == 'remove' then
    if cmd[2] == nil or cmd[3] == nil then
      error('Invalid command. Try `//bw remove <profile> <buff>`')
    else
      remove_buff(cmd[2], cmd[3])
    end
  end
end)

function add_buff(profile_name, buff_name)
  -- Create profile if it doesn't already exist
  if settings.profiles[profile_name] == nil then
    settings.profiles[profile_name] = {}
    log('Profile `' .. profile_name .. '` created')
  end
  -- Add buff to profile
  if settings.profiles[profile_name][buff_name] == nil then
    settings.profiles[profile_name][buff_name] = true
    log('Buff `' .. buff_name .. '` added to profile `' .. profile_name .. '`')
  else
    log('Buff `' .. buff_name .. '` already exists in profile `' .. profile_name .. '`')
  end
  settings:save('all')
end

function remove_buff(profile_name, buff_name)
  -- Remove buff from profile
  if settings.profiles[profile_name][buff_name] ~= nil then
    settings.profiles[profile_name][buff_name] = nil
    log('Buff `' .. buff_name .. '` removed from profile `' .. profile_name .. '`')
  else
    log('Buff `' .. buff_name .. '` does not exist in profile `' .. profile_name .. '`')
  end
  settings:save('all')
end
