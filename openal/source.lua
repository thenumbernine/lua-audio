require 'ext.gc'	-- add __gc to luajit
local ffi = require 'ffi'
local al = require 'audio.ffi.OpenAL'
local class = require 'ext.class'
local AudioBuffer = require 'audio.openal.buffer'

local AudioSource = class()

function AudioSource:init(buffer)
	local ptr = ffi.new'ALuint[1]'
	al.alGenSources(1, ptr)
	self.id = ptr[0]

	if buffer then
		self:setBuffer(buffer)
	end
	self:setPitch(1)
	self:setGain(1)
	self:setLooping(false)
	self:setPosition(0,0,0)
	self:setVelocity(0,0,0)
end

function AudioSource:delete()
	if self.id == nil then return end
	local ptr = ffi.new'ALuint[1]'
	ptr[0] = self.id
	al.alDeleteSources(1, ptr)
	self.id = nil
end

function AudioSource:setBuffer(buffer)
	if getmetatable(buffer) == AudioBuffer then
		buffer = buffer.id
	end
	assert(buffer)
	al.alSourcei(self.id, al.AL_BUFFER, buffer)
	return self
end

function AudioSource:setLooping(looping)
	if looping then
		looping = 1
	else
		looping = 0
	end
	al.alSourcei(self.id, al.AL_LOOPING, looping)
end

function AudioSource:setGain(gain)
	al.alSourcef(self.id, al.AL_GAIN, gain)
end

function AudioSource:setPitch(pitch)
	al.alSourcef(self.id, al.AL_PITCH, pitch)
end

local float3 = ffi.new('ALfloat[3]')
function AudioSource:setPosition(x,y,z)
	float3[0], float3[1], float3[2] = x, y, z
	al.alSourcefv(self.id, al.AL_POSITION, float3)
end

function AudioSource:setVelocity(x,y,z)
	float3[0], float3[1], float3[2] = x, y, z
	al.alSourcefv(self.id, al.AL_VELOCITY, float3)
end

function AudioSource:setReferenceDistance(d)
	al.alSourcef(self.id, al.AL_REFERENCE_DISTANCE, d)
end

function AudioSource:setMaxDistance(d)
	al.alSourcef(self.id, al.AL_MAX_DISTANCE, d)
end

function AudioSource:setRolloffFactor(x)
	al.alSourcef(self.id, al.AL_ROLLOFF_FACTOR, x)
end

function AudioSource:play()
	al.alSourcePlay(self.id)
end

function AudioSource:stop()
	al.alSourceStop(self.id)
end

local state = ffi.new('ALenum[1]')
function AudioSource:isPlaying()
	al.alGetSourcei(self.id, al.AL_SOURCE_STATE, state)
    return state[0] == al.AL_PLAYING
end

return AudioSource
