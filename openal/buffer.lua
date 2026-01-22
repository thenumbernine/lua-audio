require 'ext.gc'	-- add __gc to luajit
local ffi = require 'ffi'
local al = require 'audio.ffi.OpenAL'
local class = require 'ext.class'
local path = require 'ext.path'

local uint8_t = ffi.typeof'uint8_t'
local int16_t = ffi.typeof'int16_t'
local ALuint_1 = ffi.typeof'ALuint[1]'

local AudioBuffer = class()

AudioBuffer.loaders = {
	wav = 'audio.io.wav',
	ogg = 'audio.io.ogg',
}

local function getLoaderForFilename(filename)
	local ext = select(2, path(filename):getext())
	if ext then ext = ext:lower() end
	assert(ext, "failed to get extension for filename "..tostring(filename))
	local loaderRequire = assert(AudioBuffer.loaders[ext], "failed to find loader class for extension "..ext.." for filename "..filename)
	local loaderClass = require(loaderRequire)
	local loader = loaderClass()
	return loader
end

local function getALFormatForCTypeAndChannels(ctype, channels)
	ctype = ffi.typeof(ctype)
	if ctype == uint8_t then
		-- OpenAL wants unsigned only for 8bpp
		if channels == 1 then
			return al.AL_FORMAT_MONO8
		elseif channels == 2 then
			return al.AL_FORMAT_STEREO8
		end
	elseif ctype == int16_t then
		-- OpenAL wants unsigned only for 16bpp
		if channels == 1 then
			return al.AL_FORMAT_MONO16
		elseif channels == 2 then
			return al.AL_FORMAT_STEREO16
		end
	end
end

-- TODO fix this and everyone that uses it ... which isn't many other projects
-- TODO the ctor is centered around files.  also buffer support?
function AudioBuffer:init(...)
	local ptr = ALuint_1()
	al.alGenBuffers(1, ptr)
	self.id = ptr[0]
	assert(self.id ~= 0, "Could not generate buffer")

	if select('#', ...) == 1 and type(...) == 'string' then
		self:load((...))
	elseif select('#', ...) == 4 then
		self:setData(...)
	end
end

function AudioBuffer:load(filename)
	local loader = getLoaderForFilename(filename)
	local result = loader:load(filename)
	return self:setData(
		result.ctype,
		result.channels,
		result.data,
		result.size,
		result.freq
	)
end

function AudioBuffer:save(filename)
	local loader = getLoaderForFilename(filename)
	loader:save{
		filename = filename,
		ctype = self.ctype,
		channels = self.channels,
		data = self.data,
		size = self.size,
		freq = self.freq,
	}
	return self
end

function AudioBuffer:setData(ctype, channels, data, size, freq)
	self.ctype = assert(ffi.typeof(ctype))
	self.channels = channels
	self.data = data
	self.size = size
	self.freq = freq
	local alFormat = getALFormatForCTypeAndChannels(ctype, channels)
	if not alFormat then
		error("failed to find OpenAL format for ctype="..tostring(ctype).." channels="..tostring(channels))
	end
	al.alBufferData(self.id, alFormat, data, size, freq)
	return self
end

function AudioBuffer:delete()
	if self.id == nil then return end
	local ptr = ALuint_1()
	ptr[0] = self.id
	al.alDeleteBuffers(1, ptr)
	self.id = nil
end

AudioBuffer.__gc = AudioBuffer.delete

return AudioBuffer
