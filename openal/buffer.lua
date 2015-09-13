local ffi = require 'ffi'
local al = require 'ffi.al'
local class = require 'ext.class'
local io = require 'ext.io'
local string = require 'ext.string'	-- for string.csub ... replace with original sub?


local AudioBuffer = class()

function AudioBuffer:init(filename)

	-- load data *HERE*
	-- TODO a better job with ffi since it is required

	local data = assert(io.readfile(filename))
	local dataIndex = 0
	local function read(n)
		local s = string.csub(data, dataIndex, n)
		dataIndex = dataIndex + n
		return s
	end
	local function readi(n)
		local s = read(n)
		local x = 0
		for i=n,1,-1 do
			x = x * 256
			x = x + s:sub(i,i):byte()
		end
		return x
	end

	-- courtesy of https://ccrma.stanford.edu/courses/422/projects/WaveFormat/
	
	-- header
	assert(read(4) == 'RIFF', "expected RIFF")
	local chunksize = readi(4)
	-- 36 * audioDataSize
	-- 4 + (8 + subchunk1size) + (8 + audioDataSize)
	assert(read(4) == 'WAVE', "expected WAVE")

	-- subchunk 1
	assert(read(4) == 'fmt ', "expected fmt ")
	local subchunk1size = readi(4)
	assert(subchunk1size == 16, "expected subchunk1size == 16, got "..subchunk1size)
	local audioFormat = readi(2)
	assert(audioFormat == 1, "expected audioFormat == 1, got "..audioFormat)
	local numChannels = readi(2)
	local sampleRate = readi(4)
	local byteRate = readi(4)
	local blockAlign = readi(2)
	local bitsPerSample = readi(2)
	--assert(bitsPerSample/8 == math.floor(bitsPerSample/8), "bitsPerSample is not byte-aligned")
	assert(blockAlign == numChannels * bitsPerSample / 8)
	assert(byteRate == sampleRate * numChannels * bitsPerSample / 8)
	
	-- audacity has junk ...
	local chunkid = nil
	local chunksize = nil
	while dataIndex < #data do
		chunkid = read(4)
		chunksize = assert(readi(4))
		if chunkid == 'data' then break end
		dataIndex = dataIndex + chunksize
	end
	if dataIndex >= #data then
		error("got to eof without finding data")
	end

	-- subchunk 2
	local audioDataSize = assert(chunksize)
	local numSamples = audioDataSize / (numChannels * bitsPerSample / 8)
	--if numSamples/8 ~= math.floor(numSamples/8) then print("numSamples "..numSamples.." is not byte-aligned") end
	numSamples = 8 * math.floor(numSamples / 8)
	
	-- the rest is audio data
	local audioData = string.csub(data, dataIndex, audioDataSize)
	
	
	local format
	if bitsPerSample == 8 then
		if numChannels == 1 then
			format = al.AL_FORMAT_MONO8
		elseif numChannels == 2 then
			format = al.AL_FORMAT_STEREO8
		else
			error("can't handle numChannels "..numChannels)
		end
	elseif bitsPerSample == 16 then
		if numChannels == 1 then
			format = al.AL_FORMAT_MONO16
		elseif numChannels == 2 then
			format = al.AL_FORMAT_STEREO16
		else
			error("can't handle numChannels "..numChannels)
		end
	else
		error("can't handle bitsPerSample "..bitsPerSample)
	end

	
	self.buffer = ffi.new('ALuint[1]')
	al.alGenBuffers(1, self.buffer)
	assert(self.buffer[0] ~= 0, "Could not generate buffer")
	
	al.alBufferData(
		self.buffer[0],
		format,
		audioData,
		audioDataSize,
		sampleRate)
end

return AudioBuffer
