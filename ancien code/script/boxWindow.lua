boxWindow = {}


  
function boxWindow.updateBox(dt)

    for i=#list_box, 1, -1 do
      if list_box[i].isActive then 
        list_box[i]:update(dt)
      end
    end

    for i=1,#list_box do
      if list_box[i].isActive then
        for j=1,#list_box[i].parent do
          list_box[i].parent[j]:update(dt)
        end
      end
    end
    
end

function boxWindow.drawBox()
  if #list_box ~= 0 then
    for i=1, #list_box do
      if list_box[i].isActive then
          list_box[i]:draw()
          for j=1,#list_box[i].parent do
            if list_box[i].parent[j].isActive then
            list_box[i].parent[j]:draw()
            end
          end
      end
    end  
  end
end

function boxWindow.addBox(Ptype, Px, Py, Pw, Ph, Pskin, Pscale)
  local box = {}
  -- constante de la fenetre (position, taille et echelle)
  box.id = #list_box
  
  -- Attribu parenté tuile/soleil pour boite de déplacement
  box.tileID = nil
  box.sunID = nil
  box.name = "nil"
  box.state = nil
  box.x, box.y = Px or 0, Py or 0
  box.w, box.h = Pw or 0, Ph or 0
  box.c, box.l = 0,0
  box.s = Pscale or 4
    -- variable local de taille pour construire la fenetre
  box.width_body, box.height_body = 0,0
  box.y_originText = 40
  box.parent = {}
  -- type de boite (notification, box)
  box.type = Ptype
  -- type de slin (choix du skin)
  box.skin = Pskin or "standard"
    -- libellé d'en tête
    box.word = "Standard"
    box.wordWidth = nil
    -- alignement de l'en-tête
    box.alignWord = "left"
    -- sa taille
    box.sizeTitle = 25
    -- sa font
    box.font = love.graphics.newFont("fonts/Pixellari.ttf",box.sizeTitle) 
  -- stockage de sprites pour construire la fenetre
  box.body = {}
  -- variables concernant le deplacement de la fenetre
  -- boleen pour appuyer sur la fenetre (afin de la deplacer)
  box.lock = false
    -- variable pour les coordonnées de la souris, et ses deltas XY

    box.dx, box.dy = 0,0
    box.isActive = false
    box.isMoving = false
    
    box.lastEvents = false
  -- table de boutons 
  box.buttons = {}
  -- variable boite utilisé/a supprimer
  box.isUsed = false
  box.gauge = {}
  box.content = {}
  -- animation
  box.animation = {}
  box.choice = {}
  -- pour les boites statique/en mouvement
  box.static = false
  
  
  function box:build()
    
    if self.type == "box" then
      -- fonction de construction de la fenetre
      local l,c
      for l=1, 3 do
        for c=1, 3 do
          if l==1 and c==1 then
            self.body[l] = {}
            self.body[l][c] = {}
            local png = love.graphics.newImage
            self.body[l][c].png = png("sprites/skin/"..self.skin.."/head_left.png")
            -- taille du sprite (longueur, largeur)
            self.body[l][c].w = self.body[l][c].png:getWidth()*self.s
            self.body[l][c].h = self.body[l][c].png:getHeight()*self.s
            -- calcul de la longueur/largeur de la fenetre sans les extrèmités
            box.width_body = self.w - (2*self.body[l][c].png:getWidth()*self.s)
            box.height_body = self.h - (2*self.body[l][c].png:getHeight()*self.s)
            -- position du sprite
            self.body[l][c].x = self.x
            self.body[l][c].y = self.y
            table.insert(self.body, self.body[l][c])

          elseif l==1 and c==2 then
            self.body[l][c] = {}
            local png = love.graphics.newImage
            self.body[l][c].png = png("sprites/skin/"..self.skin.."/head_center.png")
            self.body[l][c].w = self.body[l][c].png:getWidth()*box.width_body
            self.body[l][c].h = self.body[l][c].png:getHeight()*self.s
            self.body[l][c].x = self.body[l][c-1].x + self.body[l][c-1].w
            self.body[l][c].y = self.y
            table.insert(self.body, self.body[l][c])    
          elseif l==1 and c==3 then
            self.body[l][c] = {}
            local png = love.graphics.newImage
            self.body[l][c].png = png("sprites/skin/"..self.skin.."/head_right.png")
            self.body[l][c].w = self.body[l][c].png:getWidth()*self.s
            self.body[l][c].h = self.body[l][c].png:getHeight()*self.s
            self.body[l][c].x = self.body[l][c-1].x + self.body[l][c-1].w
            self.body[l][c].y = self.y
            table.insert(self.body, self.body[l][c])         
          end
          
          if l==2 and c==1 then
            self.body[l][c] = {}
            local png = love.graphics.newImage
            self.body[l][c].png = png("sprites/skin/"..self.skin.."/body_left.png")
            self.body[l][c].w = self.body[l][c].png:getWidth()*self.s
            self.body[l][c].h = self.body[l][c].png:getHeight()*box.height_body
            self.body[l][c].x = self.x
            self.body[l][c].y = self.y + self.body[l-1][1].h
            table.insert(self.body, self.body[l][c])        
          elseif l==2 and c==2 then
            self.body[l][c] = {}
            local png = love.graphics.newImage
            self.body[l][c].png = png("sprites/skin/"..self.skin.."/body_center.png")
            self.body[l][c].w = self.body[l][c].png:getWidth()*box.width_body
            self.body[l][c].h = self.body[l][c].png:getHeight()*self.h
            self.body[l][c].x = self.body[l][c-1].x + self.body[l][c-1].w
            self.body[l][c].y = self.body[l][c-1].y
            table.insert(self.body, self.body[l][c])   
          elseif l==2 and c==3 then
            self.body[l][c] = {}
            local png = love.graphics.newImage
            self.body[l][c].png = png("sprites/skin/"..self.skin.."/body_right.png")
            self.body[l][c].w = self.body[l][c].png:getWidth()*self.s
            self.body[l][c].h = self.body[l][c].png:getHeight()*self.s
            self.body[l][c].x = self.body[l][c-1].x + self.body[l][c-1].w
            self.body[l][c].y = self.body[l][c-1].y
            table.insert(self.body, self.body[l][c])               
          end
          
          if l==3 and c==1 then
            self.body[l][c] = {}
            local png = love.graphics.newImage
            self.body[l][c].png = png("sprites/skin/"..self.skin.."/bottom_left.png")
            self.body[l][c].w = self.body[l][c].png:getWidth()*self.s
            self.body[l][c].h = self.body[l][c].png:getHeight()*self.s
            self.body[l][c].x = self.x
            self.body[l][c].y = self.body[l-1][1].y + self.body[l-1][1].h
            table.insert(self.body, self.body[l][c])                
          elseif l==3 and c==2 then
            self.body[l][c] = {}
            local png = love.graphics.newImage
            self.body[l][c].png = png("sprites/skin/"..self.skin.."/bottom_center.png")
            self.body[l][c].w = self.body[l][c].png:getWidth()*box.width_body
            self.body[l][c].h = self.body[l][c].png:getHeight()*self.s
            self.body[l][c].x = self.body[l][c-1].x + self.body[l][c-1].w
            self.body[l][c].y = self.body[l][c-1].y 
            table.insert(self.body, self.body[l][c])           
          elseif l==3 and c==3 then
            self.body[l][c] = {}
            local png = love.graphics.newImage
            self.body[l][c].png = png("sprites/skin/"..self.skin.."/bottom_right.png")
            self.body[l][c].w = self.body[l][c].png:getWidth()*self.s
            self.body[l][c].h = self.body[l][c].png:getHeight()*self.s
            self.body[l][c].x = self.body[l][c-1].x + self.body[l][c-1].w
            self.body[l][c].y = self.body[l][c-1].y 
            table.insert(self.body, self.body[l][c])
            end
          end
        end
      end
      
end
  
  function box:update(dt)

  -- Suppresion automatique de la boite en fonction de l'état du jeu

  if self.state ~= nil and self.state ~= GAME then table.remove(list_box, self.id) end

  if self.static then
    local x,y = love.mouse.getPosition()
    if x < self.x - 40 or x > self.x + self.w or y < self.y - 40 or y > self.y + self.h then
      table.remove(list_box, self.id)
      list_tiles[self.tileID].sun[self.sunID].isSelected = false
    end
  end

  if self.type == "box" then
    
    for i=#self.buttons, 1, -1 do self.buttons[i]:update() end
    for i=1, #list_box do list_box[i].id = i end
    for i=1, #self.buttons do self.buttons[i].id = self.id end
    if love.mouse.isDown(1) == false and self.lastEvents == false then self.lastEvents = true end
      


  -- déplacement de la boite

  
  local x,y = love.mouse.getPosition()

  if love.mouse.isDown(1) == false  and self.isActive then
      self.dx =  (x - self.x) 
      self.dy =  (y - self.y)
  end
  

  --if love.mouse.isDown(1) and self.lastEvents == true and GaugeIsUsed == false or GaugeIsUsed == nil then

    
      
  if  love.mouse.isDown(1) and  x >= self.x and x <= self.x + self.w and y >= self.y and y <= self.y + self.body[1][1].h  and self.isMoving == false and self.isActive then
    self.isMoving = true

  elseif  love.mouse.isDown(1) == false and self.isMoving then self.isMoving = false and self.isActive end

  
  if  love.mouse.isDown(1) and self.isMoving and self.isActive and self.static == false then
          self.x = (x - self.dx )
          self.y = (y - self.dy)
     

    local l,c
    for l=1, 3 do
      for c=1, 3 do
        if l==1 and c==1 then
          self.body[l][c].x = self.x
          self.body[l][c].y = self.y
        elseif l==1 and c==2 then
          self.body[l][c].x = self.body[l][c-1].x + self.body[l][c-1].w
          self.body[l][c].y = self.y 
        elseif l==1 and c==3 then
          self.body[l][c].x = self.body[l][c-1].x + self.body[l][c-1].w
          self.body[l][c].y = self.y       
        end
        
        if l==2 and c==1 then
          self.body[l][c].x = self.x
          self.body[l][c].y = self.y + self.body[l-1][1].h        
        elseif l==2 and c==2 then
          self.body[l][c].x = self.body[l][c-1].x + self.body[l][c-1].w
          self.body[l][c].y = self.body[l][c-1].y  
        elseif l==2 and c==3 then
          self.body[l][c].x = self.body[l][c-1].x + self.body[l][c-1].w
          self.body[l][c].y = self.body[l][c-1].y              
        end
        
        if l==3 and c==1 then
          self.body[l][c].x = self.x
          self.body[l][c].y = self.body[l-1][1].y + self.body[l-1][1].h               
        elseif l==3 and c==2 then
          self.body[l][c].x = self.body[l][c-1].x + self.body[l][c-1].w
          self.body[l][c].y = self.body[l][c-1].y           
        elseif l==3 and c==3 then
          self.body[l][c].x = self.body[l][c-1].x + self.body[l][c-1].w
          self.body[l][c].y = self.body[l][c-1].y          
          end
        end
      end
    end
  end 
     
     
     if self.isActive then
     -- Update des boutons
     self:UpdateButtons()

      -- Update des textes
      self:updatePositionText()
      
      
      -- update des gauges
      self:updateGauge()
    function boxUsedGauge()
      for i=1, #self.gauge do
        if self.gauge[i].cursorUsed then
          return true
        else return false end
      end
    end

  GaugeIsUsed = boxUsedGauge()
    end
    

end


  function box:setHeight(Ph)
    self.h = Ph
    
  end
  
  
  function box:setStateGame(Pgame)
  self.state = Pgame
  end
  
  function box:setPosition(Px, Py)
    self.x, self.y = Px, Py
  end
  
  function box:UpdatePosition(Px, Py)
  self.x, self.y = Px, Py
  end
  
  function box:setName(Pname)
    self.name = Pname
  end
  
  function box:setActive(Pbol)
    self.isActive = Pbol
  end
  
  function box:setTitle(Pword,Palign,Psize)
    
    -- création de l'en-tête (son texte, son aligment[gauche, centre, droite], sa taille)
    self.alignWord = Palign
    self.sizeTitle = Psize
    box.font = love.graphics.newFont("fonts/Pixellari.ttf",box.sizeTitle) 
    self.word = Pword
    self.wordSize = Psize
  end  

  function box:parentSun(Ptile, Psun)
    self.tileID = Ptile 
    self.sunID = Psun 
  end


  function box:isStatic(Pstatic)
    self.static = Pstatic
  end

  function box:addGauge(Plabel,Psize,Px,Py,Pcolor,Pgauge,Pmax)
    
    local gauge = {}
    -- label --
    gauge.label = Plabel
    gauge.labelSize = Psize or 20
    gauge.labelColor = Pcolor or {0,0,0,255}
    gauge.labelFont = love.graphics.newFont("fonts/Pixellari.ttf",gauge.labelSize)
    gauge.labelH = gauge.labelFont:getHeight(Plabel)
    gauge.labelW = gauge.labelFont:getWidth(Plabel)
    gauge.labelX = Px
    gauge.labelY = Py
    gauge.labelDx = Px - self.x
    gauge.labelDy = Py - self.y

    -- gauge --
    gauge.scale = Pscale or 4
    gauge.png = love.graphics.newImage("sprites/gauge/gauge_"..Pgauge..".png")
    gauge.w = gauge.png:getWidth()*gauge.scale
    gauge.h = gauge.png:getHeight()*gauge.scale
    gauge.x = Px
    gauge.y = Py + gauge.labelH + 5
    gauge.Dx = Px - self.x
    gauge.Dy = Py - self.y + gauge.labelH + 5
    gauge.liquid = Pliquid  
    
    
    gauge.cursorPng = love.graphics.newImage("sprites/gauge/cursor_"..Pgauge..".png")
    gauge.cursorW = gauge.cursorPng:getWidth()*gauge.scale
    gauge.cursorH = gauge.cursorPng:getHeight()*gauge.scale
    gauge.cursorX = gauge.x + gauge.cursorW/2 
    gauge.cursorY = gauge.y + gauge.h/2 - gauge.cursorH/2
    gauge.cursorDX = gauge.cursorX - gauge.cursorW/2 - gauge.x + gauge.cursorW/2 
    gauge.cursorUsed = false
    gauge.cursorMax = Pmax
    gauge.cursorMin = 0
    gauge.cursorMin_w = gauge.labelFont:getWidth(gauge.cursorMin)
    gauge.cursorMin_h = gauge.labelFont:getHeight(gauge.cursorMin)
    

    gauge.liquidPng = love.graphics.newImage("sprites/gauge/liquid_"..Pgauge..".png")
    gauge.liquidW = gauge.liquidPng:getWidth()*gauge.scale
    gauge.liquidH = gauge.liquidPng:getHeight()*gauge.scale
    gauge.liquidX = gauge.x + (4*gauge.scale)
    gauge.liquidY = gauge.y + (1*gauge.scale)

    
    table.insert(self.gauge, gauge)
    
  end

function box:updateGauge()
  
  local x,y
  x,y = love.mouse:getPosition()
  

  
  
  for i=1, #self.gauge do
    
    -- Update de la position des jauges
    -- label
      self.gauge[i].labelX = self.x + self.gauge[i].labelDx
      self.gauge[i].labelY = self.y + self.gauge[i].labelDy
    -- jauge
      self.gauge[i].x = self.x + self.gauge[i].Dx
      self.gauge[i].y = self.y + self.gauge[i].Dy
    -- liquid 
     self.gauge[i].liquidX = self.gauge[i].x + (4* self.gauge[i].scale)
     self.gauge[i].liquidY = self.gauge[i].y + (1*self.gauge[i].scale)
    -- curseur
    self.gauge[i].cursorX = self.gauge[i].x + self.gauge[i].cursorDX
    self.gauge[i].cursorY =  self.gauge[i].y + self.gauge[i].h/2 - self.gauge[i].cursorH/2
    
   
    -- Déplacement des curseurs
    if x>self.gauge[i].cursorX-self.gauge[i].cursorW/2 and x<self.gauge[i].cursorX+self.gauge[i].cursorW/2 and y>self.gauge[i].cursorY and y<self.gauge[i].cursorY+self.gauge[i].cursorH then
      if love.mouse.isDown(1) then
        self.gauge[i].cursorUsed = true
      end
    end
    
    if self.gauge[i].cursorUsed == true and love.mouse.isDown(1) == true then
      
    end
    
    if self.gauge[i].cursorUsed == true and love.mouse.isDown(1) == false then
      self.gauge[i].cursorUsed = false
    end
            
    if self.gauge[i].cursorUsed then

        local cran = (self.gauge[i].w-(24))/(self.gauge[i].cursorMax)

        
        if x>self.gauge[i].x and x<self.gauge[i].x+self.gauge[i].w then
          if x>self.gauge[i].cursorX + self.gauge[i].cursorW/2 + cran/2 then 
             self.gauge[i].cursorMin = self.gauge[i].cursorMin + 1
             --self.gauge[i].cursorX = self.gauge[i].cursorX+cran 
             self.gauge[i].cursorDX = self.gauge[i].cursorDX + cran
             self.gauge[i].liquidW = self.gauge[i].liquidW + (cran)
        elseif x<self.gauge[i].cursorX - self.gauge[i].cursorW/2 - cran/2 then
            self.gauge[i].cursorMin = self.gauge[i].cursorMin - 1
            --self.gauge[i].cursorX = self.gauge[i].cursorX-cran 
            self.gauge[i].cursorDX = self.gauge[i].cursorDX - cran
            self.gauge[i].liquidW = self.gauge[i].liquidW - (cran)
          end
        end
    end
  end



end

  function box:drawGauge()
    for i=1, #self.gauge do
      -- Affichage du label (nom de la jauge)
      love.graphics.setColor(self.gauge[i].labelColor)
      love.graphics.setFont(self.gauge[i].labelFont)
      love.graphics.print(self.gauge[i].label,self.gauge[i].labelX,self.gauge[i].labelY)
      love.graphics.setColor(255,255,255,255)
      -- Affichage de la jauge
      love.graphics.draw(self.gauge[i].png,self.gauge[i].x,self.gauge[i].y, 0, self.gauge[i].scale, self.gauge[i].scale)
      -- Affichage du liquide
      love.graphics.draw(self.gauge[i].liquidPng,self.gauge[i].liquidX,self.gauge[i].liquidY,0,self.gauge[i].liquidW,self.gauge[i].scale)
      -- Affichage de l'indicateur
      love.graphics.print(self.gauge[i].cursorMin, self.gauge[i].x + self.gauge[i].w/2 - self.gauge[i].cursorMin_w/2, self.gauge[i].y + self.gauge[i].h/2 - self.gauge[i].cursorMin_h/2)
      -- Affichage du curseur
      love.graphics.draw(self.gauge[i].cursorPng,self.gauge[i].cursorX,self.gauge[i].cursorY,0,self.gauge[i].scale,self.gauge[i].scale,(self.gauge[i].cursorW/2)/self.gauge[i].scale)
      
    end
  end

  function box:AnimationDraw()
    if #self.animation > 0 then
      if self.isActive then 
        love.graphics.draw(self.animation[1].sprite,self.animation[1].x,self.animation[1].y,0,self.animation[1].s,self.animation[1].s)
      end
    --
    end
  end

  function box:setAnimation(Psprite,Px,Py,Pscale)
    local animation = {}
    animation.sprite = love.graphics.newImage("sprites/"..Psprite)
    animation.s = Pscale
    animation.w = animation.sprite:getWidth()
    animation.h = animation.sprite:getHeight()
    animation.x = Px
    animation.y = Py
    table.insert(self.animation, animation)
  end
  
  function box:setText(Ptype,Pcontent,PlineUp,PlineDown,Psize,Pmode,Px,Py,Pcolor)
    
        if Pmode == nil or Pmode == "auto" then
          local H = 0
          if Ptype == "text" then
            if PlineUp then
              
            local content = {}
            content.mode = Pmode
            content.type = "text" -- texte ou image
            content.matter = " "
            content.fSize = Psize or 20
            content.font = love.graphics.newFont("fonts/Pixellari.ttf",content.fSize)
            content.color = Pcolor or {0,0,0,150} 
            content.x = self.x
            content.y = self.y
            content.w, lines = content.font:getWrap(content.matter,self.w)
            content.h = (#lines)*(content.font:getHeight())
            table.insert(self.content, content)
            H = H + content.h
            end
            
            local content = {}
            content.mode = Pmode
            content.case = Pcase
            content.type = Ptype -- texte ou image
            content.matter = Pcontent
            content.PlineUp = PlineUp
            content.PlineDown = PlineDown
            content.fSize = Psize or 20
            content.font = love.graphics.newFont("fonts/Pixellari.ttf",content.fSize)
            content.color =  Pcolor or {0,0,0,150} 
            content.x = Px or self.x
            content.y = Py or self.y 
            content.w, lines = content.font:getWrap(content.matter,self.w)
            content.h = (#lines)*(content.font:getHeight())
            table.insert(self.content, content)
            H = H + content.h
            if PlineDown == false then self.h = self.h + H end
            
            if PlineDown then           
              local content = {}
              content.mode = Pmode
              content.case = Pcase
              content.type = "text" -- texte ou image
              content.matter = " "
              content.fSize = Psize or 20
              content.font = love.graphics.newFont("fonts/Pixellari.ttf",content.fSize)
              content.color =  Pcolor or {0,0,0,150}
              content.x = Px or self.x
              content.y = Py or self.y
              content.w, lines = content.font:getWrap(content.matter,self.w)
              content.h = (#lines)*(content.font:getHeight())
              table.insert(self.content, content)
              H = H + content.h
              self.h = self.h + H
            end          
          end
  
    elseif Pmode == "manual" then
        if Ptype == "text" then
            local content = {}           
            content.mode = Pmode
            content.type = "text" -- texte ou image
            content.matter = Pcontent
            content.fSize = Psize or 20
            content.font = love.graphics.newFont("fonts/Pixellari.ttf",content.fSize)
            content.color =  Pcolor or {0,0,0,150}
            content.x = Px 
            content.y = Py
            content.dx = Px - self.x
            content.dy = Py - self.y 
            content.w, lines = content.font:getWrap(content.matter,self.w)
            content.h = (#lines)*(content.font:getHeight())
            table.insert(self.content, content)
        end
      end
  end



  
  function box:updatePositionText()

      
    for i=1, #self.content do
        if self.content[i].mode == "auto" or self.content[i].mode == nil then
          if i==1 then
            self.content[i].x = self.x + 5
            self.content[i].y = self.y + self.y_originText
          elseif i>1 then
            self.content[i].x = self.x + 5
            self.content[i].y = self.content[i-1].y + self.content[i-1].h
          end
        elseif self.content[i].mode == "manual" then
            self.content[i].x = self.x + self.content[i].dx 
            self.content[i].y = self.y + self.content[i].dy
        end
    end
    
    
    
    for i=1, #self.choice do
      -- Actualisation des textes
      if i==1 then
        self.choice[i].x = self.x + self.choice[i].margX
        self.choice[i].y = self.y + self.choice[i].margY 
      else
        self.choice[i].x = self.choice[i-1].x
        self.choice[i].y = self.choice[i-1].y + self.choice[i-1].h
      end
      
      
      -- Actualisation des cases
      if self.choice[i].lines == 1 and self.choice[i].caseS ~= 0 then
        self.choice[i].caseX = self.x + self.w - (1.5*self.choice[i].caseW)
        self.choice[i].caseY = self.choice[i].y
      elseif  self.choice[i].lines > 1 and self.choice[i].caseS ~= 0 then
        self.choice[i].caseX = self.x + self.w - (1.5*self.choice[i].caseW)
        self.choice[i].caseY = self.choice[i].y + self.choice[i].h - self.choice[i].caseH
      end
    
    local x,y = love.mouse.getPosition()
    if self.choice[i].caseS ~= 0  and x >= self.choice[i].caseX and x <= self.choice[i].caseX + self.choice[i].caseW and y >= self.choice[i].caseY and y <= self.choice[i].caseY + self.choice[i].caseH and self.choice[i].caseActive == false and love.mouse.isDown(1) then
      self.choice[i].caseActive = true
    end
  end  
 end 
  
  function box:drawText()
    
    self:drawGauge()
    
    
    for i=1, #self.content do
      love.graphics.setColor(self.content[i].color)
      love.graphics.setFont(self.content[i].font)
      love.graphics.printf(self.content[i].matter, self.content[i].x, self.content[i].y, self.w)
      love.graphics.setColor(255,255,255,255)
    end
    

    
    box:drawChoice()
    
    
  end
  
  function box:setChoice(Pchoice,PlineUp,Psize,Px,Py,Pmargin)
         
         H = 0
   
          if PlineUp then
             local choice = {}           
            choice.matter = " "
            choice.fSize = Psize or 20
            choice.font = love.graphics.newFont("fonts/Pixellari.ttf",choice.fSize)
            choice.color = {0,0,0,150}
            choice.margX = Px
            choice.margY = Py
            choice.x = self.x + Px  
            choice.y = self.y + Py 
            choice.dx = Px - self.x
            choice.dy = Py - self.y 
            choice.margin = Pmargin or self.w
            choice.w, lines = choice.font:getWrap(choice.matter,choice.margin)
            choice.h = (#lines)*(choice.font:getHeight())
            choice.lines = #lines
            
            choice.caseS = 0
            H = H + choice.h
            table.insert(self.choice, choice)              
            end
   
   
           local choice = {}           
          choice.matter = Pchoice
          choice.fSize = Psize or 20
          choice.font = love.graphics.newFont("fonts/Pixellari.ttf",choice.fSize)
          choice.color = {0,0,0,150}
          choice.margX = Px
          choice.margY = Py
          choice.x = self.x + Px  
          choice.y = self.y + Py 
          choice.dx = Px - self.x
          choice.dy = Py - self.y 
          choice.margin = (Pmargin or self.w) - choice.margX - 25
          choice.w, lines = choice.font:getWrap(choice.matter,choice.margin)
          choice.h = (#lines)*(choice.font:getHeight())
          choice.lines = #lines

          choice.caseS = 4
          choice.caseActive = false
          choice.caseImgOFF = love.graphics.newImage("sprites/skin/buttons/case_1.png")
          choice.caseImgON = love.graphics.newImage("sprites/skin/buttons/case_2.png")
          choice.caseW = choice.caseImgOFF:getWidth()*choice.caseS
          choice.caseH = choice.caseImgOFF:getHeight()*choice.caseS
     
          choice.caseX = self.x + choice.margin - (choice.caseW*1.5)
          if #lines>1 then
          choice.caseY = choice.y + choice.h - choice.caseH
          else choice.caseY = choice.y end
          H = H + choice.h
          table.insert(self.choice, choice)  


end
   
  function box:drawChoice()

    -- appelé dans drawText
    for i=1, #self.choice do
      love.graphics.setColor(0,0,0,150)
      love.graphics.printf(self.choice[i].matter, self.choice[i].x, self.choice[i].y, self.choice[i].margin)
      love.graphics.setColor(255,255,255,255)
      if self.choice[i].caseS > 0 and self.choice[i].caseActive == false then
      love.graphics.draw(self.choice[i].caseImgOFF, self.choice[i].caseX,self.choice[i].caseY, 0, self.choice[i].caseS, self.choice[i].caseS)
    elseif self.choice[i].caseS > 0 and self.choice[i].caseActive then
      love.graphics.draw(self.choice[i].caseImgON, self.choice[i].caseX,self.choice[i].caseY, 0, self.choice[i].caseS, self.choice[i].caseS)
      end

    end
  end
  
  function box:addButton(Pbutton)
    table.insert(self.buttons, Pbutton)
  end


  function box:buttonParentSun(Pbutton,Ptile,Psun)
    self.buttons[Pbutton].tileID = Ptile
    self.buttons[Pbutton].sunID = Psun
  end

  function box:setButtonScale(Pbutton,Pscale)
  self.buttons[Pbutton].s = Pscale
  self.buttons[Pbutton].w = self.buttons[Pbutton].type:getWidth()*Pscale
  self.buttons[Pbutton].h = self.buttons[Pbutton].type:getHeight()*Pscale
  end

  function box:buttonSetActive(Pbutton, Pactive, Psprite)
    self.buttons[Pbutton].isActive = Pactive
    self.buttons[Pbutton].sprite = Psprite
  end
  
  function box:setColorTextButton(Pbutton,Pcolor)
    self.buttons[Pbutton].textColor = Pcolor
  end
  
  
 
  
  function box:setButton(Pbutton, Palign, Ptext, Psize, Px, Py, Pdelete)
    self.buttons[Pbutton].delete = Pdelete 
    self.buttons[Pbutton].mat = Pbutton 
    -- Pbutton = numéro du bouton
    -- Palign = position du bouton automatique
    -- Ptext = texte du bouton
    -- constante de debord gauche/droite
    local x = self.w/14
    local y = self.w/14
    

      if Palign == "left" then
        self.buttons[Pbutton].align = "left"
        self.buttons[Pbutton].x = Px or self.x + x
        self.buttons[Pbutton].y = Py or self.y + self.h - self.buttons[Pbutton].h - y
      elseif Palign == "right" then
        self.buttons[Pbutton].align = "right"
        self.buttons[Pbutton].x = Px or self.x + self.w - self.buttons[Pbutton].w - x
        self.buttons[Pbutton].y = Py or self.y + self.h - self.buttons[Pbutton].h - y    
      elseif Palign == "center" then
        self.buttons[Pbutton].align = "center"
        self.buttons[Pbutton].x = Px or self.x + self.w/2 - self.buttons[Pbutton].w/2 
        self.buttons[Pbutton].y = Py or self.y + self.h/2 

      elseif Palign == "manual" then
        self.buttons[Pbutton].align = "manual"
        self.buttons[Pbutton].dx = Px - self.x
        self.buttons[Pbutton].dy = Py - self.y        
        self.buttons[Pbutton].x =  self.x + self.buttons[Pbutton].dx
        self.buttons[Pbutton].y =  self.y + self.buttons[Pbutton].dy
      end
    
      self.buttons[Pbutton].word = Ptext
      self.buttons[Pbutton].wordSize = Psize
  end


function box:setButtonHoverPng(Pbutton, Psprite)
--self.buttons[Pbutton].typeHover = love.graphics.newImage("sprites/skin/buttons/"..Psprite..".png")  
end

function box:UpdateButtons()
  
 -- constante de debord gauche/droite
      local x = self.w/14
      local y = self.w/14
      for i=1, #self.buttons do
         self.buttons[i].w = self.buttons[i].type:getWidth()*self.buttons[i].s 
         self.buttons[i].h = self.buttons[i].type:getHeight()*self.buttons[i].s
        if self.buttons[i].align == "left" then
          self.buttons[i].x = self.x + x
          self.buttons[i].y = self.y + self.h - self.buttons[i].h - y
        elseif self.buttons[i].align == "right" then
          self.buttons[i].x = self.x + self.w - self.buttons[i].w - x
          self.buttons[i].y = self.y + self.h - self.buttons[i].h - y    
        elseif self.buttons[i].align == "manual" then
          self.buttons[i].x = self.x + self.buttons[i].dx
          self.buttons[i].y = self.y + self.buttons[i].dy
        end
      end

end
  
  function box:draw()
    
    if self.type == "box" then
       -- affichage des éléments de la fenetre
       local l,c
       for l=1, 3 do
         for c=1, 3 do
            if l==1 and c == 1 then
              love.graphics.draw(self.body[l][c].png, self.body[l][c].x, self.body[l][c].y, 0, self.s, self.s)
            elseif l==1 and c == 2 then
              love.graphics.draw(self.body[l][c].png, self.body[l][c].x, self.body[l][c].y, 0, self.body[l][c].w, self.s)          
            elseif l==1 and c == 3 then
              love.graphics.draw(self.body[l][c].png, self.body[l][c].x, self.body[l][c].y, 0, self.s, self.s)          
            end
            
            if l==2 and c==1 then
              love.graphics.draw(self.body[l][c].png, self.body[l][c].x, self.body[l][c].y, 0, self.s, box.height_body)          
            elseif l==2 and c==2 then
              love.graphics.draw(self.body[l][c].png, self.body[l][c].x, self.body[l][c].y, 0, self.body[l][c].w, box.height_body)           
            elseif l==2 and c==3 then
              love.graphics.draw(self.body[l][c].png, self.body[l][c].x, self.body[l][c].y, 0, self.s, box.height_body)           
            end
            
            if l==3 and c==1 then
              love.graphics.draw(self.body[l][c].png, self.body[l][c].x, self.body[l][c].y, 0, self.s, self.s) 
            elseif l==3 and c==2 then
              love.graphics.draw(self.body[l][c].png, self.body[l][c].x, self.body[l][c].y, 0, box.width_body, self.s) 
            elseif l==3 and c==3 then
              love.graphics.draw(self.body[l][c].png, self.body[l][c].x, self.body[l][c].y, 0, self.s, self.s)           
            end
         end
      end
   end   
   


     
      -- affichage de l'en-tête de la boite
      if self.type == "box" then  
        if self.word ~= nil then
          love.graphics.setFont(self.font)
          local x,y
          local w = self.font:getWidth(self.word)
          local h = self.font:getHeight(self.word)
          if self.alignWord == "left" then
            x = self.body[1][1].x + self.w/10
            y = self.body[1][1].y + self.body[1][1].h/2 - h/2
          elseif self.alignWord == "center" then
            x = self.body[1][1].x + self.w/2 - w/2
            y = self.body[1][1].y + self.body[1][1].h/2 - h/2
          elseif self.alignWord == "right" then
            x = self.body[1][1].x + self.w - w - self.w/10
            y = self.body[1][1].y + self.body[1][1].h/2 - h/2
          end
          love.graphics.print(self.word, x, y)
        end
      end
        

      -- Affichage des boutons
      if self.buttons ~= 0 then
        local draw = love.graphics.draw
        local button = self.buttons
          for i=1, #self.buttons do 
            if button[i].hover == false then
            draw(button[i].type, button[i].x, button[i].y, 0, button[i].s, button[i].s) 
            end
            if button[i].hover then
            draw(button[i].type, button[i].x, button[i].y, 0, button[i].s, button[i].s) 
            --draw(button[i].typeHover, button[i].x, button[i].y, 0, button[i].s, button[i].s)             
            end
            local font = love.graphics.newFont("fonts/Pixellari.ttf", self.buttons[i].wordSize)
            love.graphics.setFont(font)
            local wordW = font:getWidth(self.buttons[i].word)
            local wordH = font:getHeight(self.buttons[i].word)
            local wordX = self.buttons[i].x + self.buttons[i].w/2 - wordW/2
            local wordY = self.buttons[i].y + self.buttons[i].h/2 - wordH/2
            love.graphics.setColor(self.buttons[i].textColor)
            love.graphics.print(self.buttons[i].word, wordX, wordY)
            love.graphics.setColor(255,255,255,255)
          end
      end
      
      
      -- Affichage du contenu
      self:drawText()
      -- Affichage animation
      self:AnimationDraw()
    end
  return box
end




function boxWindow.addButton(Pbutton,Phover)
  local button = {}
  button.mode = nil
  button.used = false
  -- pour les boites déplacements
  button.tileID = nil 
  button.sunID = nil
  --
  button.mat = 0
  button.id = 0
  button.x = 0
  button.y = 0
  button.dx = 0
  button.dy = 0
  button.align = nil
  button.s = Pscale or 3
  button.word = 0
  button.wordSize = 20
  button.sprite = Pbutton
  button.textColor = {255,255,255,255}
  button.type = love.graphics.newImage("sprites/skin/buttons/"..button.sprite..".png")
  --button.typeHover = love.graphics.newImage("sprites/skin/buttons/"..button.sprite..".png")
  button.w = button.type:getWidth()*button.s
  button.h = button.type:getHeight()*button.s
  button.hover = false
  button.pressed = false
  button.oldButtonState = false
  button.isActive = false
  button.lastEvents = {}
  button.idBox = 0
  button.delete = nil
  function button:setEvent(Pevent, Pfunction)
    self.lastEvents[Pevent] = Pfunction
  end
 
  function button:update()
 button.type = love.graphics.newImage("sprites/skin/buttons/"..button.sprite..".png")
 
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
            self.lastEvents["hover"]()
          end
         end
      end

      if self.hover and self.pressed == false and self.oldButtonState == false and love.mouse.isDown(1) and self.used == false then 
        if self.lastEvents["pressed"] ~= nil then
            self.used = true
            self.pressed = true 
            self.lastEvents["pressed"](self)
            if self.tileID ~= nil then list_tiles[self.tileID].sun[self.sunID].isSelected = false end
            if self.delete then  table.remove(list_box, self.id) end
            
        end
      end

      if self.pressed and love.mouse.isDown(1) == false then
          self.pressed = false 
          self.used = false
      end
      
 

  end 
  return button
end

return boxWindow