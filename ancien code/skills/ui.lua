local ui = {}

  function ui.newIcon(pX, pY, pImage, pScale)
    local icon = {}
      icon.x = pX
      icon.y = pY
      icon.imageDefault = love.graphics.newImage(pImage)
      icon.imageHover = nil
      icon.imagePressed = nil
      icon.scale = pScale or 1
      icon.width = icon.imageDefault:getWidth() * icon.scale
      icon.height = icon.imageDefault:getHeight() * icon.scale
      icon.hover = false
      icon.pressed = false
      icon.toCenter = false
      icon.oldButtonState = false
      icon.sound = nil
      icon.lastEvents = {}
     
    function icon:setSound(pSource)
      self.sound = pSource
    end
    
    function icon:setCoordinateToCenter()
      if self.toCenter then
        self.toCenter = false
      else
        self.x = self.x - ((self.width / 2))
        self.y = self.y - ((self.height / 2))
        self.toCenter = true
      end
    end
      
    function icon:setScale(pScale)
      self.scale = pScale
      icon.width = icon.imageDefault:getWidth() * icon.scale
      icon.height = icon.imageDefault:getHeight() * icon.scale
    end
    
    function icon:setImage(pHover, pPressed)
      icon.imageHover = love.graphics.newImage(pHover)
      icon.imagePressed = love.graphics.newImage(pPressed)
    end
    
    function icon:setEvent(pEventType, pFunction)
      self.lastEvents[pEventType] = pFunction
    end
    
    function icon:update(dt)
      local mx, my = love.mouse.getPosition()
      
      if mx > self.x and mx < self.x + self.width and my > self.y and my < self.y + self.height then
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
      
      if self.hover and love.mouse.isDown(1) and self.pressed == false and self.oldButtonState == false then
        self.pressed = true
        if self.lastEvents["pressed"] ~= nil then
          self.lastEvents["pressed"]()
        end
        if self.sound ~= nil then
          self.sound:play()
        end
      else
        if self.pressed == true and love.mouse.isDown(1) == false then
          self.pressed = false
          --if self.lastEvents["pressed"] ~= nil then
            --self.lastEvents["pressed"]()
          --end
        end
      end
      
      self.oldButtonState = love.mouse.isDown(1)
    end
    
    function icon:draw()
      local x, y = self.x, self.y
      love.graphics.setColor(255, 255, 255)
      
      -- Image par défaut si elle n'est pas survolée
      if self.hover == false then
        love.graphics.draw(self.imageDefault, x, y, 0, self.scale, self.scale)
      end
      -- Changement de l'image si elle existe et qu'elle est survolée
      if self.hover then
        if self.imageHover ~= nil then
          love.graphics.draw(self.imageHover, x, y, 0, self.scale, self.scale)
        else
          -- Si l'image survolé n'existe pas, on affiche un cadre autour
          love.graphics.setColor(255, 255, 255)
          love.graphics.draw(self.imageDefault, self.x, self.y, 0, self.scale, self.scale)
          love.graphics.setColor(255, 255, 255)
          love.graphics.rectangle("line", self.x, self.y, self.width, self.height)
        end
      end
      -- Changement de l'image si l'icône est cliquée
      if self.pressed then
        if self.imagePressed ~= nil then
          
          love.graphics.draw(self.imagePressed, x, y, 0, self.scale, self.scale)
        end
      end
    end
    
    return icon
  end
  
return ui