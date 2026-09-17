data = {}

local parameter = require ("game_parameter")
local sun = require ("sun")
local system = require ("system")
local libSaveTableToFile = require ("script/libSaveTableToFile")




function data.LoadSystem(Ptile) 
  -- On charge les tiles dans une table temporaire
  function loadTileTemp()
    local tile = table.load(FILEDIRECTORY.."/MAP/TILE_"..Ptile..".as")
    table.insert(list_tiles_temp,tile) 
  end

  loadTileTemp()


    if #list_tiles_temp[1].sun~=0 then 
      for j=1,#list_tiles_temp[1].sun do
        
        -- Creation des systèmes
        if list_tiles_temp[1].sun[j].discover then
        local system = system.new(0, 0, 0, 0,list_tiles_temp[1].sun[j].system[1].totalPlanets) 
        system:generateLoad(list_tiles[Ptile].sun[j],list_tiles_temp[1].sun[j].system[1].totalPlanets)
        -- Mise à jours des variables moon.n
        for p=1, list_tiles_temp[1].sun[j].system[1].totalPlanets do
          
          system.planets[p].moon.n = list_tiles_temp[1].sun[j].system[1].planets[p].moon.n 
        end
        -- Création des lunes
        system:LoadMoon()
        table.insert(list_tiles[Ptile].sun[j].system, system)
        end 
      end 
    end 
 
  
    -------------- Chargement des données -------------- 
  for i=1,#list_tiles do



  if #list_tiles[Ptile].sun ~= 0 then 
    for j = 1, #list_tiles[Ptile].sun do


          for k=1,1 do
            if #list_tiles[Ptile].sun[j].system~=0 then 
              list_tiles[Ptile].sun[j].system[1].name = list_tiles_temp[1].sun[j].system[1].name
              list_tiles[Ptile].sun[j].system[1].ID = list_tiles_temp[1].sun[j].system[1].ID
              list_tiles[Ptile].sun[j].system[1].x = list_tiles_temp[1].sun[j].system[1].x 
              list_tiles[Ptile].sun[j].system[1].y = list_tiles_temp[1].sun[j].system[1].y 
              list_tiles[Ptile].sun[j].system[1].width = list_tiles_temp[1].sun[j].system[1].width
              list_tiles[Ptile].sun[j].system[1].height = list_tiles_temp[1].sun[j].system[1].height
              list_tiles[Ptile].sun[j].system[1].rotationType = list_tiles_temp[1].sun[j].system[1].rotationType
              list_tiles[Ptile].sun[j].system[1].totalPlanets = list_tiles_temp[1].sun[j].system[1].totalPlanets
              list_tiles[Ptile].sun[j].system[1].currentPlanet = list_tiles_temp[1].sun[j].system[1].currentPlanet
              list_tiles[Ptile].sun[j].system[1].systemView = list_tiles_temp[1].sun[j].system[1].systemView

                for p=1, list_tiles[Ptile].sun[j].system[1].totalPlanets do 
                 
                      list_tiles[Ptile].sun[j].system[1].planets[p].id = list_tiles_temp[1].sun[j].system[1].planets[p].id 
                      list_tiles[Ptile].sun[j].system[1].planets[p].name = list_tiles_temp[1].sun[j].system[1].planets[p].name
                      list_tiles[Ptile].sun[j].system[1].planets[p].type = list_tiles_temp[1].sun[j].system[1].planets[p].type
                      list_tiles[Ptile].sun[j].system[1].planets[p].biome = list_tiles_temp[1].sun[j].system[1].planets[p].biome
                      list_tiles[Ptile].sun[j].system[1].planets[p].viewType = list_tiles_temp[1].sun[j].system[1].planets[p].viewType
                      list_tiles[Ptile].sun[j].system[1].planets[p].rotationType = list_tiles_temp[1].sun[j].system[1].planets[p].rotationType
                      list_tiles[Ptile].sun[j].system[1].planets[p].x = list_tiles_temp[1].sun[j].system[1].planets[p].x
                      list_tiles[Ptile].sun[j].system[1].planets[p].y = list_tiles_temp[1].sun[j].system[1].planets[p].y
                      list_tiles[Ptile].sun[j].system[1].planets[p].xo = list_tiles_temp[1].sun[j].system[1].planets[p].xo
                      list_tiles[Ptile].sun[j].system[1].planets[p].yo = list_tiles_temp[1].sun[j].system[1].planets[p].yo
                      list_tiles[Ptile].sun[j].system[1].planets[p].angle = list_tiles_temp[1].sun[j].system[1].planets[p].angle
                      list_tiles[Ptile].sun[j].system[1].planets[p].radius = list_tiles_temp[1].sun[j].system[1].planets[p].radius 
                      list_tiles[Ptile].sun[j].system[1].planets[p].diameter = list_tiles_temp[1].sun[j].system[1].planets[p].diameter
                      list_tiles[Ptile].sun[j].system[1].planets[p].orbitalSpeed = list_tiles_temp[1].sun[j].system[1].planets[p].orbitalSpeed
                      list_tiles[Ptile].sun[j].system[1].planets[p].speedRotation = list_tiles_temp[1].sun[j].system[1].planets[p].speedRotation
                      list_tiles[Ptile].sun[j].system[1].planets[p].time = list_tiles_temp[1].sun[j].system[1].planets[p].time
                      list_tiles[Ptile].sun[j].system[1].planets[p].timeShadow = list_tiles_temp[1].sun[j].system[1].planets[p].timeShadow
                      list_tiles[Ptile].sun[j].system[1].planets[p].positionShadow = list_tiles_temp[1].sun[j].system[1].planets[p].positionShadow
                      list_tiles[Ptile].sun[j].system[1].planets[p].speedTimeShadow = list_tiles_temp[1].sun[j].system[1].planets[p].speedTimeShadow
                      list_tiles[Ptile].sun[j].system[1].planets[p].speedRotateShadow = list_tiles_temp[1].sun[j].system[1].planets[p].speedRotateShadow
                      list_tiles[Ptile].sun[j].system[1].planets[p].sunDistance = list_tiles_temp[1].sun[j].system[1].planets[p].sunDistance
                      list_tiles[Ptile].sun[j].system[1].planets[p].scale = list_tiles_temp[1].sun[j].system[1].planets[p].scale
                      
                      
  
                      list_tiles[Ptile].sun[j].system[1].planets[p].moon.n = list_tiles_temp[1].sun[j].system[1].planets[p].moon.n
                      list_tiles[Ptile].sun[j].system[1].planets[p].colony = list_tiles_temp[1].sun[j].system[1].planets[p].colony
                      list_tiles[Ptile].sun[j].system[1].planets[p].background = list_tiles_temp[1].sun[j].system[1].planets[p].background
                      list_tiles[Ptile].sun[j].system[1].planets[p].background.star = list_tiles_temp[1].sun[j].system[1].planets[p].background.star  
                      list_tiles[Ptile].sun[j].system[1].planets[p].orb = list_tiles_temp[1].sun[j].system[1].planets[p].orb  
                      list_tiles[Ptile].sun[j].system[1].planets[p].systemView = list_tiles_temp[1].sun[j].system[1].planets[p].systemView  
                      list_tiles[Ptile].sun[j].system[1].planets[p].planetView = list_tiles_temp[1].sun[j].system[1].planets[p].planetView 
                      list_tiles[Ptile].sun[j].system[1].planets[p].luck = list_tiles_temp[1].sun[j].system[1].planets[p].luck
                      list_tiles[Ptile].sun[j].system[1].planets[p].cloudLuck = list_tiles_temp[1].sun[j].system[1].planets[p].cloudLuck
                      list_tiles[Ptile].sun[j].system[1].planets[p].cloudHeight = list_tiles_temp[1].sun[j].system[1].planets[p].cloudHeight
                      list_tiles[Ptile].sun[j].system[1].planets[p].shadeGradient = list_tiles_temp[1].sun[j].system[1].planets[p].shadeGradient
                      list_tiles[Ptile].sun[j].system[1].planets[p].pole = list_tiles_temp[1].sun[j].system[1].planets[p].pole
                      list_tiles[Ptile].sun[j].system[1].planets[p].radiusIce = list_tiles_temp[1].sun[j].system[1].planets[p].radiusIce
                      list_tiles[Ptile].sun[j].system[1].planets[p].poleColor = list_tiles_temp[1].sun[j].system[1].planets[p].poleColor
                      list_tiles[Ptile].sun[j].system[1].planets[p].color = list_tiles_temp[1].sun[j].system[1].planets[p].color
                      list_tiles[Ptile].sun[j].system[1].planets[p].infos = list_tiles_temp[1].sun[j].system[1].planets[p].infos                     
                      list_tiles[Ptile].sun[j].system[1].planets[p].rings = list_tiles_temp[1].sun[j].system[1].planets[p].rings    
                      list_tiles[Ptile].sun[j].system[1].planets[p].clouds = list_tiles_temp[1].sun[j].system[1].planets[p].clouds    
                      list_tiles[Ptile].sun[j].system[1].planets[p].shadows = list_tiles_temp[1].sun[j].system[1].planets[p].shadows    
                      list_tiles[Ptile].sun[j].system[1].planets[p].showOrbit = list_tiles_temp[1].sun[j].system[1].planets[p].showOrbit    
                      list_tiles[Ptile].sun[j].system[1].planets[p].showClouds = list_tiles_temp[1].sun[j].system[1].planets[p].showClouds    
                      list_tiles[Ptile].sun[j].system[1].planets[p].showShadow = list_tiles_temp[1].sun[j].system[1].planets[p].showShadow    
                      list_tiles[Ptile].sun[j].system[1].planets[p].showPlanetViewShadow = list_tiles_temp[1].sun[j].system[1].planets[p].showPlanetViewShadow    
                      list_tiles[Ptile].sun[j].system[1].planets[p].isSelected = list_tiles_temp[1].sun[j].system[1].planets[p].isSelected    
                      list_tiles[Ptile].sun[j].system[1].planets[p].hover = list_tiles_temp[1].sun[j].system[1].planets[p].hover    
                      list_tiles[Ptile].sun[j].system[1].planets[p].here = list_tiles_temp[1].sun[j].system[1].planets[p].here    
                      list_tiles[Ptile].sun[j].system[1].planets[p].discover = list_tiles_temp[1].sun[j].system[1].planets[p].discover    
                      list_tiles[Ptile].sun[j].system[1].planets[p].ellipse = list_tiles_temp[1].sun[j].system[1].planets[p].ellipse  
                    
                    if  list_tiles[Ptile].sun[j].system[1].planets[p].moon.n ~= nil then
                      for m=1, list_tiles[Ptile].sun[j].system[1].planets[p].moon.n do
                          list_tiles[Ptile].sun[j].system[1].planets[p].moon[m].pId = list_tiles_temp[1].sun[j].system[1].planets[p].moon[m].pId  
                          list_tiles[Ptile].sun[j].system[1].planets[p].moon[m].xPlanet = list_tiles_temp[1].sun[j].system[1].planets[p].moon[m].xPlanet
                          list_tiles[Ptile].sun[j].system[1].planets[p].moon[m].yPlanet = list_tiles_temp[1].sun[j].system[1].planets[p].moon[m].yPlanet 
                          list_tiles[Ptile].sun[j].system[1].planets[p].moon[m].xShadowPlanet = list_tiles_temp[1].sun[j].system[1].planets[p].moon[m].xShadowPlanet 
                          list_tiles[Ptile].sun[j].system[1].planets[p].moon[m].pId = list_tiles_temp[1].sun[j].system[1].planets[p].moon[m].pId 
                          list_tiles[Ptile].sun[j].system[1].planets[p].moon[m].rPlanet = list_tiles_temp[1].sun[j].system[1].planets[p].moon[m].rPlanet  
                          list_tiles[Ptile].sun[j].system[1].planets[p].moon[m].pole = list_tiles_temp[1].sun[j].system[1].planets[p].moon[m].pole   
                          list_tiles[Ptile].sun[j].system[1].planets[p].moon[m].type = list_tiles_temp[1].sun[j].system[1].planets[p].moon[m].type   
                          list_tiles[Ptile].sun[j].system[1].planets[p].moon[m].luck = list_tiles_temp[1].sun[j].system[1].planets[p].moon[m].luck  
                          list_tiles[Ptile].sun[j].system[1].planets[p].moon[m].birth = list_tiles_temp[1].sun[j].system[1].planets[p].moon[m].birth  
                          list_tiles[Ptile].sun[j].system[1].planets[p].moon[m].death = list_tiles_temp[1].sun[j].system[1].planets[p].moon[m].death    
                          list_tiles[Ptile].sun[j].system[1].planets[p].moon[m].color = list_tiles_temp[1].sun[j].system[1].planets[p].moon[m].color  
                          list_tiles[Ptile].sun[j].system[1].planets[p].moon[m].poleColor = list_tiles_temp[1].sun[j].system[1].planets[p].moon[m].poleColor      
                          list_tiles[Ptile].sun[j].system[1].planets[p].moon[m].os = list_tiles_temp[1].sun[j].system[1].planets[p].moon[m].os   
                          list_tiles[Ptile].sun[j].system[1].planets[p].moon[m].planetView = list_tiles_temp[1].sun[j].system[1].planets[p].moon[m].planetView                     
                      end
                    end
                end 


                list_tiles[Ptile].sun[j].system[1].sun.tileId = list_tiles_temp[1].sun[j].tileId
                list_tiles[Ptile].sun[j].system[1].sun.sunId = list_tiles_temp[1].sun[j].sunId
                list_tiles[Ptile].sun[j].system[1].sun.id = list_tiles_temp[1].sun[j].id
                list_tiles[Ptile].sun[j].system[1].sun.name = list_tiles_temp[1].sun[j].name
                list_tiles[Ptile].sun[j].system[1].sun.type = list_tiles_temp[1].sun[j].type
                list_tiles[Ptile].sun[j].system[1].sun.viewType = list_tiles_temp[1].sun[j].viewType
                list_tiles[Ptile].sun[j].system[1].sun.x = list_tiles_temp[1].sun[j].x
                list_tiles[Ptile].sun[j].system[1].sun.y = list_tiles_temp[1].sun[j].y
                list_tiles[Ptile].sun[j].system[1].sun.c = list_tiles_temp[1].sun[j].c
                list_tiles[Ptile].sun[j].system[1].sun.l = list_tiles_temp[1].sun[j].l
                list_tiles[Ptile].sun[j].system[1].sun.posX = list_tiles_temp[1].sun[j].posX
                list_tiles[Ptile].sun[j].system[1].sun.posY = list_tiles_temp[1].sun[j].posY
                list_tiles[Ptile].sun[j].system[1].sun.here = list_tiles_temp[1].sun[j].here
                list_tiles[Ptile].sun[j].system[1].sun.discover = list_tiles_temp[1].sun[j].discover
                list_tiles[Ptile].sun[j].system[1].sun.xo = list_tiles_temp[1].sun[j].xo
                list_tiles[Ptile].sun[j].system[1].sun.yo = list_tiles_temp[1].sun[j].yo
                list_tiles[Ptile].sun[j].system[1].sun.celsus = list_tiles_temp[1].sun[j].celsus
                list_tiles[Ptile].sun[j].system[1].sun.light = list_tiles_temp[1].sun[j].light
                list_tiles[Ptile].sun[j].system[1].sun.radius = list_tiles_temp[1].sun[j].radius
                list_tiles[Ptile].sun[j].system[1].sun.diameter = list_tiles_temp[1].sun[j].diameter
                list_tiles[Ptile].sun[j].system[1].sun.scale = list_tiles_temp[1].sun[j].scale
                list_tiles[Ptile].sun[j].system[1].sun.galaxyView = list_tiles_temp[1].sun[j].galaxyView
                list_tiles[Ptile].sun[j].system[1].sun.systemView = list_tiles_temp[1].sun[j].systemView
                list_tiles[Ptile].sun[j].system[1].sun.galaxyZoom = list_tiles_temp[1].sun[j].galaxyZoom
                list_tiles[Ptile].sun[j].system[1].sun.star = list_tiles_temp[1].sun[j].star
                list_tiles[Ptile].sun[j].system[1].sun.light = list_tiles_temp[1].sun[j].light
                list_tiles[Ptile].sun[j].system[1].sun.color = list_tiles_temp[1].sun[j].color
                list_tiles[Ptile].sun[j].system[1].sun.infos = list_tiles_temp[1].sun[j].infos
                list_tiles[Ptile].sun[j].system[1].sun.hover = list_tiles_temp[1].sun[j].hover
                list_tiles[Ptile].sun[j].system[1].sun.isSelected = list_tiles_temp[1].sun[j].isSelected
                list_tiles[Ptile].sun[j].system[1].sun.isVisible = list_tiles_temp[1].sun[j].isVisible
                list_tiles[Ptile].sun[j].system[1].sun.debug = list_tiles_temp[1].sun[j].debug               
              
              list_tiles[Ptile].sun[j].system[1].isVisited = list_tiles_temp[1].sun[j].system[1].isVisited
              list_tiles[Ptile].sun[j].system[1].showOrbits = list_tiles_temp[1].sun[j].system[1].showOrbits
              list_tiles[Ptile].sun[j].system[1].showClouds = list_tiles_temp[1].sun[j].system[1].showClouds
              list_tiles[Ptile].sun[j].system[1].showShadows = list_tiles_temp[1].sun[j].system[1].showShadows
              list_tiles[Ptile].sun[j].system[1].play = list_tiles_temp[1].sun[j].system[1].play
              list_tiles[Ptile].sun[j].system[1].debug = list_tiles_temp[1].sun[j].system[1].debug 
            end
          end  
    end
  end 
 end 
  for i=#list_tiles_temp,1,-1 do
  table.remove(list_tiles_temp,i) 
  end
end  


function data.LoadMap()

  -- On prevoit de sauver la tile de départ
  table.insert(TILE_SAVE, {TILE_HERE,SUN_HERE})
  
  
  -- On compte le nombre de tile existante
  local MAPTILESNUMBER = nil
  local files = love.filesystem.getDirectoryItems("MAP")
  for k,v in ipairs(files) do
    if string.find(v,".as")~= nil then
      MAPTILESNUMBER = k
    end
  end 
  
  -- On charge les tiles dans une table temporaire
  for i=1, MAPTILESNUMBER do
    local tile = table.load(FILEDIRECTORY.."/MAP/TILE_"..i..".as")
    table.insert(list_tiles_temp,tile) 
  end 




  -- On reconstitue la MAP galactique
  for i=1, #list_tiles_temp do
    local tile = map.NewTile(0,0,0,0,#list_tiles+1,false)
    table.insert(list_tiles,tile)

    if #list_tiles_temp[i].sun~=0 then 
      for j=1,#list_tiles_temp[i].sun do
        -- Creation des soleils
        local newSun = sun.new(0, 0, 0, 0, 0, 0, 0, 0, 0)
        table.insert(list_tiles[i].sun,newSun)

      end
      
    end 
  end
  
  list_box[1].content[2].matter = "   Chargement des tiles "..#list_tiles
    -------------- Chargement des données -------------- 
  for i=1,#list_tiles do
    list_tiles[i].id = list_tiles_temp[i].id
    list_tiles[i].x = list_tiles_temp[i].x
    list_tiles[i].y = list_tiles_temp[i].y
    list_tiles[i].idX = list_tiles_temp[i].idX
    list_tiles[i].idY = list_tiles_temp[i].idY
    list_tiles[i].color = list_tiles_temp[i].color
    list_tiles[i].isVisible = list_tiles_temp[i].isVisible
    list_tiles[i].discover =  list_tiles_temp[i].discover
    list_tiles[i].cellSize = list_tiles_temp[i].cellSize
    list_tiles[i].c = list_tiles_temp[i].c
    list_tiles[i].l = list_tiles_temp[i].l
    list_tiles[i].w = list_tiles_temp[i].w
    list_tiles[i].h = list_tiles_temp[i].h
    list_tiles[i].dx = list_tiles_temp[i].dx
    list_tiles[i].dy = list_tiles_temp[i].dy
    
    list_tiles[i].name = list_tiles_temp[i].name
    
    list_tiles[i].grid = list_tiles_temp[i].grid


  if #list_tiles[i].sun ~= 0 then 
    for j = 1, #list_tiles[i].sun do
      list_tiles[i].sun[j].tileId = list_tiles_temp[i].sun[j].tileId
      list_tiles[i].sun[j].sunId = list_tiles_temp[i].sun[j].sunId
      list_tiles[i].sun[j].id = list_tiles_temp[i].sun[j].id
      list_tiles[i].sun[j].name = list_tiles_temp[i].sun[j].name
      list_tiles[i].sun[j].type = list_tiles_temp[i].sun[j].type
      list_tiles[i].sun[j].viewType = list_tiles_temp[i].sun[j].viewType
      list_tiles[i].sun[j].x = list_tiles_temp[i].sun[j].x
      list_tiles[i].sun[j].y = list_tiles_temp[i].sun[j].y
      list_tiles[i].sun[j].c = list_tiles_temp[i].sun[j].c
      list_tiles[i].sun[j].l = list_tiles_temp[i].sun[j].l
      list_tiles[i].sun[j].posX = list_tiles_temp[i].sun[j].posX 
      list_tiles[i].sun[j].posY = list_tiles_temp[i].sun[j].posY
      list_tiles[i].sun[j].posX_Z1 = list_tiles_temp[i].sun[j].posX_Z1
      list_tiles[i].sun[j].posY_Z1 = list_tiles_temp[i].sun[j].posY_Z1
      list_tiles[i].sun[j].posX_Z2 = list_tiles_temp[i].sun[j].posX_Z2
      list_tiles[i].sun[j].posY_Z2 = list_tiles_temp[i].sun[j].posY_Z2   
      list_tiles[i].sun[j].here = list_tiles_temp[i].sun[j].here
      list_tiles[i].sun[j].discover = list_tiles_temp[i].sun[j].discover
      list_tiles[i].sun[j].totalPlanets = list_tiles_temp[i].sun[j].totalPlanets      
      list_tiles[i].sun[j].xo = list_tiles_temp[i].sun[j].xo
      list_tiles[i].sun[j].yo = list_tiles_temp[i].sun[j].yo
      list_tiles[i].sun[j].celsus = list_tiles_temp[i].sun[j].celsus
      list_tiles[i].sun[j].light = list_tiles_temp[i].sun[j].light
      list_tiles[i].sun[j].radius = list_tiles_temp[i].sun[j].radius
      list_tiles[i].sun[j].diameter = list_tiles_temp[i].sun[j].diameter
      list_tiles[i].sun[j].scale = list_tiles_temp[i].sun[j].scale
      list_tiles[i].sun[j].galaxyView = list_tiles_temp[i].sun[j].galaxyView
      list_tiles[i].sun[j].systemView = list_tiles_temp[i].sun[j].systemView
      list_tiles[i].sun[j].galaxyZoom = list_tiles_temp[i].sun[j].galaxyZoom
      list_tiles[i].sun[j].star = list_tiles_temp[i].sun[j].star
      list_tiles[i].sun[j].light = list_tiles_temp[i].sun[j].light
      list_tiles[i].sun[j].color = list_tiles_temp[i].sun[j].color
      list_tiles[i].sun[j].infos = list_tiles_temp[i].sun[j].infos
      list_tiles[i].sun[j].hover = list_tiles_temp[i].sun[j].hover
      list_tiles[i].sun[j].isSelected = list_tiles_temp[i].sun[j].isSelected
      list_tiles[i].sun[j].isVisible = list_tiles_temp[i].sun[j].isVisible
      list_tiles[i].sun[j].debug = list_tiles_temp[i].sun[j].debug
      --- SAUVEGARDE SYSTEME ---

          for k=1,1 do
            if #list_tiles[i].sun[j].system~=0 then 
              list_tiles[i].sun[j].system[1].name = list_tiles_temp[i].sun[j].system[1].name
              list_tiles[i].sun[j].system[1].ID = list_tiles_temp[i].sun[j].system[1].ID
              list_tiles[i].sun[j].system[1].x = list_tiles_temp[i].sun[j].system[1].x
              list_tiles[i].sun[j].system[1].y = list_tiles_temp[i].sun[j].system[1].y
              list_tiles[i].sun[j].system[1].width = list_tiles_temp[i].sun[j].system[1].width
              list_tiles[i].sun[j].system[1].height = list_tiles_temp[i].sun[j].system[1].height
              list_tiles[i].sun[j].system[1].rotationType = list_tiles_temp[i].sun[j].system[1].rotationType
              list_tiles[i].sun[j].system[1].totalPlanets = list_tiles_temp[i].sun[j].system[1].totalPlanets
              list_tiles[i].sun[j].system[1].currentPlanet = list_tiles_temp[i].sun[j].system[1].currentPlanet
              list_tiles[i].sun[j].system[1].systemView = list_tiles_temp[i].sun[j].system[1].systemView
              list_tiles[i].sun[j].system[1].sun.tileId = list_tiles_temp[i].sun[j].tileId
              list_tiles[i].sun[j].system[1].sun.sunId = list_tiles_temp[i].sun[j].sunId
              list_tiles[i].sun[j].system[1].sun.id = list_tiles_temp[i].sun[j].id
              list_tiles[i].sun[j].system[1].sun.name = list_tiles_temp[i].sun[j].name
              list_tiles[i].sun[j].system[1].sun.type = list_tiles_temp[i].sun[j].type
              list_tiles[i].sun[j].system[1].sun.viewType = list_tiles_temp[i].sun[j].viewType
              list_tiles[i].sun[j].system[1].sun.x = list_tiles_temp[i].sun[j].x
              list_tiles[i].sun[j].system[1].sun.y = list_tiles_temp[i].sun[j].y
              list_tiles[i].sun[j].system[1].sun.c = list_tiles_temp[i].sun[j].c
              list_tiles[i].sun[j].system[1].sun.l = list_tiles_temp[i].sun[j].l
              list_tiles[i].sun[j].system[1].sun.posX = list_tiles_temp[i].sun[j].posX
              list_tiles[i].sun[j].system[1].sun.posY = list_tiles_temp[i].sun[j].posY
              list_tiles[i].sun[j].system[1].sun.here = list_tiles_temp[i].sun[j].here
              list_tiles[i].sun[j].system[1].sun.discover = list_tiles_temp[i].sun[j].discover
              list_tiles[i].sun[j].system[1].sun.xo = list_tiles_temp[i].sun[j].xo
              list_tiles[i].sun[j].system[1].sun.yo = list_tiles_temp[i].sun[j].yo
              list_tiles[i].sun[j].system[1].sun.celsus = list_tiles_temp[i].sun[j].celsus
              list_tiles[i].sun[j].system[1].sun.light = list_tiles_temp[i].sun[j].light
              list_tiles[i].sun[j].system[1].sun.radius = list_tiles_temp[i].sun[j].radius
              list_tiles[i].sun[j].system[1].sun.diameter = list_tiles_temp[i].sun[j].diameter
              list_tiles[i].sun[j].system[1].sun.scale = list_tiles_temp[i].sun[j].scale
              list_tiles[i].sun[j].system[1].sun.galaxyView = list_tiles_temp[i].sun[j].galaxyView
              list_tiles[i].sun[j].system[1].sun.systemView = list_tiles_temp[i].sun[j].systemView
              list_tiles[i].sun[j].system[1].sun.galaxyZoom = list_tiles_temp[i].sun[j].galaxyZoom
              list_tiles[i].sun[j].system[1].sun.star = list_tiles_temp[i].sun[j].star
              list_tiles[i].sun[j].system[1].sun.light = list_tiles_temp[i].sun[j].light
              list_tiles[i].sun[j].system[1].sun.color = list_tiles_temp[i].sun[j].color
              list_tiles[i].sun[j].system[1].sun.infos = list_tiles_temp[i].sun[j].infos
              list_tiles[i].sun[j].system[1].sun.hover = list_tiles_temp[i].sun[j].hover
              list_tiles[i].sun[j].system[1].sun.isSelected = list_tiles_temp[i].sun[j].isSelected
              list_tiles[i].sun[j].system[1].sun.isVisible = list_tiles_temp[i].sun[j].isVisible
              list_tiles[i].sun[j].system[1].sun.debug = list_tiles_temp[i].sun[j].debug               
              list_tiles[i].sun[j].system[1].isVisited = list_tiles_temp[i].sun[j].system[1].isVisited
              list_tiles[i].sun[j].system[1].showOrbits = list_tiles_temp[i].sun[j].system[1].showOrbits
              list_tiles[i].sun[j].system[1].showClouds = list_tiles_temp[i].sun[j].system[1].showClouds
              list_tiles[i].sun[j].system[1].showShadows = list_tiles_temp[i].sun[j].system[1].showShadows
              list_tiles[i].sun[j].system[1].play = list_tiles_temp[i].sun[j].system[1].play
              list_tiles[i].sun[j].system[1].debug = list_tiles_temp[i].sun[j].system[1].debug 
            end
          end  
    end
  end 
 end 
  for i=#list_tiles_temp,1,-1 do
  table.remove(list_tiles_temp,i)
  end
       data.LoadSystem(TILE_HERE)
end

function data.parameterLoad()  
  list_parameter = {}

  local files = love.filesystem.getDirectoryItems("MAP")
  for k,v in ipairs(files) do
    if string.find(v,".ini")~= nil then

      local parameter = table.load(FILEDIRECTORY.."/MAP/parameter.ini") 
        LANGUAGE = parameter.LANGUAGE 
        RESO_WIDTH = parameter.RESO_WIDTH
        RESO_HEIGHT = parameter.RESO_HEIGHT
        GAME = parameter.GAME 
        SAVE = parameter.SAVE 
        TILES_LOAD = parameter.TILES_LOAD 
        TILE_HERE = parameter.TILE_HERE 
        SUN_HERE = parameter.SUN_HERE 
        ZOOM = parameter.ZOOM 
        SYSTEM_DISCOVER = parameter.SYSTEM_DISCOVER
    end
  end 
  

end

function data.parameterSave()

  local parameter = {}
  parameter.LANGUAGE = LANGUAGE
  parameter.RESO_WIDTH = RESO_WIDTH
  parameter.RESO_HEIGHT = RESO_HEIGHT
  parameter.GAME = GAME
  parameter.SAVE = SAVE 
  parameter.TILES_LOAD = #list_tiles 
  parameter.TILE_HERE = TILE_HERE 
  parameter.SUN_HERE = SUN_HERE
  parameter.ZOOM = ZOOM 
  parameter.SYSTEM_DISCOVER = SYSTEM_DISCOVER
  table.save(parameter,FILEDIRECTORY.."/MAP/".."parameter.ini")
end



function data.SaveMap(pTile)

      local tile = {}
      tile.id = list_tiles[pTile].id
      tile.x = list_tiles[pTile].x
      tile.y = list_tiles[pTile].y
      tile.idX = list_tiles[pTile].idX
      tile.idY = list_tiles[pTile].idY
      tile.color = list_tiles[pTile].color
      tile.isVisible = list_tiles[pTile].isVisible
      tile.discover =  list_tiles[pTile].discover
      tile.cellSize = list_tiles[pTile].cellSize
      tile.c = list_tiles[pTile].c
      tile.l = list_tiles[pTile].l
      tile.w = list_tiles[pTile].w
      tile.h = list_tiles[pTile].h
      tile.dx = list_tiles[pTile].dx
      tile.dy = list_tiles[pTile].dy
      
      tile.name = list_tiles[pTile].name
      
      tile.grid = list_tiles[pTile].grid
      tile.sun = {}
      for j = 1, #list_tiles[pTile].sun do
        local newSun = {} 
        newSun.tileId = list_tiles[pTile].sun[j].tileId
        newSun.sunId = list_tiles[pTile].sun[j].sunId
        newSun.id = list_tiles[pTile].sun[j].id
        newSun.name = list_tiles[pTile].sun[j].name
        newSun.type = list_tiles[pTile].sun[j].type
        newSun.viewType = list_tiles[pTile].sun[j].viewType
        newSun.x = list_tiles[pTile].sun[j].x
        newSun.y = list_tiles[pTile].sun[j].y
        newSun.c = list_tiles[pTile].sun[j].c
        newSun.l = list_tiles[pTile].sun[j].l
        newSun.posX = list_tiles[pTile].sun[j].posX
        newSun.posY = list_tiles[pTile].sun[j].posY
        newSun.posX_Z1 = list_tiles[pTile].sun[j].posX_Z1
        newSun.posY_Z1 = list_tiles[pTile].sun[j].posY_Z1
        newSun.posX_Z2 = list_tiles[pTile].sun[j].posX_Z2
        newSun.posY_Z2 = list_tiles[pTile].sun[j].posY_Z2     
        newSun.here = list_tiles[pTile].sun[j].here
        newSun.discover = list_tiles[pTile].sun[j].discover
        newSun.totalPlanets = list_tiles[pTile].sun[j].totalPlanets
        newSun.xo = list_tiles[pTile].sun[j].xo 
        newSun.yo = list_tiles[pTile].sun[j].yo
        newSun.celsus = list_tiles[pTile].sun[j].celsus
        newSun.light = list_tiles[pTile].sun[j].light
        newSun.radius = list_tiles[pTile].sun[j].radius
        newSun.diameter = list_tiles[pTile].sun[j].diameter
        newSun.scale = list_tiles[pTile].sun[j].scale
        newSun.galaxyView = list_tiles[pTile].sun[j].galaxyView
        newSun.systemView = list_tiles[pTile].sun[j].systemView
        newSun.galaxyZoom = list_tiles[pTile].sun[j].galaxyZoom
        newSun.star = list_tiles[pTile].sun[j].star
        newSun.light = list_tiles[pTile].sun[j].light
        newSun.color = list_tiles[pTile].sun[j].color
        newSun.infos = list_tiles[pTile].sun[j].infos
        newSun.hover = list_tiles[pTile].sun[j].hover
        newSun.isSelected = list_tiles[pTile].sun[j].isSelected
        newSun.isVisible = list_tiles[pTile].sun[j].isVisible
        newSun.debug = list_tiles[pTile].sun[j].debug 
        --- SAUVEGARDE SYSTEME ---
        newSun.system = {}
        
            for k=1,1 do
              local newSystem = {}
              if #list_tiles[pTile].sun[j].system~=0 then
                newSystem.name = list_tiles[pTile].sun[j].system[1].name
                newSystem.ID = list_tiles[pTile].sun[j].system[1].ID
                newSystem.x = list_tiles[pTile].sun[j].system[1].x
                newSystem.y = list_tiles[pTile].sun[j].system[1].y
                newSystem.width = list_tiles[pTile].sun[j].system[1].width
                newSystem.height = list_tiles[pTile].sun[j].system[1].height
                newSystem.rotationType = list_tiles[pTile].sun[j].system[1].rotationType
                newSystem.totalPlanets = list_tiles[pTile].sun[j].system[1].totalPlanets 
                newSystem.currentPlanet = list_tiles[pTile].sun[j].system[1].currentPlanet
                newSystem.systemView = list_tiles[pTile].sun[j].system[1].systemView
                newSystem.planets = {}
                  for p=1,newSystem.totalPlanets do

                      local newPlanet = {}
                        newPlanet.id = list_tiles[pTile].sun[j].system[1].planets[p].id
                        newPlanet.name = list_tiles[pTile].sun[j].system[1].planets[p].name
                        newPlanet.type = list_tiles[pTile].sun[j].system[1].planets[p].type
                        newPlanet.biome = list_tiles[pTile].sun[j].system[1].planets[p].biome
                        newPlanet.viewType = list_tiles[pTile].sun[j].system[1].planets[p].viewType
                        newPlanet.rotationType = list_tiles[pTile].sun[j].system[1].planets[p].rotationType
                        newPlanet.x = list_tiles[pTile].sun[j].system[1].planets[p].x
                        newPlanet.y = list_tiles[pTile].sun[j].system[1].planets[p].y
                        newPlanet.xo = list_tiles[pTile].sun[j].system[1].planets[p].xo
                        newPlanet.yo = list_tiles[pTile].sun[j].system[1].planets[p].yo
                        newPlanet.angle = list_tiles[pTile].sun[j].system[1].planets[p].angle
                        newPlanet.radius = list_tiles[pTile].sun[j].system[1].planets[p].radius
                        newPlanet.diameter = list_tiles[pTile].sun[j].system[1].planets[p].diameter
                        newPlanet.orbitalSpeed = list_tiles[pTile].sun[j].system[1].planets[p].orbitalSpeed
                        newPlanet.speedRotation = list_tiles[pTile].sun[j].system[1].planets[p].speedRotation
                        newPlanet.time = list_tiles[pTile].sun[j].system[1].planets[p].time
                        newPlanet.timeShadow = list_tiles[pTile].sun[j].system[1].planets[p].timeShadow
                        newPlanet.positionShadow = list_tiles[pTile].sun[j].system[1].planets[p].positionShadow
                        newPlanet.speedTimeShadow = list_tiles[pTile].sun[j].system[1].planets[p].speedTimeShadow
                        newPlanet.speedRotateShadow = list_tiles[pTile].sun[j].system[1].planets[p].speedRotateShadow
                        newPlanet.sunDistance = list_tiles[pTile].sun[j].system[1].planets[p].sunDistance
                        newPlanet.scale = list_tiles[pTile].sun[j].system[1].planets[p].scale
                        newPlanet.moon = {}
                        newPlanet.moon.n = list_tiles[pTile].sun[j].system[1].planets[p].moon.n 
                        newPlanet.colony = list_tiles[pTile].sun[j].system[1].planets[p].colony
                        newPlanet.background = list_tiles[pTile].sun[j].system[1].planets[p].background
                        newPlanet.orb = list_tiles[pTile].sun[j].system[1].planets[p].orb
                        newPlanet.systemView = list_tiles[pTile].sun[j].system[1].planets[p].systemView
                        newPlanet.planetView = list_tiles[pTile].sun[j].system[1].planets[p].planetView
                        newPlanet.luck = list_tiles[pTile].sun[j].system[1].planets[p].luck
                        newPlanet.cloudLuck = list_tiles[pTile].sun[j].system[1].planets[p].cloudLuck
                        newPlanet.cloudHeight = list_tiles[pTile].sun[j].system[1].planets[p].cloudHeight
                        newPlanet.shadeGradient = list_tiles[pTile].sun[j].system[1].planets[p].shadeGradient
                        newPlanet.pole = list_tiles[pTile].sun[j].system[1].planets[p].pole
                        newPlanet.radiusIce = list_tiles[pTile].sun[j].system[1].planets[p].radiusIce
                        newPlanet.poleColor = list_tiles[pTile].sun[j].system[1].planets[p].poleColor
                        newPlanet.color = list_tiles[pTile].sun[j].system[1].planets[p].color
                        newPlanet.infos = list_tiles[pTile].sun[j].system[1].planets[p].infos                     
                        newPlanet.rings = list_tiles[pTile].sun[j].system[1].planets[p].rings    
                        newPlanet.clouds = list_tiles[pTile].sun[j].system[1].planets[p].clouds    
                        newPlanet.shadows = list_tiles[pTile].sun[j].system[1].planets[p].shadows    
                        newPlanet.showOrbit = list_tiles[pTile].sun[j].system[1].planets[p].showOrbit    
                        newPlanet.showClouds = list_tiles[pTile].sun[j].system[1].planets[p].showClouds    
                        newPlanet.showShadow = list_tiles[pTile].sun[j].system[1].planets[p].showShadow    
                        newPlanet.showPlanetViewShadow = list_tiles[pTile].sun[j].system[1].planets[p].showPlanetViewShadow 
                        newPlanet.isSelected = list_tiles[pTile].sun[j].system[1].planets[p].isSelected    
                        newPlanet.hover = list_tiles[pTile].sun[j].system[1].planets[p].hover    
                        newPlanet.here = list_tiles[pTile].sun[j].system[1].planets[p].here    
                        newPlanet.discover = list_tiles[pTile].sun[j].system[1].planets[p].discover    
                        newPlanet.ellipse = list_tiles[pTile].sun[j].system[1].planets[p].ellipse  
                        
                        if newPlanet.moon.n ~= nil then
                          for m=1, newPlanet.moon.n do
                            local newMoon = {}
                            newMoon.pId = list_tiles[pTile].sun[j].system[1].planets[p].moon[m].pId
                            newMoon.xPlanet = list_tiles[pTile].sun[j].system[1].planets[p].moon[m].xPlanet
                            newMoon.yPlanet = list_tiles[pTile].sun[j].system[1].planets[p].moon[m].yPlanet
                            newMoon.xShadowPlanet = list_tiles[pTile].sun[j].system[1].planets[p].moon[m].xShadowPlanet
                            newMoon.rPlanet = list_tiles[pTile].sun[j].system[1].planets[p].moon[m].rPlanet
                            newMoon.pole = list_tiles[pTile].sun[j].system[1].planets[p].moon[m].pole
                            newMoon.type = list_tiles[pTile].sun[j].system[1].planets[p].moon[m].type
                            newMoon.luck = list_tiles[pTile].sun[j].system[1].planets[p].moon[m].luck
                            newMoon.birth = list_tiles[pTile].sun[j].system[1].planets[p].moon[m].birth
                            newMoon.death = list_tiles[pTile].sun[j].system[1].planets[p].moon[m].death
                            newMoon.color = list_tiles[pTile].sun[j].system[1].planets[p].moon[m].color
                            newMoon.poleColor = list_tiles[pTile].sun[j].system[1].planets[p].moon[m].poleColor
                            newMoon.os = list_tiles[pTile].sun[j].system[1].planets[p].moon[m].os
                            newMoon.planetView = list_tiles[pTile].sun[j].system[1].planets[p].moon[m].planetView
                            table.insert(newPlanet.moon,newMoon)
                          end
                        end
                    table.insert(newSystem.planets,newPlanet)
                  end

                newSystem.sun = {}
                  local newSun = {} 
                  newSystem.sun.tileId = list_tiles[pTile].sun[j].tileId
                  newSystem.sun.sunId = list_tiles[pTile].sun[j].sunId
                  newSystem.sun.id = list_tiles[pTile].sun[j].id
                  newSystem.sun.name = list_tiles[pTile].sun[j].name
                  newSystem.sun.type = list_tiles[pTile].sun[j].type
                  newSystem.sun.viewType = list_tiles[pTile].sun[j].viewType
                  newSystem.sun.x = list_tiles[pTile].sun[j].x
                  newSystem.sun.y = list_tiles[pTile].sun[j].y
                  newSystem.sun.c = list_tiles[pTile].sun[j].c
                  newSystem.sun.l = list_tiles[pTile].sun[j].l
                  newSystem.sun.posX = list_tiles[pTile].sun[j].posX
                  newSystem.sun.posY = list_tiles[pTile].sun[j].posY
                  newSystem.sun.here = list_tiles[pTile].sun[j].here
                  newSystem.sun.discover = list_tiles[pTile].sun[j].discover
                  newSystem.sun.xo = list_tiles[pTile].sun[j].xo
                  newSystem.sun.yo = list_tiles[pTile].sun[j].yo
                  newSystem.sun.celsus = list_tiles[pTile].sun[j].celsus
                  newSystem.sun.light = list_tiles[pTile].sun[j].light
                  newSystem.sun.radius = list_tiles[pTile].sun[j].radius
                  newSystem.sun.diameter = list_tiles[pTile].sun[j].diameter
                  newSystem.sun.scale = list_tiles[pTile].sun[j].scale
                  newSystem.sun.galaxyView = list_tiles[pTile].sun[j].galaxyView
                  newSystem.sun.systemView = list_tiles[pTile].sun[j].systemView
                  newSystem.sun.galaxyZoom = list_tiles[pTile].sun[j].galaxyZoom
                  newSystem.sun.star = list_tiles[pTile].sun[j].star
                  newSystem.sun.light = list_tiles[pTile].sun[j].light
                  newSystem.sun.color = list_tiles[pTile].sun[j].color
                  newSystem.sun.infos = list_tiles[pTile].sun[j].infos
                  newSystem.sun.hover = list_tiles[pTile].sun[j].hover
                  newSystem.sun.isSelected = list_tiles[pTile].sun[j].isSelected
                  newSystem.sun.isVisible = list_tiles[pTile].sun[j].isVisible
                  newSystem.sun.debug = list_tiles[pTile].sun[j].debug               
                
                newSystem.isVisited = list_tiles[pTile].sun[j].system[1].isVisited
                newSystem.showOrbits = list_tiles[pTile].sun[j].system[1].showOrbits
                newSystem.showClouds = list_tiles[pTile].sun[j].system[1].showClouds
                newSystem.showShadows = list_tiles[pTile].sun[j].system[1].showShadows
                newSystem.play = list_tiles[pTile].sun[j].system[1].play
                newSystem.debug = list_tiles[pTile].sun[j].system[1].debug 
              end
            table.insert(newSun.system,newSystem)          
            end  
        table.insert(tile.sun,newSun)
      end

      table.save(tile,FILEDIRECTORY.."/MAP/".."TILE_"..pTile..".as")
end

 

return data