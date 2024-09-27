--[[
TODO sdl_mixer has its own wav loader so... let audio subtypes override? idk
--]]
local ffi = require 'ffi'
local class = require 'ext.class'
local path = require 'ext.path'

ffi.cdef[[
typedef struct {
	char RIFF[4];
	uint32_t chunksize;
	char WAVE[4];
	char fmt_[4];
	uint32_t subchunk1size;
	uint16_t audioFormat;
	uint16_t numChannels;
	uint32_t sampleRate;
	uint32_t byteRate;
	uint16_t blockAlign;
	uint16_t bitsPerSample;
} wavheader_t;
]]
assert(ffi.sizeof'wavheader_t' == 36)
local WavLoader = class()

--[[
returns a table containing:
	format = ctype of output format
	channels = how many channels
	data = raw data buffer
	size = data size in bytes
	freq = sample-frames per second
--]]
function WavLoader:load(filename)
	local success, result = xpcall(function()
		-- TODO a better job with ffi since it is required
		-- load data *HERE*
		local data = assert(path(filename):read())
		local datalen = #data
		local dataIndex = 0
		local ptr = ffi.cast('char*', data)

		-- courtesy of https://ccrma.stanford.edu/courses/422/projects/WaveFormat/
		local hdr = ffi.new'wavheader_t[1]'
		ffi.copy(hdr, ptr, ffi.sizeof'wavheader_t')
		dataIndex = dataIndex + ffi.sizeof'wavheader_t'

		local sigRIFF = ffi.string(hdr[0].RIFF, 4)
		if sigRIFF ~= 'RIFF' then
			error("wav file has bad RIFF signature: "..require 'ext.tolua'(sigRIFF))
		end
		local chunksize = hdr[0].chunksize
		-- 36 * audioDataSize
		-- 4 + (8 + subchunk1size) + (8 + audioDataSize)
		assert(ffi.string(hdr[0].WAVE, 4) == 'WAVE')

		-- subchunk 1
		assert(ffi.string(hdr[0].fmt_, 4) == 'fmt ')
		local subchunk1size = hdr[0].subchunk1size
		assert(subchunk1size == 16, "expected subchunk1size == 16, got "..subchunk1size)
		local audioFormat = hdr[0].audioFormat
		assert(audioFormat == 1, "expected audioFormat == 1, got "..audioFormat)
		local numChannels = hdr[0].numChannels
		local sampleRate = hdr[0].sampleRate
		local byteRate = hdr[0].byteRate
		local blockAlign = hdr[0].blockAlign
		local bitsPerSample = hdr[0].bitsPerSample
		--assert(bitsPerSample/8 == math.floor(bitsPerSample/8), "bitsPerSample is not byte-aligned")
		assert(blockAlign == numChannels * bitsPerSample / 8)
		assert(byteRate == sampleRate * numChannels * bitsPerSample / 8)

		-- audacity has junk ...
		local uint32 = ffi.new'uint32_t[1]'
		local chunkid = nil
		local chunksize = nil
		while dataIndex < datalen do
			chunkid = ffi.string(ptr + dataIndex, 4)
			dataIndex = dataIndex + 4
			ffi.copy(uint32, ptr + dataIndex, 4)
			dataIndex = dataIndex + 4
			chunksize = uint32[0]
			if chunkid == 'data' then break end
			dataIndex = dataIndex + chunksize
		end
		if dataIndex > datalen then
			error("got to eof without finding data")
		end

		-- subchunk 2
		local audioDataSize = assert(chunksize)
		--[[ if you need it ...
		local numSamples = audioDataSize / (numChannels * bitsPerSample / 8)
		--if numSamples/8 ~= math.floor(numSamples/8) then print("numSamples "..numSamples.." is not byte-aligned") end
		numSamples = 8 * math.floor(numSamples / 8)
		--]]

		-- the rest is audio data
		local audioData = string.sub(data, dataIndex+1, dataIndex+audioDataSize)


		local ctype
		if bitsPerSample == 8 then
			ctype = 'uint8_t'
		elseif bitsPerSample == 16 then
			ctype = 'int16_t'
		else
			error("can't handle bitsPerSample "..bitsPerSample)
		end

		return {
			ctype = ctype,
			channels = numChannels,
			data = audioData,
			size = audioDataSize,
			freq = sampleRate,
		}
	end, function(err)
		return err..'\n'..debug.traceback()
	end)
	if not success then error("failed loading file "..filename.."\n"..result) end
	return result
end

--[[
args:
	filename = filename
	ctype = ctype of the data, usually uint8_t or int16_t if it's coming from OpenAL
	data = raw data of the ctype
	size = data size in bytes
	freq = sample-frames per second
--]]
function WavLoader:save(args)
	--[[ TODO a proper library ...
	local hdr = ffi.new'wavheader_t[1]'
	hdr[0].RIFF[0], hdr[0].RIFF[1], hdr[0].RIFF[2], hdr[0].RIFF[3] = ('RIFF'):byte(1,4)
	hdr[0].WAVE[0], hdr[0].WAVE[1], hdr[0].WAVE[2], hdr[0].WAVE[3] = ('WAVE'):byte(1,4)
	hdr[0].chunksize
	--]]
end

return WavLoader
