local music = require("musicutil")
local mod = require 'core/mods'
local status, matrix = pcall(require, 'matrix/lib/matrix')
if not status then
    matrix = nil
end

local models = {"classic analog", "waveshaping", "fm", "formant", "harmonic", "wavetable", "chord", "speech", "swarm", "noise", "particle", "string", "modal", "kick", "snare", "hat"}

local style_opts = {"perc", "poly", "mono"}

local scale = music.generate_scale(12, "Major", 8)

local plaits_note = {}

local scale_names = {}
for i = 1, #music.SCALES do
  table.insert(scale_names, music.SCALES[i].name)
end

local function n(i, s)
    return "plaits_"..s.."_"..i
end

local function add_plaits_params(i)
    params:add_group(n("group", i), "emplait voice "..i, 22)
    params:hide(n("group", i))
    params:add_option(n(i, "style"), "style", style_opts, 1)
    params:set_action(n(i, "style"), function(s)
        if s == 1 then
            params:show(n(i, "trigger"))
            params:hide(n(i, "gate"))
            params:hide(n(i, "a"))
            params:hide(n(i, "d"))
            params:hide(n(i, "s"))
            params:hide(n(i, "r"))
            params:show(n(i, "decay"))
        elseif s == 2 or s == 3 then
            params:hide(n(i, "trigger"))
            params:show(n(i, "gate"))
            params:show(n(i, "a"))
            params:show(n(i, "d"))
            params:show(n(i, "s"))
            params:show(n(i, "r"))
            params:hide(n(i, "decay"))
        end
        if s == 3 then
            params:show(n(i, "slew"))
        else
            params:hide(n(i, "slew"))
        end
        _menu.rebuild_params()
        osc.send({"localhost", 57120}, "/emplaitress/stop_all", {})
    end)
    if matrix then
        matrix:defer_bang(n(i, "style"))
    end
    params:add_trigger(n(i, "trigger"), "trigger")
    params:add_binary(n(i, "gate"), "gate", "momentary", 0)
    params:add_number(n(i, "note"), "note", 12, 127, 36, function(p)
        return music.note_num_to_name(p:get(), true)
    end)

    params:add_option(n(i, "model"), "model", models, 14)
    params:add_control(n(i, "decay"), "decay", controlspec.new(0, 1, "lin", 0, 0.5))
    params:add_control(n(i, "a"), "attack", controlspec.new(0.01, 5, "exp", 0, 0.05))
    params:add_control(n(i, "d"), "decay", controlspec.new(0.05, 5, "exp", 0, 0.5))
    params:add_control(n(i, "s"), "sustain", controlspec.new(0, 1, "lin", 0, 0.5))
    params:add_control(n(i, "r"), "release", controlspec.new(0.01, 5, "exp", 0, 0.5))

    params:add_control(n(i, "harmonics"), "harmonics", controlspec.new(0, 1, "lin", 0, 0.3))
    params:add_control(n(i, "timbre"), "timbre", controlspec.new(0, 1, "lin", 0, 0.3))
    params:add_control(n(i, "morph"), "morph", controlspec.new(0, 1, "lin", 0, 0.3))
    params:add_control(n(i, "amp"), "amp", controlspec.new(0, 1, "lin", 0, 0.2))
    params:add_control(n(i, "aux"), "aux mix", controlspec.new(0, 1, "lin", 0, 0))

    params:add_control(n(i, "fm_mod"), "fm env", controlspec.new(0, 1, "lin", 0, 0))
    params:add_control(n(i, "timb_mod"), "timbre env", controlspec.new(0, 1, "lin", 0, 0))
    params:add_control(n(i, "morph_mod"), "morph env", controlspec.new(0, 1, "lin", 0, 0))
    params:add_control(n(i, "lpg_color"), "lpg color", controlspec.new(0, 1, "lin", 0, 0.5))
    params:add_control(n(i, "gain"), "gain", controlspec.new(0, 3, "lin", 0, 1))
    params:add_control(n(i, "pan"), "pan", controlspec.new(-1, 1, "lin", 0, 0))
    params:add_control(n(i, "slew"), "slew", controlspec.new(0, 1, "lin", 0, 0))



    params:set_action(n(i, "trigger"), function ()
        local hz = music.note_num_to_freq(params:get(n(i, "note")))
        osc.send({"localhost", 57120}, "/emplaitress/perc", {
            music.freq_to_note_num(hz), --pitch
            params:get(n(i, "model")) - 1, --engine
            params:get(n(i, "harmonics")), --harm
            params:get(n(i, "timbre")), --timbre
            params:get(n(i, "morph")), --morph
            params:get(n(i, "fm_mod")), --fm_mod
            params:get(n(i, "timb_mod")), -- timb mod
            params:get(n(i, "morph_mod")), --morph mod
            params:get(n(i, "decay")), --decay
            params:get(n(i, "lpg_color")), --lpg_color
            params:get(n(i, "amp")), --mul
            params:get(n(i, "aux")), --aux_mix
            params:get(n(i, "gain")), -- post-plaits gain
            params:get(n(i, "pan")) -- pan
        })
    end)
    params:set_action(n(i, "gate"), function (g)
        local hz = music.note_num_to_freq(params:get(n(i, "note")))
        if g > 0 then
            if plaits_note[i] then
                osc.send({"localhost", 57120}, "/emplaitress/note_off", {
                    i - 1,
                    plaits_note[i],
                });
            end
            plaits_note[i] = params:get(n(i, "note"))
            osc.send({"localhost", 57120}, "/emplaitress/note_on", {
                i - 1, -- voice
                params:get(n(i, "note")), -- note
                music.freq_to_note_num(hz), --pitch
                params:get(n(i, "model")) - 1, --engine
                params:get(n(i, "harmonics")), --harm
                params:get(n(i, "timbre")), --timbre
                params:get(n(i, "morph")), --morph
                params:get(n(i, "fm_mod")), --fm_mod
                params:get(n(i, "timb_mod")), -- timb mod
                params:get(n(i, "morph_mod")), --morph mod
                params:get(n(i, "a")),
                params:get(n(i, "d")), --decay
                params:get(n(i, "s")),
                params:get(n(i, "r")),
                params:get(n(i, "lpg_color")), --lpg_color
                params:get(n(i, "amp")), --mul
                params:get(n(i, "aux")), --aux_mix
                params:get(n(i, "gain")), -- post-plaits gain
                params:get(n(i, "pan")) -- pan
            })
        else
            -- off
            if plaits_note[i] then
                osc.send({"localhost", 57120}, "/emplaitress/note_off", {
                    i - 1,
                    plaits_note[i],
                });
            end
        end
    end)
end


function add_plaits_player(i)
    local player = {
        timbre_modulation=0,
    }

    function player:active()
        if self.name ~= nil then
            params:show(n("group", i))
            _menu.rebuild_params()
        end
    end

    function player:inactive()
        if self.name ~= nil then
            params:hide(n("group", i))
            _menu.rebuild_params()
        end
    end

    function player:stop_all()
        osc.send({"localhost", 57120}, "/emplaitress/stop_all", {})
    end

    function player:modulate(val)
        self.timbre_modulation = val
    end

    function player:set_slew(s)
        params:set(n(i, "slew"), s)
    end

    function player:describe()
        return {
            name = "emplait "..i,
            supports_bend = false,
            supports_slew = (params:get(n(i, "style")) == 3),
            modulate_description = "timbre",
        }
    end

    function player:note_on(note, vel)
        if params:get(n(i, "style")) == 1 then
            osc.send({"localhost", 57120}, "/emplaitress/perc", {
                music.freq_to_note_num(music.note_num_to_freq(note)), --pitch. Round trip through music lib for tuning mod support.
                params:get(n(i, "model")) - 1, --engine
                params:get(n(i, "harmonics")), --harm
                params:get(n(i, "timbre")) + self.timbre_modulation/2, --timbre
                params:get(n(i, "morph")), --morph
                params:get(n(i, "fm_mod")), --fm_mod
                params:get(n(i, "timb_mod")), -- timb mod
                params:get(n(i, "morph_mod")), --morph mod
                params:get(n(i, "decay")), --decay
                params:get(n(i, "lpg_color")), --lpg_color
                params:get(n(i, "amp"))*vel*vel, --mul
                params:get(n(i, "aux")), --aux_mix
                params:get(n(i, "gain")), -- post-plaits gain
                params:get(n(i, "pan")) -- pan
            })
        elseif params:get(n(i, "style")) == 2 then
            osc.send({"localhost", 57120}, "/emplaitress/note_on", {
                i - 1,
                note,
                music.freq_to_note_num(music.note_num_to_freq(note)), --pitch. Round trip through music lib for tuning mod support.
                params:get(n(i, "model")) - 1, --engine
                params:get(n(i, "harmonics")), --harm
                params:get(n(i, "timbre")) + self.timbre_modulation/2, --timbre
                params:get(n(i, "morph")), --morph
                params:get(n(i, "fm_mod")), --fm_mod
                params:get(n(i, "timb_mod")), -- timb mod
                params:get(n(i, "morph_mod")), --morph mod
                params:get(n(i, "a")), --attack
                params:get(n(i, "d")), --decay
                params:get(n(i, "s")), --sustain
                params:get(n(i, "r")), --release                
                params:get(n(i, "lpg_color")), --lpg_color
                params:get(n(i, "amp"))*vel*vel, --mul
                params:get(n(i, "aux")), --aux_mix
                params:get(n(i, "gain")), -- post-plaits gain
                params:get(n(i, "pan")) -- pan
            })
        elseif params:get(n(i, "style")) == 3 then
            if self.current_note then
                osc.send({"localhost", 57120}, "/emplaitress/note_mod", {
                    i - 1,
                    self.current_note,
                    note,
                    music.freq_to_note_num(music.note_num_to_freq(note)), --pitch. Round trip through music lib for tuning mod support.
                    params:get(n(i, "model")) - 1, --engine
                    params:get(n(i, "harmonics")), --harm
                    params:get(n(i, "timbre")) + self.timbre_modulation/2, --timbre
                    params:get(n(i, "morph")), --morph
                    params:get(n(i, "fm_mod")), --fm_mod
                    params:get(n(i, "timb_mod")), -- timb mod
                    params:get(n(i, "morph_mod")), --morph mod
                    params:get(n(i, "a")), --attack
                    params:get(n(i, "d")), --decay
                    params:get(n(i, "s")), --sustain
                    params:get(n(i, "r")), --release                
                    params:get(n(i, "lpg_color")), --lpg_color
                    params:get(n(i, "amp"))*vel*vel, --mul
                    params:get(n(i, "aux")), --aux_mix
                    params:get(n(i, "gain")), -- post-plaits gain
                    params:get(n(i, "pan")), -- pan
                    params:get(n(i, "slew")) -- pitch_lag
                })
                self.current_note = note
            else
                osc.send({"localhost", 57120}, "/emplaitress/note_on", {
                    i - 1,
                    note,
                    music.freq_to_note_num(music.note_num_to_freq(note)), --pitch. Round trip through music lib for tuning mod support.
                    params:get(n(i, "model")) - 1, --engine
                    params:get(n(i, "harmonics")), --harm
                    params:get(n(i, "timbre")) + self.timbre_modulation/2, --timbre
                    params:get(n(i, "morph")), --morph
                    params:get(n(i, "fm_mod")), --fm_mod
                    params:get(n(i, "timb_mod")), -- timb mod
                    params:get(n(i, "morph_mod")), --morph mod
                    params:get(n(i, "a")), --attack
                    params:get(n(i, "d")), --decay
                    params:get(n(i, "s")), --sustain
                    params:get(n(i, "r")), --release                
                    params:get(n(i, "lpg_color")), --lpg_color
                    params:get(n(i, "amp"))*vel*vel, --mul
                    params:get(n(i, "aux")), --aux_mix
                    params:get(n(i, "gain")), -- post-plaits gain
                    params:get(n(i, "pan")), -- pan
                    params:get(n(i, "slew")) -- pitch_lag
                })
                self.current_note = note
            end
        end
    end

    function player:note_off(note)
        -- pass, for perc.
        osc.send({"localhost", 57120}, "/emplaitress/note_off", {i - 1, note});
    end

    function player:add_params()
        add_plaits_params(i)
    end

    if note_players == nil then
        note_players = {}
    end
    note_players["emplait "..i] = player
end

function pre_init()
    for v=1,4 do
        add_plaits_player(v)
    end
end

mod.hook.register("script_pre_init", "emplaitress pre init", pre_init)

mod.hook.register("system_post_startup", "emplaitress post startup", function()
    local has_mi = os.execute('test -n "$(find /home/we/.local/share/SuperCollider/Extensions/ -name MiPlaits.sc)"')
    if not has_mi then
      print("emplaitress: installing mi-UGens")
      os.execute("wget --quiet https://github.com/schollz/oomph/releases/download/prereqs/mi-UGens.762548fd3d1fcf30e61a3176c1b764ec1cc82020.tar.gz -P /tmp/")
      os.execute("tar -xvzf /tmp/mi-UGens.762548fd3d1fcf30e61a3176c1b764ec1cc82020.tar.gz -C /home/we/.local/share/SuperCollider/Extensions/")
      os.execute("rm /tmp/mi-UGens.762548fd3d1fcf30e61a3176c1b764ec1cc82020.tar.gz")
      print("PLEASE RESTART")
    else
        print("emplaitress found mi ugens")
    end
end)
