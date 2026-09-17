success = {}

-- Fonction pour valider une succés Variable/Condition/ID
function verifiedSuccess(Pvariable, Pcondition, Pid)
      if success[Pid].unlocked == false then
        if Pvariable == Pcondition then
          boxWindow.Succes(Pid,#success[Pid].line)
          return true
        else return false
        end
      end
end



if LANGUAGE == "FRENCH" then
success[1] = {}
success[1].unlocked = false
success[1].title = "Succès debloqué"
success[1].reward = "A l'aube de l'infini"
success[1].line = {}
success[1].line[1] = "Vous avez debloqué le succès suivant en decouvrant deux planètes :"
success[1].line[2] = "Succés : "..success[1].reward
success[1].line[3] = "Continuez a jouer, et decouvrer encore les nombreux succès qui vous attendent !"


success[2] = {}
success[2].unlocked = false
success[2].title = "Succès debloqué"
success[2].line = {}
success[2].line[1] = "Vous avez debloqué le succès suivant en decouvrant cinq planètes :"
success[2].line[2] = "Succés : La naissance d'un explorateur"
success[2].line[3] = "Continuez a jouer, et decouvrer encore les nombreux succès qui vous attendent !"



elseif LANGUAGE == "ENGLISH" then
success[1] = {}
success[1].unlocked = false
success[1].title = "Success Unlocked"
success[1].reward = "At the dawn of infinity"
success[1].line = {}
success[1].line[1] = "You have unlocked success by discovering two planet :"
success[1].line[2] = "Success : "..success[1].reward
success[1].line[3] = "Keep playing to discover more !"

success[2] = {}
success[2].unlocked = false
success[2].title = "Success Unlocked"
success[2].line = {}
success[2].line[1] = "You have unlocked success by discovering five planet :"
success[2].line[2] = "Success : The birth of an explorer"
success[2].line[3] = "Keep playing to discover more !"
end




function success.update()
if SUCCESS then
success[1].unlocked = verifiedSuccess(player.discover.planet, 2,1)
success[2].unlocked = verifiedSuccess(player.discover.planet, 5,2)
end

end

return success









--[[
--------------- LISTE DES SUCCES --------------- 

1) A l'aube de l'infini -- découvrir 2 planètes
2) La traversée de l'impossible -- découvrir 2 systèmes
3) Pour le bien communs -- découvrir de 10 planètes
4) Le voyageur du temps -- découvrir de 5 systèmes
5) Le Berceau -- établir une colonie (si celle-ci survie)
5) 



--]]





















