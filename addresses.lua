addresses = {
	--== this must be a link between the quest-text and the id ==--
	questGroup_offset = 0x4F0,
	--===========================================================--

	--== fixed the casting bar but i'm not sure, that the "player.casting" is completely fixed ==--
	castingBarPtr = 0xA61D20,
	castingBar_offset = 0xC,
	--===========================================================================================--

	--== trying to fix the partyDPS (no success) ==--
	partyIconList_base = 0xA63528,
	partyIconList_offset = 0xC,
	partyLeader_address = 0xA27240,
	partyMemberList_address = 0xA647B0,
	partyMemberList_offset = 0x68,
	--=============================================--
	
	game_time = 0x602F70,
	in_game = 0x65F608,
	zone_id = 0x65a268, --[[{zone_id}]]
	movement_speed = {
		base = 0x606C48, -- Float; Normal, expected movement speed, whether mounted or not
	},
	channel = {
		base = 0x6621a0, --[[{channel_base}]]
		id = 0x4c4,
	},
	class_info = {
		base = 0x607b50, --[[{class_info_base}]]
		offset = 0x438,
		size = 0x430,
		level = 0x28,
		tp = 0x10
	},
	crafting = {
		base = 0x603c0c,
	},
	code_mod = {
		freeze_target = {
			base = 0x4973e1, --[[{freeze_target_codemod}]]
			original_code = string.char(0x89, 0x86, 0x78, 0x02, 0x00, 0x00),
			replace_code = string.char(0x90, 0x90, 0x90, 0x90, 0x90, 0x90),
		},
		
		freeze_mousepos = {
			base = 0x230594, --[[{freeze_mousepos_codemod}]]
			original_code = string.char(0x89, 0x8E, 0xB4, 0x03, 0x00, 0x00, 0x89, 0x86, 0xB8, 0x03, 0x00, 0x00),
			replace_code = string.char(0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90),
		},
		freeze_mousepos2 = {
			base = 0x22fdea, --[[{freeze_mousepos2_codemod}]]
			original_code = string.char(0x89, 0x86, 0xB8, 0x03, 0x00, 0x00),
			replace_code = string.char(0x90, 0x90, 0x90, 0x90, 0x90, 0x90),
		},
		swimhack = {
			base = 0x4d519, --[[{swimhack_codemod}]]
			original_code = string.char(0xC7, 0x83, 0xB4, 0x00, 0x00, 0x00, 0x03, 0x00, 0x00, 0x00),
			replace_code = string.char(0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90),
		},
	},
	exp_table = 0x65a324, --[[{exp_table}]]
	psi = 0x607b18, --[[{psi}]]
	global_cooldown = {
		base = 0x602f78, --[[{global_cooldown_base}]]
		offset = 0x1a28, --[[{global_cooldown_offset}]]
	},
	actionbar = {
		base = 0x661c24, --[[{actionbar_base}]]
		slot = {
			size = 0x14,
			type = 0x0,
			id = 0x4,
		},
		bar1_start = 0x384c
	},
	gold = {
		base = 0x607b50, --[[{gold_base}]]
		offset = 0x82fc, --[[{gold_offset}]]
	},
	game_root = {
		base = 0x6019b4, --[[{game_root_base}]]
		mouseover_object_ptr = 0x75c,
		player_actual_speed = 0x790,
		ping = 0x7c0,
		input = {
			movement = 0xAAC,
		},
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
		base = 0x66348C,
		size = 0x508,
		id = 0x10,
		icon = 0x14,
		name = 0x18,
		content = 0x118
	},
	hotkey = {
        base = 0x663338,
		list = 0x28,
		name = 0x4,
		hotkey1 = 0x54,
		modifier1 = 0x56,
		hotkey2 = 0x58,
		modifier2 = 0x5a
	},
	loading = {
		base = 0x663448,
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
		base = 0x602F78,
		array_start = 0x1A2C,
	},
	skillbook = {
        base = 0x664870,
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
		base = 0x629b3c,
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
		card_or_npc_id = 0x368,
		recipe_id = 0xF0,
		name = 0xC,
		count = 0x10,
		max_stack = 0x1C,
		max_durability = 0x15,
		durability = 0x18,
		in_use = 0x1c,
		bound_status = 0x40,
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
		
	},
	equipment = {
		base = 0x6035F0, --(scout skills are fixed)
	},
	bank = {
		base = 0x6154D0,
		open = {
            base = 0x661C64,
			offset = 0x10,
		},
		rent = {
			base = 0x61CF94,
		},
		guild = {
			base = 0x664A2C,
		},
	},
	inventory = {
		base = 0x6124f0,
		bag_ids = {
			base = 0x61C3C4,
		},
		rent = {
			base = 0x61CF6C,
		},
	},
	cursor = {
		base = 0x663314,
		item = {
			id = 0x10,
			bag_id = 0x14,
			location = 0xC,
		},
	},
	object_list = {
		base = 0x664DEC,
		size = 0x664DE8,
	},
	input_box = {
		base = 0x661B18, -- fixes UMM
		offsets = {0xc, 0x9a4},
	},
	text = {
		base = 0x625B14,
		start_addr = 0x268,
		end_addr = 0x26C,
	},
	mouse = {
		base = 0x62B9BC,
		x = 0x8C,
		y = 0x90,
		x_in_window = {0xC, 0x3B4},
		y_in_window = {0xC, 0x3B8},
	},
}
