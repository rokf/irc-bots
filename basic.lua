
-- luarocks install irc-engine
-- luarocks install cqueues

-- http://25thandclement.com/~william/projects/cqueues.html
-- https://github.com/mirrexagon/lua-irc-engine

local irce = require 'irce' -- for the IRC protocol
local socket = require 'cqueues.socket' -- for the communication

local irc = irce.new() -- new IRCe instance
irc:load_module(require('irce.modules.base'))
irc:load_module(require('irce.modules.message'))
irc:load_module(require('irce.modules.channel'))

local nickname = 'bot'
local username = 'bot'
local realname = 'Mr. Bot'

local running = true

local channel = '#hello' -- join channel named hello

-- connect to a local IRC server on the port 6667
local connection = socket.connect('127.0.0.1', '6667')

-- I recommend https://github.com/jrosdahl/miniircd for BOT testing, its amazing

-- irc-engine is not bound to a socket library
-- this means you have to tell it how to send data
irc:set_send_func(function (self,message)
  -- this bot uses the write method
  -- from the cqueues.socket module
  return connection:write(message)
end)

-- how to respond to RPL_WELCOME
-- https://www.alien.net.au/irc/irc2numerics.html
irc:set_callback('001', function (self, ...)
	irc:send_raw('JOIN ' .. channel) -- join channel #hello
end)

-- message receive
irc:set_callback('PRIVMSG', function (self, sender, origin, message, pm)
	if message == '!quit' then -- if someone in the channel types !quit the bot stops
		self:QUIT('Bye!')
		running = false
	elseif message == 'hello' then -- respond to a "hello"
		irc:send('PRIVMSG', channel, 'hi there')
	end
end)

-- send names to server
irc:send_raw('NICK ' .. nickname)
irc:send_raw('USER ' .. username .. " 0 * :" .. realname)

while running do -- process received data
	irc:process(connection:recv('*l'))
end
