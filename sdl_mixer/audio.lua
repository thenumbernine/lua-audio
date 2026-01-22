local mix = require 'sdl.ffi.sdl_mixer'
local class = require 'ext.class'


local Audio = class()

function Audio:init()
	if mix.Mix_OpenAudio(11205, mix.AUDIO_U8, 1, 512) < 0 then
		error('failed to open audio')
	end
end

function Audio:shutdown()
	mix.Mix_CloseAudio()
end

function Audio:setDistanceModel(model) end

function Audio:getMaxSources()
	return mix.MIX_CHANNELS
end

return Audio
