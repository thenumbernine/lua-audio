local ffi = require 'ffi'
local al = require 'ffi.OpenAL'
local class = require 'ext.class'


local Audio = class()

--local method = 'alc'
local method = 'alut'

function Audio:init()
if method == 'alc' then
	self.oldCtx = al.alcGetCurrentContext()
	self.dev = al.alcOpenDevice(nil)
	if self.dev == nil then
		error("Could not open the default OpenAL device")
	end
	self.ctx = al.alcCreateContext(self.dev, nil)
	if self.ctx == nil then
		if self.oldCtx ~= nil then
			al.alcMakeContextCurrent(self.oldCtx)
		end
		al.alcCloseDevice(self.dev)
		error("Could not create a context")
	end
	al.alcMakeContextCurrent(self.ctx)
elseif method == 'alut' then
	local alut = require 'ffi.OpenALUT'
	if alut.alutInit(nil, nil) == 0 then
		error('alutInit failed with error '..alut.alutGetError())
	end
	al.alGetError()	-- "clear the error", what the official docs say ...
	-- http://open-activewrl.sourceforge.net/data/OpenAL_PGuide.pdf
end
end

function Audio:shutdown()
if method == 'alc' then
	if self.oldCtx ~= nil then
		al.alcMakeContextCurrent(self.oldCtx)
	end

	if self.ctx then al.alcDestroyContext(self.ctx) end
	if self.dev then al.alcCloseDevice(self.dev) end
	self.ctx = nil
	self.dev = nil
elseif method == 'alut' then
	local alut = require 'ffi.OpenALUT'
	alut.alutExit()
end
end

function Audio:setDistanceModel(model)
	if type(model) == 'string' then
		if model == 'inverse' then
			model = al.AL_INVERSE_DISTANCE
		elseif model == 'inverse clamped' then
			model = al.AL_INVERSE_DISTANCE_CLAMPED
		elseif model == 'linear' then
			model = al.AL_LINEAR_DISTANCE
		elseif model == 'linear clamped' then
			model = al.AL_LINEAR_DISTANCE_CLAMPED
		elseif model == 'exponent' then
			model = al.AL_EXPONENT_DISTANCE
		elseif model == 'exponent clamped' then
			model = al.AL_EXPONENT_DISTANCE_CLAMPED
		end
	end
	if type(model) ~= 'number' then
		error("expected number or model-description string")
	end
	al.alDistanceModel(model)
end

function Audio:getMaxSources() return 32 end

return Audio
