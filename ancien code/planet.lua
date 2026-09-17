local planet = {}
function math.dist(x1,y1, x2,y2) return ((x2-x1)^2+(y2-y1)^2)^0.5 end
local grid = require("grid") -- Accès aux fonctions travaillant sur les grilles
local moon = require("moon")
-- x et y correspondent au coordonnées du centre de la planète
function planet.new(pXo, pYo, pId,Pradius)
  local newPlanet = {}
    newPlanet.id = pId or nil
    newPlanet.name = "none"
    newPlanet.type = "telluric"
    newPlanet.biome = nil
    newPlanet.viewType = "system" -- "planet" ou "system"
    newPlanet.rotationType = ELLIPTICAL_ORBIT -- "circle" ou "ellipse"
    newPlanet.x = 0
    newPlanet.y = 0
    newPlanet.xo = pXo -- Position de l'étoile 
    newPlanet.yo = pYo -- Position de l'étoile
    newPlanet.angle = 0 --math.random(0, 2 * math.pi)
    newPlanet.radius = Pradius or math.random(MIN_RADIUS, MAX_RADIUS)
    while newPlanet.radius % PLANET_VIEW_CELLSIZE ~= 0 do newPlanet.radius = math.random(MIN_RADIUS, MAX_RADIUS) end -- S'assurer que le rayon est un nombre pair
    newPlanet.diameter = newPlanet.radius * 2
    newPlanet.orbitalSpeed = math.random(1, 5) / 1000 -- Vitesse de rotation autour de l'étoile en px/s
    newPlanet.speedRotation = 0.2 -- rotation toute les x/secondes
    newPlanet.time = 0--0.005 
    -- Position des ombres en vue planète
    newPlanet.timeShadow = 0
    newPlanet.positionShadow = 0
    newPlanet.speedTimeShadow = 1
    newPlanet.speedRotateShadow = 8
    newPlanet.sunDistance = 0
    newPlanet.scale = 1
    
    
    -- Paramètre des lunes
    newPlanet.moon = {} 
    newPlanet.moon.n = math.random(0,4) 
              
local function collide(pList)
  
  for i=#pList, 2, -1 do
    for j=#pList, 1, -1 do
      if i~=j and j>=1 then
        local dh = math.dist(pList[i].planetView.x, pList[i].planetView.y, pList[j].planetView.x, pList[j].planetView.y)
        if dh < pList[i].planetView.radius + pList[j].planetView.radius then
          pList[i]:setPlanetDistance()   
          collide(pList)
        end
      end
    end
  end
end
    
local function sortMoon(pList) 
  local dh = {}
  for i=1,#pList do
    table.insert(dh, pList[i].planetView.rx)
  end
  
  table.sort(dh)

  
  for i=1, #dh do
    for j=1, #pList do
      if pList[j].planetView.rx == dh[i] then
        pList[j].pId = i
      end
    end
  end
  
  for i=1, #pList  do
    for j=1, #pList do
      if pList[j].pId == i then
        table.insert(newPlanet.moon,pList[j]) 
      end
    end
  end
  
end
    
    
    local function setAngle(pList)
      for i=1,newPlanet.moon.n do
        local pi = math.pi
        pList[i].planetView.angle = math.random(0,2*math.pi)
      end
    end
 
    function newPlanet:setMoon(pNumber)
      self.moon.n = pNumber
    end
    
    function newPlanet:generateMoon()
      local temp = {}
        for i=1, self.moon.n do
          local moon = moon.new(self.planetView.radius,i,self.planetView.shadow_x)
          moon:generate(45,3,3)
          table.insert(temp,moon) 
        end
      
      collide(temp)

      sortMoon(temp)
      
      setAngle(newPlanet.moon)

    end

    function newPlanet:generateLoad()

        for i=1, self.moon.n do

          local moon = moon.new(self.planetView.radius,i,self.planetView.shadow_x)
          moon:generate(45,3,3)

          table.insert(self.moon,moon) 
        end
    end
    
    -- Paramètre des colonies
    newPlanet.colony = {}
    -- Pourcentage de surface colonisé IA
    newPlanet.colony.expansion = nil 
    newPlanet.colony.start = 15--math.random(0,100)
    newPlanet.colony.exist = false
    newPlanet.colony.here = false
    newPlanet.colony.population = 0
    newPlanet.background = {}
    newPlanet.background.star = {}
    
    newPlanet.orb = {}
    newPlanet.orb.first = {}
    newPlanet.orb.second = {}
    
    newPlanet.systemView = {}
      newPlanet.systemView.cellSize = 2
      newPlanet.systemView.radius = newPlanet.radius
      newPlanet.systemView.diameter = newPlanet.diameter
      newPlanet.systemView.line = newPlanet.systemView.diameter / newPlanet.systemView.cellSize
      newPlanet.systemView.column = newPlanet.systemView.diameter / newPlanet.systemView.cellSize
      newPlanet.systemView.ground = {}
      newPlanet.systemView.clouds = {}
      newPlanet.systemView.shadow = {}
      
    newPlanet.planetView = {}
      newPlanet.planetView.cellSize = 4
      newPlanet.planetView.radius = newPlanet.radius * RATIO_PLANET_VIEW 
      newPlanet.planetView.x = width/2
      newPlanet.planetView.y = height/2
      newPlanet.planetView.diameter = newPlanet.diameter * RATIO_PLANET_VIEW
      newPlanet.planetView.line = newPlanet.planetView.diameter / newPlanet.planetView.cellSize 
      newPlanet.planetView.column = newPlanet.planetView.diameter / newPlanet.planetView.cellSize
      newPlanet.planetView.ground = {}
      newPlanet.planetView.shadow = {}
      
      newPlanet.planetView.clouds = {}
      newPlanet.planetView.clouds_radius = newPlanet.planetView.radius + (CLOUD_ADD_RADIUS * PLANET_VIEW_CELLSIZE)
      newPlanet.planetView.clouds_line = (newPlanet.planetView.clouds_radius * 2) / PLANET_VIEW_CELLSIZE
      newPlanet.planetView.clouds_column = newPlanet.planetView.clouds_line
      newPlanet.planetView.clouds_x = newPlanet.x
      newPlanet.planetView.clouds_y = newPlanet.y
      

      newPlanet.planetView.shadow_x = newPlanet.planetView.x + math.random(0,newPlanet.planetView.radius)
      
      newPlanet.planetView.shadow_y = newPlanet.planetView.y
      newPlanet.luck = 45
      newPlanet.cloudLuck = 74--math.random(60,95)
      newPlanet.cloudHeight = 0
      newPlanet.shadeGradient = 12
      
      -- Rayon des pôles
      newPlanet.pole = false
      newPlanet.radiusIce = 15--math.random(7,45)--math.random(0,newPlanet.planetView.radius)  
      newPlanet.poleColor = {}
      newPlanet.poleColor.first = {255,255,255,255}
      newPlanet.poleColor.second = {255,255,255,210}      
      
      
    newPlanet.color = {}
      newPlanet.color.first = {255, 255, 255}
      newPlanet.color.second = {255, 255, 255}
      newPlanet.color.third = {255, 255, 255}
      newPlanet.color.fourth = {255, 255, 255}
      
    newPlanet.infos = {}
      newPlanet.infos.temperature = 0
      newPlanet.infos.diametre = 0
    
    newPlanet.rings = false
    newPlanet.clouds = false
    newPlanet.shadows = false
    newPlanet.showOrbit = true
    newPlanet.showClouds = true
    newPlanet.showShadow = true
    newPlanet.showPlanetViewShadow = true
    newPlanet.isSelected = false
    newPlanet.hover = false
    newPlanet.here = false
    newPlanet.discover = false
    
    -- Mouvement ellipsoide, principe Hypotrochoïde(petit rayon, grand rayon)
    
    newPlanet.ellipse = {}
      newPlanet.ellipse.rx = newPlanet.sunDistance
      newPlanet.ellipse.ry = newPlanet.sunDistance/2      
  
  
  function newPlanet:setName(Pname)
    self.name = Pname
  end

  function newPlanet:setAngle()
    self.angle = math.random(0, math.pi*2) 
  end
  
  function newPlanet:Radius(Pradius)
    self.radius = Pradius
          newPlanet.systemView.radius = newPlanet.radius
  end
  
  function newPlanet:setSunDistance(pDistance)
    self.sunDistance = pDistance 
    newPlanet.ellipse.rx = pDistance
    newPlanet.ellipse.ry = pDistance/2
    
    
    self.x = self.xo + newPlanet.ellipse.rx * math.cos(0)
    self.y = self.yo + newPlanet.ellipse.ry * math.sin(0)
  end
  


  function newPlanet:setType(pType)
    -- Types possible : gaz, tellurique
    self.type = pType
  end
  
  function newPlanet:setColor(P1,P2,P3,P4,P5,P6,P7,P8,P9,P10,P11,P12)
    local r, g, b = 0, 0, 0
    
    r = P1 or 239--math.random(1,255)
    g = P2 or 145--math.random(1,255)
    b = P3 or 40--math.random(1,255)
    self.color.first = {r, g, b}
    
    r = P4 or 242--math.random(1,255)
    g = P5 or 130--math.random(1,255)
    b = P6 or 28--math.random(1,255)
    self.color.second = {r, g, b}
    
    r = P7 or 112--math.random(1,255)
    g = P8 or 137--math.random(1,255)
    b = P9 or 96--math.random(1,255)
    self.color.third = {r, g, b}
    
    r = P10 or 114--math.random(1,255)
    g = P11 or 114--math.random(1,255)
    b = P12 or 109--math.random(1,255)
    self.color.fourth = {r,g,b}--{r+40, g+40, b} -- + 40 r et g
  end
  
  function newPlanet:setColorManual(P1,P2,P3,P4,P5,P6,P7,P8,P9,P10,P11,P12)
    local r, g, b = 0, 0, 0
    
    r = P1
    g = P2
    b = P3
    self.color.first = {r, g, b}
    
    r = P4
    g = P5
    b = P6
    self.color.second = {r, g, b}
    
    r = P7
    g = P8
    b = P9
    self.color.third = {r, g, b}
    
    r = P10
    g = P11
    b = P12
    self.color.fourth = {r,g,b}--{r+40, g+40, b} -- + 40 r et g    
    
  end
  
  function newPlanet:setRings(Pbol)
  self.rings = Pbol  
    
  end
  
  function newPlanet:setCloud(Pbol,Pvolume)
    self.clouds = Pbol
    self.cloudLuck = Pvolume
  end
  
  function newPlanet:setPole(Pbol,Pice)
    newPlanet.pole = Pbol
    newPlanet.radiusIce = Pice    
  end
  
  function newPlanet:setPoleColor(P1,P2,P3,P4,P5,P6,P7,P8)
      self.poleColor.first = {P1,P2,P3,P4}
      self.poleColor.second = {P5,P6,P7,P8}    
  end
  
  function newPlanet:setColony(Pbol,Ppourcent)
    self.colony.exist = Pbol
    self.colony.start = Ppourcent
  end

  
  function newPlanet:generate(Pluck,Pbirth,Pdeath)
    local luck = Pluck or 45--math.random(40,57)
    local birthLimit = Pbirth or 4--math.random(4,10)
    local deathLimit = Pdeath or 2--math.random(1,4)
    
    
    -- Vérouille la génération des nuages pour les planètes gazeuses
    if self.type == "gas" then self.clouds = false end

    if self.radius >= 10 then 
      self.type = "gas"
    end
    
    -- Editeur, ne rend pas visible les nuages
    if self.type == "gas" then self.showClouds = false self.clouds = false end
    

  --------------------------------  SYSTEM VIEW PARAMETER  ----------------------------------------
    self.systemView.radius = self.radius
    self.systemView.diameter = self.diameter
    self.systemView.line = self.systemView.diameter / self.systemView.cellSize
    self.systemView.column = self.systemView.diameter / self.systemView.cellSize
    
  --------------------------------  PLANET VIEW PARAMETER  ----------------------------------------
    self.planetView.radius = self.radius * RATIO_PLANET_VIEW
    self.planetView.diameter = self.diameter * RATIO_PLANET_VIEW
    self.planetView.line = self.planetView.diameter / self.planetView.cellSize
    self.planetView.column = self.planetView.diameter / self.planetView.cellSize
  ---------------------- INITIALISATION GRID SYSTEM VIEW  ----------------------
  -- Initialisation de la grille + continent
    self.systemView.ground = grid.init(self.type, self.systemView.line, self.systemView.column, luck, birthLimit, deathLimit)
    
    -- !!!! CONDAMNE POURQUOI? !!!! -- 
    self.systemView.ground = grid.initContinent(self.systemView.ground, self.type, self.systemView.line, self.systemView.column, luck, birthLimit, deathLimit)
    
  -- Générations des océans
        self.systemView.ground = grid.initOcean(self.systemView.ground, self.systemView.line, self.systemView.column)
    
  -- Découpage circulaire de la grille    
        self.systemView.ground = grid.toCircle(self.systemView.ground, self.x, self.y, newPlanet.systemView.radius, newPlanet.systemView.cellSize, self.systemView.line, self.systemView.column)
  
  -- Initialisation des ombres 
    self.systemView.shadow = grid.initShadow(self.x, self.y, self.angle, self.radius, self.systemView.line, self.systemView.column, self.systemView.cellSize, 5)
  
  if self.clouds then
  -- Génération des nuages
  self.systemView.clouds = grid.initCloud(self.systemView.line, self.planetView.column, self.cloudLuck)
  -- Découpage circulaire des nuages
  self.systemView.clouds = grid.toCircle(self.systemView.clouds, self.x, self.y, newPlanet.systemView.radius, newPlanet.systemView.cellSize, self.systemView.line, self.systemView.column)
  end

  ---------------------- INITIALISATION GRID PLANET VIEW  ----------------------
    -- Initialisation de la grille + continent
    self.planetView.ground = grid.init(self.type, self.planetView.line, self.planetView.column, luck, birthLimit, deathLimit)
    -- !!!! CONDAMNE POURQUOI? !!!! --
    self.planetView.ground = grid.initContinent(self.planetView.ground, self.type, self.planetView.line, self.planetView.column, luck, birthLimit, deathLimit)


    -- Générations des océans
    self.planetView.ground = grid.initOcean(self.planetView.ground, self.planetView.line, self.planetView.column)

    -- Génération des poles de glace
    if self.pole == true then 
    self.planetView.ground = grid.initPole(self.planetView.ground, self.planetView.x, self.planetView.y, self.planetView.radius, self.planetView.line, self.planetView.column, self.planetView.cellSize,self.radiusIce)   
    end
  
    if self.rings then
    -- Génération des ellipses
    self.planetView.rings = grid.initRings(self.planetView.x,self.planetView.y,self.planetView.line,self.planetView.column,self.planetView.cellSize)
  
    self.planetView.rings = grid.updateRings(self.planetView.rings,self.planetView.x,self.planetView.y,self.planetView.radius,self.planetView.line,self.planetView.column,self.planetView.cellSize,1)
    end

    if self.colony.exist == true then
    -- Générations des colonies 
      self.planetView.ground = grid.initCivilisation(self.planetView.ground,self.planetView.line,self.planetView.column,self.planetView.x, self.planetView.y, self.planetView.radius, newPlanet.planetView.cellSize,newPlanet.colony.start)
    end
    
    -- Initialisation des ombres     
    newPlanet.planetView.shadow = grid.initShadow(self.planetView.x, self.planetView.y, self.angle, newPlanet.planetView.clouds_radius, self.planetView.clouds_line, self.planetView.clouds_column, self.planetView.cellSize, self.shadeGradient)


    -- Copie des grilles ground
      -- Grille affichable
      self.planetView.groundCopy = grid.copy(self.planetView.ground, self.planetView.line, self.planetView.column)
      -- Grille de remplacement
      self.planetView.groundReplace = grid.copy(self.planetView.ground, self.planetView.line, self.planetView.column)    
    
    -- Découpage circulaire de la grille
  self.planetView.groundCopy = grid.toCircle(self.planetView.groundCopy, self.x, self.y, newPlanet.planetView.radius, newPlanet.planetView.cellSize, self.planetView.line, self.planetView.column, newPlanet.systemView.cellSize*5)    
    if self.clouds then
    -- Génération des nuages
    self.planetView.clouds = grid.initCloud(self.planetView.clouds_line, self.planetView.clouds_column, self.cloudLuck) 
    
    -- Copie des grilles cloud
      -- Grille affichable
      self.planetView.cloudsCopy = grid.copy(self.planetView.clouds, self.planetView.clouds_line, self.planetView.clouds_column)
      -- Grille de remplacement
      self.planetView.cloudsReplace = grid.copy(self.planetView.clouds, self.planetView.clouds_line, self.planetView.clouds_column)       
   
    -- Découpage circulaire de la grille nuage
    self.planetView.cloudsCopy = grid.toCircle(self.planetView.cloudsCopy, self.planetView.x, self.planetView.y, newPlanet.planetView.clouds_radius + self.cloudHeight, newPlanet.planetView.cellSize, self.planetView.clouds_line, self.planetView.clouds_column)
   end 
    
    
    self.isGenerated = true
  end
  
  function newPlanet:addStar()
    local n = math.random(5,12)
    for i=1, 6 do
      local star = {}
      star.w = 5
      star.h = 5
      star.x = math.random(0,width)
      star.y = math.random(0,height)
      star.o = 75
      star.opacityOrb = 25
      star.orb = {}
      for j=1, 4 do
        if j == 1 then
        local orb = {}
        orb.w = star.w
        orb.h = star.h
        orb.x = star.x - orb.w
        orb.y = star.y
        orb.o = star.opacityOrb
        table.insert(star.orb, orb)
      elseif j == 2 then
        local orb = {}
        orb.w = star.w
        orb.h = star.h
        orb.x = star.x
        orb.y = star.y - orb.h
        orb.o = star.opacityOrb
        table.insert(star.orb, orb)
      elseif j == 3 then
        local orb = {}
        orb.w = star.w
        orb.h = star.h
        orb.x = star.x + orb.w
        orb.y = star.y
        orb.o = star.opacityOrb
        table.insert(star.orb, orb)
      elseif j == 4 then
        local orb = {}
        orb.w = star.w
        orb.h = star.h
        orb.x = star.x 
        orb.y = star.y + orb.h
        orb.o = star.opacityOrb
        table.insert(star.orb, orb)
        end
      end
      table.insert(self.background.star, star)
    end
  end
  
  
  function newPlanet:setOrb()
    -- Création des étoiles
    self:addStar()
    local colorOrb = {255,255,255}

    function addOrb(Pn,Po,Pinsert,Pcolor,PrandomR,PrandomO)
      n=Pn
      for i=1, n do 
        if i==1 then
          local orb = {}
          orb.x = width/2
          orb.y = height/2
          orb.r = self.planetView.radius
          orb.R = Pcolor[1]
          orb.G = Pcolor[2]
          orb.B = Pcolor[3]
          orb.o = Po
          table.insert(Pinsert, orb)
        elseif i>1 then
          local orb = {}
          orb.x = width/2
          orb.y = height/2
          orb.r = Pinsert[i-1].r +PrandomR
          orb.R = Pcolor[1]
          orb.G = Pcolor[2]
          orb.B = Pcolor[3]
          orb.o = Pinsert[i-1].o +PrandomO
          table.insert(Pinsert, orb)
        end
      end
    end
  addOrb(10,35,self.orb.first,colorOrb,4,-8)
  addOrb(10,20,newPlanet.orb.second,self.color.third,8,-5)
  end
  
  function newPlanet:hover_selected(dt)
    -- Sélection de la planète
    local mX, mY = love.mouse.getPosition()
    if mX > self.x - self.radius and mX < self.x + self.radius and mY > self.y - self.radius and mY < self.y + self.radius then
      self.hover = true
    else
      self.hover = false
    end
    
    if self.hover and love.mouse.isDown(1) then
      self.isSelected = true
    else
      self.isSelected = false
    end 
  end

  function newPlanet:update(dt)


    if self.rotationType == "ellipse" then
    -- Rotation orbitale de la planète, ellipse ou circle
    self.angle = self.angle + dt * self.orbitalSpeed 
      -- Rotation du cercle directeur
    self.x = self.xo + newPlanet.ellipse.rx * math.cos(self.angle)
    self.y = self.yo + newPlanet.ellipse.ry * math.sin(self.angle)
    end

    -- Update des ombres 
      -- Vue Système
      self.systemView.shadow = grid.initShadow(self.x, self.y, self.angle, self.radius, self.systemView.line, self.systemView.column, self.systemView.cellSize, 3)
   
      self.systemView.shadow = grid.toCircle(self.systemView.shadow, self.x, self.y, newPlanet.systemView.radius, newPlanet.systemView.cellSize, self.systemView.line, self.systemView.column)
      
      -- Vue planète

      self.planetView.shadow = grid.initShadowPlanetView(self.planetView.x, self.planetView.y, self.planetView.shadow_x, newPlanet.planetView.clouds_radius, newPlanet.planetView.clouds_line, newPlanet.planetView.clouds_column, self.planetView.cellSize, self.shadeGradient)
    
    
    self.planetView.shadow = grid.toCircle(self.planetView.shadow, self.planetView.x, self.planetView.y, newPlanet.planetView.clouds_radius, newPlanet.planetView.cellSize, newPlanet.planetView.clouds_line, newPlanet.planetView.clouds_column, -newPlanet.systemView.cellSize * 5)
    
    --------------------------------------------------------

     -- UPDATE position des lunes
    if self.moon.n ~= nil then
      for i=1,self.moon.n do
        self.moon[i]:update(dt)
        self.moon[i]:shadowUpdate(self.planetView.shadow_x)    
      end
    end
    
    
    -- Rotation de la planète sur elle même
    if self.here then
      self.time = self.time + dt
      if self.time > self.speedRotation then
        

        
        
  ---------- DEPLACEMENT DES GRILLES GROUND

  -- Déplacement de la colonne Pcolumn à 1
  -- GROUND
            self.planetView.ground = grid.horizontalMove(self.planetView.ground, self.planetView.line, self.planetView.column)
  -- Remplace colonne 2 à Pcolumn
            self.planetView.ground = grid.replace(self.planetView.ground,self.planetView.groundReplace,self.planetView.line, self.planetView.column) 
      
  -- Update Colonisation
     
        --  self.planetView.ground = grid.initCivilisation(self.planetView.ground,self.planetView.line,self.planetView.column,self.planetView.x, self.planetView.y, self.planetView.radius, newPlanet.planetView.cellSize,0)      
  
  -- Update des lumières des colonies
          self.planetView.ground = grid.updateNightCity(self.planetView.ground,self.planetView.x, self.planetView.y,self.planetView.shadow_x,self.planetView.radius, self.planetView.line,self.planetView.column, self.planetView.cellSize,10)
          
  -- Copy des grilles
    -- Copie pour afficher
        self.planetView.groundReplace = grid.copy(self.planetView.ground, self.planetView.line, self.planetView.column)
    -- Copie pour remplacer
        self.planetView.groundCopy = grid.copy(self.planetView.ground, self.planetView.line, self.planetView.column)
    -- Découpage circulaire de la grille
        self.planetView.groundCopy = grid.toCircle(self.planetView.groundCopy, self.x, self.y, newPlanet.planetView.radius, newPlanet.planetView.cellSize, self.planetView.line, self.planetView.column, -newPlanet.systemView.cellSize*5)
  
      
      -- CLOUDS 
          -- Génération des nuages
      -- Déplacement de la colonne Pcolumn à 1e
      if self.clouds then
          self.planetView.clouds = grid.horizontalMove(self.planetView.clouds, self.planetView.clouds_line, self.planetView.clouds_column)
      -- Remplace colonne 2 à Pcolumn  
          self.planetView.clouds = grid.replace(self.planetView.clouds, self.planetView.cloudsReplace, self.planetView.clouds_line,self.planetView.clouds_column)
      -- Copy des grilles
          -- Copie pour afficher
            self.planetView.cloudsReplace =  grid.copy(self.planetView.clouds, self.planetView.clouds_line, self.planetView.clouds_column)
            self.planetView.cloudsCopy = grid.copy(self.planetView.clouds, self.planetView.clouds_line, self.planetView.clouds_column)
      -- Découpage circulaire de la grille      
        self.planetView.cloudsCopy = grid.toCircle(self.planetView.cloudsCopy, self.x, self.y, newPlanet.planetView.clouds_radius+self.cloudHeight, newPlanet.planetView.cellSize, self.planetView.clouds_line, self.planetView.clouds_column)
      end


     -- UPDATE position des lunes
    if self.moon.n ~= nil then
      for i=1,self.moon.n do
        self.moon[i]:updateRotation(dt)
      end
    end
    
    -- Update de la position du centre du cercle ombragé
      self.planetView.shadow_x = self.planetView.shadow_x + self.speedRotateShadow
      if self.planetView.shadow_x >= self.planetView.x + 2*newPlanet.planetView.clouds_radius then
        self.planetView.shadow_x = self.planetView.x - 2*newPlanet.planetView.clouds_radius
      end       
        self.time = 0
      end
    end

  end
  
  function newPlanet:drawOrb()
    -- Affichage de l'orbe de la planète
    for i=1, #self.orb.second do
      love.graphics.setColor(self.orb.second[i].R,self.orb.second[i].G,self.orb.second[i].B,self.orb.second[i].o)
      love.graphics.circle("fill", self.orb.second[i].x, self.orb.second[i].y, self.orb.second[i].r)
    end
    
    for i=1, #self.orb.first do
      love.graphics.setColor(self.orb.first[i].R,self.orb.first[i].G,self.orb.first[i].B,self.orb.first[i].o)
      love.graphics.circle("fill", self.orb.first[i].x, self.orb.first[i].y, self.orb.first[i].r)
    end

    -- Affichage des étoiles background
    for i=1, #self.background.star do
      love.graphics.setColor(255,255,255,self.background.star[i].o)
      love.graphics.rectangle("fill", self.background.star[i].x, self.background.star[i].y, self.background.star[i].w, self.background.star[i].h)
      for j=1, #self.background.star[i].orb do
        love.graphics.setColor(255,255,255,self.background.star[i].orb[j].o)
        love.graphics.rectangle("fill", self.background.star[i].orb[j].x, self.background.star[i].orb[j].y, self.background.star[i].orb[j].w, self.background.star[i].orb[j].h)
      end
    end
  end
 
 function newPlanet:drawRings(pPositionRings)
     
    if self.rings then
     
     
     rings = self.planetView.rings
     local x = self.planetView.rings.x
     local y = self.planetView.rings.y

    if pPositionRings == "front" then
     for l=1,rings.l do
       for c=1,rings.c do
          if y >= height/2 then
              if rings[l][c] == 1 then
                love.graphics.setColor(255,255,255,255)
                love.graphics.rectangle("fill", x,y,rings.cell, rings.cell)
              elseif rings[l][c] == 2 then
                love.graphics.setColor(255,255,255,180)
                love.graphics.rectangle("fill", x,y,rings.cell, rings.cell)
              elseif rings[l][c] == 3 then
                love.graphics.setColor(255,255,255,150)
                love.graphics.rectangle("fill", x,y,rings.cell, rings.cell)
              elseif rings[l][c] == 4 then
                love.graphics.setColor(255,255,255,150)
                love.graphics.rectangle("fill", x,y,rings.cell, rings.cell)
              elseif rings[l][c] == 5 then
                love.graphics.setColor(0,0,0,75)
                love.graphics.rectangle("fill", x,y,rings.cell, rings.cell)
              end
          end
          x = (c*rings.cell) + rings.x
        end
         x = rings.x
         y = (l*rings.cell) + rings.y
       end
    elseif pPositionRings == "back" then
     for l=1,rings.l do
       for c=1,rings.c do
          if y < height/2 then
              if rings[l][c] == 1 then
                love.graphics.setColor(255,255,255,255)
                love.graphics.rectangle("fill", x,y,rings.cell, rings.cell)
              elseif rings[l][c] == 2 then
                love.graphics.setColor(255,255,255,180)
                love.graphics.rectangle("fill", x,y,rings.cell, rings.cell)
              elseif rings[l][c] == 3 then
                love.graphics.setColor(255,255,255,150)
                love.graphics.rectangle("fill", x,y,rings.cell, rings.cell)
              elseif rings[l][c] == 4 then
                love.graphics.setColor(255,255,255,150)
                love.graphics.rectangle("fill", x,y,rings.cell, rings.cell)
              elseif rings[l][c] == 5 then
                love.graphics.setColor(0,0,0,90)
                love.graphics.rectangle("fill", x,y,rings.cell, rings.cell)
              end
          end
          x = (c*rings.cell) + rings.x
        end
         x = rings.x
         y = (l*rings.cell) + rings.y
       end
    end
  end
 end
 
  function newPlanet:drawClouds() 
  if self.clouds then
    local line, column = 0, 0
    local x, y = 0, 0
    local planet = nil
    local cellSize, radius = 0, 0
    
    clouds = self.planetView.cloudsCopy
    line = self.planetView.clouds_line
    column = self.planetView.clouds_column
    cellSize = self.planetView.cellSize
    radius = self.planetView.clouds_radius + self.cloudHeight
    
    x = self.planetView.x  - radius
    y = self.planetView.y - radius
    
    if self.showClouds then 
      for l=1, line do
        for c=1, column do
          if clouds[l][c] == 50 then
            love.graphics.setColor(250,250,250,250)
            love.graphics.rectangle("fill", x, y, cellSize, cellSize)
          elseif clouds[l][c] == 51 then
            love.graphics.setColor(160,160,160,200)
            love.graphics.rectangle("fill", x, y, cellSize, cellSize)
          end
          x = x + cellSize
        end
        x = self.planetView.x - radius
        y = y + cellSize
      end
    end 
  end
  end
    
  function newPlanet:drawShadowPlanetView()
    local line, column = 0, 0
    local x, y = 0, 0
    local planet = nil
    local cellSize, radius = 0, 0
    
    clouds = self.planetView.clouds
    --planet = self.planetView.groundCopy
    shadow = self.planetView.shadow
    line = self.planetView.clouds_line
    column = self.planetView.clouds_column
    cellSize = self.planetView.cellSize
    radius = self.planetView.clouds_radius
    
    x = self.planetView.x - radius
    y = self.planetView.y - radius
    
    for l=1, line do
      for c=1, column do 
         if self.showPlanetViewShadow then
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


   function newPlanet:drawCityLightPlanetView()
  
  local line, column = 0, 0
    local x, y = 0, 0
    local planet = nil
    local cellSize, radius = 0, 0
    
    --clouds = self.planetView.clouds
    planet = self.planetView.groundCopy
    shadow = self.planetView.shadow
    line = self.planetView.line
    column = self.planetView.column
    cellSize = self.planetView.cellSize
    radius = self.planetView.radius
    
    x = self.planetView.x - radius
    y = self.planetView.y - radius
    
    for l=1, line do
      for c=1, column do
        if planet[l][c] == 40 then
          love.graphics.setColor(233,201,62,160)
          love.graphics.rectangle("fill", x, y, cellSize, cellSize)    
        elseif planet[l][c] == 41 then
          love.graphics.setColor(233,201,62,110)
          love.graphics.rectangle("fill", x, y, cellSize, cellSize) 
        elseif planet[l][c] == 42 then
          love.graphics.setColor(233,201,62,60)
          love.graphics.rectangle("fill", x, y, cellSize, cellSize) 
        end
        x = x + cellSize
      end
      x = self.planetView.x - radius
      y = y + cellSize
    end 
  end

  -- Affichage de la planète seul, à des coordonées différentes
  function newPlanet:drawPlanetView()
  -- Affichage des anneaux derriere la planète
   self:drawRings("back") 
   self:drawMoonEllipse("back")
      
  -- Affichage des lunes
  self:drawMoon("back") 
  -- Affichage ombres lunes
  self:drawShadowMoon("back")
    
    local line, column = 0, 0
    local x, y = 0, 0
    local planet = nil
    local cellSize, radius = 0, 0
    
    --clouds = self.planetView.clouds
    local planet = self.planetView.groundCopy
    local shadow = self.planetView.shadow
    local line = self.planetView.line
    local column = self.planetView.column
    local cellSize = self.planetView.cellSize
    local radius = self.planetView.radius
    
    x = self.planetView.x - radius
    y = self.planetView.y - radius

    for l=1, line do
      for c=1, column do
        if planet[l][c] == 10 then
          love.graphics.setColor(self.color.first)
          love.graphics.rectangle("fill", x, y, cellSize, cellSize)
        elseif planet[l][c] == 11 then 
          love.graphics.setColor(self.color.second)
          love.graphics.rectangle("fill", x, y, cellSize, cellSize) 
        elseif planet[l][c] == 12 then -- pole
          love.graphics.setColor(newPlanet.poleColor.first)
          love.graphics.rectangle("fill", x, y, cellSize, cellSize)  
        elseif planet[l][c] == 13 then -- pole
          love.graphics.setColor(newPlanet.poleColor.second)
          love.graphics.rectangle("fill", x, y, cellSize, cellSize)  
        elseif planet[l][c] == 20 then
          love.graphics.setColor(self.color.third)
          love.graphics.rectangle("fill", x, y, cellSize, cellSize)
        elseif planet[l][c] == 21 then
          love.graphics.setColor(self.color.fourth)
          love.graphics.rectangle("fill", x, y, cellSize, cellSize)
        elseif planet[l][c] == 30 then
          love.graphics.setColor(48,46,46,255)
          love.graphics.rectangle("fill", x, y, cellSize, cellSize)
        elseif planet[l][c] == 31 then
          love.graphics.setColor(87,78,77,255)
          love.graphics.rectangle("fill", x, y, cellSize, cellSize)
        --elseif planet[l][c] == 40 then
        --  love.graphics.setColor(233,201,62,255)
        --  love.graphics.rectangle("fill", x, y, cellSize, cellSize)        
        end
        x = x + cellSize
      end
      x = self.planetView.x - radius
      y = y + cellSize
    end
    
    
    -- Affichage des nuages
    self:drawClouds()
    -- Affichage des ombres dans la vue planet
    self:drawShadowPlanetView()
    -- Affichage des lumières des villes
    self:drawCityLightPlanetView()
    -- Affichage des anneaux devant la planète
    self:drawRings("front") 
    
    -- Affichage des lunes
    self:drawMoon("front") 
    -- Affichage ombres lunes
    self:drawShadowMoon("front")
    -- Affichage ellipse lune
    self:drawMoonEllipse("front")
  end
  
  function newPlanet:drawShadowMoon(pFace)
    if self.moon.n ~= nil then
      for i=1,self.moon.n do
      self.moon[i]:drawShadow(pFace)
      end
    end
  end
  
  
  function newPlanet:drawMoonEllipse(pFace)
    if self.moon.n ~= nil then
        if pFace == "front" then 
          for i=1,#self.moon do
           self.moon[i]:drawEllipse(pFace)
          end
        elseif pFace == "back" then
          for i=1,#self.moon do
           self.moon[i]:drawEllipse(pFace)
          end
        end        
      end
  end 
  
  function newPlanet:drawMoon(pFace)
    if self.moon.n ~= nil then
      if pFace == "front" then
        for i=1,#self.moon do
          self.moon[i]:draw("front")
        end
      elseif pFace == "back" then
        for i=#self.moon, 1,-1 do
          self.moon[i]:draw("back")
        end     
      end
    end
  end
  
  function newPlanet:drawSystemView(Pposition)
    
    

    love.graphics.print(self.id, self.x + self.radius, self.y + self.radius)

    -- Affichage ou non de l'orbite
    love.graphics.setColor(255,255,255,120)
    love.graphics.ellipse("line", self.xo, self.yo, self.ellipse.rx, self.ellipse.ry)
    love.graphics.setColor(255,255,255,255)
        
    local line, column = 0, 0
    local x, y = 0, 0
    local planet, clouds, shadow = nil, nil, nil
    local cellSize, radius = 0, 0

    
    if self.viewType == "planet" then
      planet = self.planetView.groundCopy
      clouds = self.planetView.clouds
      line = self.planetView.line
      column = self.planetView.column
      cellSize = self.planetView.cellSize
      radius = self.planetView.radius
      
    elseif self.viewType == "system" then
      planet = self.systemView.ground
      clouds = self.systemView.clouds
      shadow = self.systemView.shadow
      line = self.systemView.line
      column = self.systemView.column
      cellSize = self.systemView.cellSize
      radius = self.systemView.radius
    end
    
    -- Sol
    x = self.x - radius
    y = self.y - radius


      for l=1, line do
        for c=1, column do
          -- Sol
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
          
          -- Nuages
          if self.clouds and self.showClouds then
            if clouds[l][c] == 50 then
              --love.graphics.setColor(250,250,250,250)
              love.graphics.setColor(250,250,250,250)
              love.graphics.rectangle("fill", x, y, cellSize, cellSize)
            elseif clouds[l][c] == 51 then
              --love.graphics.setColor(160,160,160,200)
              love.graphics.setColor(160,160,160,200)
              love.graphics.rectangle("fill", x, y, cellSize, cellSize)
            end
          end 
          
          -- Ombres
          if self.showShadow then
            if shadow[l][c] == 0 then
              love.graphics.setColor(0, 0, 0, 0)
              love.graphics.rectangle("fill", x, y, cellSize, cellSize)
            elseif shadow[l][c] == 1 then
              love.graphics.setColor(0, 0, 0, 200)
              love.graphics.rectangle("fill", x, y, cellSize, cellSize)  
            elseif shadow[l][c] == 2 then
              love.graphics.setColor(0, 0, 0, 230)
              love.graphics.rectangle("fill", x, y, cellSize, cellSize)
            elseif shadow[l][c] == 3 then
              love.graphics.setColor(0, 0, 0, 250)
              love.graphics.rectangle("fill", x, y, cellSize, cellSize)
            end
          end
          
          x = x + cellSize
        end
        x = self.x - radius
        y = y + cellSize
      end 
  
    if self.hover then
      love.graphics.setColor(255, 255, 255)
      love.graphics.circle("line", self.x, self.y, self.radius)
    end
    
    love.graphics.setColor(255, 0, 0)
  end
    
  return newPlanet 
end

return planet