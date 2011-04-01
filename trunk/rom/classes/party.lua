include("pawn.lua");
include("player.lua");



function PartyHeals()
		local partymember={}
		local partymemberName={}
		local partymemberObj={}

		table.insert(partymemberName,1, RoMScript("UnitName('player')"))  -- need to insert player name.
		table.insert(partymemberObj,1, player:findNearestNameOrId(partymemberName[1]))
		table.insert(partymember,1, CPawn(partymemberObj[1].Address))
for i = 1, 5 do

	if GetPartyMemberName(i) then

		table.insert(partymemberName,i + 1, GetPartyMemberName(i))
		table.insert(partymemberObj,i + 1, player:findNearestNameOrId(partymemberName[i]))
		table.insert(partymember,i + 1, CPawn(partymemberObj[i].Address))
	end
end


function healing()
	local target = player:getTarget();
if player.Class1 == 5 then -- priest
-- 70% to 90% HP
         	if (90 > target.HP/target.MaxHP*100 and 
            	target.HP/target.MaxHP*100 > 70 and
            	( not target:hasBuff("Regenerate")) ) then
               player:cast("PRIEST_REGENERATE")
          	end
-- 50% to 70% HP
      		if (70 > target.HP/target.MaxHP*100 and 
            target.HP/target.MaxHP*100 > 50) then
                player:cast("PRIEST_URGENT_HEAL") 
            end          
-- 30% to 50% HP
      		if (50 > target.HP/target.MaxHP*100 and 
            target.HP/target.MaxHP*100 > 30) then
                player:cast("PRIEST_HEAL") 
            end 
                        
-- 10% to 30% HP
      		if (30 > target.HP/target.MaxHP*100 and 
            target.HP/target.MaxHP*100 > 10) then
                player:cast("PRIEST_SOUL_SOURCE") 
            end
            if 30 > player.HP/player.MaxHP*100 then player:cast("PRIEST_HOLY_AURA") end      
end
end 
	while(true) do
	
		for i,v in ipairs(partymember) do
		if i == 1 then keyboardPress(key.VK_F1); end
		if i == 2 then keyboardPress(key.VK_F2); end
		if i == 3 then keyboardPress(key.VK_F3); end
		if i == 4 then keyboardPress(key.VK_F4); end
		if i == 5 then keyboardPress(key.VK_F5); end
		if i == 6 then keyboardPress(key.VK_F6); end

			partymember[i]:update()
						
			partymember[i]:updateBuffs()
			
			player:checkPotions()
			
			player:checkSkills(true);
			
			partymember[i]:update()
							
			healing()
			yrest(1000)
				
 
		if (not player.Battling) then 
  
		getNameFollow()
		end	
	end
 	end
 end

function PartyDPS()
player:update();
 
	player:target(player:findEnemy(true, nil, nil, nil))
	local target = player:getTarget();
	local pawn = CPawn(target.Address);
	local icon = pawn:GetPartyIcon()
		
		if player:haveTarget() then

		if icon == 1 then 
			local target = player:getTarget();
				
   			player:fight();
		end
		end
		if (not player.Battling) then 
  -- might try to use moveinrange function.
		getNameFollow()
		end	
end			

function getNameFollow()
	while (true) do	
  		if ( settings.profile.options.PARTY_FOLLOW_NAME ) then
    	if GetPartyMemberName(1) == settings.profile.options.PARTY_FOLLOW_NAME  then RoMScript("FollowUnit('party1');"); break  end
		if GetPartyMemberName(2) == settings.profile.options.PARTY_FOLLOW_NAME  then RoMScript("FollowUnit('party2');"); break  end
		if GetPartyMemberName(3) == settings.profile.options.PARTY_FOLLOW_NAME  then RoMScript("FollowUnit('party3');"); break  end
		if GetPartyMemberName(4) == settings.profile.options.PARTY_FOLLOW_NAME  then RoMScript("FollowUnit('party4');"); break  end
		if GetPartyMemberName(5) == settings.profile.options.PARTY_FOLLOW_NAME  then RoMScript("FollowUnit('party5');"); break  end
		RoMScript("FollowUnit('party1');");
		else RoMScript("FollowUnit('party1');");		

		end
		break
	end
end