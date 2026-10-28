-- This fork was originally written by David_G (kestral246@gmail.com)

local mod = {
	players = {},
	compass_search = function(string)
		if string.sub(string, 0, 12) == "realcompass:" then
			return true
		end
		return false
	end,
}

local function compass_item_globalstep()
	local players = core.get_connected_players()
	for _, player in ipairs(players) do
		local activewidth = player:hud_get_hotbar_itemcount()
		local gotacompass = false
		local wielded = false
		local activeinv = nil
		local stackidx = 0
		--[[
		First check to see if the user has a compass, because if they don't
		there is no reason to waste time calculating bookmarks or spawnpoints.
		]]
		local wielded_item = player:get_wielded_item():get_name()
		if mod.compass_search(wielded_item) then
			-- if the player is wielding a compass, change the wielded image
			wielded = true
			stackidx = player:get_wield_index()
			gotacompass = true
		else
			-- check to see if compass is in active inventory
			if player:get_inventory() then
				for i = 1, activewidth do
					local stack = player:get_inventory():get_stack("main", i)
					if mod.compass_search(stack:get_name()) then
						activeinv = stack -- store the stack so we can update it later with new image
						stackidx = i -- store the index so we can add image at correct location
						gotacompass = true
						break
					end
				end
			end
		end

		if gotacompass then
			local dir = player:get_look_horizontal()
			local angle_relative = math.deg(dir)
			local compass_image = math.floor((angle_relative / 22.5) + 0.5) % 16

			--update compass image to point at target
			if wielded then
				player:set_wielded_item("realcompass:" .. compass_image)
			elseif activeinv then
				player:get_inventory():set_stack("main", stackidx, "realcompass:" .. compass_image)
			end
		end
	end
end

local time_since = 0
local compass = {
	type = "compass",
	hud_elem_type = "compass",
	position = { x = 0.5, y = 0.5 },
	name = "compass",
	text = "realcompass_HUD.png", -- image
	direction = 1,
	size = { x = 16, y = 16 },
	z_index = 0,
	hideable = true,
}

local function compass_hud_globalstep(dtime)
	if core.settings:get_bool("realcompass.hud", true) then
		time_since = time_since + dtime
		if time_since > 3 then
			time_since = 0
			for _, player in ipairs(core.get_connected_players()) do
				local inv = player:get_inventory()
				local name = player:get_player_name()
				for _, stack in ipairs(inv:get_list("main")) do
					if mod.compass_search(stack:get_name()) and not mod.players[name].has_hud then
						mod.players[name].has_hud = true
						mod.players[name].hud_id = player:hud_add(compass)
						break
					elseif not mod.compass_search(stack:get_name()) then
						mod.players[name].has_hud = false
					end
				end
				if (not mod.players[name].has_hud) and mod.players[name].hud_id then
					player:hud_remove(mod.players[name].hud_id)
				end
			end
		end
	end
end

local images = {
	"realcompass_0.png",
	"realcompass_1.png",
	"realcompass_2.png",
	"realcompass_3.png",
	"realcompass_4.png",
	"realcompass_5.png",
	"realcompass_6.png",
	"realcompass_7.png",
	"realcompass_8.png",
	"realcompass_9.png",
	"realcompass_10.png",
	"realcompass_11.png",
	"realcompass_12.png",
	"realcompass_13.png",
	"realcompass_14.png",
	"realcompass_15.png",
}

for i, img in ipairs(images) do
	local inv = 1
	if i == 1 then
		inv = 0
	end
	core.register_tool("realcompass:" .. (i - 1), {
		description = "Real Compass",
		inventory_image = img,
		wield_image = img,
		groups = { not_in_creative_inventory = inv },
	})
end

-- crafting recipe only works if default mod present.
if core.get_modpath("default") ~= nil then
	core.register_craft({
		output = "realcompass:0",
		recipe = {
			{ "", "default:steel_ingot", "" },
			{ "default:copper_ingot", "default:glass", "default:copper_ingot" },
			{ "", "default:copper_ingot", "" },
		},
	})
end

core.register_on_joinplayer(function(player)
	mod.players[player:get_player_name()] = {}
end)

core.register_on_leaveplayer(function(player)
	mod.players[player:get_player_name()] = nil
end)

core.register_globalstep(function(dtime)
	compass_item_globalstep()
	compass_hud_globalstep(dtime)
end)
