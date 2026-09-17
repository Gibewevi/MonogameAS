-- Appelé dans game_planet.lua et gui.lua
local technology = require("skills/technology")
local skillTree = {}

local currentTree = "technology"
local tree = {}
local totalCategory = 0
local open = false
local x, y = RESO_WIDTH/2, RESO_HEIGHT/2
local category = 0
local categoryAngle = 0
local radius_lvl1 = 180
local radius_lvl2 = 300

-- Pour un arbre de compétence, controler le nombre de branche / catégorie


-- Adapter la découpe de l'arbre en conséquence
function skillTree.loadTechnology()
  if currentTree == "technology" then
    totalCategory = technology.category
    categoryAngle = technology.categoryAngle
    tree = technology
  end
end
  
function skillTree.open()
  if open == false then
    open = true
    technology:coordinatesAttribution(x, y, radius_lvl1)
    skillTree.loadTechnology()
  else open = false end
end

function skillTree.update(dt)
  if open then
    if totalCategory > 1 then
      for i=1, totalCategory do
        for j=1, #tree[i] do
          tree[i][j].icon:update(dt)
        end
      end
    end
  end
end

function skillTree.draw()
  if open then
    local x1, y1, x2, y2 = 0
    local angle = 0
    -- Premier niveau de compétences
    love.graphics.setLineWidth(3)
    love.graphics.setColor(255,255,255,35)
    love.graphics.circle("line", x, y, radius_lvl1)
    love.graphics.setColor(255,255,255,35)
    love.graphics.circle("line", x, y, radius_lvl2)
    love.graphics.setColor(255, 255, 255, 35)
    -- Découpage des différentes catégories en tranches
    if totalCategory > 1 then
      for i=1, totalCategory do
        x1 = x
        y1 = y
        x2 = x + math.cos(angle) * radius_lvl1
        y2 = y + math.sin(angle) * radius_lvl1
        
        love.graphics.setLineWidth(2)
        love.graphics.setColor(255,255,255,20)
        love.graphics.line(x1, y1, x2, y2)
        
        angle = angle + categoryAngle
        
        for j=1, #tree[i] do
          tree[i][j].icon:draw()
        end
      end
    end
  end
end

return skillTree