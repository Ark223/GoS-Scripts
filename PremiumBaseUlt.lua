
local GameCanUseSpell, GameHero, GameObject, GameObjectCount, GameTimer =
	Game.CanUseSpell, Game.Hero, Game.Object, Game.ObjectCount, Game.Timer
local MathCeil, MathFloor, MathMax, MathSqrt = math.ceil, math.floor, math.max, math.sqrt

local function GameHeroCount()
	local c = Game.HeroCount()
	return (not c or c < 0 or c > 12) and 0 or c
end

local SpellData = {
	["Ashe"] = {
		speed = 1600, delay = 0.25, radius = 130, collision = true,
		type = 1, damage = function(lvl) return 200 * lvl + myHero.ap end
	},
	["Draven"] = {
		speed = 2000, delay = 0.4, radius = 160, collision = false,
		type = 2, damage = function(lvl) return 150 + 200 * lvl +
		(1.8 + 0.4 * lvl) * myHero.bonusDamage end
	},
	["Ezreal"] = {
		speed = 2000, delay = 1, radius = 160, collision = false,
		type = 2, damage = function(lvl) return 100 + 75 * lvl +
		0.5 * myHero.bonusDamage + 0.45 * myHero.ap end
	},
	["Jinx"] = {
		speed = 1700, delay = 0.6, radius = 140, collision = true,
		type = 2, damage = function(lvl) return 150 + 100 * lvl +
		1.5 * myHero.bonusDamage end
	}
}

function OnLoad()
	print("Loading PremiumBaseUlt...")
	BaseUlt:__init()
	print("PremiumBaseUlt successfully loaded!")
end

class "BaseUlt"

function BaseUlt:CalcMagicalDamage(source, target, amount)
	local mr = target.magicResist * source.magicPenPercent - source.magicPen
	return MathMax(0, MathFloor((mr < 0 and 2 - 100 / (100 - mr) or 100 / (100 + mr)) * amount))
end

function BaseUlt:CalcPhysicalDamage(source, target, amount)
	local ar = target.armor * source.armorPenPercent - (target.bonusArmor * (1 -
		source.bonusArmorPenPercent)) - (source.armorPen * (0.6 + (0.4 * (target.levelData.lvl / 18))))
	return MathMax(0, MathFloor((ar < 0 and 2 - 100 / (100 - ar) or 100 / (100 + ar)) * amount))
end

function BaseUlt:CalcTimeToHit(dist)
	local data = SpellData[self.CharName]
	local speed = data.speed
	if self.CharName == "Jinx" and dist > 1350 then
		local diff = MathMin(dist - 1350, 150)
		speed = (diff ^ 2 * 0.3 + (diff + 1350) *
			speed + 2200 * (dist - 1500)) / dist
	end
	return data.delay + dist / speed
end

function BaseUlt:Distance(p1, p2)
	local dx, dy = p2.x - p1.x, p2.z - p1.z
	return MathSqrt(dx * dx + dy * dy)
end

function BaseUlt:ForceUlt()
	self.Action = true
	local mm = Vector(self.Base):ToMM()
	Control.SetCursorPos(mm.x, mm.y)
	Control.mouse_event(MOUSEEVENTF_LEFTDOWN)
	if cursorPos.x == mm.x then
		Control.CastSpell(HK_R, mm.x, mm.y)
		self.Action = false
	end
	Control.mouse_event(MOUSEEVENTF_LEFTUP)
end

function BaseUlt:IsUltReady()
	return GameCanUseSpell(_R) == READY
end

function BaseUlt:__init()
	self.Action, self.Base, self.CharName, self.Mia,
		self.Recalls = false, nil, myHero.charName, {}, {}
	for i = 1, GameObjectCount() do
		local obj = GameObject(i)
		if obj.isEnemy and obj.type == Obj_AI_SpawnPoint then
			self.Base = Vector(obj.pos); break
		end
	end
	if _G.SDK then
		_G.SDK.Orbwalker:OnPreAttack(function(...) self:OnPreAttack(...) end)
		_G.SDK.Orbwalker:OnPreMovement(function(...) self:OnPreMovement(...) end)
	elseif _G.PremiumOrbwalker then
		_G.PremiumOrbwalker:OnPreAttack(function(...) self:OnPreAttack(...) end)
		_G.PremiumOrbwalker:OnPreMovement(function(...) self:OnPreMovement(...) end)
	end
	Callback.Add("ProcessRecall", function(unit, recall)
		self:OnProcessRecall(unit, recall) end)
	Callback.Add("Tick", function() self:OnTick() end)
end

function BaseUlt:OnPreAttack(args)
	if self.Action then args.Process = false end
end

function BaseUlt:OnPreMovement(args)
	if self.Action then args.Process = false end
end

function BaseUlt:OnProcessRecall(unit, recall)
	if unit.team == myHero.team then return end
	self.Recalls[unit.networkID] = recall.isStart
		and	not recall.isFinish and (GameTimer() +
			recall.totalTime * 0.001) or nil
end

function BaseUlt:OnTick()
	if _G.JustEvade and _G.JustEvade:Evading() or (_G.ExtLibEvade and _G.ExtLibEvade.Evading)
		or Game.IsChatOpen() or myHero.dead or not self:IsUltReady() then return end
	for i = 1, GameHeroCount() do
		local hero = GameHero(i)
		if hero.valid and hero.isEnemy then
			local id, visible = hero.networkID, hero.visible
			if not visible and not self.Mia[id] then
				self.Mia[id] = GameTimer()
			elseif visible and self.Mia[id] then
				self.Mia[id] = nil
			end
			if self.Recalls[id] then
				local lvl = myHero:GetSpellData(_R).level
				local dmg = SpellData[self.CharName].damage(lvl)
				local dist = self:Distance(myHero.pos, self.Base)
				if self.CharName == "Jinx" then
					dmg = dmg * (0.1 + 0.0006 * MathMax(1500, dist)) +
						(0.2 + 0.05 * lvl) * (unit.maxHealth - unit.health)
				end
				local recallTime, timeToHit = self.Recalls[id] -
					GameTimer(), self:CalcTimeToHit(dist)
				if recallTime <= timeToHit + 0.1 and recallTime > timeToHit - 0.5 then
					local delta = timeToHit + recallTime + (self.Mia[id]
						and GameTimer() - self.Mia[id] or 0)
					dmg = dmg - MathCeil(delta) * hero.hpRegen
					dmg = SpellData[self.CharName].type == 2 and
						self:CalcPhysicalDamage(myHero, hero, dmg)
						or self:CalcMagicalDamage(myHero, hero, dmg)
					print(dmg)
					if dmg >= hero.health then self:ForceUlt() end
				end
			end
		end
	end
end
