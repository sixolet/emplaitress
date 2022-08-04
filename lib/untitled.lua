local music = require("musicutil")

local models = {"classic analog", "waveshaping", "fm", "formant", "harmonic", "wavetable", "chord", "speech", "swarm", "noise", "particle", "string", "modal", "kick", "snare", "hat"}

local scale

local scale_names = {}
for i = 1, #music.SCALES do
  table.insert(scale_names, music.SCALES[i].name)
end


local function n(i, s)
    return "plaits_"..s.."_"..i
end

function add_plaits(i)
    params:add_group("plaits "..i, 11)
    params:add_trigger(n(i, "trigger"), "trigger")
    params:add_number(n(i, "note"), "note", 12, 127, 36, function(p)
        local snapped = music.snap_note_to_array(p:get(), scale)
        return music.note_num_to_name(snapped, true)
    end)

    params:add_option(n(i, "model"), "model", models, 14)
    params:add_control(n(i, "decay"), "decay", controlspec.new(0, 1, "lin", 0, 0.5))
    params:add_control(n(i, "harmonics"), "harmonics", controlspec.new(0, 1, "lin", 0, 0.3))
    params:add_control(n(i, "timbre"), "timbre", controlspec.new(0, 1, "lin", 0, 0.3))
    params:add_control(n(i, "morph"), "morph", controlspec.new(0, 1, "lin", 0, 0.3))
    params:add_control(n(i, "amp"), "amp", controlspec.new(0, 1, "lin", 0, 0.2))
    params:add_control(n(i, "aux"), "aux mix", controlspec.new(0, 1, "lin", 0, 0))
    
    params:add_control(n(i, "fm_mod"), "fm env", controlspec.new(0, 1, "lin", 0, 0))
    -- params:add_control(n(i, "timb_mod"), "timbre env", controlspec.new(0, 1, "lin", 0, 0))
    -- params:add_control(n(i, "morph_mod"), "morph env", controlspec.new(0, 1, "lin", 0, 0))
    params:add_control(n(i, "lpg_color"), "lpg color", controlspec.new(0, 1, "lin", 0, 0.5))
    
    
    
    params:set_action(n(i, "trigger"), function ()
        local hz = music.note_num_to_freq(music.snap_note_to_array(params:get(n(i, "note")), scale))
        osc.send({"localhost", 57120}, "/emplaitress/perc", {
            music.freq_to_note_num(hz), --pitch
            params:get(n(i, "model")) - 1, --engine
            params:get(n(i, "harmonics")), --harm
            params:get(n(i, "timbre")), --timbre
            params:get(n(i, "morph")), --morph
            params:get(n(i, "fm_mod")), --fm_mod
            0, -- params:get(n(i, "timb_mod")), -- timb mod
            0, -- params:get(n(i, "morph_mod")), --morph mod
            params:get(n(i, "decay")), --decay
            params:get(n(i, "lpg_color")), --lpg_color
            params:get(n(i, "amp")), --mul
            params:get(n(i, "aux")) --aux_mix
        })
    end)
end


function init()
    params:add_number("plaits_root", "root", 1, 12, 12, function(p)
        return music.note_num_to_name(p:get())
    end)
    params:add_option("plaits_scale", "scale", scale_names, 1)
    params:set_action("plaits_scale", function ()
        local s = scale_names[params:get("plaits_scale")]
        scale = music.generate_scale(params:get("plaits_root"), s, 8)
    end)
    params:set_action("plaits_root", function ()
        local s = scale_names[params:get("plaits_scale")]
        scale = music.generate_scale(params:get("plaits_root"), s, 8)
    end)    
    add_plaits(1)
    params:bang()
    
end