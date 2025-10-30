--
-- Control Logic
--

--Functions
function unlock_all()
  for iterator, quality in pairs(prototypes.quality) do
    game.forces["player"].unlock_quality(quality.name)
  end
end

-- Settings
local unlockAll = settings.startup["quality-curve-unlock-all"].value 

-- Scripting
if unlockAll then
  script.on_init(function() unlock_all() end)
  script.on_configuration_changed(function() unlock_all() end)
end
