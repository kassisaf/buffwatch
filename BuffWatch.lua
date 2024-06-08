--[[
BuffWatch
Copyright © 2024 Zuri
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright
notice, this list of conditions and the following disclaimer.
* Redistributions in binary form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in the
documentation and/or other materials provided with the distribution.
* Neither the name of craft nor the names of its contributors may be
used to endorse or promote products derived from this software without
specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL Mojo BE LIABLE FOR ANY
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

config = require('config')

windower.register_event('load', function()
  defaults = {
    language = windower.ffxi.get_info().language
  }
  settings = config.load(defaults)
  lang = string.lower(settings.language)
  player = windower.ffxi.get_player()
end)

windower.register_event('login', function()
  player = windower.ffxi.get_player()
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
  end
end)

function create_profile(profile_name)
end

function add_buff(profile_name, buff_name)
end
