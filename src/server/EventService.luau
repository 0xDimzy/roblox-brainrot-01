-- Brainrot Boulevard: events. One rolls every 90 seconds and runs for a
-- minute: Golden Hour doubles everyone's income, Brainrot Rain drops rare
-- characters on the conveyor, and the Tsunami sweeps the map — anyone not
-- standing on their own base is knocked down and drops what they carry.
-- startEvent is also the TOUR.json hook reviewers use to reach a screen.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local EventService = {}

local DataService
local ConveyorService
local BaseService
local WorldBuilder

local EVENT_NAMES = { "GoldenHour", "BrainrotRain", "Tsunami" }
local activeEvent = ""
local eventEndsAt = 0

local function announceAll(text)
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	local announce = remotes and remotes:FindFirstChild("Announce")
	local banner = remotes and remotes:FindFirstChild("EventBanner")
	if announce then
		announce:FireAllClients(text)
	end
	if banner then
		banner:FireAllClients(text)
	end
end

function EventService.init(services)
	DataService = services.DataService
	ConveyorService = services.ConveyorService
	BaseService = services.BaseService
	WorldBuilder = services.WorldBuilder

	task.spawn(function()
		while true do
			task.wait(Config.EVENT_INTERVAL_SECONDS)
			EventService.startEvent(EVENT_NAMES[math.random(1, #EVENT_NAMES)])
		end
	end)
end

function EventService.active()
	if os.clock() < eventEndsAt then
		return activeEvent
	end
	return ""
end

-- Start an event by name. Safe to call twice: a running event is replaced.
function EventService.startEvent(name)
	activeEvent = name
	eventEndsAt = os.clock() + Config.EVENT_DURATION_SECONDS

	if name == "GoldenHour" then
		DataService.setEventMultiplier(2)
		announceAll("GOLDEN HOUR! All income DOUBLED for 60 seconds!")
		task.delay(Config.EVENT_DURATION_SECONDS, function()
			if EventService.active() == "" then
				DataService.setEventMultiplier(1)
			end
		end)
	elseif name == "BrainrotRain" then
		ConveyorService.rainRares(5)
		announceAll("BRAINROT RAIN! Five Epic-or-better brainrots hit the conveyor!")
	elseif name == "Tsunami" then
		announceAll("TSUNAMI! A wave is sweeping the map — DASH HOME to your base!")
		EventService.sweepTsunami()
	end
end

-- The wave crosses the map west to east over 12 seconds. Players caught
-- outside their own base are knocked down and drop what they carry; the
-- conveyor's brainrots are washed away.
function EventService.sweepTsunami()
	local wave = WorldBuilder.Wave
	if not wave then
		return
	end
	local startX = -130
	local endX = 130
	local steps = 60
	local hitPlayers = {}
	task.spawn(function()
		for i = 0, steps do
			local t = i / steps
			wave.Position = Vector3.new(startX + (endX - startX) * t, 13, 0)
			-- Anyone the wave passes over, off their own base, goes down.
			for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
				if not hitPlayers[player] then
					local character = player.Character
					local root = character and character:FindFirstChild("HumanoidRootPart")
					local humanoid = character and character:FindFirstChildOfClass("Humanoid")
					local state = DataService.get(player)
					if root and humanoid and state then
						local waveX = wave.Position.X
						if math.abs(root.Position.X - waveX) < 6 then
							if not BaseService.isOnPlot(root.Position, state.PlotIndex) then
								hitPlayers[player] = true
								humanoid.Sit = true
								root.AssemblyLinearVelocity = Vector3.new(30, 15, 0)
								if state.Carrying then
									local StealService = require(script.Parent:WaitForChild("StealService"))
									StealService.dropCarried(player, state)
								end
								local remotes = ReplicatedStorage:FindFirstChild("Remotes")
								local announce = remotes and remotes:FindFirstChild("Announce")
								if announce then
									announce:FireClient(player, "The tsunami caught you! Get back to your base!")
								end
							end
						end
					end
				end
			end
			task.wait(Config.TSUNAMI_SWEEP_SECONDS / steps)
		end
		-- The wave washes the conveyor clean, then parks off-map again.
		ConveyorService.clearBelt()
		wave.Position = Vector3.new(-130, 13, 0)
	end)
end

return EventService
