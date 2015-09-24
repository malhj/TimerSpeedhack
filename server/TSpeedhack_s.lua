-- Settings

lenience = 20000 -- The maximum difference between reported timer durations before a player is assumed to be speedhacking.
-- Remember that latency is a factor: there will always be a difference of the player's ping. Ping does not constantly increase difference whereas speedhacking does,
-- so by increasing the value, you reduce the risk of the script banning people with high ping, but make it take longer for an actual speedhacker to be banned.
--
-- 20,000, I find, is a good value: 20,000 ping is almost unheard of (the ESA's Mars probe had better ping than that when it was orbiting Mars), and it takes less than a minute to kick a 2x speedhacker.
--
abnormalDifference = 1000 -- The difference at which the script will log any seconds where this difference has been noted.
fileSizeMax = 1 -- The maximum filesize, in mb, before the log file of a player is cleared to save space.
kString = ("Punished for speedhacking - TimerSpeedhack" ) -- The message to deliver when kicked/banned.

function Punish(p)
	p:Kick(kString) -- change this line to p:Ban(kString) if you want to ban users instantly (not recommended)
end

-- This part of the code makes the timers that measure elapsed connection time.

TimerTable = {}

function DefineNewPlayerTimer(args) -- Inherit a table that allows us to access the joined player's data
	TimerTable[args.player:GetId()] = Timer() -- Make a timer to measure the elapsed connection time.
	-- It is stored based on ID because of the nature of Steam; two players can have the same name.
	-- Player ID is similar to a queue system, where the later you join, the higher your PID is likely to be.
end

Events:Subscribe("PlayerJoin", DefineNewPlayerTimer) -- Subscribe the above function to trigger whenever a player joins the game

function DefinePlayerTimers()
	for p in Server:GetPlayers() do
		TimerTable[p:GetId()] = Timer() -- If the module is reloaded, it will have to be made again for everyone, as to mirror the client.
		--print("Defining timers for player", p:GetName()) Previous debug
		
	end
end

Events:Subscribe("ModuleLoad", DefinePlayerTimers) -- Subscribe the above function to be triggered when the module loads on the server

-- This part of the code checks client timers.

-- Checking function

function CompareValues(args)
	clientReckons = args.timerValue
	if TimerTable[args.player:GetId()] then
		serverReckons = TimerTable[args.player:GetId()]:GetMilliseconds()
	else
		serverReckons = clientReckons -- For a split second when the script is initializing, the timer will be nil, so this is error prevention
		-- Would use pcall() to clean up a bit, but it wouldn't make much difference on readibility and is probably slower.
		--print(table.unpack(TimerTable)) Debug
	end
	
	difference = math.abs(clientReckons - serverReckons) -- Use abs because we compare using positive values
	--print("Compared timer values of player " .. args.player:GetName() .. ": Difference found of " .. tostring(difference) .. "ms.")
	if difference > lenience then -- The lower the value, the quicker it will detect speedhackers (stock value of 20000 takes around 20 seconds to kick a 2x speedhacker, 2x being the minimum Cheat Engine gives)
	-- However, the lower it is the more likely it is that someone with high ping will be kicked wrongly.
		Punish(args.player)
	end
	if difference > abnormalDifference then -- Log any suspicious activity. Useful if more conclusive evidence is needed.
		--print("Writing abnormal difference down") Previous debug
		local id = tostring(args.player:GetSteamId().id)
		local file = io.open(args.player:GetName().. " - " .. id .. ".txt", "a")
		-- The above will produce a specific file for each player with logged suspicious activity.
		-- It uses playername and steamid to preserve accurate evidence.
		-- If, for instance, it created a log file on http://steamcommunity.com/id/gabelogannewell, which is the CEO of Valve's profile, the filename would read:
		--
		-- Rabscuttle - 76561197960287930
		-- Due to the way that steam names work, (one name can be used by an infinite amount of people), the unique SteamID of each player is used to avoid overwriting.
		--
		file:write("[" .. os.date("!%c") .. "] The script has flagged player " .. args.player:GetName() .. ". Timer difference: " .. difference .. "\n") -- os.date("!%C"), outputs the date and time for logging purposes
		local filesize = file:seek("end") -- Get the filesize by seeing how many characters are before the end
		file:close()
		
		if filesize > fileSizeMax*1000000 then -- If over maximum size (multiply by 1 million because filesize is delivered in bytes, and the variable is in megabytes)
			local fileClear = io.open(args.player:GetName()..".txt", "w+") -- Open in w+ to clear
			fileClear:close()
		end
	end
	
end

Network:Subscribe("PlayerSpeedhackTimer", CompareValues) -- Make the above code run when the appropriate Network:Send is detected from the client