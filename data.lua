-- data.lua
data:extend{
    {
        type="sprite",
        name="findmycar-sprite",
        filename="__base__/graphics/icons/car.png",
        priority="extra-high-no-scale",
        width=32,
        height=32,
        scale=1,
    },
    {
        type="custom-input",
        name="findmycar-toggle-gui",
        key_sequence="CONTROL + SHIFT + C",
        consuming="all"
    },
    {
        type="custom-input",
        name="findmycar-toggle-button",
        key_sequence="CONTROL + SHIFT + ALT + C",
        consuming="all"
    }
}

data.raw["gui-style"].default.small_spacing_scroll_pane_style = {
    type="scroll_pane_style",
    parent="scroll_pane_style",
    top_padding=5,
    left_padding=5,
    right_padding=5,
    bottom_padding=5,
    flow_style={"slot_table_spacing_flow_style"}
}
