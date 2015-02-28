local ffi = require 'ffi'
local al = require 'ffi.al'
local class = require 'ext.class'


local AudioSource = class()

function AudioSource:init(buffer)
	self.src = ffi.new('ALuint[1]')
	al.alGenSources(1, self.src)

	if buffer then
		self:setBuffer(buffer)
	end
	self:setPitch(1)
	self:setGain(1)
	self:setLooping(false)
	self:setPosition(0,0,0)
	self:setVelocity(0,0,0)
end

function AudioSource:setBuffer(buffer)
	if getmetatable(buffer) == AudioBuffer then
		buffer = buffer.buffer
	end
	assert(buffer)
	al.alSourcei(self.src[0], al.AL_BUFFER, buffer[0])
	return self
end

function AudioSource:setLooping(looping)
	if looping then
		looping = 1
	else
		looping = 0
	end
	al.alSourcei(self.src[0], al.AL_LOOPING, looping)
end

function AudioSource:setGain(gain)
	al.alSourcef(self.src[0], al.AL_GAIN, gain)
end

function AudioSource:setPitch(pitch)
	al.alSourcef(self.src[0], al.AL_PITCH, pitch)
end

local float3 = ffi.new('ALfloat[3]')
function AudioSource:setPosition(x,y,z)
	float3[0], float3[1], float3[2] = x, y, z
	al.alSourcefv(self.src[0], al.AL_POSITION, float3)
end

function AudioSource:setVelocity(x,y,z)
	float3[0], float3[1], float3[2] = x, y, z
	al.alSourcefv(self.src[0], al.AL_VELOCITY, float3)
end

function AudioSource:setReferenceDistance(d)
	al.alSourcef(self.src[0], al.AL_REFERENCE_DISTANCE, d)
end

function AudioSource:setMaxDistance(d)
	al.alSourcef(self.src[0], al.AL_MAX_DISTANCE, d)
end

function AudioSource:setRolloffFactor(x)
	al.alSourcef(self.src[0], al.AL_ROLLOFF_FACTOR, x)
end

function AudioSource:play()
	al.alSourcePlay(self.src[0])
end

function AudioSource:stop()
	al.alSourceStop(self.src[0])
end

local state = ffi.new('ALenum[1]')
function AudioSource:isPlaying()
	al.alGetSourcei(self.src[0], al.AL_SOURCE_STATE, state)
    return state[0] == al.AL_PLAYING
end

return AudioSource
