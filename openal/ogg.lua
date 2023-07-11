local ffi = require 'ffi'
require 'ffi.c.stdio'
local class = require 'ext.class'
local table = require 'ext.table'
local al = require 'ffi.OpenAL'
local vorbisfile = require 'ffi.vorbis.vorbisfile'

local OGGLoader = class()

function OGGLoader:load(filename)
	local fp = ffi.C.fopen(filename, 'rb')
	if fp == nil then
		error("unable to open file for reading: "..tostring(filename))
	end

	-- example from: https://xiph.org/vorbis/doc/vorbisfile/example.html
	local vf = ffi.new'OggVorbis_File[1]'
	-- TODO put this in ffi.vorbis.vorbisfile along with the other static-init stuff
	local OV_CALLBACKS_NOCLOSE = ffi.new'ov_callbacks'
	OV_CALLBACKS_NOCLOSE.read_func = ffi.C.fread
	--[[ who puts a function as a static in a header anyways?
	OV_CALLBACKS_NOCLOSE.seek_func = ffi.C._ov_header_fseek_wrap
	--]]
	-- [[
	-- i'd free the closure but meh
	OV_CALLBACKS_NOCLOSE.seek_func = ffi.cast('int (*)(void *, ogg_int64_t, int)', function(f,off,whence)
		if f == nil then return -1 end
		return ffi.C.fseek(f,off,whence)
	end)
	--]]
	OV_CALLBACKS_NOCLOSE.close_func = nil
	OV_CALLBACKS_NOCLOSE.tell_func = ffi.C.ftell
	if vorbisfile.ov_open_callbacks(fp, vf, nil, 0, OV_CALLBACKS_NOCLOSE) < 0 then
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
