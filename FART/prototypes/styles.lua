data:extend(
    {
        {
            type = "font",
            name = "fart-small",
            from = "default",
            size = 13
        },
        {
            type ="font",
            name = "fart-small-bold",
            from = "default-bold",
            size = 13
        }
    }
)

data.raw["gui-style"].default["fart_label"] =
    {
        type = "label_style",
        font = "fart-small",
        font_color = {r=1, g=1, b=1},
        top_padding = 0,
        bottom_padding = 0
    }

data.raw["gui-style"].default["fart_textfield"] =
    {
        type = "textbox_style",
        left_padding = 3,
        right_padding = 2,
        minimal_width = 60,
        font = "fart-small"
    }

data.raw["gui-style"].default["fart_textfield_small"] =
    {
        type = "textbox_style",
        left_padding = 3,
        right_padding = 2,
        minimal_width = 30,
        font = "fart-small"
    }
data.raw["gui-style"].default["fart_button"] =
    {
        type = "button_style",
        parent = "button",
        font = "fart-small-bold",
        minimal_height = 33,
        minimal_width = 33,
    }
data.raw["gui-style"].default["fart_checkbox"] =
    {
        type = "checkbox_style",
        parent = "checkbox",
        font = "fart-small",
    }

data:extend({
    {
        type="sprite",
        name="fart_settings",
        filename = "__FART__/graphics/icons/settings.png",
        priority = "extra-high",
        width = 64,
        height = 64,
        scale = 0.5
    },
})
