#!/usr/bin/env luajit
-- resave without openal hopefully
local loader = require 'audio.io.wav'()
local fn = ...
local args = loader:load(fn)
args.filename = 'resave.wav'
loader:save(args)
