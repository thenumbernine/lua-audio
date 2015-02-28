local class = require 'ext.class'

local Audio = class()
function Audio:shutdown() end
function Audio:getMaxSources() return 1 end
function Audio:setDistanceModel() end
return Audio
