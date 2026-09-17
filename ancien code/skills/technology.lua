local ui = require("skills/ui")

local technology = {}

technology.category = 3
technology.nbOfSkills = 3
technology.categoryAngle = 0
technology.skillAngle = 0
technology.scale = 2

function technology:coordinatesAttribution(pX, pY, pRadiusLvl1)
  -- Partager l'arbre en plusieurs parts
  self.categoryAngle = (2 * math.pi) / self.category
  -- Attribution des coordonées
  for i=1, #technology do
    local angleSpace = self.categoryAngle / (#technology[i] + 1)
    local skillAngle = (self.categoryAngle * i) + angleSpace
    for j=1, #technology[i] do
      self[i][j].icon.x = pX + math.cos(skillAngle) * pRadiusLvl1
      self[i][j].icon.y = pY + math.sin(skillAngle) * pRadiusLvl1
      self[i][j].icon:setCoordinateToCenter()
      skillAngle = skillAngle + angleSpace
    end
  end
end

technology[1] = {}
  technology[1][1] = {
    id = 1,
    x = 0,
    y = 0,
    angle = 0,
    level = 1,
    category = "ship",
    icon = ui.newIcon(0, 0, "sprites/gui/bonus.png", technology.scale),
    imageScale = 1,
    title = "Intelligence artificielle",
    description = "Fatigué de perdre votre temps à debugger vos programmes. Profitez de cette IA conçue pour cette tâche ingrate et passez plus de temps à procrastiner devant vos séries préférées."
  }

  technology[1][2] = {
    id = 2,
    x = 0,
    y = 0,
    angle = 0,
    level = 1,
    category = "ship",
    icon = ui.newIcon(0, 0, "sprites/gui/bonus.png", technology.scale),
    imageScale = 1,
    title = "Stase",
    description = "Les années passent et votre corps défaille. Lors de vos prochains voyages interstellaire, allez donc vous coucher dans ce caisson à la pointe de la technologie et retrouvez votre corps tel que vous l'avez laisser quelques années plus tôt."
  }
  
   technology[1][3] = {
    id = 2,
    x = 0,
    y = 0,
    angle = 0,
    level = 1,
    category = "ship",
    icon = ui.newIcon(0, 0, "sprites/gui/bonus.png", technology.scale),
    imageScale = 1,
    title = "Stase",
    description = "Les années passent et votre corps défaille. Lors de vos prochains voyages interstellaire, allez donc vous coucher dans ce caisson à la pointe de la technologie et retrouvez votre corps tel que vous l'avez laisser quelques années plus tôt."
  }
  
  technology[1][4] = {
    id = 2,
    x = 0,
    y = 0,
    angle = 0,
    level = 1,
    category = "ship",
    icon = ui.newIcon(0, 0, "sprites/gui/bonus.png", technology.scale),
    imageScale = 1,
    title = "Stase",
    description = "Les années passent et votre corps défaille. Lors de vos prochains voyages interstellaire, allez donc vous coucher dans ce caisson à la pointe de la technologie et retrouvez votre corps tel que vous l'avez laisser quelques années plus tôt."
  }
  
technology[2] = {}
  technology[2][1] = {
    id = 1,
    x = 0,
    y = 0,
    angle = 0,
    level = 1,
    category = "space",
    icon = ui.newIcon(0, 0, "sprites/gui/bonus.png", technology.scale),
    image = love.graphics.newImage("sprites/gui/bonus.png"),
    imageScale = 1,
    title = "Pour test",
    description = "Description pour test Description pour test Description pour test Description pour test Description pour test"
  }
  
  technology[2][2] = {
    id = 1,
    x = 0,
    y = 0,
    angle = 0,
    level = 1,
    category = "space",
    icon = ui.newIcon(0, 0, "sprites/gui/bonus.png", technology.scale),
    image = love.graphics.newImage("sprites/gui/bonus.png"),
    imageScale = 1,
    title = "Pour test",
    description = "Description pour test Description pour test Description pour test Description pour test Description pour test"
  }
  
  technology[2][3] = {
    id = 1,
    x = 0,
    y = 0,
    angle = 0,
    level = 1,
    category = "space",
    icon = ui.newIcon(0, 0, "sprites/gui/bonus.png", technology.scale),
    image = love.graphics.newImage("sprites/gui/bonus.png"),
    imageScale = 1,
    title = "Pour test",
    description = "Description pour test Description pour test Description pour test Description pour test Description pour test"
  }
  
  technology[3] = {}
  technology[3][1] = {
    id = 1,
    x = 0,
    y = 0,
    angle = 0,
    level = 1,
    category = "space",
    icon = ui.newIcon(0, 0, "sprites/gui/bonus.png", technology.scale),
    image = love.graphics.newImage("sprites/gui/bonus.png"),
    imageScale = 1,
    title = "Pour test",
    description = "Description pour test Description pour test Description pour test Description pour test Description pour test"
  }
  
  technology[3][2] = {
    id = 1,
    x = 0,
    y = 0,
    angle = 0,
    level = 1,
    category = "space",
    icon = ui.newIcon(0, 0, "sprites/gui/bonus.png", technology.scale),
    image = love.graphics.newImage("sprites/gui/bonus.png"),
    imageScale = 1,
    title = "Pour test",
    description = "Description pour test Description pour test Description pour test Description pour test Description pour test"
  }

return technology