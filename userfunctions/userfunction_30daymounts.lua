--==<<            NoobBotter's 30 Day Mount Mounting function           >>==--
--==<<           	By Noobbotter        Version 1.1       				>>==--
--==<<                                              					>>==--
--==<<   Rev 1.1 includes item ID for horse rental tickets. Also 		>>==--
--==<<   noticed it would only use one if you had more than 1.          >>==--
--==<<   Now it will use even your last one if needed.                  >>==--
--==<<                                              					>>==--
--==<<  http://solarstrike.net/phpBB3/viewtopic.php?f=27&t=6012			>>==--

function doMount()
	if not player.Mounted then --if not already mounted, check for mounts
		if not inventory:getMount() then
			-- if no mounts found, check for items to create 30 day mount:
			local tempmounts = { -- 30 day Infernal and Abysmal Mounts
				206572,
				206560
			}
			local havemount = "no"
			
			--Check inventory to see if you already have an infernal or Abysmal mount:
			for k,v in pairs(tempmounts) do
				if inventory:itemTotalCount(v) > 0 then
					havemount = "yes"
				end
			end
			
			if havemount == "no" then --if no, then neither mount was found in inventory
				-- check for items to build Abysmal mount first:
				print("no mount found in inventory")
				local mycount = 0
				local mountitems = {
					206636,      -- Abysmal Nightmare 30 Day Contract
					206637,      -- Abysmal Nightmare Soul Core
					206641,      -- Abysmal Nightmare Spiny Armor
					206638,      -- Abysmal Nightmare Statue Fragment I
					206639,      -- Abysmal Nightmare Statue Fragment II
					206640      -- Abysmal Nightmare Statue Fragment III
				}
				for k,v in pairs(mountitems) do
					if inventory:itemTotalCount(v) > 0 then
						mycount = mycount + 1
					end
				end
				if mycount >= 6 then -- all items found
					if inventory:itemTotalCount(0) > 0 then
						inventory:useItem(206636);
						yrest(500)
						inventory:update()
						yrest(1000)
						havemount = "yes"
						-- player should now have an Abysmal mount in inventory
						printf("%s created an Abysmal Mount.\n",player.Name)
						--logInfo(player.Name, "NEW ABYSMAL NIGHTMARE MOUNT CREATED FOR "..player.Name,true) -- optional loginfo line
						yrest(200)
					else
						print("No available Backpack slots")
					end
				else -- If not enough material to build Abysmal mount, then check items for an Infernal mount:
					local mycount = 0
					local mountitems = {
						206631,      -- Infernal Nightmare 30 Day Contract
						206632,      -- Infernal Nightmare Soul Core
						206633,      -- Infernal Nightmare Statue Fragment I
						206634,      -- Infernal Nightmare Statue Fragment II
						206635       -- Infernal Nightmare Statue Fragment III
					}
					for k,v in pairs(mountitems) do
						if inventory:itemTotalCount(v) > 0 then
							mycount = mycount + 1
						end
					end
					if mycount >= 5 then -- all items found
						if inventory:itemTotalCount(0) > 0 then
							inventory:useItem(206631);
							yrest(500)
							inventory:update()
							yrest(1000)
							havemount = "yes"
							-- player should now have an Infernal mount in inventory
							printf("%s created an Infernal Mount.\n",player.Name)
							--logInfo(player.Name, "NEW INFERNAL NIGHTMARE MOUNT CREATED FOR "..player.Name,true) -- optional loginfo line
							yrest(200)
						else
							print("No available Backpack slots")
						end
					end
				end	
			end
			--after running function above, if it has or created a mount, havemount will now be "yes"
			if havemount == "no" then
				if inventory:itemTotalCount(205821) >= 1 then
					inventory:useItem(205821);
					yrest(500)
					inventory:update()
					yrest(1000)
				elseif inventory:itemTotalCount(203033) >= 1 then
					inventory:useItem(203033);
					yrest(500)
					inventory:update()
					yrest(1000)
				end
			end
		end
	end
	player:mount()
	yrest(5000)
	speed()
end

