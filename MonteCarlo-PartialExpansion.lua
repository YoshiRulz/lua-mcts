function waitForExecution(addr)
	flag = false
	event.onmemoryexecute(function()
		flag = true
	end, addr)
	while ~flag do
		emu.frameadvance()
	end
end

function waitFrames(n)
	for i=0,n,1 do
		emu.frameadvance()
	end
end

function Split(s, delimiter)
    result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end

function node(n)
	return { name = n, state = nil, parent = nil, children = nil, cn = 0, value = 0, visits = 0 } 
end

function selection(node)
	topChild = nil
	topScore = -999
	
	c = math.sqrt(2)
	k = 0.5
	
	for i, kid in pairs(node.children) do
		if (kid.visits > 0) then
			score = (kid.value / (kid.visits) ) + c * math.sqrt( ( 2 * math.log(node.visits) ) / (kid.visits) )
		else
			score = k + c * math.sqrt( ( 2 * math.log(node.visits) ) / (node.cn + 1) )
		end
		if score > topScore then
			topChild = kid
			topScore = score
		end
	end
	
	--If unvisited child is chosen, increase the "expanded children" counter
	if topChild.visits == 0 then node.cn = node.cn + 1 end
	
	return topChild
end

function MonteCarloTreeSearch(game, n, root)

	for i=1,n,1 do
		curNode = root
		curNode.visits = curNode.visits + 1
		
		while (curNode.state ~= nil) do
			if (curNode.children == nil) then
				newkids = game.expand(curNode)
				curNode.children = newkids
			end
			curNode = selection(curNode)
			curNode.visits = curNode.visits + 1
		end
		
		memorysavestate.loadcorestate(curNode.parent.state)
		game.perform(curNode.name)
		curNode.state = memorysavestate.savecorestate()
		
		result = game.rollout()
		
		if game.loseFlag then
			result = 0
			game.loseFlag = false
		end
		
		while (curNode ~= nil) do
			curNode.value = curNode.value + result;
			curNode = curNode.parent
		end
		
	end
	
	topKid = nil
	topScore = -999
	
	for i, kid in pairs(root.children) do
		if (kid.value / kid.visits > topScore) then
			topKid = kid
			topScore = kid.value / kid.visits
		end 
	end
	
	return topKid
end

function simulate(game, N, n)

	for i, trigger in ipairs(game.winTriggers) do
		event.onmemoryexecute(game.setWinFlag, trigger)
	end

	for i, trigger in ipairs(game.loseTriggers) do
		event.onmemoryexecute(game.setLoseFlag, trigger)
	end

	root = node(nil)
	root.state = memorysavestate.savecorestate()
	for i=1,N,1 do
		root = MonteCarloTreeSearch(game, n, root)
		memorysavestate.loadcorestate(root.state)
		root.parent = nil
	end
end

SuperMarioBros = { 
	name = "Super Mario Bros.",
	
	winFlag = false,
	winTriggers = 
	{
		0xB2A4 -- FlagpoleSlide
	},
	setWinFlag = function()
		winFlag = true
	end,
	
	loseFlag = false,
	loseTriggers = 
	{
		0xB269 -- PlayerDeath
	},
	setLoseFlag = function()
		loseFlag = true
	end,
	
	expand = function(p)
		acts = {"L", "R", "LA", "RA"}
		kids = {}
		for i, act in ipairs(acts) do
			kids[act] = node(act)
			kids[act].parent = p
		end
		return kids
	end,
	
	perform = function(act)
		MOTIF_SIZE = 20
		if		(act == "L") then
			for i=1,MOTIF_SIZE,1 do 
				joypad.set({B = true, Left = true}, 1)
				emu.frameadvance()
			end		
		elseif	(act == "R") then 
			for i=1,MOTIF_SIZE,1 do 
				joypad.set({B = true, Right = true}, 1)
				emu.frameadvance()
			end
		elseif (act == "LA") then
			for i=1,MOTIF_SIZE,1 do 
				joypad.set({B = true, Left = true, A = true}, 1)
				emu.frameadvance()
			end
		elseif (act == "RA") then
			for i=1,MOTIF_SIZE,1 do 
				joypad.set({B = true, Right = true, A = true}, 1)
				emu.frameadvance()
			end
		end
	end,
	
	rollout = function()
		for i=1,40,1 do
				joypad.set({B = true, Right = true}, 1)
				emu.frameadvance()			
				joypad.set({B = true, Right = true, A = true}, 1)
				emu.frameadvance()
		end
		--[[
		total = 0
		for i = 0,4,1 do
			total = total + math.pow(10,i) * mainmemory.readbyte(0x7DC - i)
		end 
		--]]
		
		total = 256*mainmemory.readbyte(0x6D) + mainmemory.readbyte(0x3AD)
		return total
	end,
}

OnimushaTactics = { 
	name = "Onimusha Tactics",
	
	winFlag = false,
	winTriggers = 
	{

	},
	setWinFlag = function()
		winFlag = true
	end,
	
	loseFlag = false,
	loseTriggers = 
	{

	},
	setLoseFlag = function()
		loseFlag = true
	end,
	
	expand = function(p)
		acts = {}
	
		units = {}
		UNIT_ADDR = 0x28DC
		UNIT_SIZE = 0xEC
		
		total = 0
		for i=0,2,1 do
			curUnit = UNIT_ADDR + UNIT_SIZE*i
			unitID = mainmemory.readbyte(curUnit)
			unitHP = mainmemory.readbyte(curUnit + 46)
			if unitID ~= 0 and unitID < 15 and unitHP > 0 then 
				units[i] = true
			end 
		end
		
		restore = memorysavestate.savecorestate()
		
		SpriteDataPtr = mainmemory.read_s16_le(0x2538)
		DataPtr2 = mainmemory.read_s16_le(SpriteDataPtr + 0xC)
		CursorY = mainmemory.readbyte(DataPtr2 + 0x62E)
		CursorX = mainmemory.readbyte(DataPtr2 + 0x630)		
		
		for k,v in pairs(units) do
			memorysavestate.loadcorestate(restore)
			UnitY = mainmemory.readbyte(DataPtr2 + 0xA8C + k)
			UnitX = mainmemory.readbyte(DataPtr2 + 0xA9C + k)
			
			while (CursorX < UnitX) do
				joypad.set({Up = true})
				emu.frameadvance()
				joypad.set({Up = false})
				emu.frameadvance()
				CursorX = mainmemory.readbyte(DataPtr2 + 0x630)	
			end
			
			while (CursorX > UnitX) do
				joypad.set({Down = true})
				emu.frameadvance()
				joypad.set({Down = false})
				emu.frameadvance()
				CursorX = mainmemory.readbyte(DataPtr2 + 0x630)	
			end 

			while (CursorY > UnitY) do
				joypad.set({Right = true})
				emu.frameadvance()
				joypad.set({Right = false})
				emu.frameadvance()
				CursorY = mainmemory.readbyte(DataPtr2 + 0x62E)	
			end 
			
			while (CursorY < UnitY) do
				joypad.set({Left = true})
				emu.frameadvance()
				joypad.set({Left = false})
				emu.frameadvance()
				CursorY = mainmemory.readbyte(DataPtr2 + 0x62E)	
			end 		

			waitFrames(20)
			
			joypad.set({A = true})
			waitFrames(20)

			bag = {}
			event.onmemoryexecute(
				function()
					name = tostring(emu.getregister("R2")) .. " " .. tostring(emu.getregister("R1"))
					bag[name] = true
				end, 0x0806870C
			)

			joypad.set({A = true})
			waitFrames(20)
			
			for k2,v in pairs(bag) do
				coords = Split(k2," ")
				if tonumber(coords[1]) ~= UnitX or tonumber(coords[2]) ~= UnitY then 
					actname = tostring(k) .. " " .. k2
					acts[actname] = true
				end
			end

		end
		
		kids = {}
		for k,v in pairs(acts) do
			kids[k] = node(k)
			kids[k].parent = p
		end
		
		return kids
	end,
	
	perform = function(act)
	
		SpriteDataPtr = mainmemory.read_s16_le(0x2538)
		DataPtr2 = mainmemory.read_s16_le(SpriteDataPtr + 0xC)
		CursorY = mainmemory.readbyte(DataPtr2 + 0x62E)
		CursorX = mainmemory.readbyte(DataPtr2 + 0x630)		
	
		actArray = Split(act," ")
		print(act)
		print(actArray)
		unitNo = tonumber(actArray[1])
		destX = tonumber(actArray[2])
		destY = tonumber(actArray[3])

		UnitY = mainmemory.readbyte(DataPtr2 + 0xA8C + unitNo)
		UnitX = mainmemory.readbyte(DataPtr2 + 0xA9C + unitNo)
			
		while (CursorX < UnitX) do
			joypad.set({Up = true})
			emu.frameadvance()
			joypad.set({Up = false})
			emu.frameadvance()
			CursorX = mainmemory.readbyte(DataPtr2 + 0x630)	
		end
			
		while (CursorX > UnitX) do
			joypad.set({Down = true})
			emu.frameadvance()
			joypad.set({Down = false})
			emu.frameadvance()
			CursorX = mainmemory.readbyte(DataPtr2 + 0x630)	
		end 

		while (CursorY > UnitY) do
			joypad.set({Right = true})
			emu.frameadvance()
			joypad.set({Right = false})
			emu.frameadvance()
			CursorY = mainmemory.readbyte(DataPtr2 + 0x62E)	
		end 
			
		while (CursorY < UnitY) do
			joypad.set({Left = true})
			emu.frameadvance()
			joypad.set({Left = false})
			emu.frameadvance()
			CursorY = mainmemory.readbyte(DataPtr2 + 0x62E)	
		end 		

			waitFrames(1000)
			
			joypad.set({A = true})
			waitFrames(1000)

			joypad.set({A = true})
			waitFrames(1000)

			while (CursorX < destX) do
				joypad.set({Up = true})
				emu.frameadvance()
				joypad.set({Up = false})
				emu.frameadvance()
				CursorX = mainmemory.readbyte(DataPtr2 + 0x630)	
			end
			
			while (CursorX > destX) do
				joypad.set({Down = true})
				emu.frameadvance()
				joypad.set({Down = false})
				emu.frameadvance()
				CursorX = mainmemory.readbyte(DataPtr2 + 0x630)	
			end 

			while (CursorY > destY) do
				joypad.set({Right = true})
				emu.frameadvance()
				joypad.set({Right = false})
				emu.frameadvance()
				CursorY = mainmemory.readbyte(DataPtr2 + 0x62E)	
			end 
			
			while (CursorY < destY) do
				joypad.set({Left = true})
				emu.frameadvance()
				joypad.set({Left = false})
				emu.frameadvance()
				CursorY = mainmemory.readbyte(DataPtr2 + 0x62E)	
			end 				

			joypad.set({A = true})
			waitFrames(1000)
			
			joypad.set({Up = true})
			emu.frameadvance()
			joypad.set({A = true})
			emu.frameadvance()
			--new player turn
			waitForExecution(0x08007ea0)
			joypad.set({A = true})
			waitFrames(600)
		
	end,
	
	rollout = function()
		--Rollout logic:
		--1) Act with the first available unit
		--2) If an enemy can be attacked, attack it
		--3) Else, randomly move
		--4) Repeat until end
		
		UNIT_ADDR = 0x28DC
		UNIT_SIZE = 0xEC
		
		total = 0
		for i=0,15,1 do
			curUnit = UNIT_ADDR + UNIT_SIZE*i
			unitID = mainmemory.readbyte(curUnit)
			if unitID ~= 0 and unitID < 15 then 
				unitLVL = mainmemory.readbyte(curUnit+40)
				unitEXP = mainmemory.readbyte(curUnit+180)
				total = total + 100*unitLVL + unitEXP
			end 
		end
		
		return total
		
	end,
}

simulate(OnimushaTactics, 10, 10)