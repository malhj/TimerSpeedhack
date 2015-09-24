function DefineTimer()
	SpeedhackTimer = Timer() -- Effectively measures the elapsed connection time.
end

Events:Subscribe("ModuleLoad", DefineTimer) -- Subscribe the above function to be run when the module is loaded on the client

-- Every-second checks
SecondTimer = Timer() -- Instance a new timer (begins running from this line)

function SecondCheck()
	if SecondTimer:GetSeconds() > 1 then -- This will be checked once every frame, but due to this if, the enclosed code will only actually run once per second
		--print("Sending data to server about timers...")
		Network:Send("PlayerSpeedhackTimer", {timerValue = SpeedhackTimer:GetMilliseconds(), player = LocalPlayer}) -- Send data to the server about the client timer
		SecondTimer:Restart()
	end
end

Events:Subscribe("Render", SecondCheck) -- Subscribe the above function to run every frame

