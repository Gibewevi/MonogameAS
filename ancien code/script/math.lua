math = {}


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



return math