local boxWindow = require ("script/boxWindow")
game_galaxy = {}

local player = require ("player")
local displacement = require ("script/displacement")
local system = require ("system")
local sun = require ("sun")
local map = require ("map")
local game_parameter = require ("game_parameter")



local lock = {}
lock.x, lock.y, lock.r = 0, 0, 0
lock.sprite = love.graphics.newImage("sprites/lock.png")
lock.sprite_2 = love.graphics.newImage("sprites/lock_2.png")
lock.w = lock.sprite:getWidth()
lock.h = lock.sprite:getHeight()

list_pointA = {}
list_pointB = {}
pointA = false
pointB = false


chunk = false

-- Fonction mathématiques
function math.dist(x1,y1, x2,y2) return ((x2-x1)^2+(y2-y1)^2)^0.5 end

-- PARAMETRES GUI
local scale = 0.8
toolbar = {}
icon = {}

function ButtonLine()
 buttonLine = true
end

function ButtonSystem()
  if GAME == "galaxy" or GAME == "planet" then
    GAME = "system"
  end
end

function ButtonGalaxy()
  if GAME == "system" or GAME == "planet" then
    GAME = "galaxy"
  end
end

function ButtonCockpit()
  if GAME == "galaxy" or GAME == "system" then
    GAME = "planet"
  end
end

  local oldMouseX, oldMouseY
  
function MouseMapGalaxy()
  
  if love.mouse.isDown(3) == false then
  oldMouseX, oldMouseY = love.mouse.getPosition()   

    for i=1, #list_tiles do
      list_tiles[i].dx = oldMouseX - list_tiles[i].x
      list_tiles[i].dy = oldMouseY - list_tiles[i].y
    end 
  end

  if love.mouse.isDown(3) then
    UpdateTile() 
      local x,y = love.mouse.getPosition()
      for i=1, #list_tiles do
        list_tiles[i].x = x - list_tiles[i].dx
        list_tiles[i].y = y - list_tiles[i].dy     
      end 
  end
end

-- calcul position soleil/tuile
function UpdateTile()    
      for i=1, #list_tiles do
          -- parcours de tiles
          for j=1, #list_tiles[i].sun do
              -- parcours de soleil dans chaque tuiles pour actualiser sa position par rapport a celle de sa tuile
             
              list_tiles[i].sun[j]:setCoordinates(list_tiles[i].x + (list_tiles[i].sun[j].c-1)*(list_tiles[i].cellSize) + list_tiles[i].sun[j].posX, list_tiles[i].y + (list_tiles[i].sun[j].l-1)*(list_tiles[i].cellSize)+ list_tiles[i].sun[j].posY)

            --Update des trajets
            displacement.UpdateLine()
          end
      end
end

function SunTextDiscover()
  for i=1,#SUN_DISCOVER do
    if list_tiles[SUN_DISCOVER[i][1]].isVisible then
      if ZOOM == 2 then
        Title(list_tiles[SUN_DISCOVER[i][1]].sun[SUN_DISCOVER[i][2]].name, font.idSunDiscoverZoom_2, list_tiles[SUN_DISCOVER[i][1]].sun[SUN_DISCOVER[i][2]].x + (list_tiles[SUN_DISCOVER[i][1]].sun[SUN_DISCOVER[i][2]].radius/4)+2, list_tiles[SUN_DISCOVER[i][1]].sun[SUN_DISCOVER[i][2]].y - (list_tiles[SUN_DISCOVER[i][1]].sun[SUN_DISCOVER[i][2]].radius/4)+2, {65,160,250,180},false)
        
    elseif ZOOM == 1 then

Title(list_tiles[SUN_DISCOVER[i][1]].sun[SUN_DISCOVER[i][2]].name, font.idSunDiscoverZoom_1, list_tiles[SUN_DISCOVER[i][1]].sun[SUN_DISCOVER[i][2]].x + list_tiles[SUN_DISCOVER[i][1]].sun[SUN_DISCOVER[i][2]].radius+10, list_tiles[SUN_DISCOVER[i][1]].sun[SUN_DISCOVER[i][2]].y - list_tiles[SUN_DISCOVER[i][1]].sun[SUN_DISCOVER[i][2]].radius+20, {65,160,250,180},false)

      end
    end
  end
end

function TileIsVisible()
      -- Vérification des tuiles visibles
    for i=1, #list_tiles do list_tiles[i]:IsVisible()end
end

function RegenGalaxy(pRegen)

    if pRegen == 1 then
      
      for i=1, #list_tiles do
        if list_tiles[i].isVisible then
               list_tiles[i].cellSize = 128
               list_tiles[i].w = list_tiles[i].cellSize*list_tiles[i].c
               list_tiles[i].h = list_tiles[i].cellSize*list_tiles[i].l
              for j=1, #list_tiles[i].sun do
              list_tiles[i].sun[j]:setPos(list_tiles[i].sun[j].posX_Z1, list_tiles[i].sun[j].posY_Z1)
              end
        end
      end
      
    elseif pRegen == 2 then   
    
      for i=1, #list_tiles do
        if list_tiles[i].isVisible then
             list_tiles[i].cellSize = 128/4
             list_tiles[i].w = list_tiles[i].cellSize*list_tiles[i].c
             list_tiles[i].h = list_tiles[i].cellSize*list_tiles[i].l
            for j=1, #list_tiles[i].sun do
            list_tiles[i].sun[j]:setPos(list_tiles[i].sun[j].posX_Z1,list_tiles[i].sun[j].posY_Z1)
            end

        end
      end
    end
    
     for i=1, #list_tiles do
       for j=1, #list_tiles do
          -- droite
          if list_tiles[j].idX == list_tiles[i].idX + 1 and list_tiles[j].idY == list_tiles[i].idY then
            list_tiles[j]:setCoordinate(list_tiles[i].x + list_tiles[i].w, list_tiles[i].y)
          end
          -- gauche
          if list_tiles[j].idX == list_tiles[i].idX - 1 and list_tiles[j].idY == list_tiles[i].idY then
            list_tiles[j]:setCoordinate(list_tiles[i].x - list_tiles[i].w, list_tiles[i].y)
          end
          -- haut
          if list_tiles[j].idX == list_tiles[i].idX  and list_tiles[j].idY == list_tiles[i].idY - 1 then
            list_tiles[j]:setCoordinate(list_tiles[i].x, list_tiles[i].y - list_tiles[i].h)
          end
          -- bas 
          if list_tiles[j].idX == list_tiles[i].idX  and list_tiles[j].idY == list_tiles[i].idY + 1 then
            list_tiles[j]:setCoordinate(list_tiles[i].x, list_tiles[i].y + list_tiles[i].h)
          end    
        end
      end
end


function LoadZoom()

  if ZOOM == 1 then

      
      for i=1, #list_tiles do
        list_tiles[i]:zoom(128)  
        for j=1, #list_tiles[i].sun do
        list_tiles[i].sun[j]:setPos(list_tiles[i].sun[j].posX_Z1, list_tiles[i].sun[j].posY_Z1)
        end
      end
     
      

     for i=1, #list_tiles do
       for j=1, #list_tiles do
         
        -- droite
        if list_tiles[j].idX == list_tiles[i].idX + 1 and list_tiles[j].idY == list_tiles[i].idY then
          list_tiles[j]:setCoordinate(list_tiles[i].x + list_tiles[i].w, list_tiles[i].y)
        end
        -- gauche
        if list_tiles[j].idX == list_tiles[i].idX - 1 and list_tiles[j].idY == list_tiles[i].idY then
          list_tiles[j]:setCoordinate(list_tiles[i].x - list_tiles[i].w, list_tiles[i].y)
        end
        -- haut
        if list_tiles[j].idX == list_tiles[i].idX  and list_tiles[j].idY == list_tiles[i].idY - 1 then
          list_tiles[j]:setCoordinate(list_tiles[i].x, list_tiles[i].y - list_tiles[i].h)
        end
        -- bas 
        if list_tiles[j].idX == list_tiles[i].idX  and list_tiles[j].idY == list_tiles[i].idY + 1 then
          list_tiles[j]:setCoordinate(list_tiles[i].x, list_tiles[i].y + list_tiles[i].h)
        end    
        
      end
     end
     
      map.location()
      map.location()
  elseif ZOOM == 2 then

      
      -- Changement des icons
      icon[1]:setIcon("zoom-")
      icon[1]:setHover("zoom-_hover")      
      
      for i=1, #list_tiles do
        list_tiles[i]:zoom(128/4)  
        for j=1, #list_tiles[i].sun do
        list_tiles[i].sun[j]:setPos(list_tiles[i].sun[j].posX_Z2, list_tiles[i].sun[j].posY_Z2)
        end
      end
     
      

     for i=1, #list_tiles do
       for j=1, #list_tiles do
         
        -- droite
        if list_tiles[j].idX == list_tiles[i].idX + 1 and list_tiles[j].idY == list_tiles[i].idY then
          list_tiles[j]:setCoordinate(list_tiles[i].x + list_tiles[i].w, list_tiles[i].y)
        end
        -- gauche
        if list_tiles[j].idX == list_tiles[i].idX - 1 and list_tiles[j].idY == list_tiles[i].idY then
          list_tiles[j]:setCoordinate(list_tiles[i].x - list_tiles[i].w, list_tiles[i].y)
        end
        -- haut
        if list_tiles[j].idX == list_tiles[i].idX  and list_tiles[j].idY == list_tiles[i].idY - 1 then
          list_tiles[j]:setCoordinate(list_tiles[i].x, list_tiles[i].y - list_tiles[i].h)
        end
        -- bas 
        if list_tiles[j].idX == list_tiles[i].idX  and list_tiles[j].idY == list_tiles[i].idY + 1 then
          list_tiles[j]:setCoordinate(list_tiles[i].x, list_tiles[i].y + list_tiles[i].h)
        end    
        
      end
     end
     
     map.location()
     map.location()
    end
end



function ButtonZoom()
  if ZOOM == 1 then
      ZOOM = 2
      -- Changement des icons
      icon[1]:setIcon("zoom+")
      icon[1]:setHover("zoom+_hover")  

      for i=1, #list_tiles do
        list_tiles[i]:zoom(128/4)  
        for j=1, #list_tiles[i].sun do
        list_tiles[i].sun[j]:setPos(list_tiles[i].sun[j].posX_Z2, list_tiles[i].sun[j].posY_Z2)
        end
      end
      
     for i=1, #list_tiles do
       for j=1, #list_tiles do
         
        -- droite
        if list_tiles[j].idX == list_tiles[i].idX + 1 and list_tiles[j].idY == list_tiles[i].idY then
          list_tiles[j]:setCoordinate(list_tiles[i].x + list_tiles[i].w, list_tiles[i].y)
        end
        -- gauche
        if list_tiles[j].idX == list_tiles[i].idX - 1 and list_tiles[j].idY == list_tiles[i].idY then
          list_tiles[j]:setCoordinate(list_tiles[i].x - list_tiles[i].w, list_tiles[i].y)
        end
        -- haut
        if list_tiles[j].idX == list_tiles[i].idX  and list_tiles[j].idY == list_tiles[i].idY - 1 then
          list_tiles[j]:setCoordinate(list_tiles[i].x, list_tiles[i].y - list_tiles[i].h)
        end
        -- bas 
        if list_tiles[j].idX == list_tiles[i].idX  and list_tiles[j].idY == list_tiles[i].idY + 1 then
          list_tiles[j]:setCoordinate(list_tiles[i].x, list_tiles[i].y + list_tiles[i].h)
        end    
        
      end
     end
     
      map.location()
      map.location()
  elseif ZOOM == 2 then
      ZOOM = 1
      
      -- Changement des icons
      icon[1]:setIcon("zoom-")
      icon[1]:setHover("zoom-_hover")      

      for i=1, #list_tiles do
        list_tiles[i]:zoom(128)  
        for j=1, #list_tiles[i].sun do
        list_tiles[i].sun[j]:setPos(list_tiles[i].sun[j].posX_Z1, list_tiles[i].sun[j].posY_Z1)
        end
      end

     for i=1, #list_tiles do
       for j=1, #list_tiles do
         
        -- droite
        if list_tiles[j].idX == list_tiles[i].idX + 1 and list_tiles[j].idY == list_tiles[i].idY then
          list_tiles[j]:setCoordinate(list_tiles[i].x + list_tiles[i].w, list_tiles[i].y)
        end
        -- gauche
        if list_tiles[j].idX == list_tiles[i].idX - 1 and list_tiles[j].idY == list_tiles[i].idY then
          list_tiles[j]:setCoordinate(list_tiles[i].x - list_tiles[i].w, list_tiles[i].y)
        end
        -- haut
        if list_tiles[j].idX == list_tiles[i].idX  and list_tiles[j].idY == list_tiles[i].idY - 1 then
          list_tiles[j]:setCoordinate(list_tiles[i].x, list_tiles[i].y - list_tiles[i].h)
        end
        -- bas 
        if list_tiles[j].idX == list_tiles[i].idX  and list_tiles[j].idY == list_tiles[i].idY + 1 then
          list_tiles[j]:setCoordinate(list_tiles[i].x, list_tiles[i].y + list_tiles[i].h)
        end    
        
      end
     end
     
     map.location()
     map.location()
    end

end


function loadButton()
--[[ Fleches de direction
 local buttonUp = gui_galaxy.button(width/2,0,scale,"up_1")
  table.insert(list_button, buttonUp)
  buttonUp:setPositionX(width/2-list_button[1].w/2)
  
 local buttonBottom = gui_galaxy.button(width/2,height,scale,"bottom_1")
  table.insert(list_button, buttonBottom)
  buttonBottom:setPositionX(width/2-list_button[2].w/2)  
  buttonBottom:setPositionY(height-list_button[2].h)  
  
 local buttonLeft = gui_galaxy.button(0,height/2,scale,"left_1")
  table.insert(list_button, buttonLeft)  
  buttonLeft:setPositionY(height/2-list_button[3].h/2) 
  
 local buttonRight = gui_galaxy.button(width/2,height/2,scale,"right_1")
  table.insert(list_button, buttonRight)  
  buttonRight:setPositionX(width-list_button[4].w)
  buttonRight:setPositionY(height/2-list_button[4].h/2) 
  --]]
end
  
function SunDiscoverTable()
  for i=1, #list_tiles do
    for j=1, #list_tiles[i].sun do
      if list_tiles[i].sun[j].discover then
        table.insert(SUN_DISCOVER, {i,j})
      end      
    end
  end
end




function NewChunk() 

  for i=1, #list_tiles do
    if list_tiles[TILE_HERE].discover == true and list_tiles[i].isVisible then
      
      -- Vérification des tuiles a droite
      for j=1, #list_tiles do
        if list_tiles[j].idX == list_tiles[TILE_HERE].idX + 1 and list_tiles[j].idY == list_tiles[TILE_HERE].idY then
          break
        elseif j== #list_tiles then
          local tile = map.NewTile(list_tiles[TILE_HERE].x + list_tiles[TILE_HERE].w, list_tiles[TILE_HERE].y, list_tiles[TILE_HERE].idX + 1, list_tiles[TILE_HERE].idY, #list_tiles+1)
          tile.discover = true
          if ZOOM == 1 then
            tile:zoom(128)
            for j=1, #tile.sun do
            tile.sun[j]:setPos(tile.sun[j].posX,tile.sun[j].posY)
            end
          elseif ZOOM == 2 then
            tile:zoom(32)
            for j=1, #tile.sun do
            tile.sun[j]:setPos(tile.sun[j].posX,tile.sun[j].posY)
            end
          end
          table.insert(list_tiles, tile)
          data.SaveMap(tile.id)
        end
      end
      
      -- Vérification des tuiles a gauche
      for j=1, #list_tiles do
        if list_tiles[j].idX == list_tiles[TILE_HERE].idX - 1 and list_tiles[j].idY == list_tiles[TILE_HERE].idY then
          break
        elseif j== #list_tiles then
          local tile = map.NewTile(list_tiles[TILE_HERE].x - list_tiles[TILE_HERE].w, list_tiles[TILE_HERE].y, list_tiles[TILE_HERE].idX - 1, list_tiles[TILE_HERE].idY,#list_tiles+1)
          tile.discover = true
          if ZOOM == 1 then
            tile:zoom(128)
            for j=1, #tile.sun do
            tile.sun[j]:setPos(tile.sun[j].posX,tile.sun[j].posY)
            end
          elseif ZOOM == 2 then
            tile:zoom(32)
            for j=1, #tile.sun do
            tile.sun[j]:setPos(tile.sun[j].posX,tile.sun[j].posY)
            end
          end
          table.insert(list_tiles, tile)
          data.SaveMap(tile.id)
        end
      end
      
      -- Vérification des tuiles en haut
      for j=1, #list_tiles do
        if list_tiles[j].idX == list_tiles[TILE_HERE].idX and list_tiles[j].idY == list_tiles[TILE_HERE].idY - 1 then
          break
        elseif j== #list_tiles then
          local tile = map.NewTile(list_tiles[TILE_HERE].x, list_tiles[TILE_HERE].y - list_tiles[TILE_HERE].h, list_tiles[TILE_HERE].idX, list_tiles[TILE_HERE].idY - 1,#list_tiles+1)
          tile.discover = true
          if ZOOM == 1 then
            tile:zoom(128)
            for j=1, #tile.sun do
            tile.sun[j]:setPos(tile.sun[j].posX,tile.sun[j].posY)
            end
          elseif ZOOM == 2 then
            tile:zoom(32)
            for j=1, #tile.sun do
            tile.sun[j]:setPos(tile.sun[j].posX,tile.sun[j].posY)
            end
          end
          table.insert(list_tiles, tile)
          data.SaveMap(tile.id)
        end
      end      
 
 
      -- Vérification des tuiles en bas
      for j=1, #list_tiles do
        if list_tiles[j].idX == list_tiles[TILE_HERE].idX and list_tiles[j].idY == list_tiles[TILE_HERE].idY + 1 then
          break
        elseif j== #list_tiles then
          local tile = map.NewTile(list_tiles[TILE_HERE].x, list_tiles[TILE_HERE].y + list_tiles[TILE_HERE].h, list_tiles[TILE_HERE].idX, list_tiles[TILE_HERE].idY + 1,#list_tiles+1)
          tile.discover = true
          if ZOOM == 1 then
            tile:zoom(128)
            for j=1, #tile.sun do
            tile.sun[j]:setPos(tile.sun[j].posX,tile.sun[j].posY)
            end
          elseif ZOOM == 2 then
            tile:zoom(32)
            for j=1, #tile.sun do
            tile.sun[j]:setPos(tile.sun[j].posX,tile.sun[j].posY)
            end
          end
          table.insert(list_tiles, tile)
          data.SaveMap(tile.id)
        end
      end      
    end
  end

end


function game_galaxy.load()

   stickersHere = gui_galaxy.stickers(10, 10, "here")

  
  function InitMap()
    if SAVE == false then
      local tile = map.NewTile(0,0,0,0,#list_tiles+1)
      table.insert(list_tiles, tile)
      data.SaveMap(tile.id)
      list_tiles[1]:isDiscover(true)
      local begin = math.random(1,#list_tiles[1].sun)
        for i=1, #list_tiles[1].sun do
          if i == begin then
            list_tiles[1].sun[begin].here = true 
            list_tiles[1].sun[begin].discover = true
            list_tiles[1].sun[begin].id = 1  
            list_tiles[1].sun[begin]:StellarXY()
            TILE_HERE = 1
            SUN_HERE = begin
            table.insert(TILE_SAVE, {TILE_HERE,SUN_HERE}) 
          end
        end
        
          local system = system.new(width/2, height/2, 1, 0)
          system:generateSolarSystem(list_tiles[1].sun[begin],1)
          table.insert(list_tiles[1].sun[begin].system, system)   
          list_tiles[1].sun[begin].totalPlanets = list_tiles[1].sun[begin].system[1].totalPlanets

      --RegenGalaxy(ZOOM)
      map.location()
      NewChunk()
      --LoadZoom()
      --UpdateTile() 
      --ButtonZoom()
      SunDiscoverTable()  
          
    elseif SAVE == true then
    boxWindow.loading() data.LoadMap() 
    
     -- RegenGalaxy(ZOOM)
    --  map.location()
      LoadZoom()
      --UpdateTile() 
     -- NewChunk()
    SunDiscoverTable()




    end
  end
      InitMap()

      
end


function game_galaxy.update(dt)
 -- Position de la souris
  mX, mY = love.mouse.getPosition()
 
  -- update des boites
  boxWindow.updateBox()
  -- Update souris + update des tiles/sun
  MouseMapGalaxy()
   
  lock.r = lock.r + (0.3*dt)

  -- update tile visible
  TileIsVisible() 

 -- FPS OPTIMISATION A PREVOIR
-- Vérification hover des soleils
  for i=1, #list_tiles do
    if list_tiles[i].isVisible then
      for j=1, #list_tiles[i].sun do
       list_tiles[i].sun[j]:update(dt,mX,mY)
      end
    end
  end 
  

if player.galaxy.road == true then displacement.RoadGalaxy(dt) end

-- Actualise les icones (hover, pressed)
for i=1, 5 do
  icon[i]:update()
end
  

end


function game_galaxy.draw()

 -- Affichage titre
  Title(view_galaxy_text, font.titleView, width/2, 0, {65,160,250,180},true)
  SunTextDiscover()

-- Affichage des lignes
displacement.DrawLine()

  
  --Affiche les tiles
  for i=1, #list_tiles do list_tiles[i]:draw() end
  



  -- trajet en vue galaxy
  love.graphics.setColor(255,255,255,255)
  displacement.DrawRoadGalaxy()
  
for i=1, #list_tiles do
  for j=1, #list_tiles[i].sun do
      love.graphics.draw(lock.sprite, list_tiles[TILE_HERE].sun[SUN_HERE].x, list_tiles[TILE_HERE].sun[SUN_HERE].y, lock.r, 2, 2, lock.w/2, lock.h/2)
    if list_tiles[i].sun[j].hover then
      love.graphics.draw(lock.sprite_2, list_tiles[i].sun[j].x, list_tiles[i].sun[j].y, lock.r, 2, 2, lock.w/2, lock.h/2)
    end
  end
end  


-- DEBUG Affichage de la boite notification
boxWindow.drawBox()

  -- Affichage des Toolbars
  toolbar[1]:draw()
  toolbar[2]:draw()

end

function game_galaxy.keypressed(key)
  
  function DisplaceTiles(Pkey,Pview)
  -- paramètre Pkey (touche appuyer), et Pview pour l'orientation sur la map  
    if key == Pkey then
      
      for i=1, #list_tiles do
        -- vérification de Pkey
        if Pkey == "up" then
        list_tiles[i].y = list_tiles[i].y + Pview
      elseif Pkey == "down" then
        list_tiles[i].y = list_tiles[i].y - Pview    
      elseif Pkey == "left" then
        list_tiles[i].x = list_tiles[i].x + Pview 
      elseif Pkey == "right" then
        list_tiles[i].x = list_tiles[i].x - Pview 
        end
      end    
    end
  end
  
DisplaceTiles("up",VIEW_Y)
DisplaceTiles("down",VIEW_Y)
DisplaceTiles("left",VIEW_X)
DisplaceTiles("right",VIEW_X)

end



function game_galaxy.mousepressed(x,y,button)

end

return game_galaxy