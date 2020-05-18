--=== 								===--
--===    Original done by Tsutomu 	===--
--=== Version 2.1 patch 5.0.0		===--
--=== 		Updated by lisa			===--
--=== 		Modified by Andre235	===--
--=== 								===--

--===  								===--
--===  swimAddress = 0x44DEB2		===--
--===  charPtr_offset = 0x5A8		===--
--===  pawnSwim_offset1 = 0xF0		===--
--===  pawnSwim_offset2 = 0xB4		===--
--===  								===--


local codemod = CCodeMod(addresses.code_mod.swimhack.base,
	addresses.code_mod.swimhack.original_code,
	addresses.code_mod.swimhack.replace_code);

local installed = false;

local SWIMMING_VALUE = 4;

function fly()
	local player = CPlayer.new();

	-- Install codemod
	installed = codemod:safeInstall();
	if( installed == false ) then
		print("Failed to install swimhack codemod");
		return;
	end

	-- Write swimming state to player
	memoryWriteIntPtr(getProc(),
		player.Address + addresses.game_root.pawn.swimming.base,
		addresses.game_root.pawn.swimming.swimming,
		SWIMMING_VALUE);
	
	print("Swimhack ACTIVATED!");
end

function flyoff()
	installed = codemod:safeUninstall();
	print("Swimhack Deactivated.");
end