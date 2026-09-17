local sun = {}

local grid = require("grid") -- Accès aux fonctions travaillant sur les grilles

local MIN_RADIUS = 8
local MAX_RADIUS = 16
local RATIO_PLANET_VIEW = 2--15
local SUN_CELLSIZE = 3


function NewNameSystem()
  local alphabet_M = {"A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z"} 
  local alphabet_m = {"a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z"}
  local prefix = {}
  local suffix
  for i=1,3 do  prefix[i] = alphabet_M[math.random(1,26)] end
  
  local id = math.random(0,9999)
  local luckM = math.random(1,4)
  if luckM == 1 then suffix = alphabet_m[math.random(1,4)] else suffix = "" end
  
  local system_name = prefix[1]..prefix[2]..prefix[3].."-"..id..suffix
  return system_name
end

function sun.new(pColumn, pLines, pPosX, pPosY, pX, pY, pRadius, pTileId, pSunId)
  local newSun = {}
    newSun.tileId = pTileId
    newSun.sunId = pSunId 
    newSun.id = nil
    newSun.name = NewNameSystem()
    newSun.type = "telluric"
    newSun.viewType = "system" -- ou "system"
    newSun.x = pX
    newSun.y = pY
    newSun.c = pColumn
    newSun.l = pLines
    newSun.posX = pPosX
    newSun.posY = pPosY
    newSun.posX_Z1 = pPosX
    newSun.posY_Z1 = pPosY
    newSun.posX_Z2 = pPosX/4
    newSun.posY_Z2 = pPosY/4
    newSun.here = pHere or false
    newSun.discover = pHere or false
    newSun.totalPlanets = 0
    newSun.xo = 0
    newSun.yo = 0
    newSun.celsus = nil
    newSun.light = {}
  
  function newSun:celsus(Pluck)
    local luck = Pluck
    if luck == 1 then
      newSun.celsus = math.random(0,5000)
    elseif luck == 2 then
      newSun.celsus = math.random(5000,8000)
    elseif luck == 3 then
      newSun.celsus = math.random(8000,10000)
    elseif luck == 4 then
      newSun.celsus = math.random(10000,25000)
    end
  end

    newSun.radius = pRadius --math.random(MIN_RADIUS, MAX_RADIUS)
    newSun.diameter = newSun.radius * 2
    newSun.scale = 1
    newSun.system = {}
    
    newSun.galaxyView = {}
      newSun.galaxyView.cellSize = 4
      newSun.galaxyView.radius = newSun.radius
      newSun.galaxyView.diameter = newSun.diameter
      newSun.galaxyView.line = newSun.galaxyView.diameter / newSun.galaxyView.cellSize
      newSun.galaxyView.column = newSun.galaxyView.diameter / newSun.galaxyView.cellSize
      newSun.galaxyView.ground = {}
      
    newSun.systemView = {}
      newSun.systemView.cellSize = 4   
      newSun.systemView.radius = newSun.radius * RATIO_PLANET_VIEW
      newSun.systemView.diameter = newSun.diameter * RATIO_PLANET_VIEW
      newSun.systemView.line = newSun.systemView.diameter / newSun.systemView.cellSize
      newSun.systemView.column = newSun.systemView.diameter / newSun.systemView.cellSize
      newSun.systemView.ground = {}
      
    newSun.galaxyZoom = {}  
        if newSun.radius <= 11 then
        newSun.galaxyZoom.cellSize = 1
        newSun.galaxyZoom.radius = 2
        elseif newSun.radius <= 14 then
        newSun.galaxyZoom.cellSize = 1
        newSun.galaxyZoom.radius = 3
      elseif newSun.radius > 14 then
        newSun.galaxyZoom.cellSize = 2
        newSun.galaxyZoom.radius = 4
        end
      newSun.galaxyZoom.diameter = newSun.galaxyZoom.radius * 2
      newSun.galaxyZoom.line = newSun.galaxyZoom.diameter / newSun.galaxyZoom.cellSize
      newSun.galaxyZoom.column = newSun.galaxyZoom.diameter / newSun.galaxyZoom.cellSize
      newSun.galaxyZoom.ground = {}      
      
      
     -- Lumière propagation en vue système du soleil
     
     newSun.star = {}
     -- Lumière propagation en vue planète du soleil 
     newSun.light = {}
     newSun.light.planet = {}
     newSun.light.planet.first = {}
     newSun.light.planet.second = {}
     newSun.light.planet.third = {}
      
     newSun.light.system = {}
     newSun.light.system.first = {}
     newSun.light.system.second = {}
     newSun.light.system.third = {} 
     newSun.light.system.four = {}      

      
    newSun.color = {}
      newSun.color.first = {255, 255, 255}
      newSun.color.second = {255, 255, 255}
      newSun.color.third = {255, 255, 255}
      newSun.color.fourth = {255, 255, 255}
      
      
    newSun.infos = {}
      newSun.infos.temperature = 0
      newSun.infos.diametre = 0
    
    newSun.hover = false
    newSun.isSelected = false
    newSun.isVisible = true
    newSun.debug = false
    
    

  function newSun:StellarXY()
    if self.id == 1 then
    self.xo = 1000
    self.yo = 5000
    else
      local dh, angle
            angle = math.angle(list_tiles[1].sun[1].x,list_tiles[1].sun[1].y,self.x,self.y)
            dh = math.dist(list_tiles[1].sun[1].x,list_tiles[1].sun[1].y,self.x,self.y)
            self.xo = list_tiles[1].sun[1].xo + dh * math.cos(angle)
            self.yo = list_tiles[1].sun[1].yo + dh * math.sin(angle)
    end
  end
  
  function newSun:randomColor()
    
    
    if newSun.celsus >= 0 and newSun.celsus < 5000 then
    local r, g, b = 0, 0, 0
    r = math.random(255,255)
    g = math.random(230,255)
    b = math.random(25,25)
    self.color.first = {r, g, b}
    
    self.color.second = {255, math.random(130,186), 25}
    
    r = math.random(255,255)
    g = math.random(137,255)
    b = math.random(25,25)
    self.color.third = {r, g, b}
    
    r = math.random(235,255)
    g = math.random(107,140)
    b = math.random(25,45)
    self.color.fourth = {r, g, b}
  
    elseif newSun.celsus >= 5000 and newSun.celsus < 8000 then
    local r, g, b = 0, 0, 0
    r = math.random(255,255)
    g = math.random(25,178)
    b = math.random(25,25)
    self.color.first = {r, g, b}
    
    self.color.second = {r, g + 40, b + 40}
    
    r = math.random(255,255)
    g = math.random(25,178)
    b = math.random(25,25)
    self.color.third = {r, g, b}
    
    r = math.random(255,255)
    g = math.random(25,178)
    b = math.random(25,25)
    self.color.fourth = {r, g, b}
    
  elseif newSun.celsus >= 8000 and newSun.celsus <= 10000 then
    local r, g, b = 0, 0, 0
    r = math.random(0,90)
    g = math.random(150,200)
    b = math.random(25,25)
    self.color.first = {r, g, b}
    
    self.color.second = {math.random(80,155), math.random(255,255), math.random(0,40)}
    
    r = math.random(30,140)
    g = math.random(180,210)
    b = math.random(25,25)
    self.color.third = {r, g, b}
    
    r = math.random(0,40)
    g = math.random(145,155)
    b = math.random(25,25)
    self.color.fourth = {r, g, b}
    
    elseif newSun.celsus > 10000 and newSun.celsus <= 25000 then
    local r, g, b = 0, 0, 0
    r = 68--math.random(0,30)
    g = 255--math.random(180,255)
    b = 255--math.random(0,89)
    self.color.first = {r, g, b}
    
    self.color.second = {25, 204, 255}
    
    r = 25--math.random(255,255)
    g = 158--math.random(25,178)
    b = 255--math.random(25,25)
    self.color.third = {r, g, b}
    
    r = 25--self.color.third[1]--math.random(255,255)
    g = 114--math.random(25,178)
    b = 255--math.random(25,25)
    self.color.fourth = {r, g, b}
    end
  end
    
    
  function 
  newSun:generate()
    local luck = 45
    local birthLimit = 4
    local deathLimit = 3
    
    -- génération des soleils vue dezoom
     self.galaxyZoom.ground = grid.init(self.type, self.galaxyZoom.line, self.galaxyZoom.column, luck, birthLimit, deathLimit)
    self.galaxyZoom.ground = grid.initContinent(self.galaxyZoom.ground, self.type, self.galaxyZoom.line, self.galaxyZoom.column, luck, birthLimit, deathLimit)
    self.galaxyZoom.ground = grid.initOcean(self.galaxyZoom.ground, self.galaxyZoom.line, self.galaxyZoom.column)
    self.galaxyZoom.ground = grid.toCircle(self.galaxyZoom.ground, self.x, self.y, self.galaxyZoom.radius, self.galaxyZoom.cellSize, self.galaxyZoom.line,       self.galaxyZoom.column)   
    
    -- Génération du système de grille en plusieurs étape.
    self.galaxyView.ground = grid.init(self.type, self.galaxyView.line, self.galaxyView.column, luck, birthLimit, deathLimit)
    self.galaxyView.ground = grid.initContinent(self.galaxyView.ground, self.type, self.galaxyView.line, self.galaxyView.column, luck, birthLimit, deathLimit)
    self.galaxyView.ground = grid.initOcean(self.galaxyView.ground, self.galaxyView.line, self.galaxyView.column)
    self.galaxyView.ground = grid.toCircle(self.galaxyView.ground, self.x, self.y, self.galaxyView.radius, self.galaxyView.cellSize, self.galaxyView.line, self.galaxyView.column)
    
    self.systemView.ground = grid.init(self.type, self.systemView.line, self.systemView.column, luck, birthLimit, deathLimit)
    self.systemView.ground = grid.initContinent(self.systemView.ground, self.type, self.systemView.line, self.systemView.column, luck, birthLimit, deathLimit)
    self.systemView.ground = grid.initOcean(self.systemView.ground, self.systemView.line, self.systemView.column)
    self.systemView.ground = grid.toCircle(self.systemView.ground, self.x, self.y, self.systemView.radius, self.systemView.cellSize, self.systemView.line, self.systemView.column) 
    
    self:randomColor()
    ----------------------------------------------------------------- 
    

   
    function addLight(Px,Py,Pw,Ph, Pnumber, Pvariable, Pinsert, Popacity, Pr, Pwhile, Poperator,PrandomO,PrandomC)
    
     local cycle = Pwhile
     local operator = Poperator
    
      if cycle == false then
        for i=1, Pnumber do
          if i == 1 then
            local Pvariable = {}
            Pvariable.h = Ph
            Pvariable.w = Pw
            Pvariable.x = Px 
            Pvariable.y = Py - Pvariable.h
            Pvariable.r = Pr[1]  or 255
            Pvariable.g = Pr[2]  or 255
            Pvariable.b = Pr[3]  or 255
            Pvariable.o = Popacity
            table.insert(Pinsert, Pvariable)
          elseif i > 1 then
            local Pvariable = {}
            Pvariable.h = Ph
            Pvariable.w = width
            Pvariable.x = Pinsert[i-1].x
            Pvariable.y = Pinsert[i-1].y - Pvariable.h
            Pvariable.r = Pinsert[i-1].r - PrandomC
            Pvariable.g = Pinsert[i-1].g - PrandomC
            Pvariable.b = Pinsert[i-1].b - PrandomC
            if Poperator == "negatif" then Pvariable.o = Pinsert[i-1].o - PrandomO
            elseif Poperator == "positif" then Pvariable.o = Pinsert[i-1].o + PrandomO end
            table.insert(Pinsert, Pvariable)          
          end
        end
      end
      
      if cycle then
        local y = Py
        local i = 1
        while y>=0 do
          if i == 1 then
            local Pvariable = {}
            Pvariable.h = Ph
            Pvariable.w = Pw
            Pvariable.x = Px 
            Pvariable.y = Py - Pvariable.h
            y = y - Pvariable.h
            Pvariable.r = Pr[1]  or 255
            Pvariable.g = Pr[2]  or 255
            Pvariable.b = Pr[3]  or 255
            Pvariable.o = Popacity
            table.insert(Pinsert, Pvariable)
            i=i+1
          elseif i > 1 then
            local Pvariable = {}
            Pvariable.h = Ph
            Pvariable.w = width
            Pvariable.x = Pinsert[i-1].x
            Pvariable.y = Pinsert[i-1].y - Pvariable.h
            y = y - Pvariable.h
            Pvariable.r = Pinsert[i-1].r - PrandomC
            Pvariable.g = Pinsert[i-1].g - PrandomC
            Pvariable.b = Pinsert[i-1].b - PrandomC
            if Poperator == "negatif" then Pvariable.o = Pinsert[i-1].o - PrandomO
            elseif Poperator == "positif" then Pvariable.o = Pinsert[i-1].o + PrandomO end
            table.insert(Pinsert, Pvariable) 
            i = i + 1
          end
        end
      end
  end
    
    --self.color.first[1],self.color.first[2],self.color.first[3]
    -- nbframe, variable local, liste, hframe,color --  
    local white = {255,255,255}
    --------(Px,Py,Pwidth,Ph,Pnumber,Pvariable,Pliste,Popacity,Pcolor,Pcycle)
    addLight(0,height,width,4, 40, first,self.light.planet.first,180,white,false, "negatif",math.random(8,16),0)

    addLight(0,height,width,4, 50, second,self.light.planet.second,255,self.color.second,true, "negatif", math.random(1,1),0)


    -- Palette couleur pour le background spatiale 3 ème plan 
    ------- MEMO ------ Faire des palettes de couleurs en fonction de la temperature du soleil
    -- ASSET de couleur de background 
    local color = {}
     color[1] = {100,14,95} -- rouge
     color[2] = {108,19,38} -- rouge
     color[3] = {108,53,19} -- rouge
     color[4] = {108,21,19} -- rouge

     color[5] = {108,100,19} -- vert
     color[6] = {46,108,19} -- bleu / vert
     color[7] = {19,100,108} -- bleu / rouge / vert
     color[8] = {19,108,57} -- bleu / rouge / vert
     color[9] = {19,46,108} -- bleu 



    if self.celsus <8000 then 
      c = math.random(1,4)
    elseif self.celsus >= 8000 and self.celsus<= 10000 then 
      c = math.random(5,8) 
    elseif self.celsus > 10000 then 
      c = math.random(6,9) 
    end
     
    addLight(0,height,width,10, 50, third,self.light.planet.third,0,color[c],true, "positif", math.random(2,4),math.random(0,0))
    
    --addLight(Px,Py,Pw,Ph, Pnumber, Pvariable, Pinsert, Popacity, Pr, Pwhile, Poperator,PrandomO,PrandomC)
    ----------------------------------------------------------------
   -- Algorithme pour la génération des effets lumineux circulaires en vue système
   
   
    local function NewColorFirst()
      local n = 20
      for i=1, n do
        if i==1 then
        local first = {}
        first.x = width/2
        first.y = height/2
        first.r = newSun.systemView.radius 
        first.o = 130
        first.RGB = {255,255,255,first.o}
        table.insert(newSun.light.system.first, first)
      elseif i>1 then
        local first = {}
        first.x = width/2
        first.y = height/2
        first.r = self.light.system.first[i-1].r + 2
        first.o = self.light.system.first[i-1].o - 20
        first.RGB = {255,255,255,first.o}
        table.insert(newSun.light.system.first, first)        
        end
      end
    end

      
    local function NewColorSecond()
      local color = {} 
      color.r = newSun.light.planet.second[1].r
      color.g = newSun.light.planet.second[1].g
      color.b = newSun.light.planet.second[1].b
      
      local n = 20
      for i=1, n do
        if i==1 then
        local second = {}
        second.x = width/2
        second.y = height/2
        second.r = newSun.systemView.radius 
        second.o = 110
        second.RGB = {color.r, color.g, color.b, second.o}
        table.insert(newSun.light.system.second, second)
      elseif i>1 then
        local second = {}
        second.x = width/2
        second.y = height/2
        second.r = self.light.system.second[i-1].r + 4
        second.o = self.light.system.second[i-1].o - 15
        second.RGB = {self.light.system.second[i-1].RGB[1],self.light.system.second[i-1].RGB[2], self.light.system.second[i-1].RGB[3], second.o }
        table.insert(newSun.light.system.second, second)        
        end
      end
    end
    local function NewColorThird()
      local color = {} 
      color.r = newSun.light.planet.third[1].r
      color.g = newSun.light.planet.third[1].g
      color.b = newSun.light.planet.third[1].b
      
      local n = 150
      local randomColor = 3
      for i=1, n do
        if i==1 then
        local third = {}
        third.x = width/2
        third.y = height/2
        third.r = newSun.systemView.radius 
        third.o = 140
        third.RGB = {color.r, color.g, color.b, third.o}
        table.insert(newSun.light.system.third, third)
      elseif i>1 then
        local third = {}
        third.x = width/2
        third.y = height/2
        third.r = self.light.system.third[i-1].r + 5
        third.o = self.light.system.third[i-1].o - 8
        third.RGB = {self.light.system.third[i-1].RGB[1]-randomColor,self.light.system.third[i-1].RGB[2]-randomColor, self.light.system.third[i-1].RGB[3]-randomColor, third.o }
        table.insert(newSun.light.system.third, third)        
        end
      end
    end
    
    NewColorFirst()
    NewColorSecond()
    NewColorThird()
  
  end
  
  function newSun:setDiameter(pDiameter)
    self.radius = pDiameter / 2
    self.diameter = pDiameter
    self:generate()
  end
  
  function newSun:setRadius(pRadius)
    self.radius = pRadius
    --self.diameter = self.radius
    self:generate()
  end
  
  function newSun:setViewType(pType)
    self.viewType = pType
  end
  
  function newSun:setPos(pPosX, pPosY)
    self.posX = pPosX
    self.posY = pPosY
  end
  
  function newSun:setCellSize(pCellSize)
    self.galaxyView.cellSize = pCellSize
    self:generate()
  end
  
  function newSun:setVisible(pVisible)
    self.isVisible = pVisible
  end
  
  -- POUR L'EDITEUR  
  function newSun:setsystemViewPosition(pX, pY)
    self.systemView.x = pX
    self.systemView.y = pY
  end


  function newSun:update(dt,mX,mY)
   
   
    if mX > self.x - self.radius and mX < self.x + self.radius and mY > self.y - self.radius and mY < self.y + self.radius then
      self.hover = true
    else
      self.hover = false
    end
    
    if self.hover and love.mouse.isDown(1) and self.isSelected == false then
      self.isSelected = true
      boxWindow.displacement(self.tileId, self.sunId)
    end    
  end

 --[[ function newSun:update(dt)
     -- Position de la souris
  mX, mY = love.mouse.getPosition()
  
    if mX > self.x - self.radius and mX < self.x + self.radius and mY > self.y - self.radius and mY < self.y + self.radius then
      self.hover = true
    else
      self.hover = false
    end
    
    if self.hover and love.mouse.isDown(1) and self.isSelected == false then
      self.isSelected = true
      boxWindow.displacement(self.tileId, self.sunId)
    end
  end --]]
  
  
  function newSun:drawPlanetView()
    -- Affichage des lumières de propagation du soleil
    -- Premiere plan
    for i=1, #self.light.planet.third do
      love.graphics.setColor(self.light.planet.third[i].r, self.light.planet.third[i].g, self.light.planet.third[i].b, self.light.planet.third[i].o)
      love.graphics.rectangle("fill", self.light.planet.third[i].x, self.light.planet.third[i].y, self.light.planet.third[i].w, self.light.planet.third[i].h)
    end 
    for i=1, #self.light.planet.second do
      love.graphics.setColor(self.light.planet.second[i].r, self.light.planet.second[i].g, self.light.planet.second[i].b, self.light.planet.second[i].o)
      love.graphics.rectangle("fill", self.light.planet.second[i].x, self.light.planet.second[i].y, self.light.planet.second[i].w, self.light.planet.second[i].h)
    end 
    -- Second Plan
    for i=1, #self.light.planet.first do
      love.graphics.setColor(self.light.planet.first[i].r, self.light.planet.first[i].g, self.light.planet.first[i].b, self.light.planet.first[i].o)
      love.graphics.rectangle("fill", self.light.planet.first[i].x, self.light.planet.first[i].y, self.light.planet.first[i].w, self.light.planet.first[i].h)
    end
    -- troisième Plan
   
  
    
  end
  
  
  -- POUR L'EDITEUR, affichage de la planète seul, à des coordonées différentes
  function newSun:drawsystemView()

    love.graphics.circle("line", width/2, height/2,self.systemView.radius)
    -- VARIABLE LOCAL GLOBALE
    local line, column = 0, 0
    local x, y = 0, 0
    local planet = nil
    local cellSize, radius = 0, 0
    
    planet = self.systemView.ground
    line = self.systemView.line
    column = self.systemView.column
    cellSize = self.systemView.cellSize
    radius = self.systemView.radius
    
    x = width/2 - radius 
    y = height/2 - radius
    
    love.graphics.setColor(25,24,55,110)
    love.graphics.rectangle("fill",0,0,width,height)
    love.graphics.setColor(255,255,255,255)
    -- Affichage des effets lumineux du soleil en vue système
    for i=1, #self.light.system.four do
      love.graphics.setColor(self.light.system.four[i].RGB)
      love.graphics.circle("fill", self.light.system.four[i].x, self.light.system.four[i].y, self.light.system.four[i].r)
    end
    for i=1, #self.light.system.third do
      love.graphics.setColor(self.light.system.third[i].RGB)
      love.graphics.circle("fill", self.light.system.third[i].x, self.light.system.third[i].y, self.light.system.third[i].r)
    end
    for i=1, #self.light.system.second do
      love.graphics.setColor(self.light.system.second[i].RGB)
      love.graphics.circle("fill", self.light.system.second[i].x, self.light.system.second[i].y, self.light.system.second[i].r)
    end
    for i=1, #self.light.system.first do
      love.graphics.setColor(self.light.system.first[i].RGB)
      love.graphics.circle("fill", self.light.system.first[i].x, self.light.system.first[i].y, self.light.system.first[i].r)
    end 
    
    
    
    x = width/2 - radius 
    y = height/2 - radius
    
    for l=1, line do
      for c=1, column do
        if planet[l][c] == 10 then
          love.graphics.setColor(self.color.first)
          love.graphics.rectangle("fill", x, y, cellSize, cellSize)
        elseif planet[l][c] == 11 then
          love.graphics.setColor(self.color.second)
          love.graphics.rectangle("fill", x, y, cellSize, cellSize) 
        elseif planet[l][c] == 20 then
          love.graphics.setColor(self.color.third)
          love.graphics.rectangle("fill", x, y, cellSize, cellSize)
        elseif planet[l][c] == 21 then
          love.graphics.setColor(self.color.fourth)
          love.graphics.rectangle("fill", x, y, cellSize, cellSize)
        end
        x = x + cellSize
      end
      x = width/2 - radius
      y = y + cellSize
    end
     
    
  end
  
  
  function newSun:setCoordinates(Px, Py)
    self.x = Px
    self.y = Py
  end
  
  function newSun:draw()


      local line, column = 0, 0
      local x, y = 0, 0
      local sun = nil
      local cellSize, radius = 0, 0
      
      
      if GAME == "system" then
        sun = self.systemView.ground
        line = self.systemView.line
        column = self.systemView.column
        cellSize = self.systemView.cellSize
        radius = self.systemView.radius
        
      elseif GAME == "galaxy" and ZOOM == 1 then
        sun = self.galaxyView.ground
        line = self.galaxyView.line
        column = self.galaxyView.column
        cellSize = self.galaxyView.cellSize
        radius = self.galaxyView.radius
      
      elseif GAME == "galaxy" and ZOOM == 2 then
        sun = self.galaxyZoom.ground
        line = self.galaxyZoom.line
        column = self.galaxyZoom.column
        cellSize = self.galaxyZoom.cellSize
        radius = self.galaxyZoom.radius
      end
      
      x = self.x - radius
      y = self.y - radius
    

        for l=1, line do
          for c=1, column do
            if sun[l][c] == 10 then
              love.graphics.setColor(self.color.first)
              love.graphics.rectangle("fill", x, y, cellSize, cellSize)
            elseif sun[l][c] == 11 then
              love.graphics.setColor(self.color.second)
              love.graphics.rectangle("fill", x, y, cellSize, cellSize)  
            elseif sun[l][c] == 20 then
              love.graphics.setColor(self.color.third)
              love.graphics.rectangle("fill", x, y, cellSize, cellSize)
            elseif sun[l][c] == 21 then
              love.graphics.setColor(self.color.fourth)
              love.graphics.rectangle("fill", x, y, cellSize, cellSize)
            end
            x = x + cellSize
          end
          x = self.x - radius
          y = y + cellSize
        end
        
        if self.hover then
          love.graphics.setColor(255, 255, 255)
          love.graphics.circle("line", self.x, self.y, radius)
          love.graphics.print(self.sunId,self.x-70,self.y-40)
          love.graphics.print("posX_z1: "..self.posX_Z1,self.x-300,self.y-90)
          love.graphics.print("posY_z1: "..self.posY_Z1,self.x-300,self.y-60)
          love.graphics.print("posX_z2: "..self.posX_Z2,self.x-300,self.y-30)
          love.graphics.print("posY_z2: "..self.posY_Z2,self.x-300,self.y-0)
        end
        
        if self.debug then
          local x = 10
          local y = 10
        end
  end
  
  return newSun
end

return sun
