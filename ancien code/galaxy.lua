game_galaxy = {}

local guiGalaxy = require ("guiGalaxy")
local system = require ("solar_system")

local map = require ("map")
--local list_tiles = {} print(list_tiles)
local list_button = {}

local list_pointA = {}
local list_pointB = {}
pointA = false
pointB = false


local view = {}
view.x = 40
view.y = 40
chunk = false


-- PARAMETRES GUI
local scale = 0.8
toolbar = {}
icon = {}

local function Location()
  
  local x,y = 0,0
  local dx,dy = 0,0
  for i=1, #list_tiles do
    for j=1, #list_tiles[i].sun do
      if list_tiles[i].sun[j].here then
         x = math.dist(list_tiles[i].sun[j].x, 0, width/2, 0)
         y = math.dist(0, list_tiles[i].sun[j].y, 0, height/2)
        local tile = i
        local sun = j
        
        if list_tiles[i].sun[j].x <= width/2 then
           dx = "negatif"
        elseif list_tiles[i].sun[j].x > width/2 then
           dx = "positif"
        end
        
         if list_tiles[i].sun[j].y <= height/2 then
           dy = "negatif"
        elseif list_tiles[i].sun[j].y > height/2 then
           dy = "positif"
        end

      end
    end
    
    break
  end
  
  for k=1, #list_tiles do
    if dx == "negatif" then
    list_tiles[k].x = list_tiles[k].x + x
    elseif dx == "positif" then
    list_tiles[k].x = list_tiles[k].x - x
    end
  
    if dy == "negatif" then
    list_tiles[k].y = list_tiles[k].y + y
    elseif dy == "positif" then
    list_tiles[k].y = list_tiles[k].y - y
    end
  end

      for i=1, #list_tiles do
        -- parcours de tiles
        for j=1, #list_tiles[i].sun do
          -- parcours de soleil dans chaque tuiles pour actualiser sa position par rapport a celle de sa tuile
          list_tiles[i].sun[j]:setCoordinate(list_tiles[i].x + (list_tiles[i].sun[j].c-1)*(list_tiles[i].cellSize) + list_tiles[i].sun[j].posX, list_tiles[i].y + (list_tiles[i].sun[j].l-1)*(list_tiles[i].cellSize)+ list_tiles[i].sun[j].posY)
        end
      end
  
  -- Vérification de la visibilité des grilles
    for i=1, #list_tiles do
      list_tiles[i]:IsVisible()
    end
end

function On()
 on = true
end


function loadButton()
 local buttonUp = guiGalaxy.button(width/2,0,scale,"up_1")
  table.insert(list_button, buttonUp)
  buttonUp:setPositionX(width/2-list_button[1].w/2)
  
 local buttonBottom = guiGalaxy.button(width/2,height,scale,"bottom_1")
  table.insert(list_button, buttonBottom)
  buttonBottom:setPositionX(width/2-list_button[2].w/2)  
  buttonBottom:setPositionY(height-list_button[2].h)  
  
 local buttonLeft = guiGalaxy.button(0,height/2,scale,"left_1")
  table.insert(list_button, buttonLeft)  
  buttonLeft:setPositionY(height/2-list_button[3].h/2) 
  
 local buttonRight = guiGalaxy.button(width/2,height/2,scale,"right_1")
  table.insert(list_button, buttonRight)  
  buttonRight:setPositionX(width-list_button[4].w)
  buttonRight:setPositionY(height/2-list_button[4].h/2) 
end  
  
  local function newLine()

  if pointA == false and pointB == false then
    
    for i=1, #list_tiles do
      if list_tiles[i].isVisible then
        for j=1, #list_tiles[i].sun do  
          if list_tiles[i].sun[j].here and love.mouse.isDown(1) and list_tiles[i].sun[j].hover then
              pointA = true
               local pointA = {}
               local pointB = {}
               pointA.x = list_tiles[i].sun[j].x
               pointA.y = list_tiles[i].sun[j].y
               pointB.x = love.mouse.getX()
               pointB.y = love.mouse.getY()
              table.insert(list_pointA, pointA)
              table.insert(list_pointB, pointB)
               tiles = i
               here = j            
          end
        end
      end
    end
   
  elseif pointA and pointB == false then 
    for i=1, #list_tiles do
      if list_tiles[i].isVisible then
        for j=1, #list_tiles[i].sun do  
          if list_tiles[i].sun[j].here == false then
            if list_tiles[i].sun[j].hover and love.mouse.isDown(1) then
                list_pointB[#list_pointB].x = list_tiles[i].sun[j].x
                list_pointB[#list_pointB].y = list_tiles[i].sun[j].y
                pointB = true
                pointA = false
                pointB = false
                list_tiles[tiles].sun[here].here = false
                list_tiles[i].sun[j].here = true
                
                local discover = 0
                for m=1, #list_tiles do
                  for n=1, #list_tiles[m].sun do
                    if list_tiles[m].sun[n].discover then
                      discover = discover + 1 
                    end
                  end
                end
                list_tiles[i].sun[j].discover = true
                list_tiles[i].sun[j].id = discover + 1
                system.new(width/2, height/2, discover, 0)
                
                local on = false
            end
          end
        end
      end
    end    
  end  
    
    
    
  
  end


function NewChunk() 
  
  -- Vérification de la visibilité des grilles
    for i=1, #list_tiles do
      list_tiles[i]:IsVisible()
    end

  for i=1, #list_tiles do
    if list_tiles[i].isVisible == true then
  
      -- Vérification des tuiles a droite
      for j=1, #list_tiles do
        if list_tiles[j].idX == list_tiles[i].idX + 1 and list_tiles[j].idY == list_tiles[i].idY then
          break
        elseif j== #list_tiles then
          local tile = map.NewTile(list_tiles[i].x + list_tiles[i].w, list_tiles[i].y, list_tiles[i].idX + 1, list_tiles[i].idY)
          table.insert(list_tiles, tile)
        end
      end
      
      -- Vérification des tuiles a gauche
      for j=1, #list_tiles do
        if list_tiles[j].idX == list_tiles[i].idX - 1 and list_tiles[j].idY == list_tiles[i].idY then
          break
        elseif j== #list_tiles then
          local tile = map.NewTile(list_tiles[i].x - list_tiles[i].w, list_tiles[i].y, list_tiles[i].idX - 1, list_tiles[i].idY)
          table.insert(list_tiles, tile)
        end
      end
      
      -- Vérification des tuiles en haut
      for j=1, #list_tiles do
        if list_tiles[j].idX == list_tiles[i].idX and list_tiles[j].idY == list_tiles[i].idY - 1 then
          break
        elseif j== #list_tiles then
          local tile = map.NewTile(list_tiles[i].x, list_tiles[i].y - list_tiles[i].h, list_tiles[i].idX, list_tiles[i].idY - 1)
          table.insert(list_tiles, tile)
        end
      end      
 
 
      -- Vérification des tuiles en bas
      for j=1, #list_tiles do
        if list_tiles[j].idX == list_tiles[i].idX and list_tiles[j].idY == list_tiles[i].idY + 1 then
          break
        elseif j== #list_tiles then
          local tile = map.NewTile(list_tiles[i].x, list_tiles[i].y + list_tiles[i].h, list_tiles[i].idX, list_tiles[i].idY + 1)
          table.insert(list_tiles, tile)
        end
      end      

 
    end
  end
end


function galaxy.load()

  
end


function game_galaxy.update(dt)
  

end

function game_galaxy.draw()




end

function game_galaxy.keypressed(key)
  
  function UpdateLine(Px, Py)
    for i=1, #list_pointB do
      list_pointA[i].x = list_pointA[i].x + Px
      list_pointA[i].y = list_pointA[i].y + Py
      list_pointB[i].x = list_pointB[i].x + Px
      list_pointB[i].y = list_pointB[i].y + Py
    end
  end
  
  
  
  function DisplaceTiles(Pkey,Pview)
  -- paramètre Pkey (touche appuyer), et Pview pour l'orientation sur la map  
    if key == Pkey then
      
      for i=1, #list_pointB do
        -- vérification de Pkey
        if Pkey == "up" then
        list_pointA[i].y = list_pointA[i].y + Pview
        list_pointB[i].y = list_pointB[i].y + Pview
      elseif Pkey == "down" then
        list_pointA[i].y = list_pointA[i].y - Pview
        list_pointB[i].y = list_pointB[i].y - Pview   
      elseif Pkey == "left" then
        list_pointA[i].x = list_pointA[i].x + Pview
        list_pointB[i].x = list_pointB[i].x + Pview 
      elseif Pkey == "right" then
        list_pointA[i].x = list_pointA[i].x - Pview
        list_pointB[i].x = list_pointB[i].x - Pview 
        end
      end
      
      
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
      for i=1, #list_tiles do
        -- parcours de tiles
        for j=1, #list_tiles[i].sun do
          -- parcours de soleil dans chaque tuiles pour actualiser sa position par rapport a celle de sa tuile
          list_tiles[i].sun[j]:setCoordinate(list_tiles[i].x + (list_tiles[i].sun[j].c-1)*(list_tiles[i].cellSize) + list_tiles[i].sun[j].posX, list_tiles[i].y + (list_tiles[i].sun[j].l-1)*(list_tiles[i].cellSize)+ list_tiles[i].sun[j].posY)
        end
      end    
    end
  end
  
DisplaceTiles("up",view.y)
    NewChunk()
DisplaceTiles("down",view.y)
    NewChunk()
DisplaceTiles("left",view.x)
    NewChunk()
DisplaceTiles("right",view.x)
    NewChunk()

end



function game_galaxy.mousepressed(x,y,button)

end

return game_galaxy