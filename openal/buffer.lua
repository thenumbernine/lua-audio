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
-- TODO the ctor is centered around wav files.  also add the ogg loader (now in sandtetris)
function AudioBuffer:init(filename)
	local ptr = ffi.new'ALuint[1]'
	al.alGenBuffers(1, ptr)
	self.id = ptr[0]
	assert(self.id ~= 0, "Could not generate buffer")

	local loader = getLoaderForFilename(filename)
	local result = loader:load(filename)

	al.alBufferData(self.id, result.format, result.data, result.size, result.freq)
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
