local system = {}

local sun = require("sun")
local planet = require("planet")


function math.dist(x1,y1, x2,y2) return ((x2-x1)^2+(y2-y1)^2)^0.5 end

function sortPlanet(pPlanetList)
  local distance = {}
  for i=1, #pPlanetList do
    table.insert(distance, pPlanetList[i].sunDistance)
  end
  
  table.sort(distance)
  
  for i=1, #distance do
    for j=1, #pPlanetList do
      if pPlanetList[j].sunDistance == distance[i] then
        pPlanetList[j].id = i
      end
      
      if pPlanetList[j].id == #distance then
        pPlanetList[j].here = true

      end
    end
  end
  
  return pPlanetList
end


function system.new(pX, pY, pID, pName,pPlanet)
  local newSystem = {}
    newSystem.name = pName or nil
    newSystem.ID = pID or nil 
    newSystem.x = pX
    newSystem.y = pY
    newSystem.width = width
    newSystem.height = height
    newSystem.rotationType = ELLIPTICAL_ORBIT -- "circle" ou "ellipse"
    newSystem.totalPlanets = 0 or Pplanet
    newSystem.currentPlanet = 1
    newSystem.systemView = {}
    newSystem.planets = {}
    newSystem.sun = {}
    
    newSystem.isVisited = false
    newSystem.showOrbits = true
    newSystem.showClouds = true
    newSystem.showShadows = true
    newSystem.play = true
    newSystem.debug = false 
    
  -- Modifier la position du centre du système solaire
  function newSystem:setPosition(pX, pY)
    self.x = pX
    self.y = pY
  end  
  
  function newSystem:getCurrentPlanet()
    return self.currentPlanet
  end
  
  function newSystem:destroy()
    for i = self.totalPlanets, 0, -1 do
      table.remove(self.planets, i)
    end
    self.currentPlanet = 2
  end
  
  function newSystem:random()
    self:destroy()
    self:generate()
  end
  
  
  function newSystem:generateSolarSystem(Psun)
  self.isVisited = true   
  self.sun = Psun
  
  self.totalPlanets = 9
  
  
  -- local perimeter = (W/2*UAplanet)/UAtotal
  
  -- Mercure -
 
  local Mercury = planet.new(self.x,self.y,nil,6)
  Mercury:setName("Mercury")
  Mercury:setType("telluric")
  Mercury:setColor(201,204,198,150,145,155,107,94,107,81,79,79)
  Mercury:setOrb()
  Mercury:setPole(false,0)
  Mercury:setMoon(1)
  Mercury:generate(30,4,1)
  Mercury:generateMoon()
  local distance_mercury = Mercury.systemView.radius 
  Mercury:setSunDistance(self.sun.systemView.radius*2+distance_mercury)
  table.insert(self.planets, Mercury) 


  
  -- Venus
  local Venus = planet.new(self.x,self.y,nil,8)
  Venus:setName("Venus")
  Venus:setType("telluric")
  Venus:setColor(201,183,155,211,201,186,216,214,196,206,201,204)
  Venus:setOrb()
  Venus:setPole(true,8)
  Venus:setPoleColor(255,255,255,255,255,255,255,230)
  Venus:setMoon(1)
  Venus:generate(50,5,1)
  Venus:generateMoon()
  local distance_venus = Venus.systemView.radius
  Venus:setSunDistance((self.sun.systemView.radius*2)+(Mercury.systemView.radius*4)+(distance_venus))
  table.insert(self.planets, Venus) 
  
  
  -- Terre
  local Earth = planet.new(self.x,self.y,nil,8)
  Earth:setName("Earth")
  Earth:setType("telluric")
  Earth:setColor(94,165,81,112,132,81,99,117,142,84,107,130)
  Earth:setOrb()
  Earth:setCloud(true,60)
  Earth:setRings(true)
  Earth:setPole(true,12)
  Earth:setColony(true,100) 
  Earth:setMoon(8)
  Earth:generate(52,4,4)
  Earth:generateMoon()
  local distance_earth = Earth.systemView.radius
  Earth:setSunDistance((self.sun.systemView.radius*2)+(Mercury.systemView.radius*4)+(distance_venus*4)+distance_earth)
  table.insert(self.planets, Earth) 
  
  -- Mars 
  local Mars = planet.new(self.x,self.y,nil,8)
  Mars:setName("Mars")
  Mars:setType("telluric")
  Mars:setColor(181,117,56,124,96,68,232,147,84,255,160,84)
  Mars:setOrb()
  Mars:setPole(true,12)
  Mars:setColony(true,18)
  Mars:setMoon(1)
  Mars:generate(35,4,2)
  Mars:generateMoon()
  local distance_mars = Mars.systemView.radius--((width/2)*1.52)/40
  Mars:setSunDistance((self.sun.systemView.radius*2)+(Mercury.systemView.radius*4)+(distance_venus*4)+(distance_earth*4)+distance_mars)
  table.insert(self.planets, Mars)  
  
  -- Jupiter
  local Jupiter = planet.new(self.x,self.y,nil,12)
  Jupiter:setName("Jupiter")
  Jupiter:setType("gas")
  Jupiter:setColor(232,168,117,255,244,229,186,119,81,234,165,119)
  Jupiter:setOrb()
  Jupiter:setMoon(0)
  Jupiter:generate(45,3,2)
  local distance_jupiter = Jupiter.systemView.radius --((width/2)*5.20)/40--
  Jupiter:setSunDistance((self.sun.systemView.radius*2)+(Mercury.systemView.radius*4)+(distance_venus*4)+(distance_earth*4)+(distance_mars*4)+(distance_jupiter))
  table.insert(self.planets, Jupiter)   

   -- Saturne
  local Saturne = planet.new(self.x,self.y,nil,10)
  Saturne:setName("Saturne")
  Saturne:setType("telluric")
  Saturne:setColor(201,196,142,219,209,165,183,165,135,193,183,130)
  Saturne:setRings(true)
  Saturne:setOrb()
  Saturne:setMoon(0)
  Saturne:generate(37,3,2)
  local distance_saturne = Saturne.systemView.radius --((width/2)*5.20)/40--
  Saturne:setSunDistance((self.sun.systemView.radius*2)+(Mercury.systemView.radius*4)+(distance_venus*4)+(distance_earth*4)+(distance_mars*4)+(distance_jupiter*4)+(distance_saturne))
  table.insert(self.planets, Saturne)  
 
 
   -- Uranus
  local Uranus = planet.new(self.x,self.y,nil,10)
  Uranus:setName("Saturne")
  Uranus:setType("telluric")
  Uranus:setColor(5,221,255,5,168,232,25,168,214,0,122,168)
  Uranus:setRings(true)
  Uranus:setOrb()
  Uranus:setMoon(0)
  Uranus:generate(37,3,2)
  local distance_uranus = ((width/2)*19.2)/40--Uranus.systemView.radius ----
  Uranus:setSunDistance((self.sun.systemView.radius*2)+distance_uranus)
  table.insert(self.planets, Uranus) 
  
     -- Neptune
  local Neptune = planet.new(self.x,self.y,nil,10)
  Neptune:setName("Neptune")
  Neptune:setType("telluric")
  Neptune:setColor(86,186,255,96,196,255,89,188,255,86,186,255)
  Neptune:setRings(true)
  Neptune:setOrb()
  Neptune:setMoon(0)
  Neptune:generate()
  local distance_neptune = ((width/2)*30)/40--Uranus.systemView.radius ----
  Neptune:setSunDistance((self.sun.systemView.radius*2)+distance_neptune)
  table.insert(self.planets, Neptune) 
  
  -- Pluton
  local Pluton = planet.new(self.x,self.y,nil,6)
  Pluton:setName("Pluton")
  Pluton:setType("telluric")
  Pluton:setColor(137,61,66,48,22,17,219,224,232,249,252,255)
  Pluton:setOrb()
  Pluton:setMoon(0)
  Pluton:generate(49,5,2)
  local distance_pluton = ((width/2)*35)/40
  Pluton:setSunDistance((self.sun.systemView.radius*2)+distance_pluton)
  table.insert(self.planets, Pluton) 

   -- Positionnement des planètes en évitant les collisions entre elles
   local function collide()  
      for i=self.totalPlanets, 2, -1 do
        for j=self.totalPlanets, 1, -1 do
          if i~=j and j>=1 then
           local distance = math.dist(self.planets[i].x, self.planets[i].y, self.planets[j].x, self.planets[j].y)
            if distance < self.planets[i].radius + self.planets[j].radius then
              -- On place la planète
              self.planets[i]:setSunDistance()
              collide()
            end
          end
        end
      end    
    end  
    
   -- collide()

      sortPlanet(self.planets)
    for i=1, self.totalPlanets do
      self.planets[i]:setAngle()
    end  

end
  
  function newSystem:generate(pSun)

self.isVisited = true
    
    -- Ajout de l'étoile
    self.sun = pSun

    -- Création des Planètes
    self.totalPlanets = math.random(MIN_PLANETS, MAX_PLANETS)
    
    for i=1, self.totalPlanets do
      local newPlanet = planet.new(self.x, self.y)
      
      local random = math.random(1, 2)
      if random <= 2 then
        newPlanet:setType("telluric")
      elseif random == 3 then
        newPlanet:setType("gas")
      end
      
      newPlanet:setColor()
      newPlanet:setOrb()
      newPlanet:generate()
      
      newPlanet:setSunDistance(math.random(self.sun.systemView.radius+(newPlanet.radius*2),(self.width / 2)))
      
      table.insert(self.planets, newPlanet)
    end
   
   -- Positionnement des planètes en évitant les collisions entre elles
    function collide()  
      for i=self.totalPlanets, 2, -1 do
        for j=self.totalPlanets, 1, -1 do
          if i~=j and j>=1 then
           local distance = math.dist(self.planets[i].x, self.planets[i].y, self.planets[j].x, self.planets[j].y)
            if distance < self.planets[i].radius + self.planets[j].radius then
              -- On place la planète
              distance = math.random(self.sun.systemView.radius, (self.width / 2))
              self.planets[i]:setSunDistance(distance)
              collide()
            end
          end
        end
      end    
    end  
    
    collide()
    
      sortPlanet(self.planets)

      
    for i=1, self.totalPlanets do
      self.planets[i]:setAngle()
    end
    
    
    -- Génération des lunes      
    for i=1, #self.planets do
        self.planets[i]:generateMoon()
    end
    
  end
  
  function newSystem:generateLoad(pSun,Ptotal)

self.isVisited = true
    
    -- Ajout de l'étoile
    self.sun = pSun

    -- Création des Planètes
    self.totalPlanets = Ptotal
    
    for i=1, self.totalPlanets do
      local newPlanet = planet.new(self.x, self.y)
      
      local random = math.random(1, 2)
      if random <= 2 then
        newPlanet:setType("telluric")
      elseif random == 3 then
        newPlanet:setType("gas")
      end
      
      newPlanet:setColor()
      newPlanet:setOrb()
      newPlanet:generate()
      
      newPlanet:setSunDistance(math.random(self.sun.systemView.radius+(newPlanet.radius*2),(self.width / 2)))
      
      table.insert(self.planets, newPlanet)
    end
   
   -- Positionnement des planètes en évitant les collisions entre elles
    function collide()  
      for i=self.totalPlanets, 2, -1 do
        for j=self.totalPlanets, 1, -1 do
          if i~=j and j>=1 then
           local distance = math.dist(self.planets[i].x, self.planets[i].y, self.planets[j].x, self.planets[j].y)
            if distance < self.planets[i].radius + self.planets[j].radius then
              -- On place la planète
              distance = math.random(self.sun.systemView.radius, (self.width / 2))
              self.planets[i]:setSunDistance(distance)
              collide()
            end
          end
        end
      end    
    end  
    
    collide()
    
      sortPlanet(self.planets)

      
    for i=1, self.totalPlanets do
      self.planets[i]:setAngle()
    end
    
  end

  function newSystem:LoadMoon()
        -- Génération des lunes      
    for i=1, #self.planets do
        self.planets[i]:generateMoon()
    end
  end

  function newSystem:update(dt)

    self.sun:update(dt,mX,mY)
    
    for i=1, self.totalPlanets do
      self.planets[i]:update(dt)
      
      -- Récupération de la planète selectionnée
      if self.planets[i].isSelected then
        self.currentPlanet = i
      end
      
      if self.sun.isSelected then
        self.currentPlanet = 0
      end
    end
    
    
    -- Afficher ou non les ombres
    if self.showShadows then
      for i=1, self.totalPlanets do
        self.planets[i].showShadow = true
      end
    else
      for i=1, self.totalPlanets do
        self.planets[i].showShadow = false
      end
    end
    
    -- Afficher ou non les nuages
    if self.showClouds then
      for i=1, self.totalPlanets do
        if self.planets[i].clouds == true then
          self.planets[i].showClouds = true
        end
      end
    else
      for i=1, self.totalPlanets do
        if self.planets[i].clouds == true then
          self.planets[i].showClouds = false
        end
      end
    end
  end
  
  function newSystem:drawCurrentPlanet()
    -- Vue planétaire
      for i=1, #self.planets do
        if self.planets[i].here then
          --self.planets[i]:drawsystemView()
         end
      end
  end
  
  function newSystem:draw()
    
    
    -- Affichage du soleil
    self.sun:drawsystemView()

    ---------------------------------------------------------------
    -- Affichage des orbites en fonction du type. Ellipse ou cercle
    ---------------------------------------------------------------
    if self.showOrbits then
      love.graphics.push()
      
      love.graphics.setColor(255, 255, 255, 100)
      love.graphics.setLineStyle( "rough" )
      love.graphics.setLineWidth(1)
      
      for i=1, self.totalPlanets do
          love.graphics.ellipse("line", self.x, self.y, self.planets[i].ellipse.rx,self.planets[i].ellipse.ry)
      end
      
      love.graphics.pop()
    end
    
    ---------------------------------------------------------------
    -- Affichage des planètes
    ---------------------------------------------------------------
    -- Vue dans le système solaire

      for i=1, self.totalPlanets do
        self.planets[i]:drawSystemView("front")
      end

  
    if self.debug then
      local x, y = 10, 10
      love.graphics.setColor(255, 255, 255)
      love.graphics.print("Système : "..self.name, x, y)
      love.graphics.print("Nb de planètes : "..self.totalPlanets, x, y + 20)
      love.graphics.print("Visité : "..tostring(self.isVisited), x, y + 40)
      love.graphics.print("Planète selectionnée : "..self.currentPlanet, x, y + 60)
    end
  end
  
  return newSystem
end

return system