addresses = {
	--== this must be a link between the quest-text and the id ==--
	questGroup_offset = 0x4F0,
	--===========================================================--

	--== fixed the casting bar but i'm not sure, that the "player.casting" is completely fixed ==--
	castingBarPtr = 0xA6BBC8,
	castingBar_offset = 0xC,
	--===========================================================================================--

	game_time = 0x60b1e0, --[[{game_time}]]
	in_game = 0x672ed0, --[[{in_game}]]
	zone_id = 0x66dae0, --[[{zone_id}]]
	movement_speed = {
		base = 0x60da90, --[[{movement_speed_base}]]
		offset = 0x1498, --[[{movement_speed_offset}]]
	},
	collecting = {
		base = 0x6755e8, --[[{collecting_base}]]
		type = 0xc,
	},
	channel = {
		base = 0x6753f0, --[[{channel_base}]]
		id = 0xe4,
	},
	class_info = {
		base = 0x60fe30, --[[{class_info_base}]]
		offset = 0x438,
		size = 0x430,
		level = 0x28,
		tp = 0x10
	},
	currency = {
		base = 0x622C68,
	},
	crafting = {
		base = 0x60b0fc, --[[{crafting_base}]]
	},
	code_mod = {
		freeze_target = {
			base = 0x49d8f1, --[[{freeze_target_codemod}]]
			original_code = string.char(0x89, 0x86, 0x78, 0x02, 0x00, 0x00),
			replace_code = string.char(0x90, 0x90, 0x90, 0x90, 0x90, 0x90),
		},

		freeze_mousepos = {
			base = 0x231434, --[[{freeze_mousepos_codemod}]]
			original_code = string.char(0x89, 0x8E, 0xB4, 0x03, 0x00, 0x00, 0x89, 0x86, 0xB8, 0x03, 0x00, 0x00),
			replace_code = string.char(0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90),
		},

		freeze_clicktocast_mouseoffscreen = {
			base = 0x230c54, --[[{freeze_clicktocast_mouseoffscreen}]]
			original_code = string.char(0x7D, 0x0C),
			replace_code = string.char(0xEB, 0x40),
		},

		swimhack = {
			base = 0x4dc59, --[[{swimhack_codemod}]]
			original_code = string.char(0xC7, 0x83, 0xB4, 0x00, 0x00, 0x00, 0x03, 0x00, 0x00, 0x00),
			replace_code = string.char(0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90),
		},
	},
	exp_table = 0x66db9c, --[[{exp_table}]]
	psi = 0x60fdfc, --[[{psi}]]
	global_cooldown = {
		base = 0x60b1f0, --[[{global_cooldown_base}]]
		offset = 0x1a84, --[[{global_cooldown_offset}]]
	},
	actionbar = {
		base = 0x6754ec, --[[{actionbar_base}]]
		slot = {
			size = 0x14,
			type = 0x0,
			id = 0x4,
		},
		size_per_class = 0x640,
		offset = 0xc,
	},
	gold = {
		base = 0x60fe30, --[[{gold_base}]]
		offset = 0x86bc, --[[{gold_offset}]]
	},
	game_root = {
		base = 0x609b84, --[[{game_root_base}]]
		mouseover_object_ptr = 0x75c,
		player_actual_speed = 0x790,
		ping = 0x7c0,
		input = {
			movement = 0xAAC,
		},
		mounting = 0xAE4,
		camera = {
			base = 0x47C,
			distance = 0x2e8,
			x = 0x104,
			y = 0x108,
			z = 0x10C,
			focus_x = 0x110,
			focus_y = 0x114,
			focus_z = 0x118,
		},
		camdistance = {0x454, 0x244},
		player = {
			base = 0x5a8, --[[{player_base}]]
		},
		combat_status = 0x74a,
		pawn = { -- These can apply to a player, monster, NPC, etc..
			id = 0x14,
			type = 0x18,
			name_ptr = 0x294,
			guid = 0x20,
			x = 0x28,
			y = 0x2c,
			z = 0x30,
			rotation_x = 0x34,
			rotation_y = 0x38,
			rotation_z = 0x3c,
			base_speed = 0x40, -- Your "normal" speed if you are moving
			speed = 0x1f0, -- 0 when standing still, actual speed when moving
			fading = 0x68,
			harvesting = 0x164,
			stance = 0x228,
			cast_full_time = 0x260,
			cast_time = 0x264,
			cast_spell_id = 0x25c,
			target = 0x278,
			owner_ptr = 0x280,
			pet_ptr = 0x284,
			hp = 0x2d4,
			previous_hp = 0x2dc,
			alive_flag = 0x2d7,
			max_hp = 0x2e4,
			energy1 = 0x2e8,
			max_energy1 = 0x2ec,
			energy2 = 0x2f0,
			max_energy2 = 0x2f4,
			class1 = 0x310,
			level = 0x314,
			class2 = 0x31c,
			level2 = 0x320,
			race = 0x328,
			lootable_flags = 0x3a0,
			attackable_flags = 0x39c,
			mount_ptr = 0x7c,
			swimming = {
				base = 0xf0,
				swimming = 0xb4
			},
			buffs = {
				array_start = 0x26c,
				array_end = 0x270,
				buff = {
					size = 0x54,
					time_remaining = 0x30,
					id = 0x20,
					level = 0x44,
				},
			},
		},
	},
	macro = {
		base = 0x676d54, --[[{macro_base}]]
		size = 0x508, --[[{macro_size}]]
		id = 0x10,
		icon = 0x14,
		name = 0x18,
		content = 0x118
	},
	hotkey = {
        base = 0x676c00, --[[{hotkey_base}]]
		list = 0x28,
		name = 0x4,
		hotkey1 = 0x54,
		modifier1 = 0x56,
		hotkey2 = 0x58,
		modifier2 = 0x5a
	},
	loading = {
		base = 0x676d10, --[[{loading_base}]]
		offsets = {0x18, 0x1C},
	},
	skill = {
		level = 0xc,
		tp_to_level = 0x8,
		uses = 0xc0,
		max_level = 0xf4,
		aoe_flag = 0xa4,
		as_level = 0x18,
		attack_flag = 0xb4,
		buff_flag = 0xec,
		cast_time = 0xf4,
		class = 0x304,
		remaining_cooldown = 0xe4,
		cooldown = 0xe8,
		effect_start = 0x188,
		item_set_as_level = 0x328,
		passive_flag = 0x94,
		range_aoe = 0xa0,
		target_type = 0x98,
		range = 0x9c,
		required_effect_flag = 0xd0,
		required_effect = 0xd4,
		required_effect_start = 0x190,
		self_buff_flag = 0xe0,
		type_flag1 = 0xf0,
		type_flag2 = 0x2fe,
		type_flag3 = 0x2ff,
		type_flag4 = 0x314,
		type_flag5 = 0x315,
		type_flag6 = 0xba,
		type_flag7 = 0x300,
		type_flag8 = 0xe4,
		type_flag9 = 0x274,
	},
	cooldowns = {
		base = 0x60b1f0, --[[{cooldowns_base}]]
		array_start = 0x1a88, --[[{cooldowns_array_start}]]
	},
	skillbook = {
        base = 0x678138, --[[{skillbook_base}]]
		offset = 0x8,
		book1_start = 0xc,
		book1_end = 0x10,
		book2_start = 0x1c,
		book2_end = 0x20,
		tabinfo_size = 0x20,
		skill = {
			size = 0x4c,
			id = 0x0,
			name = 0x24,
			tp_to_level = 0x8,
			level = 0xc,
			as_level = 0x18,
		},
	},
	itemset_skills = {
		base = 0x621560,
	},
	memdatabase = {
		base = 0x6378ec, --[[{memdatabase_base}]]
		offset = 0xD4,
		branch = {
			itemset_id = 0x4,
			size = 999,
			info_size = 0x24,
			itemset_address = 0x18,
		},
		skill = {
			uses = 0xC0,
			usesnum = 0xC4,
			level = 0x98,
		},
	},
	item = {
		card_or_npc_id = 0x36c,
		recipe_id = 0xF0,
		name = 0xC,
		count = 0x10,
		max_stack = 0x00, -- Wrong
		max_durability = 0x15,
		durability = 0x18,
		in_use = 0x20,
		bound_status = 0x44,
		value = 0x34,
		flags = 0x28,
		range = 0x18C,
		required_level = 0x58,
		type = 0x78,
		quality = 0x40,
		tier = 0x16,
		stats = 0x20,
		flags = 0x28,
		real_id = 0x98,
		cooldown = 0x8E,
		casting = 0x1c
	},
	equipment = {
		base = 0x60B86C,
	},
	bank = {
		base = 0x61DB94,
		open = {
            base = 0x662CDC,
			offset = 0x10,
		},
		rent = {
			base = 0x61E00C,
		},
		guild = {
			base = 0x665AA4,
		},
	},
	inventory = {
		base = 0x619808,
		item = {
			size = 0x48
		},
		rent = {
			base = 0x60fe30, --[[{inventory_rent_base}]]
			offset = 0x107cc, --[[{inventory_rent_offset}]]
		},
	},
	cursor = {
		base = 0x676bdc, --[[{cursor_base}]]
		offset = 0x0,
		item = {
			id = 0x10,
			bag_id = 0x14,
			location = 0xC,
		},
	},
	object_list = {
		base = 0x6786cc, --[[{object_list_base}]]
		size = 0x6786c8, --[[{object_list_size}]]
	},
	input_box = {
		base = 0x6753e0, --[[{input_box_base}]]
		offsets = {0xc, 0x9a4},
	},
	text = {
		base = 0x63382c, --[[{text_base}]]
		start_addr = 0x270,
		end_addr = 0x274,
	},
	mouse = {
		base = 0x633a98, --[[{mouse_base}]]
		x_in_window = {0x3B4},
		y_in_window = {0x3B8},
	},
	party = {
		leader = {
			base = 0x634f60, --[[{party_leader_base}]]
		},
		member_list = {
			base = 0x678080, --[[{party_member_list_base}]]
			offset = 0x68, --[[{party_member_list_offset}]]
		},
		icon_list = {
			base = 0x676df4, --[[{party_icon_list_base}]]
			offset = 0xc,
		},
	},
	newbie_eggpet = {
		base = 0x634c74, --[[{newbie_eggpet_base}]]
		offset = 0x7c, --[[{newbie_eggpet_offset}]]
	},
	eggpet = {
		base = 0x61F9a8,
		size = 0x348,
		max_slots = 6,
		name = 0x0,
		id = 0x20,
		pet_id = 0x28,
		level = 0x2c,
		summon_state = 0x38,
		tp = 0x44,
		max_tp = 0x48,
		loyalty = 0x4c,
		nourishment = 0x50,
		aptitude = 0x54,
		training = 0x58,
		exp = 0x5c,
		strength = 0x60,
		stamina = 0x64,
		dexterity = 0x68,
		intelligence = 0x6c,
		wisdom = 0x70,
		element = 0x74, -- 0=earth,1=water, 2=fire, 3=wind, 4=light, 5=dark
		mining = 0xd0,
		woodworking = 0xd4,
		herbalism = 0xd8
	},
}

--[[
	DEPRECATED; Please don't use these. Use the real addresses above instead
	These are left here for compatibility reasons only.
]]
partyLeader_address = 0x400000 + (addresses.party.leader.base);
addresses.partyIconList_base = 0x400000 + (addresses.party.icon_list.base);
partyIconList_offset = addresses.party.icon_list.offset;
partyMemberList_address = 0x400000 + (addresses.party.member_list.base);
partyMemberList_offset = addresses.party.member_list.offset;

addresses.loadingScreenPtr = 0x400000 + addresses.loading.base;
addresses.loadingScreen_offset = addresses.loading.offsets;
