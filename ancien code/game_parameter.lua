game_parameter = {}

-- Option de jeu
LANGUAGE = "ENGLISH"
RESO_WIDTH = 1024
RESO_HEIGHT = 800

-- Variable du jeu
GAME = "galaxy"
TILES_LOAD = 0 
FILEDIRECTORY = love.filesystem.getSaveDirectory( )
MIN_PLANETS = 3
MAX_PLANETS = 3
MIN_RADIUS = 4--4
MAX_RADIUS = 14--7--11
PLANET_VIEW_CELLSIZE = 2
RATIO_PLANET_VIEW = 14 --15
VIEW_X = 40
VIEW_Y = 40
CLOUD_ADD_RADIUS = 4
-- Constante 
SUCCESS = false
ELLIPTICAL_ORBIT = "ellipse" -- (ellipse ou circle) Le système solaire est représenté en vue elliptique pour l'orbite des planètes


-- Echelle bouton UI
scale_button = 1.7


-- liste d'élèments
list_stickers = {}

-- Variable de la partie
ZOOM = 1
SYSTEM_DISCOVER = 1
-- Stock variable sun discover
SUN_DISCOVER = {}
-- Position du joueur
TILE_HERE = nil
SUN_HERE = nil
TILE_SAVE = {}
SAVE = false

return game_parameter 