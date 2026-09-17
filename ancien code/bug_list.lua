-- **CURRENT BUG**
--[[
  -La fonction toCircle ne génère pas des étoiles totalement ronde si leurs diamètre n'est pas un multiple de la taille d'une cellule.
  - Problème de police d'écriture en vue galactique pour le numéro des planètes
  - Problème de boites de dialogues qui peuvent s'ouvrir plusieurs fois de suite sans etre fermé au prealable
  - Problème Elliptique pour les planètes trop proche du soleil. Elles passent par dessus le soleil
  - Déplacement boite de texte (si le curseur est sur l'en tete lors de la creation de la boite, celle-ci va se deplacer de suite sur le curseur de la souris)
  - Les fenetres ne peuvent pas se superposer, sinon, elles se poussent. Definir des regles.
]]--

-- **BUG FIXES**
--[[
  31/08/2019 - Poupi
    grid : Correction d'une faute d'ortho dans la fonction toCircle (toCirle) - génération de bug si mal écrite.
    planet : le rayon est adapté en multiple de la taille d'une cellule afin d'avoir une découpe circulaire sans défauts.
    - Fix bug id des planètes qui passent en here
    - Fix problème de génération de nuages avec le margin
    - Fix problème de génération des ombres en fonction du margin
    - Fix problème d'affichages des ombres sur les nuages (method)
    - Fix des points de tracés qui ne s'actualisaient plus dans les tuiles invisibles
    - Fix des points de tracés qui ne s'actualisaient pas en meme temps que les soleils
    - Fix du déplacements des boites de dialogues qui ne s'actualisent plus lorsque la souris sortaient de la boite
]]--


--[[
-- PROJECT
  - placé les planètes derriere le soleil et devant en fonction de leurs positions dans le système.
  - Ajouter le prix de l'exploration grace a une variable globale ou je stock le prix en fonction des analyses selectionné.
  - menu deroulant cliquer planete pour (deplacer, centrer, infos)
  - renommer planetes et systèmes avec un label.
  - générer des noms aleatoires (
--]]