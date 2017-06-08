
local irce = require 'irce'
local socket = require 'cqueues.socket'

local irc = irce.new()
irc:load_module(require('irce.modules.base'))
irc:load_module(require('irce.modules.message'))
irc:load_module(require('irce.modules.channel'))

local running = true

local list = {}

local nickname, username, realname = 'basil', 'basil', 'Basil'
local host, port, channel = arg[1], arg[2], '#' .. arg[3]

print(host)
print(port)
print(channel)

local connection = socket.connect(host,port)

local commands = {
  ['wtb'] = function (sender,remainder)
    if not list[remainder] then
      list[remainder] = {}
    end
    list[remainder][sender] = true
  end,
  ['found'] = function (sender,remainder)
    local users = {}
    for k,_ in pairs(list[remainder] or {}) do
      table.insert(users,k)
    end
    if #users == 0 then
      irc:send('PRIVMSG',channel,('Noone is looking for that item %s.'):format(sender))
    elseif #users == 1 then
      irc:send('PRIVMSG',channel, ("User %s is looking for %s!"):format(table.concat(users,','),remainder))
    else
      irc:send('PRIVMSG',channel, ("Users %s are looking for %s."):format(table.concat(users,','),remainder))
    end
  end,
  ['bought'] = function (sender,remainder)
    if list[remainder][sender] == true then
      list[remainder][sender] = nil
      irc:send('PRIVMSG',channel, ('User %s is not looking for %s anymore.'):format(sender,remainder))
    end
  end
}

irc:set_send_func(function (self,message)
  return connection:write(message)
end)

irc:set_callback('001', function (self, _)
  irc:send_raw('JOIN ' .. channel)
end)

irc:set_callback('PRIVMSG', function (self,sender,origin,message,pm)
  local command, remainder = string.match(message,'%?(%a+)%s*([^\n]*)')
  if command ~= nil and remainder ~= nil then
    commands[command](sender[1], remainder)
  end
end)

irc:set_callback('PART', function (sender,_,_)
  for k,_ in pairs(list) do -- user left channel, remove their data
    list[k][sender] = nil
  end
end)

irc:send_raw('NICK ' .. nickname)
irc:send_raw('USER ' .. username .. " 0 * :" .. realname)

while running do
  irc:process(connection:recv('*l'))
end
