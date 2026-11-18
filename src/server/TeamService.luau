-- Brainrot Boulevard v3: teams (clans). Up to 5 players share a team
-- with a name, a shared vault, and a team leaderboard row. Creating a
-- team costs $10,000 in-game cash; joining is free while the team has
-- a slot. Members deposit cash into the vault, and every hour the
-- vault pays each member $500 — but never more than the vault holds,
-- so a team that never deposits earns nothing. The vault is the
-- team's bank, not a money printer: deposits are the only way in.
-- Teams are server-authoritative: the client only names the team and
-- the amount; membership, the vault and the payouts live here. The
-- team leaderboard row is the team's combined lifetime earnings, so a
-- team climbs by its members earning, not by one rich member alone.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Utils = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Utils"))

local TeamService = {}

local DataService
local LeaderboardService
local updateRemote

-- teams[name] = { name, leader (Player), members = { [Player] = true },
--   vault (number), createdAt (os.clock()), totalDeposited (number) }
local teams = {}
-- playerTeams[Player] = team name, the fast lookup for membership.
local playerTeams = {}

local function announceTo(player, text)
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	local announce = remotes and remotes:FindFirstChild("Announce")
	if announce then
		announce:FireClient(player, text)
	end
end

local function announceAll(text)
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	local announce = remotes and remotes:FindFirstChild("Announce")
	if announce then
		announce:FireAllClients(text)
	end
end

-- A team name is valid when it is 1-16 letters, digits, spaces and
-- - _ . only, and no other team already holds it (case-insensitive).
local function validTeamName(name)
	if not name or #name == 0 or #name > Config.TEAM_NAME_MAX_LEN then
		return false
	end
	if not name:match("^[%w%s%._%-]+$") then
		return false
	end
	local lower = name:lower()
	for existing in pairs(teams) do
		if existing:lower() == lower then
			return false
		end
	end
	return true
end

-- Find a team by name, case-insensitive, so "noodle gang" finds
-- "Noodle Gang" for the player typing it into the team panel.
function TeamService.findTeam(name)
	if not name or name == "" then
		return nil
	end
	local lower = name:lower()
	for teamName, team in pairs(teams) do
		if teamName:lower() == lower then
			return team
		end
	end
	return nil
end

-- Which team is this player on, if any? Returns the team or nil.
function TeamService.teamOf(player)
	local name = playerTeams[player]
	return name and teams[name] or nil
end

-- How many members does this team have right now?
function TeamService.memberCount(team)
	local count = 0
	for _ in pairs(team.members) do
		count += 1
	end
	return count
end

-- The team's combined lifetime earnings: every member's TotalEarned
-- added up. This is the team leaderboard row — a team climbs when its
-- members earn, not when one member gets rich alone.
function TeamService.combinedEarnings(team)
	local total = 0
	for member in pairs(team.members) do
		local state = DataService and DataService.get(member)
		if state then
			total += state.TotalEarned
		end
	end
	return total
end

-- All teams sorted by combined earnings, best first, each with its
-- name, member count, vault and earnings. The HUD team panel shows
-- the top 5; the leaderboard service records the top team hourly.
function TeamService.topTeams(count)
	local rows = {}
	for _, team in pairs(teams) do
		table.insert(rows, {
			name = team.name,
			members = TeamService.memberCount(team),
			vault = math.floor(team.vault),
			earned = math.floor(TeamService.combinedEarnings(team)),
		})
	end
	table.sort(rows, function(a, b)
		return a.earned > b.earned
	end)
	local top = {}
	for i = 1, math.min(count or 5, #rows) do
		table.insert(top, rows[i])
	end
	return top
end

-- The snapshot the HUD team panel (Y) reads: the caller's team (or
-- nothing), its members and vault, and the top-5 team board.
function TeamService.snapshotFor(player)
	local team = TeamService.teamOf(player)
	local mine = nil
	if team then
		local members = {}
		for member in pairs(team.members) do
			table.insert(members, member.Name)
		end
		table.sort(members)
		mine = {
			name = team.name,
			leader = team.leader and team.leader.Name or "?",
			members = members,
			vault = math.floor(team.vault),
			deposited = math.floor(team.totalDeposited),
			earned = math.floor(TeamService.combinedEarnings(team)),
			hourly = Config.TEAM_VAULT_HOURLY,
		}
	end
	return {
		team = mine,
		top = TeamService.topTeams(5),
		createCost = Config.TEAM_CREATE_COST,
		maxMembers = Config.TEAM_MAX_MEMBERS,
	}
end

local function pushUpdateTo(player)
	if updateRemote and player and player.Parent then
		updateRemote:FireClient(player, TeamService.snapshotFor(player))
	end
end

local function pushUpdateToTeam(team)
	for member in pairs(team.members) do
		pushUpdateTo(member)
	end
end

local function pushUpdateAll()
	if updateRemote then
		for _, player in ipairs(Players:GetPlayers()) do
			pushUpdateTo(player)
		end
	end
end

-- Create a team: pay $10,000, become its leader and first member.
-- The name must be fresh and valid; a player already on a team
-- cannot start another one.
function TeamService.create(player, name)
	local state = DataService.get(player)
	if not state then
		return
	end
	if TeamService.teamOf(player) then
		announceTo(player, "You are already on a team — leave it first.")
		return
	end
	if not validTeamName(name) then
		announceTo(player, "That team name is taken or invalid (1-16 letters, digits, spaces).")
		return
	end
	if not DataService.spendCash(state, Config.TEAM_CREATE_COST) then
		announceTo(player, "Creating a team costs " .. Utils.formatMoney(Config.TEAM_CREATE_COST) .. "!")
		return
	end
	local team = {
		name = name,
		leader = player,
		members = { [player] = true },
		vault = 0,
		createdAt = os.clock(),
		totalDeposited = 0,
	}
	teams[name] = team
	playerTeams[player] = name
	state.TeamName = name
	announceAll(player.Name .. " founded team " .. name .. "! Type its name in the team panel (Y) to join.")
	pushUpdateAll()
end

-- Join a team: free, while it has a slot (max 5). A player already on
-- a team must leave it first; the leader's slot is never joinable.
function TeamService.join(player, name)
	local state = DataService.get(player)
	if not state then
		return
	end
	if TeamService.teamOf(player) then
		announceTo(player, "You are already on a team — leave it first.")
		return
	end
	local team = TeamService.findTeam(name)
	if not team then
		announceTo(player, "No team by that name exists.")
		return
	end
	if TeamService.memberCount(team) >= Config.TEAM_MAX_MEMBERS then
		announceTo(player, "Team " .. team.name .. " is full (" .. tostring(Config.TEAM_MAX_MEMBERS) .. " members).")
		return
	end
	team.members[player] = true
	playerTeams[player] = team.name
	state.TeamName = team.name
	for member in pairs(team.members) do
		announceTo(member, player.Name .. " joined team " .. team.name .. "!")
	end
	pushUpdateToTeam(team)
	pushUpdateAll()
end

-- Leave a team. The leader leaving passes the crown to the longest-
-- standing member; the last member leaving dissolves the team and
-- its vault goes with it (deposit wisely, and don't be the last one).
function TeamService.leave(player)
	local team = TeamService.teamOf(player)
	if not team then
		announceTo(player, "You are not on a team.")
		return
	end
	team.members[player] = nil
	playerTeams[player] = nil
	local state = DataService.get(player)
	if state then
		state.TeamName = ""
	end
	if TeamService.memberCount(team) == 0 then
		teams[team.name] = nil
		announceAll("Team " .. team.name .. " dissolved — its last member left.")
	else
		if team.leader == player then
			for member in pairs(team.members) do
				team.leader = member
				break
			end
			announceAll(player.Name .. " left team " .. team.name .. " — " .. team.leader.Name .. " is the new leader.")
		else
			for member in pairs(team.members) do
				announceTo(member, player.Name .. " left team " .. team.name .. ".")
			end
		end
		pushUpdateToTeam(team)
	end
	pushUpdateTo(player)
	pushUpdateAll()
end

-- Deposit cash into the team's vault. At least $100, at most what the
-- player holds. The vault funds the hourly member bonus — deposits
-- are the only way money gets in.
function TeamService.deposit(player, amount)
	local team = TeamService.teamOf(player)
	if not team then
		announceTo(player, "Join a team first (Y) before depositing.")
		return
	end
	local state = DataService.get(player)
	if not state then
		return
	end
	amount = math.floor(tonumber(amount) or 0)
	if amount < Config.TEAM_DEPOSIT_MIN then
		announceTo(player, "Deposits start at " .. Utils.formatMoney(Config.TEAM_DEPOSIT_MIN) .. ".")
		return
	end
	if not DataService.spendCash(state, amount) then
		announceTo(player, "Not enough cash to deposit " .. Utils.formatMoney(amount) .. "!")
		return
	end
	team.vault += amount
	team.totalDeposited += amount
	for member in pairs(team.members) do
		announceTo(member, player.Name .. " deposited " .. Utils.formatMoney(amount) .. " into the " .. team.name .. " vault (" .. Utils.formatMoney(team.vault) .. " total).")
	end
	pushUpdateToTeam(team)
end

-- The hourly vault payout: every member gets $500, but the vault
-- never pays out more than it holds — a broke vault pays nothing, and
-- a vault with $600 pays the first member $500 and the rest nothing
-- until it is topped up again. Paid in member order, so a full team
-- needs a $2,500 vault for everyone to get paid.
function TeamService.payHourlyBonus()
	for _, team in pairs(teams) do
		local paid = {}
		for member in pairs(team.members) do
			if team.vault >= Config.TEAM_VAULT_HOURLY then
				local state = DataService and DataService.get(member)
				if state then
					team.vault -= Config.TEAM_VAULT_HOURLY
					DataService.addCash(state, Config.TEAM_VAULT_HOURLY)
					table.insert(paid, member.Name)
				end
			end
		end
		if #paid > 0 then
			for member in pairs(team.members) do
				announceTo(member, "TEAM VAULT: " .. team.name .. " paid " .. Utils.formatMoney(Config.TEAM_VAULT_HOURLY) .. " to " .. table.concat(paid, ", ") .. ". Vault: " .. Utils.formatMoney(team.vault) .. ".")
			end
		end
		if LeaderboardService then
			LeaderboardService.recordTeam(team.name, TeamService.combinedEarnings(team))
		end
	end
	pushUpdateAll()
end

function TeamService.init(services)
	DataService = services.DataService
	LeaderboardService = services.LeaderboardService
	updateRemote = services.Remotes.TeamUpdate

	services.Remotes.TeamCreate.OnServerEvent:Connect(function(player, name)
		TeamService.create(player, tostring(name or ""))
	end)
	services.Remotes.TeamJoin.OnServerEvent:Connect(function(player, name)
		TeamService.join(player, tostring(name or ""))
	end)
	services.Remotes.TeamLeave.OnServerEvent:Connect(function(player)
		TeamService.leave(player)
	end)
	services.Remotes.TeamDeposit.OnServerEvent:Connect(function(player, amount)
		TeamService.deposit(player, tonumber(amount) or 0)
	end)

	-- A player who leaves the server leaves their team too; the
	-- leader's crown passes on, and a last member out dissolves it.
	Players.PlayerRemoving:Connect(function(player)
		local team = TeamService.teamOf(player)
		if team then
			team.members[player] = nil
			playerTeams[player] = nil
			if TeamService.memberCount(team) == 0 then
				teams[team.name] = nil
			elseif team.leader == player then
				for member in pairs(team.members) do
					team.leader = member
					break
				end
				pushUpdateToTeam(team)
			else
				pushUpdateToTeam(team)
			end
		end
		pushUpdateAll()
	end)

	-- The vault pays out once an hour, on the hour loop.
	task.spawn(function()
		while true do
			task.wait(3600)
			TeamService.payHourlyBonus()
		end
	end)
end

return TeamService
