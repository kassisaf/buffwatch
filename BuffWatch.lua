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
_addon.version = '0.3.2'
_addon.commands = {
  'buffwatch',
  'bw'
}

require('chat')
require('logger')
config = require('config')
res = require('resources')
texts = require('texts')

local image = texts.new()
local active_profile = nil
local colors = {
  green = '\\cs(0,255,0)',
  red = '\\cs(255,0,0)',
  white = '\\cs(255,255,255)'
}
local jobs = {}
local display_text = ''
local global_profile = 'global'

windower.register_event('load', function()
  defaults = T {
    background = {
      visible = false,
      alpha = 128
    },
    text = {
      font = 'Arial',
      size = 11,
      stroke = {
        width = 2,
        transparency = 200
      }
    },
    pos = {
      x = 141,
      y = 83
    },
    profiles = {
      example = {
        _618 = {
          id = 618,
          en = "Emporox's Gift",
          label = "Potpourri"
        },
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
    },
    auto_swap_job_profiles = true,
    default_to_global_profile = true,
    show_ok_message = true
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

  -- Populate job table from resources
  for _, job in pairs(res.jobs) do
    jobs[job.ens:lower()] = true
  end

  autodetect_job_profile()
  if active_profile == nil and settings.default_to_global_profile and settings.profiles.global then
    active_profile = global_profile
  end

  update_text()
end)

windower.register_event('unload', function()
  settings = config.load()
  settings.pos.x = image:pos_x()
  settings.pos.y = image:pos_y()
  settings:save('all')
end)

windower.register_event('gain buff', function(buff_id)
  update_text()
end)

windower.register_event('lose buff', function(buff_id)
  update_text()
end)

windower.register_event('prerender', function(buff_id)
  image:visible(active_profile ~= nil)
end)

windower.register_event('job change', function()
  autodetect_job_profile()
end)

windower.register_event('login', function()
  autodetect_job_profile()
end)

windower.register_event('logout', function()
  reset_active_profile()
end)

function update_text()
  if active_profile == nil then
    image:text('')
    return
  end

  settings = config.load()
  if active_profile == global_profile then
    display_text = get_inactive_buff_text(global_profile)
  else
    display_text = get_inactive_buff_text(active_profile) .. get_inactive_buff_text(global_profile)
  end

  if settings.show_ok_message and table.length(settings.profiles[active_profile]) and display_text == '' then
    display_text = string.format(' %sBuffs OK', colors.green)
  else
    display_text = string.format(' %sMissing:%s\n%s', colors.white, colors.red, display_text)
  end

  image:text(display_text)
end

function get_inactive_buff_text(profile_name)
  -- Assume `settings` has already been updated prior to calling this function
  if settings.profiles[profile_name] == nil or table.length(settings.profiles[profile_name]) == 0 then
    return ''
  end

  local active_buffs = windower.ffxi.get_player().buffs

  result = ''
  for _, buff in pairs(settings.profiles[profile_name]) do
    if not table.find(active_buffs, buff.id) then
      result = string.format('%s %s\n', result, buff.label)
    end
  end
  return result
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
  settings:save('all')

  update_text()
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
    settings:save('all')
  else
    error(string.format('Buff `%s` not found in profile `%s`', buff_name, profile_name))
  end

  update_text()
end

function set_active_profile(profile_name)
  settings = config.load()
  if settings.profiles[profile_name] == nil then
    error(string.format('Profile `%s` not found', profile_name))
    return
  end
  active_profile = profile_name
  log(string.format('Active profile set to `%s`', profile_name))
  update_text()
end

function autodetect_job_profile()
  settings = config.load()
  if settings.auto_swap_job_profiles == false then
    return -- User disabled this behavior
  end

  local player = windower.ffxi.get_player()
  if player == nil then
    return -- Not logged in
  end

  local main_job = player.main_job:lower()
  local sub_job = player.sub_job

  -- If a profile exists for our current main and subjob, switch to it
  if sub_job then
    sub_job = sub_job:lower()
    local full_job = string.format('%s_%s', main_job, sub_job)
    if settings.profiles[full_job] ~= nil and active_profile ~= full_job then
      set_active_profile(full_job)
      return
    end
  end
  -- If a profile exists for our current main job, switch to it
  if settings.profiles[main_job] ~= nil and active_profile ~= main_job then
    set_active_profile(main_job)
    return
  end

  -- If the active profile is a job profile and no longer matches the current job, reset it
  if active_profile == nil then
    return -- nothing to do
  end

  local switched_from_main_job_profile = is_valid_main_job(active_profile) and active_profile ~= main_job
  local switched_from_full_job_profile = sub_job and is_valid_full_job(active_profile) and active_profile ~= full_job

  if switched_from_main_job_profile or switched_from_full_job_profile then
    log(string.format('Active profile reset because `%s` no longer matches current job (%s/%s)', active_profile, main_job, sub_job))
    reset_active_profile()
  end
end

function reset_active_profile()
  settings = config.load()
  if settings.default_to_global_profile and settings.profiles[global_profile] then
    active_profile = global_profile
  else
    active_profile = nil
  end
  update_text()
end

function is_valid_main_job(job)
  return jobs[job]
end

function is_valid_full_job(job)
  return job:find('_') and jobs[job:split('_')[1]] and jobs[job:split('_')[2]]
end

function print_profile_list()
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

function print_active_profile()
  if active_profile == nil then
    log('No active profile set')
    return
  end
  log(string.format('Active profile: %s, watching the following buffs:', active_profile))

  for _, buff in pairs(settings.profiles[active_profile]) do
    local line = (string.format(' %d: %s', buff.id, buff.en))
    if buff.label ~= buff.en then
      line = line .. string.format(' as `%s`', buff.label)
    end
    log(line)
  end
end

function print_active_buffs()
  local active_buffs = windower.ffxi.get_player().buffs

  if table.length(active_buffs) == 0 then
    log('No active buffs to display')
    return
  end
  log('Currently active buffs:')
  for i, buff_id in ipairs(active_buffs) do
    local buff = res.buffs[buff_id]
    if buff ~= nil then
      log(string.format(' %d: %s', buff_id, buff.en))
    end
  end
end

function print_help_text()
  local help_text = {
    {
      syntax = '[a]dd <profile> <buff name> [label]',
      description = 'Add a buff'
    },
    {
      syntax = '[r]emove <profile> <buff name>',
      description = 'Remove a buff'
    },
    {
      syntax = '[s]et <profile>',
      description = 'Set active profile'
    },
    {
      syntax = '[l]ist',
      description = 'List available profiles'
    },
    {
      syntax = 'reset',
      description = 'Reset active profile'
    },
    {
      syntax = '[find OR search] <buff name>',
      description = 'Search for a buff by name'
    },
    {
      syntax = 'debug',
      description = 'Print info about active profile and active buffs'
    }
  }

  log('Available commands:')
  for _, command in pairs(help_text) do
    windower.add_to_chat(207, string.format(' %s: %s', command.syntax, command.description))
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
    print_help_text()

  elseif cmd[1] == 'add' or cmd[1] == 'a' then
    if cmd[2] == nil or cmd[3] == nil then
      error('Invalid command. Try `bw [a]dd <profile> <buff> [label]`')
    else
      add_buff(cmd[2], windower.convert_auto_trans(cmd[3]), cmd[4] or nil)
    end

  elseif cmd[1] == 'remove' or cmd[1] == 'r' then
    if cmd[2] == nil or cmd[3] == nil then
      error('Invalid command. Try `bw [r]emove <profile> <buff>`')
    else
      remove_buff(cmd[2], windower.convert_auto_trans(cmd[3]))
    end

  elseif cmd[1] == 'set' or cmd[1] == 's' then
    if cmd[2] == nil then
      error('Invalid command. Try `bw [s]et <profile>`')
    else
      set_active_profile(cmd[2])
    end

  elseif cmd[1] == 'list' or cmd[1] == 'l' then
    print_profile_list()

  elseif cmd[1] == 'reset' then
    reset_active_profile()

  elseif cmd[1] == 'find' or cmd[1] == 'search' then
    if cmd[2] == nil then
      error('Invalid command. Try `bw <find|search> <buff>`')
    else
      -- TODO slice the table 2:last to allow search terms with spaces and no quotes
      search(windower.convert_auto_trans(cmd[2]))
    end

  elseif cmd[1] == 'debug' then
    print_active_profile()
    print_active_buffs()

  end
end)
