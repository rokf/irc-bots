
local irce = require 'irce'
local socket = require 'cqueues.socket'

local irc = irce.new()
irc:load_module(require('irce.modules.base'))
irc:load_module(require('irce.modules.message'))
irc:load_module(require('irce.modules.channel'))

-- TODO
