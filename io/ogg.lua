local ffi = require 'ffi'
local stdio = require 'ffi.req' 'c.stdio'
local class = require 'ext.class'
local table = require 'ext.table'
local vorbisfile = require 'audio.ffi.vorbisfile'


local uint8_t = ffi.typeof'uint8_t'
local int16_t = ffi.typeof'int16_t'
local char_4096 = ffi.typeof'char[4096]'
local int_1 = ffi.typeof'int[1]'
local OggVorbis_File_1 = ffi.typeof'OggVorbis_File[1]'


local OGGLoader = class()

-- example from: https://xiph.org/vorbis/doc/vorbisfile/example.html
function OGGLoader:load(filename)
	local fp = stdio.fopen(filename, 'rb')
	if fp == nil then
		error("unable to open file for reading: "..tostring(filename))
	end

	local vf = OggVorbis_File_1()

	if vorbisfile.ov_open_callbacks(fp, vf, nil, 0, vorbisfile.OV_CALLBACKS_DEFAULT) < 0 then
		error"Input does not appear to be an Ogg bitstream"
	end

	local outbuf = table()
	local pcmout = char_4096()
	local current_section = int_1()
	local eof = false
	local totalsize  = 0
	while not eof do
		local ret = vorbisfile.ov_read(vf, pcmout, ffi.sizeof(pcmout), 0, 2, 1, current_section)
		if ret == 0 then
			eof = true
		elseif ret < 0 then
			print("error decoding ogg "..ret)
		else
			-- TODO?
			-- we don't bother dealing with sample rate changes, etc, but
			-- you'll have to
			outbuf:insert(ffi.string(pcmout, ret))
			totalsize = totalsize + ret
		end
	end
	outbuf = outbuf:concat()
	assert(totalsize == #outbuf)

	local vi = vorbisfile.ov_info(vf, -1)

	local channels = vi[0].channels
	local bitsPerSample = 16
	local sampleRate = vi[0].rate
	--local duration = vorbisfile.ov_time_total(vf, -1)

	local ctype
	if bitsPerSample == 8 then
		ctype = uint8_t
	elseif bitsPerSample == 16 then
		ctype = int16_t
	else
		error("can't handle bitsPerSample "..bitsPerSample)
	end

	return {
		ctype = ctype,
		channels = channels,
		data = outbuf,
		size = #outbuf,
		freq = sampleRate,
	}
end

return OGGLoader
