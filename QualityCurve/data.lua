
function getPlusIcon(name, tint)
return
{
	icon = "__QualityCurve__/icons/" .. name .. ".png",
	tint = tint
}
end

local nextProbability = 0.2

local normal = data.raw.quality.normal
normal.next_probability = nextProbability

local uncommon = data.raw.quality.uncommon
uncommon.next = "uncommon-plus-1"
uncommon.next_probability = nextProbability

data:extend(
{
    {
		type = "quality",
		name = "uncommon-plus-1",
		level = 1,
		color = {43, 165, 61},
		order = "ba",
		next = "rare",
		next_probability = nextProbability,
		subgroup = "qualities",
		icons =
		{
			{
				icon = "__quality__/graphics/icons/quality-uncommon.png",
			},
			getPlusIcon("plus-1",{62, 236, 87, 255}),
		},
		beacon_power_usage_multiplier = 5/6,
		mining_drill_resource_drain_multiplier = 5/6,
		science_pack_drain_multiplier = 99/100,
    }
}
)

local rare = data.raw.quality.rare
rare.next = "rare-plus-1"
rare.next_probability = nextProbability

data:extend(
{
    {
		type = "quality",
		name = "rare-plus-1",
		level = 2,
		color = {25, 104, 178},
		order = "ca",
		next = "rare-plus-2",
		next_probability = nextProbability,
		subgroup = "qualities",
		icons =
		{
			{
				icon = "__quality__/graphics/icons/quality-rare.png",
			},
			getPlusIcon("plus-1",{36, 149, 255, 255}),
		},
		beacon_power_usage_multiplier = 4/6,
		mining_drill_resource_drain_multiplier = 4/6,
		science_pack_drain_multiplier = 98/100,
    }
}
)
data:extend(
{
    {
		type = "quality",
		name = "rare-plus-2",
		level = 2,
		color = {25, 104, 178},
		order = "ca",
		next = "epic",
		next_probability = nextProbability,
		subgroup = "qualities",
		icons =
		{
			{
				icon = "__quality__/graphics/icons/quality-rare.png",
			},
			getPlusIcon("plus-2",{36, 149, 255, 255}),
		},
		beacon_power_usage_multiplier = 4/6,
		mining_drill_resource_drain_multiplier = 4/6,
		science_pack_drain_multiplier = 98/100,
    }
}
)

local epic = data.raw.quality.epic
epic.next = "epic-plus-1"
epic.next_probability = nextProbability

data:extend(
{
    {
		type = "quality",
		name = "epic-plus-1",
		level = 3,
		color = {137, 0, 178},
		order = "da",
		next = "epic-plus-2",
		next_probability = nextProbability,
		subgroup = "qualities",
		icons =
		{
			{
				icon = "__quality__/graphics/icons/quality-epic.png",
			},
			getPlusIcon("plus-1",{196, 0, 255, 255}),
		},
		beacon_power_usage_multiplier = 3/6,
		mining_drill_resource_drain_multiplier = 3/6,
		science_pack_drain_multiplier = 97/100,
    }
}
)

data:extend(
{
    {
		type = "quality",
		name = "epic-plus-2",
		level = 3,
		color = {137, 0, 178},
		order = "da",
		next = "epic-plus-3",
		next_probability = nextProbability,
		subgroup = "qualities",
		icons =
		{
			{
				icon = "__quality__/graphics/icons/quality-epic.png",
			},
			getPlusIcon("plus-2",{196, 0, 255, 255}),
		},
		beacon_power_usage_multiplier = 3/6,
		mining_drill_resource_drain_multiplier = 3/6,
		science_pack_drain_multiplier = 97/100,
    }
}
)

data:extend(
{
    {
		type = "quality",
		name = "epic-plus-3",
		level = 3,
		color = {137, 0, 178},
		order = "da",
		next = "legendary",
		next_probability = nextProbability,
		subgroup = "qualities",
		icons =
		{
			{
				icon = "__quality__/graphics/icons/quality-epic.png",
			},
			getPlusIcon("plus-3",{196, 0, 255, 255}),
		},
		beacon_power_usage_multiplier = 3/6,
		mining_drill_resource_drain_multiplier = 3/6,
		science_pack_drain_multiplier = 97/100,
    }
}
)

local qualityModuleTech = data.raw.technology["quality-module"]
for _, effect in pairs(qualityModuleTech.effects) do
	if effect.quality == "rare" then
		effect.quality = "uncommon-plus-1"
	end
end
table.insert(qualityModuleTech.effects,
{
	type = "unlock-quality",
	quality = "rare"
}
)

local epicTech = data.raw.technology["epic-quality"]
for _, effect in pairs(epicTech.effects) do
	if effect.quality == "epic" then
		effect.quality = "rare-plus-1"
	end
end
table.insert(epicTech.effects,
{
	type = "unlock-quality",
	quality = "rare-plus-2"
}
   )
table.insert(epicTech.effects,
{
	type = "unlock-quality",
	quality = "epic"
}
)

local legendaryTech = data.raw.technology["legendary-quality"]
for _, effect in pairs(legendaryTech.effects) do
	if effect.quality == "legendary" then
		effect.quality = "epic-plus-1"
	end
end
table.insert(legendaryTech.effects,
{
	type = "unlock-quality",
	quality = "epic-plus-2"
}
)
table.insert(legendaryTech.effects,
{
	type = "unlock-quality",
	quality = "epic-plus-3"
}
)
table.insert(legendaryTech.effects,
{
	type = "unlock-quality",
	quality = "legendary"
}
)
