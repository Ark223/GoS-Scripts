
--[[

     ad888888b,   ad8888ba,    ,a8888a,    88888888888                             88           
    d8"     "88  8P'    "Y8  ,8P"'  `"Y8,  88                                      88           
            a8P d8          ,8P        Y8, 88                                      88           
         aad8"  88,dd888bb, 88          88 88aaaaa 8b       d8 ,adPPYYba,  ,adPPYb,88  ,adPPYba,
         ""Y8,  88P'    `8b 88          88 88""""" `8b     d8' ""     `Y8 a8"    `Y88 a8P_____88
            "8b 88       d8 `8b        d8' 88       `8b   d8'  ,adPPPPP88 8b       88 8PP"""""""
    Y8,     a88 88a     a8P  `8ba,  ,ad8'  88        `8b,d8'   88,    ,88 "8a,   ,d88 "8b,   ,aa
     "Y888888P'  "Y88888P"     "Y8888P"    88888888888 "8"     `"8bbdP"Y8  `"8bbdP"Y8  `"Ybbd8"'

--]]

local function Class()
	local cls = {}; cls.__index = cls
	return setmetatable(cls, {__call = function (c, ...)
		local instance = setmetatable({}, cls)
		if cls.__init then cls.__init(instance, ...) end
		return instance
	end})
end

function table.push(t1, t2)
	local tab = {}
	for i, v in ipairs(t1) do
		table.insert(tab, v)
	end
	for i, v in ipairs(t2) do
		table.insert(tab, v)
	end
	return tab
end

-- Point

local function IsPoint(p)
	return p and p.x and type(p.x) == "number"
		and (p.y and type(p.y) == "number")
end

local function Round(v)
	return v < 0 and math.ceil(v - 0.5) or math.floor(v + 0.5)
end

local Point2D = Class()

function Point2D:__init(x, y)
	if x and y then
		self.x, self.y = x, y
	elseif x and not y then
		self.x, self.y = x.x, x.z or x.y
	else
		self.x, self.y = 0, 0
	end
end

function Point2D:__type()
	return "Point2D"
end

function Point2D:__eq(p)
	return (self.x == p.x and self.y == p.y)
end

function Point2D:__add(p)
	return Point2D(self.x + p.x, self.y + p.y)
end

function Point2D:__sub(p)
	return Point2D(self.x - p.x, self.y - p.y)
end

function Point2D.__mul(a, b)
	if type(a) == "number" and IsPoint(b) then
		return Point2D(b.x * a, b.y * a)
	elseif type(b) == "number" and IsPoint(a) then
		return Point2D(a.x * b, a.y * b)
	end
end

function Point2D.__div(a, b)
	if type(a) == "number" and IsPoint(b) then
		return Point2D(a / b.x, a / b.y)
	else
		return Point2D(a.x / b, a.y / b)
	end
end

function Point2D:__tostring()
	return "("..self.x..", "..self.y..")"
end

function Point2D:Append(p, dist)
	return p + Point2D(p - self):Normalize() * dist
end

function Point2D:Clone()
	return Point2D(self.x, self.y)
end

function Point2D:DistanceSquared(p)
	local dx, dy = p.x - self.x, p.y - self.y
	return dx * dx + dy * dy
end

function Point2D:Distance(p)
	if not p then
		local dInfo = debug.getinfo(2)
		print(dInfo.name .. "  Line: " .. dInfo.linedefined)
	end
	return math.sqrt(self:DistanceSquared(p))
end

function Point2D:Extend(p, dist)
	return self + Point2D(p - self):Normalize() * dist
end

function Point2D:LengthSquared(p)
	local p = p and Point2D(p) or self
	return p.x * p.x + p.y * p.y
end

function Point2D:Length(p)
	return math.sqrt(self:LengthSquared(p))
end

function Point2D:Normalize()
	local len = self:Length()
	return Point2D(self.x / len, self.y / len)
end

function Point2D:Perpendicular()
	return Point2D(-self.y, self.x)
end

function Point2D:Perpendicular2()
	return Point2D(self.y, -self.x)
end

function Point2D:Rotate(phi, p)
	local c, s = math.cos(phi), math.sin(phi)
	local p = p or Point2D()
	local diff = Point2D(self - p)
	return Point2D(c * diff.x - s * diff.y +
		p.x, s * diff.x + c * diff.y + p.y)
end

function Point2D:Round()
	return Point2D(Round(self.x), Round(self.y))
end

-- Spell Database

local SpellDatabase = {
	["Ashe"] = {
		["Volley"] = {
			DisplayName = "Volley",
			MissileName = "VolleyRightAttack",
			Type = "Conic",
			Slot = "W",
			Speed = 2000,
			Range = 1200,
			Delay = 0.25,
			Radius = 20,
			Angle = 40,
			DangerLevel = 2,
			CC = true,
			Collision = false,
			Exception = false,
			Dangerous = false,
			FixedRange = true,
			FOW = true,
			WindWall = true,
		}
	},
	["Ryze"] = {
		["RyzeQ"] = {
			DisplayName = "Overload",
			MissileName = "RyzeQ",
			Type = "Linear",
			Slot = "Q",
			Speed = 1700,
			Range = 1000,
			Delay = 0.25,
			Radius = 55,
			DangerLevel = 1,
			CC = false,
			Collision = true,
			Exception = false,
			Dangerous = false,
			FixedRange = true,
			FOW = true,
			WindWall = true
		}
	}
}

-- Menu

--[[
	[Keys]
	[General Options]
	[Evade Spells]
		[Brand]
			- Sear (Q)
			- Pillar of Flame [W]
				- Enable Drawing
				- Enable in Standard Mode
				- Enable in Combat Mode
				- Minimum Health to Evade (%)
				- Enable Dash Usage
				- Enable Flash Usage
		[Global]
			- Hextech Protobelt-01 [Item]
			- Tentacle Knockup [Baron]
			- Acid Pool [Baron]
			- Hextech GLP-800 [Item]
			- Acid Shot [Baron]
			- Mark & Poro Toss [Summoner]
	[Drawing Options]
	[Spell Usage]
	[Spell Blocking]
--]]

local Evade = Class()

function Evade:__init()
	self.Enemies, self.Spells, self.Evading, self.MyHeroPos, self.SafePos, self.BoundingRadius,
		self.EvadeTimer, self.Height, self.Quality = {}, {}, false, nil, nil, 0, 0, 0, 16
	self.IconSite = "https://raw.githubusercontent.com/Ark223/LoL-Icons/master/"
	self.MenuIcon = "https://www.edgecumbe.co.uk/wp-content/uploads/360-Feedback.png"
	self.EvadeMenu = MenuElement({type = MENU, id = "360Evade", name = "360Evade", leftIcon = self.MenuIcon})
	self.EvadeMenu:MenuElement({id = "Core", name = "Core Settings", type = MENU})
	self.EvadeMenu.Core:MenuElement({id = "Step", name = "Angle Search Step", drop = {5, 10, 15, 20, 30, 45}, value = 4})
	self.EvadeMenu.Core:MenuElement({id = "Ping", name = "Average Game Ping", value = 50, min = 0, max = 250, step = 5})
	self.EvadeMenu.Core:MenuElement({id = "Quality", name = "Circle Segments Quality", value = 16, min = 10, max = 25, step = 1})
	self.EvadeMenu.Core:MenuElement({id = "Interval", name = "Path Update Interval", value = 125, min = 100, max = 500, step = 25})
	self.EvadeMenu:MenuElement({id = "Main", name = "Main Settings", type = MENU})
	self.EvadeMenu.Main:MenuElement({id = "Dodge", name = "Dodge Spells", value = true})
	self.EvadeMenu.Main:MenuElement({id = "Draw", name = "Draw Spells", value = true})
	self.EvadeMenu.Main:MenuElement({id = "MisDet", name = "Detect Missiles", value = true})
	self.EvadeMenu.Main:MenuElement({id = "Debug", name = "Debug Mode [Z]", value = false})
	self.EvadeMenu:MenuElement({id = "Spells", name = "Spell Settings", type = MENU})
	self:LoadEnemyHeroData()
	for i, data in ipairs(self.Enemies) do
		local enemy = data.Enemy.charName
		if SpellDatabase[enemy] then
			for j, spell in pairs(SpellDatabase[enemy]) do
				self.EvadeMenu.Spells:MenuElement({id = j, name = enemy .. " [" .. spell.Slot .. "] (" ..
					spell.DisplayName .. ")", type = MENU}) --, leftIcon = self.IconSite .. enemy .. spell.Slot .. ".png"
				self.EvadeMenu.Spells[j]:MenuElement({id = "Dodge" .. j, name = "Dodge", value = true})
				self.EvadeMenu.Spells[j]:MenuElement({id = "Draw" .. j, name = "Draw", value = true})
				self.EvadeMenu.Spells[j]:MenuElement({id = "Dangerous" .. j, name = "Dangerous", value = true})
				self.EvadeMenu.Spells[j]:MenuElement({id = "Danger" .. j,
					name = "Danger Level", value = (spell.DangerLevel or 1), min = 1, max = 5, step = 1})
			end
		end
	end
	Callback.Add("Tick", function() self:OnTick() end)
	Callback.Add("Draw", function() self:OnDraw() end)
	Callback.Add("WndMsg", function(...) self:OnWndMsg(...) end)
	if _G.SDK then
		_G.SDK.Orbwalker:OnPreAttack(function(...) self:OnPreAttack(...) end)
		_G.SDK.Orbwalker:OnPreMovement(function(...) self:OnPreMovement(...) end)
	elseif _G.PremiumOrbwalker then
		_G.PremiumOrbwalker:OnPreAttack(function(...) self:OnPreAttack(...) end)
		_G.PremiumOrbwalker:OnPreMovement(function(...) self:OnPreMovement(...) end)
	end
	print("360Evade successfully loaded! Have fun!")
end

-- Geometry

function Evade:AngleBetween(p1, p2, p3)
	local angle = math.deg(math.atan2(p3.y - p1.y, p3.x -
		p1.x) - math.atan2(p2.y - p1.y, p2.x - p1.x))
	return angle < 0 and angle + 360 or angle
end
-----------------------------------------------------------------------------------------------

function Evade:ArcToPolygon(p1, p2, angle)
	local angle, result = math.rad(angle) * 0.5, {}
	for i = -angle, angle, angle * 0.5 do
		table.insert(result, p2:Rotate(i, p1):Round())
	end
	return result
end
-----------------------------------------------------------------------------------------------

function Evade:Area(poly)
	local size = #poly
	if size < 3 then return 0 end
	local j, a = size, 0
	for i = 1, size do
		a = a + (poly[j].x + poly[i].x) *
			(poly[j].y - poly[i].y)
		j = i
	end
	return -a * 0.5
end
-----------------------------------------------------------------------------------------------

function Evade:CalculateDynamicPosition(spell, time)
	local t = Game.Timer() - spell.StartTime - spell.Delay + (time or 0)
	return t <= 0 and spell.StartPos or spell.StartPos:Extend(spell.EndPos,
		math.min(spell.StartPos:Distance(spell.EndPos), spell.Speed * t))
end
-----------------------------------------------------------------------------------------------

function Evade:CircleToPolygon(center, radius, quality)
	local result = {}
	for i = 0, (quality or 16) - 1 do
		local angle = 2 * math.pi / quality * (i + 0.5)
		local cx, cy = center.x + radius * math.cos(angle),
			center.y + radius * math.sin(angle)
		table.insert(result, Point2D(cx, cy):Round())
	end
	return result
end
-----------------------------------------------------------------------------------------------

function Evade:ClosestDistanceToLine(pt, s1, s2)
	local ap, ab = Point2D(pt - s1), Point2D(s2 - s1)
	return self:DotProduct(ap, ab) / ab:Length()
end
-----------------------------------------------------------------------------------------------

function Evade:ClosestPointOnSegment(pt, s1, s2)
	local ap, ab = Point2D(pt - s1), Point2D(s2 - s1)
	local t = self:DotProduct(ap, ab) / ab:LengthSquared()
	return t < 0 and s1 or t > 1 and s2 or Point2D(s1 + ab * t)
end
-----------------------------------------------------------------------------------------------

function Evade:ConvexHull(points)
	local size = #points
	if size < 3 then return end
	table.sort(points, function(a, b) return a.x < b.x end)
	local result = {}
	for i, point in ipairs(points) do
		while #result >= 2 and not self:IsCounterClockwise(
			result[#result - 1], result[#result], point) do
				table.remove(result, #result)
		end
		table.insert(result, point)
	end
	local t = #result + 1
	for i = size, 1, -1 do
		local point = points[i]
		while #result >= t and not self:IsCounterClockwise(
			result[#result - 1], result[#result], point) do
				table.remove(result, #result)
		end
		table.insert(result, point)
	end
	table.remove(result, #result)
	return result
end
-----------------------------------------------------------------------------------------------

function Evade:CrossProduct(p1, p2)
	return p1.x * p2.y - p1.y * p2.x
end
-----------------------------------------------------------------------------------------------

function Evade:DotProduct(p1, p2)
	return p1.x * p2.x + p1.y * p2.y
end
-----------------------------------------------------------------------------------------------

function Evade:DrawPolygon(poly, width, color)
	local size = #poly
	if size < 3 then return end
	local j = size
	for i = 1, size do
		Draw.Line(poly[i].x, poly[i].y,
			poly[j].x, poly[j].y, width, color)
		j = i
	end
end
-----------------------------------------------------------------------------------------------

function Evade:FixEndPosition(data)
	if not data.FixedRange then
		if data.Range == 0 then return data.StartPos end
		if data.StartPos:Distance(data.EndPos) < data.Range then return data.EndPos end
	end
	if data.Collision then
		local startPos, minions = data.StartPos:Extend(data.EndPos, 45), {}
		for i = 1, Game.MinionCount() do
			local minion = Game.Minion(i)
			local minionPos = Point2D(minion.pos)
			if minion and minion.valid and minion.visible and minion.team == myHero.team and
				startPos:Distance(minionPos) <= data.Range and minion.maxHealth > 295 and minion.health > 5 then
					local col = self:ClosestPointOnSegment(minionPos, startPos, data.EndPos)
					if col and minionPos:Distance(col) < (minion.boundingRadius or 45) + data.Radius then
						table.insert(minions, minionPos)
				end
			end
		end
		table.sort(minions, function(a, b) return
			startPos:DistanceSquared(a) < startPos:DistanceSquared(b) end)
		if #minions > 0 then return minions[1] end
	end
	return data.StartPos:Extend(data.EndPos, data.Range)
end
-----------------------------------------------------------------------------------------------

function Evade:GetBestEvadePos()
	local extended = self.MyHeroPos:Extend(Point2D(mousePos), 5000)
	for i = 0, 180, self.EvadeMenu.Core.Step:Value() do
		local theta = math.rad(i)
		for j = 1, (i == 0 and 1 or 2) do
			local candidate = i == 0 and extended or
				extended:Rotate(theta, self.MyHeroPos):Round()
			local safe, pos = self:IsSafePath(candidate)
			if safe then return pos end
			theta = theta * -1
		end
	end
	return nil
end
-----------------------------------------------------------------------------------------------

function Evade:GetPath(data)
	if data.Type == "Linear" then
		return self:RectangleToPolygon(data.StartPos, data.EndPos, data.Radius)
	elseif data.Type == "Circular" then
		return self:CircleToPolygon(data.EndPos, data.Radius, self.Quality)
	elseif data.Type == "Conic" then
		return table.push(self:ArcToPolygon(data.StartPos, data.EndPos, data.Angle), {data.StartPos})
	elseif data.Type == "Rectangular" then
		local dir = Point2D(data.EndPos - data.StartPos):Perpendicular():Normalize() * data.Radius2
		return self:RectangleToPolygon(Point2D(data.EndPos - dir), Point2D(data.EndPos + dir), data.Radius)
	end
	-- Special spells
end
-----------------------------------------------------------------------------------------------

function Evade:Intersection(s1, s2, c1, c2, line)
	local a, b, c = Point2D(s2 - s1), Point2D(c2 - c1), Point2D(c1 - s1)
	local d = self:CrossProduct(a, b); if d == 0 then return nil end
	local t1, t2 = self:CrossProduct(c, b) / d, self:CrossProduct(c, a) / d
	return (t1 > 0 and t1 < 1 and t2 > 0 and t2 < 1 or line ~= nil) and Point2D(s1 + a * t1) or nil
end
-----------------------------------------------------------------------------------------------

function Evade:IsCounterClockwise(p1, p2, p3)
	return self:CrossProduct(Point2D(p2 - p1), Point2D(p3 - p1)) > 0
end
-----------------------------------------------------------------------------------------------

function Evade:IsInDangerousArea(pos)
	for i, spell in ipairs(self.Spells) do
		if not self:IsSafePos(pos, spell) then
			return true
		end
	end
	return false
end
-----------------------------------------------------------------------------------------------

function Evade:IsPointInPolygon(point, poly)
	local result, j = false, #poly
	for i = 1, #poly do
		local a, b = poly[i], poly[j]
		if a.y < point.y and b.y >= point.y or b.y < point.y and a.y >= point.y then
			if a.x + (point.y - a.y) / (b.y - a.y) * (b.x - a.x) < point.x then
				result = not result
			end
		end
		j = i
	end
	return result
end
-----------------------------------------------------------------------------------------------

function Evade:IsSafePos(pos, spell)
	return not self:IsPointInPolygon(pos, spell.OffsetPath)
end
-----------------------------------------------------------------------------------------------

function Evade:IsSafePath(destination)
	local safety = self:Latency() + 0.07
	local moveSpeed, safe = myHero.ms or 315, {}
	for i, spell in ipairs(self.Spells) do
		local ints = self:PathIntersection({
			self.MyHeroPos, destination}, spell.OffsetPath)
		local size = #ints
		if size == 0 then
			table.insert(safe, destination)
				goto continue end
		local int = ints[size]
		if size > 1 and self.MyHeroPos:DistanceSquared(ints[1]) >
			self.MyHeroPos:DistanceSquared(int) then int = ints[1] end
		local dist = self.MyHeroPos:Distance(int)
		if spell.Speed ~= math.huge and spell.Type == "Linear" then
			local pos = self:CalculateDynamicPosition(spell, dist / moveSpeed + safety)
			local closest = self:ClosestPointOnSegment(int, spell.Position, pos)
			if spell.StartPos ~= pos and int:Distance(closest) <=
				self.BoundingRadius + spell.Radius + 1 then return false, nil
			end
		else
			local t = math.max(0, Game.Timer() - spell.StartTime + spell.Delay - safety)
			local futurePos = self.MyHeroPos:Extend(destination, moveSpeed * t)
			if not self:IsSafePos(futurePos, spell) then return false, nil end
		end
		int = self.MyHeroPos:Append(int, 5):Round()
		table.insert(safe, int)
		::continue::
	end
	for i = #safe, 1, -1 do
		if self:IsInDangerousArea(safe[i]) then
			table.remove(safe, i)
		end
	end
	table.sort(safe, function(a, b) return
		self.MyHeroPos:DistanceSquared(a) <
		self.MyHeroPos:DistanceSquared(b)
	end)
	return #safe > 0, safe[1] or nil
end
-----------------------------------------------------------------------------------------------

function Evade:OffsetPath(path, delta)
	local delta = delta or self.BoundingRadius
	local steps = math.sqrt(delta) / math.pi * 2
	local result, j, k = {}, #path, #path - 1
	for i = 1, #path do
		local a, b, c = path[k], path[j], path[i]
		local inside = self:IsPointInPolygon(c:Append(b, 2):Round(), path)
		local d1, d2 =
			Point2D(b - a):Normalize():Perpendicular2() * delta,
			Point2D(c - b):Normalize():Perpendicular2() * delta
		local int = self:Intersection(
			Point2D(a + d1), Point2D(b + d1),
			Point2D(b + d2), Point2D(c + d2), true):Round()
		if not inside then
			local ex = b:Extend(int, delta)
			local angle = 90 - self:AngleBetween(b, a, c) * 0.5
			for i = angle, -angle, -math.min(angle, 90 / steps) do
				table.insert(result, ex:Rotate(math.rad(i), b))
			end
		else
			int = b:Append(int, b:Distance(int))
			local ex = int:Extend(b, delta)
			local angle = self:AngleBetween(b, a, c) * 0.5 - 90
			for i = -angle, angle, math.min(angle, 90 / steps) do
				table.insert(result, ex:Rotate(math.rad(i), int))
			end
		end
		k = j; j = i
	end
	return result
end
-----------------------------------------------------------------------------------------------

function Evade:Orientation(poly)
	return self:Area(poly) >= 0
end
-----------------------------------------------------------------------------------------------

function Evade:PathIntersection(path1, path2)
	local result, j = {}, #path2
	for i = 1, #path2 do
		local a, b = path2[i], path2[j]
		local int = self:Intersection(path1[1], path1[2], a, b)
		if int ~= nil then table.insert(result, int) end
		j = i
	end
	return result
end
-----------------------------------------------------------------------------------------------

function Evade:RectangleToPolygon(p1, p2, radius)
	local dir = Point2D(p2 - p1):Normalize():Perpendicular() * radius
	return {Point2D(p1 + dir), Point2D(p1 - dir), Point2D(p2 - dir), Point2D(p2 + dir)}
end
-----------------------------------------------------------------------------------------------

function Evade:ReversePath(path)
	local i, j = 1, #path
	while i < j do
		path[i], path[j] = path[j], path[i]
		i, j = i + 1, j - 1
	end
end
-----------------------------------------------------------------------------------------------

function Evade:To3D(pos)
	return Vector(pos.x, self.Height, pos.y)
end
-----------------------------------------------------------------------------------------------

function Evade:ToScreen(pos)
	return Vector(self:To3D(pos)):To2D()
end

-- Manager

function Evade:CopyTable(tab)
	local copy = {}
	for key, val in pairs(tab) do
		copy[key] = val end
	return copy
end
-----------------------------------------------------------------------------------------------

function Evade:CreateNewSpell(data, unit)
	local path = data.Path or self:GetPath(data)
	table.insert(self.Spells, {
		Name = data.Name,
		Unit = unit or nil,
		StartTime = Game.Timer() - self:Latency(),
		StartPos = data.StartPos,
		EndPos = data.EndPos,
		Position = data.StartPos,
		Path = path,
		OffsetPath = self:OffsetPath(path),
		Speed = data.Speed,
		Range = data.Range,
		Delay = data.Delay,
		Radius = data.Radius,
		Radius2 = data.Radius2 or 0,
		Angle = data.Angle or 0,
		Type = data.Type
	})
	self.EvadeTimer = 0
end
-----------------------------------------------------------------------------------------------

function Evade:Latency()
	return self.EvadeMenu.Core.Ping:Value() / 2000
end
-----------------------------------------------------------------------------------------------

function Evade:LoadEnemyHeroData()
	for i = 1, Game.HeroCount() do
		local enemy = Game.Hero(i)
		if enemy and enemy.isEnemy then
			table.insert(self.Enemies,
			{Enemy = enemy, ActiveSpell = ""})
		end
	end
end
-----------------------------------------------------------------------------------------------

function Evade:MoveToPos(pos)
	local dodge = self.MyHeroPos:Append(
		pos, self.BoundingRadius * 2)
	if _G.SDK and _G.Control.Evade then
		_G.Control.Evade(self:To3D(dodge)); return
	end
	local pos = self:ToScreen(dodge)
	Control.SetCursorPos(pos.x, pos.y)
	Control.mouse_event(MOUSEEVENTF_RIGHTDOWN)
	Control.mouse_event(MOUSEEVENTF_RIGHTUP)
end
-----------------------------------------------------------------------------------------------

function Evade:SwitchOff()
	self.Evading, self.SafePos = false, nil
end
-----------------------------------------------------------------------------------------------

function Evade:UpdateSpells()
	for i, spell in ipairs(self.Spells) do
		if Game.Timer() - spell.StartTime >
			spell.Range / spell.Speed + spell.Delay then
				table.remove(self.Spells, i); return
		end
		if spell.Speed ~= math.huge then
			if spell.Type == "Linear" then
				spell.Position = self:CalculateDynamicPosition(spell)
				if spell.Position ~= spell.StartPos then
					spell.Path = self:RectangleToPolygon(
						spell.Position, spell.EndPos, spell.Radius)
					spell.OffsetPath = self:OffsetPath(spell.Path)
				end
			elseif spell.Type == "Conic" then
				spell.Position = self:CalculateDynamicPosition(spell)
				if spell.Position ~= spell.StartPos then
					local border = self:ArcToPolygon(spell.StartPos,
						spell.Position, spell.Angle); self:ReversePath(border)
					spell.Path = table.push(border, self:ArcToPolygon(
						spell.StartPos, spell.EndPos, spell.Angle))
					spell.OffsetPath = self:OffsetPath(spell.Path)
				end
			end
		end
	end
end

-- Callbacks

function Evade:OnTick()
	self.MyHeroPos, self.BoundingRadius, self.Height, self.Quality = Point2D(myHero.pos),
		myHero.boundingRadius or 65, myHero.pos.y, self.EvadeMenu.Core.Quality:Value() or 16
	for i, data in ipairs(self.Enemies) do
		local unit = data.Enemy; local spell = unit.activeSpell
		if unit.valid and not unit.dead and spell and spell.valid and
			spell.isChanneling and data.ActiveSpell ~= spell.name .. spell.endTime then
				data.ActiveSpell = spell.name .. spell.endTime
				self:OnProcessSpell(unit, spell)
		end
	end
	if self:IsInDangerousArea(self.MyHeroPos) then
		if Game.Timer() - self.EvadeTimer >=
			self.EvadeMenu.Core.Interval:Value() * 0.001 then
			local evadePos = self:GetBestEvadePos()
			if evadePos ~= nil then
				self.EvadeTimer, self.Evading, self.SafePos =
					Game.Timer(), true, evadePos
				self:MoveToPos(evadePos); return
			end
			self:SwitchOff()
			-- Impossible dodge
		end
		return
	end
	self:SwitchOff()
end

function Evade:OnProcessSpell(unit, spell)
	local unit, name = unit.charName, spell.name
	if SpellDatabase[unit] and SpellDatabase[unit][name] then
		local data = self:CopyTable(SpellDatabase[unit][name])
		if data.Exception then return end
		data.StartPos = Point2D(spell.startPos)
		data.EndPos = Point2D(spell.placementPos)
		data.EndPos = not data.InternalFix and self:FixEndPosition(data)
			or Point2D(unit.pos) + Point2D(unit.dir) * data.Range
		data.Range = data.StartPos:Distance(data.EndPos)
		data.Name = name; self:CreateNewSpell(data, unit)
	end
end

function Evade:OnDraw()
	self:UpdateSpells()
	if self.EvadeMenu.Main.Draw:Value() then
		for i, s in ipairs(self.Spells) do
			if s.Name == "Test" or self.EvadeMenu.Spells[s.Name]["Draw"..s.Name] then
				local path, offset = {}, {}
				for j, point in ipairs(s.Path) do
					table.insert(path, self:ToScreen(point))
				end
				for j, point in ipairs(s.OffsetPath) do
					table.insert(offset, self:ToScreen(point))
				end
				self:DrawPolygon(path, 1, Draw.Color(224, 255, 255, 255))
				self:DrawPolygon(offset, 0.1, Draw.Color(128, 255, 255, 255))
				if self.SafePos then Draw.Circle(self:To3D(self.SafePos),
					self.BoundingRadius, 1, Draw.Color(128, 255, 255, 0)) end
			end
		end
	end
end

function Evade:OnWndMsg(msg, wParam)
	if not self.EvadeMenu.Main.Debug:Value() or not
		(msg == 256 and wParam == 90) then return end
	local edge = math.random(0, 1)
	local startPos = edge == 0 and
		Point2D(math.random(1400, 1500), math.random(600, 1300))
	or Point2D(math.random(3200, 3300), math.random(600, 1300))
	local endPos = edge == 0 and
		Point2D(math.random(3200, 3300), math.random(600, 1300))
	or Point2D(math.random(1400, 1500), math.random(600, 1300))
	local dist = startPos:Distance(endPos)
	self:CreateNewSpell({
		Name = "Test",
		StartPos = startPos,
		EndPos = endPos,
		Speed = math.random(1200, 1600),
		Range = dist,
		Delay = 0.25,
		Radius = 60,
		Type = "Linear"
	})
end

function Evade:OnPreAttack(args)
	if self.Evading then args.Process = false end
end

function Evade:OnPreMovement(args)
	if self.Evading then args.Process = false; return end
	if not self:IsInDangerousArea(self.MyHeroPos) then
		local intersects, points = false, {}
		for i, spell in ipairs(self.Spells) do
			for i, point in ipairs(spell.OffsetPath) do
				table.insert(points, point)
			end
			if not intersects then
				local ints = self:PathIntersection({self.MyHeroPos,
					Point2D(args.Target)}, spell.OffsetPath)
				if #ints > 0 then intersects = true end
			end
		end
		if intersects then
			local hull = self:ConvexHull(points)
			table.sort(hull, function(a, b) return
				self.MyHeroPos:DistanceSquared(a) <
				self.MyHeroPos:DistanceSquared(b)
			end)
			args.Target = self:To3D(
				self.MyHeroPos:Append(hull[1], -5):Round())
		end
	end
end

do
	print("Loading 360Evade...")
	DelayAction(function()
		Evade:__init()
	end, math.max(0.07, 30 - Game.Timer()))
end

