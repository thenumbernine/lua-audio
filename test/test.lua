#!/usr/bin/env luajit
local ffi = require 'ffi'
local assert = require 'ext.assert'
local al = require 'audio.ffi.OpenAL'
local Audio = require 'audio'
local AudioSource = require 'audio.source'
local AudioBuffer = require 'audio.buffer'

local uint8_t = ffi.typeof'uint8_t'
local int16_t = ffi.typeof'int16_t'

local audio = Audio()

local durationInSeconds = 2 	-- seconds
-- [=[ custom buffer
--local sampleFramesPerSecond = 8000			-- sample frames / second
--local sampleFramesPerSecond = 11025			-- sample frames / second
--local sampleFramesPerSecond = 22050			-- sample frames / second
local sampleFramesPerSecond = 32000			-- sample frames / second <- SNES SPC sampling rate
--local sampleFramesPerSecond = 44100			-- sample frames / second
--local sampleFramesPerSecond = 48000			-- sample frames / second
local outputChannels = 1
--local outputChannels = 2	-- channels?  whats it called mono vs stereo, number of outputs?  idk terminology
local sampleType = uint8_t
--local sampleType = int16_t

local sampleFrames = sampleFramesPerSecond * durationInSeconds	-- ... x 5 seconds of play
local samples = sampleFrames * outputChannels
local sampleTypeArr = ffi.typeof('$[?]', sampleType)
local data = sampleTypeArr(samples)	-- x2 for stereo

local function sinewave(t)
	return math.sin(t * (2 * math.pi))
end
local function sawtoothwave(t)
	return (t % 1) * 2 - 1
end
local function squarewave(t)
	return (2 * math.floor(t) - math.floor(2 * t)) * 2 + 1
end
local function trianglewave(t)
	return math.abs(t - math.floor(t + .5)) * 4 - 1
end

local matrix = require 'matrix'
local gaussianFilterSize = 25
local gaussianFilterMid = (gaussianFilterSize+1)/2
local gaussianSigma = 3
local gaussianFilter = matrix{gaussianFilterSize}:lambda(function(i)
	local x = (i - gaussianFilterMid) / gaussianSigma
	return math.exp(-x*x)
end)
gaussianFilter = gaussianFilter / gaussianFilter:sum()
--assereteq(gaussianFilter:sum(), 1)
--[[ test to make sure it matches a pure sine when it is only a dirac delta at gaussianFilterMid (i.e. infinite sigma)
gaussianFilter = gaussianFilter * 0
gaussianFilter[gaussianFilterMid] = 1
--]]

-- OpenAL specs
-- https://www.openal.org/documentation/openal-1.1-specification.pdf
--	section 5.3.4:
-- "8-bit data is expressed as an unsigned value over the range 0 to 255, 128 being an audio output level of zero."
-- "16-bit data is expressed as a signed value over the range -32768 to 32767, 0 being an audio output level of zero. Byte order for 16-bit values is determined by the native format of the CPU."
local amplZero = assert.index({[tostring(uint8_t)]=128, [tostring(int16_t)]=0}, tostring(sampleType))
local amplMax = assert.index({[tostring(uint8_t)]=127, [tostring(int16_t)]=32767}, tostring(sampleType))
local e = 0
for i=0,sampleFrames-1 do
	local t = i/sampleFramesPerSecond

	local freq = 440
	--local freq = 220		-- middle A
	--local freq = 216		-- middle A for conspiracy theorists
	--local freq = 262		-- middle C = A * 2^(3/12) since C is 3 half-steps up from A
	--local freq = 257		-- middle C for conspiracy theorists

	--[[ pure sine wave
	local ampl = sinewave(t * freq)
	--]]
	-- [[ gaussianian sample of integers octaves (TODO thrown in some nearly rationals as well so we get chords instead of just octaves)
	--local f = sinewave
	local f = trianglewave
	--local f = sawtoothwave
	--local f = squarewave
	-- sounds like an organ
	local ampl = 0
	local filterPower = 2	-- 2 <-> 12/12 <-> octaves
	--local filterPower = 2^(1/2)	-- chords?
	--local filterPower = 2^(1/3)
	--local filterPower = 2^(1/4)
	--local filterPower = 2^(1/5)	-- ... becomes nonsense at this point
	--local filterPower = 2^(1/6)
	--local filterPower = 2^(1/8)
	--local filterPower = 2^(1/12)
	for j=1,gaussianFilterSize do
		--[=[ add octaves only (or whatever the filterPower is set to)
		ampl = ampl + gaussianFilter[j] * f(t * freq * filterPower^(j-gaussianFilterMid))
		--]=]
		-- [=[ .. and add chords
		ampl = ampl + gaussianFilter[j] * (
			  f(t * freq * filterPower^(j-gaussianFilterMid))
			--+ f(t * freq * filterPower^(j-gaussianFilterMid + 4/12))	-- 2^(4/12) ~ 1.259 ~ 5/4
			--+ f(t * freq * filterPower^(j-gaussianFilterMid + 7/12))	-- 2^(7/12) ~ 1.498 ~ 3/2
			+ f(t * freq * filterPower^(j-gaussianFilterMid) * 5/4)
			+ f(t * freq * filterPower^(j-gaussianFilterMid) * 3/2)
			-- can we use 3rds too? nahhh
			-- + f(t * freq * filterPower^(j-gaussianFilterMid) * 4/3)
			-- how about 4ths? actually yes ...  but here's why ...
			--+ f(t * freq * filterPower^(j-gaussianFilterMid) * 3/4)	-- this is just one octave down, then a 3/2, which we've already got above
			--+ f(t * freq * filterPower^(j-gaussianFilterMid) * 1/4)	-- this is just the original note, two octaves down
			-- so that really just leaves 7/4 ... and nah that sounds bad.
			--+ f(t * freq * filterPower^(j-gaussianFilterMid) * 7/4)
			-- how about 8ths? is it a power-of-two thing? nahhh
			-- + f(t * freq * filterPower^(j-gaussianFilterMid) * 9/8)
		) / 3
		--]=]
	end
	--]]
	assert(-1 <= ampl and ampl <= 1)
	-- ampl is [-1,1]
	for j=0,outputChannels-1 do
		data[e] = ampl * amplMax + amplZero
		e=e+1
	end
end
assert.eq(e, samples)

local buffer = AudioBuffer(
	sampleType,
	outputChannels,
	data,					-- data
	samples * ffi.sizeof(sampleType),	-- data size
	sampleFramesPerSecond				-- sample rate
)
--]=]
--[=[ just play a wav
local buffer = AudioBuffer((assert.type(..., 'string')))
--]=]
local source = AudioSource()
source:setBuffer(buffer)
source:play()

-- wait 5 seconds
require 'ffi.req' 'c.unistd'
ffi.C.sleep(durationInSeconds)
