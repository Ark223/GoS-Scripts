
--[[
	 _______                           _                         ___         __                        __  __                   
	|_   __ \                         (_)                      .'   `.      [  |                      [  |[  |  _               
	  | |__) _ .--. .---. _ .--..--.  __ __   _  _ .--..--.   /  .-.  \_ .--.| |.--.  _   _   __ ,--.  | | | | / ].---. _ .--.  
	  |  ___[ `/'`\/ /__\[ `.-. .-. |[  [  | | |[ `.-. .-. |  | |   | [ `/'`\| '/'`\ [ \ [ \ [  `'_\ : | | | '' </ /__\[ `/'`\] 
	 _| |_   | |   | \__.,| | | | | | | || \_/ |,| | | | | |  \  `-'  /| |   |  \__/ |\ \/\ \/ /// | |,| | | |`\ | \__.,| |     
	|_____| [___]   '.__.[___||__||__[___'.__.'_[___||__||__]  `.___.'[___] [__;.__.'  \__/\__/ \'-;__[___[__|  \_'.__.[___]    

--]]

local MathAbs, MathAtan, MathAtan2, MathAcos, MathCeil, MathCos, MathDeg, MathFloor, MathHuge, MathMax, MathMin, MathPi, MathRad, MathRandom, MathSin, MathSqrt = math.abs, math.atan, math.atan2, math.acos, math.ceil, math.cos, math.deg, math.floor, math.huge, math.max, math.min, math.pi, math.rad, math.random, math.sin, math.sqrt
local GameCanUseSpell, GameIsChatOpen, GameTimer, GameHeroCount, GameHero, GameMinionCount, GameMinion, GameTurretCount, GameTurret = Game.CanUseSpell, Game.IsChatOpen, Game.Timer, Game.HeroCount, Game.Hero, Game.MinionCount, Game.Minion, Game.TurretCount, Game.Turret
local ControlIsKeyDown, ControlKeyDown, ControlKeyUp, ControlMouseEvent, ControlSetCursorPos, DrawCircle, DrawLine = Control.IsKeyDown, Control.KeyDown, Control.KeyUp, Control.mouse_event, Control.SetCursorPos, Draw.Circle, Draw.Line
local TableInsert, TableRemove, TableSort = table.insert, table.remove, table.sort

class "PremiumOrb"

-- Geometry

function PremiumOrb:Distance(p1, p2)
	return MathSqrt(self:DistanceSquared(p1, p2))
end

function PremiumOrb:DistanceSquared(p1, p2)
	local dx, dy = p2.x - p1.x, p2.z - p1.z
	return dx * dx + dy * dy
end

-- Manager

function PremiumOrb:CalcMagicalDamage(source, target, amount)
	local mr = target.magicResist * source.magicPenPercent - source.magicPen
	return MathMax(0, MathFloor((mr < 0 and 2 - 100 / (100 - mr) or 100 / (100 + mr)) * amount))
end

function PremiumOrb:CalcPhysicalDamage(source, target, amount)
	local ar = target.armor * source.armorPenPercent - (target.bonusArmor * (1 -
		source.bonusArmorPenPercent)) - (source.armorPen * (0.6 + (0.4 * (target.levelData.lvl / 18))))
	return MathMax(0, MathFloor((ar < 0 and 2 - 100 / (100 - ar) or 100 / (100 + ar)) * amount))
end

function PremiumOrb:GetEnemyHeroes()
	local enemies = {}
	for i = 1, GameHeroCount() do
		local unit = GameHero(i)
		if unit and unit.isEnemy and self:IsValid(unit)
			then TableInsert(enemies, unit) end
	end
	return enemies
end

function PremiumOrb:GetMinionsAround(range, type)
	local type, minions = type or 1, {}
	for i = 1, GameMinionCount() do
		local minion = GameMinion(i)
		if minion and self:IsValid(minion, range) then
			local isAlly = minion.team == myHero.team
			if type == 1 and not isAlly or (type == 2
				and isAlly) then TableInsert(minions, minion)
			end
		end
	end
	return minions
end

function PremiumOrb:GetSummonerLevel()
	return myHero.levelData.lvl > 18 and myHero.levelData.lvl or 1
end

function PremiumOrb:IsValid(unit, range)
	local range = range or 12500
	return unit and
		unit.valid and
		unit.visible and
		unit.health > 0 and
		unit.maxHealth > 5 and
		self:DistanceSquared(myHero.pos,
			unit.pos) <= range * range
end

function PremiumOrb:HasBuff(unit, names)
	for i = 0, unit.buffCount do
		local buff = unit:GetBuff(i)
		if buff and buff.count > 0 then
			local buffName = buff.name
			for i, name in ipairs(names) do
				if buffName == name then
					return buff.count end
			end
		end
	end
	return 0
end

function PremiumOrb:HasBuffType(unit, type)
	for i = 0, unit.buffCount do
		local buff = unit:GetBuff(i)
		if buff and buff.count > 0 then
			if buff.type == type then return true end
		end
	end
	return false
end

-- Callbacks

function PremiumOrb:BasicAttack(func)
	TableInsert(self.OnBasicAA, func)
end

function PremiumOrb:PostAttack(func)
	TableInsert(self.OnPostAA, func)
end

function PremiumOrb:PreAttack(func)
	TableInsert(self.OnPreAA, func)
end

function PremiumOrb:PreMovement(func)
	TableInsert(self.OnPreMove, func)
end

function PremiumOrb:UnkillableMinion(func)
	TableInser(self.OnUnkillable, func)
end

--[[
	┌─┐┬─┐┌┐ ┬ ┬┌─┐┬  ┬┌─┌─┐┬─┐
	│ │├┬┘├┴┐│││├─┤│  ├┴┐├┤ ├┬┘
	└─┘┴└─└─┘└┴┘┴ ┴┴─┘┴ ┴└─┘┴└─
--]]

function PremiumOrb:__init()
	self.BonusDamage = {
		["Caitlyn"] = function(unit)
			return self:HasBuff(myHero, {"caitlynheadshot"}) > 0 and
				self:CalcPhysicalDamage(myHero, unit, myHero.totalDamage) or 0
		end,
		["Diana"] = function(unit)
			return self:HasBuff(myHero, {"dianapassivemarker"}) == 2 and
				self:CalcMagicalDamage(myHero, unit, ({20, 25, 30, 35, 40, 55, 65, 75, 85, 95, 120,
				135, 150, 165, 180, 210, 230, 250})[self:GetSummonerLevel()] + 0.4 * myHero.ap) or 0
		end,
		["Draven"] = function(unit)
			local lvl = myHero:GetSpellData(_Q).level or 0
			return self:HasBuff(myHero, {"DravenSpinningAttack"}) > 0 and
				self:CalcPhysicalDamage(myHero, unit, 25 + 5 * lvl +
					(0.55 + 0.1 * lvl) * myHero.bonusDamage) or 0
		end,
		["Galio"] = function(unit)
			return 0 -- TODO
		end,
		["Jhin"] = function(unit)
			return self:HasBuff(myHero, {"jhinpassiveattackbuff"}) > 0 and
				self:CalcPhysicalDamage(myHero, unit, MathMin(0.25, 0.1 + 0.05 * MathMax(
				0.2 * self:GetSummonerLevel())) * (unit.maxHealth - unit.health)) or 0
		end,
		["Jinx"] = function(unit)
			return self:HasBuff(myHero, {"JinxQ"}) > 0 and
				self:CalcPhysicalDamage(myHero, unit, 0.1 * myHero.totalDamage) or 0
		end,
		["Lux"] = function(unit)
			return self:HasBuff(unit, {"LuxIlluminatingFraulein"}) > 0 and
				self:CalcMagicalDamage(myHero, unit, 10 + 10 *
				self:GetSummonerLevel() + (0.2 * myHero.ap)) or 0
		end,
		["Kalista"] = function(unit)
			return -self:CalcPhysicalDamage(myHero, unit, 0.1 * myHero.totalDamage)
		end,
		["Kayle"] = function(unit)
			return 0 -- TODO
		end,
		["Nasus"] = function(unit)
			return self:HasBuff(myHero, {"NasusQ"}) > 0 and
				self:CalcPhysicalDamage(myHero, unit, 10 + 20 * myHero:GetSpellData(_Q).level
				+ MathMax(0, self:HasBuff(myHero, {"NasusQStacks"}))) or 0
		end,
		["Nidalee"] = function(unit)
			return 0 -- TODO
		end,
		["Quinn"] = function(unit)
			local lvl = self:GetSummonerLevel()
			return self:HasBuff(unit, {"QuinnW"}) > 0 and
				self:CalcPhysicalDamage(myHero, unit, 5 + 5 * lvl +
				(0.14 + 0.02 * lvl) * myHero.totalDamage) or 0
		end,
		["Sylas"] = function(unit)
			return 0 -- TODO
		end,
		["TwistedFate"] = function(unit)
			local dmg = self:HasBuff(myHero, {"cardmasterstackparticle"}) > 0
				and self:CalcMagicalDamage(myHero, unit, 40 + 25 *
				myHero:GetSpellData(_E).level + (0.5 * myHero.ap)) or 0
			if self:HasBuff(myHero, {"BlueCardPreAttack"}) > 0 then
				return dmg + self:CalcMagicalDamage(myHero, unit, 20 *
				20 + myHero:GetSpellData(_Q).level + (0.5 * myHero.ap))
			elseif self:HasBuff(myHero, {"GoldCardPreAttack"}) > 0 then
				return dmg + self:CalcMagicalDamage(myHero, unit, 7.5 *
				7.5 + myHero:GetSpellData(_Q).level + (0.5 * myHero.ap))
			elseif self:HasBuff(myHero, {"RedCardPreAttack"}) > 0 then
				return dmg + self:CalcMagicalDamage(myHero, unit, 15 *
				15 + myHero:GetSpellData(_Q).level + (0.5 * myHero.ap))
			end
			return dmg
		end,
		["Varus"] = function(unit)
			local lvl = myHero:GetSpellData(_W).level or 0
			return lvl > 0 and self:CalcMagicalDamage(myHero,
				unit, 3.5 + 3.5 * lvl + (0.25 * myHero.ap)) or 0
		end,
		["Viktor"] = function(unit)
			return self:HasBuff(myHero, {"ViktorPowerTransferReturn"}) > 0
				and self:CalcMagicalDamage(myHero, unit, -5 + 25 *
				myHero:GetSpellData(_Q).level + (0.55 * myHero.ap)) or 0
		end,
		["Vayne"] = function(unit)
			local lvl = myHero:GetSpellData(_W).level
			local dmg = self:HasBuff(unit, {"VayneSilveredDebuff"}) == 2 and
				MathMax(35 + 15 * lvl, (0.015 + 0.025 * lvl) * unit.maxHealth) or 0
			return dmg + (self:HasBuff(myHero, {"vaynetumblebonus"}) > 0 and
				self:CalcPhysicalDamage(myHero, unit, 0.45 + 0.05 * myHero.totalDamage) or 0)
		end
	}
	self.IsMeleeStandard = {
		["Aatrox"] = true, ["Ahri"] = false, ["Akali"] = true, ["Alistar"] = true, ["Amumu"] = true, ["Anivia"] = false, ["Annie"] = false,
		["Aphelios"] = false, ["Ashe"] = false, ["AurelionSol"] = false, ["Azir"] = true, ["Bard"] = false, ["Blitzcrank"] = true, ["Brand"] = false,
		["Braum"] = true, ["Caitlyn"] = false, ["Camille"] = true, ["Cassiopeia"] = false, ["Chogath"] = true, ["Corki"] = false, ["Darius"] = true,
		["Diana"] = true, ["DrMundo"] = true, ["Draven"] = false, ["Ekko"] = true, ["Elise"] = false, ["Evelynn"] = true, ["Ezreal"] = false,
		["Fiddlesticks"] = false, ["Fiora"] = true, ["Fizz"] = true, ["Galio"] = true, ["Gangplank"] = true, ["Garen"] = true, ["Gnar"] = false,
		["Gragas"] = true, ["Graves"] = false, ["Hecarim"] = true, ["Heimerdinger"] = false, ["Illaoi"] = true, ["Irelia"] = true, ["Ivern"] = false,
		["Janna"] = false, ["JarvanIV"] = true, ["Jax"] = true, ["Jayce"] = false, ["Jhin"] = false, ["Jinx"] = false, ["Kaisa"] = false,
		["Kalista"] = false, ["Karma"] = false, ["Karthus"] = false, ["Kassadin"] = true, ["Katarina"] = true, ["Kayle"] = false, ["Kayn"] = true,
		["Kennen"] = false, ["Khazix"] = true, ["Kindred"] = false, ["Kled"] = true, ["KogMaw"] = false, ["Leblanc"] = false, ["LeeSin"] = true,
		["Leona"] = true, ["Lissandra"] = false, ["Lucian"] = false, ["Lulu"] = false, ["Lux"] = false, ["Malphite"] = true, ["Malzahar"] = false,
		["Maokai"] = true, ["MasterYi"] = true, ["MissFortune"] = false, ["MonkeyKing"] = true, ["Mordekaiser"] = true, ["Morgana"] = false,
		["Nami"] = false, ["Nasus"] = true, ["Nautilus"] = true, ["Neeko"] = false, ["Nidalee"] = false, ["Nocturne"] = true, ["Nunu"] = true,
		["Olaf"] = true, ["Orianna"] = false, ["Ornn"] = true, ["Pantheon"] = true, ["Poppy"] = true, ["Pyke"] = true, ["Qiyana"] = true,
		["Quinn"] = false, ["Rakan"] = true, ["Rammus"] = true, ["RekSai"] = true, ["Renekton"] = true, ["Rengar"] = true, ["Riven"] = true,
		["Rumble"] = true, ["Ryze"] = false, ["Sejuani"] = true, ["Senna"] = false, ["Sett"] = true, ["Shaco"] = true, ["Shen"] = true,
		["Shyvana"] = true, ["Singed"] = true, ["Sion"] = true, ["Sivir"] = false, ["Skarner"] = true, ["Sona"] = false, ["Soraka"] = false,
		["Swain"] = false, ["Sylas"] = true, ["TahmKench"] = true, ["Taliyah"] = false, ["Talon"] = true, ["Taric"] = true, ["Teemo"] = false,
		["Thresh"] = true, ["Tristana"] = false, ["Trundle"] = true, ["Tryndamere"] = true, ["TwistedFate"] = false, ["Twitch"] = false,
		["Udyr"] = true, ["Urgot"] = true, ["Varus"] = false, ["Vayne"] = false, ["Veigar"] = false, ["Velkoz"] = true, ["Vi"] = true,
		["Viktor"] = false, ["Vladimir"] = false, ["Volibear"] = true, ["Warwick"] = true, ["Xayah"] = false, ["Xerath"] = false,
		["XinZhao"] = true, ["Yasuo"] = true, ["Yorick"] = true, ["Yuumi"] = false, ["Zac"] = true, ["Zed"] = true, ["Ziggs"] = false,
		["Zilean"] = false, ["Zoe"] = false, ["Zyra"] = false
	}
	self.IsMeleeSpecial = {
		["Elise"] = function() return myHero.range < 250 end,
		["Gnar"] = function() return myHero.range < 250 end,
		["Jayce"] = function() return myHero.range < 250 end,
		["Kayle"] = function() return myHero.range < 250 end,
		["Nidalee"] = function() return myHero.range < 250 end
	}
	self.Priorities = {
		["Aatrox"] = 3, ["Ahri"] = 4, ["Akali"] = 4, ["Alistar"] = 1, ["Amumu"] = 1, ["Anivia"] = 4, ["Annie"] = 4, ["Aphelios"] = 5,
		["Ashe"] = 5, ["AurelionSol"] = 4, ["Azir"] = 4, ["Bard"] = 3, ["Blitzcrank"] = 1, ["Brand"] = 4, ["Braum"] = 1, ["Caitlyn"] = 5,
		["Camille"] = 3, ["Cassiopeia"] = 4, ["Chogath"] = 1, ["Corki"] = 5, ["Darius"] = 2, ["Diana"] = 4, ["DrMundo"] = 1, ["Draven"] = 5,
		["Ekko"] = 4, ["Elise"] = 3, ["Evelynn"] = 4, ["Ezreal"] = 5, ["Fiddlesticks"] = 3, ["Fiora"] = 3, ["Fizz"] = 4, ["Galio"] = 1,
		["Gangplank"] = 4, ["Garen"] = 1, ["Gnar"] = 1, ["Gragas"] = 2, ["Graves"] = 4, ["Hecarim"] = 2, ["Heimerdinger"] = 3, ["Illaoi"] = 3,
		["Irelia"] = 3, ["Ivern"] = 1, ["Janna"] = 2, ["JarvanIV"] = 3, ["Jax"] = 3, ["Jayce"] = 4, ["Jhin"] = 5, ["Jinx"] = 5, ["Kaisa"] = 5,
		["Kalista"] = 5, ["Karma"] = 4, ["Karthus"] = 4, ["Kassadin"] = 4, ["Katarina"] = 4, ["Kayle"] = 4, ["Kayn"] = 4, ["Kennen"] = 4,
		["Khazix"] = 4, ["Kindred"] = 4, ["Kled"] = 2, ["KogMaw"] = 5, ["Leblanc"] = 4, ["LeeSin"] = 3, ["Leona"] = 1, ["Lissandra"] = 4,
		["Lucian"] = 5, ["Lulu"] = 3, ["Lux"] = 4, ["Malphite"] = 1, ["Malzahar"] = 3, ["Maokai"] = 2, ["MasterYi"] = 5, ["MissFortune"] = 5,
		["MonkeyKing"] = 3, ["Mordekaiser"] = 4, ["Morgana"] = 3, ["Nami"] = 3, ["Nasus"] = 2, ["Nautilus"] = 1, ["Neeko"] = 4, ["Nidalee"] = 4,
		["Nocturne"] = 4, ["Nunu"] = 2, ["Olaf"] = 2, ["Orianna"] = 4, ["Ornn"] = 2, ["Pantheon"] = 3, ["Poppy"] = 2, ["Pyke"] = 5,
		["Qiyana"] = 4, ["Quinn"] = 5, ["Rakan"] = 3, ["Rammus"] = 1, ["RekSai"] = 2, ["Renekton"] = 2, ["Rengar"] = 4, ["Riven"] = 4,
		["Rumble"] = 4, ["Ryze"] = 4, ["Sejuani"] = 2, ["Senna"] = 3, ["Sett"] = 3, ["Shaco"] = 4, ["Shen"] = 1, ["Shyvana"] = 2, ["Singed"] = 1,
		["Sion"] = 1, ["Sivir"] = 5, ["Skarner"] = 2, ["Sona"] = 3, ["Soraka"] = 3, ["Swain"] = 3, ["Sylas"] = 4, ["TahmKench"] = 1,
		["Taliyah"] = 4, ["Talon"] = 4, ["Taric"] = 1, ["Teemo"] = 4, ["Thresh"] = 1, ["Tristana"] = 5, ["Trundle"] = 2, ["Tryndamere"] = 4,
		["TwistedFate"] = 4, ["Twitch"] = 5, ["Udyr"] = 2, ["Urgot"] = 2, ["Varus"] = 5, ["Vayne"] = 5, ["Veigar"] = 4, ["Velkoz"] = 4,
		["Vi"] = 2, ["Viktor"] = 4, ["Vladimir"] = 3, ["Volibear"] = 2, ["Warwick"] = 2, ["Xayah"] = 5, ["Xerath"] = 4, ["XinZhao"] = 3,
		["Yasuo"] = 4, ["Yorick"] = 2, ["Yuumi"] = 2, ["Zac"] = 1, ["Zed"] = 4, ["Ziggs"] = 4, ["Zilean"] = 3, ["Zoe"] = 4, ["Zyra"] = 2
	}
	self.ResetAASpells = {
		["Blitzcrank"] = _E, ["Camille"] = _Q, ["Chogath"] = _E, ["Darius"] = _W, ["DrMundo"] = _E, ["Elise"] = _W, ["Fiora"] = _E, ["Garen"] = _Q,
		["Graves"] = _E, ["Kassadin"] = _W, ["Illaoi"] = _W, ["Jax"] = _W, ["Jayce"] = _W, ["Kayle"] = _E, ["Katarina"] = _E, ["Kindred"] = _Q,
		["Leona"] = _Q, ["Lucian"] = _E, ["MasterYi"] = _W, ["Mordekaiser"] = _Q, ["Nautilus"] = _W, ["Nidalee"] = _Q, ["Nasus"] = _Q,
		["RekSai"] = _Q, ["Renekton"] = _W, ["Rengar"] = _Q, ["Riven"] = _Q, ["Sejuani"] = _E, ["Sett"] = _Q, ["Sivir"] = _W, ["Trundle"] = _Q,
		["Vayne"] = _Q, ["Vi"] = _E, ["Volibear"] = _Q, ["MonkeyKing"] = _Q, ["XinZhao"] = _Q, ["Yorick"] = _Q
	}
	self.ShouldWaitToMove = {
		["Caitlyn"] = function() return self:HasBuff(myHero, {"CaitlynAceintheHole"}) > 0 end,
		["Fiddlesticks"] = function() return self:HasBuff(myHero, {"Drain", "Crowstorm"}) > 0 end,
		["Galio"] = function() return self:HasBuff(myHero, {"GalioR"}) > 0 end,
		["Janna"] = function() return self:HasBuff(myHero, {"ReapTheWhirlwind"}) > 0 end,
		["Karthus"] = function() return self:HasBuff(myHero, {"karthusfallenonecastsound"}) > 0 end,
		["Katarina"] = function() return self:HasBuff(myHero, {"katarinarsound"}) > 0 end,
		["Malzahar"] = function() return self:HasBuff(myHero, {"alzaharnethergraspsound"}) > 0 end,
		["Karthus"] = function() return self:HasBuff(myHero, {"karthusfallenonecastsound"}) > 0 end,
		["MasterYi"] = function() return self:HasBuff(myHero, {"Meditate"}) > 0 end,
		["MissFortune"] = function() return self:HasBuff(myHero, {"missfortunebulletsound"}) > 0 end,
		["Pantheon"] = function() return self:HasBuff(myHero, {"PantheonR"}) > 0 end,
		["Shen"] = function() return self:HasBuff(myHero, {"shenstandunitedlock"}) > 0 end,
		["TwistedFate"] = function() return self:HasBuff(myHero, {"Destiny"}) > 0 end,
		["Velkoz"] = function() return self:HasBuff(myHero, {"VelkozR"}) > 0 end,
		["Warwick"] = function() return self:HasBuff(myHero, {"infiniteduresssound"}) > 0 end,
		["Xerath"] = function() return self:HasBuff(myHero, {"XerathLocusOfPower2"}) > 0 end
	}
	self.AttackEnabled, self.MovementEnabled = true, true
	self.ActiveAttacks, self.Minions, self.OnBasicAA, self.OnPostAA, self.OnPreAA,
		self.OnPreMove, self.OnUnkillable = {}, {}, {}, {}, {}, {}, {}
	self.AttackTimer, self.CastTimer, self.LastAttack, self.LastCastEnd, self.Mode, self.MoveTimer, self.WaitTimer,
		self.BaseAttackSpeed, self.BaseWindUp, self.Cursor, self.ResetSpell = 0, 0, 0, 0, 0, 0, 0, nil, nil, nil, nil
	self.PremiumOrbMenu = MenuElement({type = MENU, id = "PremiumOrbwalker", name = "Premium Orbwalker WIP"})
	self.PremiumOrbMenu:MenuElement({id = "Keys", name = "Keys", type = MENU})
	self.PremiumOrbMenu.Keys:MenuElement({id = "Burst", name = "Burst Key", key = string.byte("Z")})
	self.PremiumOrbMenu.Keys:MenuElement({id = "Combo", name = "Combo Key", key = string.byte(" ")})
	self.PremiumOrbMenu.Keys:MenuElement({id = "Harass", name = "Harass Key", key = string.byte("C")})
	self.PremiumOrbMenu.Keys:MenuElement({id = "LaneClear", name = "LaneClear Key", key = string.byte("V")})
	self.PremiumOrbMenu.Keys:MenuElement({id = "LastHit", name = "LastHit Key", key = string.byte("X")})
	self.PremiumOrbMenu.Keys:MenuElement({id = "Flee", name = "Flee Key", key = string.byte("A")})
	self.PremiumOrbMenu:MenuElement({id = "Misc", name = "Misc", type = MENU})
	self.PremiumOrbMenu.Misc:MenuElement({id = "Range", name = "Draw Auto Attack Range", value = true})
	self.PremiumOrbMenu.Misc:MenuElement({id = "Ping", name = "Average Game Ping", value = 50, min = 0, max = 250, step = 5})
	if self.ResetAASpells[myHero.charName] then self.ResetSpell = {slot = self.ResetAASpells[myHero.charName], timer = 0} end
	Callback.Add("Tick", function() self:OnTick() end)
	Callback.Add("Draw", function() self:OnDraw() end)
end

function PremiumOrb:CalcMaxDamage(unit)
	return myHero.ap > myHero.totalDamage and
		self:CalcMagicalDamage(myHero, unit, 100) or
		self:CalcPhysicalDamage(myHero, unit, 100)
end

function PremiumOrb:CanAttack()
	local spell, charName = myHero.activeSpell, myHero.charName
	if spell and spell.valid and spell.isChanneling or not
		self.AttackEnabled or myHero.pathing.isDashing or
		(charName ~= "Kalista" and self:HasBuffType(myHero, 25)) or
		(charName == "Jhin" and self:HasBuff(myHero,
			{"JhinPassiveReload"}) > 0) then return false end
	return GameTimer() >= ((self.AttackTimer < self.LastCastEnd) and self.LastAttack -
		self:GetLatency() + self:GetAnimationTime() - 0.07 or self.AttackTimer + 0.15)
end

function PremiumOrb:CanMove()
	local shouldWait = self.ShouldWaitToMove[myHero.charName]
	if not self.MovementEnabled or myHero.pathing.isDashing or
		shouldWait ~= nil and shouldWait() then return false end
	return myHero.charName == "Kalista" or GameTimer() >= ((self.AttackTimer < self.LastCastEnd) and
		self.LastAttack - self:GetLatency() + self:GetWindUpTime() or self.AttackTimer + 0.15)
end

function PremiumOrb:GetAnimationTime()
	return self.BaseAttackSpeed and 1 / (self:GetAttackSpeed() *
		self.BaseAttackSpeed) or myHero.attackData.animationTime
end

function PremiumOrb:GetAttackSpeed()
	return MathMin(myHero.attackSpeed, 2.5)
end

function PremiumOrb:GetAutoAttackDamage(source, target)
	local name = source.charName
	return self:CalcPhysicalDamage(source, target, source.totalDamage) +
		(source.type == Obj_AI_Hero and self.BonusDamage[name] ~=
			nil and self.BonusDamage[name](target) or 0)
end

function PremiumOrb:GetAutoAttackRange(unit)
	local range = myHero.range + (myHero.boundingRadius or 65)
	if unit and self:IsValid(unit) then
		if myHero.charName == "Aphelios" and
			self:HasBuff(unit, {"aphelioscalibrumbonusrangedebuff"}) > 0 then
				range = 1800
		elseif myHero.charName == "Caitlyn" and
			self:HasBuff(myHero, {"caitlynyordletrapinternal"}) > 0 then
				range = range + 650
		end
		return range + (unit.boundingRadius or 65)
	end
	return range + 35
end

function PremiumOrb:GetLatency()
	return self.PremiumOrbMenu.Misc.Ping:Value() / 2000
end

function PremiumOrb:GetHealthPrediction(unit, delta)
	local predHealth, timer = unit.health + unit.shieldAD, GameTimer()
	for i, attack in pairs(self.ActiveAttacks) do
		if attack and self:IsValid(attack.source) and attack.target == unit.handle then
			local arrival = attack.startTime + attack.windUpTime + self:Distance(
				unit.pos, attack.source.pos) / attack.projectileSpeed + 0.07
			if timer < arrival - 0.07 and arrival < timer + delta then
				predHealth = predHealth - self:GetAutoAttackDamage(attack.source, unit)
			end
		end
	end
	return predHealth
end

function PremiumOrb:GetLaneClearHealthPrediction(unit, delta)
	local predHealth, timer = unit.health + unit.shieldAD, GameTimer()
	for i, attack in pairs(self.ActiveAttacks) do
		local count = 0
		if attack and self:IsValid(attack.source) and attack.target == unit.handle then
			if timer <= attack.startTime + attack.animationTime + 0.1 then
				local from, to = attack.startTime, timer + delta
				while from < to do
					if timer <= from and from + attack.windUpTime + self:Distance(unit.pos,
						attack.source.pos) / attack.projectileSpeed < to then count = count + 1
					end
					from = from + attack.animationTime
				end
			end
			predHealth = predHealth - self:GetAutoAttackDamage(attack.source, unit) * count
		end
	end
	return predHealth
end

function PremiumOrb:GetProjectileSpeed(unit)
	local name = unit.charName
	if name == "Viktor" and self:HasBuff(
		unit, {"ViktorPowerTransferReturn"}) > 0 or
			self:IsMelee(unit) then return MathHuge end
	local speed = unit.attackData.projectileSpeed
	return speed > 0 and speed or MathHuge
end

function PremiumOrb:GetMode()
	return self.Mode == 1 and "Burst"
		or self.Mode == 2 and "Combo"
		or self.Mode == 3 and "Harass"
		or self.Mode == 4 and "LaneClear"
		or self.Mode == 5 and "LastHit"
		or self.Mode == 6 and "Flee" or nil
end

function PremiumOrb:GetPriority(unit)
	local priority = self.Priorities[unit.charName] or 3
	return priority == 5 and 2.5 or
		priority == 4 and 2 or
		priority == 3 and 1.75 or
		priority == 2 and 1.5 or 1
end

function PremiumOrb:GetWindUpTime()
	return self.BaseWindUp and 1 / (self:GetAttackSpeed() *
		self.BaseWindUp) or myHero.attackData.windUpTime
end

function PremiumOrb:IsAttackEnabled()
	return self.AttackEnabled
end

function PremiumOrb:IsAutoAttacking()
	return GameTimer() <= self.LastCastEnd
end

function PremiumOrb:IsMovementEnabled()
	return self.MovementEnabled
end

function PremiumOrb:IsMelee(unit)
	local name = unit.charName
	if unit.type == Obj_AI_Hero then
		return self.IsMeleeStandard[name]
			or self.IsMeleeSpecial[name] ~= nil
				and self.IsMeleeSpecial[name]()
	end
	return name:find("Melee") ~= nil
		or name:find("Super") ~= nil
end

function PremiumOrb:ResetAutoAttack(check)
	if check then
		local melee, name = self:IsMelee(myHero), myHero.charName
		if name == "Elise" and not melee or name == "Jayce" and melee or
			name == "Nidalee" and not melee or name == "Vayne" and
			self:HasBuff(myHero, {"vaynetumblebonus"}) == 0 then return
		end
		self.ResetSpell.timer = GameTimer()
	end
	DelayAction(function()
		self.AttackTimer, self.LastAttack,
			self.LastCastEnd = 0, 0, 0
	end, 0.05)
end

function PremiumOrb:SetAttack(bool)
	self.AttackEnabled = bool
end

function PremiumOrb:SetMovement(bool)
	self.MovementEnabled = bool
end

function PremiumOrb:GetTarget(range, mode)
	local mode = mode or 1
	if mode == 1 or mode == 2 or mode == 3 then
		local enemies = {}
		for i, enemy in ipairs(self:GetEnemyHeroes()) do
			if self:IsValid(enemy) and not enemy.isImmortal
				and self:Distance(myHero.pos, enemy.pos) <= (range or
					self:GetAutoAttackRange(enemy)) then TableInsert(enemies, enemy)
			end
		end
		TableSort(enemies, function(a, b) return
			self:CalcMaxDamage(a) / (1 + a.health) * self:GetPriority(a) >
			self:CalcMaxDamage(b) / (1 + b.health) * self:GetPriority(b)
		end)
		return #enemies > 0 and enemies[1] or nil
	end
	self.Minions = self:GetMinionsAround(self:GetAutoAttackRange(), 1)
	TableSort(self.Minions, function(a, b) return
		a.maxHealth > b.maxHealth and a.health < b.health end)
	if mode == 3 or mode == 4 or mode == 5 then
		local speed = self:GetProjectileSpeed(myHero)
		for i, minion in ipairs(self.Minions) do
			local t = self:GetWindUpTime() + self:GetLatency() -
				self:Distance(myHero.pos, minion.pos) / speed - 0.07
			local predHealth = self:GetHealthPrediction(minion, t)
			if predHealth <= 0 then for i = 1, #self.OnUnkillable do self.OnUnkillable[i](minion) end end
			if predHealth <= self:GetAutoAttackDamage(myHero, minion) then return minion end
		end
	end
	if mode == 4 then
		if GameTimer() - self:ShouldWait() >= 0.5 then
			for i = 1, GameTurretCount() do
				local turret = GameTurret(i)
				if turret and turret.valid and turret.isEnemy and
					turret.health > 0 and self:Distance(myHero.pos, turret.pos)
						<= self:GetAutoAttackRange(turret) then return turret
				end
			end
			return #self.Minions > 0 and self.Minions[1] or nil
		end
	end
	return nil
end

function PremiumOrb:ShouldWait()
	local t = self:GetAnimationTime() * 2
	for i, minion in ipairs(self.Minions) do
		local pred = self:GetLaneClearHealthPrediction(minion, t)
		if minion.health ~= pred and pred <=
			self:GetAutoAttackDamage(myHero, minion) * 2 then
				self.WaitTimer = GameTimer(); break
		end
	end
	return self.WaitTimer
end

function PremiumOrb:DetectAutoAttacksAndSpells()
	local spell, timer = myHero.activeSpell, GameTimer()
	if spell and spell.valid and spell.isAutoAttack and
		self.LastCastEnd ~= spell.castEndTime then
			for i = 1, #self.OnBasicAA do self.OnBasicAA[i](spell.target) end
			local attackSpeed = self:GetAttackSpeed()
			self.BaseAttackSpeed = 1 / (spell.animation * attackSpeed)
			self.BaseWindUp = 1 / (spell.windup * attackSpeed)
			self.LastAttack, self.LastCastEnd = spell.startTime, spell.castEndTime
			DelayAction(function()
				for i = 1, #self.OnPostAA do self.OnPostAA[i]() end
			end, spell.windup)
	end
	if self.ResetSpell ~= nil then
		local data = myHero:GetSpellData(self.ResetSpell.slot)
		local state = GameCanUseSpell(self.ResetSpell.slot)
		if state ~= READY and timer - data.castTime < 0.25 and timer -
			self.ResetSpell.timer > 1 then self:ResetAutoAttack(true)
		end
	end
	local minions = self:GetMinionsAround(
		self:GetAutoAttackRange() + 550, 2)
	for i, minion in ipairs(minions) do
		local active = minion.activeSpell
		if active and active.valid and active.name:find("Attack") then
			self.ActiveAttacks[minion.networkID] = {
				source = minion,
				target = active.target,
				startTime = active.startTime,
				endTime = active.endTime,
				windUpTime = active.windup,
				animationTime = active.animation,
				projectileSpeed = self:IsMelee(minion)
					and MathHuge or active.speed
			}
		end
	end
	for id, data in pairs(self.ActiveAttacks) do
		if timer >= data.endTime then
			self.ActiveAttacks[id] = nil
		end
	end
end

function PremiumOrb:OnTick()
	if myHero.dead then return end
	self:DetectAutoAttacksAndSpells()
	if _G.ExtLibEvade and _G.ExtLibEvade.Evading or (_G.JustEvade and
		_G.JustEvade:Evading()) or GameIsChatOpen() then return end
	self.Mode = self.PremiumOrbMenu.Keys.Burst:Value() and 1
		or self.PremiumOrbMenu.Keys.Combo:Value() and 2
		or self.PremiumOrbMenu.Keys.Harass:Value() and 3
		or self.PremiumOrbMenu.Keys.LaneClear:Value() and 4
		or self.PremiumOrbMenu.Keys.LastHit:Value() and 5
		or self.PremiumOrbMenu.Keys.Flee:Value() and 6 or 0
	if self.Mode == 0 then return end
	local target = self:GetTarget(nil, self.Mode)
	if target and target.isTargetable and self:CanAttack() then
		local args = {Target = target, Process = true}
		for i = 1, #self.OnPreAA do self.OnPreAA[i](args) end
		if args.Process then self:AttackUnit(args.Target) end
	elseif self:CanMove() then
		local args = {Process = true}
		for i = 1, #self.OnPreMove do self.OnPreMove[i]() end
		if args.Process then self:Move() end
	end
end

function PremiumOrb:OnDraw()
	if self.PremiumOrbMenu.Misc.Range:Value() then
		DrawCircle(myHero.pos, self:GetAutoAttackRange(), 1, Draw.Color(96, 230, 230, 230))
	end
end

function PremiumOrb:AttackUnit(unit, check)
	if not (unit and self:IsValid(unit)) or
		(check and not self:CanAttack()) then return end
	local pos = Vector(unit.pos.x, unit.pos.y + 25, unit.pos.z):To2D()
	self.Cursor = cursorPos
	self.AttackTimer = GameTimer()
	ControlSetCursorPos(pos.x, pos.y)
	ControlMouseEvent(MOUSEEVENTF_RIGHTDOWN)
	ControlMouseEvent(MOUSEEVENTF_RIGHTUP)
	DelayAction(function()
		local pos = self.Cursor
		ControlSetCursorPos(pos.x, pos.y)
	end, 0.05)
end

function PremiumOrb:Move()
	if GetTickCount() - self.MoveTimer >= 100 then
		ControlMouseEvent(MOUSEEVENTF_RIGHTDOWN)
		ControlMouseEvent(MOUSEEVENTF_RIGHTUP)
		self.MoveTimer = GetTickCount() + MathRandom(-25, 25)
	end
end

PremiumOrb:__init()

-- API

_G.PremiumOrbwalker = {
	AttackUnit = function(self, unit, check) PremiumOrb:AttackUnit(unit, check) end,
	CanAttack = function(self) return PremiumOrb:CanAttack() end,
	CanMove = function(self) return PremiumOrb:CanMove() end,
	GetAnimationTime = function(self) return PremiumOrb:GetAnimationTime() end,
	GetAutoAttackDamage = function(self, source, unit) return PremiumOrb:GetAutoAttackDamage(source, unit) end,
	GetMode = function(self) return PremiumOrb:GetMode() end,
	GetHealthPrediction = function(self, unit, delta) return PremiumOrb:GetHealthPrediction(unit, delta) end,
	GetProjectileSpeed = function(self, unit) return PremiumOrb:GetProjectileSpeed(unit) end,
	GetTarget = function(self, range, mode) return PremiumOrb:GetTarget(range, mode) end,
	GetWindUpTime = function(self) return PremiumOrb:GetWindUpTime() end,
	IsAttackEnabled = function(self) return PremiumOrb.AttackEnabled end,
	IsAutoAttacking = function(self) return PremiumOrb:IsAutoAttacking() end,
	IsMovementEnabled = function(self) return PremiumOrb.MovementEnabled end,
	ResetAutoAttack = function(self) PremiumOrb:ResetAutoAttack() end,
	SetAttack = function(self, bool) PremiumOrb:SetAttack(bool) end,
	SetMovement = function(self, bool) PremiumOrb:SetMovement(bool) end,
	OnBasicAttack = function(self, func) return PremiumOrb:BasicAttack(func) end,
	OnPostAttack = function(self, func) return PremiumOrb:PostAttack(func) end,
	OnPreAttack = function(self, func) return PremiumOrb:PreAttack(func) end,
	OnPreMovement = function(self, func) return PremiumOrb:PreMovement(func) end,
	OnUnkillableMinion = function(self, func) return PremiumOrb:OnUnkillableMinion(func) end
}

