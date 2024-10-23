#!/usr/bin/env luajit
-- resave without openal hopefully
local loader = require 'audio.io.wav'()
local fn = ...
local args = loader:load(fn)
for k,v in pairs(args) do
	if k ~= 'data' then print(k,v) end
end
args.filename = 'resave.wav'
loader:save(args)
