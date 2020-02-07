--[[

	   ______            ______        _____  _____     _______           __                                 
	 .' ___  |         .' ____ \      |_   _||_   _|   |_   __ \         [  |                                
	/ .'   \_|   .--.  | (___ \_|______ | |    | |       | |__) |  .---.  | |.--.    .--.   _ .--.  _ .--.   
	| |   ____ / .'`\ \ _.____`.|______|| '    ' |       |  __ /  / /__\\ | '/'`\ \/ .'`\ \[ `/'`\][ `.-. |  
	\ `.___]  || \__. || \____) |        \ \__/ /       _| |  \ \_| \__., |  \__/ || \__. | | |     | | | |  
	 `._____.'  '.__.'  \______.'         `.__.'       |____| |___|'.__.'[__;.__.'  '.__.' [___]   [___||__] 

	Changelog:

	v1.2.2
	+ Fixed MapPosition callbacks

	v1.2.1
	+ Fixed icons

	v1.2
	+ Fixed Jinx's Q usage and added switch to minigun while laneclearing

	v1.1.9
	+ Removed Ezreal's & Lucian's E gapclosing
	+ Minor changes regarding to evade check

	v1.1.8
	+ Updated compatibility with new Premium Prediction
	+ Removed missile data from Sivir E settings

	v1.1.7
	+ Updated to support new JustEvade

	v1.1.6
	+ Fixed Tristana's Q usage

	v1.1.5
	+ Pushed small fix

	v1.1.4
	+ Fixed BaseUlt toggle switch

	v1.1.3
	+ Added Twitch

	v1.1.2
	+ Added Jinx

	v1.1.1
	+ Fixed BaseUlt

	v1.1
	+ Updated Kayle and Morgana spell data

	v1.0.9
	+ Added Tristana

	v1.0.8.2
	+ Minor changes

	v1.0.8.1
	+ Fixed Interrupter

	v1.0.8
	+ Added Under-Turret check in Auto mode

	v1.0.7
	+ Added KaiSa

	v1.0.6
	+ Added Lucian

	v1.0.5
	+ Added Sivir
	+ Added R to KogMaw's LaneClear

	v1.0.4.1
	+ Fixed slots

	v1.0.4
	+ Added tear stacking for Ezreal
	+ Fixed items usage

	v1.0.3
	+ Added Kog'Maw
	+ Fixed Ashe's target selection on attack

	v1.0.2
	+ Added Ezreal

	v1.0.1
	+ Added Vayne
	+ Added Interrupter to champions
	+ Made minor changes

	v1.0
	+ Initial release

--]]

local DrawCircle = Draw.Circle
local DrawColor = Draw.Color
local DrawLine = Draw.Line
local DrawText = Draw.Text
local ControlCastSpell = Control.CastSpell
local ControlIsKeyDown = Control.IsKeyDown
local ControlKeyUp = Control.KeyUp
local ControlKeyDown = Control.KeyDown
local ControlMouseEvent = Control.mouse_event
local ControlMove = Control.Move
local ControlSetCursorPos = Control.SetCursorPos
local GameCanUseSpell = Game.CanUseSpell
local GameLatency = Game.Latency
local GameTimer = Game.Timer
local GameHeroCount = Game.HeroCount
local GameHero = Game.Hero
local GameMinionCount = Game.MinionCount
local GameMinion = Game.Minion
local GameMissileCount = Game.MissileCount
local GameMissile = Game.Missile
local GameObjectCount = Game.ObjectCount
local GameObject = Game.Object
local GameParticleCount = Game.ParticleCount
local GameParticle = Game.Particle
local GameTurretCount = Game.TurretCount
local GameTurret = Game.Turret
local GameWardCount = Game.WardCount
local GameWard = Game.Ward

local MathAbs = math.abs
local MathAcos = math.acos
local MathAtan = math.atan
local MathAtan2 = math.atan2
local MathCeil = math.ceil
local MathCos = math.cos
local MathDeg = math.deg
local MathFloor = math.floor
local MathHuge = math.huge
local MathMax = math.max
local MathMin = math.min
local MathPi = math.pi
local MathRad = math.rad
local MathRandom = math.random
local MathSin = math.sin
local MathSqrt = math.sqrt
local TableInsert = table.insert
local TableRemove = table.remove
local TableSort = table.sort

local Allies, Enemies, Turrets, Units = {}, {}, {}, {}
local Module = {Awareness = nil, BaseUlt = nil, Champion = nil, TargetSelector = nil, Utility = nil}
local OnDraws = {Awareness = nil, BaseUlt = nil, Champion = nil, TargetSelector = nil}
local OnRecalls = {Awareness = nil, BaseUlt = nil}
local OnTicks = {Champion = nil, Utility = nil}
local BaseUltC = {["Ashe"] = true, ["Draven"] = true, ["Ezreal"] = true, ["Jinx"] = true}
local Champions = {["Ashe"] = true, ["Caitlyn"] = false, ["Corki"] = false, ["Draven"] = false, ["Ezreal"] = true, ["Jhin"] = false, ["Jinx"] = true, ["Kaisa"] = true, ["Kalista"] = false, ["KogMaw"] = true, ["Lucian"] = true, ["MissFortune"] = false, ["Quinn"] = false, ["Sivir"] = true, ["Tristana"] = true, ["Twitch"] = true, ["Varus"] = false, ["Vayne"] = true, ["Xayah"] = false}
local Item_HK = {[ITEM_1] = HK_ITEM_1, [ITEM_2] = HK_ITEM_2, [ITEM_3] = HK_ITEM_3, [ITEM_4] = HK_ITEM_4, [ITEM_5] = HK_ITEM_5, [ITEM_6] = HK_ITEM_6, [ITEM_7] = HK_ITEM_7}
local Version = "1.22"; local LuaVer = "1.2.2"
local VerSite = "https://raw.githubusercontent.com/Ark223/GoS-Scripts/master/GoS-U%20Reborn.version"
local LuaSite = "https://raw.githubusercontent.com/Ark223/GoS-Scripts/master/GoS-U%20Reborn.lua"

local function OnProcessSpell()
	for i = 1, #Units do
		local unit = Units[i].unit; local last = Units[i].spell; local spell = unit.activeSpell
		if spell and last ~= (spell.name .. spell.endTime) and unit.activeSpell.isChanneling then
			Units[i].spell = spell.name .. spell.endTime; return unit, spell
		end
	end
	return nil, nil
end

function OnLoad()
	require '2DGeometry'
	require 'MapPositionGOS'
	if FileExist(COMMON_PATH .. "PremiumPrediction.lua") then require "PremiumPrediction" end
	Module.Awareness = GoSuAwareness()
	if BaseUltC[myHero.charName] then Module.BaseUlt = GoSuBaseUlt() end
	Module.Geometry = GoSuGeometry()
	Module.Manager = GoSuManager()
	Module.TargetSelector = GoSuTargetSelector()
	Module.Utility = GoSuUtility()
	if Champions[myHero.charName] then _G[myHero.charName]() end
	LoadUnits()
	AutoUpdate()
end

function LoadUnits()
	for i = 1, GameHeroCount() do
		local unit = GameHero(i); Units[i] = {unit = unit, spell = nil}
		if unit.team ~= myHero.team then TableInsert(Enemies, unit)
		elseif unit.team == myHero.team and unit ~= myHero then TableInsert(Allies, unit) end
	end
	for i = 1, GameTurretCount() do
		local turret = GameTurret(i)
		if turret and turret.isEnemy then TableInsert(Turrets, turret) end
	end
end

function DownloadFile(site, file)
	DownloadFileAsync(site, file, function() end)
	while not FileExist(file) do end
end

function ReadFile(file)
	local txt = io.open(file, "r"); local result = txt:read()
	txt:close(); return result
end

function AutoUpdate()
	if not FileExist(COMMON_PATH .. "PremiumPrediction.lua") then
		DownloadFile("https://github.com/Ark223/GoS-Scripts/blob/master/PremiumPrediction.lua", COMMON_PATH .. "PremiumPrediction.lua")
	end
	DownloadFile(VerSite, SCRIPT_PATH .. "GoS-U Reborn.version")
	if tonumber(ReadFile(SCRIPT_PATH .. "GoS-U Reborn.version")) > tonumber(Version) then
		print("GoS-U Reborn: Downloading update...")
		DownloadFile(LuaSite, SCRIPT_PATH .. "GoS-U Reborn.lua")
		print("GoS-U Reborn: Successfully updated. 2xF6!")
	end
end

local CCSpells = {
	["AatroxW"] = {charName = "Aatrox", displayName = "Infernal Chains", slot = _W, type = "linear", speed = 1800, range = 825, delay = 0.25, radius = 80, collision = true},
	["AhriSeduce"] = {charName = "Ahri", displayName = "Seduce", slot = _E, type = "linear", speed = 1500, range = 975, delay = 0.25, radius = 60, collision = true},
	["AkaliR"] = {charName = "Akali", displayName = "Perfect Execution [First]", slot = _R, type = "linear", speed = 1800, range = 525, delay = 0, radius = 65, collision = false},
	["Pulverize"] = {charName = "Alistar", displayName = "Pulverize", slot = _Q, type = "circular", speed = MathHuge, range = 0, delay = 0.25, radius = 365, collision = false},
	["BandageToss"] = {charName = "Amumu", displayName = "Bandage Toss", slot = _Q, type = "linear", speed = 2000, range = 1100, delay = 0.25, radius = 80, collision = true},
	["CurseoftheSadMummy"] = {charName = "Amumu", displayName = "Curse of the Sad Mummy", slot = _R, type = "circular", speed = MathHuge, range = 0, delay = 0.25, radius = 550, collision = false},
	["FlashFrostSpell"] = {charName = "Anivia", displayName = "Flash Frost",missileName = "FlashFrostSpell", slot = _Q, type = "linear", speed = 850, range = 1100, delay = 0.25, radius = 110, collision = false},
	["EnchantedCrystalArrow"] = {charName = "Ashe", displayName = "Enchanted Crystal Arrow", slot = _R, type = "linear", speed = 1600, range = 25000, delay = 0.25, radius = 130, collision = false},
	["AurelionSolQ"] = {charName = "AurelionSol", displayName = "Starsurge", slot = _Q, type = "linear", speed = 850, range = 25000, delay = 0, radius = 110, collision = false},
	["AzirR"] = {charName = "Azir", displayName = "Emperor's Divide", slot = _R, type = "linear", speed = 1400, range = 500, delay = 0.3, radius = 250, collision = false},
	["BardQ"] = {charName = "Bard", displayName = "Cosmic Binding", slot = _Q, type = "linear", speed = 1500, range = 950, delay = 0.25, radius = 60, collision = true},
	["BardR"] = {charName = "Bard", displayName = "Tempered Fate", slot = _R, type = "circular", speed = 2100, range = 3400, delay = 0.5, radius = 350, collision = false},
	["RocketGrab"] = {charName = "Blitzcrank", displayName = "Rocket Grab", slot = _Q, type = "linear", speed = 1800, range = 1150, delay = 0.25, radius = 70, collision = true},
	["BraumQ"] = {charName = "Braum", displayName = "Winter's Bite", slot = _Q, type = "linear", speed = 1700, range = 1000, delay = 0.25, radius = 70, collision = true},
	["BraumR"] = {charName = "Braum", displayName = "Glacial Fissure", slot = _R, type = "linear", speed = 1400, range = 1250, delay = 0.5, radius = 115, collision = false},
	["CaitlynYordleTrap"] = {charName = "Caitlyn", displayName = "Yordle Trap", slot = _W, type = "circular", speed = MathHuge, range = 800, delay = 0.25, radius = 75, collision = false},
	["CaitlynEntrapment"] = {charName = "Caitlyn", displayName = "Entrapment", slot = _E, type = "linear", speed = 1600, range = 750, delay = 0.15, radius = 70, collision = true},
	["CassiopeiaW"] = {charName = "Cassiopeia", displayName = "Miasma", slot = _W, type = "circular", speed = 2500, range = 800, delay = 0.75, radius = 160, collision = false},
	["Rupture"] = {charName = "Chogath", displayName = "Rupture", slot = _Q, type = "circular", speed = MathHuge, range = 950, delay = 1.2, radius = 250, collision = false},
	["InfectedCleaverMissile"] = {charName = "DrMundo", displayName = "Infected Cleaver", slot = _Q, type = "linear", speed = 2000, range = 975, delay = 0.25, radius = 60, collision = true},
	["DravenDoubleShot"] = {charName = "Draven", displayName = "Double Shot", slot = _E, type = "linear", speed = 1600, range = 1050, delay = 0.25, radius = 130, collision = false},
	["EkkoQ"] = {charName = "Ekko", displayName = "Timewinder", slot = _Q, type = "linear", speed = 1650, range = 1175, delay = 0.25, radius = 60, collision = false},
	["EkkoW"] = {charName = "Ekko", displayName = "Parallel Convergence", slot = _W, type = "circular", speed = MathHuge, range = 1600, delay = 3.35, radius = 400, collision = false},
	["EliseHumanE"] = {charName = "Elise", displayName = "Cocoon", slot = _E, type = "linear", speed = 1600, range = 1075, delay = 0.25, radius = 55, collision = true},
	["FizzR"] = {charName = "Fizz", displayName = "Chum the Waters", slot = _R, type = "linear", speed = 1300, range = 1300, delay = 0.25, radius = 150, collision = false},
	["GalioE"] = {charName = "Galio", displayName = "Justice Punch", slot = _E, type = "linear", speed = 2300, range = 650, delay = 0.4, radius = 160, collision = false},
	["GnarQMissile"] = {charName = "Gnar", displayName = "Boomerang Throw", slot = _Q, type = "linear", speed = 2500, range = 1125, delay = 0.25, radius = 55, collision = false},
	["GnarBigQMissile"] = {charName = "Gnar", displayName = "Boulder Toss", slot = _Q, type = "linear", speed = 2100, range = 1125, delay = 0.5, radius = 90, collision = true},
	["GnarBigW"] = {charName = "Gnar", displayName = "Wallop", slot = _W, type = "linear", speed = MathHuge, range = 575, delay = 0.6, radius = 100, collision = false},
	["GnarR"] = {charName = "Gnar", displayName = "GNAR!", slot = _R, type = "circular", speed = MathHuge, range = 0, delay = 0.25, radius = 475, collision = false},
	["GragasQ"] = {charName = "Gragas", displayName = "Barrel Roll", slot = _Q, type = "circular", speed = 1000, range = 850, delay = 0.25, radius = 275, collision = false},
	["GragasR"] = {charName = "Gragas", displayName = "Explosive Cask", slot = _R, type = "circular", speed = 1800, range = 1000, delay = 0.25, radius = 400, collision = false},
	["GravesSmokeGrenade"] = {charName = "Graves", displayName = "Smoke Grenade", slot = _W, type = "circular", speed = 1500, range = 950, delay = 0.15, radius = 250, collision = false},
	["HeimerdingerE"] = {charName = "Heimerdinger", displayName = "CH-2 Electron Storm Grenade", slot = _E, type = "circular", speed = 1200, range = 970, delay = 0.25, radius = 250, collision = false},
	["HeimerdingerEUlt"] = {charName = "Heimerdinger", displayName = "CH-2 Electron Storm Grenade", slot = _E, type = "circular", speed = 1200, range = 970, delay = 0.25, radius = 250, collision = false},
	["IreliaW2"] = {charName = "Irelia", displayName = "Defiant Dance", slot = _W, type = "linear", speed = MathHuge, range = 775, delay = 0.25, radius = 120, collision = false},
	["IreliaR"] = {charName = "Irelia", displayName = "Vanguard's Edge", slot = _R, type = "linear", speed = 2000, range = 950, delay = 0.4, radius = 160, collision = false},
	["IvernQ"] = {charName = "Ivern", displayName = "Rootcaller", slot = _Q, type = "linear", speed = 1300, range = 1075, delay = 0.25, radius = 80, collision = true},
	["JarvanIVDragonStrike"] = {charName = "JarvanIV", displayName = "Dragon Strike", slot = _Q, type = "linear", speed = MathHuge, range = 770, delay = 0.4, radius = 70, collision = false},
	["JhinW"] = {charName = "Jhin", displayName = "Deadly Flourish", slot = _W, type = "linear", speed = 5000, range = 2550, delay = 0.75, radius = 40, collision = false},
	["JhinE"] = {charName = "Jhin", displayName = "Captive Audience", slot = _E, type = "circular", speed = 1600, range = 750, delay = 0.25, radius = 130, collision = false},
	["JinxWMissile"] = {charName = "Jinx", displayName = "Zap!", slot = _W, type = "linear", speed = 3300, range = 1450, delay = 0.6, radius = 60, collision = true},
	["KarmaQ"] = {charName = "Karma", displayName = "Inner Flame", slot = _Q, type = "linear", speed = 1700, range = 950, delay = 0.25, radius = 60, collision = true},
	["KarmaQMantra"] = {charName = "Karma", displayName = "Inner Flame [Mantra]", slot = _Q, origin = "linear", type = "linear", speed = 1700, range = 950, delay = 0.25, radius = 80, collision = true},
	["KayleQ"] = {charName = "Kayle", displayName = "Radiant Blast", slot = _Q, type = "linear", speed = 2000, range = 850, delay = 0.5, radius = 60, collision = false},
	["KaynW"] = {charName = "Kayn", displayName = "Blade's Reach", slot = _W, type = "linear", speed = MathHuge, range = 700, delay = 0.55, radius = 90, collision = false},
	["KhazixWLong"] = {charName = "Khazix", displayName = "Void Spike [Threeway]", slot = _W, type = "threeway", speed = 1700, range = 1000, delay = 0.25, radius = 70,angle = 23, collision = true},
	["KledQ"] = {charName = "Kled", displayName = "Beartrap on a Rope", slot = _Q, type = "linear", speed = 1600, range = 800, delay = 0.25, radius = 45, collision = true},
	["KogMawVoidOozeMissile"] = {charName = "KogMaw", displayName = "Void Ooze", slot = _E, type = "linear", speed = 1400, range = 1360, delay = 0.25, radius = 120, collision = false},
	["LeblancE"] = {charName = "Leblanc", displayName = "Ethereal Chains [Standard]", slot = _E, type = "linear", speed = 1750, range = 925, delay = 0.25, radius = 55, collision = true},
	["LeblancRE"] = {charName = "Leblanc", displayName = "Ethereal Chains [Ultimate]", slot = _E, type = "linear", speed = 1750, range = 925, delay = 0.25, radius = 55, collision = true},
	["LeonaZenithBlade"] = {charName = "Leona", displayName = "Zenith Blade", slot = _E, type = "linear", speed = 2000, range = 875, delay = 0.25, radius = 70, collision = false},
	["LeonaSolarFlare"] = {charName = "Leona", displayName = "Solar Flare", slot = _R, type = "circular", speed = MathHuge, range = 1200, delay = 0.85, radius = 300, collision = false},
	["LissandraQMissile"] = {charName = "Lissandra", displayName = "Ice Shard", slot = _Q, type = "linear", speed = 2200, range = 750, delay = 0.25, radius = 75, collision = false},
	["LuluQ"] = {charName = "Lulu", displayName = "Glitterlance", slot = _Q, type = "linear", speed = 1450, range = 925, delay = 0.25, radius = 60, collision = false},
	["LuxLightBinding"] = {charName = "Lux", displayName = "Light Binding", slot = _Q, type = "linear", speed = 1200, range = 1175, delay = 0.25, radius = 50, collision = true},
	["LuxLightStrikeKugel"] = {charName = "Lux", displayName = "Light Strike Kugel", slot = _E, type = "circular", speed = 1200, range = 1100, delay = 0.25, radius = 300, collision = true},
	["Landslide"] = {charName = "Malphite", displayName = "Ground Slam", slot = _E, type = "circular", speed = MathHuge, range = 0, delay = 0.242, radius = 400, collision = false},
	["MalzaharQ"] = {charName = "Malzahar", displayName = "Call of the Void", slot = _Q, type = "rectangular", speed = 1600, range = 900, delay = 0.5, radius = 400, radius2 = 100, collision = false},
	["MaokaiQ"] = {charName = "Maokai", displayName = "Bramble Smash", slot = _Q, type = "linear", speed = 1600, range = 600, delay = 0.375, radius = 110, collision = false},
	["MorganaQ"] = {charName = "Morgana", displayName = "Dark Binding", slot = _Q, type = "linear", speed = 1200, range = 1250, delay = 0.25, radius = 70, collision = true},
	["NamiQ"] = {charName = "Nami", displayName = "Aqua Prison", slot = _Q, type = "circular", speed = MathHuge, range = 875, delay = 1, radius = 180, collision = false},
	["NamiRMissile"] = {charName = "Nami", displayName = "Tidal Wave", slot = _R, type = "linear", speed = 850, range = 2750, delay = 0.5, radius = 250, collision = false},
	["NautilusAnchorDragMissile"] = {charName = "Nautilus", displayName = "Dredge Line", slot = _Q, type = "linear", speed = 2000, range = 925, delay = 0.25, radius = 90, collision = true},
	["NeekoQ"] = {charName = "Neeko", displayName = "Blooming Burst", slot = _Q, type = "circular", speed = 1500, range = 800, delay = 0.25, radius = 200, collision = false},
	["NeekoE"] = {charName = "Neeko", displayName = "Tangle-Barbs", slot = _E, type = "linear", speed = 1400, range = 1000, delay = 0.25, radius = 65, collision = false},
	["NunuR"] = {charName = "Nunu", displayName = "Absolute Zero", slot = _R, type = "circular", speed = MathHuge, range = 0, delay = 3, radius = 650, collision = false},
	["OlafAxeThrowCast"] = {charName = "Olaf", displayName = "Undertow", slot = _Q, type = "linear", speed = 1600, range = 1000, delay = 0.25, radius = 90, collision = false},
	["OrnnQ"] = {charName = "Ornn", displayName = "Volcanic Rupture", slot = _Q, type = "linear", speed = 1800, range = 800, delay = 0.3, radius = 65, collision = false},
	["OrnnE"] = {charName = "Ornn", displayName = "Searing Charge", slot = _E, type = "linear", speed = 1600, range = 800, delay = 0.35, radius = 150, collision = false},
	["OrnnRCharge"] = {charName = "Ornn", displayName = "Call of the Forge God", slot = _R, type = "linear", speed = 1650, range = 2500, delay = 0.5, radius = 200, collision = false},
	["PoppyQSpell"] = {charName = "Poppy", displayName = "Hammer Shock", slot = _Q, type = "linear", speed = MathHuge, range = 430, delay = 0.332, radius = 100, collision = false},
	["PoppyRSpell"] = {charName = "Poppy", displayName = "Keeper's Verdict", slot = _R, type = "linear", speed = 2000, range = 1200, delay = 0.33, radius = 100, collision = false},
	["PykeQMelee"] = {charName = "Pyke", displayName = "Bone Skewer [Melee]", slot = _Q, type = "linear", speed = MathHuge, range = 400, delay = 0.25, radius = 70, collision = false},
	["PykeQRange"] = {charName = "Pyke", displayName = "Bone Skewer [Range]", slot = _Q, type = "linear", speed = 2000, range = 1100, delay = 0.2, radius = 70, collision = true},
	["PykeE"] = {charName = "Pyke", displayName = "Phantom Undertow", slot = _E, type = "linear", speed = 3000, range = 25000, delay = 0, radius = 110, collision = false},
	["RakanW"] = {charName = "Rakan", displayName = "Grand Entrance", slot = _W, type = "circular", speed = MathHuge, range = 650, delay = 0.7, radius = 265, collision = false},
	["RengarE"] = {charName = "Rengar", displayName = "Bola Strike", slot = _E, type = "linear", speed = 1500, range = 1000, delay = 0.25, radius = 70, collision = true},
	["RumbleGrenade"] = {charName = "Rumble", displayName = "Electro Harpoon", slot = _E, type = "linear", speed = 2000, range = 850, delay = 0.25, radius = 60, collision = true},
	["SejuaniR"] = {charName = "Sejuani", displayName = "Glacial Prison", slot = _R, type = "linear", speed = 1600, range = 1300, delay = 0.25, radius = 120, collision = false},
	["ShyvanaTransformLeap"] = {charName = "Shyvana", displayName = "Transform Leap", slot = _R, type = "linear", speed = 700, range = 850, delay = 0.25, radius = 150, collision = false},
	["SionQ"] = {charName = "Sion", displayName = "Decimating Smash", slot = _Q, origin = "", type = "linear", speed = MathHuge, range = 750, delay = 2, radius = 150, collision = false},
	["SionE"] = {charName = "Sion", displayName = "Roar of the Slayer", slot = _E, type = "linear", speed = 1800, range = 800, delay = 0.25, radius = 80, collision = false},
	["SkarnerFractureMissile"] = {charName = "Skarner", displayName = "Fracture", slot = _E, type = "linear", speed = 1500, range = 1000, delay = 0.25, radius = 70, collision = false},
	["SonaR"] = {charName = "Sona", displayName = "Crescendo", slot = _R, type = "linear", speed = 2400, range = 1000, delay = 0.25, radius = 140, collision = false},
	["SorakaQ"] = {charName = "Soraka", displayName = "Starcall", slot = _Q, type = "circular", speed = 1150, range = 810, delay = 0.25, radius = 235, collision = false},
	["SwainW"] = {charName = "Swain", displayName = "Vision of Empire", slot = _W, type = "circular", speed = MathHuge, range = 3500, delay = 1.5, radius = 300, collision = false},
	["SwainE"] = {charName = "Swain", displayName = "Nevermove", slot = _E, type = "linear", speed = 1800, range = 850, delay = 0.25, radius = 85, collision = false},
	["TahmKenchQ"] = {charName = "TahmKench", displayName = "Tongue Lash", slot = _Q, type = "linear", speed = 2800, range = 800, delay = 0.25, radius = 70, collision = true},
	["TaliyahWVC"] = {charName = "Taliyah", displayName = "Seismic Shove", slot = _W, type = "circular", speed = MathHuge, range = 900, delay = 0.85, radius = 150, collision = false},
	["TaliyahR"] = {charName = "Taliyah", displayName = "Weaver's Wall", slot = _R, type = "linear", speed = 1700, range = 3000, delay = 1, radius = 120, collision = false},
	["ThreshE"] = {charName = "Thresh", displayName = "Flay", slot = _E, type = "linear", speed = MathHuge, range = 500, delay = 0.389, radius = 110, collision = true},
	["TristanaW"] = {charName = "Tristana", displayName = "Rocket Jump", slot = _W, type = "circular", speed = 1100, range = 900, delay = 0.25, radius = 300, collision = false},
	["UrgotQ"] = {charName = "Urgot", displayName = "Corrosive Charge", slot = _Q, type = "circular", speed = MathHuge, range = 800, delay = 0.6, radius = 180, collision = false},
	["UrgotE"] = {charName = "Urgot", displayName = "Disdain", slot = _E, type = "linear", speed = 1540, range = 475, delay = 0.45, radius = 100, collision = false},
	["UrgotR"] = {charName = "Urgot", displayName = "Fear Beyond Death", slot = _R, type = "linear", speed = 3200, range = 1600, delay = 0.4, radius = 80, collision = false},
	["VarusE"] = {charName = "Varus", displayName = "Hail of Arrows", slot = _E, type = "linear", speed = 1500, range = 925, delay = 0.242, radius = 260, collision = false},
	["VarusR"] = {charName = "Varus", displayName = "Chain of Corruption", slot = _R, type = "linear", speed = 1950, range = 1200, delay = 0.25, radius = 120, collision = false},
	["VelkozQ"] = {charName = "Velkoz", displayName = "Plasma Fission", slot = _Q, type = "linear", speed = 1300, range = 1050, delay = 0.25, radius = 50, collision = true},
	["VelkozE"] = {charName = "Velkoz", displayName = "Tectonic Disruption", slot = _E, type = "circular", speed = MathHuge, range = 800, delay = 0.8, radius = 185, collision = false},
	["ViktorGravitonField"] = {charName = "Viktor", displayName = "Graviton Field", slot = _W, type = "circular", speed = MathHuge, range = 800, delay = 1.75, radius = 270, collision = false},
	["WarwickR"] = {charName = "Warwick", displayName = "Infinite Duress", slot = _R, type = "linear", speed = 1800, range = 3000, delay = 0.1, radius = 55, collision = false},
	["XerathArcaneBarrage2"] = {charName = "Xerath", displayName = "Arcane Barrage", slot = _W, type = "circular", speed = MathHuge, range = 1000, delay = 0.75, radius = 235, collision = false},
	["XerathMageSpear"] = {charName = "Xerath", displayName = "Mage Spear", slot = _E, type = "linear", speed = 1400, range = 1050, delay = 0.2, radius = 60, collision = true},
	["XinZhaoW"] = {charName = "XinZhao", displayName = "Wind Becomes Lightning", slot = _W, type = "linear", speed = 5000, range = 900, delay = 0.5, radius = 40, collision = false},
	["ZacQ"] = {charName = "Zac", displayName = "Stretching Strikes", slot = _Q, type = "linear", speed = 2800, range = 800, delay = 0.33, radius = 120, collision = false},
	["ZiggsW"] = {charName = "Ziggs", displayName = "Satchel Charge", slot = _W, type = "circular", speed = 1750, range = 1000, delay = 0.25, radius = 240, collision = false},
	["ZiggsE"] = {charName = "Ziggs", displayName = "Hexplosive Minefield", slot = _E, type = "circular", speed = 1800, range = 900, delay = 0.25, radius = 250, collision = false},
	["ZileanQ"] = {charName = "Zilean", displayName = "Time Bomb", slot = _Q, type = "circular", speed = MathHuge, range = 900, delay = 0.8, radius = 150, collision = false},
	["ZoeE"] = {charName = "Zoe", displayName = "Sleepy Trouble Bubble", slot = _E, type = "linear", speed = 1700, range = 800, delay = 0.3, radius = 50, collision = true},
	["ZyraE"] = {charName = "Zyra", displayName = "Grasping Roots", slot = _E, type = "linear", speed = 1150, range = 1100, delay = 0.25, radius = 70, collision = false},
	["ZyraR"] = {charName = "Zyra", displayName = "Stranglethorns", slot = _R, type = "circular", speed = MathHuge, range = 700, delay = 2, radius = 500, collision = false},
	["BrandConflagration"] = {charName = "Brand", slot = _R, type = "targeted", displayName = "Conflagration", range = 625,cc = true},
	["JarvanIVCataclysm"] = {charName = "JarvanIV", slot = _R, type = "targeted", displayName = "Cataclysm", range = 650},
	["JayceThunderingBlow"] = {charName = "Jayce", slot = _E, type = "targeted", displayName = "Thundering Blow", range = 240},
	["BlindMonkRKick"] = {charName = "LeeSin", slot = _R, type = "targeted", displayName = "Dragon's Rage", range = 375},
	["LissandraR"] = {charName = "Lissandra", slot = _R, type = "targeted", displayName = "Frozen Tomb", range = 550},
	["SeismicShard"] = {charName = "Malphite", slot = _Q, type = "targeted", displayName = "Seismic Shard", range = 625,cc = true},
	["AlZaharNetherGrasp"] = {charName = "Malzahar", slot = _R, type = "targeted", displayName = "Nether Grasp", range = 700},
	["MaokaiW"] = {charName = "Maokai", slot = _W, type = "targeted", displayName = "Twisted Advance", range = 525},
	["NautilusR"] = {charName = "Nautilus", slot = _R, type = "targeted", displayName = "Depth Charge", range = 825},
	["PoppyE"] = {charName = "Poppy", slot = _E, type = "targeted", displayName = "Heroic Charge", range = 475},
	["RyzeW"] = {charName = "Ryze", slot = _W, type = "targeted", displayName = "Rune Prison", range = 615},
	["Fling"] = {charName = "Singed", slot = _E, type = "targeted", displayName = "Fling", range = 125},
	["SkarnerImpale"] = {charName = "Skarner", slot = _R, type = "targeted", displayName = "Impale", range = 350},
	["TahmKenchW"] = {charName = "TahmKench", slot = _W, type = "targeted", displayName = "Devour", range = 250},
	["TristanaR"] = {charName = "Tristana", slot = _R, type = "targeted", displayName = "Buster Shot", range = 669}
}

local ChanellingSpells = {
	["CaitlynAceintheHole"] = {charName = "Caitlyn", slot = _R, type = "targeted", displayName = "Ace in the Hole", danger = 3},
	["Drain"] = {charName = "Fiddlesticks", slot = _W, type = "targeted", displayName = "Drain", danger = 2},
	["Crowstorm"] = {charName = "Fiddlesticks", slot = _R, type = "skillshot", displayName = "Crowstorm", danger = 3},
	["GalioW"] = {charName = "Galio", slot = _W, type = "skillshot", displayName = "Shield of Durand", danger = 2},
	["GalioR"] = {charName = "Galio", slot = _R, type = "skillshot", displayName = "Hero's Entrance", danger = 3},
	["GragasW"] = {charName = "Gragas", slot = _W, type = "skillshot", displayName = "Drunken Rage", danger = 1},
	["ReapTheWhirlwind"] = {charName = "Janna", slot = _R, type = "skillshot", displayName = "Monsoon", danger = 2},
	["KarthusFallenOne"] = {charName = "Karthus", slot = _R, type = "skillshot", displayName = "Requiem", danger = 3},
	["KatarinaR"] = {charName = "Katarina", slot = _R, type = "skillshot", displayName = "Death Lotus", danger = 3},
	["LucianR"] = {charName = "Lucian", slot = _R, type = "skillshot", displayName = "The Culling", danger = 2},
	["AlZaharNetherGrasp"] = {charName = "Malzahar", slot = _R, type = "targeted", displayName = "Nether Grasp", danger = 3},
	["Meditate"] = {charName = "MasterYi", slot = _Q, type = "skillshot", displayName = "Meditate", danger = 1},
	["MissFortuneBulletTime"] = {charName = "MissFortune", slot = _R, type = "skillshot", displayName = "Bullet Time", danger = 3},
	["AbsoluteZero"] = {charName = "Nunu", slot = _R, type = "skillshot", displayName = "Absolute Zero", danger = 3},
	["PantheonRFall"] = {charName = "Pantheon", slot = _R, type = "skillshot", displayName = "Grand Skyfall [Fall]", danger = 3},
	["PantheonRJump"] = {charName = "Pantheon", slot = _R, type = "skillshot", displayName = "Grand Skyfall [Jump]", danger = 3},
	["PykeQ"] = {charName = "Pyke", slot = _Q, type = "skillshot", displayName = "Bone Skewer", danger = 1},
	["ShenR"] = {charName = "Shen", slot = _R, type = "skillshot", displayName = "Stand United", danger = 2},
	["SionQ"] = {charName = "Sion", slot = _Q, type = "skillshot", displayName = "Decimating Smash", danger = 2},
	["Destiny"] = {charName = "TwistedFate", slot = _R, type = "skillshot", displayName = "Destiny", danger = 2},
	["VarusQ"] = {charName = "Varus", slot = _Q, type = "skillshot", displayName = "Piercing Arrow", danger = 1},
	["VelKozR"] = {charName = "VelKoz", slot = _R, type = "skillshot", displayName = "Life Form Disintegration Ray", danger = 3},
	["ViQ"] = {charName = "Vi", slot = _Q, type = "skillshot", displayName = "Vault Breaker", danger = 2},
	["XerathLocusOfPower2"] = {charName = "Xerath", slot = _R, type = "skillshot", displayName = "Rite of the Arcane", danger = 3},
	["ZacR"] = {charName = "Zac", slot = _R, type = "skillshot", displayName = "Let's Bounce!", danger = 3}
}

local DamageTable = {
	["Ashe"] = {
		{slot = 1, state = 0, damage = function(target) return GoSuManager:CalcPhysicalDamage(myHero, target, (({20, 35, 50, 65, 80})[GoSuManager:GetCastLevel(myHero, _W)] + myHero.totalDamage)) end},
		{slot = 3, state = 0, damage = function(target) return GoSuManager:CalcMagicalDamage(myHero, target, (({200, 400, 600})[GoSuManager:GetCastLevel(myHero, _R)] + myHero.ap)) end},
	},
	["Caitlyn"] = {
		{slot = 3, state = 0, damage = function(target) return GoSuManager:CalcMagicalDamage(myHero, target, (({250, 475, 700})[GoSuManager:GetCastLevel(myHero, _R)] + 2 * myHero.bonusDamage)) end},
	},
	["Corki"] = {
		{slot = 0, state = 0, damage = function(target) return GoSuManager:CalcMagicalDamage(myHero, target, (({75, 120, 165, 210, 255})[GoSuManager:GetCastLevel(myHero, _Q)] + 0.5 * myHero.bonusDamage + 0.5 * myHero.ap)) end},
		{slot = 3, state = 0, damage = function(target) return GoSuManager:CalcMagicalDamage(myHero, target, (({90, 115, 140})[GoSuManager:GetCastLevel(myHero, _R)] + ({0.15, 0.45, 0.75})[GoSuManager:GetCastLevel(myHero, _R)] * myHero.totalDamage + 0.2 * myHero.ap)) end},
		{slot = 3, state = 1, damage = function(target) return GoSuManager:CalcMagicalDamage(myHero, target, (({180, 230, 280})[GoSuManager:GetCastLevel(myHero, _R)] + ({0.3, 0.9, 1.5})[GoSuManager:GetCastLevel(myHero, _R)] * myHero.totalDamage + 0.4 * myHero.ap)) end},
	},
	["Draven"] = {
		{slot = 3, state = 0, damage = function(target) return GoSuManager:CalcPhysicalDamage(myHero, target, (({175, 275, 375})[GoSuManager:GetCastLevel(myHero, _R)] + 1.1 * myHero.bonusDamage)) end},
		{slot = 3, state = 1, damage = function(target) return GoSuManager:CalcPhysicalDamage(myHero, target, (({350, 550, 750})[GoSuManager:GetCastLevel(myHero, _R)] + 2.2 * myHero.bonusDamage)) end},
	},
	["Ezreal"] = {
		{slot = 0, state = 0, damage = function(target) return GoSuManager:CalcPhysicalDamage(myHero, target, (({15, 40, 65, 90, 115})[GoSuManager:GetCastLevel(myHero, _Q)] + 1.1 * myHero.totalDamage + 0.3 * myHero.ap)) end},
		{slot = 3, state = 0, damage = function(target) return GoSuManager:CalcMagicalDamage(myHero, target, (({175, 250, 325})[GoSuManager:GetCastLevel(myHero, _R)] + myHero.bonusDamage + 0.9 * myHero.ap)) end},
	},
	["Jinx"] = {
		{slot = 3, state = 0, damage = function(target) return GoSuManager:CalcPhysicalDamage(myHero, target, (({250, 350, 450})[GoSuManager:GetCastLevel(myHero, _R)] + 1.5 * myHero.bonusDamage + ({0.25, 0.3, 0.35})[GoSuManager:GetCastLevel(myHero, _R)] * target.maxHealth)) end},
		{slot = 3, state = 1, damage = function(target) return GoSuManager:CalcPhysicalDamage(myHero, target, (({25, 35, 45})[GoSuManager:GetCastLevel(myHero, _R)] + 0.15 * myHero.bonusDamage + ({0.25, 0.3, 0.35})[GoSuManager:GetCastLevel(myHero, _R)] * target.maxHealth)) end},
	},
	["Kaisa"] = {
		{slot = 1, state = 0, damage = function(target) return GoSuManager:CalcMagicalDamage(myHero, target, (({20, 45, 70, 95, 120})[GoSuManager:GetCastLevel(myHero, _W)] + 1.5 * myHero.totalDamage + 0.6 * myHero.ap)) end},
	},
	["Kalista"] = {
		{slot = 2, state = 0, damage = function(target) return GoSuManager:CalcPhysicalDamage(myHero, target, GoSuManager:GotBuff(target, "kalistaexpungemarker") > 0 and ((({20, 30, 40, 50, 60})[GoSuManager:GetCastLevel(myHero, _E)] + 0.6 * myHero.bonusDamage) + ((GoSuManager:GotBuff(target, "kalistaexpungemarker") - 1) * (({10, 14, 19, 25, 32})[GoSuManager:GetCastLevel(myHero, _E)] + ({0.2, 0.2375, 0.275, 0.3125, 0.35})[GoSuManager:GetCastLevel(myHero, _E)] * myHero.totalDamage)))) end},
	},
	["KogMaw"] = {
		{slot = 0, state = 0, damage = function(target) return GoSuManager:CalcMagicalDamage(myHero, target, (({80, 130, 180, 230, 280})[GoSuManager:GetCastLevel(myHero, _Q)] + 0.5 * myHero.ap)) end},
		{slot = 3, state = 0, damage = function(target)	local base = ({100, 140, 180})[GoSuManager:GetCastLevel(myHero, _R)] + 0.65 * myHero.bonusDamage + 0.25 * myHero.ap; local multiplyer = MathFloor(100 - (target.health * 100 / target.maxHealth)); return GoSuManager:CalcMagicalDamage(myHero, target, multiplyer > 60 and base * 2 or base * (1 + (multiplyer * 0.00833))) end},
	},
	["Lucian"] = {
		{slot = 3, state = 0, damage = function(target) return GoSuManager:CalcPhysicalDamage(myHero, target, (({400, 875, 1500})[GoSuManager:GetCastLevel(myHero, _R)] + ({5, 6.25, 7.5})[GoSuManager:GetCastLevel(myHero, _R)] * myHero.totalDamage + ({2, 2.5, 3})[GoSuManager:GetCastLevel(myHero, _R)] * myHero.ap)) end},
	},
	["MissFortune"] = {
		{slot = 3, state = 0, damage = function(target) return GoSuManager:CalcPhysicalDamage(myHero, target, (({9, 10.5, 12})[GoSuManager:GetCastLevel(myHero, _R)] * myHero.totalDamage + ({2.4, 2.8, 3.2})[GoSuManager:GetCastLevel(myHero, _R)] * myHero.ap)) end},
		{slot = 3, state = 1, damage = function(target) return GoSuManager:CalcPhysicalDamage(myHero, target, (({10.8, 12.6, 14.4})[GoSuManager:GetCastLevel(myHero, _R)] * myHero.totalDamage + ({2.88, 3.36, 3.84})[GoSuManager:GetCastLevel(myHero, _R)] * myHero.ap)) end},
	},
	["Tristana"] = {
		{slot = 3, state = 0, damage = function(target) return GoSuManager:CalcMagicalDamage(myHero, target, (({300, 400, 500})[GoSuManager:GetCastLevel(myHero, _R)] + myHero.ap)) end},
	},
	["Vayne"] = {
		{slot = 2, state = 0, damage = function(target) return GoSuManager:CalcPhysicalDamage(myHero, target, (({50, 85, 120, 155, 190})[GoSuManager:GetCastLevel(myHero, _E)] + 0.5 * myHero.bonusDamage)) end},
		{slot = 2, state = 1, damage = function(target) return GoSuManager:CalcPhysicalDamage(myHero, target, (({100, 170, 240, 310, 380})[GoSuManager:GetCastLevel(myHero, _E)] + myHero.bonusDamage)) end},
	},
}

local SpellData = {
	["Ashe"] = {
		[1] = {speed = 2000, range = 1200, delay = 0.25, radius = 20, collision = {}, type = "linear"},
		[3] = {speed = 1600, range = 12500, delay = 0.25, radius = 130, collision = {}, type = "linear"},
	},
	["Caitlyn"] = {
		[0] = {speed = 2200, range = 1250, delay = 0.625, radius = 90, collision = {}, type = "linear"},
		[1] = {speed = MathHuge, range = 800, delay = 0.25, radius = 75, collision = {}, type = "linear"},
		[2] = {speed = 1600, range = 750, delay = 0.15, radius = 70, collision = {"minion"}, type = "linear"},
	},
	["Corki"] = {
		[0] = {speed = 1000, range = 825, delay = 0.25, radius = 250, collision = {}, type = "circular"},
		[2] = {range = 600},
		[3] = {speed = 2000, range = 1300, delay = 0.175, radius = 40, collision = {"minion"}, type = "linear"},
	},
	["Draven"] = {
		[2] = {speed = 1600, range = 1050, delay = 0.25, radius = 130, collision = {}, type = "linear"},
		[3] = {speed = 2000, range = 12500, delay = 0.25, radius = 160, collision = {}, type = "linear"},
	},
	["Ezreal"] = {
		[0] = {speed = 2000, range = 1150, delay = 0.25, radius = 60, collision = {"minion"}, type = "linear"},
		[1] = {speed = 2000, range = 1150, delay = 0.25, radius = 60, collision = {}, type = "linear"},
		[2] = {range = 475, radius = 750},
		[3] = {speed = 2000, range = 12500, delay = 1, radius = 160, collision = {}, type = "linear"},
	},
	["Jhin"] = {
		[0] = {range = 550},
		[1] = {speed = 5000, range = 2550, delay = 0.75, radius = 40, collision = {}, type = "linear"},
		[2] = {speed = 1600, range = 750, delay = 0.25, radius = 130, collision = {}, type = "circular"},
		[3] = {speed = 5000, range = 3500, delay = 0.25, radius = 80, collision = {}, type = "linear"},
	},
	["Jinx"] = {
		[1] = {speed = 3300, range = 1450, delay = 0.5, radius = 60, collision = {"minion"}, type = "linear"},
		[2] = {speed = 1750, range = 900, delay = 0, radius = 120, collision = {}, type = "circular"},
		[3] = {speed = 1700, range = 12500, delay = 0.6, radius = 140, collision = {}, type = "linear"},
	},
	["Kaisa"] = {
		[0] = {range = 600},
		[1] = {speed = 1750, range = 3000, delay = 0.4, radius = 100, collision = {"minion"}, type = "linear"},
	},
	["Kalista"] = {
		[0] = {speed = 2400, range = 1150, delay = 0.25, radius = 40, collision = {"minion"}, type = "linear"},
		[1] = {range = 1000},
		[3] = {range = 1200},
	},
	["KogMaw"] = {
		[0] = {speed = 1650, range = 1175, delay = 0.25, radius = 70, collision = {"minion"}, type = "linear"},
		[2] = {speed = 1400, range = 1360, delay = 0.25, radius = 120, collision = {}, type = "linear"},
		[3] = {speed = MathHuge, range = 1300, delay = 1.1, radius = 200, collision = {}, type = "circular"},
	},
	["Lucian"] = {
		[0] = {speed = MathHuge, range = 900, range2 = 500, delay = 0.35, radius = 65, collision = {}, type = "linear"},
		[1] = {speed = 1600, range = 900, delay = 0.25, radius = 40, collision = {"minion"}, type = "linear"},
		[2] = {range = 425},
		[3] = {speed = 2800, range = 1200, delay = 0, radius = 110, collision = {"minion"}, type = "linear"},
	},
	["MissFortune"] = {
		[2] = {speed = MathHuge, range = 1000, delay = 0.25, radius = 350, collision = {}, type = "conic"},
		[3] = {speed = 2000, range = 1400, delay = 0.25, radius = 100, angle = 34, collision = {}, type = "conic"},
	},
	["Sivir"] = {
		[0] = {speed = 1350, range = 1250, delay = 0.25, radius = 90, collision = {}, type = "linear"},
	},
	["Tristana"] = {
		[1] = {speed = 1100, range = 900, delay = 0.25, radius = 300, collision = {}, type = "circular"},
		[2] = {range = 525},
		[3] = {range = 525},
	},
	["Twitch"] = {
		[1] = {speed = 1400, range = 950, delay = 0.25, radius = 300, collision = {}, type = "circular"},
		[2] = {range = 1200},
	},
	["Vayne"] = {
		[0] = {range = 300},
		[2] = {speed = 2000, range = 1, range2 = 550, delay = 0.25, radius = 65, collision = {}, type = "linear"},
	},
	["Varus"] = {
		[0] = {speed = 1900, range = 1525, delay = 0, radius = 70, collision = {}, type = "linear"},
		[2] = {speed = 1500, range = 925, delay = 0.242, radius = 260, collision = {}, type = "circular"},
		[3] = {speed = 1950, range = 1200, delay = 0.25, radius = 120, collision = {}, type = "linear"},
	},
	--["Xayah"] = {
	--},
}

--[[
	┌─┐┌─┐┌─┐┌┬┐┌─┐┌┬┐┬─┐┬ ┬
	│ ┬├┤ │ ││││├┤  │ ├┬┘└┬┘
	└─┘└─┘└─┘┴ ┴└─┘ ┴ ┴└─ ┴ 
--]]

class "GoSuGeometry"

function GoSuGeometry:__init()
end

function GoSuGeometry:CalculateCollisionTime(startPos, endPos, unitPos, startTime, speed, delay, origin)
	local pos = startPos:Extended(endPos, speed * (GameTimer() - delay - startTime))
	return self:GetDistance(unitPos, pos) / speed
end

function GoSuGeometry:CalculateEndPos(startPos, placementPos, unitPos, range, radius, collision, type)
	local range = range or 3000; local endPos = startPos:Extended(placementPos, range)
	if type == "circular" or type == "rectangular" then
		if range > 0 then if self:GetDistance(unitPos, placementPos) < range then endPos = placementPos end
		else endPos = unitPos end
	elseif collision then
		for i = 1, GameMinionCount() do
			local minion = GameMinion(i)
			if minion and minion.team == myHero.team and minion.alive and self:GetDistance(minion.pos, startPos) < range then
				local col = self:VectorPointProjectionOnLineSegment(startPos, placementPos, minion.pos)
				if col and self:GetDistance(col, minion.pos) < (radius + minion.boundingRadius / 2) then
					range = self:GetDistance(startPos, col); endPos = startPos:Extended(placementPos, range); break
				end
			end
		end
	end
	return endPos, range
end

function GoSuGeometry:CircleCircleIntersection(c1, c2, r1, r2)
	local d = self:GetDistance(c1, c2); local a = (r1 * r1 - r2 * r2 + d * d) / (2 * d); local h = MathSqrt(r1 * r1 - a * a)
	local dir = Vector(c2 - c1):Normalized(); local pa = Vector(c1) + a * dir
	local s1 = pa + h * dir:Perpendicular(); local s2 = pa - h * dir:Perpendicular()
	return s1, s2
end

function GoSuGeometry:CutUnitsRange(units, range)
	local units = units
	for i = 1, #units do
		local unit = units[i]
		if unit and self:GetDistance(myHero.pos, unit.pos) > range then TableRemove(units, i) end
	end
	return units
end

function GoSuGeometry:GetBestCircularAOEPos(units, radius, expected)
	local BestPos = nil; local MostHit = 0
	for i = 1, #units do
		local unit = units[i]; local MostHit = 0
		for j = 1, #units do
			local target = units[j]
			if self:GetDistance(target.pos, unit.pos) <= radius then MostHit = MostHit + 1 end
		end
		BestPos = unit.pos
		if MostHit >= expected then return BestPos, MostHit end
	end
	return nil, 0
end

function GoSuGeometry:GetBestLinearAOEPos(units, range, radius)
	local BestPos = Vector(0, 0, 0); local MostHit = 0
	for i = 0, 1 do
		for j = 1, #units do
			local unit = units[j]; local endPos = i == 0 and myHero.pos:Extended(unit.pos, range) or BestPos
			local pointSegment, pointLine, isOnSegment = self:VectorPointProjectionOnLineSegment(myHero.pos, endPos, unit.pos)
			if isOnSegment and self:GetDistanceSqr(pointSegment, unit.pos) < (radius + unit.boundingRadius) ^ 2 then
				MostHit = MostHit + 1; if i == 0 then BestPos = BestPos + endPos end
			end
		end
		if i == 0 then BestPos = Vector(BestPos.x / MostHit, 0, BestPos.z / MostHit); MostHit = 0 end
	end
	return BestPos, MostHit
end

function GoSuGeometry:GetDistance(pos1, pos2)
	return MathSqrt(self:GetDistanceSqr(pos1, pos2))
end

function GoSuGeometry:GetDistanceSqr(pos1, pos2)
	local pos2 = pos2 or myHero.pos
	local dx = pos1.x - pos2.x
	local dz = (pos1.z or pos1.y) - (pos2.z or pos2.y)
	return dx * dx + dz * dz
end

function GoSuGeometry:IsInRange(pos1, pos2, range)
    local dx = pos1.x - pos2.x; local dz = pos1.z - pos2.z
    return dx * dx + dz * dz <= range * range
end

function GoSuGeometry:RotateVector2D(startPos, endPos, theta)
	local dx = endPos.x - startPos.x; local dy = endPos.y - startPos.y
	local nx = dx * MathCos(theta) - dy * MathSin(theta); local ny = dx * MathSin(theta) + dy * MathCos(theta)
	nx = nx + startPos.x; ny = ny + startPos.y
	return Vector(nx, endPos.y, ny)
end

function GoSuGeometry:VectorIntersection(a1, b1, a2, b2)
	local x1, y1, x2, y2, x3, y3, x4, y4 = a1.x, a1.z or a1.y, b1.x, b1.z or b1.y, a2.x, a2.z or a2.y, b2.x, b2.z or b2.y
	local r, s, u, v, k, l = x1 * y2 - y1 * x2, x3 * y4 - y3 * x4, x3 - x4, x1 - x2, y3 - y4, y1 - y2
	local px, py, divisor = r * u - v * s, r * k - l * s, v * k - l * u
	return divisor ~= 0 and Vector(px / divisor, py / divisor)
end

function GoSuGeometry:VectorPointProjectionOnLineSegment(v1, v2, v)
	local cx, cy, ax, ay, bx, by = v.x, v.z, v1.x, v1.z, v2.x, v2.z
	local rL = ((cx - ax) * (bx - ax) + (cy - ay) * (by - ay)) / ((bx - ax) ^ 2 + (by - ay) ^ 2)
	local pointLine = { x = ax + rL * (bx - ax), y = ay + rL * (by - ay) }
	local rS = rL < 0 and 0 or (rL > 1 and 1 or rL)
	local isOnSegment = rS == rL
	local pointSegment = isOnSegment and pointLine or { x = ax + rS * (bx - ax), y = ay + rS * (by - ay) }
	return pointSegment, pointLine, isOnSegment
end

--[[
	┌┬┐┌─┐┌┐┌┌─┐┌─┐┌─┐┬─┐
	│││├─┤│││├─┤│ ┬├┤ ├┬┘
	┴ ┴┴ ┴┘└┘┴ ┴└─┘└─┘┴└─
--]]

class "GoSuManager"

function GoSuManager:__init()
end

function GoSuManager:CalcMagicalDamage(source, target, damage)
	local mr = target.magicResist
	local value = 100 / (100 + (mr * source.magicPenPercent) - source.magicPen)
	if mr < 0 then value = 2 - 100 / (100 - mr)
	elseif (mr * source.magicPenPercent) - source.magicPen < 0 then value = 1 end
	return MathMax(0, MathFloor(value * damage))
end

function GoSuManager:CalcPhysicalDamage(source, target, damage)
	local ArmorPenPercent = source.armorPenPercent
	local ArmorPenFlat = source.armorPen * (0.6 + (0.4 * (target.levelData.lvl / 18))) 
	local BonusArmorPen = source.bonusArmorPenPercent
	if source.type == Obj_AI_Minion then ArmorPenPercent = 1; ArmorPenFlat = 0; BonusArmorPen = 1
	elseif source.type == Obj_AI_Turret then
		ArmorPenFlat = 0; BonusArmorPen = 1
		if source.charName:find("3") or source.charName:find("4") then ArmorPenPercent = 0.25
		else ArmorPenPercent = 0.7 end	
		if target.type == Obj_AI_Minion then damage = damage * 1.25
			if target.charName:find("MinionSiege") then damage = damage * 0.7 end
			return damage
		end
	end
	local armor = target.armor; local bonusArmor = target.bonusArmor
	local value = 100 / (100 + (armor * ArmorPenPercent) - (bonusArmor * (1 - BonusArmorPen)) - ArmorPenFlat)
	if armor < 0 then value = 2 - 100 / (100 - armor)
	elseif (armor * ArmorPenPercent) - (bonusArmor * (1 - BonusArmorPen)) - ArmorPenFlat < 0 then value = 1 end
	return MathMax(0, MathFloor(value * damage))
end

function GoSuManager:GetAllyHeroes()
	return Allies
end

function GoSuManager:GetCastLevel(unit, slot)
	return unit:GetSpellData(slot).level == 0 and 1 or unit:GetSpellData(slot).level
end

function GoSuManager:GetCastRange(unit, spell)
	local range = unit:GetSpellData(spell).range
	if range and range > 0 then return range end
end

function GoSuManager:GetDamage(target, spell, state)
	local state = state or 0
	if spell == 0 or spell == 1 or spell == 2 or spell == 3 then
		if DamageTable[myHero.charName] then
			for i, spells in pairs(DamageTable[myHero.charName]) do
				if spells.slot == spell then
					if spells.state == state then
						return spells.damage(target)
					end
				end
			end
		end
	end
end

function GoSuManager:GetEnemyHeroes()
	return Enemies
end

function GoSuManager:GetHeroesAround(pos, range, mode)
	local range = range or MathHuge; local t = {}; local n = 0
	for i = 1, (mode == "allies" and #Allies or #Enemies) do
		local unit = mode == "allies" and Allies[i] or Enemies[i]
		if unit and unit.alive and unit.valid and GoSuGeometry:GetDistance(pos, unit.pos) <= range then
			TableInsert(t, unit); n = n + 1
		end
	end
	return t, n
end

function GoSuManager:GetHeroByHandle(handle)
	for i = 1, #Enemies do
		local unit = Enemies[i]
		if unit.handle == handle then return unit end
	end
end

function GoSuManager:GetItemSlot(unit, id)
	for i = ITEM_1, ITEM_7 do
		if unit:GetItemData(i).itemID == id then return i end
	end
	return 0
end

function GoSuManager:GetMinionsAround(pos, range, mode)
	local range = range or MathHuge; local t = {}; local n = 0
	for i = 1, GameMinionCount() do
		local minion = GameMinion(i)
		if minion and minion.alive and minion.valid and GoSuGeometry:GetDistance(pos, minion.pos) <= range then
			if mode == "allies" and minion.isAlly or minion.isEnemy then
				TableInsert(t, minion); n = n + 1
			end
		end
	end
	return t, n
end

function GoSuManager:GetOrbwalkerMode()
	if _G.SDK then
		if _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_COMBO] then return "Combo"
		elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_HARASS] then return "Harass"
		elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_LANECLEAR] then return "Clear" end
	else
		return GOS.GetMode()
	end
	return ""
end

function GoSuManager:GetPercentHP(unit)
	return 100 * unit.health / unit.maxHealth
end

function GoSuManager:GetPercentMana(unit)
	return 100 * unit.mana / unit.maxMana
end

function GoSuManager:GetSpellCooldown(unit, spell)
	return MathCeil(unit:GetSpellData(spell).currentCd)
end

function GoSuManager:GotBuff(unit, buffname)
	for i = 0, unit.buffCount do
		local buff = unit:GetBuff(i)
		if buff and buff.name == buffname and buff.count > 0 then return buff.count end
	end
	return 0
end

function GoSuManager:IsImmobile(unit)
	if unit.ms == 0 then return true end
	for i = 0, unit.buffCount do
		local buff = unit:GetBuff(i)
		if buff and (buff.type == 5 or buff.type == 11 or buff.type == 18 or buff.type == 22 or buff.type == 24 or buff.type == 28 or buff.type == 29 or buff.name == "recall") and buff.count > 0 then return true end
	end
	return false
end

function GoSuManager:IsReady(spell)
	return GameCanUseSpell(spell) == 0
end

function GoSuManager:IsUnderTurret(pos)
	for i = 1, #Turrets do
		local turret = Turrets[i]
		if turret and turret.valid and turret.health > 0 and GoSuGeometry:GetDistance(pos, turret.pos) <= 900 then
			return true
		end
	end
	return false
end

function GoSuManager:IsSlowed(unit)
	for i = 0, unit.buffCount do
		local buff = unit:GetBuff(i)
		if buff and buff.type == 10 and buff.count > 0 then return true end
	end
	return false
end

function GoSuManager:ValidTarget(target, range)
	local range = range or MathHuge
	return target and target.valid and target.visible and target.health > 0 and GoSuGeometry:GetDistance(myHero.pos, target.pos) < range
end

--[[
	┌─┐┬ ┬┌─┐┬─┐┌─┐┌┐┌┌─┐┌─┐┌─┐
	├─┤│││├─┤├┬┘├┤ │││├┤ └─┐└─┐
	┴ ┴└┴┘┴ ┴┴└─└─┘┘└┘└─┘└─┘└─┘
--]]

class "GoSuAwareness"

function GoSuAwareness:__init()
	self.AwarenessMenu = MenuElement({type = MENU, id = "Awareness", name = "[GoS-U] Awareness"})
	self.AwarenessMenu:MenuElement({id = "DrawJng", name = "Draw Jungler Info", value = true})
	self.AwarenessMenu:MenuElement({id = "DrawEnAA", name = "Draw Enemy AA Range", value = true})
	self.AwarenessMenu:MenuElement({id = "EnAARng", name = "AA Range Color", color = DrawColor(64, 192, 192, 192)})
	self.AwarenessMenu:MenuElement({id = "DrawEnRng", name = "Draw Enemy Spell Ranges", value = true})
	self.AwarenessMenu:MenuElement({id = "EnQRng", name = "Q Range Color", color = DrawColor(64, 0, 250, 154)})
	self.AwarenessMenu:MenuElement({id = "EnWRng", name = "W Range Color", color = DrawColor(64, 218, 112, 214)})
	self.AwarenessMenu:MenuElement({id = "EnERng", name = "E Range Color", color = DrawColor(64, 255, 140, 0)})
	self.AwarenessMenu:MenuElement({id = "EnRRng", name = "R Range Color", color = DrawColor(64, 220, 20, 60)})
	self.AwarenessMenu:MenuElement({id = "DrawAA", name = "Draw AA's Left", value = true})
	self.AwarenessMenu:MenuElement({id = "CDs", name = "Show Cooldowns", value = true})
	self.AwarenessMenu:MenuElement({id = "Recall", name = "Track Recalls", value = true})
	OnRecalls.Awareness = function(unit, recall) self:ProcessRecall(unit, recall) end
	OnDraws.Awareness = function() self:Draw() end
end

function GoSuAwareness:ProcessRecall(unit, recall)
	if self.AwarenessMenu.Recall:Value() then
		if unit.team ~= myHero.team then
			if recall.isStart then print(unit.charName.." started recalling at " ..MathCeil(unit.health).. "HP")
			elseif recall.isFinish then print(unit.charName.." successfully recalled!")
			else print(unit.charName.." canceled recalling!") end
		end
	end
end

function GoSuAwareness:Draw()
	for i, enemy in pairs(GoSuManager:GetEnemyHeroes()) do
		if GoSuManager:ValidTarget(enemy, 3000) then
			if self.AwarenessMenu.DrawEnAA:Value() then
				DrawCircle(enemy.pos, enemy.range, 1, self.AwarenessMenu.EnAARng:Value())
			end
			if self.AwarenessMenu.DrawEnRng:Value() then
				if GoSuManager:GetCastRange(enemy, _Q) then DrawCircle(enemy.pos, GoSuManager:GetCastRange(enemy, _Q), 1, self.AwarenessMenu.EnQRng:Value()) end
				if GoSuManager:GetCastRange(enemy, _W) then DrawCircle(enemy.pos, GoSuManager:GetCastRange(enemy, _W), 1, self.AwarenessMenu.EnWRng:Value()) end
				if GoSuManager:GetCastRange(enemy, _E) then DrawCircle(enemy.pos, GoSuManager:GetCastRange(enemy, _E), 1, self.AwarenessMenu.EnERng:Value()) end
				if GoSuManager:GetCastRange(enemy, _R) then DrawCircle(enemy.pos, GoSuManager:GetCastRange(enemy, _R), 1, self.AwarenessMenu.EnRRng:Value()) end
			end
		end
		if GoSuManager:ValidTarget(enemy) then
			if self.AwarenessMenu.CDs:Value() then
				if GoSuManager:GetSpellCooldown(enemy, _Q) ~= 0 then DrawText("Q", 15, enemy.pos2D.x-85, enemy.pos2D.y+10, DrawColor(0xFFFF0000)); DrawText(GoSuManager:GetSpellCooldown(enemy, _Q), 15, enemy.pos2D.x-85, enemy.pos2D.y+25, DrawColor(0xFFFFA500))
				else DrawText("Q", 15, enemy.pos2D.x-85, enemy.pos2D.y+10, DrawColor(0xFF00FF00)) end
				if GoSuManager:GetSpellCooldown(enemy, _W) ~= 0 then DrawText("W", 15, enemy.pos2D.x-53, enemy.pos2D.y+10, DrawColor(0xFFFF0000)); DrawText(GoSuManager:GetSpellCooldown(enemy, _W), 15, enemy.pos2D.x-53, enemy.pos2D.y+25, DrawColor(0xFFFFA500))
				else DrawText("W", 15, enemy.pos2D.x-53, enemy.pos2D.y+10, DrawColor(0xFF00FF00)) end
				if GoSuManager:GetSpellCooldown(enemy, _E) ~= 0 then DrawText("E", 15, enemy.pos2D.x-17, enemy.pos2D.y+10, DrawColor(0xFFFF0000)); DrawText(GoSuManager:GetSpellCooldown(enemy, _E), 15, enemy.pos2D.x-17, enemy.pos2D.y+25, DrawColor(0xFFFFA500))
				else DrawText("E", 15, enemy.pos2D.x-17, enemy.pos2D.y+10, DrawColor(0xFF00FF00)) end
				if GoSuManager:GetSpellCooldown(enemy, _R) ~= 0 then DrawText("R", 15, enemy.pos2D.x+15, enemy.pos2D.y+10, DrawColor(0xFFFF0000)); DrawText(GoSuManager:GetSpellCooldown(enemy, _R), 15, enemy.pos2D.x+15, enemy.pos2D.y+25, DrawColor(0xFFFFA500))
				else DrawText("R", 15, enemy.pos2D.x+15, enemy.pos2D.y+10, DrawColor(0xFF00FF00)) end
				if GoSuManager:GetSpellCooldown(enemy, SUMMONER_1) ~= 0 then DrawText("SUM1", 15, enemy.pos2D.x-73, enemy.pos2D.y+40, DrawColor(0xFFFF0000))
				else DrawText("SUM1", 15, enemy.pos2D.x-73, enemy.pos2D.y+40, DrawColor(0xFF00FF00)) end
				if GoSuManager:GetSpellCooldown(enemy, SUMMONER_2) ~= 0 then DrawText("SUM2", 15, enemy.pos2D.x-19, enemy.pos2D.y+40, DrawColor(0xFFFF0000))
				else DrawText("SUM2", 15, enemy.pos2D.x-19, enemy.pos2D.y+40, DrawColor(0xFF00FF00)) end
			end
			if self.AwarenessMenu.DrawAA:Value() then
				local AALeft = enemy.health / GoSuManager:CalcPhysicalDamage(myHero, enemy, myHero.totalDamage)
				Draw.Text("AA Left: "..tostring(math.ceil(AALeft)), 15, enemy.pos2D.x+40, enemy.pos2D.y+10, Draw.Color(0xFF00BFFF))
			end
		end
		if self.AwarenessMenu.DrawJng:Value() then
			if enemy:GetSpellData(SUMMONER_1).name:lower():find("smite") and SUMMONER_1 or (enemy:GetSpellData(SUMMONER_2).name:lower():find("smite") and SUMMONER_2) then
				if enemy.alive then
					if GoSuManager:ValidTarget(enemy) then
						if GoSuGeometry:GetDistance(myHero.pos, enemy.pos) > 3000 then DrawText("Jungler: Visible", 17, myHero.pos2D.x-45, myHero.pos2D.y+10, DrawColor(0xFF32CD32))
						else DrawText("Jungler: Near", 17, myHero.pos2D.x-43, myHero.pos2D.y+10, DrawColor(0xFFFF0000)) end
					else
						DrawText("Jungler: Invisible", 17, myHero.pos2D.x-55, myHero.pos2D.y+10, DrawColor(0xFFFFD700))
					end
				else
					DrawText("Jungler: Dead", 17, myHero.pos2D.x-45, myHero.pos2D.y+10, DrawColor(0xFF32CD32))
				end
			end
		end
	end
end

--[[
	┌┐ ┌─┐┌─┐┌─┐┬ ┬┬ ┌┬┐
	├┴┐├─┤└─┐├┤ │ ││  │ 
	└─┘┴ ┴└─┘└─┘└─┘┴─┘┴ 
--]]

class "GoSuBaseUlt"

function GoSuBaseUlt:__init()
	self.EnemyBase = nil; self.RecallData = {}; self.RData = SpellData[myHero.charName][3]
	for i = 1, GameObjectCount() do
		local base = GameObject(i)
		if base.isEnemy and base.type == Obj_AI_SpawnPoint then self.EnemyBase = base break end
	end
	for i = 1, GameHeroCount() do
		local unit = GameHero(i)
		if unit.isEnemy then self.RecallData[unit.charName] = {startTime = 0, duration = 0, missing = 0, isRecalling = false} end
	end
	self.BaseUltMenu = MenuElement({type = MENU, id = "BaseUlt", name = "[GoS-U] BaseUlt"})
	self.BaseUltMenu:MenuElement({id = "Enable", name = "Enable BaseUlt", value = true})
	--self.BaseUltMenu:MenuElement({id = "Check", name = "Check Collision", value = myHero.charName == "Ashe" or myHero.charName == "Jinx"})
	OnRecalls.BaseUlt = function(unit, recall) self:ProcessRecall(unit, recall) end
	OnDraws.BaseUlt = function() self:Tick() end
end

function GoSuBaseUlt:Tick()
	if self.BaseUltMenu.Enable:Value() then
		if GoSuManager:IsReady(_R) then
			for i, enemy in pairs(GoSuManager:GetEnemyHeroes()) do
				local recall = self.RecallData[enemy.charName]
				if recall.isRecalling then
					local FirstStage = enemy.health <= GoSuManager:GetDamage(enemy, 3, 0)
					if FirstStage then DrawText("Possible BaseUlt!", 35, myHero.pos2D.x-85, myHero.pos2D.y+20, DrawColor(192, 220, 20, 60)) end
					local RecallTime = recall.startTime + recall.duration - GameTimer()
					local HitTime = self:CalculateTravelTime()
					if (HitTime - RecallTime) > 0 then
						local PredictedHealth = enemy.health + enemy.hpRegen * HitTime
						if not enemy.visible then PredictedHealth = PredictedHealth + enemy.hpRegen * HitTime end
						if PredictedHealth + enemy.maxHealth * 0.021 <= GoSuManager:GetDamage(enemy, 3, 0) then
							local BasePos = myHero.pos:Extended(self.EnemyBase.pos, 1000)
							ControlCastSpell(HK_R, BasePos)
						end
					end
				end
			end
		end
	end
end

function GoSuBaseUlt:ProcessRecall(unit, recall)
	if self.BaseUltMenu.Enable:Value() then
		if unit.isAlly then return end
		local recallData = self.RecallData[unit.charName]
		if recall.isStart then recallData.startTime = GameTimer(); recallData.duration = recall.totalTime / 1000; recallData.isRecalling = true
		else recallData.isRecalling = false end
	end
end

function GoSuBaseUlt:CalculateTravelTime()
	local distance = GoSuGeometry:GetDistance(myHero.pos, self.EnemyBase.pos); local delay = self.RData.delay + 0.05
	local speed = myHero.charName == "Jinx" and distance > 1350 and (2295000 + (distance - 1350) * 2200) / distance or self.RData.speed
	return (distance / speed + delay)
end

--[[
	┬ ┬┌┬┐┬┬  ┬┌┬┐┬ ┬
	│ │ │ ││  │ │ └┬┘
	└─┘ ┴ ┴┴─┘┴ ┴  ┴ 
--]]

class "GoSuUtility"

function GoSuUtility:__init()
	self.MSIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/0/0a/Mercurial_Scimitar_item.png"
	self.QSIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/f/f9/Quicksilver_Sash_item.png"
	self.BCIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/4/44/Bilgewater_Cutlass_item.png"
	self.BOTRKIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/2/2f/Blade_of_the_Ruined_King_item.png"
	self.HGIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/6/64/Hextech_Gunblade_item.png"
	self.HealIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/6/6e/Heal.png"
	self.UtilityMenu = MenuElement({type = MENU, id = "Utility", name = "[GoS-U] Utility"})
	self.UtilityMenu:MenuElement({id = "Items", name = "Items", type = MENU})
	self.UtilityMenu.Items:MenuElement({id = "Defensive", name = "Defensive Items", type = MENU})
	self.UtilityMenu.Items.Defensive:MenuElement({id = "UseMS", name = "Use Mercurial Scimitar", value = true, leftIcon = self.MSIcon})
	self.UtilityMenu.Items.Defensive:MenuElement({id = "UseQS", name = "Use Quicksilver Sash", value = true, leftIcon = self.QSIcon})
	self.UtilityMenu.Items:MenuElement({id = "Offensive", name = "Offensive Items", type = MENU})
	self.UtilityMenu.Items.Offensive:MenuElement({id = "UseBC", name = "Use Bilgewater Cutlass", value = true, leftIcon = self.BCIcon})
	self.UtilityMenu.Items.Offensive:MenuElement({id = "UseBOTRK", name = "Use BOTRK", value = true, leftIcon = self.BOTRKIcon})
	self.UtilityMenu.Items.Offensive:MenuElement({id = "UseHG", name = "Use Hextech Gunblade", value = true, leftIcon = self.HGIcon})
	self.UtilityMenu.Items.Offensive:MenuElement({id = "HE", name = "Enemy %HP To Use Items", value = 75, min = 0, max = 100, step = 5})
	self.UtilityMenu:MenuElement({id = "SS", name = "Summoner Spells", type = MENU})
	self.UtilityMenu.SS:MenuElement({id = "UseHeal", name = "Use Heal", value = true, leftIcon = self.HealIcon})
	self.UtilityMenu.SS:MenuElement({id = "UseSave", name = "Save Ally Using Heal", value = true, leftIcon = self.HealIcon})
	self.UtilityMenu.SS:MenuElement({id = "HealMe", name = "HP [%] To Use Heal: MyHero", value = 15, min = 0, max = 100, step = 5})
	self.UtilityMenu.SS:MenuElement({id = "HealAlly", name = "HP [%] To Use Heal: Ally", value = 15, min = 0, max = 100, step = 5})
	OnTicks.Utility = function() self:Tick() end
end

function GoSuUtility:Tick()
	if self.UtilityMenu.SS.UseHeal:Value() then
		if myHero.alive and myHero.health > 0 and GoSuManager:GetPercentHP(myHero) < self.UtilityMenu.SS.HealMe:Value() then
			if myHero:GetSpellData(SUMMONER_1).name == "SummonerHeal" and GoSuManager:IsReady(SUMMONER_1) then
				ControlCastSpell(HK_SUMMONER_1)
			elseif myHero:GetSpellData(SUMMONER_2).name == "SummonerHeal" and GoSuManager:IsReady(SUMMONER_2) then
				ControlCastSpell(HK_SUMMONER_2)
			end
		end
		local allies, countAllies = GoSuManager:GetHeroesAround(myHero.pos, 850, "allies")
		if countAllies > 0 then
			for i, ally in pairs(allies) do
				if GoSuManager:ValidTarget(ally, 850) then
					if ally.alive and ally.health > 0 and GoSuManager:GetPercentHP(ally) < self.UtilityMenu.SS.HealAlly:Value() then
						if myHero:GetSpellData(SUMMONER_1).name == "SummonerHeal" and GoSuManager:IsReady(SUMMONER_1) then
							ControlCastSpell(HK_SUMMONER_1, ally.pos)
						elseif myHero:GetSpellData(SUMMONER_2).name == "SummonerHeal" and GoSuManager:IsReady(SUMMONER_2) then
							ControlCastSpell(HK_SUMMONER_2, ally.pos)
						end
					end
				end
			end
		end
	end
	local target = Module.TargetSelector:GetTarget(700, nil)
	if target then
		local itemSlots = {[1] = 3144, [2] = 3153, [3] = 3139, [4] = 3140}
		if GoSuManager:GetPercentHP(target) <= self.UtilityMenu.Items.Offensive.HE:Value() then
			if GoSuManager:ValidTarget(target, 550) then
				for i = 1, 2, 1 do
					if GoSuManager:GetItemSlot(myHero, itemSlots[i]) > 0 then
						if i == 1 and self.UtilityMenu.Items.Offensive.UseBC:Value() or self.UtilityMenu.Items.Offensive.UseBOTRK:Value() then
							if GoSuManager:GetSpellCooldown(myHero, GoSuManager:GetItemSlot(myHero, itemSlots[i])) == 0 then
								ControlCastSpell(Item_HK[GoSuManager:GetItemSlot(myHero, itemSlots[i])], target.pos)
							end
						end
					end
				end
			elseif GoSuManager:ValidTarget(target, 700) then
				if self.UtilityMenu.Items.Offensive.UseHG:Value() then
					if GoSuManager:GetItemSlot(myHero, 3146) > 0 then
						if GoSuManager:GetSpellCooldown(myHero, GoSuManager:GetItemSlot(myHero, 3146)) == 0 then
							ControlCastSpell(Item_HK[GoSuManager:GetItemSlot(myHero, 3146)], target.pos)
						end
					end
				end
			end
		end
		if GoSuManager:IsImmobile(myHero) then
			for i = 3, 4, 1 do
				if GoSuManager:GetItemSlot(myHero, itemSlots[i]) > 0 then
					if i == 3 and self.UtilityMenu.Items.Defensive.UseMS:Value() or self.UtilityMenu.Items.Defensive.UseQS:Value() then
						if GoSuManager:GetSpellCooldown(myHero, GoSuManager:GetItemSlot(myHero, itemSlots[i])) == 0 then
							ControlCastSpell(Item_HK[GoSuManager:GetItemSlot(myHero, itemSlots[i])], myHero.pos)
						end
					end
				end
			end
		end
	end
end

--[[
	┌┬┐┌─┐┬─┐┌─┐┌─┐┌┬┐  ┌─┐┌─┐┬  ┌─┐┌─┐┌┬┐┌─┐┬─┐
	 │ ├─┤├┬┘│ ┬├┤  │   └─┐├┤ │  ├┤ │   │ │ │├┬┘
	 ┴ ┴ ┴┴└─└─┘└─┘ ┴   └─┘└─┘┴─┘└─┘└─┘ ┴ └─┘┴└─
--]]

class "GoSuTargetSelector"

function GoSuTargetSelector:__init()
	self.Timer = 0
	self.SelectedTarget = nil
	self.DamageType = {["Ashe"] = "AD", ["Caitlyn"] = "AD", ["Corki"] = "HB", ["Draven"] = "AD", ["Ezreal"] = "AD", ["Jhin"] = "AD", ["Jinx"] = "AD", ["Kaisa"] = "HB", ["Kalista"] = "AD", ["KogMaw"] = "HB", ["Lucian"] = "AD", ["MissFortune"] = "AD", ["Quinn"] = "AD", ["Sivir"] = "AD", ["Tristana"] = "AD", ["Twitch"] = "AD", ["Varus"] = "AD", ["Vayne"] = "AD", ["Xayah"] = "AD"}
	self.Damage = function(target, dmgType, value) return (dmgType == "AD" and GoSuManager:CalcPhysicalDamage(myHero, target, value)) or (GoSuManager:CalcPhysicalDamage(myHero, target, value / 2) + GoSuManager:CalcMagicalDamage(myHero, target, value / 2)) end
	self.Modes = {
		[1] = function(a, b) return self.Damage(a, self.DamageType[myHero.charName], 100) / (1 + a.health) * self:GetPriority(a) > self.Damage(b, self.DamageType[myHero.charName], 100) / (1 + b.health) * self:GetPriority(b) end,
		[2] = function(a, b) return self:GetPriority(a) > self:GetPriority(b) end,
		[3] = function(a, b) return self.Damage(a, "AD", 100) / (1 + a.health) * self:GetPriority(a) > self.Damage(b, "AD", 100) / (1 + b.health) * self:GetPriority(b) end,
		[4] = function(a, b) return self.Damage(a, "AP", 100) / (1 + a.health) * self:GetPriority(a) > self.Damage(b, "AP", 100) / (1 + b.health) * self:GetPriority(b) end,
		[5] = function(a, b) return self.Damage(a, "AD", 100) / (1 + a.health) > self.Damage(b, "AD", 100) / (1 + b.health) end,
		[6] = function(a, b) return self.Damage(a, "AP", 100) / (1 + a.health) > self.Damage(b, "AP", 100) / (1 + b.health) end,
		[7] = function(a, b) return a.health < b.health end,
		[8] = function(a, b) return a.totalDamage > b.totalDamage end,
		[9] = function(a, b) return a.ap > b.ap end,
		[10] = function(a, b) return GoSuGeometry:GetDistance(a.pos, myHero.pos) < GoSuGeometry:GetDistance(b.pos, myHero.pos) end,
		[11] = function(a, b) return GoSuGeometry:GetDistance(a.pos, mousePos) < GoSuGeometry:GetDistance(b.pos, mousePos) end
	}
	self.Priorities = {
		["Aatrox"] = 3, ["Ahri"] = 4, ["Akali"] = 4, ["Alistar"] = 1, ["Amumu"] = 1, ["Anivia"] = 4, ["Annie"] = 4, ["Ashe"] = 5, ["AurelionSol"] = 4, ["Azir"] = 4,
		["Bard"] = 3, ["Blitzcrank"] = 1, ["Brand"] = 4, ["Braum"] = 1, ["Caitlyn"] = 5, ["Camille"] = 3, ["Cassiopeia"] = 4, ["Chogath"] = 1, ["Corki"] = 5, ["Darius"] = 2,
		["Diana"] = 4, ["DrMundo"] = 1, ["Draven"] = 5, ["Ekko"] = 4, ["Elise"] = 3, ["Evelynn"] = 4, ["Ezreal"] = 5, ["Fiddlesticks"] = 3, ["Fiora"] = 3, ["Fizz"] = 4,
		["Galio"] = 1, ["Gangplank"] = 4, ["Garen"] = 1, ["Gnar"] = 1, ["Gragas"] = 2, ["Graves"] = 4, ["Hecarim"] = 2, ["Heimerdinger"] = 3, ["Illaoi"] =	3, ["Irelia"] = 3,
		["Ivern"] = 1, ["Janna"] = 2, ["JarvanIV"] = 3, ["Jax"] = 3, ["Jayce"] = 4, ["Jhin"] = 5, ["Jinx"] = 5, ["Kaisa"] = 5, ["Kalista"] = 5, ["Karma"] = 4, ["Karthus"] = 4,
		["Kassadin"] = 4, ["Katarina"] = 4, ["Kayle"] = 4, ["Kayn"] = 4, ["Kennen"] = 4, ["Khazix"] = 4, ["Kindred"] = 4, ["Kled"] = 2, ["KogMaw"] = 5, ["Leblanc"] = 4,
		["LeeSin"] = 3, ["Leona"] = 1, ["Lissandra"] = 4, ["Lucian"] = 5, ["Lulu"] = 3, ["Lux"] = 4, ["Malphite"] = 1, ["Malzahar"] = 3, ["Maokai"] = 2, ["MasterYi"] = 5,
		["MissFortune"] = 5, ["MonkeyKing"] = 3, ["Mordekaiser"] = 4, ["Morgana"] = 3, ["Nami"] = 3, ["Nasus"] = 2, ["Nautilus"] = 1, ["Neeko"] = 4, ["Nidalee"] = 4,
		["Nocturne"] = 4, ["Nunu"] = 2, ["Olaf"] = 2, ["Orianna"] = 4, ["Ornn"] = 2, ["Pantheon"] = 3, ["Poppy"] = 2, ["Pyke"] = 5, ["Quinn"] = 5, ["Rakan"] = 3, ["Rammus"] = 1,
		["RekSai"] = 2, ["Renekton"] = 2, ["Rengar"] = 4, ["Riven"] = 4, ["Rumble"] = 4, ["Ryze"] = 4, ["Sejuani"] = 2, ["Shaco"] = 4, ["Shen"] = 1, ["Shyvana"] = 2,
		["Singed"] = 1, ["Sion"] = 1, ["Sivir"] = 5, ["Skarner"] = 2, ["Sona"] = 3, ["Soraka"] = 3, ["Swain"] = 3, ["Sylas"] = 4, ["Ashe"] = 4, ["TahmKench"] = 1,
		["Taliyah"] = 4, ["Talon"] = 4, ["Taric"] = 1, ["Teemo"] = 4, ["Thresh"] = 1, ["Tristana"] = 5, ["Trundle"] = 2, ["Tryndamere"] = 4, ["TwistedFate"] = 4, ["Twitch"] = 5,
		["Udyr"] = 2, ["Urgot"] = 2, ["Varus"] = 5, ["Vayne"] = 5, ["Veigar"] = 4, ["Velkoz"] = 4, ["Vi"] = 2, ["Viktor"] = 4, ["Vladimir"] = 3, ["Volibear"] = 2, ["Warwick"] = 2,
		["Xayah"] = 5, ["Xerath"] = 4, ["XinZhao"] = 3, ["Yasuo"] = 4, ["Yorick"] = 2, ["Zac"] = 1, ["Zed"] = 4, ["Ziggs"] = 4, ["Zilean"] = 3, ["Zoe"] = 4, ["Zyra"] = 2
	}
	self.TSMenu = MenuElement({type = MENU, id = "TargetSelector", name = "[GoS-U] Target Selector"})
	self.TSMenu:MenuElement({id = "TS", name = "Target Selector Mode", drop = {"Auto", "Priority", "Less Attack Priority", "Less Cast Priority", "Less Attack", "Less Cast", "Lowest HP", "Most AD", "Most AP", "Closest", "Near Mouse"}, value = 1})
	self.TSMenu:MenuElement({id = "PR", name = "Priority Menu", type = MENU})
	self.TSMenu:MenuElement({id = "ST", name = "Selected Target", key = string.byte("Z")})
	DelayAction(function()
		for i, enemy in pairs(GoSuManager:GetEnemyHeroes()) do
			self.TSMenu.PR:MenuElement({id = "Level"..enemy.charName, name = enemy.charName, value = (self.Priorities[enemy.charName] or 3), min = 1, max = 5, step = 1})
		end
	end, 0.01)
	OnDraws.TargetSelector = function() self:Draw() end
end

function GoSuTargetSelector:Draw()
	if GameTimer() > self.Timer + 0.2 then
		if self.TSMenu.ST:Value() then
			if self.SelectedTarget == nil then
				for i, enemy in pairs(GoSuManager:GetEnemyHeroes()) do
					if GoSuManager:ValidTarget(enemy) and GoSuGeometry:IsInRange(mousePos, enemy.pos, 50) then self.SelectedTarget = enemy; break end
				end
			else
				self.SelectedTarget = nil
			end
		end
		self.Timer = GameTimer()
	end
	local target = self.SelectedTarget
	if target then DrawCircle(target.pos, 100, 1, DrawColor(192, 255, 215, 0)) end
end

function GoSuTargetSelector:GetPriority(enemy)
	local priority = 1
	if self.TSMenu == nil then return priority end
	if self.TSMenu.PR["Level"..enemy.charName]:Value() ~= nil then
		priority = self.TSMenu.PR["Level"..enemy.charName]:Value()
	end
	if priority == 2 then return 1.5
	elseif priority == 3 then return 1.75
	elseif priority == 4 then return 2
	elseif priority == 5 then return 2.5 end
	return priority
end

function GoSuTargetSelector:GetTarget(range, mode)
	if self.SelectedTarget and GoSuGeometry:GetDistance(myHero.pos, self.SelectedTarget.pos) <= range then
		return self.SelectedTarget
	end
	local targets = {}
	for i, enemy in pairs(GoSuManager:GetEnemyHeroes()) do
		if GoSuManager:ValidTarget(enemy, range) then TableInsert(targets, enemy) end
	end
	self.SelectedMode = mode or self.TSMenu.TS:Value() or 1
	TableSort(targets, self.Modes[self.SelectedMode])
	return #targets > 0 and targets[1] or nil
end

--[[
	┌─┐┌─┐┬ ┬┌─┐
	├─┤└─┐├─┤├┤ 
	┴ ┴└─┘┴ ┴└─┘
--]]

class "Ashe"

function Ashe:__init()
	self.Target1 = nil; self.Target2 = nil
	self.HeroIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/7/7e/Ashe_OriginalSquare.png"
	self.QIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/2/2a/Ranger%27s_Focus_2.png"
	self.WIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/5/5d/Volley.png"
	self.EIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/e/e3/Hawkshot.png"
	self.RIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/2/28/Enchanted_Crystal_Arrow.png"
	self.WData = SpellData[myHero.charName][1]; self.RData = SpellData[myHero.charName][3]
	self.AsheMenu = MenuElement({type = MENU, id = "Ashe", name = "[GoS-U] Ashe", leftIcon = self.HeroIcon})
	self.AsheMenu:MenuElement({id = "Auto", name = "Auto", type = MENU})
	self.AsheMenu.Auto:MenuElement({id = "UseW", name = "Use W [Volley]", value = true, leftIcon = self.WIcon})
	self.AsheMenu.Auto:MenuElement({id = "MP", name = "Mana-Manager", value = 40, min = 0, max = 100, step = 5})
	self.AsheMenu:MenuElement({id = "Combo", name = "Combo", type = MENU})
	self.AsheMenu.Combo:MenuElement({id = "UseQ", name = "Use Q [Ranger's Focus]", value = true, leftIcon = self.QIcon})
	self.AsheMenu.Combo:MenuElement({id = "UseW", name = "Use W [Volley]", value = true, leftIcon = self.WIcon})
	self.AsheMenu.Combo:MenuElement({id = "UseR", name = "Use R [Enchanted Crystal Arrow]", value = true, leftIcon = self.RIcon})
	self.AsheMenu.Combo:MenuElement({id = "Distance", name = "Distance: R", value = 2000, min = self.WData.range, max = 5000, step = 50})
	self.AsheMenu.Combo:MenuElement({id = "X", name = "Minimum Enemies: R", value = 1, min = 0, max = 5, step = 1})
	self.AsheMenu.Combo:MenuElement({id = "HP", name = "HP-Manager: R", value = 40, min = 0, max = 100, step = 5})
	self.AsheMenu:MenuElement({id = "Harass", name = "Harass", type = MENU})
	self.AsheMenu.Harass:MenuElement({id = "UseQ", name = "Use Q [Ranger's Focus]", value = true, leftIcon = self.QIcon})
	self.AsheMenu.Harass:MenuElement({id = "UseW", name = "Use W [Volley]", value = true, leftIcon = self.WIcon})
	self.AsheMenu.Harass:MenuElement({id = "MP", name = "Mana-Manager", value = 40, min = 0, max = 100, step = 5})
	self.AsheMenu:MenuElement({id = "KillSteal", name = "KillSteal", type = MENU})
	self.AsheMenu.KillSteal:MenuElement({id = "UseR", name = "Use R [Enchanted Crystal Arrow]", value = true, leftIcon = self.RIcon})
	self.AsheMenu.KillSteal:MenuElement({id = "Distance", name = "Distance: R", value = 2000, min = self.WData.range, max = 5000, step = 50})
	self.AsheMenu:MenuElement({id = "AntiGapcloser", name = "Anti-Gapcloser", type = MENU})
	self.AsheMenu.AntiGapcloser:MenuElement({id = "UseR", name = "Use R [Enchanted Crystal Arrow]", value = true, leftIcon = self.RIcon})
	self.AsheMenu.AntiGapcloser:MenuElement({id = "Distance", name = "Distance: R", value = 100, min = 25, max = 500, step = 25})
	self.AsheMenu:MenuElement({id = "Interrupter", name = "Interrupter", type = MENU})
	self.AsheMenu.Interrupter:MenuElement({id = "UseRDash", name = "Use R On Dashing Spells", value = false, leftIcon = self.RIcon})
	self.AsheMenu.Interrupter:MenuElement({id = "UseRChan", name = "Use R On Channeling Spells", value = true, leftIcon = self.RIcon})
	self.AsheMenu.Interrupter:MenuElement({id = "CSpells", name = "Channeling Spells", type = MENU})
	self.AsheMenu.Interrupter:MenuElement({id = "Distance", name = "Distance: R", value = 1000, min = 100, max = 1500, step = 50})
	self.AsheMenu.Interrupter:MenuElement({id = "Dng", name = "Minimum Danger Level To Cast", value = 3, min = 1, max = 3, step = 1})
	self.AsheMenu:MenuElement({id = "HitChance", name = "HitChance", type = MENU})
	self.AsheMenu.HitChance:MenuElement({id = "HCW", name = "HitChance: W", value = 10, min = 0, max = 100, step = 1})
	self.AsheMenu.HitChance:MenuElement({id = "HCR", name = "HitChance: R", value = 40, min = 0, max = 100, step = 1})
	self.AsheMenu:MenuElement({id = "Drawings", name = "Drawings", type = MENU})
	self.AsheMenu.Drawings:MenuElement({id = "DrawW", name = "Draw W Range", value = true})
	self.AsheMenu.Drawings:MenuElement({id = "DrawR", name = "Draw R Range", value = true})
	self.AsheMenu.Drawings:MenuElement({id = "WRng", name = "W Range Color", color = DrawColor(192, 218, 112, 214)})
	self.AsheMenu.Drawings:MenuElement({id = "RRng", name = "R Range Color", color = DrawColor(192, 220, 20, 60)})
	self.AsheMenu:MenuElement({id = "Misc", name = "Misc", type = MENU})
	self.AsheMenu.Misc:MenuElement({id = "UseEDragon", name = "Use E On Dragon", key = string.byte("N"), leftIcon = self.EIcon})
	self.AsheMenu.Misc:MenuElement({id = "UseEBaron", name = "Use E On Baron", key = string.byte("M"), leftIcon = self.EIcon})
	self.AsheMenu:MenuElement({id = "blank", name = "GoS-U Reborn v"..LuaVer.."", type = SPACE})
	self.AsheMenu:MenuElement({id = "blank", name = "Author: Ark223", type = SPACE})
	self.AsheMenu:MenuElement({id = "blank", name = "Credits: gamsteron", type = SPACE})
	self.Slot = {[_Q] = "Q", [_W] = "W", [_E] = "E", [_R] = "R"}
	DelayAction(function()
		for i, spell in pairs(ChanellingSpells) do
			for j, hero in pairs(GoSuManager:GetEnemyHeroes()) do
				if not ChanellingSpells[i] then return end
				if spell.charName == hero.charName then
					if not self.AsheMenu.Interrupter.CSpells[i] then self.AsheMenu.Interrupter.CSpells:MenuElement({id = i, name = ""..spell.charName.." "..self.Slot[spell.slot].." | "..spell.displayName, type = MENU}) end
					self.AsheMenu.Interrupter.CSpells[i]:MenuElement({id = "Detect"..i, name = "Detect Spell", value = true})
					self.AsheMenu.Interrupter.CSpells[i]:MenuElement({id = "Danger"..i, name = "Danger Level", value = (spell.danger or 3), min = 1, max = 3, step = 1})
				end
			end
		end
	end, 0.1)
	OnDraws.Champion = function() self:Draw() end
	OnTicks.Champion = function() self:Tick() end
	_G.SDK.Orbwalker:OnPreAttack(function(...) self:OnPreAttack(...) end)
end

function Ashe:Tick()
	if _G.JustEvade and _G.JustEvade:Evading() then return end
	if ((_G.ExtLibEvade and _G.ExtLibEvade.Evading) or Game.IsChatOpen() or not myHero.alive) then return end
	self:Auto2()
	self.Range = myHero.range + myHero.boundingRadius * 2
	self.Target1 = Module.TargetSelector:GetTarget(self.WData.range, nil)
	self.Target2 = Module.TargetSelector:GetTarget(self.AsheMenu.Combo.Distance:Value(), nil)
	if self.Target2 == nil then return end
	if GoSuManager:GetOrbwalkerMode() == "Combo" then Module.Utility:Tick(); self:Combo(self.Target1, self.Target2)
	elseif GoSuManager:GetOrbwalkerMode() == "Harass" then self:Harass(self.Target1)
	else self:Auto(self.Target1) end
end

function Ashe:Draw()
	if self.AsheMenu.Drawings.DrawW:Value() then DrawCircle(myHero.pos, self.WData.range, 1, self.AsheMenu.Drawings.WRng:Value()) end
	if self.AsheMenu.Drawings.DrawR:Value() then DrawCircle(myHero.pos, self.AsheMenu.Combo.Distance:Value(), 1, self.AsheMenu.Drawings.RRng:Value()) end
end

function Ashe:OnPreAttack(args)
	local Mode = GoSuManager:GetOrbwalkerMode()
	if Mode == "Combo" or Mode == "Harass" then
		local target = Module.TargetSelector:GetTarget(self.Range, nil); args.Target = target
		if (self.AsheMenu.Combo.UseQ:Value() and Mode == "Combo") or (GoSuManager:GetPercentMana(myHero) > self.AsheMenu.Harass.MP:Value() and self.AsheMenu.Harass.UseQ:Value() and Mode == "Harass") then
			if GoSuManager:IsReady(_Q) and GoSuManager:ValidTarget(target, self.Range) and GoSuManager:GotBuff(myHero, "asheqcastready") == 4 then
				ControlCastSpell(HK_Q)
			end
		end
	end
end

function Ashe:Auto(target)
	if target == nil or myHero.attackData.state == 2 or GoSuManager:GetPercentMana(myHero) <= self.AsheMenu.Auto.MP:Value() then return end
	if self.AsheMenu.Auto.UseW:Value() and GoSuManager:IsReady(_W) and GoSuManager:ValidTarget(target, self.WData.range) and not GoSuManager:IsUnderTurret(myHero.pos) then
		self:UseW(target)
	end
end

function Ashe:Auto2()
	for i, enemy in pairs(GoSuManager:GetEnemyHeroes()) do
		if GoSuManager:IsReady(_R) and enemy then
			if self.AsheMenu.AntiGapcloser.UseR:Value() and GoSuManager:ValidTarget(enemy, self.AsheMenu.AntiGapcloser.Distance:Value()) then
				self:UseR(enemy, self.AsheMenu.AntiGapcloser.Distance:Value())
			end
			if self.AsheMenu.KillSteal.UseR:Value() and GoSuManager:ValidTarget(enemy, self.AsheMenu.KillSteal.Distance:Value()) then
				local RDmg = GoSuManager:GetDamage(enemy, 3, 0)
				if RDmg > enemy.health then
					self:UseR(enemy, self.AsheMenu.KillSteal.Distance:Value())
				end
			end
			if GoSuManager:ValidTarget(enemy, self.AsheMenu.Interrupter.Distance:Value()) then
				if self.AsheMenu.Interrupter.UseRChan:Value() then
					local spell = enemy.activeSpell
					if spell and spell.valid and spell.isChanneling then
						if ChanellingSpells[spell.name] and self.AsheMenu.Interrupter.CSpells[spell.name] and self.AsheMenu.Interrupter.CSpells[spell.name]["Detect"..spell.name]:Value() then
							if self.AsheMenu.Interrupter.CSpells[spell.name]["Danger"..spell.name]:Value() >= self.AsheMenu.Interrupter.Dng:Value() then
								self:UseR(enemy, self.AsheMenu.Interrupter.Distance:Value())
							end
						end
					end
				end
				if self.AsheMenu.Interrupter.UseRDash:Value() then
					if enemy.pathing.isDashing and enemy.pathing.dashSpeed > 500 then
						if GoSuGeometry:GetDistance(enemy.pos, myHero.pos) > GoSuGeometry:GetDistance(Vector(enemy.pathing.endPos), myHero.pos) then
							self:UseR(enemy, self.AsheMenu.Interrupter.Distance:Value())
						end
					end
				end
			end
		end
	end
	if GoSuManager:IsReady(_E) then
		local Spot = nil
		if self.AsheMenu.Misc.UseEBaron:Value() then Spot = Vector(4942, -71, 10400):ToMM()
		elseif self.AsheMenu.Misc.UseEDragon:Value() then Spot = Vector(9832, -71, 4360):ToMM() end
		if Spot then ControlCastSpell(HK_E, Spot.x, Spot.y) end
	end
end

function Ashe:Combo(target1, target2)
	if target2 == nil or myHero.attackData.state == 2 then return end
	if target1 and self.AsheMenu.Combo.UseW:Value() and GoSuManager:IsReady(_W) and GoSuManager:ValidTarget(target1, self.WData.range) then
		self:UseW(target1)
	end
	if self.AsheMenu.Combo.UseR:Value() and GoSuManager:IsReady(_R) and GoSuManager:ValidTarget(target2, self.AsheMenu.Combo.Distance:Value()) then
		local enemies, count = GoSuManager:GetHeroesAround(myHero.pos, self.AsheMenu.Combo.Distance:Value())
		if GoSuManager:GetPercentHP(target2) < self.AsheMenu.Combo.HP:Value() and count >= self.AsheMenu.Combo.X:Value() then			
			self:UseR(target2, self.AsheMenu.Combo.Distance:Value())
		end
	end
end

function Ashe:Harass(target)
	if target == nil or myHero.attackData.state == 2 or GoSuManager:GetPercentMana(myHero) <= self.AsheMenu.Harass.MP:Value() then return end
	if self.AsheMenu.Harass.UseW:Value() and GoSuManager:IsReady(_W) and GoSuManager:ValidTarget(target, self.WData.range) then
		self:UseW(target)
	end
end

function Ashe:UseW(target)
	local pred = _G.PremiumPrediction:GetPrediction(myHero, target, self.WData)
	if pred.CastPos and pred.HitChance >= (self.AsheMenu.HitChance.HCW:Value() / 100) then ControlCastSpell(HK_W, pred.CastPos) end
end

function Ashe:UseR(target, range)
	self.RData.range = range
	local pred = _G.PremiumPrediction:GetPrediction(myHero, target, self.RData)
	if pred.CastPos and pred.HitChance >= (self.AsheMenu.HitChance.HCR:Value() / 100) then ControlCastSpell(HK_R, myHero.pos:Extended(pred.CastPos, 1000)) end
end

--[[
	┌─┐┌─┐┬─┐┌─┐┌─┐┬  
	├┤ ┌─┘├┬┘├┤ ├─┤│  
	└─┘└─┘┴└─└─┘┴ ┴┴─┘
--]]

class "Ezreal"

function Ezreal:__init()
	self.Target1 = nil; self.Target2 = nil
	self.HeroIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/5/54/Ezreal_OriginalSquare.png"
	self.QIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/5/5a/Mystic_Shot.png"
	self.WIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/9/9e/Essence_Flux.png"
	self.EIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/f/fb/Arcane_Shift.png"
	self.RIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/0/02/Trueshot_Barrage.png"
	self.STIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/2/2b/Tear_of_the_Goddess_item.png"
	self.QData = SpellData[myHero.charName][0]; self.WData = SpellData[myHero.charName][1]
	self.EData = SpellData[myHero.charName][2]; self.RData = SpellData[myHero.charName][3]
	self.EzrealMenu = MenuElement({type = MENU, id = "Ezreal", name = "[GoS-U] Ezreal", leftIcon = self.HeroIcon})
	self.EzrealMenu:MenuElement({id = "Auto", name = "Auto", type = MENU})
	self.EzrealMenu.Auto:MenuElement({id = "UseQ", name = "Use Q [Mystic Shot]", value = true, leftIcon = self.QIcon})
	self.EzrealMenu.Auto:MenuElement({id = "UseW", name = "Use W [Essence Flux]", value = false, leftIcon = self.WIcon})
	self.EzrealMenu.Auto:MenuElement({id = "MP", name = "Mana-Manager", value = 40, min = 0, max = 100, step = 5})
	self.EzrealMenu:MenuElement({id = "Combo", name = "Combo", type = MENU})
	self.EzrealMenu.Combo:MenuElement({id = "UseQ", name = "Use Q [Mystic Shot]", value = true, leftIcon = self.QIcon})
	self.EzrealMenu.Combo:MenuElement({id = "UseW", name = "Use W [Essence Flux]", value = true, leftIcon = self.WIcon})
	self.EzrealMenu.Combo:MenuElement({id = "UseR", name = "Use R [Trueshot Barrage]", value = true, leftIcon = self.RIcon})
	self.EzrealMenu.Combo:MenuElement({id = "Distance", name = "Distance: R", value = 2000, min = self.QData.range, max = 5000, step = 50})
	self.EzrealMenu.Combo:MenuElement({id = "X", name = "Minimum Enemies: R", value = 1, min = 0, max = 5, step = 1})
	self.EzrealMenu.Combo:MenuElement({id = "HP", name = "HP-Manager: R", value = 40, min = 0, max = 100, step = 5})
	self.EzrealMenu:MenuElement({id = "Harass", name = "Harass", type = MENU})
	self.EzrealMenu.Harass:MenuElement({id = "UseQ", name = "Use Q [Mystic Shot]", value = true, leftIcon = self.QIcon})
	self.EzrealMenu.Harass:MenuElement({id = "UseW", name = "Use W [Essence Flux]", value = true, leftIcon = self.WIcon})
	self.EzrealMenu.Harass:MenuElement({id = "MP", name = "Mana-Manager", value = 40, min = 0, max = 100, step = 5})
	self.EzrealMenu:MenuElement({id = "LaneClear", name = "LaneClear", type = MENU})
	self.EzrealMenu.LaneClear:MenuElement({id = "UseQ", name = "Use Q [Mystic Shot]", value = false, leftIcon = self.QIcon})
	self.EzrealMenu.LaneClear:MenuElement({id = "MP", name = "Mana-Manager", value = 70, min = 0, max = 100, step = 5})
	self.EzrealMenu:MenuElement({id = "KillSteal", name = "KillSteal", type = MENU})
	self.EzrealMenu.KillSteal:MenuElement({id = "UseR", name = "Use R [Trueshot Barrage]", value = true, leftIcon = self.RIcon})
	self.EzrealMenu.KillSteal:MenuElement({id = "Distance", name = "Distance: R", value = 2000, min = self.QData.range, max = 5000, step = 50})
	self.EzrealMenu:MenuElement({id = "AntiGapcloser", name = "Anti-Gapcloser", type = MENU})
	self.EzrealMenu.AntiGapcloser:MenuElement({id = "UseE", name = "Use E [Arcane Shift]", value = true, leftIcon = self.EIcon})
	self.EzrealMenu.AntiGapcloser:MenuElement({id = "CastE", name = "Cast Range: E", value = 275, min = 25, max = self.EData.range, step = 25})
	self.EzrealMenu.AntiGapcloser:MenuElement({id = "Distance", name = "Distance: E", value = 200, min = 25, max = 500, step = 25})
	self.EzrealMenu:MenuElement({id = "HitChance", name = "HitChance", type = MENU})
	self.EzrealMenu.HitChance:MenuElement({id = "HCQ", name = "HitChance: Q", value = 40, min = 0, max = 100, step = 1})
	self.EzrealMenu.HitChance:MenuElement({id = "HCW", name = "HitChance: W", value = 40, min = 0, max = 100, step = 1})
	self.EzrealMenu.HitChance:MenuElement({id = "HCR", name = "HitChance: R", value = 50, min = 0, max = 100, step = 1})
	self.EzrealMenu:MenuElement({id = "Drawings", name = "Drawings", type = MENU})
	self.EzrealMenu.Drawings:MenuElement({id = "DrawQW", name = "Draw Q/W Range", value = true})
	self.EzrealMenu.Drawings:MenuElement({id = "DrawE", name = "Draw E Range", value = true})
	self.EzrealMenu.Drawings:MenuElement({id = "DrawR", name = "Draw R Range", value = true})
	self.EzrealMenu.Drawings:MenuElement({id = "QWRng", name = "Q/W Range Color", color = DrawColor(192, 0, 250, 154)})
	self.EzrealMenu.Drawings:MenuElement({id = "ERng", name = "E Range Color", color = DrawColor(192, 255, 140, 0)})
	self.EzrealMenu.Drawings:MenuElement({id = "RRng", name = "R Range Color", color = DrawColor(192, 220, 20, 60)})
	self.EzrealMenu:MenuElement({id = "Misc", name = "Misc", type = MENU})
	self.EzrealMenu.Misc:MenuElement({id = "StackTear", name = "Stack Tear", value = false, leftIcon = self.STIcon})
	self.EzrealMenu.Misc:MenuElement({id = "STMana", name = "Mana-Manager: Tear", value = 75, min = 0, max = 100, step = 5})
	self.EzrealMenu:MenuElement({id = "blank", name = "GoS-U Reborn v"..LuaVer.."", type = SPACE})
	self.EzrealMenu:MenuElement({id = "blank", name = "Author: Ark223", type = SPACE})
	self.EzrealMenu:MenuElement({id = "blank", name = "Credits: gamsteron", type = SPACE})
	OnDraws.Champion = function() self:Draw() end
	OnTicks.Champion = function() self:Tick() end
	_G.SDK.Orbwalker:OnPreAttack(function(...) self:OnPreAttack(...) end)
end

function Ezreal:Tick()
	if _G.JustEvade and _G.JustEvade:Evading() then return end
	if _G.ExtLibEvade and _G.ExtLibEvade.Evading or Game.IsChatOpen() or not myHero.alive then return end
	self:Auto2()
	if GoSuManager:GetOrbwalkerMode() == "Clear" then self:LaneClear() end
	self.Range = myHero.range + myHero.boundingRadius * 2
	self.Target1 = Module.TargetSelector:GetTarget(self.QData.range, nil)
	self.Target2 = Module.TargetSelector:GetTarget(self.EzrealMenu.Combo.Distance:Value(), nil)
	if self.Target2 == nil then return end
	if GoSuManager:GetOrbwalkerMode() == "Combo" then Module.Utility:Tick(); self:Combo(self.Target1, self.Target2)
	elseif GoSuManager:GetOrbwalkerMode() == "Harass" then self:Harass(self.Target1)
	else self:Auto(self.Target1) end
end

function Ezreal:Draw()
	if self.EzrealMenu.Drawings.DrawQW:Value() then DrawCircle(myHero.pos, self.QData.range, 1, self.EzrealMenu.Drawings.QWRng:Value()) end
	if self.EzrealMenu.Drawings.DrawE:Value() then DrawCircle(myHero.pos, self.EData.range, 1, self.EzrealMenu.Drawings.ERng:Value()) end
	if self.EzrealMenu.Drawings.DrawR:Value() then DrawCircle(myHero.pos, self.EzrealMenu.Combo.Distance:Value(), 1, self.EzrealMenu.Drawings.RRng:Value()) end
end

function Ezreal:OnPreAttack(args)
	if GoSuManager:GetOrbwalkerMode() == "Combo" or GoSuManager:GetOrbwalkerMode() == "Harass" then
		local target = Module.TargetSelector:GetTarget(self.Range, nil); args.Target = target
	end
end

function Ezreal:Auto(target)
	if target == nil or myHero.attackData.state == 2 then return end
	if GoSuManager:GetPercentMana(myHero) > self.EzrealMenu.Auto.MP:Value() and GoSuManager:ValidTarget(target, self.QData.range) and not GoSuManager:IsUnderTurret(myHero.pos) then
		if self.EzrealMenu.Auto.UseW:Value() and ((self.EzrealMenu.Auto.UseQ:Value() and GoSuManager:IsReady(_Q) and GoSuManager:IsReady(_W)) or (GoSuManager:IsReady(_W) and GoSuManager:ValidTarget(target, self.Range))) then
			self:UseW(target)
		elseif self.EzrealMenu.Auto.UseQ:Value() and GoSuManager:IsReady(_Q) then
			self:UseQ(target)
		end
	end
end

function Ezreal:Auto2()
	for i, enemy in pairs(GoSuManager:GetEnemyHeroes()) do
		if enemy then
			if GoSuManager:IsReady(_E) and self.EzrealMenu.AntiGapcloser.UseE:Value() and GoSuManager:ValidTarget(enemy, self.EzrealMenu.AntiGapcloser.Distance:Value()) then
				ControlCastSpell(HK_E, myHero.pos:Extended(enemy.pos, -self.EzrealMenu.AntiGapcloser.CastE:Value()))
			end
			if GoSuManager:IsReady(_R) and self.EzrealMenu.KillSteal.UseR:Value() and GoSuManager:ValidTarget(enemy, self.EzrealMenu.KillSteal.Distance:Value()) then
				local RDmg = GoSuManager:GetDamage(enemy, 3, 0)
				if RDmg > enemy.health then
					self:UseR(enemy, self.EzrealMenu.KillSteal.Distance:Value())
				end
			end
		end
	end
	if GoSuManager:GetOrbwalkerMode() == "" and self.EzrealMenu.Misc.StackTear:Value() then
		local enemies, count = GoSuManager:GetHeroesAround(myHero.pos, 3000, "enemies")
		if count == 0 and GoSuManager:GetItemSlot(myHero, 3070) > 0 and GoSuManager:GetPercentMana(myHero) >= self.EzrealMenu.Misc.STMana:Value() then
			ControlCastSpell(HK_Q)
		end
	end
end

function Ezreal:Combo(target1, target2)
	if target2 == nil or myHero.attackData.state == 2 then return end
	if target1 and GoSuManager:ValidTarget(target1, self.QData.range) then
		if self.EzrealMenu.Combo.UseW:Value() and ((self.EzrealMenu.Combo.UseQ:Value() and GoSuManager:IsReady(_Q) and GoSuManager:IsReady(_W)) or (GoSuManager:IsReady(_W) and GoSuManager:ValidTarget(target1, self.Range))) then
			self:UseW(target1)
		elseif self.EzrealMenu.Combo.UseQ:Value() and GoSuManager:IsReady(_Q) then
			self:UseQ(target1)
		end
	end
	if self.EzrealMenu.Combo.UseR:Value() and GoSuManager:IsReady(_R) and GoSuManager:ValidTarget(target2, self.EzrealMenu.Combo.Distance:Value()) then
		local enemies, count = GoSuManager:GetHeroesAround(myHero.pos, self.EzrealMenu.Combo.Distance:Value())
		if GoSuManager:GetPercentHP(target2) < self.EzrealMenu.Combo.HP:Value() and count >= self.EzrealMenu.Combo.X:Value() then			
			self:UseR(target2, self.EzrealMenu.Combo.Distance:Value())
		end
	end
end

function Ezreal:Harass(target)
	if target == nil or myHero.attackData.state == 2 then return end
	if GoSuManager:GetPercentMana(myHero) > self.EzrealMenu.Harass.MP:Value() and GoSuManager:ValidTarget(target, self.QData.range) then
		if self.EzrealMenu.Harass.UseW:Value() and ((self.EzrealMenu.Harass.UseQ:Value() and GoSuManager:IsReady(_Q) and GoSuManager:IsReady(_W)) or (GoSuManager:IsReady(_W) and GoSuManager:ValidTarget(target, self.Range))) then
			self:UseW(target)
		elseif self.EzrealMenu.Harass.UseQ:Value() and GoSuManager:IsReady(_Q) then
			self:UseQ(target)
		end
	end
end

function Ezreal:LaneClear()
	if GoSuManager:GetPercentMana(myHero) > self.EzrealMenu.LaneClear.MP:Value() and GoSuManager:IsReady(_Q) and self.EzrealMenu.LaneClear.UseQ:Value() then
		local minions, count = GoSuManager:GetMinionsAround(myHero.pos, self.QData.range)
		if count > 0 then
			for i = 1, #minions do
				local minion = minions[i]
				for j = 1, #minions do
					local target = minions[j]
					local endPos = myHero.pos:Extended(target.pos, GoSuGeometry:GetDistance(myHero.pos, target.pos) - (target.boundingRadius / 2))
					local pointSegment, pointLine, isOnSegment = GoSuGeometry:VectorPointProjectionOnLineSegment(myHero.pos, endPos, minion.pos)
					if isOnSegment and GoSuGeometry:GetDistanceSqr(pointSegment, minion.pos) <= (self.QData.radius + minion.boundingRadius * 2) ^ 2 then return end
					local QDmg = GoSuManager:GetDamage(target, 0, 0)
					if QDmg > target.health then
						if GoSuGeometry:GetDistanceSqr(myHero.pos, target.pos) <= self.Range ^ 2 and myHero.attackData.state == 3 or GoSuGeometry:GetDistanceSqr(myHero.pos, target.pos) > self.Range ^ 2 then
							ControlCastSpell(HK_Q, target.pos)
						end
					end
				end
			end
		end
	end
end

function Ezreal:UseQ(target)
	local pred = _G.PremiumPrediction:GetPrediction(myHero, target, self.QData)
	if pred.CastPos and pred.HitChance >= (self.EzrealMenu.HitChance.HCQ:Value() / 100) then ControlCastSpell(HK_Q, pred.CastPos) end
end

function Ezreal:UseW(target)
	local pred = _G.PremiumPrediction:GetPrediction(myHero, target, self.WData)
	if pred.CastPos and pred.HitChance >= (self.EzrealMenu.HitChance.HCW:Value() / 100) then ControlCastSpell(HK_W, pred.CastPos) end
end

function Ezreal:UseR(target, range)
	self.RData.range = range
	local pred = _G.PremiumPrediction:GetPrediction(myHero, target, self.RData)
	if pred.CastPos and pred.HitChance >= (self.EzrealMenu.HitChance.HCR:Value() / 100) then ControlCastSpell(HK_R, myHero.pos:Extended(pred.CastPos, 1000)) end
end

--[[
	 ┬┬┌┐┌─┐ ┬
	 │││││┌┴┬┘
	└┘┴┘└┘┴ └─
--]]

class "Jinx"

function Jinx:__init()
	self.Target = nil; self.Target1 = nil; self.Target2 = nil
	self.BonusRange = {75, 100, 125, 150, 175}
	self.HeroIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/6/65/Jinx_OriginalSquare.png"
	self.QIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/4/4d/Pow-Pow.png"
	self.WIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/7/76/Zap%21.png"
	self.EIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/b/bb/Flame_Chompers%21.png"
	self.RIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/a/a8/Super_Mega_Death_Rocket%21.png"
	self.WData = SpellData[myHero.charName][1]; self.EData = SpellData[myHero.charName][2]; self.RData = SpellData[myHero.charName][3]
	self.JinxMenu = MenuElement({type = MENU, id = "Jinx", name = "[GoS-U] Jinx", leftIcon = self.HeroIcon})
	self.JinxMenu:MenuElement({id = "Combo", name = "Combo", type = MENU})
	self.JinxMenu.Combo:MenuElement({id = "UseQ", name = "Use Q [Switcheroo!]", value = true, leftIcon = self.QIcon})
	self.JinxMenu.Combo:MenuElement({id = "UseW", name = "Use W [Zap!]", value = true, leftIcon = self.WIcon})
	self.JinxMenu.Combo:MenuElement({id = "UseE", name = "Use E [Flame Chompers!]", value = true, leftIcon = self.EIcon})
	self.JinxMenu.Combo:MenuElement({id = "UseR", name = "Use R [Super Mega Death Rocket!]", value = true, leftIcon = self.RIcon})
	self.JinxMenu.Combo:MenuElement({id = "ModeW", name = "Cast Mode: W", drop = {"Standard", "Out Of AA"}, value = 2})
	self.JinxMenu.Combo:MenuElement({id = "Distance", name = "Distance: R", value = 2000, min = self.WData.range, max = 5000, step = 50})
	self.JinxMenu.Combo:MenuElement({id = "X", name = "Minimum Enemies: R", value = 2, min = 0, max = 5, step = 1})
	self.JinxMenu.Combo:MenuElement({id = "HP", name = "HP-Manager: R", value = 40, min = 0, max = 100, step = 5})
	self.JinxMenu:MenuElement({id = "Harass", name = "Harass", type = MENU})
	self.JinxMenu.Harass:MenuElement({id = "UseQ", name = "Use Q [Switcheroo!]", value = true, leftIcon = self.QIcon})
	self.JinxMenu.Harass:MenuElement({id = "UseW", name = "Use W [Zap!]", value = true, leftIcon = self.WIcon})
	self.JinxMenu.Harass:MenuElement({id = "UseE", name = "Use E [Flame Chompers!]", value = false, leftIcon = self.EIcon})
	self.JinxMenu.Harass:MenuElement({id = "ModeW", name = "Cast Mode: W", drop = {"Standard", "Out Of AA"}, value = 1})
	self.JinxMenu.Harass:MenuElement({id = "MP", name = "Mana-Manager", value = 40, min = 0, max = 100, step = 5})
	self.JinxMenu:MenuElement({id = "KillSteal", name = "KillSteal", type = MENU})
	self.JinxMenu.KillSteal:MenuElement({id = "UseR", name = "Use R [Super Mega Death Rocket!]", value = true, leftIcon = self.RIcon})
	self.JinxMenu.KillSteal:MenuElement({id = "Distance", name = "Distance: R", value = 2000, min = self.WData.range, max = 5000, step = 50})
	self.JinxMenu:MenuElement({id = "AntiGapcloser", name = "Anti-Gapcloser", type = MENU})
	self.JinxMenu.AntiGapcloser:MenuElement({id = "UseE", name = "Use E [Flame Chompers!]", value = true, leftIcon = self.EIcon})
	self.JinxMenu.AntiGapcloser:MenuElement({id = "Distance", name = "Distance: E", value = 100, min = 25, max = 500, step = 25})
	self.JinxMenu:MenuElement({id = "HitChance", name = "HitChance", type = MENU})
	self.JinxMenu.HitChance:MenuElement({id = "HCW", name = "HitChance: W", value = 35, min = 0, max = 100, step = 1})
	self.JinxMenu.HitChance:MenuElement({id = "HCE", name = "HitChance: E", value = 60, min = 0, max = 100, step = 1})
	self.JinxMenu.HitChance:MenuElement({id = "HCR", name = "HitChance: R", value = 30, min = 0, max = 100, step = 1})
	self.JinxMenu:MenuElement({id = "Drawings", name = "Drawings", type = MENU})
	self.JinxMenu.Drawings:MenuElement({id = "DrawW", name = "Draw W Range", value = true})
	self.JinxMenu.Drawings:MenuElement({id = "DrawE", name = "Draw E Range", value = true})
	self.JinxMenu.Drawings:MenuElement({id = "DrawR", name = "Draw R Range", value = true})
	self.JinxMenu.Drawings:MenuElement({id = "WRng", name = "W Range Color", color = DrawColor(192, 218, 112, 214)})
	self.JinxMenu.Drawings:MenuElement({id = "ERng", name = "E Range Color", color = DrawColor(192, 255, 140, 0)})
	self.JinxMenu.Drawings:MenuElement({id = "RRng", name = "R Range Color", color = DrawColor(192, 220, 20, 60)})
	self.JinxMenu:MenuElement({id = "blank", name = "GoS-U Reborn v"..LuaVer.."", type = SPACE})
	self.JinxMenu:MenuElement({id = "blank", name = "Author: Ark223", type = SPACE})
	self.JinxMenu:MenuElement({id = "blank", name = "Credits: gamsteron", type = SPACE})
	OnDraws.Champion = function() self:Draw() end
	OnTicks.Champion = function() self:Tick() end
	_G.SDK.Orbwalker:OnPreAttack(function(...) self:OnPreAttack(...) end)
end

function Jinx:Tick()
	if _G.JustEvade and _G.JustEvade:Evading() then return end
	if (_G.ExtLibEvade and _G.ExtLibEvade.Evading) or Game.IsChatOpen() or not myHero.alive then return end
	self:Auto2()
	local mode = GoSuManager:GetOrbwalkerMode()
	if mode == "Clear" and self:HasQ2() then ControlCastSpell(HK_Q) end
	self.Range = myHero.range + myHero.boundingRadius * 2
	self.Target = Module.TargetSelector:GetTarget(655 + self.BonusRange[GoSuManager:GetCastLevel(myHero, _Q)], nil)
	self.Target1 = Module.TargetSelector:GetTarget(self.WData.range, nil)
	self.Target2 = Module.TargetSelector:GetTarget(self.JinxMenu.Combo.Distance:Value(), nil)
	if self.Target2 == nil then return end
	if mode == "Combo" then Module.Utility:Tick(); self:Combo(self.Target1, self.Target2, self.Target)
	elseif mode == "Harass" then self:Harass(self.Target1, self.Target) end
end

function Jinx:Draw()
	if self.JinxMenu.Drawings.DrawW:Value() then DrawCircle(myHero.pos, self.WData.range, 1, self.JinxMenu.Drawings.WRng:Value()) end
	if self.JinxMenu.Drawings.DrawE:Value() then DrawCircle(myHero.pos, self.EData.range, 1, self.JinxMenu.Drawings.ERng:Value()) end
	if self.JinxMenu.Drawings.DrawR:Value() then DrawCircle(myHero.pos, self.JinxMenu.Combo.Distance:Value(), 1, self.JinxMenu.Drawings.RRng:Value()) end
end

function Jinx:OnPreAttack(args)
	if GoSuManager:GetOrbwalkerMode() == "Combo" or GoSuManager:GetOrbwalkerMode() == "Harass" then
		args.Target = self.Target
	end
end

function Jinx:Auto2()
	for i, enemy in pairs(GoSuManager:GetEnemyHeroes()) do
		if enemy then
			if GoSuManager:IsReady(_E) and self.JinxMenu.AntiGapcloser.UseE:Value() and GoSuManager:ValidTarget(enemy, self.JinxMenu.AntiGapcloser.Distance:Value()) then
				self:UseE(enemy, self.JinxMenu.AntiGapcloser.Distance:Value())
			end
			if GoSuManager:IsReady(_R) and self.JinxMenu.KillSteal.UseR:Value() and GoSuManager:ValidTarget(enemy, self.JinxMenu.KillSteal.Distance:Value()) then
				local RDmg = GoSuManager:GetDamage(enemy, 3, 0)
				if RDmg > enemy.health then
					self:UseR(enemy, self.JinxMenu.KillSteal.Distance:Value())
				end
			end
		end
	end
end

function Jinx:Combo(target1, target2, target3)
	if target2 == nil or myHero.attackData.state == 2 then return end
	if target3 and GoSuManager:IsReady(_Q) and self.JinxMenu.Combo.UseQ:Value() then
		local dist = GoSuGeometry:GetDistance(myHero.pos, target3.pos)
		if dist > 615 and not self:HasQ2() or (dist < 615 and self:HasQ2()) then
			ControlCastSpell(HK_Q)
		end
	end
	if target1 then
		if GoSuManager:IsReady(_W) and GoSuManager:ValidTarget(target1, self.WData.range) and self.JinxMenu.Combo.UseW:Value() then
			if self.JinxMenu.Combo.ModeW:Value() == 2 and GoSuGeometry:GetDistance(myHero.pos, target1.pos) > self.Range or self.JinxMenu.Combo.ModeW:Value() == 1 then
				self:UseW(target1)
			end
		end
		if GoSuManager:IsReady(_E) and GoSuManager:ValidTarget(target1, self.EData.range) and self.JinxMenu.Combo.UseE:Value() then
			self:UseE(target1)
		end
	end
	if self.JinxMenu.Combo.UseR:Value() and GoSuManager:IsReady(_R) and GoSuManager:ValidTarget(target2, self.JinxMenu.Combo.Distance:Value()) then
		local enemies, count = GoSuManager:GetHeroesAround(myHero.pos, self.JinxMenu.Combo.Distance:Value())
		if GoSuManager:GetPercentHP(target2) < self.JinxMenu.Combo.HP:Value() and count >= self.JinxMenu.Combo.X:Value() then			
			self:UseR(target2, self.JinxMenu.Combo.Distance:Value())
		end
	end
end

function Jinx:Harass(target1, target2)
	if target1 == nil or GoSuManager:GetPercentMana(myHero) <= self.JinxMenu.Harass.MP:Value() or myHero.attackData.state == 2 then return end
	if target2 and GoSuManager:IsReady(_Q) and self.JinxMenu.Harass.UseQ:Value() then
		local dist = GoSuGeometry:GetDistance(myHero.pos, target2.pos)
		if dist > 615 and not self:HasQ2() or (dist < 615 and self:HasQ2()) then
			ControlCastSpell(HK_Q)
		end
	end
	if GoSuManager:IsReady(_W) and GoSuManager:ValidTarget(target1, self.WData.range) and self.JinxMenu.Harass.UseW:Value() then
		if self.JinxMenu.Harass.ModeW:Value() == 2 and GoSuGeometry:GetDistance(myHero.pos, target1.pos) > self.Range or self.JinxMenu.Harass.ModeW:Value() == 1 then
			self:UseW(target1)
		end
	end
	if GoSuManager:IsReady(_E) and GoSuManager:ValidTarget(target1, self.EData.range) and self.JinxMenu.Harass.UseE:Value() then
		self:UseE(target1)
	end
end

function Jinx:HasQ2()
	return GoSuManager:GotBuff(myHero, "JinxQ") > 0
end

function Jinx:UseW(target)
	local pred = _G.PremiumPrediction:GetPrediction(myHero, target, self.WData)
	if pred.CastPos and pred.HitChance >= (self.JinxMenu.HitChance.HCW:Value() / 100) then ControlCastSpell(HK_W, pred.CastPos) end
end

function Jinx:UseE(target)
	local pred = _G.PremiumPrediction:GetPrediction(myHero, target, self.EData)
	if pred.CastPos and pred.HitChance >= (self.JinxMenu.HitChance.HCE:Value() / 100) then ControlCastSpell(HK_E, pred.PredPos) end
end

function Jinx:UseR(target, range)
	self.RData.range = range
	local pred = _G.PremiumPrediction:GetPrediction(myHero, target, self.RData)
	if pred.CastPos and pred.HitChance >= (self.JinxMenu.HitChance.HCR:Value() / 100) then ControlCastSpell(HK_R, pred.PredPos) end
end

--[[
	┬┌─┌─┐┬┌─┐┌─┐
	├┴┐├─┤│└─┐├─┤
	┴ ┴┴ ┴┴└─┘┴ ┴
--]]

class "Kaisa"

function Kaisa:__init()
	self.Target1 = nil; self.Target2 = nil; self.Timer = 0
	self.HeroIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/1/15/Kai%27Sa_OriginalSquare.png"
	self.QIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/9/9a/Icathian_Rain.png"
	self.WIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/8/89/Void_Seeker.png"
	self.EIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/e/e4/Supercharge.png"
	self.QData = SpellData[myHero.charName][0]; self.WData = SpellData[myHero.charName][1]
	self.KaisaMenu = MenuElement({type = MENU, id = "Kaisa", name = "[GoS-U] Kai'Sa", leftIcon = self.HeroIcon})
	self.KaisaMenu:MenuElement({id = "Auto", name = "Auto", type = MENU})
	self.KaisaMenu.Auto:MenuElement({id = "UseQ", name = "Use Q [Icathian Rain]", value = true, leftIcon = self.QIcon})
	self.KaisaMenu.Auto:MenuElement({id = "MP", name = "Mana-Manager: Q", value = 40, min = 0, max = 100, step = 5})
	self.KaisaMenu:MenuElement({id = "Combo", name = "Combo", type = MENU})
	self.KaisaMenu.Combo:MenuElement({id = "UseQ", name = "Use Q [Icathian Rain]", value = true, leftIcon = self.QIcon})
	self.KaisaMenu.Combo:MenuElement({id = "UseW", name = "Use W [Void Seeker]", value = true, leftIcon = self.WIcon})
	self.KaisaMenu:MenuElement({id = "Harass", name = "Harass", type = MENU})
	self.KaisaMenu.Harass:MenuElement({id = "UseQ", name = "Use Q [Icathian Rain]", value = true, leftIcon = self.QIcon})
	self.KaisaMenu.Harass:MenuElement({id = "UseW", name = "Use W [Void Seeker]", value = true, leftIcon = self.WIcon})
	self.KaisaMenu.Harass:MenuElement({id = "MP", name = "Mana-Manager: Q", value = 40, min = 0, max = 100, step = 5})
	self.KaisaMenu:MenuElement({id = "LaneClear", name = "LaneClear", type = MENU})
	self.KaisaMenu.LaneClear:MenuElement({id = "UseQ", name = "Use Q [Icathian Rain]", value = true, leftIcon = self.QIcon})
	self.KaisaMenu.LaneClear:MenuElement({id = "MMH", name = "Minimum Minions To Hit", value = 5, min = 1, max = 10, step = 1})
	self.KaisaMenu.LaneClear:MenuElement({id = "MP", name = "Mana-Manager: Q", value = 40, min = 0, max = 100, step = 5})
	self.KaisaMenu:MenuElement({id = "KillSteal", name = "KillSteal", type = MENU})
	self.KaisaMenu.KillSteal:MenuElement({id = "UseW", name = "Use W [Void Seeker]", value = true, leftIcon = self.WIcon})
	self.KaisaMenu:MenuElement({id = "HitChance", name = "HitChance", type = MENU})
	self.KaisaMenu.HitChance:MenuElement({id = "HCW", name = "HitChance: W", value = 25, min = 0, max = 100, step = 1})
	self.KaisaMenu:MenuElement({id = "Drawings", name = "Drawings", type = MENU})
	self.KaisaMenu.Drawings:MenuElement({id = "DrawQ", name = "Draw Q Range", value = true})
	self.KaisaMenu.Drawings:MenuElement({id = "DrawW", name = "Draw W Range", value = true})
	self.KaisaMenu.Drawings:MenuElement({id = "QRng", name = "Q Range Color", color = DrawColor(192, 0, 250, 154)})
	self.KaisaMenu.Drawings:MenuElement({id = "WRng", name = "W Range Color", color = DrawColor(192, 218, 112, 214)})
	self.KaisaMenu:MenuElement({id = "blank", name = "GoS-U Reborn v"..LuaVer.."", type = SPACE})
	self.KaisaMenu:MenuElement({id = "blank", name = "Author: Ark223", type = SPACE})
	self.KaisaMenu:MenuElement({id = "blank", name = "Credits: gamsteron", type = SPACE})
	OnDraws.Champion = function() self:Draw() end
	OnTicks.Champion = function() self:Tick() end
	_G.SDK.Orbwalker:OnPreAttack(function(...) self:OnPreAttack(...) end)
end

function Kaisa:Tick()
	if _G.JustEvade and _G.JustEvade:Evading() then return end
	if ((_G.ExtLibEvade and _G.ExtLibEvade.Evading) or Game.IsChatOpen() or not myHero.alive or GoSuManager:GotBuff(myHero, "KaisaE") > 0) then return end
	self:Auto2()
	if GoSuManager:GetOrbwalkerMode() == "Clear" then self:LaneClear() end
	self.Range = myHero.range + myHero.boundingRadius * 2
	self.Target1 = Module.TargetSelector:GetTarget(self.QData.range, nil)
	self.Target2 = Module.TargetSelector:GetTarget(self.WData.range, nil)
	if self.Target2 == nil then return end
	if GoSuManager:GetOrbwalkerMode() == "Combo" then Module.Utility:Tick(); self:Combo(self.Target1, self.Target2)
	elseif GoSuManager:GetOrbwalkerMode() == "Harass" then self:Harass(self.Target1, self.Target2)
	else self:Auto(self.Target1) end
end

function Kaisa:Draw()
	if self.KaisaMenu.Drawings.DrawQ:Value() then DrawCircle(myHero.pos, self.QData.range, 1, self.KaisaMenu.Drawings.QRng:Value()) end
	if self.KaisaMenu.Drawings.DrawW:Value() then DrawCircle(myHero.pos, self.WData.range, 1, self.KaisaMenu.Drawings.WRng:Value()) end
end

function Kaisa:OnPreAttack(args)
	if GoSuManager:GetOrbwalkerMode() == "Combo" or GoSuManager:GetOrbwalkerMode() == "Harass" then
		local target = Module.TargetSelector:GetTarget(self.Range, nil); args.Target = target
	end
end

function Kaisa:Auto(target)
	if target == nil or myHero.attackData.state == 2 or GoSuManager:GetPercentMana(myHero) <= self.KaisaMenu.Auto.MP:Value() then return end
	if self.KaisaMenu.Auto.UseQ:Value() and GoSuManager:IsReady(_Q) and GoSuManager:ValidTarget(target, self.QData.range) and not GoSuManager:IsUnderTurret(myHero.pos) then
		ControlCastSpell(HK_Q)
	end
end

function Kaisa:Auto2()
	for i, enemy in pairs(GoSuManager:GetEnemyHeroes()) do
		if enemy and GoSuManager:IsReady(_W) and self.KaisaMenu.KillSteal.UseW:Value() and GoSuManager:ValidTarget(enemy, self.WData.range) then
			local WDmg = GoSuManager:GetDamage(enemy, 1, 0)
			if WDmg > enemy.health then
				self:UseW(enemy)
			end
		end
	end
end

function Kaisa:Combo(target1, target2)
	if target2 == nil or myHero.attackData.state == 2 then return end
	if target1 and self.KaisaMenu.Combo.UseQ:Value() and GoSuManager:IsReady(_Q) and GoSuManager:ValidTarget(target1, self.QData.range) then
		ControlCastSpell(HK_Q)
	end
	if self.KaisaMenu.Combo.UseW:Value() and GoSuManager:IsReady(_W) and GoSuManager:ValidTarget(target2, self.WData.range) then
		self:UseW(target2)
	end
end

function Kaisa:Harass(target1, target2)
	if target2 == nil or myHero.attackData.state == 2 or GoSuManager:GetPercentMana(myHero) <= self.KaisaMenu.Harass.MP:Value() then return end
	if target1 and self.KaisaMenu.Harass.UseQ:Value() and GoSuManager:IsReady(_Q) and GoSuManager:ValidTarget(target1, self.QData.range) then
		ControlCastSpell(HK_Q)
	end
	if self.KaisaMenu.Harass.UseW:Value() and GoSuManager:IsReady(_W) and GoSuManager:ValidTarget(target2, self.WData.range) then
		self:UseW(target2)
	end
end

function Kaisa:LaneClear()
	if myHero.attackData.state == 2 or GoSuManager:GetPercentMana(myHero) <= self.KaisaMenu.LaneClear.MP:Value() then return end
	local minions, count = GoSuManager:GetMinionsAround(myHero.pos, self.QData.range)
	if count >= self.KaisaMenu.LaneClear.MMH:Value() and GoSuManager:IsReady(_Q) and self.KaisaMenu.LaneClear.UseQ:Value() then
		ControlCastSpell(HK_Q)
	end
end

function Kaisa:UseW(target)
	local pred = _G.PremiumPrediction:GetPrediction(myHero, target, self.WData)
	if pred.CastPos and pred.HitChance >= (self.KaisaMenu.HitChance.HCW:Value() / 100) then ControlCastSpell(HK_W, myHero.pos:Extended(pred.CastPos, 500)) end
end

--[[
	┬┌─┌─┐┌─┐┌┬┐┌─┐┬ ┬
	├┴┐│ ││ ┬│││├─┤│││
	┴ ┴└─┘└─┘┴ ┴┴ ┴└┴┘
--]]

class "KogMaw"

function KogMaw:__init()
	self.Target1 = nil; self.Target2 = nil; self.Timer = 0
	self.BonusRange = {130, 150, 170, 190, 210}
	self.HeroIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/b/bd/Kog%27Maw_OriginalSquare.png"
	self.QIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/a/a9/Caustic_Spittle.png"
	self.WIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/e/ef/Bio-Arcane_Barrage.png"
	self.EIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/0/0c/Void_Ooze.png"
	self.RIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/b/bf/Living_Artillery.png"
	self.QData = SpellData[myHero.charName][0]; self.EData = SpellData[myHero.charName][2]; self.RData = SpellData[myHero.charName][3]
	self.KogMawMenu = MenuElement({type = MENU, id = "KogMaw", name = "[GoS-U] Kog'Maw", leftIcon = self.HeroIcon})
	self.KogMawMenu:MenuElement({id = "Auto", name = "Auto", type = MENU})
	self.KogMawMenu.Auto:MenuElement({id = "UseQ", name = "Use Q [Caustic Spittle]", value = true, leftIcon = self.QIcon})
	self.KogMawMenu.Auto:MenuElement({id = "UseR", name = "Use R [Living Artillery]", key = string.byte("A"), leftIcon = self.RIcon})
	self.KogMawMenu.Auto:MenuElement({id = "MP", name = "Mana-Manager", value = 40, min = 0, max = 100, step = 5})
	self.KogMawMenu:MenuElement({id = "Combo", name = "Combo", type = MENU})
	self.KogMawMenu.Combo:MenuElement({id = "UseQ", name = "Use Q [Caustic Spittle]", value = true, leftIcon = self.QIcon})
	self.KogMawMenu.Combo:MenuElement({id = "UseW", name = "Use W [Bio-Arcane Barrage]", value = true, leftIcon = self.WIcon})
	self.KogMawMenu.Combo:MenuElement({id = "UseE", name = "Use E [Void Ooze]", value = true, leftIcon = self.EIcon})
	self.KogMawMenu.Combo:MenuElement({id = "UseR", name = "Use R [Living Artillery]", value = true, leftIcon = self.RIcon})
	self.KogMawMenu.Combo:MenuElement({id = "MaxStacks", name = "Max Stacks While >%HP: R", value = 4, min = 1, max = 10, step = 1})
	self.KogMawMenu.Combo:MenuElement({id = "HP", name = "HP-Manager: R", value = 40, min = 0, max = 100, step = 5})
	self.KogMawMenu.Combo:MenuElement({id = "MP", name = "Mana-Manager: R", value = 10, min = 0, max = 100, step = 5})
	self.KogMawMenu:MenuElement({id = "Harass", name = "Harass", type = MENU})
	self.KogMawMenu.Harass:MenuElement({id = "UseQ", name = "Use Q [Caustic Spittle]", value = true, leftIcon = self.QIcon})
	self.KogMawMenu.Harass:MenuElement({id = "UseW", name = "Use W [Bio-Arcane Barrage]", value = true, leftIcon = self.WIcon})
	self.KogMawMenu.Harass:MenuElement({id = "UseE", name = "Use E [Void Ooze]", value = false, leftIcon = self.EIcon})
	self.KogMawMenu.Harass:MenuElement({id = "UseR", name = "Use R [Living Artillery]", value = true, leftIcon = self.RIcon})
	self.KogMawMenu.Harass:MenuElement({id = "MaxStacks", name = "Max Stacks While >%HP: R", value = 3, min = 1, max = 10, step = 1})
	self.KogMawMenu.Harass:MenuElement({id = "HP", name = "HP-Manager: R", value = 40, min = 0, max = 100, step = 5})
	self.KogMawMenu.Harass:MenuElement({id = "MP", name = "Mana-Manager", value = 40, min = 0, max = 100, step = 5})
	self.KogMawMenu:MenuElement({id = "LaneClear", name = "LaneClear", type = MENU})
	self.KogMawMenu.LaneClear:MenuElement({id = "UseQ", name = "Use Q [Caustic Spittle]", value = false, leftIcon = self.QIcon})
	self.KogMawMenu.LaneClear:MenuElement({id = "UseR", name = "Use R [Living Artillery]", value = true, leftIcon = self.RIcon})
	self.KogMawMenu.LaneClear:MenuElement({id = "MMH", name = "Minimum Minions To Hit: R", value = 3, min = 1, max = 10, step = 1})
	self.KogMawMenu.LaneClear:MenuElement({id = "MaxStacks", name = "Max Stacks: R", value = 1, min = 1, max = 10, step = 1})
	self.KogMawMenu.LaneClear:MenuElement({id = "MP", name = "Mana-Manager", value = 70, min = 0, max = 100, step = 5})
	self.KogMawMenu:MenuElement({id = "KillSteal", name = "KillSteal", type = MENU})
	self.KogMawMenu.KillSteal:MenuElement({id = "UseR", name = "Use R [Living Artillery]", value = true, leftIcon = self.RIcon})
	self.KogMawMenu:MenuElement({id = "AntiGapcloser", name = "Anti-Gapcloser", type = MENU})
	self.KogMawMenu.AntiGapcloser:MenuElement({id = "UseE", name = "Use E [Void Ooze]", value = true, leftIcon = self.EIcon})
	self.KogMawMenu.AntiGapcloser:MenuElement({id = "Distance", name = "Distance: E", value = 400, min = 25, max = 500, step = 25})
	self.KogMawMenu:MenuElement({id = "HitChance", name = "HitChance", type = MENU})
	self.KogMawMenu.HitChance:MenuElement({id = "HCQ", name = "HitChance: Q", value = 40, min = 0, max = 100, step = 1})
	self.KogMawMenu.HitChance:MenuElement({id = "HCE", name = "HitChance: E", value = 50, min = 0, max = 100, step = 1})
	self.KogMawMenu.HitChance:MenuElement({id = "HCR", name = "HitChance: R", value = 40, min = 0, max = 100, step = 1})
	self.KogMawMenu:MenuElement({id = "Drawings", name = "Drawings", type = MENU})
	self.KogMawMenu.Drawings:MenuElement({id = "DrawQ", name = "Draw Q Range", value = true})
	self.KogMawMenu.Drawings:MenuElement({id = "DrawE", name = "Draw E Range", value = true})
	self.KogMawMenu.Drawings:MenuElement({id = "DrawR", name = "Draw R Range", value = true})
	self.KogMawMenu.Drawings:MenuElement({id = "QRng", name = "Q Range Color", color = DrawColor(192, 0, 250, 154)})
	self.KogMawMenu.Drawings:MenuElement({id = "ERng", name = "E Range Color", color = DrawColor(192, 255, 140, 0)})
	self.KogMawMenu.Drawings:MenuElement({id = "RRng", name = "R Range Color", color = DrawColor(192, 220, 20, 60)})
	self.KogMawMenu:MenuElement({id = "blank", name = "GoS-U Reborn v"..LuaVer.."", type = SPACE})
	self.KogMawMenu:MenuElement({id = "blank", name = "Author: Ark223", type = SPACE})
	self.KogMawMenu:MenuElement({id = "blank", name = "Credits: gamsteron", type = SPACE})
	OnDraws.Champion = function() self:Draw() end
	OnTicks.Champion = function() self:Tick() end
	_G.SDK.Orbwalker:OnPreAttack(function(...) self:OnPreAttack(...) end)
end

function KogMaw:Tick()
	if _G.JustEvade and _G.JustEvade:Evading() then return end
	if ((_G.ExtLibEvade and _G.ExtLibEvade.Evading) or Game.IsChatOpen() or not myHero.alive) then return end
	self.RRange = GoSuManager:GetCastRange(myHero, _R)
	self:Auto2()
	if GoSuManager:GetOrbwalkerMode() == "Clear" then self:LaneClear() end
	self.AARange = myHero.range + myHero.boundingRadius * 2
	self.Target1 = Module.TargetSelector:GetTarget(self.EData.range, nil)
	self.Target2 = Module.TargetSelector:GetTarget(self.RRange, nil)
	if self.Target2 == nil then return end
	if GoSuManager:GetOrbwalkerMode() == "Combo" then Module.Utility:Tick(); self:Combo(self.Target1, self.Target2)
	elseif GoSuManager:GetOrbwalkerMode() == "Harass" then self:Harass(self.Target1, self.Target2)
	else self:Auto(self.Target1) end
end

function KogMaw:Draw()
	if self.KogMawMenu.Drawings.DrawQ:Value() then DrawCircle(myHero.pos, self.QData.range, 1, self.KogMawMenu.Drawings.QRng:Value()) end
	if self.KogMawMenu.Drawings.DrawE:Value() then DrawCircle(myHero.pos, self.EData.range, 1, self.KogMawMenu.Drawings.ERng:Value()) end
	if self.KogMawMenu.Drawings.DrawR:Value() then DrawCircle(myHero.pos, GoSuManager:GetCastRange(myHero, _R), 1, self.KogMawMenu.Drawings.RRng:Value()) end
end

function KogMaw:OnPreAttack(args)
	local Mode = GoSuManager:GetOrbwalkerMode()
	if Mode == "Combo" or Mode == "Harass" then
		local target = Module.TargetSelector:GetTarget(self.AARange, nil); args.Target = target
		local target2 = Module.TargetSelector:GetTarget(self.AARange + self.BonusRange[GoSuManager:GetCastLevel(myHero, _W)], nil)
		if GoSuManager:IsReady(_W) and target2 and GoSuManager:ValidTarget(target2) and ((self.KogMawMenu.Combo.UseW:Value() and Mode == "Combo") or (GoSuManager:GetPercentMana(myHero) > self.KogMawMenu.Harass.MP:Value() and self.KogMawMenu.Harass.UseW:Value() and Mode == "Harass")) then
			ControlCastSpell(HK_W)
		end
	end
end

function KogMaw:Auto(target)
	if target == nil or myHero.attackData.state == 2 then return end
	if self.KogMawMenu.Auto.UseQ:Value() and GoSuManager:IsReady(_Q) and GoSuManager:ValidTarget(target, self.QData.range) and not GoSuManager:IsUnderTurret(myHero.pos) then
		if GoSuManager:GetPercentMana(myHero) > self.KogMawMenu.Auto.MP:Value() then self:UseQ(target) end
	end
	if self.KogMawMenu.Auto.UseR:Value() and GoSuManager:IsReady(_R) and GoSuManager:ValidTarget(target, self.RRange) then
		if GameTimer() > self.Timer + 0.25 then self:UseR(target, self.RRange) end
		self.Timer = GameTimer()
	end
end

function KogMaw:Auto2()
	for i, enemy in pairs(GoSuManager:GetEnemyHeroes()) do
		if enemy then
			if GoSuManager:IsReady(_E) and self.KogMawMenu.AntiGapcloser.UseE:Value() and GoSuManager:ValidTarget(enemy, self.KogMawMenu.AntiGapcloser.Distance:Value()) then
				self:UseE(enemy)
			end
			if GoSuManager:IsReady(_R) and self.KogMawMenu.KillSteal.UseR:Value() and GoSuManager:ValidTarget(enemy, self.RRange) then
				local RDmg = GoSuManager:GetDamage(enemy, 3, 0)
				if RDmg > enemy.health then
					self:UseR(enemy, self.RRange)
				end
			end
		end
	end
end

function KogMaw:Combo(target1, target2)
	if target2 == nil or myHero.attackData.state == 2 then return end
	if target1 then
		if self.KogMawMenu.Combo.UseQ:Value() and GoSuManager:IsReady(_Q) and GoSuManager:ValidTarget(target1, self.QData.range) then
			self:UseQ(target1)
		end
		if self.KogMawMenu.Combo.UseE:Value() and GoSuManager:IsReady(_E) and GoSuManager:ValidTarget(target1, self.EData.range) then
			self:UseE(target1)
		end
	end
	if GoSuManager:GetPercentMana(myHero) > self.KogMawMenu.Combo.MP:Value() and self.KogMawMenu.Combo.UseR:Value() and GoSuManager:IsReady(_R) and GoSuManager:ValidTarget(target2, self.RRange) then
		if GoSuManager:GetPercentHP(target2) > self.KogMawMenu.Combo.HP:Value() and (GoSuManager:GotBuff(myHero, "kogmawlivingartillerycost") + 1) <= self.KogMawMenu.Combo.MaxStacks:Value() or GoSuManager:GetPercentHP(target2) <= self.KogMawMenu.Combo.HP:Value() then
			if GoSuGeometry:GetDistance(myHero.pos, target2.pos) > self.AARange then self:UseR(target2, self.RRange) end
		end
	end
end

function KogMaw:Harass(target1, target2)
	if target2 == nil or myHero.attackData.state == 2 or GoSuManager:GetPercentMana(myHero) <= self.KogMawMenu.Harass.MP:Value() then return end
	if target1 then
		if self.KogMawMenu.Harass.UseQ:Value() and GoSuManager:IsReady(_Q) and GoSuManager:ValidTarget(target1, self.QData.range) then
			self:UseQ(target1)
		end
		if self.KogMawMenu.Harass.UseE:Value() and GoSuManager:IsReady(_E) and GoSuManager:ValidTarget(target1, self.EData.range) then
			self:UseE(target1)
		end
	end
	if GoSuManager:GetPercentMana(myHero) > self.KogMawMenu.Harass.MP:Value() and self.KogMawMenu.Harass.UseR:Value() and GoSuManager:IsReady(_R) and GoSuManager:ValidTarget(target2, self.RRange) then
		if GoSuManager:GetPercentHP(target2) > self.KogMawMenu.Harass.HP:Value() and (GoSuManager:GotBuff(myHero, "kogmawlivingartillerycost") + 1) <= self.KogMawMenu.Harass.MaxStacks:Value() then
			if GoSuGeometry:GetDistance(myHero.pos, target2.pos) > self.AARange then self:UseR(target2, self.RRange) end
		end
	end
end

function KogMaw:LaneClear()
	if myHero.attackData.state == 2 or GoSuManager:GetPercentMana(myHero) <= self.KogMawMenu.LaneClear.MP:Value() then return end
	local minions, count = GoSuManager:GetMinionsAround(myHero.pos, self.RData.range)
	if count > 0 then
		if GoSuManager:IsReady(_R) and self.KogMawMenu.LaneClear.UseR:Value() then
			local BestPos, MostHit = GoSuGeometry:GetBestCircularAOEPos(minions, self.RData.radius, self.KogMawMenu.LaneClear.MMH:Value())
			if BestPos and (GoSuManager:GotBuff(myHero, "kogmawlivingartillerycost") + 1) <= self.KogMawMenu.LaneClear.MaxStacks:Value() then
				ControlCastSpell(HK_R, BestPos)
			end
		end
	end
	minions = GoSuGeometry:CutUnitsRange(minions, self.QData.range)
	if GoSuManager:IsReady(_Q) and self.KogMawMenu.LaneClear.UseQ:Value() then
		for i = 1, #minions do
			local minion = minions[i]
			for j = 1, #minions do
				local target = minions[j]
				local endPos = myHero.pos:Extended(target.pos, GoSuGeometry:GetDistance(myHero.pos, target.pos) - (target.boundingRadius / 2))
				local pointSegment, pointLine, isOnSegment = GoSuGeometry:VectorPointProjectionOnLineSegment(myHero.pos, endPos, minion.pos)
				if isOnSegment and GoSuGeometry:GetDistanceSqr(pointSegment, minion.pos) <= (self.QData.radius + minion.boundingRadius * 2) ^ 2 then return end
				local QDmg = GoSuManager:GetDamage(target, 0, 0)
				if QDmg > target.health then
					if GoSuGeometry:GetDistanceSqr(myHero.pos, target.pos) <= self.AARange ^ 2 and myHero.attackData.state == 3 or GoSuGeometry:GetDistanceSqr(myHero.pos, target.pos) > self.AARange ^ 2 then
						ControlCastSpell(HK_Q, target.pos)
					end
				end
			end
		end
	end
end

function KogMaw:UseQ(target)
	local pred = _G.PremiumPrediction:GetPrediction(myHero, target, self.QData)
	if pred.CastPos and pred.HitChance >= (self.KogMawMenu.HitChance.HCQ:Value() / 100) then ControlCastSpell(HK_Q, pred.CastPos) end
end

function KogMaw:UseE(target)
	local pred = _G.PremiumPrediction:GetPrediction(myHero, target, self.EData)
	if pred.CastPos and pred.HitChance >= (self.KogMawMenu.HitChance.HCE:Value() / 100) then ControlCastSpell(HK_E, pred.PredPos) end
end

function KogMaw:UseR(target)
	local pred = _G.PremiumPrediction:GetPrediction(myHero, target, self.RData)
	if pred.CastPos and pred.HitChance >= (self.KogMawMenu.HitChance.HCR:Value() / 100) then ControlCastSpell(HK_R, pred.CastPos) end
end

--[[
	┬  ┬ ┬┌─┐┬┌─┐┌┐┌
	│  │ ││  │├─┤│││
	┴─┘└─┘└─┘┴┴ ┴┘└┘
--]]

class "Lucian"

function Lucian:__init()
	self.Target1 = nil; self.Target2 = nil; self.MPos = mousePos; self.Timer = GameTimer()
	self.HeroIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/1/10/Lucian_OriginalSquare.png"
	self.QIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/2/2d/Piercing_Light.png"
	self.WIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/6/60/Ardent_Blaze.png"
	self.EIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/f/f1/Relentless_Pursuit.png"
	self.RIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/6/6e/The_Culling.png"
	self.QData = SpellData[myHero.charName][0]; self.WData = SpellData[myHero.charName][1]
	self.EData = SpellData[myHero.charName][2]; self.RData = SpellData[myHero.charName][3]
	self.LucianMenu = MenuElement({type = MENU, id = "Lucian", name = "[GoS-U] Lucian", leftIcon = self.HeroIcon})
	self.LucianMenu:MenuElement({id = "Auto", name = "Auto", type = MENU})
	self.LucianMenu.Auto:MenuElement({id = "UseExQ", name = "Use Extended Q", value = true, leftIcon = self.QIcon})
	self.LucianMenu.Auto:MenuElement({id = "MP", name = "Mana-Manager", value = 40, min = 0, max = 100, step = 5})
	self.LucianMenu:MenuElement({id = "Combo", name = "Combo", type = MENU})
	self.LucianMenu.Combo:MenuElement({id = "UseQ", name = "Use Q [Piercing Light]", value = true, leftIcon = self.QIcon})
	self.LucianMenu.Combo:MenuElement({id = "UseExQ", name = "Use Extended Q", value = true, leftIcon = self.QIcon})
	self.LucianMenu.Combo:MenuElement({id = "UseW", name = "Use W [Ardent Blaze]", value = true, leftIcon = self.WIcon})
	self.LucianMenu.Combo:MenuElement({id = "UseE", name = "Use E [Relentless Pursuit]", value = true, leftIcon = self.EIcon})
	self.LucianMenu.Combo:MenuElement({id = "ModeE", name = "Cast Mode: E", drop = {"Mouse", "Smart"}, value = 2})
	self.LucianMenu:MenuElement({id = "Harass", name = "Harass", type = MENU})
	self.LucianMenu.Harass:MenuElement({id = "UseQ", name = "Use Q [Piercing Light]", value = true, leftIcon = self.QIcon})
	self.LucianMenu.Harass:MenuElement({id = "UseExQ", name = "Use Extended Q", value = true, leftIcon = self.QIcon})
	self.LucianMenu.Harass:MenuElement({id = "UseW", name = "Use W [Ardent Blaze]", value = true, leftIcon = self.WIcon})
	self.LucianMenu.Harass:MenuElement({id = "UseE", name = "Use E [Relentless Pursuit]", value = false, leftIcon = self.EIcon})
	self.LucianMenu.Harass:MenuElement({id = "ModeE", name = "Cast Mode: E", drop = {"Mouse", "Smart"}, value = 1})
	self.LucianMenu.Harass:MenuElement({id = "MP", name = "Mana-Manager", value = 40, min = 0, max = 100, step = 5})
	self.LucianMenu:MenuElement({id = "LaneClear", name = "LaneClear", type = MENU})
	self.LucianMenu.LaneClear:MenuElement({id = "UseQ", name = "Use Q [Piercing Light]", value = false, leftIcon = self.QIcon})
	self.LucianMenu.LaneClear:MenuElement({id = "MMH", name = "Minimum Minions To Hit", value = 4, min = 1, max = 10, step = 1})
	self.LucianMenu.LaneClear:MenuElement({id = "MP", name = "Mana-Manager", value = 70, min = 0, max = 100, step = 5})
	self.LucianMenu:MenuElement({id = "AntiGapcloser", name = "Anti-Gapcloser", type = MENU})
	self.LucianMenu.AntiGapcloser:MenuElement({id = "UseE", name = "Use E [Relentless Pursuit]", value = true, leftIcon = self.EIcon})
	self.LucianMenu.AntiGapcloser:MenuElement({id = "CastE", name = "Cast Range: E", value = 325, min = 25, max = self.EData.range, step = 25})
	self.LucianMenu.AntiGapcloser:MenuElement({id = "Distance", name = "Distance: E", value = 75, min = 25, max = 500, step = 25})
	self.LucianMenu:MenuElement({id = "HitChance", name = "HitChance", type = MENU})
	self.LucianMenu.HitChance:MenuElement({id = "HCQ", name = "HitChance: Q", value = 15, min = 0, max = 100, step = 1})
	self.LucianMenu.HitChance:MenuElement({id = "HCW", name = "HitChance: W", value = 15, min = 0, max = 100, step = 1})
	self.LucianMenu:MenuElement({id = "Drawings", name = "Drawings", type = MENU})
	self.LucianMenu.Drawings:MenuElement({id = "DrawQ", name = "Draw Q Range", value = true})
	self.LucianMenu.Drawings:MenuElement({id = "DrawW", name = "Draw W Range", value = true})
	self.LucianMenu.Drawings:MenuElement({id = "DrawE", name = "Draw E Range", value = true})
	self.LucianMenu.Drawings:MenuElement({id = "DrawR", name = "Draw R Range", value = true})
	self.LucianMenu.Drawings:MenuElement({id = "QRng", name = "Q Range Color", color = DrawColor(192, 0, 250, 154)})
	self.LucianMenu.Drawings:MenuElement({id = "WRng", name = "W Range Color", color = DrawColor(192, 218, 112, 214)})
	self.LucianMenu.Drawings:MenuElement({id = "ERng", name = "E Range Color", color = DrawColor(192, 255, 140, 0)})
	self.LucianMenu.Drawings:MenuElement({id = "RRng", name = "R Range Color", color = DrawColor(192, 220, 20, 60)})
	self.LucianMenu:MenuElement({id = "blank", name = "GoS-U Reborn v"..LuaVer.."", type = SPACE})
	self.LucianMenu:MenuElement({id = "blank", name = "Author: Ark223", type = SPACE})
	self.LucianMenu:MenuElement({id = "blank", name = "Credits: gamsteron", type = SPACE})
	OnDraws.Champion = function() self:Draw() end
	OnTicks.Champion = function() self:Tick() end
	_G.SDK.Orbwalker:OnPreAttack(function(...) self:OnPreAttack(...) end)
	_G.SDK.Orbwalker:OnPostAttackTick(function(...) self:OnPostAttackTick(...) end)
end

function Lucian:Tick()
	if _G.JustEvade and _G.JustEvade:Evading() then return end
	if ((_G.ExtLibEvade and _G.ExtLibEvade.Evading) or Game.IsChatOpen() or not myHero.alive) then return end
	self:Auto2()
	if GoSuManager:GetOrbwalkerMode() == "Clear" then self:LaneClear() end
	self.Range = myHero.range + myHero.boundingRadius * 2
	self.Target = Module.TargetSelector:GetTarget(self.WData.range, nil)
	if self.Target == nil then return end
	if GoSuManager:GetOrbwalkerMode() == "Combo" then Module.Utility:Tick(); self:Combo(self.Target)
	elseif GoSuManager:GetOrbwalkerMode() == "Harass" then self:Harass(self.Target)
	else self:Auto(self.Target) end
end

function Lucian:Draw()
	if self.LucianMenu.Drawings.DrawQ:Value() then DrawCircle(myHero.pos, self.QData.range2, 1, self.LucianMenu.Drawings.QRng:Value()) end
	if self.LucianMenu.Drawings.DrawW:Value() then DrawCircle(myHero.pos, self.WData.range, 1, self.LucianMenu.Drawings.WRng:Value()) end
	if self.LucianMenu.Drawings.DrawE:Value() then DrawCircle(myHero.pos, self.EData.range, 1, self.LucianMenu.Drawings.ERng:Value()) end
	if self.LucianMenu.Drawings.DrawR:Value() then DrawCircle(myHero.pos, self.RData.range, 1, self.LucianMenu.Drawings.RRng:Value()) end
end

function Lucian:OnPreAttack(args)
	if GoSuManager:GetOrbwalkerMode() == "Combo" or GoSuManager:GetOrbwalkerMode() == "Harass" then
		local target = Module.TargetSelector:GetTarget(self.Range, nil); args.Target = target; self.MPos = mousePos; self.Timer = GameTimer()
	end
end

function Lucian:OnPostAttackTick(args)
	if _G.JustEvade and _G.JustEvade:Evading() or (_G.ExtLibEvade and _G.ExtLibEvade.Evading) then return end
	if self.Target then
		local Mode = GoSuManager:GetOrbwalkerMode()
		if Mode == "Harass" and GoSuManager:GetPercentMana(myHero) <= self.LucianMenu.Harass.MP:Value() then return end
		local target2 = Module.TargetSelector:GetTarget(self.QData.range2 + myHero.boundingRadius, nil)
		if target2 and GoSuManager:IsReady(_Q) and ((self.LucianMenu.Combo.UseQ:Value() and Mode == "Combo") or (self.LucianMenu.Harass.UseQ:Value() and Mode == "Harass")) then
			ControlCastSpell(HK_Q, target2.pos)
		elseif GoSuManager:IsReady(_E) and ((self.LucianMenu.Combo.UseE:Value() and Mode == "Combo") or (self.LucianMenu.Harass.UseE:Value() and Mode == "Harass")) then
			self:UseE(self.Target, Mode == "Combo" and self.LucianMenu.Combo.ModeE:Value() or self.LucianMenu.Harass.ModeE:Value())
		elseif GoSuManager:ValidTarget(self.Target, self.WData.range) and GoSuManager:IsReady(_W) and ((self.LucianMenu.Combo.UseW:Value() and Mode == "Combo") or (self.LucianMenu.Harass.UseW:Value() and Mode == "Harass")) then
			self:UseW(self.Target)
		end
	end
end

function Lucian:Auto(target)
	if target == nil or myHero.attackData.state == 2 then return end
	if GoSuManager:GetPercentMana(myHero) > self.LucianMenu.Auto.MP:Value() and GoSuManager:IsReady(_Q) and not GoSuManager:IsUnderTurret(myHero.pos) then
		if self.LucianMenu.Auto.UseExQ:Value() and GoSuManager:ValidTarget(target, self.QData.range) then self:UseExQ(target) end
	end
end

function Lucian:Auto2()
	for i, enemy in pairs(GoSuManager:GetEnemyHeroes()) do
		if GoSuManager:IsReady(_E) and self.LucianMenu.AntiGapcloser.UseE:Value() and GoSuManager:ValidTarget(enemy, self.LucianMenu.AntiGapcloser.Distance:Value()) then
			ControlCastSpell(HK_E, myHero.pos:Extended(enemy.pos, -self.LucianMenu.AntiGapcloser.CastE:Value()))
		end
	end
end

function Lucian:Combo(target)
	if target == nil or myHero.attackData.state == 2 then return end
	if self.LucianMenu.Combo.UseExQ:Value() and GoSuManager:IsReady(_Q) and GoSuManager:ValidTarget(target, self.QData.range) then
		if GoSuGeometry:GetDistance(myHero.pos, target.pos) > self.QData.range2 then self:UseExQ(target) end
	end
end

function Lucian:Harass(target)
	if target == nil or myHero.attackData.state == 2 or GoSuManager:GetPercentMana(myHero) <= self.LucianMenu.Harass.MP:Value() then return end
	if self.LucianMenu.Harass.UseExQ:Value() and GoSuManager:IsReady(_Q) and GoSuManager:ValidTarget(target, self.QData.range) then
		if GoSuGeometry:GetDistance(myHero.pos, target.pos) > self.QData.range2 then self:UseExQ(target) end
	end
end

function Lucian:LaneClear()
	if myHero.attackData.state == 2 or GoSuManager:GetPercentMana(myHero) <= self.LucianMenu.LaneClear.MP:Value() then return end
	if GoSuManager:IsReady(_Q) and self.LucianMenu.LaneClear.UseQ:Value() then
		local minions, count = GoSuManager:GetMinionsAround(myHero.pos, self.QData.range)
		if count > 0 then
			for i = 1, #minions do
				local minion = minions[i]
				if GoSuGeometry:GetDistance(myHero.pos, minion.pos) < self.QData.range2 then
					local MostHit = 0
					for j = 1, #minions do
						local target = minions[j]
						local endPos = myHero.pos:Extended(minion.pos, self.QData.range)
						local pointSegment, pointLine, isOnSegment = GoSuGeometry:VectorPointProjectionOnLineSegment(myHero.pos, endPos, target.pos)
						if isOnSegment and GoSuGeometry:GetDistanceSqr(pointSegment, target.pos) <= self.QData.radius ^ 2 then
							MostHit = MostHit + 1
						end
					end
					if MostHit >= self.LucianMenu.LaneClear.MMH:Value() then ControlCastSpell(HK_Q, minion.pos); return end
				end
			end
		end
	end
end

function Lucian:UseExQ(target)
	local pred = _G.PremiumPrediction:GetPrediction(myHero, target, self.QData)
	if pred.CastPos and pred.HitChance >= (self.LucianMenu.HitChance.HCQ:Value() / 100) then
		local minions, count = GoSuManager:GetMinionsAround(myHero.pos, self.QData.range)
		if count > 0 then
			for i = 1, #minions do
				local minion = minions[i]
				if GoSuGeometry:GetDistance(myHero.pos, minion.pos) <= self.QData.range2 and not GoSuManager:IsUnderTurret(myHero.pos) then
					local extendedQ = myHero.pos:Extended(minion.pos, self.QData.range)
					local pointSegment, pointLine, isOnSegment = GoSuGeometry:VectorPointProjectionOnLineSegment(myHero.pos, extendedQ, pred.CastPos)
					if GoSuGeometry:GetDistanceSqr(pointSegment, pred.CastPos) <= self.QData.radius ^ 2 then ControlCastSpell(HK_Q, minion.pos) end
				end
			end
		end
	end
end

function Lucian:UseW(target)
	local pred = _G.PremiumPrediction:GetPrediction(myHero, target, self.WData)
	if pred.CastPos and pred.HitChance >= (self.LucianMenu.HitChance.HCW:Value() / 100) then ControlCastSpell(HK_W, pred.CastPos) end
end

function Lucian:UseE(target, mode)
	if self.Timer + 1 < GameTimer() then self.MPos = mousePos end
	if mode == 1 then ControlCastSpell(HK_E, self.MPos)
	else
		local p1, p2 = GoSuGeometry:CircleCircleIntersection(myHero.pos, target.pos, myHero.range, self.EData.range + 50)
		if p1 and p2 then
			local pos = GoSuGeometry:GetDistance(p1, self.MPos) > GoSuGeometry:GetDistance(p2, self.MPos) and p2 or p1
			ControlCastSpell(HK_E, myHero.pos:Extended(pos, MathMin(GoSuGeometry:GetDistance(myHero.pos, target.pos) / 3, self.EData.range)))
		else ControlCastSpell(HK_E, self.MPos) end
	end
	DelayAction(function() _G.SDK.Orbwalker:__OnAutoAttackReset() end, 0.05)
end

--[[
	┌─┐┬┬  ┬┬┬─┐
	└─┐│└┐┌┘│├┬┘
	└─┘┴ └┘ ┴┴└─
--]]

class "Sivir"

function Sivir:__init()
	self.DetectedMissiles = {}; self.DetectedSpells = {}; self.Target = nil; self.Timer = 0
	self.HeroIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/9/90/Sivir_OriginalSquare.png"
	self.QIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/b/bb/Boomerang_Blade.png"
	self.WIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/8/87/Ricochet.png"
	self.EIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/4/4a/Spell_Shield.png"
	self.RIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/5/50/On_the_Hunt.png"
	self.QData = SpellData[myHero.charName][0]
	self.SivirMenu = MenuElement({type = MENU, id = "Sivir", name = "[GoS-U] Sivir", leftIcon = self.HeroIcon})
	self.SivirMenu:MenuElement({id = "Auto", name = "Auto", type = MENU})
	self.SivirMenu.Auto:MenuElement({id = "UseQ", name = "Use Q [Boomerang Blade]", value = true, leftIcon = self.QIcon})
	self.SivirMenu.Auto:MenuElement({id = "MP", name = "Mana-Manager", value = 40, min = 0, max = 100, step = 5})
	self.SivirMenu:MenuElement({id = "Combo", name = "Combo", type = MENU})
	self.SivirMenu.Combo:MenuElement({id = "UseQ", name = "Use Q [Boomerang Blade]", value = true, leftIcon = self.QIcon})
	self.SivirMenu.Combo:MenuElement({id = "UseW", name = "Use W [Ricochet]", value = true, leftIcon = self.WIcon})
	self.SivirMenu.Combo:MenuElement({id = "UseR", name = "Use R [On The Hunt]", value = true, leftIcon = self.RIcon})
	self.SivirMenu.Combo:MenuElement({id = "Distance", name = "Distance: R", value = 1000, min = 500, max = 2000, step = 50})
	self.SivirMenu.Combo:MenuElement({id = "X", name = "Minimum Enemies: R", value = 1, min = 0, max = 5, step = 1})
	self.SivirMenu.Combo:MenuElement({id = "HP", name = "HP-Manager: R", value = 30, min = 0, max = 100, step = 5})
	self.SivirMenu:MenuElement({id = "Harass", name = "Harass", type = MENU})
	self.SivirMenu.Harass:MenuElement({id = "UseQ", name = "Use Q [Boomerang Blade]", value = true, leftIcon = self.QIcon})
	self.SivirMenu.Harass:MenuElement({id = "UseW", name = "Use W [Ricochet]", value = true, leftIcon = self.WIcon})
	self.SivirMenu.Harass:MenuElement({id = "MP", name = "Mana-Manager", value = 40, min = 0, max = 100, step = 5})
	self.SivirMenu:MenuElement({id = "ESet", name = "E Settings", type = MENU})
	self.SivirMenu.ESet:MenuElement({id = "UseE", name = "Use E [Spell Shield]", value = true, leftIcon = self.EIcon})
	self.SivirMenu.ESet:MenuElement({id = "BlockList", name = "Block List", type = MENU})
	self.SivirMenu:MenuElement({id = "LaneClear", name = "LaneClear", type = MENU})
	self.SivirMenu.LaneClear:MenuElement({id = "UseQ", name = "Use Q [Boomerang Blade]", value = false, leftIcon = self.QIcon})
	self.SivirMenu.LaneClear:MenuElement({id = "MMH", name = "Minimum Minions To Hit", value = 5, min = 1, max = 10, step = 1})
	self.SivirMenu.LaneClear:MenuElement({id = "MP", name = "Mana-Manager", value = 70, min = 0, max = 100, step = 5})
	self.SivirMenu:MenuElement({id = "HitChance", name = "HitChance", type = MENU})
	self.SivirMenu.HitChance:MenuElement({id = "HCQ", name = "HitChance: Q", value = 50, min = 0, max = 100, step = 1})
	self.SivirMenu:MenuElement({id = "Drawings", name = "Drawings", type = MENU})
	self.SivirMenu.Drawings:MenuElement({id = "DrawQ", name = "Draw Q Range", value = true})
	self.SivirMenu.Drawings:MenuElement({id = "QRng", name = "Q Range Color", color = DrawColor(192, 0, 250, 154)})
	self.SivirMenu:MenuElement({id = "blank", name = "GoS-U Reborn v"..LuaVer.."", type = SPACE})
	self.SivirMenu:MenuElement({id = "blank", name = "Author: Ark223", type = SPACE})
	self.SivirMenu:MenuElement({id = "blank", name = "Credits: gamsteron", type = SPACE})
	self.Slot = {[_Q] = "Q", [_W] = "W", [_E] = "E", [_R] = "R"}
	DelayAction(function()
		for i, spell in pairs(CCSpells) do
			if not CCSpells[i] then return end
			for j, k in pairs(GoSuManager:GetEnemyHeroes()) do
				if spell.charName == k.charName and not self.SivirMenu.ESet.BlockList[i] then
					if not self.SivirMenu.ESet.BlockList[i] then self.SivirMenu.ESet.BlockList:MenuElement({id = "Dodge"..i, name = ""..spell.charName.." "..self.Slot[spell.slot].." | "..spell.displayName, value = true}) end
				end
			end
		end
	end, 0.01)
	OnDraws.Champion = function() self:Draw() end
	OnTicks.Champion = function() self:Tick() end
	_G.SDK.Orbwalker:OnPreAttack(function(...) self:OnPreAttack(...) end)
	_G.SDK.Orbwalker:OnPostAttackTick(function(...) self:OnPostAttackTick(...) end)
end

function Sivir:Tick()
	if _G.JustEvade and _G.JustEvade:Evading() then return end
	if ((_G.ExtLibEvade and _G.ExtLibEvade.Evading) or Game.IsChatOpen() or not myHero.alive) then return end
	self:Auto2()
	if GoSuManager:GetOrbwalkerMode() == "Clear" then self:LaneClear() end
	self.Range = myHero.range + myHero.boundingRadius * 2
	self.Target = Module.TargetSelector:GetTarget(self.QData.range, nil)
	if self.Target == nil then return end
	if GoSuManager:GetOrbwalkerMode() == "Combo" then Module.Utility:Tick(); self:Combo(self.Target)
	elseif GoSuManager:GetOrbwalkerMode() == "Harass" then self:Harass(self.Target)
	else self:Auto(self.Target) end
end

function Sivir:Draw()
	if self.SivirMenu.Drawings.DrawQ:Value() then DrawCircle(myHero.pos, self.QData.range, 1, self.SivirMenu.Drawings.QRng:Value()) end
end

function Sivir:OnPreAttack(args)
	if GoSuManager:GetOrbwalkerMode() == "Combo" or GoSuManager:GetOrbwalkerMode() == "Harass" then
		local target = Module.TargetSelector:GetTarget(self.Range, nil); args.Target = target
	end
end

function Sivir:OnPostAttackTick(args)
	if (self.SivirMenu.Combo.UseW:Value() and GoSuManager:GetOrbwalkerMode() == "Combo") or (GoSuManager:GetPercentMana(myHero) > self.SivirMenu.Harass.MP:Value() and self.SivirMenu.Harass.UseW:Value() and GoSuManager:GetOrbwalkerMode() == "Harass") then
		if GoSuManager:IsReady(_W) then ControlCastSpell(HK_W); DelayAction(function() _G.SDK.Orbwalker:__OnAutoAttackReset() end, 0.05) end
	end
end

function Sivir:Auto(target)
	if target == nil or myHero.attackData.state == 2 or GoSuManager:GetPercentMana(myHero) <= self.SivirMenu.Auto.MP:Value() then return end
	if self.SivirMenu.Auto.UseQ:Value() and GoSuManager:IsReady(_Q) and GoSuManager:ValidTarget(target, self.QData.range) and not GoSuManager:IsUnderTurret(myHero.pos) then
		self:UseQ(target)
	end
end

function Sivir:Auto2()
	if self.SivirMenu.ESet.UseE:Value() and GoSuManager:IsReady(_E) then
		self:OnProcessSpell()
		for i, spell in pairs(self.DetectedSpells) do
			self:UseE(i, spell)
		end
	end
end

function Sivir:Combo(target)
	if target == nil or myHero.attackData.state == 2 then return end
	if self.SivirMenu.Combo.UseQ:Value() and GoSuManager:IsReady(_Q) and GoSuManager:ValidTarget(target, self.QData.range) then
		self:UseQ(target)
	end
	if self.SivirMenu.Combo.UseR:Value() and GoSuManager:IsReady(_R) and GoSuManager:ValidTarget(target, self.SivirMenu.Combo.Distance:Value()) then
		local enemies, count = GoSuManager:GetHeroesAround(myHero.pos, self.SivirMenu.Combo.Distance:Value())
		if GoSuManager:GetPercentHP(target) < self.SivirMenu.Combo.HP:Value() and count >= self.SivirMenu.Combo.X:Value() then			
			ControlCastSpell(HK_R)
		end
	end
end

function Sivir:Harass(target)
	if target == nil or myHero.attackData.state == 2 or GoSuManager:GetPercentMana(myHero) <= self.SivirMenu.Harass.MP:Value() then return end
	if self.SivirMenu.Harass.UseQ:Value() and GoSuManager:IsReady(_Q) and GoSuManager:ValidTarget(target, self.QData.range) then
		self:UseQ(target)
	end
end

function Sivir:LaneClear(target)
	if GoSuManager:GetPercentMana(myHero) > self.SivirMenu.LaneClear.MP:Value() and self.SivirMenu.LaneClear.UseQ:Value() and GoSuManager:IsReady(_Q) then
		local minions, count = GoSuManager:GetMinionsAround(myHero.pos, self.QData.range)
		if count > 0 then
			local BestPos, MostHit = GoSuGeometry:GetBestLinearAOEPos(minions, self.QData.range, self.QData.radius)
			if BestPos and MostHit >= self.SivirMenu.LaneClear.MMH:Value() and GoSuGeometry:GetDistance(BestPos, myHero.pos) < self.QData.range then
				ControlCastSpell(HK_Q, BestPos)
			end
		end
	end
end

function Sivir:UseQ(target)
	local pred = _G.PremiumPrediction:GetPrediction(myHero, target, self.QData)
	if pred.CastPos and pred.HitChance >= (self.SivirMenu.HitChance.HCQ:Value() / 100) then ControlCastSpell(HK_Q, pred.CastPos) end
end

function Sivir:UseE(i, s)
	local startPos = s.startPos; local endPos = s.endPos; local travelTime = 0
	if s.speed == MathHuge then travelTime = s.delay else travelTime = s.range / s.speed + s.delay end
	if s.type == "rectangular" then
		local StartPosition = endPos-Vector(endPos-startPos):Normalized():Perpendicular()*(s.radius2 or 400)
		local EndPosition = endPos+Vector(endPos-startPos):Normalized():Perpendicular()*(s.radius2 or 400)
		startPos = StartPosition; endPos = EndPosition
	end
	if s.startTime + travelTime > GameTimer() then
		local Col = GoSuGeometry:VectorPointProjectionOnLineSegment(startPos, endPos, myHero.pos)
		if s.type == "circular" and GoSuGeometry:GetDistanceSqr(myHero.pos, endPos) < (s.radius + myHero.boundingRadius) ^ 2 or GoSuGeometry:GetDistanceSqr(myHero.pos, Col) < (s.radius + myHero.boundingRadius * 1.25) ^ 2 then
			local t = s.speed ~= MathHuge and GoSuGeometry:CalculateCollisionTime(startPos, endPos, myHero.pos, s.startTime, s.speed, s.delay) or 0.29
			if t < 0.3 then ControlCastSpell(HK_E) end
		end
	else TableRemove(self.DetectedSpells, i) end
end

function Sivir:OnProcessSpell()
	local unit, spell = OnProcessSpell()
	if unit and spell and CCSpells[spell.name] then
		if GoSuGeometry:GetDistance(unit.pos, myHero.pos) > 3000 or not self.SivirMenu.ESet.BlockList["Dodge"..spell.name]:Value() then return end
		local Detected = CCSpells[spell.name]
		local type = Detected.type
		if type == "targeted" then
			if spell.target == myHero.handle then ControlCastSpell(HK_E) end
		else
			local startPos = Vector(spell.startPos); local placementPos = Vector(spell.placementPos); local unitPos = unit.pos
			local radius = Detected.radius; local range = Detected.range; local col = Detected.collision; local type = Detected.type
			local endPos, range2 = GoSuGeometry:CalculateEndPos(startPos, placementPos, unitPos, range, radius, col, type)
			TableInsert(self.DetectedSpells, {startPos = startPos, endPos = endPos, startTime = GameTimer(), speed = Detected.speed, range = range2, delay = Detected.delay, radius = radius, radius2 = radius2 or nil, angle = angle or nil, type = type, collision = col})
		end
	end
end

--[[
	┌┬┐┬─┐┬┌─┐┌┬┐┌─┐┌┐┌┌─┐
	 │ ├┬┘│└─┐ │ ├─┤│││├─┤
	 ┴ ┴└─┴└─┘ ┴ ┴ ┴┘└┘┴ ┴
--]]

class "Tristana"

function Tristana:__init()
	self.Target = nil
	self.HeroIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/0/08/Tristana_OriginalSquare.png"
	self.QIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/4/4b/Rapid_Fire.png"
	self.EIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/1/1d/Explosive_Charge.png"
	self.RIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/f/f3/Buster_Shot.png"
	self.WData = SpellData[myHero.charName][1]; self.EData = SpellData[myHero.charName][2]; self.RData = SpellData[myHero.charName][3]
	self.TristanaMenu = MenuElement({type = MENU, id = "Tristana", name = "[GoS-U] Tristana", leftIcon = self.HeroIcon})
	self.TristanaMenu:MenuElement({id = "Combo", name = "Combo", type = MENU})
	self.TristanaMenu.Combo:MenuElement({id = "UseQ", name = "Use Q [Rapid Fire]", value = true, leftIcon = self.QIcon})
	self.TristanaMenu.Combo:MenuElement({id = "UseE", name = "Use E [Explosive Charge]", value = true, leftIcon = self.EIcon})
	self.TristanaMenu:MenuElement({id = "Harass", name = "Harass", type = MENU})
	self.TristanaMenu.Harass:MenuElement({id = "UseQ", name = "Use Q [Rapid Fire]", value = true, leftIcon = self.QIcon})
	self.TristanaMenu.Harass:MenuElement({id = "UseE", name = "Use E [Explosive Charge]", value = true, leftIcon = self.EIcon})
	self.TristanaMenu.Harass:MenuElement({id = "MP", name = "Mana-Manager", value = 40, min = 0, max = 100, step = 5})
	self.TristanaMenu:MenuElement({id = "KillSteal", name = "KillSteal", type = MENU})
	self.TristanaMenu.KillSteal:MenuElement({id = "UseR", name = "Use R [Buster Shot]", value = true, leftIcon = self.RIcon})
	self.TristanaMenu:MenuElement({id = "AntiGapcloser", name = "Anti-Gapcloser", type = MENU})
	self.TristanaMenu.AntiGapcloser:MenuElement({id = "UseR", name = "Use R [Buster Shot]", value = true, leftIcon = self.RIcon})
	self.TristanaMenu.AntiGapcloser:MenuElement({id = "Distance", name = "Distance: E", value = 50, min = 25, max = 500, step = 25})
	self.TristanaMenu:MenuElement({id = "Interrupter", name = "Interrupter", type = MENU})
	self.TristanaMenu.Interrupter:MenuElement({id = "UseRDash", name = "Use R On Dashing Spells", value = false, leftIcon = self.EIcon})
	self.TristanaMenu.Interrupter:MenuElement({id = "UseRChan", name = "Use R On Channeling Spells", value = true, leftIcon = self.RIcon})
	self.TristanaMenu.Interrupter:MenuElement({id = "CSpells", name = "Channeling Spells", type = MENU})
	self.TristanaMenu.Interrupter:MenuElement({id = "Distance", name = "Distance: R", value = self.RData.range, min = 100, max = 660, step = 25})
	self.TristanaMenu.Interrupter:MenuElement({id = "Dng", name = "Minimum Danger Level To Cast", value = 3, min = 1, max = 3, step = 1})
	self.TristanaMenu:MenuElement({id = "Drawings", name = "Drawings", type = MENU})
	self.TristanaMenu.Drawings:MenuElement({id = "DrawW", name = "Draw W Range", value = true})
	self.TristanaMenu.Drawings:MenuElement({id = "DrawE", name = "Draw E Range", value = true})
	self.TristanaMenu.Drawings:MenuElement({id = "DrawR", name = "Draw R Range", value = true})
	self.TristanaMenu.Drawings:MenuElement({id = "WRng", name = "W Range Color", color = DrawColor(192, 218, 112, 214)})
	self.TristanaMenu.Drawings:MenuElement({id = "ERng", name = "E Range Color", color = DrawColor(192, 255, 140, 0)})
	self.TristanaMenu.Drawings:MenuElement({id = "RRng", name = "R Range Color", color = DrawColor(192, 220, 20, 60)})
	self.TristanaMenu:MenuElement({id = "blank", name = "GoS-U Reborn v"..LuaVer.."", type = SPACE})
	self.TristanaMenu:MenuElement({id = "blank", name = "Author: Ark223", type = SPACE})
	self.TristanaMenu:MenuElement({id = "blank", name = "Credits: gamsteron", type = SPACE})
	self.Slot = {[_Q] = "Q", [_W] = "W", [_E] = "E", [_R] = "R"}
	DelayAction(function()
		for i, spell in pairs(ChanellingSpells) do
			for j, hero in pairs(GoSuManager:GetEnemyHeroes()) do
				if not ChanellingSpells[i] then return end
				if spell.charName == hero.charName then
					if not self.TristanaMenu.Interrupter.CSpells[i] then self.TristanaMenu.Interrupter.CSpells:MenuElement({id = i, name = ""..spell.charName.." "..self.Slot[spell.slot].." | "..spell.displayName, type = MENU}) end
					self.TristanaMenu.Interrupter.CSpells[i]:MenuElement({id = "Detect"..i, name = "Detect Spell", value = true})
					self.TristanaMenu.Interrupter.CSpells[i]:MenuElement({id = "Danger"..i, name = "Danger Level", value = (spell.danger or 1), min = 1, max = 3, step = 1})
				end
			end
		end
	end, 0.1)
	OnDraws.Champion = function() self:Draw() end
	OnTicks.Champion = function() self:Tick() end
	_G.SDK.Orbwalker:OnPreAttack(function(...) self:OnPreAttack(...) end)
	_G.SDK.Orbwalker:OnPostAttackTick(function(...) self:OnPostAttackTick(...) end)
end

function Tristana:Tick()
	if _G.JustEvade and _G.JustEvade:Evading() then return end
	if ((_G.ExtLibEvade and _G.ExtLibEvade.Evading) or Game.IsChatOpen() or not myHero.alive) then return end
	self:Auto2()
	self.Range = myHero.range + myHero.boundingRadius * 2
	self.ERange = self:GetSpellRange(_E); self.RRange = self:GetSpellRange(_R)
	self.Target = Module.TargetSelector:GetTarget(self.ERange, nil)
end

function Tristana:Draw()
	if self.TristanaMenu.Drawings.DrawW:Value() then DrawCircle(myHero.pos, self.WData.range, 1, self.TristanaMenu.Drawings.WRng:Value()) end
	if self.TristanaMenu.Drawings.DrawE:Value() then DrawCircle(myHero.pos, self.ERange or self.EData.range, 1, self.TristanaMenu.Drawings.ERng:Value()) end
	if self.TristanaMenu.Drawings.DrawR:Value() then DrawCircle(myHero.pos, self.RRange or self.RData.range, 1, self.TristanaMenu.Drawings.RRng:Value()) end
end

function Tristana:OnPreAttack(args)
	if GoSuManager:IsReady(_Q) and ((self.TristanaMenu.Combo.UseQ:Value() and GoSuManager:GetOrbwalkerMode() == "Combo") or (GoSuManager:GetPercentMana(myHero) > self.TristanaMenu.Harass.MP:Value() and self.TristanaMenu.Harass.UseQ:Value() and GoSuManager:GetOrbwalkerMode() == "Harass")) then
		local target = Module.TargetSelector:GetTarget(self.Range, nil); args.Target = target; ControlCastSpell(HK_Q)
	end
end

function Tristana:OnPostAttackTick(args)
	if _G.JustEvade and _G.JustEvade:Evading() or (_G.ExtLibEvade and _G.ExtLibEvade.Evading) then return end
	if (self.TristanaMenu.Combo.UseE:Value() and GoSuManager:GetOrbwalkerMode() == "Combo") or (GoSuManager:GetPercentMana(myHero) > self.TristanaMenu.Harass.MP:Value() and self.TristanaMenu.Harass.UseE:Value() and GoSuManager:GetOrbwalkerMode() == "Harass") then
		if self.Target and GoSuManager:IsReady(_E) and GoSuManager:ValidTarget(self.Target, self.ERange) then
			ControlCastSpell(HK_E, self.Target.pos)
		end
	end
end

function Tristana:Auto2()
	for i, enemy in pairs(GoSuManager:GetEnemyHeroes()) do
		if GoSuManager:IsReady(_R) then
			if self.TristanaMenu.AntiGapcloser.UseR:Value() and GoSuManager:ValidTarget(enemy, self.TristanaMenu.AntiGapcloser.Distance:Value()) then
				ControlCastSpell(HK_R, enemy.pos)
			end
			if self.TristanaMenu.KillSteal.UseR:Value() and GoSuManager:ValidTarget(enemy, self.RRange) then
				local RDmg = GoSuManager:GetDamage(enemy, 3, 0) * 9 / 10
				if RDmg > enemy.health then
					ControlCastSpell(HK_R, enemy.pos)
				end
			end
			if GoSuManager:ValidTarget(enemy, self.TristanaMenu.Interrupter.Distance:Value()) then
				if self.TristanaMenu.Interrupter.UseRChan:Value() then
					local spell = enemy.activeSpell
					if spell and spell.valid and spell.isChanneling then
						if ChanellingSpells[spell.name] and self.TristanaMenu.Interrupter.CSpells[spell.name] and self.TristanaMenu.Interrupter.CSpells[spell.name]["Detect"..spell.name]:Value() then
							if self.TristanaMenu.Interrupter.CSpells[spell.name]["Danger"..spell.name]:Value() >= self.TristanaMenu.Interrupter.Dng:Value() then
								ControlCastSpell(HK_R, enemy.pos)
							end
						end
					end
				end
				if self.TristanaMenu.Interrupter.UseRDash:Value() then
					if enemy.pathing.isDashing and enemy.pathing.dashSpeed > 500 then
						if GoSuGeometry:GetDistance(enemy.pos, myHero.pos) > GoSuGeometry:GetDistance(Vector(enemy.pathing.endPos), myHero.pos) then
							ControlCastSpell(HK_R, enemy.pos)
						end
					end
				end
			end
		end
	end
end

function Tristana:GetSpellRange(slot)
	return (slot == _E and 525 + 8 * myHero.levelData.lvl or 525 + (8 * (myHero.levelData.lvl - 1)))
end

--[[
	┌┬┐┬ ┬┬┌┬┐┌─┐┬ ┬
	 │ ││││ │ │  ├─┤
	 ┴ └┴┘┴ ┴ └─┘┴ ┴
 --]]

class "Twitch"

function Twitch:__init()
	self.Target = nil; self.VenomData = {}
	self.HeroIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/f/fb/Twitch_OriginalSquare.png"
	self.WIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/f/f6/Venom_Cask.png"
	self.EIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/5/5f/Contaminate.png"
	self.WData = SpellData[myHero.charName][1]; self.EData = SpellData[myHero.charName][2]
	self.TwitchMenu = MenuElement({type = MENU, id = "Twitch", name = "[GoS-U] Twitch", leftIcon = self.HeroIcon})
	self.TwitchMenu:MenuElement({id = "Combo", name = "Combo", type = MENU})
	self.TwitchMenu.Combo:MenuElement({id = "UseW", name = "Use W [Venom Cask]", value = true, leftIcon = self.WIcon})
	self.TwitchMenu:MenuElement({id = "Harass", name = "Harass", type = MENU})
	self.TwitchMenu.Harass:MenuElement({id = "UseW", name = "Use W [Venom Cask]", value = true, leftIcon = self.WIcon})
	self.TwitchMenu.Harass:MenuElement({id = "MP", name = "Mana-Manager", value = 40, min = 0, max = 100, step = 5})
	self.TwitchMenu:MenuElement({id = "KillSteal", name = "KillSteal", type = MENU})
	self.TwitchMenu.KillSteal:MenuElement({id = "UseE", name = "Use E [Contaminate]", value = true, leftIcon = self.EIcon})
	self.TwitchMenu.KillSteal:MenuElement({id = "DCR", name = "Damage Calc Ratio", value = 0.95, min = 0.01, max = 1, step = 0.01})
	self.TwitchMenu:MenuElement({id = "HitChance", name = "HitChance", type = MENU})
	self.TwitchMenu.HitChance:MenuElement({id = "HCW", name = "HitChance: W", value = 40, min = 0, max = 100, step = 1})
	self.TwitchMenu:MenuElement({id = "Drawings", name = "Drawings", type = MENU})
	self.TwitchMenu.Drawings:MenuElement({id = "DrawW", name = "Draw W Range", value = true})
	self.TwitchMenu.Drawings:MenuElement({id = "DrawE", name = "Draw E Range", value = true})
	self.TwitchMenu.Drawings:MenuElement({id = "DrawR", name = "Draw R Range", value = true})
	self.TwitchMenu.Drawings:MenuElement({id = "WRng", name = "W Range Color", color = DrawColor(192, 218, 112, 214)})
	self.TwitchMenu.Drawings:MenuElement({id = "ERng", name = "E Range Color", color = DrawColor(192, 255, 140, 0)})
	self.TwitchMenu.Drawings:MenuElement({id = "RRng", name = "R Range Color", color = DrawColor(192, 220, 20, 60)})
	self.TwitchMenu:MenuElement({id = "blank", name = "GoS-U Reborn v"..LuaVer.."", type = SPACE})
	self.TwitchMenu:MenuElement({id = "blank", name = "Author: Ark223", type = SPACE})
	self.TwitchMenu:MenuElement({id = "blank", name = "Credits: gamsteron", type = SPACE})
	self.Slot = {[_Q] = "Q", [_W] = "W", [_E] = "E", [_R] = "R"}
	OnDraws.Champion = function() self:Draw() end
	OnTicks.Champion = function() self:Tick() end
	_G.SDK.Orbwalker:OnPreAttack(function(...) self:OnPreAttack(...) end)
end

function Twitch:Tick()
	if _G.JustEvade and _G.JustEvade:Evading() then return end
	if ((_G.ExtLibEvade and _G.ExtLibEvade.Evading) or Game.IsChatOpen() or not myHero.alive) then return end
	self:Auto2()
	self.Range = myHero.range + myHero.boundingRadius * 2
	self.Target = Module.TargetSelector:GetTarget(self.EData.range, nil)
	if self.Target == nil then return end
	if GoSuManager:GetOrbwalkerMode() == "Combo" then Module.Utility:Tick(); self:Combo(self.Target)
	elseif GoSuManager:GetOrbwalkerMode() == "Harass" then self:Harass(self.Target) end
end

function Twitch:Draw()
	if self.TwitchMenu.Drawings.DrawW:Value() then DrawCircle(myHero.pos, self.WData.range, 1, self.TwitchMenu.Drawings.WRng:Value()) end
	if self.TwitchMenu.Drawings.DrawE:Value() then DrawCircle(myHero.pos, self.EData.range, 1, self.TwitchMenu.Drawings.ERng:Value()) end
	if self.TwitchMenu.Drawings.DrawR:Value() then DrawCircle(myHero.pos, self:GetUltRange(), 1, self.TwitchMenu.Drawings.RRng:Value()) end
end

function Twitch:OnPreAttack(args)
	if (GoSuManager:GetOrbwalkerMode() == "Combo" or GoSuManager:GetOrbwalkerMode() == "Harass") then
		args.Target = Module.TargetSelector:GetTarget(self.Range, nil)
	end
end

function Twitch:Auto2()
	for i, enemy in pairs(GoSuManager:GetEnemyHeroes()) do
		if self.TwitchMenu.KillSteal.UseE:Value() and GoSuManager:ValidTarget(enemy, self.EData.range) then
			local NID = enemy.networkID
			if self.VenomData[NID] == nil then self.VenomData[NID] = {timer = 0, stacks = 0} end
			local stacks = self:GetEStacks(enemy)
			if GoSuManager:IsReady(_E) and stacks > 0 then
				local EDmg = GoSuManager:CalcPhysicalDamage(myHero, enemy, ((({20, 30, 40, 50, 60})[GoSuManager:GetCastLevel(myHero, _E)]) + (stacks * (({15, 20, 25, 30, 35})[GoSuManager:GetCastLevel(myHero, _E)] + 0.35 * myHero.bonusDamage + 0.2 * myHero.ap)))) * self.TwitchMenu.KillSteal.DCR:Value()
				if EDmg > enemy.health then ControlCastSpell(HK_E) end
			end
		end
	end
end

function Twitch:Combo(target)
	if target == nil or myHero.attackData.state == 2 then return end
	if self.TwitchMenu.Combo.UseW:Value() and GoSuManager:IsReady(_W) and GoSuManager:ValidTarget(target, self.WData.range) then
		self:UseW(target)
	end
end

function Twitch:Harass(target)
	if target == nil or myHero.attackData.state == 2 or GoSuManager:GetPercentMana(myHero) <= self.TwitchMenu.Harass.MP:Value() then return end
	if self.TwitchMenu.Harass.UseW:Value() and GoSuManager:IsReady(_W) and GoSuManager:ValidTarget(target, self.WData.range) then
		self:UseW(target)
	end
end

function Twitch:GetEStacks(unit)
	local id = unit.networkID
	for i = 0, unit.buffCount do
		local buff = unit:GetBuff(i)
		if buff and buff.name == "TwitchDeadlyVenom" and buff.count > 0 and GameTimer() < buff.expireTime then
			if buff.expireTime > self.VenomData[id].timer and self.VenomData[id].stacks < 6 then
				self.VenomData[id].stacks = self.VenomData[id].stacks + 1
			end
			self.VenomData[id].timer = buff.expireTime
			return self.VenomData[id].stacks
		end
	end
	self.VenomData[id].stacks = 0
	return 0
end

function Twitch:GetUltRange()
	return self.Range and self.Range + 300 or 680
end

function Twitch:UseW(target)
	local pred = _G.PremiumPrediction:GetPrediction(myHero, target, self.WData)
	if pred.CastPos and pred.HitChance >= (self.TwitchMenu.HitChance.HCW:Value() / 100) then ControlCastSpell(HK_W, pred.PredPos) end
end

--[[
	┬  ┬┌─┐┬ ┬┌┐┌┌─┐
	└┐┌┘├─┤└┬┘│││├┤ 
	 └┘ ┴ ┴ ┴ ┘└┘└─┘
--]]

class "Vayne"

function Vayne:__init()
	self.Target = nil; self.Timer = GameTimer()
	self.HeroIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/0/05/Vayne_OriginalSquare.png"
	self.QIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/8/8d/Tumble.png"
	self.EIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/6/66/Condemn.png"
	self.RIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/b/b4/Final_Hour.png"
	self.QData = SpellData[myHero.charName][0]; self.EData = SpellData[myHero.charName][2]
	self.VayneMenu = MenuElement({type = MENU, id = "Vayne", name = "[GoS-U] Vayne", leftIcon = self.HeroIcon})
	self.VayneMenu:MenuElement({id = "Auto", name = "Auto", type = MENU})
	self.VayneMenu.Auto:MenuElement({id = "UseE", name = "Use E [Condemn]", value = true, leftIcon = self.EIcon})
	self.VayneMenu.Auto:MenuElement({id = "MP", name = "Mana-Manager", value = 40, min = 0, max = 100, step = 5})
	self.VayneMenu:MenuElement({id = "Combo", name = "Combo", type = MENU})
	self.VayneMenu.Combo:MenuElement({id = "UseQ", name = "Use Q [Tumble]", value = true, leftIcon = self.QIcon})
	self.VayneMenu.Combo:MenuElement({id = "UseE", name = "Use E [Condemn]", value = true, leftIcon = self.EIcon})
	self.VayneMenu.Combo:MenuElement({id = "UseR", name = "Use R [Final Hour]", value = true, leftIcon = self.RIcon})
	self.VayneMenu.Combo:MenuElement({id = "ModeQ", name = "Cast Mode: Q", drop = {"Mouse", "Smart"}, value = 2})
	self.VayneMenu.Combo:MenuElement({id = "Distance", name = "Distance: R", value = 1000, min = 100, max = 2000, step = 50})
	self.VayneMenu.Combo:MenuElement({id = "X", name = "Minimum Enemies: R", value = 1, min = 0, max = 5, step = 1})
	self.VayneMenu.Combo:MenuElement({id = "HP", name = "HP-Manager: R", value = 40, min = 0, max = 100, step = 5})
	self.VayneMenu:MenuElement({id = "Harass", name = "Harass", type = MENU})
	self.VayneMenu.Harass:MenuElement({id = "UseQ", name = "Use Q [Tumble]", value = true, leftIcon = self.QIcon})
	self.VayneMenu.Harass:MenuElement({id = "UseE", name = "Use E [Condemn]", value = true, leftIcon = self.EIcon})
	self.VayneMenu.Harass:MenuElement({id = "ModeQ", name = "Cast Mode: Q", drop = {"Mouse", "Smart"}, value = 1})
	self.VayneMenu:MenuElement({id = "KillSteal", name = "KillSteal", type = MENU})
	self.VayneMenu.KillSteal:MenuElement({id = "UseE", name = "Use E [Condemn]", value = true, leftIcon = self.EIcon})
	self.VayneMenu:MenuElement({id = "AntiGapcloser", name = "Anti-Gapcloser", type = MENU})
	self.VayneMenu.AntiGapcloser:MenuElement({id = "UseE", name = "Use E [Condemn]", value = true, leftIcon = self.EIcon})
	self.VayneMenu.AntiGapcloser:MenuElement({id = "Distance", name = "Distance: E", value = 75, min = 25, max = 500, step = 25})
	self.VayneMenu:MenuElement({id = "Interrupter", name = "Interrupter", type = MENU})
	self.VayneMenu.Interrupter:MenuElement({id = "UseEDash", name = "Use E On Dashing Spells", value = false, leftIcon = self.EIcon})
	self.VayneMenu.Interrupter:MenuElement({id = "UseEChan", name = "Use E On Channeling Spells", value = true, leftIcon = self.EIcon})
	self.VayneMenu.Interrupter:MenuElement({id = "CSpells", name = "Channeling Spells", type = MENU})
	self.VayneMenu.Interrupter:MenuElement({id = "Distance", name = "Distance: E", value = self.EData.range2, min = 100, max = self.EData.range2, step = 50})
	self.VayneMenu.Interrupter:MenuElement({id = "Dng", name = "Minimum Danger Level To Cast", value = 3, min = 1, max = 3, step = 1})
	self.VayneMenu:MenuElement({id = "HitChance", name = "HitChance", type = MENU})
	self.VayneMenu.HitChance:MenuElement({id = "HCE", name = "HitChance: E", value = 10, min = 0, max = 100, step = 1})
	self.VayneMenu:MenuElement({id = "Drawings", name = "Drawings", type = MENU})
	self.VayneMenu.Drawings:MenuElement({id = "DrawQ", name = "Draw Q Range", value = true})
	self.VayneMenu.Drawings:MenuElement({id = "DrawE", name = "Draw E Range", value = true})
	self.VayneMenu.Drawings:MenuElement({id = "QRng", name = "Q Range Color", color = DrawColor(192, 0, 250, 154)})
	self.VayneMenu.Drawings:MenuElement({id = "ERng", name = "E Range Color", color = DrawColor(192, 255, 140, 0)})
	self.VayneMenu:MenuElement({id = "Misc", name = "Misc", type = MENU})
	self.VayneMenu.Misc:MenuElement({id = "BlockAA", name = "Block AA While Stealthed", value = false})
	self.VayneMenu.Misc:MenuElement({id = "PD", name = "Push Distance: E", value = 450, min = 100, max = 475, step = 5})
	self.VayneMenu:MenuElement({id = "blank", name = "GoS-U Reborn v"..LuaVer.."", type = SPACE})
	self.VayneMenu:MenuElement({id = "blank", name = "Author: Ark223", type = SPACE})
	self.VayneMenu:MenuElement({id = "blank", name = "Credits: gamsteron", type = SPACE})
	self.Slot = {[_Q] = "Q", [_W] = "W", [_E] = "E", [_R] = "R"}
	DelayAction(function()
		for i, spell in pairs(ChanellingSpells) do
			for j, hero in pairs(GoSuManager:GetEnemyHeroes()) do
				if not ChanellingSpells[i] then return end
				if spell.charName == hero.charName then
					if not self.VayneMenu.Interrupter.CSpells[i] then self.VayneMenu.Interrupter.CSpells:MenuElement({id = i, name = ""..spell.charName.." "..self.Slot[spell.slot].." | "..spell.displayName, type = MENU}) end
					self.VayneMenu.Interrupter.CSpells[i]:MenuElement({id = "Detect"..i, name = "Detect Spell", value = true})
					self.VayneMenu.Interrupter.CSpells[i]:MenuElement({id = "Danger"..i, name = "Danger Level", value = (spell.danger or 1), min = 1, max = 3, step = 1})
				end
			end
		end
	end, 0.1)
	OnDraws.Champion = function() self:Draw() end
	OnTicks.Champion = function() self:Tick() end
	_G.SDK.Orbwalker:OnPreAttack(function(...) self:OnPreAttack(...) end)
	_G.SDK.Orbwalker:OnPostAttackTick(function(...) self:OnPostAttackTick(...) end)
end

function Vayne:Tick()
	if _G.JustEvade and _G.JustEvade:Evading() then return end
	if ((_G.ExtLibEvade and _G.ExtLibEvade.Evading) or Game.IsChatOpen() or not myHero.alive) then return end
	if GameTimer() > self.Timer + 1 and GoSuManager:GotBuff(myHero, "vaynetumblebonus") > 0 then
		_G.SDK.Orbwalker:__OnAutoAttackReset(); self.Timer = GameTimer()
	end
	self:Auto2()
	self.Range = myHero.range + myHero.boundingRadius * 2
	self.Target = Module.TargetSelector:GetTarget(self.Range + self.QData.range, nil)
	if self.Target == nil then return end
	if GoSuManager:GetOrbwalkerMode() == "Combo" then Module.Utility:Tick(); self:Combo(self.Target)
	elseif GoSuManager:GetOrbwalkerMode() == "Harass" then self:Harass(self.Target)
	else self:Auto(self.Target) end
end

function Vayne:Draw()
	if self.VayneMenu.Drawings.DrawQ:Value() then DrawCircle(myHero.pos, self.QData.range, 1, self.VayneMenu.Drawings.QRng:Value()) end
	if self.VayneMenu.Drawings.DrawE:Value() then DrawCircle(myHero.pos, self.EData.range2, 1, self.VayneMenu.Drawings.ERng:Value()) end
end

function Vayne:OnPreAttack(args)
	if GoSuManager:GetOrbwalkerMode() == "Combo" or GoSuManager:GetOrbwalkerMode() == "Harass" then
		local target = Module.TargetSelector:GetTarget(self.Range, nil); args.Target = target
	end
end

function Vayne:OnPostAttackTick(args)
	if _G.JustEvade and _G.JustEvade:Evading() or (_G.ExtLibEvade and _G.ExtLibEvade.Evading) then return end
	if (self.VayneMenu.Combo.UseQ:Value() and GoSuManager:GetOrbwalkerMode() == "Combo") or (self.VayneMenu.Harass.UseQ:Value() and GoSuManager:GetOrbwalkerMode() == "Harass") then
		if self.Target and GoSuManager:IsReady(_Q) and GoSuManager:ValidTarget(self.Target, self.Range) then
			self:UseQ(self.Target, GoSuManager:GetOrbwalkerMode() == "Combo" and self.VayneMenu.Combo.ModeQ:Value() or self.VayneMenu.Harass.ModeQ:Value())
		end
	end
end

function Vayne:Auto(target)
	if target == nil or myHero.attackData.state == 2 then return end
	if self.VayneMenu.Auto.UseE:Value() then
		if GoSuManager:GetPercentMana(myHero) > self.VayneMenu.Auto.MP:Value() and GoSuManager:IsReady(_E) and GoSuManager:ValidTarget(target, self.EData.range2) then
			if self:IsOnLineToStun(target) and not GoSuManager:IsUnderTurret(myHero.pos) then ControlCastSpell(HK_E, target.pos) end
		end
	end
end

function Vayne:Auto2()
	for i, enemy in pairs(GoSuManager:GetEnemyHeroes()) do
		if GoSuManager:IsReady(_R) then
			if self.VayneMenu.AntiGapcloser.UseE:Value() and GoSuManager:ValidTarget(enemy, self.VayneMenu.AntiGapcloser.Distance:Value()) then
				ControlCastSpell(HK_E, enemy.pos)
			end
			if self.VayneMenu.KillSteal.UseE:Value() and GoSuManager:ValidTarget(enemy, self.EData.range2) then
				local EDmg = GoSuManager:GetDamage(enemy, 2, 0) * 2 / 3
				if EDmg > enemy.health then
					ControlCastSpell(HK_E, enemy.pos)
				end
			end
			if GoSuManager:ValidTarget(enemy, self.VayneMenu.Interrupter.Distance:Value()) then
				if self.VayneMenu.Interrupter.UseEChan:Value() then
					local spell = enemy.activeSpell
					if spell and spell.valid and spell.isChanneling then
						if ChanellingSpells[spell.name] and self.VayneMenu.Interrupter.CSpells[spell.name] and self.VayneMenu.Interrupter.CSpells[spell.name]["Detect"..spell.name]:Value() then
							if self.VayneMenu.Interrupter.CSpells[spell.name]["Danger"..spell.name]:Value() >= self.VayneMenu.Interrupter.Dng:Value() then
								ControlCastSpell(HK_E, enemy.pos)
							end
						end
					end
				end
				if self.VayneMenu.Interrupter.UseEDash:Value() then
					if enemy.pathing.isDashing and enemy.pathing.dashSpeed > 400 then
						if GoSuGeometry:GetDistance(enemy.pos, myHero.pos) > GoSuGeometry:GetDistance(Vector(enemy.pathing.endPos), myHero.pos) then
							ControlCastSpell(HK_E, enemy.pos)
						end
					end
				end
			end
		end
	end
	if self.VayneMenu.Misc.BlockAA:Value() then
		if GoSuManager:GotBuff(myHero, "vaynetumblefade") == 0 then _G.SDK.Orbwalker:SetAttack(true)
		else _G.SDK.Orbwalker:SetAttack(false) end
	end
end

function Vayne:Combo(target)
	if target == nil or myHero.attackData.state == 2 then return end
	if self.VayneMenu.Combo.UseE:Value() and GoSuManager:IsReady(_E) and GoSuManager:ValidTarget(target, self.EData.range2) then
		if self:IsOnLineToStun(target) then ControlCastSpell(HK_E, target.pos) end
	end
	if self.VayneMenu.Combo.UseQ:Value() and GoSuManager:IsReady(_Q) and GoSuManager:ValidTarget(target, self.Range + self.QData.range) and GoSuGeometry:GetDistance(target.pos, myHero.pos) > (myHero.range + myHero.boundingRadius) then
		self:UseQ(target, self.VayneMenu.Combo.ModeQ:Value())
	end
	if self.VayneMenu.Combo.UseR:Value() and GoSuManager:IsReady(_R) and GoSuManager:ValidTarget(target, self.VayneMenu.Combo.Distance:Value()) then
		local enemies, count = GoSuManager:GetHeroesAround(myHero.pos, self.VayneMenu.Combo.Distance:Value())
		if GoSuManager:GetPercentHP(target) < self.VayneMenu.Combo.HP:Value() and count >= self.VayneMenu.Combo.X:Value() then			
			ControlCastSpell(HK_R)
		end
	end
end

function Vayne:Harass(target)
	if target == nil or myHero.attackData.state == 2 then return end
	if self.VayneMenu.Harass.UseE:Value() and GoSuManager:IsReady(_E) and GoSuManager:ValidTarget(target, self.EData.range2) then
		if self:IsOnLineToStun(target) then ControlCastSpell(HK_E, target.pos) end
	end
	if self.VayneMenu.Harass.UseQ:Value() and GoSuManager:IsReady(_Q) and GoSuManager:ValidTarget(target, self.Range + self.QData.range) and GoSuGeometry:GetDistance(target.pos, myHero.pos) > (myHero.range + myHero.boundingRadius) then
		self:UseQ(target, self.VayneMenu.Harass.ModeQ:Value())
	end
end

function Vayne:UseQ(target, mode)
	local MPos = myHero.pos:Extended(mousePos, 300); local QPos = MPos
	if mode == 2 and GoSuManager:IsReady(_E) then
		local Pos = nil
		for i = 20, 360, 20 do
			Pos = GoSuGeometry:RotateVector2D(myHero.pos, MPos, MathRad(i))
			if GoSuGeometry:GetDistance(Pos, target.pos) < self.EData.range2 and self:IsOnLineToStun(target) and not GoSuManager:IsUnderTurret(Pos) then QPos = Pos; break end
		end
	end
	ControlCastSpell(HK_Q, QPos)
end

function Vayne:IsOnLineToStun(target)
	self.EData.range, self.EData.radius = GoSuGeometry:GetDistance(myHero.pos, target.pos), target.boundingRadius
	local pred = _G.PremiumPrediction:GetPrediction(myHero, target, self.EData)
	if pred.PredPos and pred.HitChance >= (self.VayneMenu.HitChance.HCE:Value() / 100) then
		local Col = pred.PredPos:Extended(myHero.pos, -self.VayneMenu.Misc.PD:Value())
		local Line = LineSegment(pred.PredPos, Col)
		return MapPosition:intersectsWall(Line) or MapPosition:inWall(Col)
	end
	return false
end

--
--
--

Callback.Add("Draw", function()
	if OnDraws.Awareness then OnDraws.Awareness() end
	if OnDraws.BaseUlt then OnDraws.BaseUlt() end
	if OnDraws.Champion then OnDraws.Champion() end
	if OnDraws.TargetSelector then OnDraws.TargetSelector() end
end)

Callback.Add("ProcessRecall", function(unit, recall)
	if OnRecalls.Awareness then OnRecalls.Awareness(unit, recall) end
	if OnRecalls.BaseUlt then OnRecalls.BaseUlt(unit, recall) end
end)

Callback.Add("Tick", function()
	if OnTicks.Champion then OnTicks.Champion() end
end)
