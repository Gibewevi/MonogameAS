game_planet = {}
local skillTree = require("skills/skillTree")
UIBOX_ANALYSE = false




function game_planet.load()
  
--modelBox.exploration()
--modelBox.exploration_Probe()  
--modelBox.exploration_Terrestre() 
--modelBox.laboratory()
end

function game_planet.update(dt)
  
  -- Actualisation des boites de dialogues
   -- UpdateBoxExploration()
  
  -- Actualise les icones (hover, pressed)
  for i=1, #icon do
    icon[i]:update()
  end
  
  for i=1, #list_tiles do
    for j=1, #list_tiles[i].sun do
      if list_tiles[i].sun[j].here then
        for k=1, #list_tiles[i].sun[j].system[1].planets do
          if list_tiles[i].sun[j].system[1].planets[k].here then
              list_tiles[i].sun[j].system[1].planets[k]:update(dt)   
          end
        end
      end
    end
  end   
    skillTree.update(dt)
end

function game_planet.draw()

  for i=1, #list_tiles do
    for j=1, #list_tiles[i].sun do
      if list_tiles[i].sun[j].here then
        -- Affichage des effets de lumière
        list_tiles[i].sun[j]:drawPlanetView()
      end
    end
  end


  for i=1, #list_tiles do
    for j=1, #list_tiles[i].sun do
      if list_tiles[i].sun[j].here then
        for k=1, #list_tiles[i].sun[j].system[1].planets do
          if list_tiles[i].sun[j].system[1].planets[k].here then
              list_tiles[i].sun[j].system[1].planets[k]:drawOrb()
              list_tiles[i].sun[j].system[1].planets[k]:drawOrb()
              list_tiles[i].sun[j].system[1].planets[k]:drawPlanetView()   
          end
        end
      end
    end
  end      
  
  

  -- Affichage de la toolbar 
    
    toolbar[2]:draw()
    toolbar[3]:draw()
    
  -- DEBUG Affichage de la boite notification
  boxWindow.drawBox()


     -- Affichage titre
    Title(view_planet_text, font.titleView, width/2, 0, {65,160,250,180},true)
  
end










return game_planet