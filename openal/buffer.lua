local ffi = require 'ffi'
local al = require 'ffi.OpenAL'
local class = require 'ext.class'
local file = require 'ext.file'

local AudioBuffer = class()

AudioBuffer.loaders = {
	wav = 'audio.openal.wav',
	ogg = 'audio.openal.ogg',
}

local function getLoaderForFilename(filename)
	local ext = select(2, file(filename):getext())
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
	local loader = getLoaderForFilename(filename)
	local result = loader:load(filename)

	self.buffer = ffi.new('ALuint[1]')
	al.alGenBuffers(1, self.buffer)
	assert(self.buffer[0] ~= 0, "Could not generate buffer")

	al.alBufferData(self.buffer[0], result.format, result.data, result.size, result.freq)
end

return AudioBuffer
