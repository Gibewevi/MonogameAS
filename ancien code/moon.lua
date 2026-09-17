moon = {}

local grid = require("grid")


function moon.new(pRadiusPlanet,pId,pShadowXPlanet)
  local newMoon = {}
  -- paramètres globaux
  newMoon.pId = pId 
  newMoon.xPlanet = width/2
  newMoon.yPlanet = height/2
  newMoon.xShadowPlanet = pShadowXPlanet or 0
  newMoon.rPlanet = pRadiusPlanet
  newMoon.pole = false
  newMoon.type = "telluric"
  -- paramètres génération procédurale
  newMoon.luck = 43
  newMoon.birth = 4
  newMoon.death = 2
  -- couleurs
  newMoon.color = {}
    -- couleurs lune
  newMoon.color.first = { math.random(0,255), math.random(0,255), math.random(0,255),255}
  newMoon.color.second = { math.random(0,255), math.random(0,255), math.random(0,255),255}
  newMoon.color.third = { math.random(0,255), math.random(0,255), math.random(0,255),255}
  newMoon.color.fourth = { math.random(0,255), math.random(0,255), math.random(0,255),255}
    -- couleurs pôle
  newMoon.poleColor = {}
  newMoon.poleColor.first = {255,255,255}
  newMoon.poleColor.second = {255,255,255}  
  -- orbital speed
  -- paramètre vue planet
  newMoon.os = math.random(1, 5) / 1000
  newMoon.planetView = {}
  newMoon.planetView.lines = nil


  local size = {8,10,12,14}
  local random = math.random(1,#size)
  newMoon.planetView.radius = size[random]

  newMoon.planetView.orbiteMax = (500000) --km

  -- repère km Terre-Lune 384 400km = width
  local planetRadiusKm =(((pRadiusPlanet*newMoon.planetView.orbiteMax))/((width/2)))
  newMoon.planetView.rxMin = newMoon.planetView.radius + pRadiusPlanet
  newMoon.planetView.rxMax = width/2
  newMoon.planetView.ryMax = width/16 
  newMoon.planetView.ryMin = newMoon.planetView.radius 

  
  newMoon.planetView.rx = math.random(newMoon.planetView.rxMin,newMoon.planetView.rxMax)
  newMoon.planetView.ry = newMoon.planetView.rx/8

  newMoon.planetView.cellSize = 4 --TESTER 2
  
  newMoon.planetView.angle = 0--1*(math.pi/2)
  newMoon.planetView.orbitalSpeed = 0.02-- math.random(1, 5) / 1000 
  newMoon.planetView.x = newMoon.xPlanet + newMoon.planetView.rx * math.cos(newMoon.planetView.angle)
  newMoon.planetView.y = newMoon.yPlanet + newMoon.planetView.ry * math.sin(newMoon.planetView.angle)
  newMoon.planetView.shadeGradient = 4
  newMoon.planetView.diameter = (newMoon.planetView.radius*2)
  newMoon.planetView.line = math.floor(newMoon.planetView.diameter/newMoon.planetView.cellSize) 
  newMoon.planetView.column = math.floor(newMoon.planetView.diameter/newMoon.planetView.cellSize)
  newMoon.planetView.ground = {}
  newMoon.planetView.shadow = {}

 local function ShadowXUpdate(PxSha)
    local w = (newMoon.rPlanet*6)
    local posX = PxSha - (newMoon.xPlanet - (3*newMoon.rPlanet)) 
    local x_shadow_moon =  (newMoon.planetView.x-3*newMoon.planetView.radius) + ((posX*newMoon.planetView.radius*6))/(w)
    return x_shadow_moon
  end

 

  newMoon.planetView.shadow_x = ShadowXUpdate(newMoon.xShadowPlanet)
  newMoon.planetView.ellipse = {}
  newMoon.planetView.ellipse.cell = newMoon.planetView.cellSize/2
  newMoon.planetView.ellipse.line = math.ceil((newMoon.planetView.ry*2)/newMoon.planetView.ellipse.cell) 
  newMoon.planetView.ellipse.column = math.ceil((newMoon.planetView.rx*2)/newMoon.planetView.ellipse.cell)
  newMoon.planetView.ellipse.x =  newMoon.xPlanet - newMoon.planetView.rx 
  newMoon.planetView.ellipse.y =  newMoon.yPlanet - newMoon.planetView.ry
  newMoon.planetView.ellipse.w = newMoon.planetView.ellipse.line*newMoon.planetView.ellipse.cell
  newMoon.planetView.ellipse.h = newMoon.planetView.ellipse.column*newMoon.planetView.ellipse.cell
  newMoon.planetView.ellipse.grid =  {}


  function newMoon:generate(Pluck,Pbirth,Pdeath)
    
    -- génération des grilles
    -- Initialisation de la grille 
    
        self.planetView.ground = grid.init(self.type, self.planetView.line, self.planetView.column, self.luck, self.birth, self.death)

      -- génération continents
        self.planetView.ground = grid.initContinent(self.planetView.ground, self.type, self.planetView.line, self.planetView.column, self.luck, self.birth, self.death)
        
      -- génération océans
        self.planetView.ground = grid.initOcean(self.planetView.ground, self.planetView.line, self.planetView.column)      

    -- Découpage de la grille circulaire
        self.planetView.ground = grid.toCircle(self.planetView.ground, self.planetView.x, self.planetView.y, self.planetView.radius, self.planetView.cellSize, self.planetView.line, self.planetView.column)    
        
    -- génération ombre --------------------------
    -- Génération de la grille des ombres
    self.planetView.shadow = grid.initShadow(self.planetView.x, self.planetView.y, 0,self.planetView.radius,self.planetView.line,self.planetView.column,self.planetView.cellSize,self.planetView.shadeGradient)

        
    -- Génération de l'ellipse de révolution
    self.planetView.ellipse.grid = grid.ellipse(self.xPlanet, self.yPlanet, self.planetView.ellipse.x,self.planetView.ellipse.y, self.planetView.rx, self.planetView.ry,self.planetView.ellipse.cell, self.planetView.ellipse.line, self.planetView.ellipse.column)

  end
  
  
  function newMoon:setSize(pSize)
  newMoon.planetView.radius = pSize
  end
  
  function newMoon:setColor(P1,P2,P3,P4,P5,P6,P7,P8,P9,P10,P11,P12)
    local r,g,b
    
        -- couleurs lune
  newMoon.color.first = {P1,P2,P3,255}
  newMoon.color.second = {P4,P5,P6,255}
  newMoon.color.third = {P7,P8,P9,255}
  newMoon.color.fourth = {P10,P11,P12,255}
    
  end
  
  
  function newMoon:updateRotation(dt)
   self.planetView.angle = self.planetView.angle - newMoon.planetView.orbitalSpeed
   self.planetView.x = self.xPlanet + self.planetView.rx * math.cos(self.planetView.angle) 
   self.planetView.y = self.yPlanet + self.planetView.ry * math.sin(self.planetView.angle)
  end
  
  function newMoon:setPlanetDistance()

  -- repère km Terre-Lune 384 400km = width
  newMoon.planetView.rx = math.random(newMoon.planetView.rxMin,newMoon.planetView.rxMax)
  newMoon.planetView.ry = newMoon.planetView.rx/8 
  newMoon.planetView.x = newMoon.xPlanet + newMoon.planetView.rx * math.cos(newMoon.planetView.angle)
  newMoon.planetView.y = newMoon.yPlanet + newMoon.planetView.ry * math.sin(newMoon.planetView.angle)
  newMoon.planetView.ellipse.x =  newMoon.xPlanet - newMoon.planetView.rx 
  newMoon.planetView.ellipse.y =  newMoon.yPlanet - newMoon.planetView.ry
  newMoon.planetView.shadow_x = ShadowXUpdate(newMoon.xShadowPlanet) 
  newMoon.planetView.ellipse.line = math.ceil((newMoon.planetView.ry*2)/newMoon.planetView.ellipse.cell) 
  newMoon.planetView.ellipse.column = math.ceil((newMoon.planetView.rx*2)/newMoon.planetView.ellipse.cell)
  self.planetView.ellipse.grid = grid.ellipse(self.xPlanet, self.yPlanet, self.planetView.ellipse.x,self.planetView.ellipse.y, self.planetView.rx, self.planetView.ry,self.planetView.ellipse.cell, self.planetView.ellipse.line, self.planetView.ellipse.column)
  end
  
  
  function newMoon:shadowUpdate(pShadow_x)
    -- Actualisation de la position des ombres par rapport à la planète
    self.planetView.shadow_x = ShadowXUpdate(pShadow_x) 
  end
  
  function newMoon:update(dt)

-- Actualisation de la position des ombres par rapport à la planète

self.planetView.shadow = grid.initShadowPlanetView(self.planetView.x, self.planetView.y,self.planetView.shadow_x, self.planetView.radius, self.planetView.line, self.planetView.column, self.planetView.cellSize, self.planetView.shadeGradient)  

self.planetView.shadow = grid.toCircle(self.planetView.shadow, self.planetView.x, self.planetView.y, self.planetView.radius, self.planetView.cellSize, self.planetView.line, self.planetView.column, 0)

  end
    
  function newMoon:drawEllipse(pFace)

     local ellipse = newMoon.planetView.ellipse
     local x = newMoon.xPlanet - newMoon.planetView.rx
     local y = newMoon.yPlanet - newMoon.planetView.ry

    if pFace == "front"  then
     for l=1,ellipse.line do
       for c=1,ellipse.column do
          if y>=height/2 then
            if ellipse.grid[l][c] == 1 then
              love.graphics.setColor(255,255,255,30)
              love.graphics.rectangle("fill", x,y,ellipse.cell, ellipse.cell)
            end
            x = (c* ellipse.cell ) + ellipse.x
          end
       end
           x = ellipse.x
           y = (l* ellipse.cell ) + ellipse.y
       end
    end
    
    if pFace == "back" then
     for l=1,ellipse.line do
       if y<height/2 then 
         for c=1,ellipse.column do
            if ellipse.grid[l][c] == 1 then
              love.graphics.setColor(255,255,255,30)
              love.graphics.rectangle("fill", x,y,ellipse.cell, ellipse.cell)
            end
            x = (c* ellipse.cell ) + ellipse.x
          end
        end
             x = ellipse.x
             y = (l* ellipse.cell ) + ellipse.y 
      end
    end
  end
    
  function newMoon:drawShadow(pFace)
    local shadow = self.planetView.shadow
    local line = self.planetView.line
    local column = self.planetView.column
    local cellSize = self.planetView.cellSize
    local radius = self.planetView.radius
    
    
    x = self.planetView.x - radius
    y = self.planetView.y - radius
   
  if pFace == "front" then
    for l=1, line do
      for c=1, column do
        if y>= height/2 then
          if shadow[l][c] == 0 then
            love.graphics.setColor(0, 0, 0, 0)
            love.graphics.rectangle("fill", x, y, cellSize, cellSize)
          elseif shadow[l][c] == 1 then
            love.graphics.setColor(0, 0, 0, 135)
            love.graphics.rectangle("fill", x, y, cellSize, cellSize)  
          elseif shadow[l][c] == 2 then
            love.graphics.setColor(0, 0, 0, 180)
            love.graphics.rectangle("fill", x, y, cellSize, cellSize)
          elseif shadow[l][c] == 3 then
            love.graphics.setColor(0, 0, 0, 230)
            love.graphics.rectangle("fill", x, y, cellSize, cellSize)
          end
        end
        x = x + cellSize
      end
      x = self.planetView.x - radius
      y = y + cellSize
    end
  elseif pFace == "back" then
    for l=1, line do
      for c=1, column do
        if y<height/2 then
          if shadow[l][c] == 0 then
            love.graphics.setColor(0, 0, 0, 0)
            love.graphics.rectangle("fill", x, y, cellSize, cellSize)
          elseif shadow[l][c] == 1 then
            love.graphics.setColor(0, 0, 0, 135)
            love.graphics.rectangle("fill", x, y, cellSize, cellSize)  
          elseif shadow[l][c] == 2 then
            love.graphics.setColor(0, 0, 0, 180)
            love.graphics.rectangle("fill", x, y, cellSize, cellSize)
          elseif shadow[l][c] == 3 then
            love.graphics.setColor(0, 0, 0, 230)
            love.graphics.rectangle("fill", x, y, cellSize, cellSize)
          end
        end
        x = x + cellSize
      end
      x = self.planetView.x - radius
      y = y + cellSize
    end    
    
    
  end
    
  end
    
  function newMoon:draw(pFace)
    local l,c,x,y
    local moon = self.planetView.ground 
    local line = self.planetView.line 
    local column = self.planetView.column 
    local cellSize = self.planetView.cellSize
    local radius = self.planetView.radius 
    x = self.planetView.x - radius 
    y = self.planetView.y - radius
    
  if pFace == "back" then
    for l=1, line do
        for c=1, column do     
          if y<height/2 then
            if moon[l][c] == 10 then
              love.graphics.setColor(self.color.first)
              love.graphics.rectangle("fill", x, y, cellSize, cellSize)
            elseif moon[l][c] == 11 then 
              love.graphics.setColor(self.color.second)
              love.graphics.rectangle("fill", x, y, cellSize, cellSize) 
            elseif moon[l][c] == 12 then -- pole
              love.graphics.setColor(self.poleColor.first)
              love.graphics.rectangle("fill", x, y, cellSize, cellSize)  
            elseif moon[l][c] == 13 then -- pole
              love.graphics.setColor(self.poleColor.second)
              love.graphics.rectangle("fill", x, y, cellSize, cellSize)  
            elseif moon[l][c] == 20 then
              love.graphics.setColor(self.color.third)
              love.graphics.rectangle("fill", x, y, cellSize, cellSize)
            elseif moon[l][c] == 21 then
              love.graphics.setColor(self.color.fourth)
              love.graphics.rectangle("fill", x, y, cellSize, cellSize)
            elseif moon[l][c] == 30 then
              love.graphics.setColor(48,46,46,255)
              love.graphics.rectangle("fill", x, y, cellSize, cellSize)
            elseif moon[l][c] == 31 then
              love.graphics.setColor(87,78,77,255)
              love.graphics.rectangle("fill", x, y, cellSize, cellSize)
            --elseif planet[l][c] == 40 then
            --  love.graphics.setColor(233,201,62,255)
            --  love.graphics.rectangle("fill", x, y, cellSize, cellSize)        
            end
            x = x + cellSize
          end
      end
        
      x = self.planetView.x - radius
      y = y + cellSize
    end
  elseif pFace == "front" then
    for l=1, line do
      for c=1, column do
        if y>=height/2 then
          if moon[l][c] == 10 then
            love.graphics.setColor(self.color.first)
            love.graphics.rectangle("fill", x, y, cellSize, cellSize)
          elseif moon[l][c] == 11 then 
            love.graphics.setColor(self.color.second)
            love.graphics.rectangle("fill", x, y, cellSize, cellSize) 
          elseif moon[l][c] == 12 then -- pole
            love.graphics.setColor(self.poleColor.first)
            love.graphics.rectangle("fill", x, y, cellSize, cellSize)  
          elseif moon[l][c] == 13 then -- pole
            love.graphics.setColor(self.poleColor.second)
            love.graphics.rectangle("fill", x, y, cellSize, cellSize)  
          elseif moon[l][c] == 20 then
            love.graphics.setColor(self.color.third)
            love.graphics.rectangle("fill", x, y, cellSize, cellSize)
          elseif moon[l][c] == 21 then
            love.graphics.setColor(self.color.fourth)
            love.graphics.rectangle("fill", x, y, cellSize, cellSize)
          elseif moon[l][c] == 30 then
            love.graphics.setColor(48,46,46,255)
            love.graphics.rectangle("fill", x, y, cellSize, cellSize)
          elseif moon[l][c] == 31 then
            love.graphics.setColor(87,78,77,255)
            love.graphics.rectangle("fill", x, y, cellSize, cellSize)
          --elseif planet[l][c] == 40 then
          --  love.graphics.setColor(233,201,62,255)
          --  love.graphics.rectangle("fill", x, y, cellSize, cellSize)        
          end
          x = x + cellSize
        end
      end
      x = self.planetView.x - radius
      y = y + cellSize
    end
  end
love.graphics.print(self.pId,self.planetView.x + self.planetView.radius, self.planetView.y)

end
  return newMoon
end

return moon