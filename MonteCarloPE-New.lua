BEST_SCORE = 0

function waitFrames(n)
	for i=1,n,1 do
		emu.frameadvance()
	end
end

function waitFramesBreak(n, game)
	--print(bp)
	for i=1,n,1 do
		emu.frameadvance()
		if game.ended() then game.endFlag = true break end
	end
	return false
end

function waitFrameBreak(game)
	return waitFramesBreak(1, game)
end

function count(dic)
	i = 0
	for k,v in pairs(dic) do
		i = i + 1
	end
	return i
end

function node(n)
	return { name = n, action = nil, state = nil, parent = nil, children = nil, cn = 0, value = 0, visits = 0, terminal = false, terminalKids = 0} 
end

function markTerminal(node)
	print("markTerminal")
	print("Marking as terminal: " .. node.name)
	node.terminal = true
	if node.parent == nil then return end
	node.parent.terminalKids = node.parent.terminalKids + 1
--	print("Parent has " .. node.parent.terminalKids .. " terminal kids out of " .. count(node.parent.children) .. " children total")
	if node.parent.terminalKids == count(node.parent.children) then
		markTerminal(node.parent)
	end
end

function selection(node)
	topChild = nil
	topScore = -999
	
	c = math.sqrt(2)
	k = node.value / 2
	
	for i, kid in pairs(node.children) do
		if (kid.terminal) then
--			print("skipping terminal kid: " .. kid.name)
		else
			if (kid.visits > 0) then
				score = kid.value + c * math.sqrt( ( 2 * math.log(node.visits) ) / (kid.visits) )
			--	score = (kid.value / (kid.visits) ) + c * math.sqrt( ( 2 * math.log(node.visits) ) / (kid.visits) )
			else
				score = k + c * math.sqrt( ( 2 * math.log(node.visits) ) / (node.cn + 1) )
			end
			if score > topScore then
				topChild = kid
				topScore = score
			end
		end
	end
	
	if topChild == nil then
		print("selection ERROR: node has no children")
	end
	
	if topChild.visits == 0 then node.cn = node.cn + 1 end
	
	return topChild
end

function MonteCarloTreeSearch(game, n, root)

	for i=1,n,1 do
		print("Iteration #" .. i)
		curNode = root
		if curNode.terminal then break end
		curNode.visits = curNode.visits + 1
		-- memorysavestate.loadcorestate(curNode.state)
		
		while (curNode.state ~= nil) do
			-- memorysavestate.loadcorestate(curNode.state)
			if (curNode.children == nil) then
				game.expand(curNode)
				-- skip analysis and designate this node as terminal if no children
				if curNode.children == nil then
--					print("No children. skipping...")
					game.endFlag = true
					break
				end
			end
			curNode = selection(curNode)
--			print("Selected action: " .. curNode.name)
			curNode.visits = curNode.visits + 1
		end
		
		if not game.endFlag then
			memorysavestate.loadcorestate(curNode.parent.state)
			game.perform(curNode.action)
			curNode.state = memorysavestate.savecorestate()
		end
		
		if (game.endFlag) then
			markTerminal(curNode)
		else
			game.rollout()
		end
		
		result = game.score()
		print(result)
		if (result > BEST_SCORE) then
			BEST_SCORE = result
			print("New best score: " .. BEST_SCORE)
		end
--		print("Score: " .. result)
		game.endFlag = false
		
		while (curNode ~= nil) do
			if (result > curNode.value) then
				curNode.value = result
			end
--			curNode.value = curNode.value + result;
			curNode = curNode.parent
		end
		
	end
	
	topKid = nil
	topScore = -999
	
	for i, kid in pairs(root.children) do
		if (kid.value > topScore) then
--		if (kid.value / kid.visits > topScore) then
			topKid = kid
			topScore = kid.value
--			topScore = kid.value / kid.visits
		end 
	end
	
	return topKid
end

function simulate(game, N, n)
	root = node(nil)
	root.state = memorysavestate.savecorestate()
	for i=1,N,1 do
		print("Starting move " .. i)
		root = MonteCarloTreeSearch(game, n, root)
		if (root == nil) then break end
		memorysavestate.loadcorestate(root.state)
		root.parent = nil
		print("Selected move: " .. root.name .. " (score = " .. root.value .. ")" )
		client.pause()
	end
end

OnimushaTactics = { 
	name = "Onimusha Tactics",

	SELECT_BATTLE_UNIT = 0x19,
	UNIT_MENU = 0x1D,
	SELECT_MOVE = 0x1A,
	SELECT_ATTACK = 0x1E,
	
	endFlag = false,
	
	ended = function()
		-- player dead
		if mainmemory.readbyte(0x2AE2) == 0 then return true end
		-- all enemies dead
		if mainmemory.readbyte(0x38A0) == 0x4B or mainmemory.readbyte(0x38A0) == 0x2F or mainmemory.readbyte(0x38A0) == 0x01 then
			--client.pause()
			return true
		end
		
		return false
		
--		UNIT_ADDR = 0x28DC
--		UNIT_SIZE = 0xEC		
		
--		allDead = true
--		for i=0,15,1 do
--			uaddr = UNIT_ADDR + i*UNIT_SIZE
--			uid = mainmemory.readbyte(uaddr)
--			ustat = mainmemory.readbyte(uaddr + 0x4A)	
--			if uid > 0x17 and bit.band(ustat,2) ~= 0 then allDead = false break end
--		end
--		if allDead then return true end
--		return false
	end,
	
	getActs = function()
		acts = {}

		SystemDataPtr = mainmemory.read_s16_le(0x2538)
		GameDataPtr = mainmemory.read_s16_le(SystemDataPtr + 0xC)
		CursorX = mainmemory.readbyte(GameDataPtr + 0x62E)
		CursorY = mainmemory.readbyte(GameDataPtr + 0x630)

		UnitXPosArr = GameDataPtr + 0xA8C
		UnitYPosArr = GameDataPtr + 0xA9C

		UNIT_ADDR = 0x28DC
		UNIT_SIZE = 0xEC
		
		gameMode = mainmemory.readbyte(0x38A0)

--		print(string.format("%x",gameMode))
		if (gameMode == OnimushaTactics.SELECT_BATTLE_UNIT) then
--			print("  Current mode: Select Battle Unit")
			--Generate list of player units
			--Determine which ones are alive and can act
			--For each one, insert a selection act into acts
			
			for i=0,15,1 do
				curUnit = UNIT_ADDR + i*UNIT_SIZE
				unitID = mainmemory.readbyte(curUnit)
				unitFlags = mainmemory.readbyte(curUnit+0xB8)
				unitStatus = mainmemory.readbyte(curUnit+0x4A)
							
				if (unitID > 0 and unitID <= 16)    -- if unit is player-controlled
					and bit.band(unitFlags,1) == 0  -- if unit has not finished turn
					and bit.band(unitStatus,1) == 1 -- if unit is alive
					then
--					print("Unit ID: " .. unitID)
					unitXpos = mainmemory.readbyte(UnitXPosArr + i)
					unitYpos = mainmemory.readbyte(UnitYPosArr + i)
--					print("Pos: " .. unitXpos .. ", " .. unitYpos)
					table.insert(acts, { id = "Select Unit @ " .. unitXpos .. ", " .. unitYpos, name = "Select Unit", x = unitXpos, y = unitYpos } ) 
				end
			end
			
--			table.insert(acts, { id = "End Phase", name = "End Phase" } )
		elseif (gameMode == OnimushaTactics.UNIT_MENU) then
		
			--unitNum = mainmemory.readbyte(0x379C)
			unitNum = 2
--			print(unitNum)
			curUnit = UNIT_ADDR + unitNum*UNIT_SIZE
			unitFlags = mainmemory.readbyte(curUnit+0xB8)
			
--			print("  Current mode: Unit Menu")
--			print("Unit flags: " .. unitFlags)
			if (bit.band(unitFlags,4) == 0) then
				table.insert(acts, { id = "Select Move", name = "Select Move" } )
			end
			if (bit.band(unitFlags,2) == 0) then
				table.insert(acts, { id = "Select Attack", name = "Select Attack" } )
			end
			
			if (unitFlags ~= 0) then
				table.insert(acts, { id = "Done", name = "Done"} )
			end
		elseif (gameMode == OnimushaTactics.SELECT_MOVE) then
		
			--unitNum = mainmemory.readbyte(0x379C)
			unitNum = 2
			curUnit = UNIT_ADDR + unitNum*UNIT_SIZE
			unitFlags = mainmemory.readbyte(curUnit+0xB8)
			unitX = mainmemory.readbyte(UnitXPosArr + unitNum)
			unitY = mainmemory.readbyte(UnitYPosArr + unitNum)
--			print(unitX .. "," .. unitY)
--			print("  Current mode: Select Move")
			-- scan all tiles to see which are highlighted
			-- insert act for each move
			
			for yPos=0,15,1 do
				baseRow = 0x249C + 4*yPos
				for xPos=0,15,1 do
--					print("Checking " .. xPos .. ", " .. yPos)
					exactRow = baseRow + math.floor(xPos/8)
--					print("exactRow: " .. string.format("%x", exactRow))
					baseVal = mainmemory.readbyte(exactRow)
--					print("baseVal: " .. string.format("%x", baseVal))
					digit = math.pow(2,xPos%8)
--					print("Digit: " .. digit)
					if (xPos == unitX and yPos == unitY) then
--						print("lol")
					elseif bit.band(baseVal,digit) ~= 0 then
--						print("Possible move detected: " .. xPos .. ", " .. yPos)
						table.insert(acts, { id = "Move to " .. xPos .. ", " .. yPos, name = "Move", x = xPos, y  = yPos } )
					end
				end
			end
		elseif (gameMode == OnimushaTactics.SELECT_ATTACK) then
		
			--unitNum = mainmemory.readbyte(0x379C)
			unitNum = 2
			curUnit = UNIT_ADDR + unitNum*UNIT_SIZE
			unitFlags = mainmemory.readbyte(curUnit+0xB8)		
		
--			print("Current mode: Select Attack")
			-- scan all tiles to see which are highlighted and contain an attackable enemy unit
			-- insert act for each attack
			
			for yPos=0,15,1 do
				baseRow = 0x249C + 4*yPos
--				print("baseRow: " .. string.format("%x", baseRow))
				for xPos=0,15,1 do
--					print("Checking " .. xPos .. ", " .. yPos)
					exactRow = baseRow + math.floor(xPos/8)
--					print("exactRow: " .. string.format("%x", exactRow))
					baseVal = mainmemory.readbyte(exactRow)
--					print("baseVal: " .. string.format("%x", baseVal))
					digit = math.pow(2,xPos%8)
--					print("Digit: " .. digit)
					if bit.band(baseVal,digit) ~= 0 then
						for i=0,15,1 do
--							print(string.format("%x",UnitXPosArr))
--							print(string.format("%x",UnitYPosArr))
							if xPos == mainmemory.readbyte(UnitXPosArr + i) and yPos == mainmemory.readbyte(UnitYPosArr + i) then
								uaddr = UNIT_ADDR + i * UNIT_SIZE
								uid = mainmemory.readbyte(uaddr)
								ustat = mainmemory.readbyte(uaddr + 0x4A)
								
--								print("data")
--								print(uid)
--								print(ustat)
								
								if uid > 0x17 and bit.band(ustat,2) ~= 0 then						
--									print("Possible attack detected: " .. xPos .. ", " .. yPos)
									table.insert(acts, { id = "Attack " .. xPos .. ", " .. yPos, name = "Attack", x = xPos, y  = yPos } )
								end
							end
						end
					end
				end
			end
		end
		
		if #acts == 0 then
			mainmemory.writebyte(0x2AE2,0)
			endFlag = true
		end
		
		return acts
	end,
	
	expand = function(p)
--		print("  expand")
		acts = OnimushaTactics:getActs()

		kids = {}
		for k,v in ipairs(acts) do
			kids[v.id] = node(v.id)
			kids[v.id].action = v
			kids[v.id].parent = p
		end
		
		if #acts == 0 then kids = nil end
		
		p.children = kids
	end,
	
	perform = function(act,act2)
		if (act.name == "Onimusha Tactics") then
			act = act2
		end
		
--		print("  perform")
--		print(act)
		
		SpriteDataPtr = mainmemory.read_s16_le(0x2538)
		DataPtr2 = mainmemory.read_s16_le(SpriteDataPtr + 0xC)
		CursorX = mainmemory.readbyte(DataPtr2 + 0x62E)
		CursorY = mainmemory.readbyte(DataPtr2 + 0x630)			
		
		gameMode = mainmemory.readbyte(0x38A0)
	
		if act.name == "End Phase" then
--			print("End Phase")
			joypad.set({Start = true})
			
			while (mainmemory.readbyte(0x38A0) ~= 0x34) do
				emu.frameadvance()
			end
			
			joypad.set({Up = true})
			waitFrames(1)
			joypad.set({A = true})
			waitFrames(2)
			joypad.set({Left = true})
			waitFrames(1)
			joypad.set({A = true})
	
			
			while (mainmemory.readbyte(0x38A0) ~= 0x50 and not OnimushaTactics.endFlag) do
				--print("wait for 0x50")
				endFlag = waitFrameBreak(OnimushaTactics)
				if (endFlag) then
					print("endFlag 1")
					return
				end
			end
			while (mainmemory.readbyte(0x38A0) ~= 0x19 and not OnimushaTactics.endFlag) do
				--print("wait for 0x19")
				endFlag = waitFrameBreak(OnimushaTactics)
				if (endFlag) then
--					print("endFlag 2")
					return
				end
			end
		elseif act.name == "Select Unit" or act.name == "Move" or act.name == "Attack" then
			targetX = act.x
			targetY = act.y
--			print(targetX .. "," .. targetY)
--			print(CursorX .. "," .. CursorY)
			while (CursorX < targetX) do
				joypad.set({Left = true})
				emu.frameadvance()
				CursorX = mainmemory.readbyte(DataPtr2 + 0x62E)	
			end
			
			while (CursorX > targetX) do
				joypad.set({Right = true})
				emu.frameadvance()
				CursorX = mainmemory.readbyte(DataPtr2 + 0x62E)	
			end 

			while (CursorY > targetY) do
				joypad.set({Down = true})
				emu.frameadvance()
				CursorY = mainmemory.readbyte(DataPtr2 + 0x630)	
			end 
			
			while (CursorY < targetY) do
				joypad.set({Up = true})
				emu.frameadvance()
				CursorY = mainmemory.readbyte(DataPtr2 + 0x630)	
			end 
			
			waitFrames(10)
			joypad.set({A = true})
			while (mainmemory.readbyte(0x38A0) ~= 0x1D and not OnimushaTactics.endFlag) do
				endFlag = waitFrameBreak(OnimushaTactics)
				if (endFlag) then
					return 
				end
			end	
			waitFrames(10)
		elseif act.name == "Select Move" then
			while (mainmemory.readbyte(0x281F) ~= 0) do
				joypad.set({Down = true})
				emu.frameadvance()
			end
			joypad.set({A = true})
			while (mainmemory.readbyte(0x38A0) ~= 0x1A) do
				emu.frameadvance()
			end
		elseif act.name == "Select Attack" then
			while (mainmemory.readbyte(0x281F) ~= 1) do
				joypad.set({Down = true})
				emu.frameadvance()
			end
			joypad.set({A = true})
			while (mainmemory.readbyte(0x38A0) ~= 0x1E and not OnimushaTactics.endFlag) do
				endFlag = waitFrameBreak(OnimushaTactics)
				if (endFlag) then
					return 
				end
			end
		elseif act.name == "Done" then
			joypad.set({Up = true})
			emu.frameadvance()
			joypad.set({A = true})
			waitFrames(10)
			
			--check if any units still to act
			found = false
			for i=0,15,1 do
				curUnit = UNIT_ADDR + i*UNIT_SIZE
				unitID = mainmemory.readbyte(curUnit)
				unitFlags = mainmemory.readbyte(curUnit+0xB8)
				unitStatus = mainmemory.readbyte(curUnit+0x4A)
							
				if (unitID > 0 and unitID <= 16)    -- if unit is player-controlled
					and bit.band(unitFlags,1) == 0  -- if unit has not finished turn
					and bit.band(unitStatus,1) == 1 -- if unit is alive
					then
					found = true
					break
				end
			end			
			
			--If there are still more units
			if found then
				while (mainmemory.readbyte(0x38A0) ~= 0x19) do
					emu.frameadvance()
				end
			--If there are no more units to act, proceed to next turn
			else		
				while (mainmemory.readbyte(0x38A0) ~= 0x50 and not OnimushaTactics.endFlag) do
					--print("wait for 0x50")
					endFlag = waitFrameBreak(OnimushaTactics)
					if (endFlag) then
--						print("endFlag 1")
						return
					end
				end
				while (mainmemory.readbyte(0x38A0) ~= 0x19 and not OnimushaTactics.endFlag) do
					--print("wait for 0x19")
					endFlag = waitFrameBreak(OnimushaTactics)
					if (endFlag) then
--						print("endFlag 2")
						return
					end
				end
			end
		else
			print("Perform ERROR: \"" .. act.name .. "\" not known")
		end
	end,
	
	rollout = function()
--		print("rollout")
		--Rollout logic:
		---Arbitrary action until end
		endFlag = false
		while (not endFlag) do
			acts = OnimushaTactics:getActs()
			-- random item
			if #acts == 0 then
				endFlag = true
				return
			end
			a = acts[math.random(#acts)]
--			print(a.id)
			OnimushaTactics:perform(a)
		end
	end,
	
	score = function()
		UNIT_ADDR = 0x28DC
		UNIT_SIZE = 0xEC
		
		if mainmemory.readbyte(0x38A0) == 0x4B then
			return 30000 - emu.framecount()
		else
			print(mainmemory.readbyte(0x38A0))
			return 0
		end
		
	end
}

		SystemDataPtr = mainmemory.read_s16_le(0x2538)
		GameDataPtr = mainmemory.read_s16_le(SystemDataPtr + 0xC)
		CursorX = mainmemory.readbyte(GameDataPtr + 0x62E)
		CursorY = mainmemory.readbyte(GameDataPtr + 0x630)

		UnitXPosArr = GameDataPtr + 0xA8C
		UnitYPosArr = GameDataPtr + 0xA9C

		UNIT_ADDR = 0x28DC
		UNIT_SIZE = 0xEC
		
		gameMode = mainmemory.readbyte(0x38A0)

print("Starting simulation")
simulate(OnimushaTactics, 100, 100)