local sun = require "sun"

map = {}
list_sun = {}



  function map.locationBox()
  local tile = 0
  local sun = 0
  
  for i=1, #list_tiles do 
      for j=1,#list_tiles[i].sun do
        if list_tiles[i].sun[j].isSelected then
        tile = i
        sun = j
        end
      end
  end
  
  local x,y = 0,0
  local dx,dy = 0,0

        
         x = math.dist(list_tiles[tile].sun[sun].x, 0, width/2, 0)
         y = math.dist(0, list_tiles[tile].sun[sun].y, 0, height/2)
        
        if list_tiles[tile].sun[sun].x <= width/2 then
           dx = "negatif"
        elseif list_tiles[tile].sun[sun].x > width/2 then
           dx = "positif"
        end
        
         if list_tiles[tile].sun[sun].y <= height/2 then
           dy = "negatif"
        elseif list_tiles[tile].sun[sun].y > height/2 then
           dy = "positif"
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
          list_tiles[i].sun[j]:setCoordinates(list_tiles[i].x + (list_tiles[i].sun[j].c-1)*(list_tiles[i].cellSize) + list_tiles[i].sun[j].posX, list_tiles[i].y + (list_tiles[i].sun[j].l-1)*(list_tiles[i].cellSize)+ list_tiles[i].sun[j].posY)
        end
      end
  
  -- Vérification de la visibilité des grilles
    for i=1, #list_tiles do
      list_tiles[i]:IsVisible()
    end
    
    list_tiles[tile].sun[sun].isSelected = false
end

  function map.location()
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

          if ZOOM == 1 then
          list_tiles[i].sun[j]:setCoordinates(list_tiles[i].x + (list_tiles[i].sun[j].c-1)*(list_tiles[i].cellSize) + list_tiles[i].sun[j].posX, list_tiles[i].y + (list_tiles[i].sun[j].l-1)*(list_tiles[i].cellSize)+ list_tiles[i].sun[j].posY)
        elseif ZOOM == 2 then
          list_tiles[i].sun[j]:setCoordinates(list_tiles[i].x + (list_tiles[i].sun[j].c-1)*(list_tiles[i].cellSize) + list_tiles[i].sun[j].posX, list_tiles[i].y + (list_tiles[i].sun[j].l-1)*(list_tiles[i].cellSize)+ list_tiles[i].sun[j].posY)          
          end
        end
      end

  -- Vérification de la visibilité des grilles
    for i=1, #list_tiles do
      list_tiles[i]:IsVisible()
    end
end

function map.NewTile(Px, Py, PidX, PidY, Pid, Psun)
  
  local tile = {}
  tile.id = Pid 
  tile.x = Px
  tile.y = Py
  tile.idX = PidX
  tile.idY = PidY
  tile.color = {math.random(0,255),math.random(0,255),math.random(0,255),50}
  tile.isVisible = false
  tile.discover =  false
  if ZOOM == 1 then tile.cellSize = 128 elseif ZOOM == 2 then tile.cellSize = 32 end
  tile.c = 3
  tile.l = 3
  tile.w = tile.cellSize*tile.c
  tile.h = tile.cellSize*tile.l
  tile.dx = 0
  tile.dy = 0
  
  tile.name = {}
  tile.name.new = math.random(0,0)


  tile.grid = {}
  tile.sun = {}
    if Psun == nil then  
      if #list_tiles == 0 then
        for l=1, tile.l do
          tile.grid[l] = {}
          for c=1, tile.c do
            tile.grid[l][c] = 0
          end
        end
        local l = math.random(1,tile.l) 
        local c = math.random(1,tile.c) 
        local sunRadius = 12
        local posX = math.random(sunRadius,tile.cellSize - sunRadius)
        local posY = math.random(sunRadius,tile.cellSize - sunRadius) 
        local sunX = tile.x + (c-1)*(tile.cellSize) + posX 
        local sunY = tile.y + (l-1)*(tile.cellSize) + posY 
        local newSun = sun.new(c, l, posX, posY, sunX, sunY, sunRadius, tile.id, #tile.sun+1)
        newSun:celsus(1)
        newSun:generate()
        table.insert(tile.sun, newSun)    

      else
        for l=1, tile.l do
          tile.grid[l] = {}
          for c=1, tile.c do
            tile.grid[l][c] = math.random(0,100)
            if tile.grid[l][c] >= 80 then
                local listRadius = {8,10,12,14,16,18,20,22}
                local sunRadius = listRadius[math.random(1,#listRadius)] 
                local posX = math.random(sunRadius,tile.cellSize - sunRadius)
                local posY = math.random(sunRadius,tile.cellSize - sunRadius)
                local sunX = tile.x + (c-1)*(tile.cellSize) + posX 
                local sunY = tile.y + (l-1)*(tile.cellSize) + posY
                local newSun = sun.new(c, l, posX, posY, sunX, sunY, sunRadius, tile.id, #tile.sun+1)
                newSun:celsus(math.random(1,4))
                newSun:generate()
                table.insert(tile.sun, newSun)
            end
            
          end
        end
      end
    end
function tile:isDiscover(Pdiscover)
tile.discover = Pdiscover  
end

function tile:setCoordinate(Px, Py)
  self.x = Px
  self.y = Py
  end

function tile:zoom(Pzoom)
  self.cellSize = Pzoom
  self.w = self.cellSize*self.c
  self.h = self.cellSize*self.l
end

function tile:update()

end


function tile:draw() 
  if self.isVisible then  
      local x, y = 0, 0
      
      for l=1, tile.l do
        for c=1, tile.c do
          x = self.x + (c-1) * self.cellSize
          y = self.y + (l-1) * self.cellSize
          
          if tile.grid[l][c] >= 0 then
            --love.graphics.setColor(self.color)
            love.graphics.setColor(255,255,255,10)
            love.graphics.rectangle("line", x, y, self.cellSize, self.cellSize)
            love.graphics.print(self.id, x,y)
          end
        end
      end
      
      for i=1, #self.sun do
          self.sun[i]:draw()
      end
      
      if self.name.new == 1 then
      local font = love.graphics.newFont("fonts/Pixellari.ttf",20)
      love.graphics.setFont(font)
      love.graphics.setColor(255,255,255,40)
      love.graphics.print(self.name.id, self.x + self.name.x, self.y +  self.name.y)
      end
    
  end 
end
 
function tile:IsVisible()
  
  if self.x + self.w > 0 and self.x < width and self.y + self.h > 0 and self.y < height then
      self.isVisible = true
  else 
      self.isVisible = false
  end

end
 
  return tile
end





return map