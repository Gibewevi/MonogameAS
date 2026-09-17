gui_galaxy = {}


function gui_galaxy.stickers(Px, Py, Psprite)
  local stickers = {}
  stickers.scale = 2.5
  stickers.png = love.graphics.newImage("sprites/gui/stickers/"..Psprite..".png")
  stickers.pngWidth = stickers.png:getWidth()*stickers.scale
  stickers.pngHeight = stickers.png:getHeight()*stickers.scale
  stickers.x = Px
  stickers.y = Py
  table.insert(list_stickers, stickers)
  
  function stickers:setPosition(Px, Py)
    self.x = Px + 30
    self.y = Py - stickers.pngHeight
  end
  
  
  function stickers:draw()
    love.graphics.draw(self.png, self.x, self.y,0,stickers.scale,stickers.scale)
  end
  
  
  return stickers
end



function gui_galaxy.button(Px, Py, Pscale, Psprite)
  
  local button = {}
  button.sprite = love.graphics.newImage("sprites/gui/galaxy/"..Psprite..".png")
  button.scale = Pscale
  button.w = button.sprite:getWidth()*button.scale
  button.h = button.sprite:getHeight()*button.scale
  button.x = Px
  button.y = Py
  button.hover = false
  button.isDown = false

  function button:setPositionX(Px)
  self.x = Px
  end
 
  function button:setPositionY(Py)
  self.y = Py
  end
 
 
 function button:draw()
   love.graphics.setColor(255,255,255,255)
   love.graphics.draw(self.sprite, self.x, self.y, 0, self.scale, self.scale)
  end
  return button
end

function gui_galaxy.toolbar(Px, Py, Palignment)
  local toolbar = {}
  toolbar.x = Px
  toolbar.y = Py
  toolbar.w = 0
  toolbar.h = 0
  toolbar.borderRadius = 0
  toolbar.backgroundColor = {255,255,255,180}
  toolbar.borderColor = {0,0,0,255}
  toolbar.alignment = Palignment
  toolbar.icons = {}
  
  function toolbar:setPosition(Px, Py)
    self.x = Px
    self.y = Py
  end
  
  function toolbar:setBorderRadius(Pradius)
  self.borderRadius = Pradius
  end
  
  function toolbar:setBackgroundColor(Pcolor)
  self.backgroundColor = Pcolor
  end

  function toolbar:setAlignment()
    if self.alignment == "horizontal" then
       self.h = self.icons[1].h
       self.w = 0
     
      for i=1, #self.icons do
        self.icons[i].y = self.y
        self.w = self.w + self.icons[i].w

        
          if i == 1 then
            self.icons[i].x = self.x
          elseif i>1 then
            self.icons[i].x = self.icons[i-1].x + self.icons[i-1].w 
          end

      end
    elseif self.alignment == "vertical" then
        self.w = self.icons[1].w
        self.h = 0
        for i=1, #self.icons do
          self.h = self.h + self.icons[i].h
        
          if i==1 then
          self.icons[i].y = self.y
          self.icons[i].x = self.x
          elseif i>1 then
          self.icons[i].y = self.icons[i-1].y + self.icons[i-1].h
          self.icons[i].x = self.x
          end
        end
      
      
    end
  end
  
  
    function toolbar:addIcon(Picon)
      table.insert(self.icons, Picon)
      self:setAlignment(self.alignment)
    end
    
  function toolbar:draw()
    
    -- affichage de la toolbar
    love.graphics.setColor(self.backgroundColor)
    --love.graphics.rectangle("fill", self.x, self.y, self.w, self.h, self.borderRadius, self.borderRadius)
    love.graphics.setColor(self.borderColor)
    --love.graphics.rectangle("line", self.x, self.y, self.w, self.h, self.borderRadius, self.borderRadius)
    love.graphics.setColor(255,255,255,255)
    
    -- affichage de des icons
    for i=1, #self.icons do
      if self.icons[i].hover then
      --  love.graphics.setColor(255,255,255,135)
      love.graphics.draw(self.icons[i].sprite.hover, self.icons[i].x, self.icons[i].y, 0, self.icons[i].scale, self.icons[i].scale)
      elseif self.icons[i].hover == false then
      love.graphics.setColor(255,255,255,255)
      love.graphics.draw(self.icons[i].sprite.icon, self.icons[i].x, self.icons[i].y, 0, self.icons[i].scale, self.icons[i].scale)
      end
    end
    
  end
  
  return toolbar
end


function gui_galaxy.icon(Psprite, Pscale)
local icon = {}
icon.x = 0
icon.y = 0
icon.scale = Pscale
icon.sprite = {}
icon.sprite.icon = love.graphics.newImage("sprites/gui/"..Psprite..".png")
icon.sprite.hover = nil
icon.w = icon.sprite.icon:getWidth()*Pscale
icon.h = icon.sprite.icon:getHeight()*Pscale
icon.hover = false
icon.pressed = false
icon.oldButtonState = false
icon.lastEvents = {}

    function icon:setEvent(Pevent, Pfunction)
      self.lastEvents[Pevent] = Pfunction
    end

    function icon:setIcon(Picon)
      self.sprite.icon = love.graphics.newImage("sprites/gui/"..Picon..".png")
    end
    
    function icon:setHover(Phover)
      self.sprite.hover = love.graphics.newImage("sprites/gui/"..Phover..".png")
    end

    function icon:update()
      local x,y = love.mouse.getPosition()

        if x >= self.x and x <= self.x + self.w and y >= self.y and y <= self.y + self.h then
          if self.hover == false then
            self.hover = true
            if self.lastEvents["hover"] ~= nil then
              self.lastEvents["hover"]("begin")
            end
          end
        else
           if self.hover == true then
              self.hover = false
            if self.lastEvents["hover"] ~= nil then
              self.lastEvents["hover"]("end")
            end
           end
        end
        
        
        if self.hover and self.pressed == false and self.oldButtonState == false and love.mouse.isDown(1) then
          self.pressed = true
          if self.lastEvents["pressed"] ~= nil then
              self.lastEvents["pressed"]()
          end
        else
          if self.pressed and love.mouse.isDown(1) == false then
              self.pressed = false
          end
        end
        

    end



  return icon
end

return gui_galaxy
