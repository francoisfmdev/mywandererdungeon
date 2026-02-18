-- data/xp_table.lua - XP total requis par niveau (1 a 100)
-- xpToReach[level] = XP total pour atteindre ce niveau
-- Progression: base 10, delta +50 par niveau (niveau 2 = 100, 3 = 250, etc.)
local t = {}
local xp = 0
for level = 1, 100 do
  t[level] = xp
  xp = xp + 50 * (level + 1)
end
return t
