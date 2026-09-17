save = {}

function saveSun(Ptile,Psun)
    local newSun = {}
    newSun.tileId = Psun.tileId
    newSun.sunId = Psun.sunId 
    newSun.id = Psun.id
    newSun.name = Psun.name
    newSun.type = Psun.type
    newSun.viewType = Psun.viewType
    newSun.x = Psun.x
    newSun.y = Psun.y
    newSun.c = Psun.c
    newSun.l = Psun.l
    newSun.posX = Psun.posX
    newSun.posY = Psun.posY
    newSun.here = Psun.here
    newSun.discover = Psun.discover
    newSun.xo = Psun.xo
    newSun.yo = Psun.yo
    newSun.celsus = Psun.celsus
    newSun.light = Psun.light
    newSun.radius = Psun.radius
    newSun.diameter = Psun.diameter
    newSun.scale = Psun.scale
    newSun.system = Psun.system
    newSun.galaxyView = Psun.galaxyView
    newSun.systemView = Psun.systemView
    newSun.galaxyZoom = Psun.galaxyZoom  
    newSun.star =  Psun.star
    newSun.light = Psun.light
    newSun.light.system = Psun.light.system
    newSun.color = Psun.color
    newSun.infos = Psun.infos
    newSun.hover = Psun.hover
    newSun.isSelected = Psun.isSelected
    newSun.isVisible = Psun.isVisible
    newSun.debug = Psun.debug
    print("sauvegarde du soleil")
    table.insert(Ptile,newSun)
end

function saveTile(Ptile)
 local tile = {}
  tile.id = Ptile.id
  tile.x = Ptile.x
  tile.y = Ptile.y
  tile.idX = Ptile.idX
  tile.idY = Ptile.idY
  tile.color = Ptile.color
  tile.isVisible = Ptile.isVisible
  tile.discover =  Ptile.discover
  tile.cellSize = Ptile.cellSize
  tile.c = Ptile.c
  tile.l = Ptile.l
  tile.w = Ptile.w
  tile.h = Ptile.h
  tile.dx = Ptile.dx
  tile.dy = Ptile.dy
  
  tile.name = Ptile.name
 
  tile.grid = Ptile.grid
  --tile.sun = Ptile.sun

  table.insert(listTileTest,tile)
  local saveTileSaveTest = json.encode(listTileTest)
  print(saveTileSaveTest)
end

return save