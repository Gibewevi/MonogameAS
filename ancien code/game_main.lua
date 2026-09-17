game_main = {}


function game_main.load()
  modelBox.main()
end

function game_main.update(dt)
 boxWindow.updateBox()
end

function game_main.draw()
  boxWindow.drawBox()
end



return game_main