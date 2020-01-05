-- Auto-generated by update.lua
addresses = {
	client_exe_module_start = 0x400000,
	game_time = 0x601F58,
	player_name = 0x602510,
	in_game = 0x65E5F0,
	zone_id = 0x659250,
	buff_count = 0x6031B0,
	channel = {
		base = 0x661188,
		id = 0x4c4,
	},
	class_info = {
		base = 0x60C5F0,
		size = 0x430,
		level = 0x28,
		tp = 0x10
	},
	crafting = {
		base = 0x602bfc,
	},
	code_mod = {
		freeze_target = {
			base = 0x4970f1,
			original_code = string.char(0x89, 0x86, 0x78, 0x02, 0x00, 0x00),
			replace_code = string.char(0x90, 0x90, 0x90, 0x90, 0x90, 0x90),
		},
	},
	exp_table = 0x65930C,
	psi = 0x606B08,
	global_cooldown = 0x603990,
	game_root = {
		base = 0x60099c,
		gold = 0x6144B4,
		mouseover_object_ptr = 0x75c,
		player_actual_speed = 0x790,
		ping = 0x7c0,
		input = {
			movement = 0xAAC,
		},
		camera = {
			base = 0x454,
			distance = 0x244,
			x = 0xc428,
			y = 0xc438,
			z = 0xc448,
		},
		player = {
			base = 0x5a8,
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
			fading = 0x68,
			harvesting = 0x164,
			speed = 0x1f0,
			stance = 0x228,
			cast_full_time = 0x260,
			cast_time = 0x264,
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
			class2 = 0x318,
			level2 = 0x320,
			race = 0x328,
			lootable_flags = 0x3a0,
			attackable_flags = 0x39c,
			mounted = 0x3fa,
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
		base = 0x662474,
		size = 0x508,
		id = 0x10,
		icon = 0x14,
		name = 0x18,
		content = 0x118
	},
	hotkey = {
		base = 0x662320,
		list = 0x28,
		name = 0x4,
		hotkey1 = 0x54,
		modifier1 = 0x56,
		hotkey2 = 0x58,
		modifier2 = 0x5a
	},
	loading = {
		base = 0x662430,
		offsets = {0x18, 0x1C},
	},
	skill = {
		base = 0x663864,
		cooldowns = {
			base = 0x603990,
		},
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
		cooldown = 0xe8,
		effect_start = 0x188,
		item_set_as_level = 0x328,
		passive_flag = 0x94,
		range_aoe = 0xa0,
		target_type = 0x98,
		range = 0x9c,
		remaining_cooldown = 0xe4,
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
		tab_end = 0x8,
		tab_start = 0x4,
	},
	item = {
		table = {
			--base = ???,
			--start = ???,
		},
		card_or_npc_id = 0x364,
		recipe_id = 0xF0,
		name = 0xC,
		count = 0x10,
		max_durability = 0x15,
		durability = 0x18,
		in_use = 0x1c,
		bound_status = 0x40,
		value = 0x34,
	},
	equipment = {
		base = 0x6025E0
	},
	bank = {
		base = 0x6143F4,
		open = {
			base = 0x660C4C,
			offset = 0x10,
		},
		rent = {
			base = 0x61BF84,
		},
		guild = {
			base = 0x663A14,
		},
	},
	inventory = {
		base = 0x611418,
		bag_ids = {
			base = 0x61b3b4,
		},
		rent = {
			base = 0x61BF5C
		},
	},
	cursor = {
		base = 0x6622FC,
		item = {
			id = 0x10,
			bag_id = 0x14,
			location = 0xC,
		},
	},
	object_list = {
		base = 0x663DD4,
		size = 0x663DD0,
	},
	input_box = {
		base = 0x660B00,
		offsets = {0xc, 0x9a4},
	},
}
