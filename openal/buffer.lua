require 'ext.gc'	-- add __gc to luajit
local ffi = require 'ffi'
local al = require 'ffi.req' 'OpenAL'
local class = require 'ext.class'
local path = require 'ext.path'

local AudioBuffer = class()

AudioBuffer.loaders = {
	wav = 'audio.openal.wav',
	ogg = 'audio.openal.ogg',
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

-- TODO fix this and everyone that uses it ... which isn't many other projects
-- TODO the ctor is centered around files.  also buffer support? 
function AudioBuffer:init(...)
	local ptr = ffi.new'ALuint[1]'
	al.alGenBuffers(1, ptr)
	self.id = ptr[0]
	assert(self.id ~= 0, "Could not generate buffer")

	if type(...) == 'string' then
		self:load((...))
	elseif select('#', ...) == 4 then
		self:setData(...)
	end
end

function AudioBuffer:load(filename)
	local loader = getLoaderForFilename(filename)
	local result = loader:load(filename)
	self:setData(result.format, result.data, result.size, result.freq)
	return self
end

function AudioBuffer:save(filename)
	local loader = getLoaderForFilename(filename)
	loader:save{
		filename = filename,
		format = self.format,
		data = self.data,
		size = self.size,
		freq = self.freq,
	}
	return self
end

function AudioBuffer:setData(format, data, size, freq)
	self.format = format
	self.data = data
	self.size = size
	self.freq = freq
	al.alBufferData(self.id, format, data, size, freq)
	return self
end

function AudioBuffer:delete()
	if self.id == nil then return end
	local ptr = ffi.new'ALuint[1]'
	ptr[0] = self.id
	al.alDeleteBuffers(1, ptr) 
	self.id = nil
end

AudioBuffer.__gc = AudioBuffer.delete

return AudioBuffer
