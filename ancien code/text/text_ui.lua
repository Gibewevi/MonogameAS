text_ui = {}


if LANGUAGE == "FRENCH" then
  
  
-- Titre des différentes vues
view_galaxy_text = "--[Vue galactique]--"
view_system_text = "--[Vue système]--"
view_planet_text = "--[Vue planète]--"

-- Variables des boites UI
-- Déplacements
destinate_title_text = "NAVIGATION GALACTIQUE"
destinate_A_text = "Destination de départ : "
destinate_B_text = "Destination d'arrivée : "
destinate_time_text = "Temps stellaire : "
destinate_DH_text = "Distance : "
destinate_ressource_text = "Ressource requise : "
destinate_possibility_text = "Condition requise : "
-- Location
location_title_text = "LOCALISATION"
location_SystemID = "Nom du système : "
location_numberPlanet_text = "Nombre de planètes "
location_stellarCoordinate = "Coordonnées stellaire :"
-- Boutons UI
button_accept_text = "Accepter"
button_decline_text = "Refuser"
button_collect_text = "Récupérer"

elseif LANGUAGE == "ENGLISH" then
-- Titre des différentes vues
view_galaxy_text = "--[View galaxy]--"
view_system_text = "--[View system]--"
view_planet_text = "--[View planet]--"

-- Variables des boites UI
-- Déplacements
destinate_title_text = "GALACTIC NAVIGATION"
destinate_A_text = "Departure destination : "
destinate_B_text = "Arrival destination: "
destinate_time_text = "Stellar time : "
destinate_DH_text = "Distance : "
destinate_ressource_text = "Required resource : "
destinate_possibility_text = "Required condition : "
-- Location
location_title_text = "LOCATION"
location_SystemID = "Name of system : "
location_numberPlanet_text = "Number of planets : "
location_stellarCoordinate = "Stellar coordinates :"

-- Boutons UI
button_accept_text = "Accept"
button_decline_text = "Decline"
button_collect_text = "Collect"
end






return text_ui