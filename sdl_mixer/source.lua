local mix = require 'sdl.ffi.sdl_mixer'
local class = require 'ext.class'

local function Mix_PlayChannel(channel,chunk,loops)
	return mix.Mix_PlayChannelTimed(channel,chunk,loops,-1)
end


local AudioSource = class()

local channelIndex = 0
function AudioSource:init(buffer)
	self.channelIndex = channelIndex
	channelIndex = channelIndex + 1	-- modulo the number of channels ...
	if buffer then self:setBuffer(buffer) end
end

function AudioSource:setBuffer(buffer)
	buffer = buffer.buffer
	assert(buffer)
	self.currentBuffer = buffer
	return self
end

function AudioSource:setLooping(looping)
	self.looping = not not looping
end

function AudioSource:setGain(gain)
	mix.Mix_Volume(self.channelIndex, math.floor(gain*mix.MIX_MAX_VOLUME))
end

function AudioSource:setPitch(pitch) end
function AudioSource:setPosition(x,y,z) end
function AudioSource:setVelocity(x,y,z) end
function AudioSource:setReferenceDistance(d) end
function AudioSource:setMaxDistance(d) end
function AudioSource:setRolloffFactor(x) end

function AudioSource:play()
	if not self.currentBuffer then return end
	local loops = 0
	if self.looping then loops = 10000 end
	Mix_PlayChannel(self.channelIndex, self.currentBuffer, loops)
end

function AudioSource:stop()
	mix.Mix_HaltChannel(self.channelIndex)
end

function AudioSource:isPlaying()
	return mix.Mix_Playing(self.channelIndex) ~= 0
end

return AudioSource
