
gui = {}
local skillTree = require("skills/skillTree")

local function test(ptest)
print(ptest)
end

    function gui.load()
      
  toolbar[1] = gui_galaxy.toolbar(0,0, "horizontal")
  toolbar[1]:setBorderRadius(5)

  icon[1] = gui_galaxy.icon("calcul",scale_button)
  icon[1]:setEvent("pressed", ButtonZoom)
  icon[1]:setIcon("zoom-")
  icon[1]:setHover("zoom-_hover")  
  
--ButtonZoom

  toolbar[1]:addIcon(icon[1])
  toolbar[1]:setPosition(width/2 + ((width/4)-(toolbar[1].w/2)), height - toolbar[1].h)
  toolbar[1]:setAlignment()
  

  toolbar[2] = gui_galaxy.toolbar(0,0, "vertical")
  toolbar[2]:setBorderRadius(5)

  icon[2] = gui_galaxy.icon("galaxy",scale_button)
  icon[2]:setHover("galaxy_hover")
  icon[2]:setEvent("pressed", ButtonGalaxy)
  icon[3] = gui_galaxy.icon("system",scale_button)
  icon[3]:setHover("system_hover")
  icon[3]:setEvent("pressed", ButtonSystem)
  icon[4] = gui_galaxy.icon("cockpit",scale_button)
  icon[4]:setHover("cockpit_hover")
  icon[4]:setEvent("pressed", ButtonCockpit)
  
  toolbar[2]:addIcon(icon[2])
  toolbar[2]:addIcon(icon[3])
  toolbar[2]:addIcon(icon[4])
  
  toolbar[2]:setPosition(width - toolbar[2].w , height/2 - height/4 - toolbar[2].h/2)
  toolbar[2]:setAlignment() 


  toolbar[3] = gui_galaxy.toolbar(0,0, "vertical")
  toolbar[3]:setBorderRadius(5)


  icon[5] = gui_galaxy.icon("empty",scale_button)
  icon[5]:setHover("empty")
  icon[5]:setEvent("pressed", modelBox.exploration)
  

  



  --icon[11] = gui_galaxy.icon("empty",scale_button)
  --icon[12] = gui_galaxy.icon("empty",scale_button)
  
  toolbar[3]:addIcon(icon[5])


  
  toolbar[3]:setPosition(width - toolbar[2].w , toolbar[2].y+toolbar[2].h)
  toolbar[3]:setAlignment() 
      
      
    end


    function Title(Ptitle, Pfont, Px, Py, Pcolor, Pcenter)
      love.graphics.setFont(Pfont)
      local txt = Ptitle
      local txt_w = Pfont:getWidth(txt)
      local txt_h = Pfont:getHeight(txt)
      local x,y
      if Pcenter == true then
       x = Px - (txt_w/2)
       y = Py + (txt_h/2)
      elseif Pcenter == false then
       x = Px 
       y = Py        
      end

      love.graphics.setColor(Pcolor)
      love.graphics.print(txt, x, y)
    end 
    
    
    
return gui