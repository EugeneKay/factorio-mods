--Settings
data:extend{
    {
        type = "int-setting",
        name = "quality-curve-max-jump",
        setting_type = "startup",
        default_value = 10,
        minimum_value = 1,
        maximum_value = 255,
        order = "a"
    },
        {
        type = "int-setting",
        name = "quality-curve-next-probability",
        setting_type = "startup",
        default_value = 20,
        minimum_value = 0,
        maximum_value = 100,
        order = "b"
    },
    {
        type = "bool-setting",
        name = "quality-curve-unlock-all",
        setting_type = "startup",
        default_value = true,
        order = "c"
    }
}
