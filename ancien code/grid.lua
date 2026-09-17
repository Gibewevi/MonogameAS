--
-- Intègre toutes les fonctions travaillant sur les grilles
--
local grid = {}

function math.dist(x1,y1, x2,y2) return ((x2-x1)^2+(y2-y1)^2)^0.5 end
function math.angle(x1,y1, x2,y2) return math.atan2(y2-y1, x2-x1) end

-- Grille de base pour le sol des planètes et du soleil
function grid.init(pType, pLine, pColumn, pLuck, pBirth, pDeath)
  local grid = {}
  local transferGrid = {} -- Grille de transfert, pour ne pas erroner la génération des cellules
  local count = 0 -- Nombre de cellules vivantes autour de la cellule analysée
  
  -- Calcul de la proportion des 2 zones de bases**
  if pType == "telluric" then
    for l=1, pLine do
      grid[l] = {}
      transferGrid[l] = {}
      for c=1, pColumn do
        local random = math.random(1, 100)
        transferGrid[l][c] = false
        if random < pLuck then
          grid[l][c] = 10
        else
          grid[l][c] = 20
        end
      end
    end
  
  elseif pType == "gas" then
    for l=1, pLine do
      grid[l] = {}
      transferGrid[l] = {}
      local random = math.random(1, 100)
      for c=1, pColumn do
        transferGrid[l][c] = false
        if random < pLuck then
          if l%2 == 0 then
            grid[l][c] = 10
            local r = math.random(0, 5)
            if l > 2 and r > 2 then
              grid[l-1][c] = 10
            end
          else
            grid[l][c] = 20
          end
        else
          grid[l][c] = 20
        end
      end
    end
  end
  
  for l=2, pLine-1 do
    for c=2, pColumn-1 do
      if l > 1 and c > 1 and l < pLine and c < pColumn then
        if grid[l-1][c-1] == 10 then
          count = count + 1
        end
        if grid[l-1][c] == 10 then
          count = count + 1
        end 
        if grid[l-1][c+1] == 10 then
          count = count + 1
        end          
        if grid[l][c-1] == 10 then
          count = count + 1
        end           
        if grid[l][c+1] == 10 then
          count = count + 1
        end          
        if grid[l+1][c-1] == 10 then
          count = count + 1
        end           
        if grid[l+1][c] == 10 then
          count = count + 1
        end  
        if grid[l+1][c+1] == 10 then
          count = count + 1
        end
        
        -- Si la cellule est de biome 10 et ... alors ... "sol"
        if grid[l][c] == 10 then
          if count < pDeath then
            transferGrid[l][c] = 20
          else
            transferGrid[l][c] = 10
          end
        elseif grid[l][c] == 20 then
          -- Si la cellule est de biome 20 et ... alors ... "ocean"
          if count > pBirth then
            transferGrid[l][c] = 10
          else
            transferGrid[l][c] = 20
          end
        end
        count = 0
      end
      grid[l][c] = transferGrid[l][c]
    end
  end
  

  if pType == "gas" then 
      for l=1, pLine do
        local random = math.random(1, 100)
        for c=1, pColumn do
          if random < pLuck then
            if l%2 == 0 then
              grid[l][c] = 10
              local r = math.random(0, 5)
              if l > 2 and r > 2 then
                grid[l-1][c] = 10
              end
            else
              grid[l][c] = 11
            end
          else
            grid[l][c] = 11
          end
        end
      end
    
   
  for l=2, pLine - 1 do
    for c=2, pColumn - 1 do
      if l > 1 and c > 1 and l < pLine and c < pColumn and grid[l][c] == 11 then
        if grid[l-1][c-1] == 11 then
          local random = math.random(2,3)
          if random == 3 then
            transferGrid[l-1][c-1] = 11
          end
        end
        if grid[l-1][c] == 11 then
          local random = math.random(2,3)
          if random == 3 then
            transferGrid[l-1][c] = 11
          end
        end 
        if grid[l-1][c+1] == 11 then
          local random = math.random(2,3)
          if random == 3 then
            transferGrid[l-1][c+1] = 11
          end
        end 
        if grid[l][c-1] == 11 then
          local random = math.random(2,3)
          if random == 3 then
            transferGrid[l][c-1] = 11
          end
        end 
        if grid[l][c+1] == 11 then
          local random = math.random(2,3)
          if random == 3 then
            transferGrid[l][c+1] = 11
          end
        end
        if grid[l+1][c-1] == 11 then
          local random = math.random(2,3)
          if random == 3 then
            transferGrid[l+1][c-1] = 11
          end
        end
        if grid[l+1][c] == 11 then
          local random = math.random(2,3)
          if random == 3 then
            transferGrid[l+1][c-1] = 11
          end
        end
        if grid[l+1][c+1] == 11 then
          local random = math.random(2,3)
          if random == 3 then
            transferGrid[l+1][c+1] = 11 
          end
        end
        count = 0
      end
      grid[l][c] = transferGrid[l][c]
    end
  end 
 end 
  
  return grid
end

------------------------------------------------------------------
-- Définition des contours de la première zone id:10, rajout d'une
-- nouvelle couleur plus claire
-- Retourne la grille passée en paramêtre après avoir été modifiée
function grid.initContinent(pGrid, pType, pLine, pColumn, pLuck, pBirth, pDeath)
  local count = 0 -- Nombre de cellules vivantes autour de la cellule analysée
  local grid = pGrid
  local transferGrid = pGrid

  if pType == "telluric" then
    for l=1, pLine do
      for c=1, pColumn do
        local random = math.random(0, 100)
        if grid[l][c] == 10 and random < pLuck then
          grid[l][c] = 11
        end
      end
    end
  
   
  for l=2, pLine - 1 do
    for c=2, pColumn - 1 do
      if l > 1 and c > 1 and l < pLine and c < pColumn and grid[l][c] == 11 then
        if grid[l-1][c-1] == 11 then
          local random = math.random(2,3)
          if random == 3 then
            transferGrid[l-1][c-1] = 11
          end
        end
        if grid[l-1][c] == 11 then
          local random = math.random(2,3)
          if random == 3 then
            transferGrid[l-1][c] = 11
          end
        end 
        if grid[l-1][c+1] == 11 then
          local random = math.random(2,3)
          if random == 3 then
            transferGrid[l-1][c+1] = 11
          end
        end 
        if grid[l][c-1] == 11 then
          local random = math.random(2,3)
          if random == 3 then
            transferGrid[l][c-1] = 11
          end
        end 
        if grid[l][c+1] == 11 then
          local random = math.random(2,3)
          if random == 3 then
            transferGrid[l][c+1] = 11
          end
        end
        if grid[l+1][c-1] == 11 then
          local random = math.random(2,3)
          if random == 3 then
            transferGrid[l+1][c-1] = 11
          end
        end
        if grid[l+1][c] == 11 then
          local random = math.random(2,3)
          if random == 3 then
            transferGrid[l+1][c-1] = 11
          end
        end
        if grid[l+1][c+1] == 11 then
          local random = math.random(2,3)
          if random == 3 then
            transferGrid[l+1][c+1] = 11 
          end
        end
        count = 0
      end
      grid[l][c] = transferGrid[l][c]
    end
   end
  end 
  return grid
end

------------------------------------------------------------------
-- Définition des contours de la deuxième zone id:20, rajout d'une
-- nouvelle couleur plus fonçée
-- Retourne la grille passée en paramêtre après avoir été modifiée
------------------------------------------------------------------
function grid.initOcean(pGrid, pLine, pColumn) 
  local count = 0 -- Nombre de cellules vivantes autour de la cellule analysée
  local grid = pGrid
  
  for l=2, pLine - 1 do
  -- nombres de cellules autour de grid[l][c] 
    local count = 0     
    for c=2, pColumn do
      if l > 1 and c > 1 and l < pLine and c < pColumn then
        if grid[l-1][c-1] == 10 then
          count = count + 1
        end
        if grid[l-1][c] == 10 then
          count = count + 1
        end 
        if grid[l-1][c+1] == 10 then
          count = count + 1
        end          
        if grid[l][c-1] == 10 then
          count = count + 1
        end           
        if grid[l][c+1] == 10 then
          count = count + 1
        end          
        if grid[l+1][c-1] == 10 then
          count = count + 1
        end           
        if grid[l+1][c] == 10 then
          count = count + 1
        end  
        if grid[l+1][c+1] == 10 then
          count = count + 1
        end
        if grid[l][c] == 20 and count == 0 then
          grid[l][c] = 21    
        end
        count = 0
      end
    end
  end
  
  return grid
end


function grid.initPole(Pgrid, PcenterX, PcenterY, Pradius, Pline, Pcolumn, PcellSize,PradiusIce)
  function math.dist(x1,y1, x2,y2) return ((x2-x1)^2+(y2-y1)^2)^0.5 end
  function math.delta(y1,y2) return math.abs(y2-y1) end
  
  local grid = Pgrid
  
  local x_north, y_north = PcenterX, PcenterY - Pradius
  local x_south, y_south = Pcenter_X, PcenterY + Pradius
  local radius_ice = PradiusIce
  local x = PcenterX - Pradius
  local y = PcenterY - Pradius
  local dh = 0
  
  for l=1, Pline do
    for c=1, Pcolumn do
      x = x + PcellSize 
      local dy_north = math.delta(y,y_north)
      local random_bloc = math.random(1,2)
      
      --------- Calcul North
      if dy_north < radius_ice then
        if random_bloc == 1 then
        grid[l][c] = 12
        elseif random_bloc == 2 then
        grid[l][c] = 13        
        end
      end
       --------- Calcul North
      local dy_south = math.delta(y,y_south)
      if dy_south < radius_ice then
        if random_bloc == 1 then
        grid[l][c] = 12
        elseif random_bloc == 2 then
        grid[l][c] = 13        
        end
      end
      
      
      local random_luck = math.random(1,3)
       --------- Extension North
      if dy_north >= radius_ice and dy_north < radius_ice + 15 then
        if random_luck == 1 then
          grid[l][c] = 13
        end
      end
       --------- Extension South
      if dy_south >= radius_ice and dy_south < radius_ice + 15 then
        if random_luck == 1 then
          grid[l][c] = 13
        end
      end      
      
    end
      y = y + PcellSize
      x = PcenterX - Pradius
  end
  
  return grid
end

function grid.ellipse(PxPlanet, PyPlanet, pX, pY, pRx, pRy, pCellSize, pLine, pColumn)
  local grid = {}
  grid.c = pColumn
  grid.l = pLine
  grid.x = pX
  grid.y = pY
  grid.ex = PxPlanet
  grid.ey = PyPlanet
  grid.rx = pRx
  grid.ry = pRy
  grid.cell = pCellSize
  
  local line = pLine
  local column = pColumn
  
  for l=1,grid.l do
    grid[l] = {}
    for c=1,grid.c do
      grid[l][c] = false
    end
  end

  


      local cell_x, cell_y = grid.x, grid.y
        for l=1, grid.l do
          for c=1, grid.c do
            local c1 = math.pow(((((c-1)*grid.cell+grid.x) -grid.ex) / grid.rx),2) + math.pow(((((l-1)*grid.cell+grid.y) - grid.ey) / grid.ry),2)
            local c2 = math.pow((((c*grid.cell+grid.x) - grid.ex) / grid.rx),2) + math.pow(((((l-1)*grid.cell+grid.y) -grid.ey) / grid.ry),2)
            local c3 = math.pow((((c*grid.cell+grid.x) - grid.ex) / grid.rx),2) + math.pow((((l*grid.cell+grid.y)-grid.ey) / grid.ry),2)
            local c4 = math.pow(((((c-1)*grid.cell+grid.x) - grid.ex) / grid.rx),2) + math.pow((((l*grid.cell+grid.y)-grid.ey) / grid.ry),2)     

            if c1 > 1 and c2 < 1 or c1 < 1 and c2 > 1 then
              grid[l][c] = 1
            elseif c1 < 1 and c3 > 1 or c1 > 1 and c3 < 1 then
              grid[l][c] = 1
            elseif c4 > 1 and c3 < 1 or c4 < 1 and c3 > 1 then
              grid[l][c] = 1
            elseif c4 > 1 and c2 < 1 or c4 < 1 and c2 > 1 then
              grid[l][c] = 1
            end      
          end
        end


  return grid  
  
end

function grid.initRings(Px, Py, Pline, Pcolumn, Pcellsize)
  local grid = {}
  grid.c = Pcolumn*2
  grid.l = Pline*2
  grid.x = Px
  grid.y = Py
  grid.cellsize = Pcellsize
  grid.rings = Prings
  grid.rx = (grid.c/2)*grid.cellsize
  grid.ry =  grid.rx/2

  
  local l,c
  for l=1,grid.c do
    grid[l] = {}
    for c=1,grid.l do
      grid[l][c] = 0
    end
  end
  
  return grid
end

function grid.updateRings(Pgrid, Px, Py, Pradius, Pline, Pcolumn, Pcellsize, Prings)
   
  local grid = Pgrid
  grid.c = Pcolumn*2
  grid.l = Pline*2
  grid.x = Px - (2*Pradius)
  grid.y = Py - (2*Pradius)
  grid.ex = Px
  grid.ey = Py
  grid.radius = Pradius
  grid.cell = Pcellsize
  grid.rings = 1
  grid.rx = (grid.c/2)*grid.cellsize
  grid.ry =  grid.rx/6 + grid.cellsize
  

    
    for i=1,5 do 
      local cell_x, cell_y = grid.x, grid.y
        for l=1, grid.l do
          for c=1, grid.c do
            local c1 = math.pow(((((c-1)*grid.cell+grid.x) -grid.ex) / grid.rx),2) + math.pow(((((l-1)*grid.cell+grid.y) - grid.ey) / grid.ry),2)
            local c2 = math.pow((((c*grid.cell+grid.x) - grid.ex) / grid.rx),2) + math.pow(((((l-1)*grid.cell+grid.y) -grid.ey) / grid.ry),2)
            local c3 = math.pow((((c*grid.cell+grid.x) - grid.ex) / grid.rx),2) + math.pow((((l*grid.cell+grid.y)-grid.ey) / grid.ry),2)
            local c4 = math.pow(((((c-1)*grid.cell+grid.x) - grid.ex) / grid.rx),2) + math.pow((((l*grid.cell+grid.y)-grid.ey) / grid.ry),2)     

            if c1 > 1 and c2 < 1 or c1 < 1 and c2 > 1 then
              grid[l][c] = i
            elseif c1 < 1 and c3 > 1 or c1 > 1 and c3 < 1 then
              grid[l][c] = i
            elseif c4 > 1 and c3 < 1 or c4 < 1 and c3 > 1 then
              grid[l][c] = i
            elseif c4 > 1 and c2 < 1 or c4 < 1 and c2 > 1 then
              grid[l][c] = i
            end      
          end
        end


          if i==1 then -- 2ème ellipse
            grid.rx = grid.rx - (2*grid.cell)
            grid.ry = grid.ry 
          elseif i==2 then -- 3ème ellipse
            grid.rx = grid.rx - (2*grid.cell)
            grid.ry = grid.ry - grid.cell
          elseif i==3  then -- 4 ème ellipse
            grid.rx = grid.rx - (7*grid.cell)   
            grid.ry = grid.ry - (2*grid.cell)
          elseif i==4 then -- dernière ellipse ombre projeté
            grid.rx = grid.radius   
            grid.ry = 4*grid.cell
          end
        end


  return grid
end



function grid.initCivilisation(pGrid, pLine, pColumn, pX, pY, pRadius, pCellSize,pExpansion)
   local grid = pGrid
   local count_empty = 0
  ------------------  Calcul du nombre de celulle à civiliser %  --------------------- 
   for l=1,pLine do
    for c=1, pColumn do
        if grid[l][c] == 10 or grid[l][c] == 11 then
          count_empty = count_empty + 1 
        end
    end 
  end
  
  local expansion_cellCalcul = (count_empty*pExpansion)/100
  if pExpansion == 0 then expansion_cellCalcul = 1 end
  ------------------------------------------------------------------------------------- 
for i=1,expansion_cellCalcul do


  local cellX = ((pX - pRadius) + (pCellSize / 2))
  local cellY = ((pY - pRadius) + (pCellSize / 2))
  local distance = 0
  local count_urbain = 0

  -- new biome civilisation = 30,31
  for l=1,pLine do
    for c=1, pColumn do
        if grid[l][c] == 30 then
          count_urbain = count_urbain + 1 
        end
    end 
  end



  
  local count_result = count_urbain 

    -- creation de la civilisation
    if count_urbain == 0 then
      while count_urbain == 0 do
        -- Variable random 
        local spawnCivilisation = math.random(1,pColumn)
        for l=spawnCivilisation, pLine do
          for c=spawnCivilisation, pColumn do
              distance = math.dist(pX, pY, cellX, cellY)
              -- Si le terrain est constructible 
              if distance < pRadius and grid[l][c] == 10 and count_urbain == 0 then 
                -- Creation de cellule de civilisation
                grid[l][c] = 30
                count_urbain = count_urbain + 1 
              end
            cellX = cellX + pCellSize
          end
        cellX = ((pX - pRadius) + (pCellSize / 2))
        cellY = cellY + pCellSize
       end
      end
    end
    
    -- expension de la civilisation
    local stock_cell = {}
    if count_result >= 1 then
      -- variable du nombre de cellule civilisation
      local count_finish = count_result
      -- Vérification de creation d'une cellule civilisée
      while count_finish == count_result do

        for l=2, pLine-1 do
          for c=2, pColumn-1 do
            if grid[l][c] == 30 or grid[l][c] == 40 or grid[l][c] == 41 or grid[l][c] == 42 then
              -- Vérification cellule voisine pour zone à urbaniser
                if grid[l-1][c-1] == 10 or grid[l-1][c-1] == 11 then
                  local cell = {}
                  cell.l = l-1
                  cell.c = c-1
                  table.insert(stock_cell, cell)
                  count_result = count_result + 1
              elseif grid[l-1][c] == 10 or grid[l-1][c] == 11 then
                  local cell = {}
                  cell.l = l-1
                  cell.c = c
                  table.insert(stock_cell, cell)
                  count_result = count_result + 1              
              elseif grid[l-1][c+1] == 10 or grid[l-1][c+1] == 11 then
                  local cell = {}
                  cell.l = l-1
                  cell.c = c+1
                  table.insert(stock_cell, cell)
                  count_result = count_result + 1              
              elseif grid[l][c-1] == 10 or grid[l][c-1] == 11 then
                  local cell = {}
                  cell.l = l
                  cell.c = c-1
                  table.insert(stock_cell, cell)
                  count_result = count_result + 1              
              elseif grid[l][c+1] == 10 or grid[l][c+1] == 11 then  
                  local cell = {}
                  cell.l = l
                  cell.c = c+1
                  table.insert(stock_cell, cell)
                  count_result = count_result + 1              
              elseif grid[l+1][c-1] == 10 or grid[l+1][c-1] == 11 then
                  local cell = {}
                  cell.l = l+1
                  cell.c = c-1
                  table.insert(stock_cell, cell)
                  count_result = count_result + 1              
              elseif grid[l+1][c] == 10 or grid[l+1][c] == 11 then
                  local cell = {}
                  cell.l = l+1
                  cell.c = c
                  table.insert(stock_cell, cell)
                  count_result = count_result + 1              
              elseif grid[l+1][c+1] == 10 or grid[l+1][c+1] == 11 then
                  local cell = {}
                  cell.l = l+1
                  cell.c = c+1
                  table.insert(stock_cell, cell)
                  count_result = count_result + 1              
                end
            end
          end
        end

          -- Si une nouvelle cellule est trouvé
          if count_result ~= count_finish then
          -- Variable random pour choisir la cellule civilisé parmis les prétendantes
          local new_cellCivilisation =  math.random(1,#stock_cell)
              -- Création de la nouvelle cellule civilisée
              grid[stock_cell[new_cellCivilisation].l][stock_cell[new_cellCivilisation].c] = math.random(30,31)
          expansion_cellCalcul = expansion_cellCalcul -1
          elseif count_result == count_finish then
          -- Si aucune nouvelle cellule trouvé
          local last_cell = 0
                for l=1,pLine do
                  for c=1, pColumn do
                    if last_cell == 0 then
                      if grid[l][c] == 10 or grid[l][c] == 11  then
                        grid[l][c] = math.random(30,31) 
                        last_cell = last_cell + 1
                        expansion_cellCalcul = expansion_cellCalcul -1
                      end 
                    end
                  end
                end 
            break
          end
      end
    end     
  end
return grid
end

--------------------------------------------------------------
-- Création de la grille de nuages
--------------------------------------------------------------
function grid.initCloud(pLine, pColumn, pLuck)
local cloud = {}
local count = 0 -- Nombre de cellules vivantes autour de la cellule analysée

  for l=1, pLine do
    cloud[l] = {}
    for c=1, pColumn do
      local random = math.random(0,100)
      -- Si random>grid.chance, alors génére une cellule sinon désactive la cellule
      if random > pLuck then
        -- génére un biome cloud [50]
        cloud[l][c] = 50 
      else
        -- génére un biome
        cloud[l][c] = false
      end
    end
  end
  
  for l=2, pLine-1 do
    local count = 0
      for c=2, pColumn-1 do
        if l > 1 and c > 1 and l < pLine and c < pColumn then
          if cloud[l-1][c-1] == 50 then
            count = count +1
          end
          if cloud[l-1][c] == 50 then
            count = count +1
          end 
          if cloud[l-1][c+1] == 50 then
            count = count +1
          end 
          if cloud[l][c-1] == 50 then
            count = count +1
          end 
          if cloud[l][c+1] == 50 then
            count = count +1
          end
          if cloud[l+1][c-1] == 50 then
            count = count +1
          end
          if cloud[l+1][c] == 50 then
            count = count +1
          end
          if cloud[l+1][c+1] == 50 then
            count = count +1
          end
          if cloud[l][c] == 50 then
            if count < 3 then
              cloud[l][c] = false
            end
          elseif cloud[l][c] == false then
            if count> 3 then
              cloud[l][c] = 50
            end
          end
          if cloud[l][c] == 50 then
            local random = math.random(0,10)
            if random > 7 then
              cloud[l][c] = 51
            end
          end
        count = 0      
      end
    end  
  end
  return cloud
end





--------------------------------------------------------------
-- Calcul la position de l'ombre par rapport à l'étoile et 
-- génère une grille de cellule sombre
--------------------------------------------------------------
function grid.initShadow(pX, pY, pAngle, pRadius, pLine, pColumn, pCellSize, pGradient)
  local grid = {}
  local shadowX = pX + math.cos(pAngle) * pRadius
  local shadowY = pY + math.sin(pAngle) * pRadius
  local cellX = (pX - pRadius) + (pCellSize / 2)
  local cellY = (pY - pRadius) + (pCellSize / 2)
  
  --local radius = pRadius - pGradient
  local radius = pRadius 
    
  for l=1, pLine do
    grid[l] = {}
    for c=1, pColumn do
      local distance = math.dist(cellX, cellY, shadowX, shadowY)
      if distance > radius + pGradient then
        grid[l][c] = 0
      elseif distance > radius then
        grid[l][c] = 1
      elseif distance < radius - pGradient then
        grid[l][c] = 3
      elseif distance < radius then
        grid[l][c] = 2
      end
      cellX = cellX + pCellSize
    end
    cellX = (pX - pRadius) + (pCellSize / 2)
    cellY = cellY + pCellSize
  end

  return grid
end

function grid.updateNightCity(Pgrid,Px, Py, PshadowX,Pradius,Pline,Pcolumn,PcellSize,Pgradiant)
  
  -- nouveau 
  local grid = Pgrid
  local cell_x = (Px - Pradius) + (PcellSize /2)
  local cell_y = (Py - Pradius) + (PcellSize /2)
  local shadow_x = PshadowX
  local shadow_y = Py
  local radius = Pradius
  local dh = nil
  
  for l=1, Pline do
    for c=1, Pcolumn do

      local dh = math.dist(cell_x,cell_y,shadow_x,shadow_y)
      if dh < radius - Pgradiant then
        if grid[l][c] == 30 then
            grid[l][c] = math.random(40,41,42)
        end
      elseif dh > radius - Pgradiant then
        if grid[l][c] == 40 or grid[l][c] == 41 or grid[l][c] == 42 then
        grid[l][c] = 30
        end
      end
        cell_x = cell_x + PcellSize
    end
    cell_x = (Px - radius) + (PcellSize / 2)
    cell_y = cell_y + PcellSize
  end
  
  return grid
  
end


function grid.initShadowPlanetView(pX, pY, Pspeed, pRadius, pLine, pColumn, pCellSize, pGradient)
  local grid = {}
  local shadowX =  Pspeed
  local shadowY = pY 
  local cellX = (pX - pRadius) + (pCellSize / 2)
  local cellY = (pY - pRadius) + (pCellSize / 2)
  local radius = pRadius - pGradient
  --local radius = pRadius

  for l=1, pLine do
    grid[l] = {}
    for c=1, pColumn do
      local distance = math.dist(cellX, cellY, shadowX, shadowY)
      if distance > radius + pGradient then
        grid[l][c] = 0
      elseif distance > radius then
        grid[l][c] = 1
      elseif distance < radius - pGradient then
        grid[l][c] = 3
      elseif distance < radius then
        grid[l][c] = 2
      end
      cellX = cellX + pCellSize 
    end
    cellX = (pX - pRadius) + (pCellSize / 2) 
    cellY = cellY + pCellSize
  end

  return grid
end


--------------------------------------------------------------
-- Déplacement horizontal de la grille
--------------------------------------------------------------
function grid.horizontalMove(pGrid, pLine, pColumn)
  local grid = pGrid
  
  for l=pLine,1,-1 do 
    for c=pColumn,1,-1 do
      if c==pColumn then
        grid[l][1] = grid[l][c]
      end
    end
  end
  return grid
end

function grid.replace(pGrid, pCopy, pLine, pColumn)
  for l=1, pLine do
    for c=1, pColumn do
      if c>=2 then
        pGrid[l][c] = pCopy[l][c-1] 
      end
    end
  end
  return pGrid
end


function grid.copy(pGrid, pLine, pColumn)
  local copy = {}
  for l=1, pLine do
    copy[l] = {}
    for c=1, pColumn do
      copy[l][c] = pGrid[l][c]
    end
  end
  return copy
end 

--------------------------------------------------------------
-- Prend une grille en paramêtre. Supprime les cellules en
-- dehors du rayon de la planète pour pouvoir en dessiner le
-- contour. 
-- Margin : permet d'augmenter / diminuer le rayon, faire dépasser les nuages
--------------------------------------------------------------
function grid.toCircle(pGrid, pX, pY, pRadius, pCellSize, pLine, pColumn, pMargin)
  local grid = pGrid
  local cellX = ((pX - pRadius) + (pCellSize / 2))
  local cellY = ((pY - pRadius) + (pCellSize / 2))
  local distance = 0
  local margin = pMargin or 0
    
  for l=1, pLine do
    for c=1, pColumn do
        distance = math.dist(pX, pY, cellX, cellY)
        
        if distance > pRadius then -- + margin
          grid[l][c] = false
        end
      cellX = cellX + pCellSize
    end
  cellX = ((pX - pRadius) + (pCellSize / 2))
  cellY = cellY + pCellSize
  end
  return grid
end

return grid
