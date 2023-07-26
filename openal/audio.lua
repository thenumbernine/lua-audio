local al = require 'ffi.OpenAL'
local class = require 'ext.class'
local GCWrapper = require 'ffi.gcwrapper.gcwrapper'

local method = 'alc'
--local method = 'alut'

local Audio = class(
	assert(({
		alc = function()
			-- TODO separate context from device
			return GCWrapper{
				gctype = 'autorelease_al_context_ptr_t',
				ctype = 'ALCcontext*',
				release = function()
					-- ... ??
				end,
			}
		end,
		alut = function()
			return GCWrapper{
				gctype = 'autorelease_alut_t',
				ctype = 'int',
				release = function()
					local alut = require 'ffi.OpenALUT'
					alut.alutExit()
				end,
			}
		end,
	})[method], "failed to find gcwrapper for method "..tostring(method))()
)


function Audio:init()
	Audio.super.init(self)
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
	self.gc.ptr[0] = self.ctx
	al.alcMakeContextCurrent(self.ctx)
elseif method == 'alut' then
	self.gc.ptr[0] = 1
	local alut = require 'ffi.OpenALUT'

	local alutErrors = {}
	for _,k in ipairs{
		'ALUT_ERROR_NO_ERROR',
		'ALUT_ERROR_OUT_OF_MEMORY',
		'ALUT_ERROR_INVALID_ENUM',
		'ALUT_ERROR_INVALID_VALUE',
		'ALUT_ERROR_INVALID_OPERATION',
		'ALUT_ERROR_NO_CURRENT_CONTEXT',
		'ALUT_ERROR_AL_ERROR_ON_ENTRY',
		'ALUT_ERROR_ALC_ERROR_ON_ENTRY',
		'ALUT_ERROR_OPEN_DEVICE',
		'ALUT_ERROR_CLOSE_DEVICE',
		'ALUT_ERROR_CREATE_CONTEXT',
		'ALUT_ERROR_MAKE_CONTEXT_CURRENT',
		'ALUT_ERROR_DESTROY_CONTEXT',
		'ALUT_ERROR_GEN_BUFFERS',
		'ALUT_ERROR_BUFFER_DATA',
		'ALUT_ERROR_IO_ERROR',
		'ALUT_ERROR_UNSUPPORTED_FILE_TYPE',
		'ALUT_ERROR_UNSUPPORTED_FILE_SUBTYPE',
		'ALUT_ERROR_CORRUPT_OR_TRUNCATED_DATA',
	} do
		alutErrors[alut[k]] = k
	end
	if alut.alutInit(nil, nil) == 0 then
		local err = alut.alutGetError()
		local errstr = alutErrors[tonumber(err)]
		error('alutInit failed with error '..err
			..(errstr and ' ('..errstr..')' or '')
		)
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
