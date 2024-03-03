addresses = {
	--== this must be a link between the quest-text and the id ==--
	questGroup_offset = 0x4F0,
	--===========================================================--

	--== fixed the casting bar but i'm not sure, that the "player.casting" is completely fixed ==--
	castingBarPtr = 0xA6BBC8,
	castingBar_offset = 0xC,
	--===========================================================================================--

	game_time = 0x611268, --[[{game_time}]]
	in_game = 0x6790c0, --[[{in_game}]]
	zone_id = 0x673cb8, --[[{zone_id}]]
	movement_speed = {
		base = 0x613b18, --[[{movement_speed_base}]]
		offset = 0x1498, --[[{movement_speed_offset}]]
	},
	collecting = {
		base = 0x67b7d8, --[[{collecting_base}]]
		type = 0xc,
	},
	channel = {
		base = 0x67b5e0, --[[{channel_base}]]
		id = 0xe4,
	},
	class_info = {
		base = 0x615eb8, --[[{class_info_base}]]
		offset = 0x438,
		size = 0x430,
		level = 0x28,
		tp = 0x10
	},
	currency = {
		base = 0x622C68,
	},
	crafting = {
		base = 0x611224, --[[{crafting_base}]]
	},
	code_mod = {
		freeze_target = {
			base = 0x4a24a1, --[[{freeze_target_codemod}]]
			original_code = string.char(0x89, 0x86, 0x78, 0x02, 0x00, 0x00),
			replace_code = string.char(0x90, 0x90, 0x90, 0x90, 0x90, 0x90),
		},

		freeze_mousepos = {
			base = 0x231c34, --[[{freeze_mousepos_codemod}]]
			original_code = string.char(0x89, 0x8E, 0xB4, 0x03, 0x00, 0x00, 0x89, 0x86, 0xB8, 0x03, 0x00, 0x00),
			replace_code = string.char(0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90),
		},

		freeze_clicktocast_mouseoffscreen = {
			base = 0x231454, --[[{freeze_clicktocast_mouseoffscreen}]]
			original_code = string.char(0x7D, 0x0C),
			replace_code = string.char(0xEB, 0x40),
		},

		swimhack = {
			base = 0x4de92, --[[{swimhack_codemod}]]
			original_code = string.char(0xC7, 0x83, 0xB4, 0x00, 0x00, 0x00, 0x03, 0x00, 0x00, 0x00),
			replace_code = string.char(0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90),
		},
	},
	exp_table = 0x673d74, --[[{exp_table}]]
	psi = 0x615e84, --[[{psi}]]
	global_cooldown = {
		base = 0x611278, --[[{global_cooldown_base}]]
		offset = 0x1a84, --[[{global_cooldown_offset}]]
	},
	actionbar = {
		base = 0x67653c, --[[{actionbar_base}]]
		slot = {
			size = 0x14,
			type = 0x0,
			id = 0x4,
		},
		size_per_class = 0x640,
		offset = 0xc,
	},
	gold = {
		base = 0x615eb8, --[[{gold_base}]]
		offset = 0x86bc, --[[{gold_offset}]]
	},
	game_root = {
		base = 0x60fc0c, --[[{game_root_base}]]
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
		base = 0x67cf44, --[[{macro_base}]]
		size = 0x508, --[[{macro_size}]]
		id = 0x10,
		icon = 0x14,
		name = 0x18,
		content = 0x118
	},
	hotkey = {
        base = 0x67cdf0, --[[{hotkey_base}]]
		list = 0x28,
		name = 0x4,
		hotkey1 = 0x54,
		modifier1 = 0x56,
		hotkey2 = 0x58,
		modifier2 = 0x5a
	},
	loading = {
		base = 0x67cf00, --[[{loading_base}]]
		offsets = {0x18, 0x1C},
	},
	skill = {
		level = 0xc, --unused
		tp_to_level = 0x8, --unused
		uses = 0xc0,
		max_level = 0xf4, --unused
		aoe_flag = 0xa4, --unused
		as_level = 0x18, --unused
		attack_flag = 0xb4, --unused
		buff_flag = 0xec, --unused
		cast_time = 0xf4, --unused
		class = 0x304, --unused
		remaining_cooldown = 0xe4,
		cooldown = 0xe8, --unused
		effect_start = 0x188, --unused
		item_set_as_level = 0x328, --unused
		passive_flag = 0x94, --unused
		range_aoe = 0xa0, --unused
		target_type = 0x98, --unused
		range = 0x9c, --unused
		required_effect_flag = 0xd0, --unused
		required_effect = 0xd4, --unused
		required_effect_start = 0x190, --unused
		self_buff_flag = 0xe0, --unused
		type_flag1 = 0xf0, --unused
		type_flag2 = 0x2fe, --unused
		type_flag3 = 0x2ff, --unused
		type_flag4 = 0x314, --unused
		type_flag5 = 0x315, --unused
		type_flag6 = 0xba, --unused
		type_flag7 = 0x300, --unused
		type_flag8 = 0xe4, --unused
		type_flag9 = 0x274, --unused
	},
	cooldowns = {
		base = 0x611278, --[[{cooldowns_base}]]
		array_start = 0x1a88, --[[{cooldowns_array_start}]]
	},
	skillbook = {
        base = 0x67e328, --[[{skillbook_base}]]
		offset = 0x8,
		book1_start = 0xc,
		book1_end = 0x10,
		book2_start = 0x1c,
		book2_end = 0x20,
		tabinfo_size = 0x20,
		skill = {
			id = 0x0,
			tp_to_level = 0x8,
			level = 0xc,
			as_level = 0xc,
			required_level = 0x18,
			name = 0x24,
			size = 0x4C,
		},
	},
	itemset_skills = {
		base = 0x621560,
	},
	memdatabase = {
		base = 0x63da2c, --[[{memdatabase_base}]]
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
		ammo_count = 0x10,
		count = 0x10,
		max_stack = 0x20, -- wrong
		max_durability = 0x19, -- 1 byte
		durability = 0x1C, -- 4 byte
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
		base = 0x6118F4,
	},
	bank = {
		base = 0x623C20,
		open = {
			base = 0x662CDC,
			offset = 0x10,
		},
		guild = {
			base = 0x665AA4,
		},
	},
	inventory = {
		base = 0x61F890,
		item = {
			size = 0x48
		},
		rent = {
			base = 0x615eb8, --[[{inventory_rent_base}]]
			offset = 0x107cc, --[[{inventory_rent_offset}]]
			bank_offset = 0x28,
		},
	},
	cursor = {
		base = 0x67cdcc, --[[{cursor_base}]]
		offset = 0x0,
		item = {
			id = 0x10,
			bag_id = 0x14,
			location = 0xC,
		},
	},
	object_list = {
		base = 0x67e8cc, --[[{object_list_base}]]
		size = 0x67e8c8, --[[{object_list_size}]]
	},
	input_box = {
		base = 0x67b5d0, --[[{input_box_base}]]
		offsets = {0xc, 0x9a4},
	},
	text = {
		base = 0x63994c, --[[{text_base}]]
		start_addr = 0x2a8,
		end_addr = 0x2ac,
	},
	mouse = {
		base = 0x639bb8, --[[{mouse_base}]]
		x_in_window = {0x3B4},
		y_in_window = {0x3B8},
	},
	party = {
		leader = {
			base = 0x63b084, --[[{party_leader_base}]]
		},
		member_list = {
			base = 0x67e270, --[[{party_member_list_base}]]
			offset = 0x68, --[[{party_member_list_offset}]]
		},
		icon_list = {
			base = 0x67cfe4, --[[{party_icon_list_base}]]
			offset = 0xc,
		},
	},
	newbie_eggpet = {
		base = 0x63ad94, --[[{newbie_eggpet_base}]]
		offset = 0x7c, --[[{newbie_eggpet_offset}]]
	},
	eggpet = {
		base = 0x62e7b0, --[[{eggpet_base}]]
		size = 0x36C,
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
