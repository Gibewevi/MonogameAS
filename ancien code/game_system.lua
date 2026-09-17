game_galaxy = require("game_galaxy")
displacement = require("script/displacement")

game_system = {}

function game_system.update(dt)
  displacement.NewDestinateSystem(dt)

  if player.system.road then
    displacement.RoadSystem(dt)
  end

  -- Actualise les icones (hover, pressed)
  for i = 1, #icon do
    icon[i]:update()
  end


  if buttonGalaxy then
    list_tiles[TILE_HERE].sun[SUN_HERE]:setViewType("system")


    GAME = "galaxy"
    buttonGalaxy = false
  end


  list_tiles[TILE_HERE].sun[SUN_HERE].system[1]:update(dt)
end

function game_system.draw()
  if player.galaxy.road == false then
    displacement.DrawRoadSystem()


    list_tiles[TILE_HERE].sun[SUN_HERE].system[1]:draw()



    love.graphics.circle("fill", player.system.x, player.system.y, 8)
  end

  if player.galaxy.road then
    -- Affichage titre
    Title("[Perte du signal]", font.titleView, width / 2, height / 2, { 185, 72, 72, 255 }, true)
  end


  -- Affichage titre
  Title(view_system_text, font.titleView, width / 2, 0, { 65, 160, 250, 180 }, true)

  toolbar[1]:draw()
  toolbar[2]:draw()
end

return game_system
