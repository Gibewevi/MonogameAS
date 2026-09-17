tech = {}

function createListTech()
  -- Initialisation des constructeurs
  local arpex = {}

  -- creation des objets arpex
  local orbital_colony = tech.orbital_colony("Arpex", "model Colonial_B1", 1550000, "modelB1.png", pLifeTime)
  table.insert(arpex,orbital_colony)
  
  table.insert(list_tech, arpex)
end

function tech.orbital_colony(pConstructor, pName, pPrice, pAnimation, pLifeTime)
  local objet = {}
  objet.constructor = pConstructor
  objet.name = Pname 
  objet.price = pPrice
  objet.lifeTime = pLifeTime
  objet.animation = love.graphics.newImage("sprites/tech/"..pConstructor.."/"..pAnimation)
  return objet
end

function tech.probe_Communication(pConstructor,pName,pPrice,pLifeTime,pScope,pAnimation)
local objet = {}
objet.constructor = pConstructor
objet.name = pName
objet.price = pPrice
objet.lifeTime = pLifeTime
objet.scope = pScope
objet.weight = nil
objet.manufactoringTime = nil
objet.animation = pAnimation

return objet
end

return tech