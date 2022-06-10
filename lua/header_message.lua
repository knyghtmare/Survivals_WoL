local header_message = {valid = false}
local header_text = ""
function wesnoth.wml_actions.header_message(cfg)
    if header_message.valid then
        header_message:remove()
    end
    if cfg.message and not cfg.remove then
        header_text = cfg.message
        if cfg.caption and cfg.caption ~= "" then
            header_text = "<b><big>" .. cfg.caption .. "</big></b>\n" .. header_text
        end
        header_message = wesnoth.interface.add_overlay_text(header_text, {
            size = 18,
            location = {5,5},
            color = {255, 255, 255},
            duration = "unlimited",
            max_width = "40%",
            valign = "top",
            halign = "center"
        })
    end
end

wesnoth.persistent_tags.header_message.read = wesnoth.wml_actions.header_message

function wesnoth.persistent_tags.header_message.write(add)
    add{message = header_text}
end