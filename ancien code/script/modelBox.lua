boxWindow = require ("script/boxWindow")
local skillTree = require("skills/skillTree")
modelBox = {}


function ActiveBoxExploration()
  for i=1,#list_box do
    if list_box[i].name == "box_exploration" then
      list_box[i].isActive = true
    end
  end
end

function ActiveBoxLaboratory()
  for i=1,#list_box do
    if list_box[i].name == "box_laboratory" then
      list_box[i].isActive = true
    end
  end
end





function modelBox.main()
 -- création d'une nouvelle boite (x,y,width,height)
 local box = boxWindow.addBox("box",0,0,210,210,"main") 
 local id = #list_box+1
 table.insert(list_box, box)
 list_box[id].id = id 
list_box[id]:setTitle("", "center", 25)
list_box[id]:setActive(true)
    -- création de l'en-tête de la boite (libellé, position, taille de police)

  list_box[id]:setPosition(10, height-list_box[id].h - 10)
  list_box[id]:build()
  
    -- ajout de bouton 1 (skin.png)
  local button = boxWindow.addButton("button_4",4)
  list_box[id]:addButton(button)
  list_box[id]:setButton(1,"center", "Exploration", 25, list_box[id].x + list_box[id].w/2 - (list_box[id].buttons[1].w/2),list_box[id].y + 25)
     -- ajout de bouton 1 (skin.png)
     
  local button = boxWindow.addButton("button_4",4)
  list_box[id]:addButton(button)
  list_box[id]:setButton(2,"center", "Quitter", 25, list_box[id].x + list_box[id].w/2 - (list_box[id].buttons[1].w/2),list_box[id].y + list_box[id].buttons[1].h+45) 
  
end




function modelBox.laboratory()
 -- création d'une nouvelle boite (x,y,width,height)
 local box = boxWindow.addBox("box",width/2-(350/2),height/2-(300/2),350,500,"mail") 
 local id = #list_box+1
 table.insert(list_box, box)
 list_box[id].id = id 
 list_box[id].isActive = true
    -- création de l'en-tête de la boite (libellé, position, taille de police)
  list_box[id]:setTitle("LABORATORY", "center", 20)
  list_box[id]:setName("box_laboratory")
  list_box[id]:setText("text", "You can consult the reports here.",true,false,22)
  
 local Margin_text = 90
  
  local button = boxWindow.addButton("analyse_1")
  list_box[id]:addButton(button)
  list_box[id]:setButtonScale(1,4)
  local Margin_x = (list_box[id].w - list_box[id].buttons[1].w)/2
  list_box[id]:setButton(1,"manual", "", 20, list_box[id].x+Margin_x, list_box[id].y+120,false) 
  list_box[id]:setText("text","rover analysis report",false,false,22,"manual",list_box[id].buttons[1].x+ Margin_text, list_box[id].buttons[1].y + list_box[id].buttons[1].h/2)
  
  local Margin_y = 5

  
  local button = boxWindow.addButton("analyse_1")
  list_box[id]:addButton(button)
  list_box[id]:setButtonScale(2,4)
  list_box[id]:setButton(2,"manual", "", 20, list_box[id].buttons[1].x, list_box[id].buttons[1].y + list_box[id].buttons[1].h + (Margin_y),false) 
  list_box[id]:setText("text","probe analysis report",false,false,22,"manual",list_box[id].buttons[2].x+ Margin_text, list_box[id].buttons[2].y + list_box[id].buttons[2].h/2)
  

  
  local button = boxWindow.addButton("analyse_1")
  list_box[id]:addButton(button)
  list_box[id]:setButtonScale(3,4)
  list_box[id]:setButton(3,"manual", "", 20, list_box[id].buttons[2].x, list_box[id].buttons[2].y + list_box[id].buttons[2].h + (Margin_y),false) 
  list_box[id]:setText("text","earthly analysis report",false,false,22,"manual",list_box[id].buttons[3].x+ Margin_text, list_box[id].buttons[3].y + list_box[id].buttons[3].h/2)


  local button = boxWindow.addButton("analyse_1")
  list_box[id]:addButton(button)
  list_box[id]:setButtonScale(4,4)
  list_box[id]:setButton(4,"manual", "", 20, list_box[id].buttons[3].x, list_box[id].buttons[3].y + list_box[id].buttons[3].h + (Margin_y),false) 
  list_box[id]:setText("text","drone analysis report",false,false,22,"manual",list_box[id].buttons[4].x+ Margin_text, list_box[id].buttons[4].y + list_box[id].buttons[4].h/2)

  local button = boxWindow.addButton("button_6") -- skin bouton
  list_box[id]:addButton(button)
  list_box[id]:setButton(5,"right", "annuler", 20,nil,nil,true)
  local function Empty() end
  list_box[#list_box].buttons[5]:setEvent("pressed", Empty)
  
  list_box[id]:setPosition(width/2-list_box[id].w/2,height/2-list_box[id].h/2)
  list_box[id]:build()


end





function modelBox.exploration_Terrestre()



----------------- création de la boite PARAMETRE JAUGE -----------------
local x_jauge,y_jauge, margY 
 for i=1, #list_box do
   if list_box[i].word == "PREPARATION/EXPLORATION" then
     x_jauge = list_box[i].x
     y_jauge = list_box[i].y
     margY = list_box[i].buttons[1].y
   end
  end
 local box = boxWindow.addBox("box",width/6,height/2,220,420,"mail") 
 local id = #list_box+1
 table.insert(list_box, box)
 list_box[id].id = id 
 list_box[id]:setActive(false)
    -- création de l'en-tête de la boite (libellé, position, taille de police)
  list_box[id]:setTitle("Paramètres", "center", 23)
  list_box[id]:setName("parameter_terrestre")


  list_box[id]:updatePositionText() -- update position texte
  list_box[id]:setPosition(x_jauge+30,y_jauge+140)
  list_box[id]:build()
  
  local margX = list_box[id].x + 20
  list_box[id]:addGauge("Oxygène :",20,margX, list_box[id].y+list_box[id].body[1][1].h+5,{0,0,0,160}, 1,22)
  
  list_box[id]:addGauge("Durée de la mission :",20,margX, list_box[id].gauge[1].y + list_box[id].gauge[1].h + 5,{0,0,0,160}, 2,48)  

  list_box[id]:addGauge("Equipage :",20,margX, list_box[id].gauge[2].y + list_box[id].gauge[2].h + 5,{0,0,0,160}, 1,8)   
  
  list_box[id]:setText("text","Choisir combinaison",false,false,20,"manual",margX, list_box[id].gauge[3].y + list_box[id].gauge[3].h + 5)
  
  
----------------- création de la boite ANALYSE   -----------------
local x_analyse,y_analyse 
 for i=1, #list_box do
   if list_box[i].name == "parameter_terrestre" then
     x_analyse = list_box[i].x + list_box[i].w +10
     y_analyse = list_box[i].y
   end
  end
  
 -- création d'une nouvelle boite (x,y,width,height)
 local box = boxWindow.addBox("box",width/6,height/2,330,420,"mail") 
 local id = #list_box+1
 table.insert(list_box, box)
 list_box[id].id = id 
 list_box[id].isActive = false
    -- création de l'en-tête de la boite (libellé, position, taille de police)
  list_box[id]:setTitle("Choix des analyses", "center", 23)
  list_box[id]:setName("terrestre_analyse")

  list_box[id]:setPosition(x_analyse,y_analyse)
  list_box[id]:build()
  
  list_box[id]:setChoice("Analyse granulométrique des sols", true, 20,15, list_box[id].body[1][1].h)
  list_box[id]:setChoice("Prélèvements de particules fines", true, 20,15, list_box[id].body[1][1].h)
  list_box[id]:setChoice("Prélèvements de bloc de glace ancienne", true, 20,15, list_box[id].body[1][1].h)
  list_box[id]:setChoice("Analyse granulométrique des sols", true, 20,15, list_box[id].body[1][1].h)
  list_box[id]:setChoice("Prélèvements de particules fines", true, 20,15, list_box[id].body[1][1].h)
  list_box[id]:setChoice("Prélèvements de bloc de glace ancienne", true, 20,15, list_box[id].body[1][1].h)  
  
----------------- création de la boite price ----------------
local x_price,y_p, margY 
 for i=1, #list_box do
   if list_box[i].name == "parameter_terrestre" then
     x_price = list_box[i].x
     y_price = list_box[i].y + list_box[i].h
   end
  end
 local box = boxWindow.addBox("box",width/6,height/2,400,150,"standard") 
 local id = #list_box+1
 table.insert(list_box, box)
 list_box[id].id = id 
 list_box[id]:setActive(false)
    -- création de l'en-tête de la boite (libellé, position, taille de police)
  list_box[id]:setTitle("Coût de l'exploration", "center", 23)
  list_box[id]:setName("parameter_price")
  
  list_box[id]:updatePositionText() -- update position texte
  list_box[id]:setPosition(x_price,y_price+8)
  list_box[id]:build()
  
  local margXtext = 10
  list_box[id]:setText("text","Coût des analyses : 20k",false,false,22,"manual",list_box[id].x + margXtext, list_box[id].y + list_box[id].body[1][1].h + margXtext)  
  list_box[id]:setText("text","Coût d'extraction : 45k",false,false,22,"manual",list_box[id].x + margXtext, list_box[id].content[1].y + list_box[id].content[1].h)    
   list_box[id]:setText("text","Coût humanitaire : 45k",false,false,22,"manual",list_box[id].x + margXtext, list_box[id].content[2].y + list_box[id].content[2].h)  
   
  local button = boxWindow.addButton("button_3") -- skin bouton
  list_box[id]:addButton(button)
  list_box[id]:setButton(1,"manual", "Acheter", 20, list_box[id].x + list_box[id].w - list_box[id].buttons[1].w - 20, list_box[id].y + list_box[id].h - list_box[id].buttons[1].h - 20,false) 
  local function Empty() end
  list_box[id].buttons[1]:setEvent("pressed", Empty)
  
----------------- création de la boite RESOURCE   -----------------
local x_resource,y_resource 
 for i=1, #list_box do
   if list_box[i].name == "terrestre_analyse" then
     x_resource = list_box[i].x + list_box[i].w +10
     y_resource = list_box[i].y
   end
  end
  
 -- création d'une nouvelle boite (x,y,width,height)
 local box = boxWindow.addBox("box",width/6,height/2,330,420,"mail") 
 local id = #list_box+1
 table.insert(list_box, box)
 list_box[id].id = id 
 list_box[id].isActive = false
    -- création de l'en-tête de la boite (libellé, position, taille de police)
  list_box[id]:setTitle("Choix des ressources", "center", 23)
  list_box[id]:setName("terrestre_resource")

  list_box[id]:setPosition(x_resource,y_resource)
  list_box[id]:build()
  
  list_box[id]:setChoice("Scandium", true, 20,15, list_box[id].body[1][1].h)
  list_box[id]:setChoice("Titane", true, 20,15, list_box[id].body[1][1].h)
  list_box[id]:setChoice("Vanadium", true, 20,15, list_box[id].body[1][1].h)
  list_box[id]:setChoice("Jode", true, 20,15, list_box[id].body[1][1].h)
  list_box[id]:setChoice("Carbone", true, 20,15, list_box[id].body[1][1].h)
  list_box[id]:setChoice("Oxygène", true, 20,15, list_box[id].body[1][1].h)  
  list_box[id]:setChoice("Europium", true, 20,15, list_box[id].body[1][1].h)
  list_box[id]:setChoice("Zirconium", true, 20,15, list_box[id].body[1][1].h)      
end


function modelBox.exploration_Probe(Pid)
-------------- BOITE PARAMETRE PROBE ----------------


local x_jauge = list_box[Pid].x 
local y_jauge = list_box[Pid].y 
local margY = list_box[Pid].buttons[1].y

local box = boxWindow.addBox("box",width/6,height/2,300,150,"mecanical") 
 local id = #list_box[Pid].parent +1
 table.insert(list_box[Pid].parent, box) 
 list_box[Pid].parent[id].id = id
 list_box[Pid].parent[id]:setActive(false)
    -- création de l'en-tête de la boite (libellé, position, taille de police)
  list_box[Pid].parent[id]:setTitle("Constructeur", "center", 23)
  list_box[Pid].parent[id]:setName("parameter probe")
  list_box[Pid].parent[id]:updatePositionText() -- update position texte
  list_box[Pid].parent[id]:setPosition(x_jauge+30,y_jauge+140)
  list_box[Pid].parent[id]:setAnimation("tech/arpex/arpex_logo.png",x_jauge+50,y_jauge+150+list_box[Pid].body[1][1].h+15,4)
  list_box[Pid].parent[id]:build()
  
  local margX = list_box[Pid].parent[id].x + 20

end

function modelBox.exploration_model(Pid)
-------------- BOITE PARAMETRE PROBE ----------------
local x_jauge = list_box[Pid].x 
local y_jauge = list_box[Pid].y 
local margY = list_box[Pid].buttons[1].y

local box = boxWindow.addBox("box",width/6,height/2,300,300,"mecanical") 
 local id = #list_box[Pid].parent +1
 table.insert(list_box[Pid].parent, box) 
 list_box[Pid].parent[id].id = id
 list_box[Pid].parent[id]:setActive(false)
    -- création de l'en-tête de la boite (libellé, position, taille de police)
  list_box[Pid].parent[id]:setTitle("Model spatial", "center", 23)
  list_box[Pid].parent[id]:setName("parameter probe")


  list_box[Pid].parent[id]:updatePositionText() -- update position texte
  list_box[Pid].parent[id]:setPosition(x_jauge+30,y_jauge+150+150)
  list_box[Pid].parent[id]:setAnimation("tech/arpex/modelB1.png",x_jauge+60,y_jauge+150+150+list_box[Pid].body[1][1].h,2)
  list_box[Pid].parent[id]:build()
  
  local margX = list_box[Pid].parent[id].x + 20

end

function modelBox.exploration_feature(Pid)
-------------- BOITE PARAMETRE PROBE ----------------
local x_jauge = list_box[Pid].x 
local y_jauge = list_box[Pid].y 
local margY = list_box[Pid].buttons[1].y

local box = boxWindow.addBox("box",width/6,height/2,400,80,"mecanical") 
 local id = #list_box[Pid].parent +1
 table.insert(list_box[Pid].parent, box) 
 list_box[Pid].parent[id].id = id
 list_box[Pid].parent[id]:setActive(false)
    -- création de l'en-tête de la boite (libellé, position, taille de police)
  list_box[Pid].parent[id]:setTitle("Caractéristiques", "center", 23)
  list_box[Pid].parent[id]:setName("parameter probe")
local color = {255,255,255,190} print(color)
  list_box[Pid].parent[id]:setText("text", " Manufacture : ARPEX COMPANY",true,false,22,nil,nil,nil,color)
  list_box[Pid].parent[id]:setText("text", " Modèle : Orbital Tech B2",true,false,22,nil,nil,nil,color)
  list_box[Pid].parent[id]:setText("text", " Durée d'utilisation : ~ 36 ans",true,false,22,nil,nil,nil,color)
  list_box[Pid].parent[id]:setText("text", " Poid : 150 254 kg",true,false,22,nil,nil,nil,color)
  list_box[Pid].parent[id]:setText("text", " Price : 1.6M",true,false,22,nil,nil,nil,color)
  list_box[Pid].parent[id]:updatePositionText() -- update position texte
  list_box[Pid].parent[id]:setPosition(x_jauge+30+320,y_jauge+140)
  list_box[Pid].parent[id]:build()
  


end



function modelBox.exploration()
      local function CreateBox()
       local box = boxWindow.addBox("box",width/2,height/2,950,100,"futuriste")  
       local id = #list_box+1
       table.insert(list_box, box)
       list_box[id].id = id  
       list_box[id]:setActive(true)

        -- création de l'en-tête de la boite (libellé, position, taille de police)
        list_box[id]:setTitle("PREPARATION/EXPLORATION", "center", 25)
        list_box[id]:setName("PREPARATION/EXPLORATION")
        list_box[id]:setStateGame("planet")
        list_box[id]:setPosition(width/2-list_box[id].w/2,30)
        list_box[id]:build()


    local function setActive(selfButtons)

      -- Si le bouton est actif, je le désactive
       if selfButtons.isActive then
          for i=1,#list_box[id].buttons do
              list_box[id].buttons[i].isActive = false
              list_box[id]:buttonSetActive(i,false,"button_8") 
          end 
      -- Si le bouton n'est pas actif, je l'active
     elseif selfButtons.isActive == false then
       list_box[id]:buttonSetActive(selfButtons.mat,true,"button_3") 
         for i=1,#list_box[id].buttons do
            if i~=selfButtons.mat then
              list_box[id].buttons[i].isActive = false
              list_box[id]:buttonSetActive(i,false,"button_8") 
            end
         end 
       end
        
        
        
        if selfButtons.mat == 1 then 
          if selfButtons.isActive then

            -- Désactivation des autres
            for i=1,#list_box do
             for j=1,#list_box[i].parent do
               -- Affichage des boites parameter_Terrestre
               if list_box[i].parent[j].name == "parameter terrestre" then list_box[i].parent[j].isActive = true end
               if list_box[i].parent[j].name == "parameter probe" or list_box[i].parent[j].name == "parameter rover" or list_box[i].parent[j].name == "parameter drone" then
                  list_box[i].parent[j].isActive = false
               end
             end
           end            
          elseif selfButtons.isActive == false then
            for i=1,#list_box do
             for j=1,#list_box[i].parent do
               if list_box[i].parent[j].name == "parameter probe" then
                  list_box[i].parent[j].isActive = false
               end
             end
           end
           
          end
        end        
        
        
        
        
        if selfButtons.mat == 2 then 
          if selfButtons.isActive then
            for i=1,#list_box do
             for j=1,#list_box[i].parent do
               -- Affichage des boites parameter_Probe
               if list_box[i].parent[j].name == "parameter probe" then list_box[i].parent[j].isActive = true end
               -- Désactivation des autres
               if list_box[i].parent[j].name == "parameter terrestre" or list_box[i].parent[j].name == "parameter rover" or list_box[i].parent[j].name == "parameter drone" then
list_box[i].parent[j].isActive = false
               end
             end
           end            
          elseif selfButtons.isActive == false then
            for i=1,#list_box do
             for j=1,#list_box[i].parent do
               if list_box[i].parent[j].name == "parameter probe" then
                  list_box[i].parent[j].isActive = false
               end
             end
           end
           
          end
        end   
        
        if selfButtons.mat == 3 then 
          if selfButtons.isActive then
            for i=1,#list_box do
             for j=1,#list_box[i].parent do
               -- Affichage des boites parameter_rover
               if list_box[i].parent[j].name == "parameter rover" then list_box[i].parent[j].isActive = true end
               -- Désactivation des autres
               if list_box[i].parent[j].name == "parameter terrestre" or list_box[i].parent[j].name == "parameter probe" or list_box[i].parent[j].name == "parameter drone" then
list_box[i].parent[j].isActive = false
               end
             end
           end            
          elseif selfButtons.isActive == false then
            for i=1,#list_box do
             for j=1,#list_box[i].parent do
               if list_box[i].parent[j].name == "parameter rover" then
                  list_box[i].parent[j].isActive = false
               end
             end
           end
           
          end
        end           
 
        if selfButtons.mat == 4 then 
          if selfButtons.isActive then
            for i=1,#list_box do
             for j=1,#list_box[i].parent do
               -- Affichage des boites parameter_drone
               if list_box[i].parent[j].name == "parameter drone" then list_box[i].parent[j].isActive = true end
               -- Désactivation des autres
               if list_box[i].parent[j].name == "parameter terrestre" or list_box[i].parent[j].name == "parameter probe" or list_box[i].parent[j].name == "parameter rover" then
list_box[i].parent[j].isActive = false
               end
             end
           end            
          elseif selfButtons.isActive == false then
            for i=1,#list_box do
             for j=1,#list_box[i].parent do
               if list_box[i].parent[j].name == "parameter drone" then
                  list_box[i].parent[j].isActive = false
               end
             end
           end
           
          end
        end   
    end        

  
        -- Boutons pour selection methode
        local buttons_spacing = 80
        
        local button = boxWindow.addButton("button_8")
        list_box[id]:addButton(button)
        list_box[id]:setButtonScale(1,4)
        list_box[id]:buttonSetActive(1,false,"button_8") 
        list_box[id]:setButton(1,"manual", "Terrestre", 25, list_box[id].x+120, list_box[id].y+list_box[id].body[1][1].h+20,false) 
        list_box[id].buttons[1]:setEvent("pressed", setActive)

        local button = boxWindow.addButton("button_8")
        list_box[id]:addButton(button)
        list_box[id]:setButtonScale(2,4)
        list_box[id]:buttonSetActive(2,false,"button_8") 
        list_box[id]:setButton(2,"manual", "Sonde", 25, list_box[id].buttons[1].x + list_box[id].buttons[1].w +buttons_spacing, list_box[id].y+list_box[id].body[1][1].h+20,false) 
        list_box[id].buttons[2]:setEvent("pressed", setActive)

        
        local button = boxWindow.addButton("button_8")
        list_box[id]:addButton(button)
        list_box[id]:setButtonScale(3,4)
        list_box[id]:buttonSetActive(3,false,"button_8") 
        list_box[id]:setButton(3,"manual", "Rover", 25, list_box[id].buttons[2].x + list_box[id].buttons[2].w +buttons_spacing, list_box[id].y+list_box[id].body[1][1].h+20,false) 
        list_box[id].buttons[3]:setEvent("pressed", setActive)
 
        local button = boxWindow.addButton("button_8")
        list_box[id]:addButton(button)
        list_box[id]:setButtonScale(4,4)
        list_box[id]:buttonSetActive(4,false,"button_8") 
        list_box[id]:setButton(4,"manual", "Drône", 25, list_box[id].buttons[3].x + list_box[id].buttons[3].w +buttons_spacing, list_box[id].y+list_box[id].body[1][1].h+20,false) 
        list_box[id].buttons[4]:setEvent("pressed", setActive)

        --- creation de la boite fils probe
        modelBox.exploration_Probe(id)
        modelBox.exploration_model(id)
        modelBox.exploration_feature(id)
      end
    if #list_box==0 then
        CreateBox()
      else
      for i=1,#list_box do
        if list_box[i].name == "PREPARATION/EXPLORATION" then
           table.remove(list_box, list_box[i].id)
          break
        end
        if i==#list_box then
          CreateBox()
       end 
      end
    end
  end



function boxWindow.HelloWorld()
 -- création d'une nouvelle boite (x,y,width,height)
 local box = boxWindow.addBox("box",0,0,400,135,"mail") 
 local id = #list_box+1
 table.insert(list_box, box)
 list_box[id].id = id 
 
  -- création de l'en-tête de la boite (libellé, position, taille de police)
  list_box[id]:setTitle("ADVENTURE SANDBOX","center",25)



  list_box[id]:setText("text","Bienvenue sur la version [EXPLORER EDITION].",true,true)
  list_box[id]:setText("text", "Cette version d'évaluation ne représente pas le contenu du jeu définitif.",false, true)
  list_box[id]:setText("text", "Vous pouvez participer au développement en nous faisant parvenir les bugs rencontrés lors de votre exploration.",false,true)
  list_box[id]:setText("text", "L'équipe de Adventure Sandbox.",false,true)
  list_box[id]:setPosition(width/2-list_box[id].w/2,height/2-list_box[id].h/2)
  list_box[id]:updatePositionText() -- update position texte
  list_box[id]:build() -- construction boite
  

  -- ajout de bouton 1 (skin.png)
  local button = boxWindow.addButton("button_3") -- skin bouton
  list_box[id]:addButton(button)
  -- paramètre du bouton (numéro, position, libellé, taille de police)
  list_box[id]:setButton(1,"auto","right", "OK", 25)

  local function Empty() end
  -- fonction de boutons
  list_box[#list_box].buttons[1]:setEvent("pressed", Empty)

end

function boxWindow.loading()
 -- création d'une nouvelle boite (x,y,width,height)
 local box = boxWindow.addBox("box",0,0,400,135,"mail") 
 local id = #list_box+1
 table.insert(list_box, box)
 list_box[id].id = id 
list_box[id]:setActive(true)
  -- création de l'en-tête de la boite (libellé, position, taille de police)
  list_box[id]:setTitle("LOADING...","center",25)


  local size_font = 25
  list_box[id]:setText("text","",true,true,size_font)
  list_box[id]:setText("text","",false,false,size_font)
  list_box[id]:setPosition(width/2-list_box[id].w/2,height/2-list_box[id].h/2)
  list_box[id]:updatePositionText() -- update position texte
  list_box[id]:build() -- construction boite
  

  -- ajout de bouton 1 (skin.png)
  local button = boxWindow.addButton("button_3") -- skin bouton
  list_box[id]:addButton(button)
  -- paramètre du bouton (numéro, position, libellé, taille de police)
  list_box[id]:setButton(1,"right", "OK", 25,nil,nil,true)
 -- list_box[id]:setButton(1,"auto","right", "OK", 25)

  local function Empty() end
  -- fonction de boutons
  list_box[#list_box].buttons[1]:setEvent("pressed", Empty)

end


function boxWindow.Succes(Pid,Pline)
 -- création d'une nouvelle boite (x,y,width,height)
 local box = boxWindow.addBox("box",0,0,400,135,"mail") 
 local id = #list_box+1
 table.insert(list_box, box)
 list_box[id].id = id 
 list_box[id]:setActive(true)
  -- création de l'en-tête de la boite (libellé, position, taille de police)
  list_box[id]:setTitle(success[Pid].title,"center",35)


  local size_font = 25
  list_box[id]:setText("text",success[Pid].line[1],true,true,size_font)
  
  for i=2, Pline do
    list_box[id]:setText("text",success[Pid].line[i],false,true,size_font)
  end 

  list_box[id]:setPosition(width/2-list_box[id].w/2,height/2-list_box[id].h/2)
  list_box[id]:updatePositionText() -- update position texte
  list_box[id]:build() -- construction boite
  

  -- ajout de bouton 1 (skin.png)
  local button = boxWindow.addButton("button_3") -- skin bouton
  list_box[id]:addButton(button)
  -- paramètre du bouton (numéro, position, libellé, taille de police)
  list_box[id]:setButton(1,"right", button_collect_text, 22,nil,nil,true)

  local function Empty() end
  -- fonction de boutons
  list_box[#list_box].buttons[1]:setEvent("pressed", Empty)

end





function boxWindow.addRoadGalaxy(Pdeparture, Parrival, Pdh)
 -- création d'une nouvelle boite (x,y,width,height)
 local box = boxWindow.addBox("box",0,0,400,120,"standard") 
 local id = #list_box+1
 table.insert(list_box, box)
 list_box[id].id = id 
 list_box[id]:setActive(true)
    -- création de l'en-tête de la boite (libellé, position, taille de police)
  list_box[id]:setTitle(destinate_title_text, "center", 30)
  list_box[id]:setPosition(10, 10)

 -- list_box[id]:setText("text", "Voici la deuxieme ligne de texte!")
  --list_box[id]:setText("text", "Voici la deuxieme ligne de texte!")
  list_box[id]:build()    
  local size_font = 25
  list_box[id]:setText("text", destinate_A_text..Pdeparture,true,false,size_font)
  list_box[id]:setText("text", destinate_B_text..Parrival,false,false,size_font)
  list_box[id]:setText("text", destinate_time_text.."unknown",false,false,size_font)
  list_box[id]:setText("text", destinate_DH_text..Pdh,false,false,size_font)
  list_box[id]:setText("text", destinate_ressource_text.."unknown",false,false,size_font)
  list_box[id]:setText("text", destinate_possibility_text.."accept",false,true,size_font)
  list_box[id]:setPosition(width/2-list_box[id].w/2,height/2-list_box[id].h/2)
  list_box[id]:updatePositionText()
  list_box[id]:build()
  ---------- CREATION DE LA BOITE --------------------------------------------


  -- ajout de bouton 1 (skin.png)
  local button = boxWindow.addButton("button_2")
  list_box[id]:addButton(button)
  -- paramètre du bouton (numéro, position, libellé, taille de police)
  list_box[id]:setButton(1,"left", button_decline_text, 25,nil,nil,true)

  
  -- fonction pour supprimer la boite concerné
  local function Road()
      player.galaxy.road = true
  end
  local function NoRoad()
      player.galaxy.road = false
      table.remove(list_pointA, #list_pointA)
      table.remove(list_pointB, #list_pointB)
  end

  -- ajout de bouton 2
  local button = boxWindow.addButton("button_1")
  list_box[#list_box]:addButton(button)
  list_box[#list_box]:setButton(2,"right", button_accept_text, 25,nil,nil,true)
  
  -- fonction de boutons
  list_box[#list_box].buttons[1]:setEvent("pressed", NoRoad)
  list_box[#list_box].buttons[2]:setEvent("pressed", Road)
end

function boxWindow.location(Ptile,Psun)
  
local system_name,planets,discover

          if list_tiles[Ptile].sun[Psun].discover == true then
            system_name = list_tiles[Ptile].sun[Psun].name
            planets = list_tiles[Ptile].sun[Psun].totalPlanets 
            discover = list_tiles[Ptile].sun[Psun].discover 
          else discover = false end


 -- création d'une nouvelle boite (x,y,width,height)
 local box = boxWindow.addBox("box",0,0,300,140,"standard") 
 local id = #list_box+1
 table.insert(list_box, box)
 list_box[id].id = id 
 list_box[id]:setActive(true)
    -- création de l'en-tête de la boite (libellé, position, taille de police)
  list_box[id]:setTitle(location_title_text, "center", 30)
  list_box[id]:setPosition(10, 10)

 -- list_box[id]:setText("text", "Voici la deuxieme ligne de texte!")
  --list_box[id]:setText("text", "Voici la deuxieme ligne de texte!")
  list_box[id]:build() 
  
  if discover then
    local size_font = 25
    
    local x,y = 0,0
    -- Récupère les coordonnées de l'étoile


       list_tiles[Ptile].sun[Psun]:StellarXY()
       x = list_tiles[Ptile].sun[Psun].xo 
       y = list_tiles[Ptile].sun[Psun].yo



    list_box[id]:setText("text", location_SystemID..system_name,true,false,size_font)
    list_box[id]:setText("text", location_numberPlanet_text..planets,false,false,size_font)  
    list_box[id]:setText("text", location_stellarCoordinate,true,false,size_font)  
    list_box[id]:setText("text", "X : "..x,false,false,size_font)
    list_box[id]:setText("text", "Y : "..y,false,false,size_font)
    list_box[id]:setPosition(width/2-list_box[id].w/2,height/2-list_box[id].h/2)
    list_box[id]:updatePositionText()
    list_box[id]:build()
    ---------- CREATION DE LA BOITE --------------------------------------------


    -- ajout de bouton 1 (skin.png)
    local button = boxWindow.addButton("button_1")
    list_box[id]:addButton(button)
    -- paramètre du bouton (numéro, position, libellé, taille de police)
    list_box[id]:setButton(1,"right", "OK", 25,nil,nil,true)
    local function Empty() end
    list_box[#list_box].buttons[1]:setEvent("pressed", Empty)
  elseif discover == false then
    local size_font = 25
    
    local x,y = 0,0
     list_box[id]:setText("text", "Sorry, but the system is not known",true,false,size_font)
    -- ajout de bouton 1 (skin.png)
    local button = boxWindow.addButton("button_1")
    list_box[id]:addButton(button)
    -- paramètre du bouton (numéro, position, libellé, taille de police)
    list_box[id]:setButton(1,"right", "OK", 25,nil,nil,true)    
    local function Empty() end
    list_box[#list_box].buttons[1]:setEvent("pressed", Empty)
    
    list_box[id]:setPosition(width/2-list_box[id].w/2,height/2-list_box[id].h/2)
    list_box[id]:updatePositionText()
    list_box[id]:build()
  end

end

function boxWindow.displacement(Ptile, Psun)

 local box = boxWindow.addBox("box",width/6,height/2,148,165,"deplacement") 
  local x,y
  for i=1, #list_tiles do
    if list_tiles[i].isVisible then
      for j=1, #list_tiles[i].sun do
        if list_tiles[i].sun[j].isSelected then
          x = list_tiles[i].sun[j].x + 10
          y = list_tiles[i].sun[j].y + 10
        end
      end
    end
  end
 local id = #list_box+1
 table.insert(list_box, box)
 list_box[id].id = id 
 list_box[id]:setActive(true)
 list_box[id]:isStatic(true) 
 list_box[id]:parentSun(Ptile, Psun)
 
    -- création de l'en-tête de la boite (libellé, position, taille de police)
  list_box[id]:setTitle("", "center", 1)
  list_box[id]:setName("displacement_galaxy")
  list_box[id]:setPosition(x,y)
  list_box[id]:build()

  local button = boxWindow.addButton("button_9")
  list_box[id]:addButton(button)
  list_box[id]:setButtonHoverPng(1,"button_10")  
  list_box[id]:setButtonScale(1,4)
  list_box[id]:setColorTextButton(1,{0,0,0,140})
  
  local function displace() 
    displacement.NewLine(Ptile,Psun) 
  end
  
  list_box[id]:setButton(1,"manual", "Allez vers", 24, list_box[id].x, list_box[id].y,true) 
  list_box[id].buttons[1]:setEvent("pressed", displace)
  
  local button = boxWindow.addButton("button_9")
  list_box[id]:addButton(button)
  list_box[id]:buttonParentSun(2,Ptile,Psun)
  list_box[id]:setButtonHoverPng(2,"button_10")  
  list_box[id]:setButtonScale(2,4)
  list_box[id]:setColorTextButton(2,{0,0,0,140})
  list_box[id]:setButton(2,"manual", "Centrer", 24, list_box[id].buttons[1].x, list_box[id].buttons[1].y + list_box[id].buttons[1].h,true) 
  list_box[id].buttons[2]:setEvent("pressed", map.locationBox)

  local button = boxWindow.addButton("button_9")
  list_box[id]:addButton(button)
  list_box[id]:buttonParentSun(3,Ptile,Psun)
  list_box[id]:setButtonHoverPng(3,"button_10")  
  list_box[id]:setButtonScale(3,4)
  list_box[id]:setColorTextButton(3,{0,0,0,140})
  list_box[id]:setButton(3,"manual", "coordonnées", 24, list_box[id].buttons[2].x, list_box[id].buttons[2].y + list_box[id].buttons[2].h,true)
  
  local function boxLocation()
    boxWindow.location(Ptile,Psun)
  end
  
  list_box[id].buttons[3]:setEvent("pressed", boxLocation)
end

return modelBox