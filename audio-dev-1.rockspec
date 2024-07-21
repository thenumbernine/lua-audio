package = "audio"
version = "dev-1"
source = {
	url = "git+https://github.com/thenumbernine/lua-audio"
}
description = {
	summary = "LuaJIT audio OOP classes.",
	detailed = "LuaJIT audio OOP classes.",
	homepage = "https://github.com/thenumbernine/lua-audio",
	license = "MIT"
}
dependencies = {
	"lua >= 5.1",
}
build = {
	type = "builtin",
	modules = {
		["audio"] = "audio.lua",
		["audio.buffer"] = "buffer.lua",
		["audio.currentsystem"] = "currentsystem.lua",
		["audio.null.audio"] = "null/audio.lua",
		["audio.null.buffer"] = "null/buffer.lua",
		["audio.null.source"] = "null/source.lua",
		["audio.openal.audio"] = "openal/audio.lua",
		["audio.openal.buffer"] = "openal/buffer.lua",
		["audio.openal.ogg"] = "openal/ogg.lua",
		["audio.openal.source"] = "openal/source.lua",
		["audio.openal.wav"] = "openal/wav.lua",
		["audio.sdl_mixer.audio"] = "sdl_mixer/audio.lua",
		["audio.sdl_mixer.buffer"] = "sdl_mixer/buffer.lua",
		["audio.sdl_mixer.source"] = "sdl_mixer/source.lua",
		["audio.source"] = "source.lua"
	}
}
