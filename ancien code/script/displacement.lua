displacement = {}
local boxWindow = require ("script/boxWindow")
local modelBox = ("script/modelBox")


local system = require ("system")
local player = require ("player")

function math.dist(x1,y1, x2,y2) return ((x2-x1)^2+(y2-y1)^2)^0.5 end
function math.angle(x1,y1, x2,y2) return math.atan2(y2-y1, x2-x1) end

function drawDottedLine(pX1, pY1, pX2, pY2, pLineWidth, pSpace)
  local dist = math.dist(pX1, pY1, pX2, pY2)
  local slice = math.floor(dist / (pLineWidth + pSpace))
  local angle = math.angle(pX1, pY1, pX2, pY2)
  local x1, y1 = pX1, pY1
  local x2, y2 = 0, 0
  
  for i=1, slice do
    x2 = x1 + math.cos(angle) * pLineWidth
    y2 = y1 + math.sin(angle) * pLineWidth
    love.graphics.line(x1, y1, x2, y2)
    x1 = x2 + math.cos(angle) * pSpace
    y1 = y2 + math.sin(angle) * pSpace
  end
end

-- DEPLACEMENT GALAXIE 
  -- fonction qui actualise les trajets en temps reel dans toute les vues
  function displacement.UpdateLine()
    -- actualisation des coordonnées des points contenus dans les listes A et B
      for i=1, #list_pointA do
        list_pointA[i].x = list_tiles[list_pointA[i].tile].sun[list_pointA[i].sun].x
        list_pointA[i].y = list_tiles[list_pointA[i].tile].sun[list_pointA[i].sun].y
      end
      
      for i=1, #list_pointB do
        if list_pointB[i].tile ~= nil then
          list_pointB[i].x = list_tiles[list_pointB[i].tile].sun[list_pointB[i].sun].x
          list_pointB[i].y = list_tiles[list_pointB[i].tile].sun[list_pointB[i].sun].y          
        end
      end
  end


 -- fonction pour tracer un nouveau trajet
    
local departure = 0
local arrival = 0

 function displacement.NewLine(Ptile,Psun)
print("deplacement en cours")
  -- vérification qu'aucuns points de soit selectionnés
 -- if pointA == false and pointB == false then
      local tiles
      local here

          -- si notre étoile de résidence est visible et que je clique dessus alors...

              -- je créé un point A/position du soleil de résidence actuel
               local pointA = {}
               local pointB = {}
               pointA.tile = TILE_HERE
               pointA.sun = SUN_HERE
               pointA.x = list_tiles[TILE_HERE].sun[SUN_HERE].x
               pointA.y = list_tiles[TILE_HERE].sun[SUN_HERE].y
               -- je créé un point B/position de ma souris pour selectionner la destination
               pointB.x = list_tiles[Ptile].sun[Psun].x
               pointB.y = list_tiles[Ptile].sun[Psun].y
               pointB.tile = Ptile
               pointB.sun = Psun
              table.insert(list_pointA, pointA)
              table.insert(list_pointB, pointB)
               -- je mémorise les indices de notre soleil de résidence
               tiles = TILE_HERE
               here = SUN_HERE    
               -- on récupère le nom du système
               departure = list_tiles[TILE_HERE].sun[SUN_HERE].name
               
                -- On récupère le nom de l'arrivée
                arrival = list_tiles[Ptile].sun[Psun].name
                -- calcul dh
                local dh = math.floor(math.dist(list_pointA[#list_pointA].x, list_pointA[#list_pointA].y, list_pointB[#list_pointB].x, list_pointB[#list_pointB].y))               
                boxWindow.addRoadGalaxy(departure, arrival, dh)
                list_tiles[Ptile].sun[Psun].isSelected = false
               
              SYSTEM_DISCOVER = SYSTEM_DISCOVER + 1    
                -- SI le système est découvert
                if list_tiles[Ptile].sun[Psun].discover then
                  -- Et qu'il n'a pas encore été chargé
                  if #list_tiles[Ptile].sun[Psun].system == 0 then
                      -- Chargement du système
                      print("Chargement du système")
                      data.LoadSystem(Ptile)
                  -- SI contient déjà le chargement
                  elseif #list_tiles[Ptile].sun[Psun].system ~= 0 then
                  -- Je ne fais rien
                  print("contient déjà un système")
                end

            -- SINON SI le système est inconnu
            elseif list_tiles[Ptile].sun[Psun].discover == false then
                  -- Je met à jour le système "découvert"
                  list_tiles[Ptile].discover = true
                  list_tiles[Ptile].sun[Psun].discover, list_tiles[Ptile].discover = true, true
                  -- Attribution d'un ID a notre nouvelle résidence
                  list_tiles[Ptile].sun[Psun].id = SYSTEM_DISCOVER 
                  if #list_tiles[Ptile].sun[Psun].system == 0 then 
                    local system = system.new(width/2, height/2, id, 0)
                    -- Attribution ID fixe soleil/planete
                    list_tiles[Ptile].sun[Psun].id = id
                    system:generate(list_tiles[Ptile].sun[Psun], id)
                    
                    table.insert(list_tiles[Ptile].sun[Psun].system, system)
                    list_tiles[Ptile].sun[Psun].totalPlanets = list_tiles[Ptile].sun[Psun].system[1].totalPlanets
                    table.insert(SUN_DISCOVER,{Ptile,Psun})
                  end      
                end
                

end  

            

 function displacement.DrawLine()
  -- si la liste Point B contient quelque chose, alors affiche la ligne AB
    if ZOOM == 1 then
      if #list_pointB>0 then
        for i=1, #list_pointA do
          love.graphics.setLineWidth(3)
          love.graphics.setColor(159,252,246,180)
          drawDottedLine(list_pointA[i].x, list_pointA[i].y, list_pointB[i].x, list_pointB[i].y, 15, 15)
        end
    love.graphics.setLineWidth(1)
      end
    elseif ZOOM == 2 then
      if #list_pointB>0 then
        for i=1, #list_pointA do
          love.graphics.setLineWidth(3)
          love.graphics.setColor(159,252,246,180)
          drawDottedLine(list_pointA[i].x, list_pointA[i].y, list_pointB[i].x, list_pointB[i].y, 5, 5)
        end
    love.graphics.setLineWidth(1)
      end
    end
  end

  

  function displacement.RoadGalaxy(dt)
    
    -- Si le joueur a validé un trajet/est en route alors
    if player.galaxy.road then
      
   

      -- calcul de l'angle AB
      local angle = math.angle(list_pointA[#list_pointA].x, list_pointA[#list_pointA].y ,list_pointB[#list_pointB].x ,list_pointB[#list_pointB].y)
      local force 
      -- si je suis en ZOOM 1 ou 2, j'applique le ratio de cohérence pour la distance
      if ZOOM == 1 then
        player.galaxy.x = list_pointA[#list_pointA].x + player.galaxy.v * math.cos(angle)
        player.galaxy.y = list_pointA[#list_pointA].y + player.galaxy.v * math.sin(angle)
      elseif ZOOM == 2 then
        player.galaxy.x = list_pointA[#list_pointA].x + ((player.galaxy.v)/4) * math.cos(angle)
        player.galaxy.y = list_pointA[#list_pointA].y + ((player.galaxy.v)/4) * math.sin(angle)
      end

        -- calcul de la vitesse 
        player.galaxy.v = player.galaxy.v + (player.galaxy.force*dt)        
        
        local dh = math.dist(list_pointA[#list_pointA].x, list_pointA[#list_pointA].y, list_pointB[#list_pointB].x, list_pointB[#list_pointB].y)
   
      -- vérification du ZOOM pour le ratio
      if ZOOM == 1 then
        if player.galaxy.v >= dh then                  
                  player.discover.system = player.discover.system + 1
                  player.discover.planet = player.discover.planet + 1
          -- la distance entre AB valide, j'arrète la fonction
          player.galaxy.road = false
  

                  -- le soleil de résidence passe false
                  if list_tiles[TILE_HERE].sun[SUN_HERE].here == true then list_tiles[TILE_HERE].sun[SUN_HERE].here = false end
                  -- j'attribue une nouvelle résidence sur la destination
                  list_tiles[list_pointB[#list_pointB].tile].sun[list_pointB[#list_pointB].sun].here = true 
                  TILE_HERE = list_pointB[#list_pointB].tile  
                  SUN_HERE = list_pointB[#list_pointB].sun
                  table.insert(TILE_SAVE, {TILE_HERE,SUN_HERE}) 
                  NewChunk()
                  player.galaxy.x, player.galaxy.y, player.galaxy.v = list_pointB[#list_pointB].x, list_pointB[#list_pointB].y, 0


          end
        elseif ZOOM == 2 then
          if player.galaxy.v/4 >= dh then 
                  player.discover.system = player.discover.system + 1
                  player.discover.planet = player.discover.planet + 1

            player.galaxy.road = false
    

                    if list_tiles[TILE_HERE].sun[SUN_HERE].here == true then list_tiles[TILE_HERE].sun[SUN_HERE].here = false end
                    list_tiles[list_pointB[#list_pointB].tile].sun[list_pointB[#list_pointB].sun].here = true 
                    TILE_HERE = list_pointB[#list_pointB].tile 
                    SUN_HERE = list_pointB[#list_pointB].sun
                    table.insert(TILE_SAVE, {TILE_HERE,SUN_HERE}) 
                    NewChunk()
                    player.galaxy.x, player.galaxy.y, player.galaxy.v = list_pointB[#list_pointB].x, list_pointB[#list_pointB].y, 0

            end
          end
                UpdateTile()
    end
  end
  
  
  -- fonctions draw
  
  function displacement.DrawRoadGalaxy()
    if player.galaxy.road then  
        local circleRadius
        
        -- taille de l'objet en fonction du ZOOM
        if ZOOM == 1 then
          circleRadius = 8
        elseif ZOOM == 2 then
          circleRadius = 2
        end
        love.graphics.circle("fill", player.galaxy.x, player.galaxy.y, circleRadius)
    end
  end
  
  
  -- DEPLACEMENT VUE SYSTEME
  local list_pointA_system = {}
  local list_pointB_system = {}
  local pointA_system = {}
  local pointB_system = {}
   pointA_system.x, pointA_system.y, pointB_system.x, pointB_system.y = 0, 0, 0, 0
   pointA_system.select = false
   pointB_system.select = false   
   
   
  function displacement.NewDestinateSystem(dt)

    for i=1, #list_tiles do
        for j=1, #list_tiles[i].sun do
          if list_tiles[i].sun[j].here then
            for k=1, #list_tiles[i].sun[j].system[1].planets do
              list_tiles[i].sun[j].system[1].planets[k]:hover_selected(dt)
              
              if list_tiles[i].sun[j].system[1].planets[k].here and list_tiles[i].sun[j].system[1].planets[k].isSelected then
                local planet = list_tiles[i].sun[j].system[1].planets[k]
                pointA_system.x, pointA_system.y = planet.x, planet.y
                pointA_system.i, pointA_system.j, pointA_system.k = i, j, k 
                pointA_system.select = true
                table.insert(list_pointA_system, pointA_system)
                
               end
               
               if pointA_system.select and pointB_system.select == false then
                 local x,y = love.mouse.getPosition()
                 pointB_system.x, pointB_system.y = x, y
               else  end
               
               if pointA_system.select and list_tiles[i].sun[j].system[1].planets[k].isSelected and list_tiles[i].sun[j].system[1].planets[k].here == false then
                 pointB_system.i, pointB_system.j, pointB_system.k = i,j,k
                 local planet = list_tiles[i].sun[j].system[1].planets[k]
                 pointB_system.x = planet.x
                 pointB_system.y = planet.y
                 pointB_system.i, pointB_system.j, pointB_system.k = i, j, k
                 pointB_system.select = true
                 table.insert(list_pointB_system, pointB_system)

             
             player.system.road = true
                end
               end
            end
          end
        end
    end
    
  function displacement.RoadSystem(dt)
      local planet, destinate = #list_pointA_system, #list_pointB_system
    if player.system.road then 
      local angle = math.angle(list_pointA_system[planet].x, list_pointA_system[planet].y, list_pointB_system[destinate].x, list_pointB_system[destinate].y)
      local force = 400
      local dh = math.dist(list_pointA_system[planet].x, list_pointA_system[planet].y, list_pointB_system[destinate].x, list_pointB_system[destinate].y)
      player.system.v = player.system.v + (force*dt)
      player.system.x = list_pointA_system[planet].x + player.system.v * math.cos(angle)
      player.system.y = list_pointA_system[planet].y + player.system.v * math.sin(angle)
      
      if player.system.v >= dh then
        player.system.road = false
        list_tiles[list_pointA_system[planet].i].sun[list_pointA_system[planet].j].system[1].planets[list_pointA_system[planet].k].here = false
        list_tiles[list_pointB_system[destinate].i].sun[list_pointB_system[destinate].j].system[1].planets[list_pointB_system[destinate].k].here = true
        
        -- On rajoute une planète decouverte
         player.discover.planet = player.discover.planet + 1                 
         pointA_system.select = false 
         pointB_system.select = false  
         player.system.v = 0
        for i=1, #list_pointA_system do table.remove(list_pointA_system, i) table.remove(list_pointB_system, i) end
        
        
      end  
    end
  end

  function displacement.DrawRoadSystem()
    
    for i=1, #list_tiles do
        for j=1, #list_tiles[i].sun do
          if list_tiles[i].sun[j].here then
            for k=1, #list_tiles[i].sun[j].system[1].planets do
              if list_tiles[i].sun[j].system[1].planets[k].here then
                local planet = list_tiles[i].sun[j].system[1].planets[k]
                love.graphics.circle("line", planet.x, planet.y, 20)
              end
            end
          end
        end
    end   

    if pointA_system.select == true then 
      love.graphics.setLineWidth(2)
      love.graphics.setColor(74,255,211,255)
      drawDottedLine(pointA_system.x, pointA_system.y,  pointB_system.x, pointB_system.y, 10, 5)
      love.graphics.setColor(255,255,255,255)
      love.graphics.setLineWidth(1)
    end
  end
  
  
  
    
return displacement