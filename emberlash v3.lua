function start(...) 
    return ...
end

local js = panorama.open()
local vector = require("vector")
local pui = require("gamesense/pui")
local clipboard = require("gamesense/clipboard")
local ent = require("gamesense/entity")
local aa_funcs = require("gamesense/antiaim_funcs")
local images = require('gamesense/images')
local base64 = require('gamesense/base64')
local ffi = require("ffi")

local menu = {}
local user_lua = js.MyPersonaAPI.GetName()

local r, g, b = 255,255,255
local r1, g1, b1 = 0,0,0
local r2, g2, b2 = 0,0,0
local r3,g3,b3 = 0,0,0
local x, y = client.screen_size()

start(function()
    client.open_link = panorama.open().SteamOverlayAPI.OpenExternalBrowserURL

    math.random_string = function(...)
        local args = {...}
        if #args == 1 and type(args[1]) == "table" then
            args = args[1]
        end
        return args[math.random(1, #args)]
    end

    math.round = function(value)
		return math.floor(value + 0.5)
	end

    math.clamp = function(value, minimum, maximum)
        if minimum > maximum then 
            minimum, maximum = maximum, minimum 
        end

        return math.max(minimum, math.min(maximum, value))
    end

    math.to_hex = function(r, g, b, a)
        return bit.tohex((math.floor((r or 0) + 0.5) * 16777216) + (math.floor((g or 0) + 0.5) * 65536) + (math.floor((b or 0) + 0.5) * 256) +(math.floor((a or 0) + 0.5)))
    end

    client.ping = math.floor(client.latency() * 1000)

    string.split = function(input, sep)
        local result = {}
        for str in input:gmatch("([^" .. sep .. "]+)") do
            table.insert(result, str)
        end
        return result
    end

    string.upper_first = function(input)
        return input:sub(1, 1):upper() .. input:sub(2)
    end

    string.add_string = function(tbl, to_add, upp)
        local result = {}
        for i, v in ipairs(tbl) do
            if upp then
                result[i] = to_add .. v:upper_first()
            else
                result[i] = to_add .. v
            end
        end
        return result
    end

    string.del_string = function(str, prefix, low)
        local result = str:gsub("^" .. prefix, "")
        if low then
            result = result:lower()
        end
        return result
    end

    string.delete = function(str, count)
        return str:sub(count + 1)
    end  

    entity.get_max_desync = function(ent)
		local ways = math.clamp(ent.feet_speed_forwards_or_sideways, 0, 1)
		local frac = (ent.stop_to_full_running_fraction * -0.3 - 0.2) * ways + 1
		local ducking = ent.duck_amount

		if ducking > 0 then
			frac = frac + ducking * ways * (0.5 - frac)
		end

		return math.clamp(frac, 0.5, 1)
	end

    local animstates = ffi.typeof("struct { char pad0[0x18]; float anim_update_timer; char pad1[0xC]; float started_moving_time; float last_move_time; char pad2[0x10]; float last_lby_time; char pad3[0x8]; float run_amount; char pad4[0x10]; void* entity; void* active_weapon; void* last_active_weapon; float last_client_side_animation_update_time; int\t last_client_side_animation_update_framecount; float eye_timer; float eye_angles_y; float eye_angles_x; float goal_feet_yaw; float current_feet_yaw; float torso_yaw; float last_move_yaw; float lean_amount; char pad5[0x4]; float feet_cycle; float feet_yaw_rate; char pad6[0x4]; float duck_amount; float landing_duck_amount; char pad7[0x4]; float current_origin[3]; float last_origin[3]; float velocity_x; float velocity_y; char pad8[0x4]; float unknown_float1; char pad9[0x8]; float unknown_float2; float unknown_float3; float unknown; float m_velocity; float jump_fall_velocity; float clamped_velocity; float feet_speed_forwards_or_sideways; float feet_speed_unknown_forwards_or_sideways; float last_time_started_moving; float last_time_stopped_moving; bool on_ground; bool hit_in_ground_animation; char pad10[0x4]; float time_since_in_air; float last_origin_z; float head_from_ground_distance_standing; float stop_to_full_running_fraction; char pad11[0x4]; float magic_fraction; char pad12[0x3C]; float world_force; char pad13[0x1CA]; float min_yaw; float max_yaw; } **")
	local animlayers = ffi.typeof("struct { char pad_0x0000[0x18]; uint32_t sequence; float prev_cycle; float weight; float weight_delta_rate; float playback_rate; float cycle;void *entity;char pad_0x0038[0x4]; } **")
	local entity_list = vtable_bind("client.dll", "VClientEntityList003", 3, "void*(__thiscall*)(void*, int)")

    entity.get_animstate = function(ent)
        local active = ent and entity_list(ent)

		if active then
			return ffi.cast(animstates, ffi.cast("char*", ffi.cast("void***", active)) + 39264)[0]
		end
    end

    entity.get_animlayer = function(ent, layer)
        local active = entity_list(ent)

		if active then
			return ffi.cast(animlayers, ffi.cast("char*", ffi.cast("void***", active)) + 10640)[0][layer or 0]
		end
    end
end)()

local refs = {
	aa = {
		enabled = pui.reference("AA", "anti-aimbot angles", "enabled"),
		pitch = {pui.reference("AA", "anti-aimbot angles", "pitch")},
		yaw_base = {pui.reference("AA", "anti-aimbot angles", "Yaw base")},
		yaw = {pui.reference("AA", "anti-aimbot angles", "Yaw")},
		yaw_jitter = {pui.reference("AA", "anti-aimbot angles", "Yaw Jitter")},
		body_yaw = {pui.reference("AA", "anti-aimbot angles", "Body yaw")},
		body_free = {pui.reference("AA", "anti-aimbot angles", "Freestanding body yaw")},
		freestand = {pui.reference("AA", "anti-aimbot angles", "Freestanding")},
		roll = {pui.reference("AA", "anti-aimbot angles", "Roll")},
		edge_yaw = {pui.reference("AA", "anti-aimbot angles", "Edge yaw")},
		fake_peek = {pui.reference("AA", "other", "Fake peek")},
        osaa = {pui.reference("AA", "other", "On shot anti-aim")},
        fl = {
            enable = {pui.reference("AA", "fake lag", "enabled")},
            amount = {pui.reference("AA", "fake lag", "amount")},
            variance = {pui.reference("AA", "fake lag", "variance")},
            limit = {pui.reference("AA", "fake lag", "limit")},
            lg = {pui.reference("AA", "other", "Leg movement")},
            sw = {pui.reference("AA", "other", "Slow motion")}, 
        },
	},
    sw = {ui.reference("AA", "other", "Slow motion")},
    scope = ui.reference('VISUALS', 'Effects', 'Remove scope overlay'),
	rage = {
		enable = ui.reference('RAGE', 'aimbot', 'Enabled'),
        dt = {
            value = {ui.reference("RAGE", "aimbot", "Double tap")},
            fl = {pui.reference("RAGE", "Aimbot", "Double tap fake lag limit")}
        },
        md = {
            damage = {pui.reference('RAGE', 'aimbot', 'minimum damage')},
            ovr = {ui.reference('RAGE', 'aimbot', 'minimum damage override')},
        },

		faceduck = {ui.reference("RAGE", "other", "Duck peek assist")},
		peek = {ui.reference("RAGE", "other", "Quick peek assist")},
		baim = {ui.reference('RAGE', 'aimbot', 'force body aim')},
		safe = {ui.reference('RAGE', 'aimbot', 'force safe point')},
        osaa = {ui.reference("AA", "other", "On shot anti-aim")},
	},
    misc = {
        fov = ui.reference('misc', 'miscellaneous', 'Override FOV'),
        clantag = pui.reference("MISC", "Miscellaneous", "Clan tag spammer"),
        log_damage = pui.reference("MISC", "Miscellaneous", "Log damage dealt"),
        ping_spike = pui.reference("MISC", "Miscellaneous", "Ping spike"),
        bindfs = {ui.reference("aa", "anti-aimbot angles", "Freestanding")},
        settings = {
            maxshift = pui.reference("MISC", "Settings", "sv_maxusrcmdprocessticks2")
        }
    }
}

local name = "emberlash"

local databases = {
    version = "nightly",
    scope = 0,
    orig = {
        viewmodel = {
            fov = client.get_cvar("viewmodel_fov"),
            x = client.get_cvar("viewmodel_offset_x"),
            y = client.get_cvar("viewmodel_offset_y"),
            z = client.get_cvar("viewmodel_offset_z")
        }
    },

    cfg = "emberlash:cfg:db:",
    load = "emberlash:load:db:",
    kill = "emberlash:kill:db:",
    miss = "emberlash:miss:db:",
    init = function(self)
        if database.read(self.cfg) == nil then 
            database.write(self.cfg, {})
        end
    
        local loads = database.read(self.load)
        local kills = database.read(self.kill)
        local miss = database.read(self.miss)

        if loads == nil then loads = 1 end
        loads = loads + 1

        if kills == nil then kills = 0 end
        if miss == nil then miss = 0 end
        
        database.write(self.load, loads)
        database.write(self.kill, kills)
        database.write(self.miss, miss)
    end
}

databases:init()

local puiacc = "\a"..pui.accent
local conditions = {"global", "stand", "walking", "running", "crouch", "crouch-moving", "air", "air+", "manual-left", "manual-right", "on-peek", "fakelag", "hideshots"}
local helper_weapon = {"SSG-08", "Awp", "Auto"}

local gui = {
    show = function(self, visible)
        pui.traverse(refs.aa, function(ac)
            ac:set_visible(visible)
        end)
    end,
    header = function(self, tab) return tab:label("\a333333FF‾‾‾‾‾‾‾‾‾‾‾‾‾") end,
    space = function(self, tab) return tab:label("\n ") end,
    init = function(self) 
        local gaa = pui.group("AA", "anti-aimbot angles")
        local gfl = pui.group("AA", "Fake lag")
        local goh = pui.group("AA", "Other")

        pui.macros.d = "\a808080FF•\r  "
		pui.macros.gray = "\a505050FF"
        pui.macros.lgray = "\a909090FF"
		pui.macros.a = "\v"
        pui.macros.ab = "\v"
        pui.macros.red = "\aFF0000FF"
        pui.macros.dred = "\a700000FF"

        menu = {
            name = gaa:label("\f<a>Emberlash "..databases.version:upper_first().."\r ~ Source"),
            tab = gaa:combobox("\n tab-is", {" User Section", " Anti-aimbot angles", " Features"}),

            home = {
                tab_1 = gfl:label("\f<a>\f<gray>  •  "),
                tab = gfl:combobox("\ntab:home", " Information", " Visuals"),
                space = self:space(gfl),

                info = {
                    mephissa = gfl:label("\f<gray>The darkness."),
                    space = self:space(gfl),
                    welcome = gfl:label("\v\r  Welcome back, \vadmin!"),
                    build = gfl:label("\v \r Your build is \v"..databases.version:upper_first()),
                    killed = gfl:label("dadno3118"),
                    misses = gfl:label("verim."),
                    space1 = self:space(gfl),
                    textion = gfl:label("Feel the heat. That's \vEmberlash v2"),
                },
                config = {
                    space = self:space(gaa),
                    name = gaa:textbox("\nglasigh"),
                    create = gaa:button(" Create"),
                    import = gaa:button("Import From Clipboard"),
                    list = gaa:listbox("\nlocal-configs:list", {}),
                    save = gaa:button(" Save"),
                    load = gaa:button("\v\r Load"),
                    export = gaa:button("Export To Clipboard"),
                    delete = gaa:button("\f<dred> Delete"),

                    social = {
                        social_type = goh:slider("Our \vTeam\r Socials", 1, 2, 1, true, '', 1, {[1]=" Mephissa",[2]=" Reload"}),
                        yt = goh:button("\f<red>YouTube\r @релоад", function()
                            client.open_link("https://www.youtube.com/@reloadhvh")
                        end),
                        space_soc = self:space(goh),
                        dsc = goh:button("Our\v Discord\r Server"),
                    }
                }
            },
            aa = {
                tab_1 = gfl:label("шо сюда гляддишь?"),
                tab = gfl:combobox("\n tab:aa-is", " Builder", " Defensive", " Settings"),

                setting = {
                    tab = gfl:combobox("\nsubtub-builder", "Hotkeys", "Exploit", "Settings"),
                    space = self:space(gfl),
                    sett = {
                        select = gfl:multiselect("\nselect settings","Safe head", "Off defensive am l bowping", "Anti backstab", "Fast ladder", "Spin if enemies died", "E-Bombsite fix", "Spin on warmup"), 
                        safehead = gfl:multiselect("\nsafeheadtype","Knife", "Taser"),
                        body_type = gfl:combobox("\nbodytype","Defensive", "Offensive"),
                    },
                    exploit = {
                        vsnl = gfl:checkbox("\f<a>Secret\r exploit"),
                        deff = gfl:checkbox("Defensive \f<a>exploit\r"),
                    },
                    hotkey = { -- aa.setting.hotkey
                        manual_f = gfl:hotkey("Manual \f<a>•\r Forward"),
                        manual_l = gfl:hotkey("Manual \f<a>•\r Left"),
                        manual_r = gfl:hotkey("Manual \f<a>•\r Right"),
                        manual_reset = gfl:hotkey("Manual \f<a>•\r Reset"),
                        fs = gfl:checkbox("Freestanding", 0),
                        edge_yaw = gfl:checkbox("Edge yaw", 0),
                    },
                },
                builder = {
                    space = self:space(gaa),
                    cond = gaa:combobox("\f<a>\r    Player state", string.add_string(conditions, puiacc.."•\a999999ff  ", true)),
                    states = {
                        jitr = {},
                        defs = {},
                    },
                },
            },
            vis = {
                space = self:space(gaa),

                color = {
                    color_type = gfl:combobox("Color", "Default", "Gradient"),
                    style = gfl:combobox("\nstyle:hud", "Lilith", "Nightly"),
                    clr_def = gfl:color_picker("Default Color", 168, 133, 203),
                    gradient = {
                        clr1 = gfl:color_picker("\nFirst Color", 168, 133, 203),
                        clr2 = gfl:color_picker("\nSecond Color", 129, 115, 143),
                        clr3 = gfl:color_picker("\nThird Color", 66, 62, 69),
                        clr4 = gfl:color_picker("\nFourth Color", 50, 50, 50),
                    },
                },

                crosshair = gaa:checkbox("Crosshair"), cross = {
                    type = gaa:combobox("\ncrosshair:type", {"Simple", "Yaw-based"}),
                    flag = gaa:multiselect("\ncrosshair:flag", {"Condition", "Binds"})
                },
                arrows = gaa:checkbox("Arrows"), arrow = {
                    type = gaa:combobox("\narrows:type", {"Pointers", "Firmed"}),
                    sides = gaa:multiselect("\narrows:sides", {"Manuals", "Freestanding"})
                },
                custom_scope = gaa:checkbox("Scope"), scope = { -- zoom custom
                    color = gaa:color_picker("\nscope:clr", 255,255,255,255),
                    no_lines = gaa:multiselect("\nscope:lines", {"Left", "Right", "Up", "Bottom"}),
                    offset = gaa:slider("\nscope:offset", 0, 50, 5, true, "px", 1),
                    size = gaa:slider("\nscope:size", 0, 450, 100, true, "px", 1)
                },

                space1 = self:space(gaa),

                anim_zoom = gaa:checkbox("Zoom animation"), zoom = {
                    fov = gaa:slider("\nscope:fov", 0, 30, 0, true, "%+S", 1),
                    speed = gaa:slider("\nscope:speed", 10, 30, 0, true, "", 0.1),
                },
                ratio = gaa:checkbox("Aspect ratio"), 
                viewmodel = gaa:checkbox("Viewmodel"), view = {
                    fov = gaa:slider("\nview:fov", 0, 115, 68, true, "°", 1),
                    x = gaa:slider("\nview:x", -45, 45, 0, true, "u", 0.1),
                    y = gaa:slider("\nview:y", -45, 45, 0, true, "u", 0.1),
                    z = gaa:slider("\nview:z", -45, 45, 0, true, "u", 0.1),
                },

                damage = goh:checkbox("Damage indicator"), dmg = { -- damage_ind
                    type = goh:combobox("\ndmg:type", {"On damage", "Always on"}),
                    flag = goh:combobox("\ndmg:flag", {"Normal", "Small", "Bold"}),
                },
                markers = goh:checkbox("Markers"),
                markers_type = goh:multiselect("\nmarker:flag", {"On hit", "On miss", "Damage", "Preview"}),

                widgets = gfl:checkbox("Windows"),
                widgets_type = gfl:multiselect("\nwidgets", {"Force text watermark", "Watermark", "Keybinds", "Spectators", "Debug panel", "Multi panel", "LC Side indicator", "Event logger"}),
                glow = gfl:multiselect("Glow Disablers", "Event Logger"),
            },
            feature = {
                space = self:space(gaa),
                tab_1 = gfl:label("tab:misc-1"),
                tab = gfl:combobox("\ntab:misc", {" Aimbot", " Misc"}),
                space1 = self:space(gfl),

                aim = {
                    charge_fix = gaa:checkbox("Unsafe exploit recharge"),
                    auto_discharge = gaa:checkbox("Auto exploit discharge", 0),
                    resolver = gaa:checkbox("\vResolver"),
                    miss_fix = gaa:checkbox("Aim punch miss fix"),
                    auto_hs = gaa:checkbox("Auto hideshots"),
                    auto_qs = gaa:checkbox("Auto air stop"),

                    aim_hel = gfl:checkbox("Aimbot helper"), helper = {
                        current = gfl:combobox("\naim:weapon", helper_weapon), 
                        setts = gfl:multiselect("\naim:settings", {"Force safe point", "Prefer body aim", "Force body aim"}),
                        sett = {
                            fsafe = gfl:multiselect("\vForce safe point\r triggers", {"If hp < X", "Target lethal"}),
                            pbaim = gfl:multiselect("\vPrefer body aim\r triggers", {"If hp < X", "Target lethal"}),
                            fbaim = gfl:multiselect("\vForce body aim\r triggers", {"If hp < X", "Target lethal"}),
                        }
                    },

                    predict = goh:checkbox("Predict \venemies"),
                    game_ench = goh:checkbox("Game enhancer"),
                },
                misc = {
                    trashtalk = gaa:checkbox("Trashtalk"),
                    trashtalk_type = gaa:multiselect("\ntt:adds", {"On Kill","On Death"}),
                    clantag = gaa:checkbox("Clantag"),
                    filter = gaa:checkbox("Console filter"),
                    space = self:space(gaa),
                    breaker = gaa:checkbox("Animations legs"), breaker_help = {
                        type = gaa:combobox("\nanims:type", {"Off", "Static", "Moonwalk", "Jitter", "Earthquake"}),
                        adds = gaa:multiselect("\nanims:add", {"Pitch 0 on land", "Static in air", "Moonwalk+"})
                    },
                }
            }
        }

        local hydennn = {
            [menu.home] = {{menu.tab, " User Section"}},
            [menu.home.config] = {{menu.home.tab, " Visuals", true}},
            [menu.home.info] = {{menu.home.tab, " Information"}},
            [menu.vis.color] = {{menu.home.tab, " Visuals"}},
            [menu.vis.color.clr_def] = {{menu.vis.color.color_type, "Default"}},
            [menu.vis.color.gradient] = {{menu.vis.color.color_type, "Gradient"}},

            [menu.aa] = {{menu.tab, " Anti-aimbot angles"}},
            [menu.aa.setting] = {{menu.aa.tab, " Settings", true}},
            [menu.aa.setting.sett] = {{menu.aa.setting.tab, "Settings"}},
            [menu.aa.setting.exploit] = {{menu.aa.setting.tab, "Exploit"}},
            [menu.aa.setting.hotkey] = {{menu.aa.setting.tab, "Hotkeys"}},

            [menu.aa.builder.states.jitr] = {{menu.aa.tab, " Builder"}}, 
            [menu.aa.builder.states.defs] = {{menu.aa.tab, " Defensive"}}, 
            
            [menu.vis] = {{menu.tab, " User Section"}, {menu.home.tab, " Visuals"}},
            [menu.vis.cross] = {{menu.vis.crosshair, true}},
            [menu.vis.arrow] = {{menu.vis.arrows, true}},
            [menu.vis.scope] = {{menu.vis.custom_scope, true}},
            [menu.vis.zoom] = {{menu.vis.anim_zoom, true}},
            [menu.vis.view] = {{menu.vis.viewmodel, true}},
            [menu.vis.dmg] = {{menu.vis.damage, true}},
            [menu.vis.markers] = {{menu.vis.widgets, true}, {menu.vis.widgets_type, "Event logger"}},
            [menu.vis.markers_type] = {{menu.vis.markers, true}, {menu.vis.widgets, true}, {menu.vis.widgets_type, "Event logger"}},

            [menu.vis.widgets_type] = {{menu.vis.widgets, true}},
            
            [menu.feature] = {{menu.tab, " Features"}},
            [menu.feature.aim] = {{menu.feature.tab, " Aimbot"}},
            [menu.feature.misc] = {{menu.feature.tab, " Misc"}},
            [menu.feature.misc.trashtalk_type] = {{menu.feature.misc.trashtalk, true}},
            [menu.feature.misc.breaker_help] = {{menu.feature.misc.breaker, true}}
        }

        local tr = {
            delay = {[1] = "OFF"}
        }

        for _, state in ipairs(conditions) do
            menu.aa.builder.states.jitr[state] = {}
            menu.aa.builder.states.defs[state] = {}

            local aa = menu.aa.builder.states.jitr[state]
            local defaa = menu.aa.builder.states.defs[state]
            local c = "\n" .. state
            
            aa.space123 = self:space(gaa);defaa.space123 = self:space(gaa)

            if state ~= "global" then
                aa.active = gaa:checkbox("Enable  \f<ab>•\r  \f<lgray>" .. state:upper_first())
            end

            defaa.active = gaa:checkbox("\nenable"..c)
            defaa.activators = gaa:multiselect("\nactivators"..c, {"Double tap", "Hide shots"})
            defaa.trigger = gaa:multiselect("\ntrigger"..c, {"Always", "On weapon switch"})

            defaa.duration = goh:slider("\f<a>⯌\r    Duration"..c, 3, 18, 3, true, "t", 1, {[18] = "Maximum", [3] = "Lower", [10] = "Recom."})
            defaa.space13 = self:space(goh)
            defaa.pitch_min = goh:checkbox("Pitch \v•\r Min. - Max. mode"..c)
            defaa.pitch_based = goh:checkbox("Pitch \v•\r Height based value"..c)

            defaa.space = self:space(gaa)
            defaa.label = gaa:label("\f<a>⯁\r    Yaw")
            defaa.header = self:space(gaa)

            defaa.yaw = gaa:combobox("\ndefyaw"..c, {"Spin", "Static", "Random", "Sway", "Distortion", "Meta"})
            defaa.yaw_delay = gaa:slider("\ndefyaw:delay"..c, 1, 16, 4, true, "t", 1):depend({defaa.yaw, "Static", true})
            defaa.yaw_value = gaa:slider("\ndefyaw:value"..c, 0, 359, 359, true, "°", 1)
            defaa.yaw_update = gaa:slider("\ndefyaw:update"..c, 5, 70, 15, true, "u+", 1):depend({defaa.yaw, "Spin"})

            defaa.space1 = self:space(gaa)
            defaa.label1 = gaa:label("\f<a>\r    Pitch")
            defaa.header1 = self:space(gaa)

            defaa.pitch = gaa:combobox("\npitch"..c, {"Spin", "Static", "Random", "Sway", "Distortion"})
            defaa.pitch_delay = gaa:slider("\npitch:delay"..c, 1, 16, 2, true, "t", 1):depend({defaa.pitch, "Static", true})
            defaa.pitch_value = gaa:slider("\npitch:value"..c, -89, 89, 0, true, "°", 1)
            defaa.pitch_value_2 = gaa:slider("\npitch:value2"..c, -89, 89, 0, true, "°", 1):depend({defaa.pitch, "Static", true}, {defaa.pitch_min, true, true})

            defaa.space2 = self:space(gaa)
            defaa.label2 = gaa:label("\f<a>\r    Delay")
            defaa.header2 = self:space(gaa)

            defaa.delay = gaa:slider("\ndelay"..c, 1, 24, 1, true, "t", 1, tr.delay)
            defaa.delay_sp = self:space(gaa)
            defaa.delay_adds = gaa:combobox("\f<a>Delay »\r Add-ons"..c, {"-","Randomize Delay Ticks","Freeze-Inverter"})


            aa.yaw_base = goh:combobox("\n yaw-base"..c, {"At targets", "Local view"})
            aa.lryawsp = self:space(goh)
            aa.lryaw = goh:checkbox("Yaw \v»\r Left  Right mode"..c)

            aa.lyaw = gaa:slider("\n lyaw"..c, -90, 90, 0, true, "°", 1)
            aa.lyaw_random = gaa:slider("\n lyaw:random"..c, 0, 100, 0, true, "%", 1):depend({aa.lryaw, true})
            aa.ryaw = gaa:slider("\n ryaw"..c, -90, 90, 0, true, "°", 1):depend({aa.lryaw, true})
            aa.ryaw_random = gaa:slider("\n ryaw:random"..c, 0, 100, 0, true, "%", 1):depend({aa.lryaw, true})

            aa.space = self:space(gaa)
            aa.label = gaa:label("\f<a>\r    Yaw jitter")
            aa.header = self:space(gaa)

            aa.yaw = gaa:combobox("\n curr-jitter"..c, {"Off", "Offset", "Center", "Ground-Based", "X-way", "Random"})
            aa.way_value = gaa:slider("\nways:value"..c, 2, 5, 2, true, "-w", 1):depend({aa.yaw, "X-way"})

            for way = 1, 5 do 
                aa["way_"..way] = gaa:slider("\nway:value"..way..c, -145, 145, 0, true, "°", 1):depend({aa.yaw, "X-way"},{aa.way_value, way, 5})
            end

            aa.yaw_check = gaa:checkbox("\nyaw:check2"):depend({aa.yaw, "Off", true}, {aa.yaw, "X-way", true}, {aa.lryaw, true})
            aa.yaw_value = gaa:slider("\nyaw:value"..c, -145, 145, 0, true, "°", 1):depend({aa.yaw, "Off", true}, {aa.yaw, "X-way", true}, {aa.lryaw, true})
            aa.yaw_random = gaa:slider("Randomization"..c, 0, 100, 0, true, "%", 1):depend({aa.yaw, "Off", true}, {aa.yaw, "X-way", true})

            aa.space1 = self:space(gaa)
            aa.label1 = gaa:label("\f<a>\r    Body yaw")
            aa.header1 = self:space(gaa)

            aa.body_yaw = gaa:combobox("\n curr-bodyaw"..c, {"Off", "Opposite", "Static", "Jitter"})
            aa.body_value = gaa:slider("\nbody:value"..c, -60, 60, 0, true, "°", 1):depend({aa.body_yaw, "Off", true})
            aa.body_yaw_static = gaa:combobox("\n bodyyaw:static"..c, "Left", "Right"):depend({aa.body_yaw, "Static"})
            aa.body_yaw_freestand = gaa:checkbox("Freestanding body yaw"..c)

            aa.space2 = self:space(gaa)
            aa.label2 = gaa:label("\f<a>\r    Delay")
            aa.header2 = self:space(gaa)

            aa.delayCheck1 = gaa:checkbox("\ndelay:check1")
            aa.delay_value = gaa:slider("\n delay:value"..c, 1, 24, 1, true, "t", 0.1)
            aa.delayCheck2 = gaa:checkbox("\ndelay:check2")
            aa.delay_random = gaa:slider("\n delay:random"..c, 0, 16, 0, true, "t", 0.1)

            aa.delay_value_freze = gaa:slider("\n delay:value_freeze"..c, 1, 24, 2, true, "t", 1, tr.delay)
            aa.freeze_random = gaa:slider("\n delay:invert"..c, 0, 100, 4, true, "%", 1)
            aa.freeze_ms = gaa:slider("\n delay:freeze"..c, 1, 100, 15, true, "ms", 1)

            aa.delay_space = self:space(gaa)
            aa.delay_adds = gaa:combobox("\f<a>Delay »\r Add-ons"..c, {"-","Randomize Delay Ticks","Freeze-Inverter"})
            
            do
                aa.delayCheck1:depend({aa.delay_adds, "Randomize Delay Ticks"})
                aa.delay_value:depend({aa.delay_adds, "Randomize Delay Ticks"})
                aa.delayCheck2:depend({aa.delay_adds, "Randomize Delay Ticks"})
                aa.delay_random:depend({aa.delay_adds, "Randomize Delay Ticks"})
                aa.delay_value_freze:depend({aa.delay_adds, "Randomize Delay Ticks", true})
                aa.freeze_random:depend({aa.delay_adds, "Freeze-Inverter"})
                aa.freeze_ms:depend({aa.delay_adds, "Freeze-Inverter"})
            end

            for _, v in pairs(defaa) do
                local astate = puiacc.."•\a999999ff  "..state:upper_first()
                local arr = {{menu.aa.builder.cond, astate}}

                if _ ~= "active" and _ ~= "space123" then
                    arr = {{menu.aa.builder.cond, astate}, {defaa.active, true}}
                end

                v:depend(table.unpack(arr))
            end

            for _, v in pairs(aa) do
                local astate = puiacc.."•\a999999ff  "..state:upper_first()
                local arr = {{menu.aa.builder.cond, astate}}

                if _ ~= "active" and _ ~= "space123" and not astate:find("Global") then
                    arr = {{menu.aa.builder.cond, astate}, {aa.active, true}}
                end

                v:depend(table.unpack(arr))
            end
        end

        menu.aa.space = self:space(goh)
        menu.aa.state_to = goh:button("\v\r State To \v»\r ⛟", function()
            local tab = menu.aa.tab:get():find("Builder") and "builder" or "defensive"
            local state = string.del_string(menu.aa.builder.cond:get(), puiacc.."•\a999999ff  ", true)
            local config = tab=="builder" and pui.setup({menu.aa.builder.states.jitr[state]}) or pui.setup({menu.aa.builder.states.defs[state]})

			local data = config:save()
			local encrypted = "{state:"..state..":"..tab.."}::"..base64.encode(json.stringify(data))

            clipboard.set(encrypted)
            print("Exported state: "..tab.."::"..state)
        end)
        menu.aa.state_from = goh:button("\v\r State From \v«\r ⛴", function()
            local tab = menu.aa.tab:get():find("Builder") and "builder" or "defensive"
            local state = string.del_string(menu.aa.builder.cond:get(), puiacc.."•\a999999ff  ", true)
            local config = tab=="builder" and pui.setup({menu.aa.builder.states.jitr[state]}) or pui.setup({menu.aa.builder.states.defs[state]})

            local encrypted = clipboard.get()
            local dcp = encrypted:find("::")
            
            if not dcp then
                print("Pls, copy config for state!")
                return
            end
            
            local decoded = base64.decode(encrypted:sub(dcp + 2))
            
            local success, data = pcall(json.parse, decoded)
            if not success then
                print("Config state data invalid, try other!")
                return
            end
            
            config:load(data)
            
            print("Imported state: "..tab.."::"..state)
        end)
        menu.aa.reset = goh:button("\v♻\r Reset", function()
            local state = menu.aa.builder.cond:get()
            config:load(json.parse("[{...}]"))
        end)

        for element, deps in pairs(hydennn) do
            pui.traverse(element, function(ac)
                ac:depend(unpack(deps))
            end)
        end
    end
} gui:init()

start(function()
    local events = {
        set = client.set_event_callback,
        unset = client.unset_event_callback,
        fire = client.fire_event
    }
    
    local event_handler_mt = {
        set = function(self, callback)
            if type(callback) == "function" and self.proxy[callback] == nil then
                local callback_index = #self.callbacks + 1
                self.proxy[callback], self.callbacks[callback_index] = callback_index, callback
            end
        end,
        
        unset = function(self, callback)
            local callback_index = self.proxy[callback]
            if callback_index == nil then return end
            
            table.remove(self.callbacks, callback_index)
            self.proxy[callback] = nil
            
            for cb, idx in pairs(self.proxy) do
                if callback_index < idx then
                    self.proxy[cb] = idx - 1
                end
            end
        end,
        
        __call = function(self, enable, callback)
            if enable then
                event_handler_mt.set(self, callback)
            else
                event_handler_mt.unset(self, callback)
            end
        end,
        
        fire = function(self, ...)
            return self.hook(...)
        end,
        
        global_fire = function(self, ...)
            events.fire(self.event_name, ...)
        end,
        
        unhook = function(self)
            events.unset(self.event_name, self.hook)
        end
    }
    
    event_handler_mt.__index = event_handler_mt
    
    local call_reg = setmetatable({}, {
        __index = function(registry, event_name)
            local handler = setmetatable({
                event_name = event_name,
                proxy = {},
                callbacks = {}
            }, event_handler_mt)
            
            function handler.hook(...)
                local result
                
                for i = 1, #handler.callbacks do
                    if handler.callbacks[i] then
                        local callback_result = handler.callbacks[i](...)
                        if callback_result ~= nil then
                            result = callback_result
                        end
                    end
                end
                
                return result
            end
            
            events.set(handler.event_name, handler.hook)
            rawset(registry, event_name, handler)
            
            return handler
        end
    })

    local animate = {
        table = {},
        smooth = function(self, start, end_pos, speed)
            return (end_pos - start) * (globals.frametime() * speed * 170) + start
        end,
        lerp = function(self, start, end_pos, speed)
            speed = math.clamp(globals.frametime() * speed * 175, 0, 1)

            local finally = (end_pos - start) * speed + start
    
            return tonumber(string.format("%.3f", finally))
        end,
        get_anim = function(self, name) 
            return self.table[name]
        end,
        color = function(self, name, value, speed)
            local aname = "clr." .. name

            if not self.table[aname] then
                self.table[aname] = {unpack(value)}
            end
            
            local result = {}
            
            for i = 1, 4 do
                result[i] = self:lerp(self.table[aname][i], value[i], speed)
                self.table[aname][i] = result[i]
            end
            
            return unpack(result)
        end,
        number = function(self, name, value, speed)
            if self.table[name] == nil then
                self.table[name] = value
            end
            
            local animation = self:lerp(self.table[name], value, speed)
    
            self.table[name] = animation
    
            return self.table[name]
        end
    }

    local render = {
        measures = function(self, plus, arg, name) 
            return {renderer.measure_text(arg, name) + plus, name}
        end,
        alphen = function(self, value)
            return math.clamp(value, 0, 255)
        end,
        blur = function(self, x, y, w, h) 
            return renderer.blur(x, y, w, h)
        end,
        rect = {
            rect = function(self, x, y, w, h, clr, rounding)
                local r, g, b, a = unpack(clr)
        
                renderer.circle(x + rounding, y + rounding, r, g, b, a, rounding, 180, 0.25)
                renderer.rectangle(x + rounding, y, w - rounding - rounding, rounding, r, g, b, a)
                renderer.circle(x + w - rounding, y + rounding, r, g, b, a, rounding, 90, 0.25)
                renderer.rectangle(x, y + rounding, w, h - rounding*2, r, g, b, a)
                renderer.circle(x + rounding, y + h - rounding, r, g, b, a, rounding, 270, 0.25)
                renderer.rectangle(x + rounding, y + h - rounding, w - rounding - rounding, rounding, r, g, b, a)
                renderer.circle(x + w - rounding, y + h - rounding, r, g, b, a, rounding, 0, 0.25)
            end,
            outline = function(self, x, y, w, h, clr, thickness, round)
                local r, g, b, a = unpack(clr)
        
                if thickness == 0 then
                    renderer.rectangle(x, y, w - round, round, r, g, b, a)
                    renderer.rectangle(x, y + round, round, h - round, r, g, b, a)
                    renderer.rectangle(x + w - round, y, round, h - round, r, g, b, a)
                    renderer.rectangle(x + round, y + h - round, w - round, round, r, g, b, a)
                else
                    renderer.circle_outline(x + thickness, y + thickness, r, g, b, a, thickness, 180, 0.25, round)
                    renderer.rectangle(x + thickness, y, w - thickness - thickness, round, r, g, b, a)
                    renderer.circle_outline(x + w - thickness, y + thickness, r, g, b, a, thickness, 270, 0.25, round)
                    renderer.rectangle(x, y + thickness, round, h - thickness - thickness, r, g, b, a)
                    renderer.circle_outline(x + thickness, y + h - thickness, r, g, b, a, thickness, 90, 0.25, round)
                    renderer.rectangle(x + thickness, y + h - round, w - thickness - thickness, round, r, g, b, a)
                    renderer.circle_outline(x + w - thickness, y + h - thickness, r, g, b, a, thickness, 0, 0.25, round)
                    renderer.rectangle(x + w - round, y + thickness, round, h - thickness - thickness, r, g, b, a)
                end
            end,
            emberlash = function(self, x, y, w, h, clr, rounding, clr2, thickness)
                local r, g, b, a = unpack(clr)
                local r1, g1, b1, a1
        
                renderer.circle(x + rounding, y + rounding, r, g, b, a, rounding, 180, 0.25)
                renderer.rectangle(x + rounding, y, w - rounding - rounding, rounding, r, g, b, a)
                renderer.circle(x + w - rounding, y + rounding, r, g, b, a, rounding, 90, 0.25)
                renderer.rectangle(x, y + rounding, w, h - rounding*2 + 1, r, g, b, a)
                
                renderer.circle(x + rounding, y + h - rounding + 1, r, g, b, a, rounding, 270, 0.25)
                renderer.rectangle(x + rounding, y + h - rounding + 1, w - rounding - rounding, rounding, r, g, b, a)
                renderer.circle(x + w - rounding, y + h - rounding + 1, r, g, b, a, rounding, 0, 0.25)
        
                if clr2 then 
                    r1, g1, b1, a1 = unpack(clr2)
                    local hs = thickness or 2
        
                    renderer.rectangle(x + rounding, y, w - rounding * 2, hs, r1, g1, b1, a1)
                    renderer.gradient(x - 1, y + rounding, hs, h - rounding * 2.7, r1, g1, b1, a1, r1, g1, b1, 0, false) -- left
                    renderer.gradient(x + w - 1, y + rounding, hs, h - rounding * 2.7, r1, g1, b1, a1, r1, g1, b1, 0, false) -- right
                    renderer.circle_outline(x + w - rounding, y + rounding, r1, g1, b1, a1, rounding, 270, 0.25, hs) -- right
                    renderer.circle_outline(x + rounding, y + rounding, r1, g1, b1, a1, rounding, 180, .25, hs) -- left
                end
            end,
            recth = function(self, x, y, w, h, clr, rounding)
                local r, g, b, a = unpack(clr)
        
                renderer.circle(x + rounding, y + rounding, r,g, b,a, rounding, 180, 0.25)
                renderer.rectangle(x + rounding, y, w - rounding - rounding, rounding, r,g, b,a)
                renderer.circle(x + w - rounding, y + rounding, r,g, b,a, rounding, 90, 0.25)
                renderer.rectangle(x, y + rounding, w, h - rounding, r,g, b,a)
            end
        },
        glow = {
            work = function(x, y, w, h, radius, thickness, color)
                radius = math.min(w/2, h/2, radius)
                local r, g, b, a = unpack(color)
                if radius == 1 then
                    renderer.rectangle(x, y, w, thickness, r, g, b, a)
                    renderer.rectangle(x, y + h - thickness, w , thickness, r, g, b, a)
                else
                    renderer.rectangle(x + radius, y, w - radius*2, thickness, r, g, b, a)
                    renderer.rectangle(x + radius, y + h - thickness, w - radius*2, thickness, r, g, b, a)
                    renderer.rectangle(x, y + radius, thickness, h - radius*2, r, g, b, a)
                    renderer.rectangle(x + w - thickness, y + radius, thickness, h - radius*2, r, g, b, a)
                    renderer.circle_outline(x + radius, y + radius, r, g, b, a, radius, 180, 0.25, thickness)
                    renderer.circle_outline(x + radius, y + h - radius, r, g, b, a, radius, 90, 0.25, thickness)
                    renderer.circle_outline(x + w - radius, y + radius, r, g, b, a, radius, -90, 0.25, thickness)
                    renderer.circle_outline(x + w - radius, y + h - radius, r, g, b, a, radius, 0, 0.25, thickness)
                end
            end,
            run = function(self,x,y,w,h,width, clr,rounding,thickness)
                local Offset = 1
                local r, g, b, a = unpack(clr)
    
                for k = 0, width do
                    if a * (k/width)^(1) > 5 then
                        local accent = {r, g, b, a * (k/width)^(2)}
                        self.work(x + (k - width - Offset)*thickness, y + (k - width - Offset) * thickness, w - (k - width - Offset)*thickness*2, h + 1 - (k - width - Offset)*thickness*2, rounding + thickness * (width - k + Offset), thickness, accent)
                    end
                end
            end
        },
        paint_tab = function(self, el, names, labels)
            local text_tab = ""
            local active_index = 1
            local current_tab = el:get()
            for i, name in ipairs(names) do
                if current_tab:find(name) then
                    active_index = i
                    break
                end
            end
            for i, label in ipairs(labels) do
                if i == active_index then
                    text_tab = text_tab .. "\v" .. label
                else
                    text_tab = text_tab .. "\f<gray>" .. label
                end
                if i < #labels then
                    text_tab = text_tab .. "\f<gray>  •  "
                end
            end
            return text_tab
        end,
        text = {
            default = function(self, speed, string, r1, g1, b1, a1, r2, g2, b2, a2)
                local t_out, t_out_iter = {}, 1
                local time = globals.curtime()
                for i = 1, #string do
                    local iter = (i - 1)/(#string - 1) + time * speed
                    local progress = math.abs(math.cos(iter))
                    
                    local r = r1 + (r2 - r1) * progress
                    local g = g1 + (g2 - g1) * progress
                    local b = b1 + (b2 - b1) * progress
                    local a = a1 + (a2 - a1) * progress
                    
                    t_out[t_out_iter] = "\a" .. math.to_hex(r, g, b, a)
                    t_out[t_out_iter + 1] = string:sub(i, i)
                    t_out_iter = t_out_iter + 2
                end
            
                return t_out
            end,
            center = function(self, speed, string, ...)
                local colors = {...}
                local t_out, t_out_iter = {}, 1
                local time = globals.curtime()
                local length = #string
                local center = length / 2
                
                local valid_colors = {}
                for i = 1, 4 do
                    if colors[i] and type(colors[i]) == "table" and #colors[i] >= 4 then
                        valid_colors[#valid_colors+1] = colors[i]
                    end
                end
                
                for i = 1, length do
                    local distance_from_center = math.abs(i - center) / center
                    local iter = distance_from_center + time * speed
                    local progress = (math.sin(iter) + 1) / 2
                    local color_count = #valid_colors
                    local segment = progress * (color_count - 1)
                    local idx1 = math.floor(segment) + 1
                    local idx2 = math.min(idx1 + 1, color_count)
                    local local_progress = segment % 1
                    local c1 = valid_colors[idx1] or valid_colors[1]
                    local c2 = valid_colors[idx2] or valid_colors[#valid_colors]
                    local r = c1[1] + (c2[1] - c1[1]) * local_progress
                    local g = c1[2] + (c2[2] - c1[2]) * local_progress
                    local b = c1[3] + (c2[3] - c1[3]) * local_progress
                    local a = c1[4] + (c2[4] - c1[4]) * local_progress
                    
                    t_out[t_out_iter] = "\a" .. math.to_hex(r, g, b, a)
                    t_out[t_out_iter + 1] = string:sub(i, i)
                    t_out_iter = t_out_iter + 2
                end
                
                return t_out
            end,
        }
    }  

    local native_print = vtable_bind("vstdlib.dll", "VEngineCvar007", 25, "void(__cdecl*)(void*, const void*, const char*, ...)")
    local hex = "\a74A6A9FF"

	printc = function (...)
		for i, v in ipairs{...} do
			local r = "\aD9D9D9" .. string.gsub(tostring(v), "[\r\v]", {["\r"] = "\aD9D9D9", ["\v"] = "\a".. (hex:sub(1, 7))})
			for col, text in r:gmatch("\a(%x%x%x%x%x%x)([^\a]*)") do
				native_print(math.to_hex(tonumber(col)), text)
			end
		end
		native_print("\a74A6A9", "\n")
	end

    function printf(...)
        --printc("\vemberlash\r ", ...)
        print("emberlash - ", ...)
    end

    local draggable = {
        elements = {},
        active_element = nil,
        offset = {0,0},
        alpha = {0,0,0},

        new = function(self, name, x, y, lock_x, lock_y)
            local element = {
                name = name,
                x = x,
                y = y,
                width = 0,
                height = 0,
                dragging = false,
                locks = {lock_x or false, lock_y or false},

                drag = function(elem, width, height)
                    elem.width = width
                    elem.height = height
                    self.alpha[3] = animate:smooth(self.alpha[3], pui.menu_open and 1 or 0, 0.04)

                    if (self.alpha[3] > 0.1) then 
                        self:setup(elem, self.alpha[3])
                    end
                end,
                get = function(elem) 
                    return elem.x, elem.y
                end,
                get_x = function(elem) 
                    return elem.x, 0.1
                end,
                get_y = function(elem) 
                    return elem.y 
                end
            }
            table.insert(self.elements, element)
            return element
        end,
        hover = function(self, x, y, w, h, mouseX, mouseY)
            return mouseX >= x and mouseX <= x + w and mouseY >= y and mouseY <= y + h
        end,
        setup = function(self, element, alpha_menu)
            local mouseX, mouseY = ui.mouse_position()
            local pressed_left = client.key_state(0x01) == true
            local hover = self:hover(element.x, element.y, element.width, element.height, mouseX, mouseY)

            local padd = 5
            self.alpha[1] = animate:smooth(self.alpha[1], 15 + (hover and 20 or 0) + (element.dragging and 60 or 0), 0.05)*alpha_menu
            self.alpha[2] = animate:smooth(self.alpha[2], element.dragging and 80 or 0, 0.03)*alpha_menu

            render.rect:rect(element.x - padd, element.y - padd, element.width + padd * 2, element.height + padd * 2, {255,255,255,self.alpha[1]}, 4)
            renderer.rectangle(0,0,x,y,0,0,0,self.alpha[2])

            if self.alpha[2] >.9 then  -- отсылка на >.< 
                renderer.blur(0,0,x,y)
            end

            if pressed_left then
                if not self.active_element then
                    if hover then
                        self.active_element = element
                        self.offset[1] = mouseX - element.x
                        self.offset[2] = mouseY - element.y
                        element.dragging = true
                    end
                end
            else
                if element.dragging then
                    element.dragging = false
                    self.active_element = nil
                end
            end
            if element.dragging then
                if not element.locks[1] then 
                    element.x = mouseX - self.offset[1]
                else
                    renderer.rectangle(x/2, 0, 1, y, 255,255,255,self.alpha[2])
                end
                if not element.locks[2] then 
                    element.y = mouseY - self.offset[2]
                else
                    renderer.rectangle(0, y/2, x, 1, 255,255,255,self.alpha[2])
                end

                element.x = math.max(0, math.min(x - element.width, element.x))
                element.y = math.max(0, math.min(y - element.height, element.y))
            end
        end
    }

    local util = {
        flags = { 
            ['HIT'] = {11, 2048} 
        },
        contains = function(self, tbl, val)
            for k, v in pairs(tbl) do
                if v == val then
                    return true
                end
            end
            return false
        end,    
        is_flag = function(self, entindex, flag_name)
            if not entindex or not flag_name then return false end
        
            local flag_data = self.flags[flag_name]
            if flag_data == nil then return false end
            local esp_data = entity.get_esp_data(entindex) or {}
        
            return bit.band(esp_data.flags or 0, bit.lshift(1, flag_data[1])) == flag_data[2]
        end,
        get_me = function(self)
            return entity.get_local_player()
        end,
        not_me = function(self)
            local me = self.get_me()
            return me == nil or not entity.is_alive(me)
        end,
        in_air = function(self, ent)
            local flags = entity.get_prop(ent, "m_fFlags")
            return bit.band(flags, 1) == 0
        end,
        in_duck = function(self, ent)
            local flags = entity.get_prop(ent, "m_fFlags")
            return bit.band(flags, 4) == 4
        end,
        get_velocity = function(self, ent)
            local wam = entity.get_prop(ent, "m_vecVelocity")

            return vector(wam):length2d()
        end,
        charge = function(self)
            if self:not_me() then 
                return 
            end

            local a = self:get_me()
            local weapon = entity.get_prop(a, "m_hActiveWeapon")

            if weapon == nil then 
                return false 
            end

            local next_attack = entity.get_prop(a, "m_flNextAttack") + 0.01
            local checkcheck = entity.get_prop(weapon, "m_flNextPrimaryAttack")

            if checkcheck == nil then 
                return 
            end

            local next_primary_attack = checkcheck + 0.01

            if next_attack == nil or next_primary_attack == nil then 
                return false 
            end

            return next_attack - globals.curtime() < 0 and next_primary_attack - globals.curtime() < 0
        end,
        manual = function(self)
            if self:not_me() then
                return
            end

            local left = menu.aa.setting.hotkey.manual_l
            local right = menu.aa.setting.hotkey.manual_r
            local forward = menu.aa.setting.hotkey.manual_f

            if self.last_forward == nil then
                self.last_forward, self.last_right, self.last_left = forward:get(), right:get(), left:get()
            end

            if left:get() ~= self.last_left then
                if self.manual_side == 1 then
                    self.manual_side = nil
                else
                    self.manual_side = 1
                end
            end

            if right:get() ~= self.last_right then
                if self.manual_side == 2 then
                    self.manual_side = nil
                else
                    self.manual_side = 2
                end
            end

            if forward:get() ~= self.last_forward then
                if self.manual_side == 3 then
                    self.manual_side = nil
                else
                    self.manual_side = 3
                end
            end

            self.last_forward, self.last_right, self.last_left = forward:get(), right:get(), left:get()

            if not self.manual_side then
                return
            end

            return ({-100, 90, 180})[self.manual_side]
        end,
        state = function(self)
            local me = self:get_me()
        
            local exec = {
                vel = self:get_velocity(me),
                iair = self:in_air(me),
                ducking = self:in_duck(me) or ui.get(refs.rage.faceduck[1]),
                manual = self:manual(),
                menu = menu.aa.builder.states.jitr,
                dt = ui.get(refs.rage.dt.value[1]) and ui.get(refs.rage.dt.value[2]),
                os = ui.get(refs.rage.osaa[1]) and ui.get(refs.rage.osaa[2]),
                fd = ui.get(refs.rage.faceduck[1]),
                target = client.current_threat(),
                sw = ui.get(refs.sw[1]) and ui.get(refs.sw[2]),
                qp = ui.get(refs.rage.peek[1]) and ui.get(refs.rage.peek[2])
            }
        
            local state_checks = {
                { check = exec.vel and exec.menu["fakelag"].active() and ((not exec.dt and not exec.os) or exec.fd), state = "fakelag" },
                { check = exec.vel and exec.menu["hideshots"].active() and exec.os and not exec.dt and not exec.fd, state = "hideshots" },
                { check = not exec.iair and exec.qp and self:is_flag(exec.target, "HIT") and exec.menu["on-peek"].active(), state = "on-peek" },
                { check = exec.manual == -100 and exec.menu["manual-left"].active(), state = "manual-left" },
                { check = exec.manual == 90 and exec.menu["manual-right"].active(), state = "manual-right" },
                { check = exec.iair and exec.ducking and exec.menu["air+"].active(), state = "air+" },
                { check = exec.iair and exec.menu["air"].active(), state = "air" },
                { check = exec.vel > 1 and exec.sw and exec.menu["walking"].active(), state = "walking" },
                { check = exec.vel > 1.5 and exec.ducking and exec.menu["crouch-moving"].active(), state = "crouch-moving" },
                { check = exec.vel > 1.5 and exec.menu["running"].active(), state = "running" },
                { check = exec.ducking and exec.menu["crouch"].active(), state = "crouch" },
                { check = exec.menu["stand"].active(), state = "stand" },
               
            }
        
            for _, check in ipairs(state_checks) do
                if check.check then
                    return check.state
                end
            end
        
            return "global"
        end,
        normalize_yaw = function(self, yaw)
            yaw = yaw % 360 
            yaw = (yaw + 360) % 360
            if (yaw > 180)  then
                yaw = yaw - 360
            end
            return yaw
        end,
        get_real_time = function(self)
            local hours, minutes = client.system_time()
            return string.format("%02d:%02d", hours, minutes)
        end,
        format_text = function(self, text, symbol, clr)
            local r, g, b, alpha = clr[1], clr[2], clr[3], clr[4]
            local parts = {}
            local split_text = text:split(symbol)
            local colored = true
            
            for i, part in ipairs(split_text) do
                if i % 2 == 0 then
                    local color = colored and math.to_hex(r, g, b, alpha) or math.to_hex(255, 255, 255, alpha)
                    table.insert(parts, "\a"..color..part)
                    colored = not colored
                else
                    table.insert(parts, part)
                end
            end
            
            return table.concat(parts)
        end
    }

    local drag_notify = draggable:new("notification", x/2 - 60, y/2 + 250, true)

    local notification = {
        notifications = {},
        test_alpha = 0,
        start_y = y/2 + 250,
        create_notification = function(maxTime, message, description, color)
            return {
                message = message, description = description,
                maxTime = maxTime, startTime = globals.curtime(),
                alpha = 0, y = 0,
                clr = color or {r, g, b},
                direction = math.random(0, 1) * 2 - 1,
                
                is_expired = function(self) return (globals.curtime() - self.startTime) * 1000 >= self.maxTime or (globals.curtime() - self.startTime) > 7 end,
                alpha_check = function(self)
                    local elapsed = (globals.curtime() - self.startTime) * 1000
                    return elapsed >= self.maxTime or self.maxTime - elapsed <= 100
                end
            }
        end,
        delete = function(self)  
            client.set_event_callback("paint_ui", function()
                for i = #self.notifications, 1, -1 do
                    if self.notifications[i]:is_expired() then
                        table.remove(self.notifications, i)
                    end
                end
            end)
            return self
        end,
        create = function(self, message, description, maxTime, color)
            table.insert(self.notifications, 1, self.create_notification(maxTime, message, description, color))
        end,
        preview = function(self, a, y)
            local style33 = menu.vis.color.style:get()
            local c = { "\a"..math.to_hex(255,255,255,a*255), "\a"..math.to_hex(r,g,b,a*255) }
            local text = render:measures(9, nil, "Killed "..c[2].."mephissa "..c[1].."in"..c[2].." ass (dog 109%)")
            local bc = (35-35*a)

            if style33 == "Lilith" then 
                if not util:contains(menu.vis.glow:get(), "Event Logger") then
                    render.glow:run(x/2 - text[1]/2, y-12-bc, text[1], 25, 20, {r/4,g/4,b/4,a*100},6,1)
                end
                render.rect:emberlash(x/2 - text[1]/2, y-12-bc, text[1], 25, {0,0,0,a*255},4,{r,g,b,a*255}, 2)
                renderer.text(x/2, y - bc + 1, 255,255,255,a*255, "c", nil, text[2])
            elseif style33 == "Nightly" then 
                local logo = render:measures(9, nil, "emberlash")

                render.rect:emberlash(x/2-text[1] + logo[1]/2, y - 12 - bc, logo[1], 23, {25,25,25,a*210},4)
                renderer.text(x/2-text[1]+3 + logo[1]/2,y-bc - 7, r,g,b,a*255, "b", nil, logo[2])
                
                render.rect:recth(x/2 - text[1]/2 + logo[1]/2, y - 12 - bc, text[1]*a, 24, {25,25,25,a*210}, 4)
                renderer.rectangle(x/2 - text[1]/2 + logo[1]/2, y - bc + 10, text[1]*a, 2, r, g, b, a*255)

                renderer.text(x/2 + logo[1]/2, y - bc -1, 255,255,255,a*255, "c", nil, text[2])
            end
        end,
        complete = function(self)
            local style = menu.vis.color.style:get()
            local menu_check = menu.vis.widgets:get() and menu.vis.widgets_type:get("Event logger") and menu.vis.markers:get() and menu.vis.markers_type:get("Preview")
            
            local base_y = drag_notify:get_y() + 12
            local has_notifications = #self.notifications > 0
        
            if menu_check or has_notifications then 
                drag_notify:drag(120, 25)
            end
        
            if has_notifications then
                self:delete()
        
                for i, notification in ipairs(self.notifications) do
                    notification.y = animate:lerp(notification.y, (i - 1) * 32, 0.08)
                    notification.alpha = animate:lerp(notification.alpha, notification:alpha_check() and 0 or 1, 0.05)
                    
                    local alpha = tonumber(string.format("%.2f", notification.alpha))
                    local r, g, b = unpack(notification.clr)
                    local current_y = base_y + notification.y
                    local brightness_correction = (25 - 25 * alpha) * -1
                    
                    local formatted_text = util:format_text(notification.description, "$", {r, g, b, alpha * 255})
                    local white_hex = math.to_hex(255, 255, 255, alpha * 255)
                    
                    if style == "Lilith" then
                        self.style:lilith(r, g, b, alpha, current_y, brightness_correction, formatted_text, notification.message)
                    elseif style == "Nightly" then
                        self.style:nightly(r, g, b, alpha, current_y, brightness_correction, formatted_text)
                    end
                end
            else
                self.test_alpha = animate:lerp(self.test_alpha, (pui.menu_open and menu_check) and 1 or 0, 0.15)
                
                if self.test_alpha > 0.1 then 
                    self:preview(self.test_alpha, base_y)
                end
            end
        end,
        
        style = {
            lilith = function(self, r, g, b, a, y, bc, main_text, message)
                local icon = render:measures(8, "b", "\a"..math.to_hex(r, g, b, a*255)..message.."\a")
                local text = render:measures(9, nil, main_text)
                
                local icon_x = x/2 - text[1]/2 - 7
                local text_x = x/2 - text[1]/2 + icon[1]
                
                if not util:contains(menu.vis.glow:get(), "Event Logger") then
                    render.glow:run(text_x, y-12-bc, text[1]+1, 25, 20, {r/4, g/4, b/4, a*100}, 6, 1)
                    render.glow:run(icon_x, y-12-bc, icon[1], 25, 20, {r/4, g/4, b/4, a*100}, 6, 1)
                end
            
                render.rect:emberlash(icon_x, y-12-bc, icon[1], 25, {0, 0, 0, a*255}, 4, {r, g, b, a*255}, 2)
                render.rect:emberlash(text_x, y-12-bc, text[1]+1, 25, {0, 0, 0, a*255}, 4, {r, g, b, a*255}, 2)
            
                renderer.text(icon_x + 4, y - 5 - bc, 255, 255, 255, a*255, "b", nil, icon[2])
                renderer.text(text_x + 5, y - 4 - bc, 255, 255, 255, a*255, "", nil, text[2])
            end,
            
            nightly = function(self, r, g, b, a, y, bc, main_text)
                local text = render:measures(9, nil, main_text)
                local logo = render:measures(9, nil, "emberlash")
                local start_x = x/2 - text[1]/2 - logo[1]/2 - 4
                
                render.rect:emberlash(start_x, y - 12 - bc, logo[1], 23, {25, 25, 25, a*210}, 4)
                renderer.text(start_x + 3, y - bc - 7, r, g, b, a*255, "b", nil, logo[2])
                
                local text_start = x/2 - text[1]/2 + logo[1]/2
                render.rect:recth(text_start, y - 12 - bc, text[1]*a, 24, {25, 25, 25, a*210}, 4)
                renderer.rectangle(text_start, y - bc + 10, text[1]*a, 2, r, g, b, a*255)
                
                if not util:contains(menu.vis.glow:get(), "Event Logger") then
                    render.glow:run(text_start, y - 12 - bc, text[1]*a, 23, 10, {r, g, b, a*30}, 4, 1)
                end
            
                renderer.text(x/2 + logo[1]/2, y - bc - 1, 255, 255, 255, a*255, "c", nil, text[2])
            end
        }
    }

    client.delay_call(0.5, function() notification:create(database.read(databases.load), "Welcome to $emberlash$", 1300) end)

    call_reg.paint:set(function()
        notification:complete()
    end)

    local defensive = {
        check = 0,
        defensive = 0,
        sim_time = globals.tickcount(),
        active_until = 0,
        ticks = 0,
        active = false,

        activate = function(self)
            local me = util:get_me()

            if util:not_me() then 
                return 
            end

            local tickcount = globals.tickcount()
            local sim_time = entity.get_prop(me, "m_flSimulationTime")
            local sim_diff = toticks(sim_time - self.sim_time)

            if sim_diff < 0 then
                self.active_until = tickcount + math.abs(sim_diff)
            end

            self.ticks = math.clamp(self.active_until - tickcount, 0, 16)
            self.active = self.active_until > tickcount

            self.sim_time = sim_time
        end,
        normalize = function(self)
            local me = util:get_me()
            local tickbase = entity.get_prop(me, "m_nTickBase")

            self.check = math.max(tickbase, self.check or 0)
            self.defensive = math.abs(tickbase - self.check)
        end,
        reset = function(self)
            self.check = 0
            self.defensive = 0
        end
    }

    local antiaim = {
        me = nil,
        manual_side = 0,
        yaw_last = 0,

        get_defensive = function(self, data)
            local trigs = data.trigger
            local condition = false
            local check_charge = (util:contains(data.activators, "Double tap") and refs.rage.dt.value[1]) or (util:contains(data.activators, "Hide shots") and refs.rage.osaa[1])
            local tick = data.duration*2

            if util:contains(trigs, "Always") then 
                condition = true
            end

            if util:contains(trigs, "On weapon switch") then 
                local nextattack = math.max(entity.get_prop(self.me, 'm_flNextAttack') - globals.curtime(), 0)

                if nextattack / globals.tickinterval() > defensive.defensive + 2 then
                    condition = true
                end
            end

            if globals.tickcount() % 32 <= tick and check_charge then 
                return condition
            end
        end,
        get_safehead = function(self, taser)
            local target = client.current_threat()

            if target then
                local taser = util:contains(menu.aa.setting.sett.safehead:get(), "Taser")
                local knife = util:contains(menu.aa.setting.sett.safehead:get(), "Knife")
                local weapon = entity.get_player_weapon(self.me)
                if util:in_air(self.me) and weapon and (knife and entity.get_classname(weapon):find('Knife') or (taser and entity.get_classname(weapon):find('Taser'))) then 
                    return true
                end
            end
            
            return false
        end,
        get_backstab = function(self)
            local target = client.current_threat()

            if util:not_me() or not target then 
                return false 
            end

            local weapon_ent = entity.get_player_weapon(target)
            if not weapon_ent then return false end
            local weapon_name = entity.get_classname(weapon_ent)
            if not weapon_name:find('Knife') then return false end
            local origin = {vector(entity.get_origin(self.me)), vector(entity.get_origin(target))}

            return origin[2]:dist2d(origin[1]) < 230 -- #дистанция #2метра #коронавирус
        end,
        side = 0,
        cycle = 0,
        ways = {
            curr = 0,
            deg = 0,
        },
        yaw = { 
            freeze = 0,
            random = 0,
            skit = 0,
        }, 
        def = {
            yaw = {spin=0,side=0,sway=0},
            pitch = {spin=0,side=0,sway=0}
        },
        modifier = function(self, data, type, is_delayed, general_yaw)
            local to_return = 0
            local current_side = self.side

            if type == "Offset" then
                if current_side == 1 then
                    to_return = general_yaw
                end
            elseif type == "Center" then
                to_return = (current_side == 1 and -general_yaw or general_yaw)
            elseif type == "Ground-Based" then
                local sequence = {0, 2, 1}

                local next_side

                if self.yaw.skit == #sequence then
                    self.yaw.skit = 1
                elseif not is_delayed then
                    self.yaw.skit = self.yaw.skit + 1
                end
                
                next_side = sequence[self.yaw.skit]

                if next_side == 0 then
                    to_return = to_return - math.abs(general_yaw)
                elseif next_side == 1 then
                    to_return = to_return + math.abs(general_yaw)
                end
            elseif type == "Random" then 
                local rand = (math.random(0, general_yaw*2) - general_yaw)
                if not is_delayed then
                    to_return = to_return + rand

                    self.yaw.random = rand
                else
                    to_return = to_return + self.yaw.random
                end
            elseif type == "X-way" then
                if not is_delayed then 
                    self.ways.curr = self.ways.curr + 1 
                    if self.ways.curr > data.way_value then
                        self.ways.curr = 1 
                    end 
                else
                    to_return = to_return + self.ways.deg
                end

                self.ways.deg = data["way_"..self.ways.curr] or 0
                to_return = self.ways.deg
            end
            
            return to_return
        end,
        set = function(self, cmd, data, data_defs) 
            local ref = {pitch_mode = refs.aa.pitch[1], pitch = refs.aa.pitch[2], yaw_mode = refs.aa.yaw[1], yaw = refs.aa.yaw[2], yaw_base = refs.aa.yaw_base[1], jitter_type = refs.aa.yaw_jitter[1], jitter_yaw = refs.aa.yaw_jitter[2], body_mode = refs.aa.body_yaw[1], body = refs.aa.body_yaw[2], body_f = refs.aa.body_free[1]}

            local safe_head = false
            local manual = util:manual()
            local current_side = self.side

            local freeze_value = data.delay_value_freze
            local freeze_delay = data.freeze_ms/10

            if ((globals.tickcount() % freeze_delay*2)+1 <= freeze_delay and -1 or 1) == 1 then 
                self.yaw.freeze = math.random(0, data.freeze_random/10)
            end

            local freeze = freeze_value + self.yaw.freeze/2

            local yaw_delay = math.clamp(data.delay_adds=="Randomize Delay Ticks" and data.delay_value + math.random(-data.delay_random, data.delay_random) or freeze, 0, 32)
            local is_delayed = true

            if data.delay_adds=="-" then
                yaw_delay = data.delay_value_freze
            end

            if globals.chokedcommands() == 0 and self.cycle == yaw_delay then
                current_side = current_side == 1 and 0 or 1
                is_delayed = false
            end

            local pitch = 90
            local yaw_offset = 0
            local general_yaw = (data.lryaw and data.yaw_value or data.lyaw) + math.random(-data.yaw_random, data.yaw_random)
            local body_yaw = data.body_yaw
            local bodyy
        
            if body_yaw == "Off" then
                bodyy = "Off"
            elseif body_yaw == "Opposite" then
                bodyy = "Opposite"
            else
                if body_yaw ~= "Jitter" then 
                    if data.body_yaw_static == "Left" then 
                        current_side = 1
                    else
                        current_side = 0
                    end
                end

                bodyy = "Static"
            end

            yaw_offset = self:modifier(data, data.yaw, is_delayed, general_yaw)

            local defensive_value = 0
            if self:get_defensive(data_defs) then 
                cmd.force_defensive = true
                if defensive.ticks * defensive.defensive > 0 then
                    defensive_value = math.max(defensive.defensive, defensive.ticks)
                end
            end

            if data_defs.active and defensive_value > 0 and not safehead then 
                if data_defs.yaw == "Spin" then 
                    self.def.yaw.spin = self.def.yaw.spin + data_defs.yaw_update * (data_defs.yaw_delay / 5)

                    if self.def.yaw.spin > data_defs.yaw_value then 
                        self.def.yaw.spin = 0
                    end

                    yaw_offset = self.def.yaw.spin
                elseif data_defs.yaw == "Static" then 
                    yaw_offset = data_defs.yaw_value
                elseif data_defs.yaw == "Random" then 
                    yaw_offset = math.random(-data_defs.yaw_value, data_defs.yaw_value)
                elseif data_defs.yaw == "Sway" then
                    local delay = data_defs.yaw_delay * 3
                    self.def.yaw.sway = animate:lerp(self.def.yaw.sway, (globals.tickcount() % (delay * 2)) + 1 <= delay and -1 or 1, data_defs.yaw_value * 0.001)
                    
                    yaw_offset = self.def.yaw.sway * data_defs.yaw_value
                    
                    if self.def.yaw.sway == data_defs.yaw_value then
                        yaw_offset = -yaw_offset
                    end
                elseif data_defs.yaw == "Distortion" then
                    local delay = data_defs.yaw_delay*3

                    if delay == 1 then 
                        self.def.yaw.side = self.def.yaw.side == -1 and 1 or -1
                    else 
                        self.def.yaw.side = (globals.tickcount() % delay*2)+1 <= delay and -1 or 1
                    end

                    yaw_offset = self.def.yaw.side * data_defs.yaw_value
                end

                if data_defs.pitch == "Static" then 
                    pitch = data_defs.pitch_value
                elseif data_defs.pitch == "Random" then 
                    pitch = math.random(data_defs.pitch_value, data_defs.pitch_value_2)
                elseif data_defs.pitch == "Sway" then  -- pitch_value_2
                    local delay = data_defs.pitch_delay * 3
                    self.def.pitch.sway = animate:lerp(self.def.pitch.sway, (globals.tickcount() % (delay * 2)) + 1 <= delay and -1 or 1, data_defs.pitch_value * 0.001)
                    
                    pitch = self.def.pitch.sway * data_defs.pitch_value
                    
                    if self.def.pitch.sway == data_defs.pitch_value then
                        pitch = -pitch
                    end
                elseif data_defs.pitch == "Distortion" then 
                    local delay = data_defs.pitch_delay*3

                    if delay == 1 then 
                        self.def.pitch.side = self.def.pitch.side == -1 and data_defs.pitch_value or data_defs.pitch_value_2
                    else 
                        self.def.pitch.side = (globals.tickcount() % delay*2)+1 <= delay and data_defs.pitch_value or data_defs.pitch_value_2
                    end

                    pitch = self.def.pitch.side
                elseif data_defs.pitch == "Meta" then 
                    local delay = data_defs.pitch_delay * 3
                    local delay_switch = data_defs.pitch_delay * 6

                    self.def.pitch.side = (globals.tickcount() % delay_switch*2)+1 <= delay_switch and -1 or 1
                    self.def.pitch.sway = animate:lerp(self.def.pitch.sway, (globals.tickcount() % (delay * 2)) + 1 <= delay and -1 or 1, data_defs.pitch_value * 0.001)

                    pitch = self.def.pitch.sway * data_defs.pitch_value + math.random(-5, 12)
                    
                    if self.def.pitch.sway == data_defs.pitch_value then
                        pitch = -pitch
                    end
                end
            end

            local add_left = data.lyaw + (math.random(-data.lyaw_random, data.lyaw_random))
            local add_right = data.ryaw + (math.random(-data.ryaw_random, data.ryaw_random))

            yaw_offset = yaw_offset + (data.lryaw and (current_side == 0 and add_right or (current_side == 1 and add_left or 0)) or 0)
        
            local body_yaw_angle = (current_side == 2) and 0 or (current_side == 1 and -data.body_value or data.body_value)

            refs.aa.edge_yaw[1]:override(menu.aa.setting.hotkey.edge_yaw:get() and menu.aa.setting.hotkey.edge_yaw:get_hotkey())
            refs.aa.freestand[1]:override(false)
            ui.set(refs.misc.bindfs[2], "Always on")

            if util:contains(menu.aa.setting.sett.select:get(), "Anti backstab") and self:get_backstab() then 
                yaw_offset = yaw_offset + 180
            end

            if util:contains(menu.aa.setting.sett.select:get(), "Safe head") and self:get_safehead() then
                safe_head = true
                yaw_offset = 0
                pitch = 90
                body_yaw_angle = 0
                current_side = 2
            end

            if manual then
                yaw_offset = yaw_offset + manual
            elseif menu.aa.setting.hotkey.fs:get() and menu.aa.setting.hotkey.fs:get_hotkey() then 
                refs.aa.freestand[1]:override(true)
                if not body_yaw_freestand then
                    yaw_offset = 0
                    body_yaw_angle = 0
                end
            end

            refs.aa.enabled:override(true)
            ref.pitch_mode:override(pitch == "default" and pitch or "custom")
            ref.pitch:override(math.clamp(type(pitch) == "number" and pitch or 0, -89, 89))
            ref.yaw_base:override(data.yaw_base)
            ref.yaw_mode:override(180)
            ref.yaw:override(util:normalize_yaw(yaw_offset))
            self.yaw_last = util:normalize_yaw(yaw_offset)
            ref.jitter_type:override("Off")
            ref.jitter_yaw:override(0)
            ref.body_mode:override(bodyy)
            ref.body:override(body_yaw ~= "Off" and body_yaw_angle or 0)
            ref.body_f:override(false)

            if globals.chokedcommands() == 0 then
                if self.cycle >= yaw_delay then
                    self.cycle = 1
                else
                    self.cycle = self.cycle + 1
                end
            end
            self.side = current_side
        end,
        complete = function(self, cmd, state)
            local data = {}
            local data_defs = {}

            for k, v in pairs(menu.aa.builder.states.jitr[state]) do
                data[k] = v()
            end

            for k, v in pairs(menu.aa.builder.states.defs[state]) do 
                data_defs[k] = v()
            end

            self:set(cmd, data, data_defs)
        end,
        run = function(self, cmd)
            self.me = util.get_me()

            if util:not_me() then
                return 
            end

            local state = util:state()

            self:complete(cmd, state)
        end
    }

    call_reg.setup_command:set(function(cmd)
        antiaim:run(cmd)
    end)

    local hud = {
        draggable:new("watermark-small", 20, y/2 - 10),
        draggable:new("watermark", 20, 20),
        draggable:new("arrows", x/2 + 50, y/2 - 11, false, true),
        draggable:new("crosshair", x/2 - 30, y/2 + 30, true)
    }

    local funcs = {}

    funcs.paint = {
        lc = {
            pos = {}, log = false,
            complete = function(self)
                local me = util:get_me()
                local origin = vector(entity.get_origin(me))
                local time = 1 / globals.tickinterval()

                if globals.chokedcommands() == 0 then
                    self.pos[#self.pos + 1] = origin
                
                    if #self.pos >= time then
                        local record = self.pos[time]
                        self.log = (origin - record):lengthsqr() > 4.096
                    end    
                end
            
                if #self.pos > time then
                    table.remove(self.pos, 1)
                end 
            end,
            run = function(self)
                if util:not_me() or not (menu.vis.widgets:get() and menu.vis.widgets_type:get("LC Side indicator")) then return end 
                local me = util:get_me()
    
                self:complete()
            
                local r, g, b = 240, 15, 15
                if self.log then
                    r, g, b = 160, 202, 43
                end
    
                local red, green, blue = animate:color("lc", {r, g, b, 255}, 0.08)
    
                renderer.indicator(red, green, blue, 240, "LC")
            end
        },
        viewmodel = {
            state = false,
            set = function(self, x, y, z, fov)
                client.set_cvar("viewmodel_offset_x", x)
                client.set_cvar("viewmodel_offset_y", y)
                client.set_cvar("viewmodel_offset_z", z)
                client.set_cvar("viewmodel_fov", fov)
            end,
            work = function(self)
                self:set(menu.vis.view.x:get(), menu.vis.view.y:get(), menu.vis.view.z:get(), menu.vis.view.fov:get())
            end,
            restore = function(self)
                self:set(databases.orig.viewmodel.x, databases.orig.viewmodel.y, databases.orig.viewmodel.z, databases.orig.viewmodel.fov)
            end,
            run = function(self)
                local enabled = menu.vis.viewmodel:get()

                if self.state ~= enabled then 
                    if not enabled then 
                        self:restore()
                    end
                    self.state = enabled
                end

                if enabled then 
                    self:work()
                end
            end
        },
        watermark = {
            fps = 0,
            text = function(self)
                local x, y = hud[1]:get()
                local prefix = render:measures(0, 'a', name:upper_first().." "..databases.version:upper_first().." v2")
                hud[1]:drag(prefix[1], 13)
                    
                local anim_name = render.text:default(2.5, prefix[2], r3,g3,b3,255, r,g,b,255)
                renderer.text(x, y, 255,255,255,255, "a", nil, unpack(anim_name))
                renderer.text(x + prefix[1] + 3, y, 255,255,255,255, "a", nil, "/ "..user_lua)
            end,
            run = function(self)
                if not menu.vis.widgets:get() then return end 

                if menu.vis.widgets_type:get("Force text watermark") then 
                    self:text()
                end

                if menu.vis.widgets_type:get("Watermark") then 
                    if globals.curtime() % 1 > 0.93 then 
                        self.fps = math.floor(1 / globals.frametime() + 0.5)
                    end

                    local x, y = hud[2]:get()
                    local rgb = "\a"..math.to_hex(r, g, b, 255) -- get_real_time
                    local user = render:measures(0, nil, rgb.." \aFFFFFFFF"..user_lua)
                    local time = render:measures(0, nil, rgb.." \aFFFFFFFF"..util:get_real_time())
                    local ping = render:measures(0, nil, rgb.." \aFFFFFFFF"..math.floor(client.latency() * 1000))
                    local ffps = render:measures(0, nil, rgb.." \aFFFFFFFF"..self.fps)
                    
                    local width = user[1] + time[1] + ping[1] + ffps[1] + 34
                    hud[2]:drag(width, 25)

                    render:blur(x, y, width, 25)
                    render.rect:rect(x, y, width, 25, {25,25,25,150}, 4)
                    render.rect:outline(x, y, width, 25, {r,g,b,255}, 4, 1) 
                    
                    renderer.text(x + 8, y + 6, 255,255,255,255, "", nil, user[2])
                    renderer.text(x + user[1] + 14, y + 6, 255,255,255,255, "", nil, time[2])
                    renderer.text(x + user[1] + time[1] + 20, y + 6, 255,255,255,255, "", nil, ping[2])
                    renderer.text(x + user[1] + time[1] + ping[1] + 26, y + 6, 255,255,255,255, "", nil, ffps[2])
                end
            end
        },
        crosshair = {
            run = function(self)
                if not menu.vis.crosshair:get() or util:not_me() then 
                    return 
                end 

                local me = util:get_me()
                local y = hud[4]:get_y()
                local state = render:measures(0, "a-", util:state():upper())
                local style = menu.vis.cross.type:get()

                hud[4]:drag(60, 50)

                local dt_clr = {animate:color("cross.dt", {r, (util:charge() and g or 0), (util:charge() and b or 0),255}, 0.1)}
                local qp_clr = {animate:color("cross.peek", {200, (aa_funcs.get_double_tap() and 200 or 0), (aa_funcs.get_double_tap() and 200 or 0),255}, 0.1)} 

                local binds = {
                    {
                        name = "DT",
                        clr = {dt_clr[1], dt_clr[2], dt_clr[3]},
                        active = ui.get(refs.rage.dt.value[1]) and ui.get(refs.rage.dt.value[2]) and not ui.get(refs.rage.faceduck[1]) 
                    },
                    {
                        name = "OSAA",
                        clr = {dt_clr[1], dt_clr[2], dt_clr[3]}, 
                        active = ui.get(refs.rage.osaa[1]) and ui.get(refs.rage.osaa[2]) and not ui.get(refs.rage.faceduck[1]) 
                    },
                    {
                        name = "MD",
                        clr = {255, 255, 255},
                        active = ui.get(refs.rage.md.ovr[1]) and ui.get(refs.rage.md.ovr[2]) 
                    },
                    {
                        name = "FD",
                        clr = {222, 222, 222},
                        active = ui.get(refs.rage.faceduck[1])
                    },
                    {
                        name = "QP",
                        clr = {qp_clr[1], qp_clr[2], qp_clr[3]},
                        active = ui.get(refs.rage.peek[1]) and ui.get(refs.rage.peek[2])
                    }
                }

                if style == "Yaw-based" then 
                    local part = {
                        "\a"..math.to_hex(animate:color("cross.part1", antiaim.yaw_last <= 0 and {r,g,b,255} or {255,255,255,255}, 0.1)),
                        "\a"..math.to_hex(animate:color("cross.part2", antiaim.yaw_last >= 0 and {r,g,b,255} or {255,255,255,255}, 0.1))
                    }

                    renderer.text(x/2 + databases.scope*40, y + 10, 255,255,255,255,"cb",nil,part[1].."ember"..part[2].."lash°")
                elseif style == "Simple" then 
                    local anim_name = render.text:default(1.8, "emberlash", r,g,b,255, r3,g3,b3,255)
                    renderer.text(x/2 + databases.scope*40, y + 10, 255,255,255,255,"cba",nil,unpack(anim_name))

                    if menu.vis.cross.flag:get("Condition") then 
                        renderer.text(x/2 - (state[1]/2*(1-databases.scope)) + 13*databases.scope, y + 18, 255,255,255,255,"a-",nil,state[2])
                    end

                    local voffset = 0
                    if menu.vis.cross.flag:get("Binds") then 
                        for _, bind in ipairs(binds) do
                            local name = render:measures(0, "a-", bind.name)
                            local isbind = animate:number("cross.active:"..bind.name, bind.active and 1 or 0, 0.1)
                            local offset = isbind*10
                            voffset = voffset + offset

                            if isbind > 0.1 then 
                                renderer.text(x/2-(name[1]/2*(1-databases.scope))+13*databases.scope, y + 20 + voffset, bind.clr[1], bind.clr[2], bind.clr[3], isbind*255, "a-", nil, name[2])
                            end
                        end
                    end
                end
            end
        },
        arrows = {
            run = function(self)
                if not menu.vis.arrows:get() or util:not_me() then return end

                local type = menu.vis.arrow.type:get()
                local tips = menu.vis.arrow.sides
                local pos_x = hud[3]:get_x()
                hud[3]:drag(22, 22)

                local manual = tips:get("Manuals") and util:manual() or 0
                local right = animate:number("arrows.right", (manual == 90 or pui.menu_open) and 1 or 0, 0.1)
                local left = animate:number("arrows.left", (manual == -100 or pui.menu_open) and 1 or 0, 0.1)
                local offset, scp = x/2-pos_x, databases.scope

                if right > 0.1 then
                    if type == "Pointers" then 
                        renderer.text(x/2 - offset, y/2 - 19 - (scp*20), r,g,b,right*255,"a+",nil,"∘")
                        renderer.text(x/2 - offset + 6, y/2 - 19 - (scp*20), r,g,b,right*255,"a+",nil,"≻")
                    else 
                        renderer.text(x/2 - offset + 2, y/2 - 18 - (scp*20), r,g,b,right*255,"a+",nil,"⮞")
                    end
                end

                if left > 0.1 then 
                    if type == "Pointers" then 
                        renderer.text(x/2 + offset - 10, y/2 - 19 - (scp*20), r,g,b,left*255,"a+",nil,"∘")
                        renderer.text(x/2 + offset - 19, y/2 - 19 - (scp*20), r,g,b,left*255,"a+",nil,"≺")
                    else 
                        renderer.text(x/2 + offset - 18, y/2 - 18 - (scp*20), r,g,b,left*255,"a+",nil,"⮜")
                    end
                end
            end
        },
        damage = {
            dmg = 0,
            run = function(self)
                if not menu.vis.damage:get() or util:not_me() then return end 

                local dmg, flag
                local marker = false
                local tips = {
                    menu.vis.dmg.type:get(), 
                    menu.vis.dmg.flag:get(),
                    ui.get(refs.rage.md.ovr[2])
                }

                if tips[2] == "Small" then 
                    flag = "-"
                elseif tips[2] == "Normal" then 
                    flag = "a"
                elseif tips[2] == "Bold" then 
                    flag = "b"
                end

                if ui.get(refs.rage.md.ovr[1]) and tips[3] then
                    dmg = ui.get(refs.rage.md.ovr[3])
                else
                    dmg = refs.rage.md.damage[1]:get()
                end

                if tips[1] == "On damage" then 
                    if tips[3] then 
                        marker = true
                    end
                else
                    marker = true
                end

                self.dmg = tips[1] == "On damage" and dmg or math.floor(animate:lerp(self.dmg, dmg, 0.12))

                if marker then 
                    renderer.text(x/2+7, y/2-16, 255,255,255,255,flag,nil,self.dmg)
                end
            end
        },
        scope = {
            run = function(self)
                if util:not_me() or not menu.vis.custom_scope:get() then return end
                local me = util:get_me()
                if entity.get_prop(me, "m_bIsScoped") ~= 1 then return end
    
                local tips = {
                    left = menu.vis.scope.no_lines:get("Left"),
                    right = menu.vis.scope.no_lines:get("Right"),
                    up = menu.vis.scope.no_lines:get("Up"),
                    bottom = menu.vis.scope.no_lines:get("Bottom"),
                    offset = menu.vis.scope.offset:get() * y / 1080,
                    size = menu.vis.scope.size:get() * y / 1080,
                }
    
                local alpha = 1
                local color = {255,255,255,255}
    
                if not tips.left then 
                    renderer.gradient(x/2 - tips.size + 2, y / 2, tips.size - tips.offset, 1, color[1], color[2], color[3], 0, color[1], color[2], color[3], alpha*color[4], true)
                end
                if not tips.right then 
                    renderer.gradient(x/2 + tips.offset, y / 2, tips.size - tips.offset, 1, color[1], color[2], color[3], alpha*color[4], color[1], color[2], color[3], 0, true)
                end
    
                if not tips.up then 
                    renderer.gradient(x / 2, y/2 - tips.size + 2, 1, tips.size - tips.offset, color[1], color[2], color[3], 0, color[1], color[2], color[3], alpha*color[4], false)
                end
                if not tips.bottom then
                    renderer.gradient(x / 2, y/2 + tips.offset, 1, tips.size - tips.offset, color[1], color[2], color[3], alpha*color[4], color[1], color[2], color[3], 0, false)
                end
            end
        }
    }
    --[[
    breaker = gaa:checkbox("Animations legs"), 
    breaker_help = {
        type = gaa:combobox("\nanims:type", {"Off", "Static", "Moonwalk", "Jitter"}),
        adds = gaa:multiselect("\nanims:add", {"Pitch 0 on land", "Static in air", "Moonwalk+"}
        )
                     ]]
    funcs.pre_render = {
        leg_breaker = {
            state =false,
            work = function(self)
                if util:not_me() then 
                    return 
                end

                local me = util:get_me()
                local animstate = entity.get_animstate(me)

                if not animstate then
                    return
                end

                local ltype = menu.feature.misc.breaker_help.type:get()
                local adds = menu.feature.misc.breaker_help.adds
                
                if adds:get("Pitch 0 on land") and not util:in_air(me) and animstate.hit_in_ground_animation then 
                    entity.set_prop(me, "m_flPoseParameter", 0.5, 12)
                end

                if adds:get("Static in air") and util:in_air(me) then
                    entity.set_prop(me, "m_flPoseParameter", 1, 6)
                end

                if ltype == "Static" then 
                    refs.aa.fl.lg[1]:override("Always slide")
                    entity.set_prop(me, "m_flPoseParameter", 0, 0)
                elseif ltype == "Moonwalk" and util:in_air(me) then 
                    refs.aa.fl.lg[1]:override("Never slide")
                    entity.set_prop(me, "m_flPoseParameter", 0, 7)

                    local left = entity.get_animlayer(me, 6)
                    local right = entity.get_animlayer(me, 4)

                    left.weight = 1
                    right.weight = 0

                    if adds:get("Moonwalk+") then 
                        local cycle = globals.realtime() * 0.7 % 2

                        if cycle > 1 then
                            cycle = 1 - (cycle - 1)
                        end

                        left.cycle = cycle
                    end
                elseif ltype == "Jitter" then 
                    refs.aa.fl.lg[1]:override("Always slide")

                    if globals.tickcount() % 4 > 1 then
                        entity.set_prop(me, "m_flPoseParameter", 0, 0)
                    end
                elseif ltype == "Earthquake" then 
                    local anim = entity.get_animlayer(me, 12)

				    anim.weight = client.random_float(0, 2.5)
                end
            end,
            run = function(self)
                local enabled = menu.feature.misc.breaker:get()
                
                if self.state ~= enabled then
                    self.state = enabled
                end
    
                if enabled then
                    self:work()
                end
            end
        }
    }
    funcs.override_view = {
        scope = {
            zoom = 0,
            run = function(self, player)
                if util:not_me() or not menu.vis.anim_zoom:get() then 
                    return 
                end
                
                local me = util:get_me()
                local scoping = entity.get_prop(me, "m_bIsScoped") == 1
                
                local tips = {
                    speed = menu.vis.zoom.speed:get() / 150,
                    fov = menu.vis.zoom.fov:get(),
                    rfov = ui.get(refs.misc.fov)
                }
                
                local target_zoom = tips.rfov - (scoping and tips.fov or 0)
                
                if not scoping and (tips.rfov - 0.5 < self.zoom) then
                    return
                end

                self.zoom = animate:lerp(self.zoom, target_zoom, tips.speed)
                player.fov = self.zoom
            end,
        },
    }
    funcs.predict_command = {
        defensive = {
            restore = function(self)
                defensive:reset()
            end,
            run = function(self)
                call_reg.round_start:set(function()
                    self:restore()
                end)

                defensive:normalize()
            end
        },
        resolver = {
            state = false,
            records = {},
            fix = function(self, ent, realtime)
                local entpich, entyaw = entity.get_prop(ent, "m_angEyeAngles")
                return {
                    time = realtime,
                    pos = entity.get_prop(ent, "m_flPoseParameter", 11) * 120 - 60,
                    pitch = entpich,
                    yaw = entyaw
                }
            end,
            work = function(self)
                local players = {}
                client.update_player_list()
    
                for i = 1, #players do
                    local entity = players[i]
                    local steam = entity.get_steam64(players[i])
    
                    if entity.is_enemy(entity) and steam then
                        local sim1, sim2 = entity.get_simtime(entity)
                        local tick1, tick2 = toticks(sim1), toticks(sim2)
                        local records = self.records[steam]
                        local gather = self:fix(entity, tick1)
                        local last
    
                        last = records and records.prev
    
                        if not records then
                            self.records[steam] = {
                                diff = tick1 - tick2,
                                prev = gather
                            }
                            records = self.records[steam]
                        else
                            records.diff = tick1 - tick2
                        end
    
                        local baim
    
                        if records ~= nil and records.diff >= 0 and records.diff <= 2 and not entity.is_lethal(entity) then
                            local anim = entity.get_animstate(entity)
                            local yaw = util:normalize_yaw(gather.yaw - anim.goal_feet_yaw)
    
                            gather.gfy = anim.goal_feet_yaw
    
                            if yaw ~= 0 then
                                baim = (yaw > 0 and -1 or 1) * entity.get_max_desync(anim)
    
                                if baim then
                                    print(entity.get_player_name(entity).." body:"..baim)
                                    plist.set(entity, "Force body yaw value", baim)
                                end
                            end
                        end
    
                        records.active = baim ~= nil
    
                        plist.set(entity, "Force body yaw", baim ~= nil)
                        plist.set(entity, "Correction active", true)
    
                        records.prev = gather
                    end
                end
            end,
            refresh = function(self)
                table.clear(self.records)
            end,
            restore = function(self)
                for player = 1, 64 do
                    plist.set(player, "Force body yaw", false)
                end
    
                self.records = {}
            end,
            run = function(self)
                local enabled = menu.feature.aim.resolver:get()
                
                if self.state ~= enabled then 
                    if not enabled then 
                        self:restore()
                    end
                    self.state = enabled
                end
    
                if enabled then 
                    call_reg.round_start:set(function()
                        self:restore()
                    end)
                    self:work()
                end
            end
        }
    }

    funcs.setup_command = {
        charge_fix = {
            state = false,
            set = function(self, value)
                ui.set(refs.rage.enable, value)
            end,
            work = function(self)
                local target = client.current_threat()
                local me = util:get_me()

                if util:charge() and target and util:in_air(me) and util:is_flag(target, "HIT") then 
                    self:set(false)
                else
                    self:set(true)
                end
            end,
            restore = function(self)
                self:set(true)
            end,
            run = function(self)
                local enabled = menu.feature.aim.charge_fix:get()

                if self.state ~= enabled then 
                    if not enabled then 
                        self:restore()
                    end
                    self.state = enabled
                end
    
                if enabled then 
                    self:work()
                end
            end
        },
        miss_fix = {
            work = function(self, cmd)
                local target = client.current_threat()
                local me = util:get_me()

                if target and util:is_flag(target, "HIT") then 
                    cmd.force_defensive = true
                end
            end,
            run = function(self, cmd)
                local enabled = menu.feature.aim.miss_fix:get()
    
                if enabled then 
                    self:work(cmd)
                end
            end
        }
    }

    funcs.net_update_end = {
        defensive = {
            run = function(self)
                defensive:activate()
            end
        },
        clantag = {
            state = false, last = 0,
            list = {
                "@",
                "#e",
                "|em",
                "@embe",
                "#ember",
                "|ember|",
                "@emberlas",
                "#emberlash",
                "emberlash", "emberlash", "emberlash", "emberlash", "emberlash",
                "emberlas%",
                "emberl&",
                "ember*",
                "embe#",
                "emb@",
                "em|",
                "e%",
            },
            restore = function(self)
                client.set_clan_tag()
                refs.misc.clantag:set_enabled(true)
                refs.misc.clantag:override()
            end,
            run = function(self)
                local enabled = menu.feature.misc.clantag:get()

                if self.state ~= enabled then
                    if not enabled then
                        self:restore()
                    end
                    self.state = enabled
                end

                if enabled then
                    self:work()
                end
            end,
            work = function(self)
                local current = math.round(globals.curtime() * 3) % #self.list + 1
    
                if current == self.last then
                    return
                end
    
                self.last = current
    
                client.set_clan_tag(self.list[current])
                refs.misc.clantag:override(false)
                refs.misc.clantag:set_enabled(false)
            end
        }
    }
    funcs.player_death = {
        trashtalk = {
            phrases = {
                ["kill"] = {
                    {"𝙀𝙢𝙗𝙚𝙧𝙡𝙖𝙨𝙝 𝙥𝙧𝙚𝙢𝙞𝙪𝙢 𝙥𝙧𝙚𝙙𝙞𝙘𝙩𝙞𝙤𝙣 𝙩𝙚𝙘𝙝𝙣𝙤𝙡𝙤𝙜𝙞𝙚𝙨 ◣◢ :crown:", "ʙʏ ʙᴜʏɪɴɢ ᴇᴍʙᴇʀʟᴀsʜ, ʏᴏᴜ'ʀᴇ ʙᴜʏɪɴɢ ᴀ ᴛɪᴄᴋᴇᴛ ᴛᴏ ʜᴇʟʟ.", "The Flame will never die, for I am EMBERLASH"},
                    {"☾ 𝕘𝕖𝕥 **𝕖𝕕 𝕓𝕪 𝕕𝕖𝕧𝕚𝕝 #𝕖𝕞𝕓𝕖𝕣𝕝𝕒𝕤𝕙 ~ 𝕟𝕖𝕥𝕨𝕠𝕣k ☾   "}, {"твоя сила – лишь иллюзия перед властью Emberlash."},
                    {"теперь сам Дьявол объявил на тебя охоту #𝕖𝕞𝕓𝕖𝕣𝕝𝕒𝕤𝕙 ☾"}, {"#𝙚𝙢𝙗𝙚𝙧𝙡𝙖𝙨𝙝 𝙘𝙤𝙙𝙚 𝙬𝙖𝙨 𝙬𝙧𝙞𝙩𝙩𝙚𝙣 𝙗𝙮 𝐵𝓁𝑜𝑜𝒹 𝑜𝒻 𝐿𝓊𝒸𝒾𝒻𝑒𝓇 ٩(×̯×)۶"},
                    {"опять слезы % ?","умоляй моих дьяволов выдать тебе emberlash"}, {"это не битва, %","это исповедь, emberlash выслушает все твои грехи. "},
                    {"𝕖𝕞𝕓𝕖𝕣𝕝𝕒𝕤𝕙 𝕚𝕤 𝕥𝕙𝕖 𝕓𝕖𝕤𝕥 𝔸𝔸 𝔸𝔸 𝔸𝔸 𝔸𝔸 𝔸𝔸 𝔸𝔸 𝔸"}, {"♆ Сливы Дьяволиц -> .𝕘𝕘/𝔼𝕞𝕓𝕖𝕣𝕝𝕒𝕤𝕙 ♆"}, {"𝕟𝕠 𝕤𝕜𝕚𝕝𝕝 𝕟𝕖𝕖𝕕 𝕛𝕦𝕤𝕥 𝕖𝕞𝕓𝕖𝕣𝕝𝕒𝕤𝕙"},
                    {"Это не борьба за выживание, это жертва Emberlash.", "1"}, {"𝕘𝕠𝕕 𝕘𝕒𝕧𝕖 𝕞𝕖 𝕡𝕠𝕨𝕖𝕣 𝕠𝕗 𝕣𝕖𝕫𝕠𝕝𝕧𝕖𝕣 𝔼𝕄𝔹𝔼ℝ𝕃𝔸𝕊ℍ "}, {"っ◔◡◔)っ ♥️ enjoy die to emberlash and spectate me ♥️"},
                    {"𝕚 𝕒𝕞 𝕚𝕥”𝕤 𝕕𝕠𝕟𝕥 𝕝𝕠𝕤𝕖 ◣◢ #emberlash", "god may forgive you but emberlash resolver wont (◣_◢)"}, {"𝕓𝕪 𝕤𝕚𝕘𝕟𝕚𝕟𝕘 𝕒 𝕔𝕠𝕟𝕥𝕒𝕔𝕥 𝕨𝕚𝕥𝕙 𝕥𝕙𝕖 𝕕𝕖𝕧𝕚𝕝 𝕪𝕠𝕦 𝕒𝕣𝕖 𝕕𝕠𝕠𝕞𝕖𝕕 𝕥𝕠 𝕕𝕚𝕖 #emberlash"},
                    {"ＹＯＵ ＷＩＳＨ ＹＯＵ ＨＡＤ E M B E R L A S H Ｕ ＨＲＳＮ", "winning not possibility, sry #emberlash"}, {"𝙙𝙖𝙮 666 𝗲𝗺𝗯𝗲𝗿𝗹𝗮𝘀𝗵 𝙨𝙩𝙞𝙡𝙡 𝙣𝙤 𝙧𝙞𝙫𝙖𝙡𝙨"}, {"once this game started 𝔂𝓸𝓾 𝓵𝓸𝓼𝓮𝓭 𝓪𝓵𝓻𝓮𝓭𝔂 #emberlash"},
                    {"ＹＯＵ ＨＡＤ ＦＵＮ ＬＡＵＧＨＩＮＧ ＵＮＴＩＬ ＮＯＷ"}, {"EMBERLASH SEASON ON TRƱE #WITCHHOUSE AND #EVIL RADIO vibe 2025™"},{"rock star lifestyle #EMBERLASH"},
                    {"% иди спргыни с крыши хуевый", "тебя моя эмберка экслюзив", "убила нахуй"}, {"молодец %", "молись чтобы тебе дали эмберлаш"}, {"долбаеб % я тебя убил", "с эмберлашом экслюзив"},
                    {"i love emberlash", "do you love it?"}, {"zｚＺ","im cursed, % killed"}, {"family-friendly lua -> .gg/emberlash"}, {"1","теперь думай кто это написал)))"},{"z бы тебя похвалил","a везением"},
                    {"мы летим низко","снова палю в экран","снова вижу этот дискорд",".gg/emberlash"}, {"1", "бомж ты куда"}, {"моя сила emberlash"}, {"это происходит в действительности?","1"}, {"ты - как бесплатный emberlash"},
                    {"я смотрю", "если бы твой скилл зависел от интеллекта","ты не победил"}, {"я просто протестировал баг на перерождение"}, {"ты ошибка природы", "каково жить с осознанием"},
                    {"если твои успехи в игре перевести в реальные достижения","ты бы был миллионером… в минусах"}, {"мой труп был в 100 раз полезнее команды"}, 
                    {"это было настолько случайно, что даже твои родители не так удивились, когда ты родился"}, {"eсли бы IQ был оружием", "где тебя научили стрелять"},
                    {"если бы победы давали смысл жизни", "интеллект у тиа бл такой же плоский, как шахматная доска в аду"}, {"ты меня убил","который заигрался и случайно открыл портал в ад"},
                    {"The Flame will never die, for I am EMBERLASH"}, {"карма"}, {"переигран", "школьник ебучий"}, {"иди поплачь", "тут начнешь", "или к маме пойдешь"}
                },
                ["death"] = {
                    {"в этом раунде эмберлашик не прокерил","значит прокерит в следующем"}, {"какой же ты хуевый","НУ Я МИССАЮ ЕМУ В РУКУ А ОН ДУМАЕТ","ЧТО ЭТО ЛЦ"},
                    {"ну ты говно ебучее", "под неймом % сидит", "emberlash - missed shot due to right leg"}, {"найс ты трекаешь 200бектрек", "хуесос жирный %"},
                    {"опять говно убивает"}, {"ты че ваще далбаеб?","я твою мать ебал","хуесос тупой ублюдок"}, {"ну он же реально","подрывате себя","и я не могу попасть"},
                    {"опять говно убивает","я просто не могу уже"}, {"ну как ты мои антиаимы тапаешь в эмберлаше??", "че ебу дал"}, {"я не могу в тебя попасть","сделаешь мне такие же пресетики?"},
                    {"сын шлюхи хуевой","я просто не знаю как тебя ещё назвать"}, {"че бля дал"}, {"НУ ЧТО ТЫ ЗА ДАЛБАЕБ"},
                },
            },
            work = function(self, type, entindex)
                local group = math.random_string(self.phrases[type])

                for i, phrase in ipairs(group) do
                    client.delay_call(i * 1.1, function()
                        local target_name = entity.get_player_name(entindex) or "бичара"
                        local formatted_phrase = phrase:gsub("%%", target_name)
                        
                        client.exec("say " .. formatted_phrase)
                    end)
                end
            end,
            run = function(self, event)
                local me = util:get_me()
        
                if util:not_me() then return end
            
                local active = menu.feature.misc.trashtalk:get()
                local victim = client.userid_to_entindex(event.userid)
                local attacker = client.userid_to_entindex(event.attacker) 
                local db = database.read(databases.kill)
            
                if attacker == me and victim ~= me then 
                    db = db + 1
                    if active and menu.feature.misc.trashtalk_type:get("On Kill") then 
                        self:work("kill", victim)
                    end
                end
        
                if active and menu.feature.misc.trashtalk_type:get("On Death") and attacker ~= me and victim == me then
                    self:work("death", attacker)
                end

                database.write(databases.kill, db)
            end
        }
    }
    
    local hitboxes = {[0] = 'body', 'head', 'chest', 'stomach', 'left arm', 'right arm', 'left leg', 'right leg', 'neck', '?', 'gear'}

    funcs.aim_hit = {
        hitten = {
            run = function(self, event)
                if not (menu.vis.widgets:get() and menu.vis.widgets_type:get("Event logger") and menu.vis.markers:get() and menu.vis.markers_type:get("On hit")) then return end
    
                local target = entity.get_player_name(event.target)
                local hitbox = hitboxes[event.hitgroup] or "?"
                local hp = math.max(0, entity.get_prop(event.target, 'm_iHealth'))
                local damage = event.damage
                local bt = globals.tickcount() - event.tick
                local hc = math.floor(event.hit_chance)
    
                if hp ~= 0 then 
                    notification:create("", "Hit $"..target.."$ $in$ $"..hitbox.."$ $for$ $"..damage.."", 3000)
                    printf("Hit "..target.." in ".. hitbox .." for "..damage..", "..bt.."bt, "..hc.."hc")
                else 
                    printf("Kill "..target.." in ".. hitbox ..", "..bt.."bt, "..hc.."hc")
                    notification:create("", "Killed $"..target.."$ $in$ $"..hitbox, 3200)
                end
            end
        }
    }
    funcs.aim_miss = {
        missed = {
            run = function(self, shot)
                local db = database.read(databases.miss)
                db = db + 1
                database.write(databases.miss, db)

                if not (menu.vis.widgets:get() and menu.vis.widgets_type:get("Event logger") and menu.vis.markers:get() and menu.vis.markers_type:get("On miss")) then return end
    
                local target = entity.get_player_name(shot.target)
                local hitbox = hitboxes[shot.hitgroup] or "?"
                local reason = shot.reason
                local bt = globals.tickcount() - shot.tick
                local hc = math.floor(shot.hit_chance)
                local clr = reason == "spread" and {255,255,0} or {255,0,0}
                printf("Missed "..target.." in ".. hitbox .." due to "..reason..", "..bt.."bt, "..hc.."hc")
                notification:create("", "Missed $"..target.."$ $in$ $"..hitbox.."$ $due$ $"..reason, 3600, clr)
            end
        }
    }

    for call_name, call in next, funcs do
        if call_name ~= "null" then 
            for func_name, func_data in next, call do
                if func_data.run then
                    call_reg[call_name]:set(function(...)
                        local args = {...}
                        if #args > 0 then
                            func_data:run(args[1])
                        else
                            func_data:run()
                        end
                    end)
                end

                if func_data.restore then 
                    if func_data.state then 
                        call_reg.shutdown:set(function()
                            func_data:restore()
                        end)
                    end
                end
            end
        end
    end

    funcs.null = {
        filter = {
            set = function(elemt)
                cvar.con_filter_enable:set_int(elemt.value and 1 or 0)
                cvar.con_filter_text:set_string(elemt.value and "memberlash" or "")
            end,
            run = function(self)
                menu.feature.misc.filter:set_callback(self.set, true)
            end
        }
    }

    for name, func in next, funcs.null do
		func:run()
	end

    local extra = {}

    extra = {
        data = {
            state = false,
            work = function(self)
                local me = util:get_me()
                databases.scope = animate:lerp(databases.scope, entity.get_prop(me, "m_bIsScoped") == 1 and 1 or 0, 0.08)
            end,
            restore = function(self)
                databases.scope = 0
            end,
            run = function(self)
                local enabled = not util:not_me()
                
                if self.state ~= enabled then 
                    if not enabled then 
                        self:restore()
                    end
                    self.state = enabled
                end

                if enabled then 
                    self:work()
                end
            end
        },
        complete = function(self)
            call_reg.shutdown:set(function()
                cvar.con_filter_enable:set_int(0)
				cvar.con_filter_text:set_string("")
                gui:show(true)
            end)

            if not pui.menu_open then return end

            local defclr = menu.vis.color.color_type:get() == "Default"
                
            if defclr then
                r, g, b = menu.vis.color.clr_def:get()
                r1, g1, b1 = r, g, b
                r2, g2, b2 = r, g, b
                r3, g3, b3 = r, g, b
            else
                r, g, b = menu.vis.color.gradient.clr1:get()
                r1, g1, b1 = menu.vis.color.gradient.clr2:get()
                r2, g2, b2 = menu.vis.color.gradient.clr3:get()
                r3, g3, b3 = menu.vis.color.gradient.clr4:get()
            end

            gui:show(false)
        
            local tabs = {
                home = render:paint_tab(menu.home.tab, {"Info", "Visuals"}, {"", ""}),
                aa = render:paint_tab(menu.aa.tab, {"Builder", "Defensive", "Settings"}, {"", "", ""}),
                feature = render:paint_tab(menu.feature.tab, {"Aimbot", "Misc"}, {"", ""})
            }
            
            menu.home.info.killed:set("\v \r Killed on time \v"..database.read(databases.kill))
            menu.home.info.misses:set("\v \r Missed on time \v"..database.read(databases.miss))

            menu.home.tab_1:set(tabs.home)
            menu.aa.tab_1:set(tabs.aa)
            menu.feature.tab_1:set(tabs.feature)
        end   
    }

    call_reg.paint:set(function()
        extra.data:run() 
    end)

    call_reg.paint_ui:set(function()
        extra:complete()
    end)

    local configs = {
        update_name = function(self)
            local info = menu.home.config.list()
            local count = 0
            local configs  = database.read(databases.cfg) or {}

            for k, v in pairs(configs) do
                if info == count then
                    return menu.home.config.name(k)
                end

                count = count + 1
            end
            return nil
        end,
        update_cfgs = function(self)
            local names = {}
            local configs = database.read(databases.cfg) or {}

            for k, v in pairs(configs) do
                table.insert(names, k)
            end

            if #names > 0 then
                menu.home.config.list:update(names)
            end

            self:update_name()
        end,
        export = function(self, notifyt)
            local cfg = pui.setup({menu.home, menu.aa, menu.vis, menu.feature})
            local data = cfg:save()
            
            local encrypted = base64.encode(json.stringify(data))
        
            if notifyt then
                print("Config successfully exported!")
                notification:create("", "Config successfully $exported$!", 4000)
            end
            return encrypted
        end,
        import = function(self, encrypted, notifyt)
            local decoded = base64.decode(encrypted)
            
            local success, data = pcall(json.parse, decoded)
            if not success then
                if notifyt then
                    print("Config data invalid, try other!")
                end
                return
            end
        
            local cfg = pui.setup({menu.home, menu.aa, menu.vis, menu.feature})
            cfg:load(data)
        
            if notifyt then
                print("Config successfully imported!")
                notification:create("", "Config successfully $imported!$", 4000)
            end
        end,
        save = function(self)
            local name = menu.home.config.name()

            if name:match("%w") == nil then
                print("Please, type other name for config")
                notification:create("", "Please, type other name for $config$", 4000, {177,177,0})
                return
            end

            print("Config "..name.." succsesfully saved!")
            notification:create("", "Config $"..name.."$ $successfully$ $saved!$", 4000)

            local data = self:export(false)
            local configs = database.read(databases.cfg) or {}
            configs[name] = data

            database.write(databases.cfg, configs)
            self:update_cfgs()
        end,
        load = function(self)
            local name = menu.home.config.name()

            if name:match("%w") == nil then
                return print("Please, select config for load!")
            end

            local configs = database.read(databases.cfg) or {}
            self:import(configs[name], false)

            if configs[name] then 
                print("Config "..name.." succsesfully loaded!")
                notification:create("", "Config $"..name.."$ $successfully$ $loaded!$", 4000)
            else 
                print("Config "..name.." not found!")
                notification:create("", "Config $"..name.."$ $not$ $found!$", 4000, {255,0,0})
            end
        end,
        trash = function(self)
            local name = menu.home.config.name()

            if name:match("%w") == nil then
                print("Please, select config for trash!")
                return
            end
        
            local configs = database.read(databases.cfg) or {}
        
            if configs[name] then
                configs[name] = nil
                database.write(databases.cfg, configs)
                print("Config "..name.." succsesfully deleted!")
                notification:create("", "Config $"..name.."$ $successfully$ $deleted!$", 4000, {255,0,0})
            else
                print("Config "..name.." not found!")
                notification:create("", "Config $"..name.."$ $not$ $found!$", 4000, {255,0,0})
                return
            end

            if not next(configs) then
                menu.home.config.list:update({})
                menu.home.config.name("")
            else
                self:update_cfgs()
            end
        end
    } configs:update_cfgs()

    menu.home.config.list:set_callback(function()
        configs:update_cfgs()
    end)

    menu.home.config.export:set_callback(function()
        local data = configs:export(true)

        clipboard.set(data)
    end)

    menu.home.config.import:set_callback(function()
        configs:import(clipboard.get(), true)
    end)

    menu.home.config.save:set_callback(function()
        configs:save()
    end)

    menu.home.config.load:set_callback(function()
        configs:load()
    end)

    menu.home.config.delete:set_callback(function()
        configs:trash()
    end)
end)()