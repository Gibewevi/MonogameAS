-- Cette ligne permet d'afficher des traces dans la console pendant l'éxécution
io.stdout:setvbuf('no')

-- Empèche Love de filtrer les contours des images quand elles sont redimentionnées
-- Indispensable pour du pixel art
love.graphics.setDefaultFilter("nearest")




-- Cette ligne permet de déboguer pas à pas dans ZeroBraneStudio
if arg[#arg] == "-debug" then require("mobdebug").start() end
json = require ("script/json")
font = require ("fonts/font")
local system = require ("system")
local sun = require ("sun")
local game_parameter = require ("game_parameter")
local text_ui = require ("text/text_ui")
local math = require ("math")
local player = require ("player")
success = require ("success")
local modelBox = require ("script/modelBox")
local gui_buttons = require ("gui/gui_buttons")
local gui = require ("gui/gui")
local map = require ("map")
local game_main = require ("game_main")
local game_galaxy = require ("game_galaxy")
local game_system = require ("game_system")
local game_planet = require ("game_planet")
local data = require ("script/data")
local tech = require ("tech")

love.window.setMode(RESO_WIDTH,RESO_HEIGHT)
--love.window.setFullscreen(true, "desktop")
width = love.graphics.getWidth()
height = love.graphics.getHeight()


list_tiles_temp = {}
list_tiles = {} 
list_button = {}
list_box = {}
list_tech = {}
save = false

function love.load()
  createListTech()
  
-- création dossier pour stocker world
love.filesystem.createDirectory("MAP" )
data.parameterLoad()

  gui.load()
  game_galaxy.load()
  game_planet.load()

end

function love.update(dt)

  boxWindow.updateBox() 
  success.update()

 
  if GAME == "galaxy" then
  game_galaxy.update(dt)
elseif GAME == "system" then
  game_system.update(dt)
elseif GAME == "planet" then
 game_planet.update(dt)
elseif GAME == "main" then
  game_main.update(dt)
end

end

function love.draw()
  love.graphics.print(tostring(love.timer.getFPS()), 10, 10)
    -- Adventure Sandbox Version
  --  love.graphics.setColor(255,255,255,255)
    Title("[OPTIMIZE VERSION-13/06/2020-19h42]", font.titleView, width-(width/5), 5, {202,58,56,255},true)
          
  if GAME == "galaxy" then
  game_galaxy.draw()
elseif GAME == "system" then
  game_system.draw()
elseif GAME == "planet" then
 game_planet.draw()
elseif GAME == "main" then
  game_main.draw()
  end


end

function love.keypressed(key)
  if key == "m" then map.location() end
  if key == "s" then 
    for i=1, #TILE_SAVE do
    data.SaveMap(TILE_SAVE[i][1])  
    end
    for i=#TILE_SAVE,1,-1 do
    table.remove(TILE_SAVE,i)
    end
    SAVE = true
    data.parameterSave()
    table.insert(TILE_SAVE,{TILE_HERE,SUN_HERE})
    end
  
    if key=="q" then love.event.quit() end
      
  if GAME == "galaxy" then
    game_galaxy.keypressed(key)
  end
 
end

function love.mousepressed(x,y,button)
  if GAME == "galaxy" then
  game_galaxy.mousepressed(x,y,button)
  end
end