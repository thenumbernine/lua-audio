local sdl = require 'ffi.sdl'
local mix = require 'ffi.sdl_mixer'
local class = require 'ext.class'


local function Mix_LoadWAV(file)
	return mix.Mix_LoadWAV_RW(
		sdl.SDL_RWFromFile(file, "rb"),
		1)
end


local AudioBuffer = class()

function AudioBuffer:init(filename)
	self.buffer = Mix_LoadWAV(filename)
end

function AudioBuffer:free()
	mix.Mix_FreeChunk(self.buffer)
end

return AudioBuffer

