local class = require 'ext.class'

local AudioSource = class()
function AudioSource:setReferenceDistance() end
function AudioSource:setMaxDistance() end
function AudioSource:setRolloffFactor() end
function AudioSource:setBuffer(buffer) return self end
function AudioSource:setLooping(looping) end
function AudioSource:setGain(gain) end
function AudioSource:setPitch(pitch) end
function AudioSource:isPlaying() return false end
function AudioSource:setPosition() end
function AudioSource:setVelocity() end
function AudioSource:play() end
function AudioSource:stop() end
return AudioSource
