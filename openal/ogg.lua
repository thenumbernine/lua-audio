local ffi = require 'ffi'
local stdio = require 'ffi.req' 'c.stdio'
local class = require 'ext.class'
local table = require 'ext.table'
local al = require 'ffi.req' 'OpenAL'
local vorbisfile = require 'ffi.req' 'vorbis.vorbisfile'

local OGGLoader = class()

-- example from: https://xiph.org/vorbis/doc/vorbisfile/example.html
function OGGLoader:load(filename)
	local fp = stdio.fopen(filename, 'rb')
	if fp == nil then
		error("unable to open file for reading: "..tostring(filename))
	end

	local vf = ffi.new'OggVorbis_File[1]'

	if vorbisfile.ov_open_callbacks(fp, vf, nil, 0, vorbisfile.OV_CALLBACKS_DEFAULT) < 0 then
		error"Input does not appear to be an Ogg bitstream"
	end

	local outbuf = table()
	local pcmout = ffi.new'char[4096]'
	local current_section = ffi.new'int[1]'
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

	local format
	if channels == 1 and bitsPerSample == 8 then
		format = al.AL_FORMAT_MONO8
	elseif channels == 1 and bitsPerSample == 16 then
		format = al.AL_FORMAT_MONO16
	elseif channels == 2 and bitsPerSample == 8 then
		format = al.AL_FORMAT_STEREO8
	elseif channels == 2 and bitsPerSample == 16 then
		format = al.AL_FORMAT_STEREO16
	end
	if not format then
		error("unrecognised ogg format: " .. channels .. " channels, " .. bitsPerSample .. " bps")
	end

	return {
		format = format,
		data = outbuf,
		size = #outbuf,
		freq = sampleRate,
	}
end

return OGGLoader
