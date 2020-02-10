
--[[
	 _______                           _                        ______                _              
	|_   __ \                         (_)                     .' ____ \              (_)             
	  | |__) _ .--. .---. _ .--..--.  __ __   _  _ .--..--.   | (___ \_|.---. _ .--. __ .---. .--.   
	  |  ___[ `/'`\/ /__\[ `.-. .-. |[  [  | | |[ `.-. .-. |   _.____`./ /__\[ `/'`\[  / /__\( (`\]  
	 _| |_   | |   | \__.,| | | | | | | || \_/ |,| | | | | |  | \____) | \__.,| |    | | \__.,`'.'.  
	|_____| [___]   '.__.[___||__||__[___'.__.'_[___||__||__]  \______.''.__.[___]  [___'.__.[\__) ) 

	Author: Ark223

	Changelog:

	v1.0.1
	+ Fixed minor bug

	v1.0
	+ Initial release [imported Cassiopeia]

--]]

local GlobalVersion = 1.01

local Champions = {
	["Cassiopeia"] = function() return Cassiopeia:__init() end
}

local Versions = {
	["Cassiopeia"] = "1.0.1"
}

-- Init

local MathAbs, MathAtan, MathAtan2, MathAcos, MathCeil, MathCos, MathDeg, MathFloor, MathHuge, MathMax, MathMin, MathPi, MathRad, MathSin, MathSqrt = math.abs, math.atan, math.atan2, math.acos, math.ceil, math.cos, math.deg, math.floor, math.huge, math.max, math.min, math.pi, math.rad, math.sin, math.sqrt
local DrawCircle, DrawLine, GameCanUseSpell, GameLatency, GameTimer, GameHeroCount, GameHero, GameMinionCount, GameMinion = Draw.Circle, Draw.Line, Game.CanUseSpell, Game.Latency, Game.Timer, Game.HeroCount, Game.Hero, Game.MinionCount, Game.Minion
local TableInsert, TableRemove, TableSort = table.insert, table.remove, table.sort
local Icons, Png = "https://raw.githubusercontent.com/Ark223/LoL-Icons/master/", ".png"
local Allies, Enemies = {}, {}

local function DownloadFile(site, file)
	DownloadFileAsync(site, file, function() end)
	local timer = os.clock()
	while os.clock() < timer + 1 do end
	while not FileExist(file) do end
end

local function ReadFile(file)
	local txt = io.open(file, "r")
	local result = txt:read()
	txt:close(); return result
end

local function AutoUpdate()
	DownloadFile("https://raw.githubusercontent.com/Ark223/GoS-Scripts/master/PremiumSeries.version", SCRIPT_PATH .. "PremiumSeries.version")
	if tonumber(ReadFile(SCRIPT_PATH .. "PremiumSeries.version")) > GlobalVersion then
		print("PremiumSeries: Found update! Downloading...")
		DownloadFile("https://raw.githubusercontent.com/Ark223/GoS-Scripts/master/PremiumSeries.lua", SCRIPT_PATH .. "PremiumSeries.lua")
		print("PremiumSeries: Successfully updated. Use 2x F6!")
	end
end

function OnLoad()
	if not FileExist(COMMON_PATH .. "PremiumPrediction.lua") then
		print("PremiumPrediction: Library not found! Please download it and put into Common folder!");
		return
	end
	require "PremiumPrediction"
	for i = 1, Game.HeroCount() do
		local unit = Game.Hero(i)
		if unit and not unit.isMe then
			TableInsert(unit.isEnemy and Enemies or Allies, unit)
		end
	end
	if Champions[myHero.charName] ~= nil then
		Champions[myHero.charName]()
	end
	AutoUpdate()
end


--[[
	┌─┐┌─┐┬┌┐┌┌┬┐
	├─┘│ │││││ │ 
	┴  └─┘┴┘└┘ ┴ 
--]]

local function IsPoint(p)
	return p and p.x and type(p.x) == "number" and p.y and type(p.y) == "number"
end

local function Round(v)
	return v < 0 and MathCeil(v - 0.5) or MathFloor(v + 0.5)
end

class "Point"

function Point:__init(x, y)
	if not x then self.x, self.y = 0, 0
	elseif not y then self.x, self.y = x.x, x.y
	else self.x = x; if y and type(y) == "number" then self.y = y end end
end

function Point:__type()
	return "Point"
end

function Point:__eq(p)
	return self.x == p.x and self.y == p.y
end

function Point:__add(p)
	return Point(self.x + p.x, (p.y and self.y) and self.y + p.y)
end

function Point:__sub(p)
	return Point(self.x - p.x, (p.y and self.y) and self.y - p.y)
end

function Point.__mul(a, b)
	if type(a) == "number" and IsPoint(b) then
		return Point(b.x * a, b.y * a)
	elseif type(b) == "number" and IsPoint(a) then
		return Point(a.x * b, a.y * b)
	end
end

function Point.__div(a, b)
	if type(a) == "number" and IsPoint(b) then
		return Point(a / b.x, a / b.y)
	else
		return Point(a.x / b, a.y / b)
	end
end

function Point:__tostring()
	return "("..self.x..", "..self.y..")"
end

function Point:Clone()
	return Point(self)
end

function Point:Extended(to, distance)
	return self + (Point(to) - self):Normalized() * distance
end

function Point:Magnitude()
	return MathSqrt(self:MagnitudeSquared())
end

function Point:MagnitudeSquared(p)
	local p = p and Point(p) or self
	return p.x * p.x + p.y * p.y
end

function Point:Normalize()
	local dist = self:Magnitude()
	self.x, self.y = self.x / dist, self.y / dist
end

function Point:Normalized()
	local p = self:Clone()
	p:Normalize(); return p
end

function Point:Perpendicular()
	return Point(-self.y, self.x)
end

function Point:Perpendicular2()
	return Point(self.y, -self.x)
end

function Point:Rotate(phi)
	local c, s = MathCos(phi), MathSin(phi)
	self.x, self.y = self.x * c + self.y * s, self.y * c - self.x * s
end

function Point:Rotated(phi)
	local p = self:Clone()
	p:Rotate(phi); return p
end

function Point:Round()
	local p = self:Clone()
	p.x, p.y = Round(p.x), Round(p.y)
	return p
end

--[[
	┌─┐┌─┐┌─┐┌┬┐┌─┐┌┬┐┬─┐┬ ┬
	│ ┬├┤ │ ││││├┤  │ ├┬┘└┬┘
	└─┘└─┘└─┘┴ ┴└─┘ ┴ ┴└─ ┴ 
--]]

class "Geometry"

function Geometry:__init()
end

function Geometry:AngleBetween(p1, p2)
	local angle = MathAbs(MathDeg(MathAtan2(p3.y - p1.y,
		p3.x - p1.x) - MathAtan2(p2.y - p1.y, p2.x - p1.x)))
	if angle < 0 then angle = angle + 360 end
	return angle > 180 and 360 - angle or angle
end

function Geometry:CrossProduct(p1, p2)
	return p1.x * p2.y - p1.y * p2.x
end

function Geometry:Distance(p1, p2)
	if not p1.x or not p2.x then
		local dInfo = debug.getinfo(2)
		print("Method: " .. dInfo.name .. "  Line: " .. dInfo.linedefined)
	end
	return MathSqrt(self:DistanceSquared(p1, p2))
end

function Geometry:DistanceSquared(p1, p2)
	local dx, dy = p2.x - p1.x, p2.y - p1.y
	return dx * dx + dy * dy
end

function Geometry:DotProduct(p1, p2)
	return p1.x * p2.x + p1.y * p2.y
end

function Geometry:GetCircularAOEPos(points, radius)
	local bestPos, count = Point(0, 0), #points
	if count == 0 then return nil, 0 end
	if count == 1 then return points[1], 1 end
	local inside, furthest, id = 0, 0, 0
	for i, point in ipairs(points) do
		bestPos = bestPos + point
	end
	bestPos = bestPos / count
	for i, point in ipairs(points) do
		local distSqr = self:DistanceSquared(bestPos, point)
		if distSqr < radius * radius then inside = inside + 1 end
		if distSqr > furthest then furthest = distSqr; id = i end
	end
	if inside == count then
		return bestPos, count
	else
		TableRemove(points, id)
		return self:GetCircularAOEPos(points, radius)
	end
end

function Geometry:To2D(pos)
	return Point(pos.x, pos.z or pos.y)
end

function Geometry:To3D(pos, y)
	return Vector(pos.x, y or myHero.pos.y, pos.y)
end

--[[
	┌┬┐┌─┐┌┐┌┌─┐┌─┐┌─┐┬─┐
	│││├─┤│││├─┤│ ┬├┤ ├┬┘
	┴ ┴┴ ┴┘└┘┴ ┴└─┘└─┘┴└─
--]]

class "Manager"

function Manager:__init()
	self.Priorities = {
		["Aatrox"] = 3, ["Ahri"] = 4, ["Akali"] = 4, ["Alistar"] = 1, ["Amumu"] = 1, ["Anivia"] = 4, ["Annie"] = 4, ["Aphelios"] = 5, ["Ashe"] = 5, ["AurelionSol"] = 4,
		["Azir"] = 4, ["Bard"] = 3, ["Blitzcrank"] = 1, ["Brand"] = 4, ["Braum"] = 1, ["Caitlyn"] = 5, ["Camille"] = 3, ["Cassiopeia"] = 4, ["Chogath"] = 1, ["Corki"] = 5,
		["Darius"] = 2, ["Diana"] = 4, ["DrMundo"] = 1, ["Draven"] = 5, ["Ekko"] = 4, ["Elise"] = 3, ["Evelynn"] = 4, ["Ezreal"] = 5, ["Fiddlesticks"] = 3, ["Fiora"] = 3,
		["Fizz"] = 4, ["Galio"] = 1, ["Gangplank"] = 4, ["Garen"] = 1, ["Gnar"] = 1, ["Gragas"] = 2, ["Graves"] = 4, ["Hecarim"] = 2, ["Heimerdinger"] = 3, ["Illaoi"] = 3,
		["Irelia"] = 3, ["Ivern"] = 1, ["Janna"] = 2, ["JarvanIV"] = 3, ["Jax"] = 3, ["Jayce"] = 4, ["Jhin"] = 5, ["Jinx"] = 5, ["Kaisa"] = 5, ["Kalista"] = 5, ["Karma"] = 4,
		["Karthus"] = 4, ["Kassadin"] = 4, ["Katarina"] = 4, ["Kayle"] = 4, ["Kayn"] = 4, ["Kennen"] = 4, ["Khazix"] = 4, ["Kindred"] = 4, ["Kled"] = 2, ["KogMaw"] = 5,
		["Leblanc"] = 4, ["LeeSin"] = 3, ["Leona"] = 1, ["Lissandra"] = 4, ["Lucian"] = 5, ["Lulu"] = 3, ["Lux"] = 4, ["Malphite"] = 1, ["Malzahar"] = 3, ["Maokai"] = 2,
		["MasterYi"] = 5, ["MissFortune"] = 5, ["MonkeyKing"] = 3, ["Mordekaiser"] = 4, ["Morgana"] = 3, ["Nami"] = 3, ["Nasus"] = 2, ["Nautilus"] = 1, ["Neeko"] = 4,
		["Nidalee"] = 4, ["Nocturne"] = 4, ["Nunu"] = 2, ["Olaf"] = 2, ["Orianna"] = 4, ["Ornn"] = 2, ["Pantheon"] = 3, ["Poppy"] = 2, ["Pyke"] = 5, ["Qiyana"] = 4, ["Quinn"] = 5,
		["Rakan"] = 3, ["Rammus"] = 1, ["RekSai"] = 2, ["Renekton"] = 2, ["Rengar"] = 4, ["Riven"] = 4, ["Rumble"] = 4, ["Ryze"] = 4, ["Sejuani"] = 2, ["Senna"] = 3, ["Sett"] = 3,
		["Shaco"] = 4, ["Shen"] = 1, ["Shyvana"] = 2, ["Singed"] = 1, ["Sion"] = 1, ["Sivir"] = 5, ["Skarner"] = 2, ["Sona"] = 3, ["Soraka"] = 3, ["Swain"] = 3, ["Sylas"] = 4,
		["TahmKench"] = 1, ["Taliyah"] = 4, ["Talon"] = 4, ["Taric"] = 1, ["Teemo"] = 4, ["Thresh"] = 1, ["Tristana"] = 5, ["Trundle"] = 2, ["Tryndamere"] = 4, ["TwistedFate"] = 4,
		["Twitch"] = 5, ["Udyr"] = 2, ["Urgot"] = 2, ["Varus"] = 5, ["Vayne"] = 5, ["Veigar"] = 4, ["Velkoz"] = 4, ["Vi"] = 2, ["Viktor"] = 4, ["Vladimir"] = 3, ["Volibear"] = 2,
		["Warwick"] = 2, ["Xayah"] = 5, ["Xerath"] = 4, ["XinZhao"] = 3, ["Yasuo"] = 4, ["Yorick"] = 2, ["Yuumi"] = 2, ["Zac"] = 1, ["Zed"] = 4, ["Ziggs"] = 4, ["Zilean"] = 3,
		["Zoe"] = 4, ["Zyra"] = 2
	}
end

function Manager:CalcMagicalDamage(source, target, amount)
	local mr = target.magicResist
	local value = 100 / (100 + (mr * source.magicPenPercent) - source.magicPen)
	if mr < 0 then value = 2 - 100 / (100 - mr)
	elseif (mr * source.magicPenPercent) - source.magicPen < 0 then value = 1 end
	return MathMax(0, MathFloor(value * amount))
end

function Manager:CalcPhysicalDamage(source, target, amount)
	local armor, bonusArmor = target.armor, target.bonusArmor
	local armorPenPercent, bonusArmorPenPercent = source.armorPenPercent, source.bonusArmorPenPercent
	local armorPenFlat = source.armorPen * (0.6 + (0.4 * (target.levelData.lvl / 18)))
	local value = 100 / (100 + (armor * armorPenPercent) - (bonusArmor * (1 - bonusArmorPenPercent)) - armorPenFlat)
	if armor < 0 then value = 2 - 100 / (100 - armor)
	elseif (armor * armorPenPercent) - (bonusArmor * (1 - bonusArmorPenPercent)) - armorPenFlat < 0 then value = 1 end
	return MathMax(0, MathFloor(value * amount))
end

function Manager:GetSpellCooldown(spell)
	return GameCanUseSpell(spell) == ONCOOLDOWN and myHero:GetSpellData(spell).currentCd or
			GameCanUseSpell(spell) == READY and 0 or MathHuge
end

function Manager:GetMinionsAround(pos, range, type)
	local minions = {}
	for i = 1, GameMinionCount() do
		local minion = GameMinion(i)
		if minion and self:IsValid(minion, range, pos) then
			if type == 2 and minion.isAlly or minion.isEnemy then
				TableInsert(minions, minion)
			end
		end
	end
	return minions
end

function Manager:GetOrbwalkerMode()
	if not _G.SDK then return nil end
	return _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_COMBO] and "Combo"
		or _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_HARASS] and "Harass"
		or _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_LANECLEAR] and "Clear"
		or nil
end

function Manager:GetPercentMana()
	return 100 * myHero.mana / myHero.maxMana
end

function Manager:GetPriority(unit)
	local priority = self.Priorities[unit.charName] or 3
	return priority == 2 and 1.5 or
		priority == 3 and 1.75 or
		priority == 4 and 2 or 2.5
end

function Manager:IsReady(spell)
	return GameCanUseSpell(spell) == READY
end

function Manager:IsValid(unit, range, pos)
	local range = range or 12500
	local pos = pos or Geometry:To2D(myHero.pos)
	return unit and
		unit.valid and
		unit.visible and
		not unit.dead and
		unit.health > 0 and
		unit.maxHealth > 5 and
		Geometry:DistanceSquared(pos, Geometry:To2D(unit.pos)) <= range * range
end

--[[
	┌─┐┌─┐┌─┐┌─┐┬┌─┐┌─┐┌─┐┬┌─┐
	│  ├─┤└─┐└─┐││ │├─┘├┤ │├─┤
	└─┘┴ ┴└─┘└─┘┴└─┘┴  └─┘┴┴ ┴
--]]

class "Cassiopeia"

function Cassiopeia:__init()
	self.AAHandler, self.AATimer, self.QueueTimer, self.ShouldWait, self.WindUp = true, 0, 0, 0, 0
	self.Q = {speed = MathHuge, range = 850, delay = 0.75, radius = 150, windup = 0.25, collision = nil, type = "circular"}
	self.W = {speed = MathHuge, range = 700, delay = 0.25, radius = 160, windup = 0.25, collision = nil, type = "circular"}
	self.E = {speed = 2500, range = 700, windup = 0.125}
	self.R = {speed = MathHuge, range = 725, delay = 0.5, radius = 80, angle = 80, windup = 0.5, collision = nil, type = "conic"}
	self.IsPoison = function(name) return name == "cassiopeiaqdebuff" or name == "cassiopeiawpoison" end
	self.CassiopeiaMenu = MenuElement({type = MENU, id = "Cassiopeia", name = "Premium Cassiopeia v" .. Versions[myHero.charName]})
	--self.CassiopeiaMenu:MenuElement({id = "Auto", name = "Auto", type = MENU})
	--self.CassiopeiaMenu.Auto:MenuElement({id = "UseQ", name = "Q [Noxious Blast]", value = true, leftIcon = Icons.."CassiopeiaQ"..Png})
	--self.CassiopeiaMenu.Auto:MenuElement({id = "ManaQ", name = "Q: Mana Manager", value = 35, min = 0, max = 100, step = 5})
	self.CassiopeiaMenu:MenuElement({id = "Combo", name = "Combo", type = MENU})
	self.CassiopeiaMenu.Combo:MenuElement({id = "UseQ", name = "Q [Noxious Blast]", value = true, leftIcon = Icons.."CassiopeiaQ"..Png})
	self.CassiopeiaMenu.Combo:MenuElement({id = "UseW", name = "W [Miasma]", value = true, leftIcon = Icons.."CassiopeiaW"..Png})
	self.CassiopeiaMenu.Combo:MenuElement({id = "UseE", name = "E [Twin Fang]", value = true, leftIcon = Icons.."CassiopeiaE"..Png})
	self.CassiopeiaMenu.Combo:MenuElement({id = "UseR", name = "R [Petrifying Gaze]", value = true, leftIcon = Icons.."CassiopeiaR"..Png})
	self.CassiopeiaMenu.Combo:MenuElement({id = "ModeQ", name = "Q: If Not Poisoned", value = false})
	self.CassiopeiaMenu.Combo:MenuElement({id = "ModeE", name = "E: If Poisoned Only", value = false})
	self.CassiopeiaMenu.Combo:MenuElement({id = "MinW", name = "W: Minimum Enemies", value = 1, min = 1, max = 5, step = 1})
	self.CassiopeiaMenu.Combo:MenuElement({id = "MinR", name = "R: Minimum Enemies", value = 2, min = 1, max = 5, step = 1})
	self.CassiopeiaMenu:MenuElement({id = "Harass", name = "Harass", type = MENU})
	self.CassiopeiaMenu.Harass:MenuElement({id = "UseQ", name = "Q [Noxious Blast]", value = true, leftIcon = Icons.."CassiopeiaQ"..Png})
	self.CassiopeiaMenu.Harass:MenuElement({id = "UseW", name = "W [Miasma]", value = true, leftIcon = Icons.."CassiopeiaW"..Png})
	self.CassiopeiaMenu.Harass:MenuElement({id = "UseE", name = "E [Twin Fang]", value = true, leftIcon = Icons.."CassiopeiaE"..Png})
	self.CassiopeiaMenu.Harass:MenuElement({id = "ModeQ", name = "Q: If Not Poisoned", value = true})
	self.CassiopeiaMenu.Harass:MenuElement({id = "ModeE", name = "E: If Poisoned Only", value = true})
	self.CassiopeiaMenu.Harass:MenuElement({id = "MinW", name = "W: Minimum Enemies", value = 2, min = 1, max = 5, step = 1})
	self.CassiopeiaMenu:MenuElement({id = "LaneClear", name = "LaneClear", type = MENU})
	self.CassiopeiaMenu.LaneClear:MenuElement({id = "UseQ", name = "Q [Noxious Blast]", value = true, leftIcon = Icons.."CassiopeiaQ"..Png})
	self.CassiopeiaMenu.LaneClear:MenuElement({id = "UseE", name = "E [Twin Fang]", value = true, leftIcon = Icons.."CassiopeiaE"..Png})
	self.CassiopeiaMenu.LaneClear:MenuElement({id = "ManaQ", name = "Q: Mana Manager", value = 35, min = 0, max = 100, step = 5})
	self.CassiopeiaMenu:MenuElement({id = "Drawings", name = "Drawings", type = MENU})
	self.CassiopeiaMenu.Drawings:MenuElement({id = "DrawQ", name = "Q: Draw Range", value = true})
	self.CassiopeiaMenu.Drawings:MenuElement({id = "DrawE", name = "E: Draw Range", value = true})
	self.CassiopeiaMenu.Drawings:MenuElement({id = "Track", name = "Track Enemies", value = true})
	self.CassiopeiaMenu:MenuElement({id = "Misc", name = "Misc", type = MENU})
	self.CassiopeiaMenu.Misc:MenuElement({id = "ModeAA", name = "AutoAttacks Disabler", drop = {"Always", "E Is Ready", "On Reached Level", "Toggle Key"}, value = 4})
	self.CassiopeiaMenu.Misc:MenuElement({id = "Toggle", name = "Toggle Autoattacks", key = string.byte("N")})
	self.CassiopeiaMenu.Misc:MenuElement({id = "MinLvl", name = "Minimum Level", value = 6, min = 1, max = 18, step = 1})
	Callback.Add("Tick", function() self:OnTick() end)
	Callback.Add("Draw", function() self:OnDraw() end)
	_G.SDK.Orbwalker:OnPreAttack(function(...) self:OnPreAttack(...) end)
	_G.SDK.Orbwalker:OnPreMovement(function(...) self:OnPreMovement(...) end)
end

-- Methods

function Cassiopeia:CalcFangArrivalTime(unit)
	return Geometry:Distance(self.MyPos, Geometry:To2D(unit.pos)) / self.E.speed + self.E.windup
end

function Cassiopeia:GetTarget(range)
	local units = {}
	for i, enemy in ipairs(Enemies) do
		if Manager:IsValid(enemy, range) then
			TableInsert(units, enemy)
		end
	end
	TableSort(units, function(a, b) return self:PoisonDuration(a) > self:PoisonDuration(b) and
		Manager:CalcMagicalDamage(myHero, a, 100) / (1 + a.health) * Manager:GetPriority(a) >
		Manager:CalcMagicalDamage(myHero, b, 100) / (1 + b.health) * Manager:GetPriority(b)
	end)
	return #units > 0 and units[1] or nil
end

function Cassiopeia:PoisonDuration(unit)
	for i = 0, unit.buffCount do
		local buff = unit:GetBuff(i)
		if buff and buff.count > 0 and self.IsPoison(buff.name) then
			return buff.duration
		end
	end
	return 0
end

function Cassiopeia:PredictHealth(unit, mod)
	return _G.SDK.HealthPrediction:GetPrediction(unit, self:CalcFangArrivalTime(unit) * (mod or 1))
end

-- Events

function Cassiopeia:OnPreAttack(args)
	local timer = GameTimer()
	local disable = mode == 1 or
		(mode == 2 and Manager:IsReady(_E)) or
		(mode == 3 and myHero.levelData.lvl >
		self.CassiopeiaMenu.Misc.MinLvl:Value()) or
		not self.AAHandler
	if disable or timer - self.QueueTimer < self.WindUp
		or timer - self.ShouldWait <= 0.45 then
			args.Process = false; return
	end
	self.WindUp = 0
end

function Cassiopeia:OnPreMovement(args)
	return
	--[[
	if GameTimer() - self.QueueTimer < self.WindUp then
		args.Process = false; return
	end
	self.WindUp = 0 --]]
end

function Cassiopeia:OnTick()
	self.MyPos = Geometry:To2D(myHero.pos)
	if _G.JustEvade and _G.JustEvade:Evading() or (_G.ExtLibEvade and _G.ExtLibEvade.Evading) or
		_G.SDK.Orbwalker:IsAutoAttacking() or Game.IsChatOpen() or myHero.dead then return end
	self:AutoAttackHandler(self.CassiopeiaMenu.Misc.ModeAA:Value())
	local mode = Manager:GetOrbwalkerMode()
	if mode == "Clear" then self:Clear(); return end
	local tQ, tW, tE = self:GetTarget(self.Q.range), self:GetTarget(self.W.range), self:GetTarget(self.E.range)
	if mode == "Combo" then self:Combo(tQ, tW, tE, self:GetTarget(self.R.range))
	elseif mode == "Harass" then self:Harass(tQ, tW, tE) end
end

function Cassiopeia:OnDraw()
	if Game.IsChatOpen() or myHero.dead then return end
	if self.CassiopeiaMenu.Drawings.DrawQ:Value() then
		DrawCircle(myHero.pos, self.Q.range, 1, Draw.Color(96, 127, 255, 0))
	end
	if self.CassiopeiaMenu.Drawings.DrawE:Value() then
		DrawCircle(myHero.pos, self.E.range, 1, Draw.Color(96, 50, 205, 50))
	end
	if not self.MyPos then return end
	if self.CassiopeiaMenu.Drawings.Track:Value() then
		for i, enemy in ipairs(Enemies) do
			if enemy and enemy.valid and enemy.visible then
				local dist = Geometry:DistanceSquared(self.MyPos, Geometry:To2D(enemy.pos))
				DrawLine(myHero.pos:To2D(), enemy.pos:To2D(), 2,
					dist < 4000000 and Draw.Color(128, 220, 20, 60)
					or dist < 16000000 and Draw.Color(128, 240, 230, 140)
					or Draw.Color(128, 152, 251, 152))
			end
		end
	end
end

function Cassiopeia:AutoAttackHandler(mode)
	if GameTimer() - self.AATimer > 0.35 then
		if self.CassiopeiaMenu.Misc.Toggle:Value() then
			self.AAHandler = not self.AAHandler
			print("Autoattacks " .. (self.AAHandler and "enabled!" or "disabled!"))
		end
		self.AATimer = GameTimer()
	end
end

function Cassiopeia:Clear()
	if GameTimer() - self.QueueTimer < 0.25 then return end
	local minions = Manager:GetMinionsAround(self.MyPos, self.E.range)
	if Manager:IsReady(_Q) and self.CassiopeiaMenu.LaneClear.UseQ:Value() and #minions >= 3 and
		Manager:GetPercentMana() > self.CassiopeiaMenu.LaneClear.ManaQ:Value() then
		local points = {}
		for i, minion in ipairs(minions) do
			local predPos = _G.PremiumPrediction:GetFastPrediction(myHero, minion, self.Q)
			if predPos then TableInsert(points, Geometry:To2D(predPos)) end
		end
		local pos, count = Geometry:GetCircularAOEPos(points, self.Q.radius)
		if pos and count >= 3 and Geometry:DistanceSquared(self.MyPos, pos) < self.Q.range * self.Q.range then
			self.QueueTimer = GameTimer(); self.WindUp = self.Q.windup
			_G.Control.CastSpell(HK_Q, Geometry:To3D(pos))
		end
	end
	if Manager:IsReady(_E) and self.CassiopeiaMenu.LaneClear.UseE:Value() and #minions > 0 then
		local timer, ap = GameTimer(), myHero.ap
		local rawDmg = 48 + myHero.levelData.lvl * 4 + (0.1 * ap)
		local bonusDmg = 20 * (myHero:GetSpellData(_E).level or 1) - 10 + (0.6 * ap)
		for i, minion in ipairs(minions) do
			local arrival, duration = self:CalcFangArrivalTime(minion), self:PoisonDuration(minion)
			local dmg = Manager:CalcMagicalDamage(myHero, minion, rawDmg + (duration > arrival and bonusDmg or 0))
			if self.ShouldWait ~= timer then
				if self:PredictHealth(minion, 2.5) <= dmg then self.ShouldWait = timer end
			end
			if self:PredictHealth(minion) < dmg then
				self.QueueTimer = timer; self.WindUp = self.E.windup
				_G.Control.CastSpell(HK_E, minion.pos); break
			end
		end
	end
end

function Cassiopeia:Combo(targetQ, targetW, targetE, targetR)
	if GameTimer() - self.QueueTimer < 0.25 then return end
	if targetQ and Manager:IsReady(_Q) and self.CassiopeiaMenu.Combo.UseQ:Value() then
		local modeQ = self.CassiopeiaMenu.Combo.ModeQ:Value()
		if modeQ and self:PoisonDuration(targetQ) < self.Q.delay or not modeQ then
			local pred = _G.PremiumPrediction:GetAOEPrediction(myHero, targetQ, self.Q)
			if pred.CastPos and pred.HitChance >= 0.3 then
				self.QueueTimer = GameTimer(); self.WindUp = self.Q.windup
				_G.Control.CastSpell(HK_Q, pred.CastPos)
			end
		end
	end
	if targetW and Manager:IsReady(_W) and self.CassiopeiaMenu.Combo.UseW:Value() then
		local pred = _G.PremiumPrediction:GetPrediction(myHero, targetW, self.W)
		if pred.PredPos and pred.HitChance >= 0.6 and pred.HitCount >= self.CassiopeiaMenu.Combo.MinW:Value() then
			self.QueueTimer = GameTimer(); self.WindUp = self.W.windup
			_G.Control.CastSpell(HK_W, pred.PredPos)
		end
	end
	if targetE and Manager:IsReady(_E) and self.CassiopeiaMenu.Combo.UseE:Value() then
		local modeE = self.CassiopeiaMenu.Combo.ModeE:Value()
		if modeE and self:PoisonDuration(targetE) >=
			self:CalcFangArrivalTime(targetE) or not modeE then
				self.QueueTimer = GameTimer(); self.WindUp = self.E.windup
				_G.Control.CastSpell(HK_E, targetE.pos)
		end
	end
	if targetR and Manager:IsReady(_R) and self.CassiopeiaMenu.Combo.UseR:Value() and _G.PremiumPrediction:IsFacing(targetR, myHero) then
		local pred = _G.PremiumPrediction:GetAOEPrediction(myHero, targetR, self.R)
		if pred.CastPos and pred.HitChance >= 0.8 and pred.HitCount >= self.CassiopeiaMenu.Combo.MinR:Value() then
			self.QueueTimer = GameTimer(); self.WindUp = self.R.windup
			_G.Control.CastSpell(HK_R, pred.CastPos)
		end
	end
end

function Cassiopeia:Harass(targetQ, targetW, targetE)
	if GameTimer() - self.QueueTimer < 0.25 then return end
	if targetQ and Manager:IsReady(_Q) and self.CassiopeiaMenu.Harass.UseQ:Value() then
		local modeQ = self.CassiopeiaMenu.Harass.ModeQ:Value()
		if modeQ and self:PoisonDuration(targetQ) < self.Q.delay or not modeQ then
			local pred = _G.PremiumPrediction:GetAOEPrediction(myHero, targetQ, self.Q)
			if pred.CastPos and pred.HitChance >= 0.4 then
				self.QueueTimer = GameTimer(); self.WindUp = self.Q.windup
				_G.Control.CastSpell(HK_Q, pred.CastPos)
			end
		end
	end
	if targetW and Manager:IsReady(_W) and self.CassiopeiaMenu.Harass.UseW:Value() then
		local pred = _G.PremiumPrediction:GetPrediction(myHero, targetW, self.W)
		if pred.PredPos and pred.HitChance >= 0.7 and pred.HitCount >= self.CassiopeiaMenu.Harass.MinW:Value() then
			self.QueueTimer = GameTimer(); self.WindUp = self.W.windup
			_G.Control.CastSpell(HK_W, pred.PredPos)
		end
	end
	if targetE and Manager:IsReady(_E) and self.CassiopeiaMenu.Harass.UseE:Value() then
		local modeE = self.CassiopeiaMenu.Harass.ModeE:Value()
		if modeE and self:PoisonDuration(targetE) >=
			self:CalcFangArrivalTime(targetE) or not modeE then
				self.QueueTimer = GameTimer(); self.WindUp = self.E.windup
				_G.Control.CastSpell(HK_E, targetE.pos)
		end
	end
end
