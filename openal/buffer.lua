local ffi = require 'ffi'
local GCWrapper = require 'ffi.gcwrapper.gcwrapper'
local al = require 'ffi.OpenAL'
local class = require 'ext.class'
local file = require 'ext.file'

local AudioBuffer = class(GCWrapper{
	gctype = 'autorelease_al_buffer_ptr_t',
	ctype = 'ALuint',
	release = function(ptr)
-- why does calling this upno release give me OpenAL shutdown error "AL lib: (EE) alc_cleanup: 1 device not closed"
-- maybe because the openal context and device are shutdown manually, so this is called after the device is already shut down
--		al.alDeleteBuffers(1, ptr) 
	end,
})

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
	AudioBuffer.super.init(self)
	al.alGenBuffers(1, self.gc.ptr)
	self.id = self.gc.ptr[0]
	assert(self.id ~= 0, "Could not generate buffer")

	local loader = getLoaderForFilename(filename)
	local result = loader:load(filename)

	al.alBufferData(self.id, result.format, result.data, result.size, result.freq)
end

return AudioBuffer
