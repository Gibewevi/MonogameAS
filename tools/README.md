# Validation visuelle

`-GalaxyOnly` vérifie la nouvelle carte galactique : conservation exacte des
15 systèmes initiaux, sélection et survol, exploration adjacente, déplacement
par glisser et clavier, zoom ancré sous la souris, boutons, onglets, ouverture
du système et panneau F3. Le fond procédural est contrôlé pour son déterminisme,
sa grille pixel art et son animation. Les captures comprennent la carte initiale,
la sélection, l'exploration et les deux limites du zoom.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/Test-Visuals.ps1 -GalaxyOnly -OutputDirectory artifacts/visual-review/galaxy-redesign/after
```

`-GalaxySolarOnly` ajoute les captures solaires aux quatre zooms et à 0, 1, 60
et 240 secondes. Il contrôle les projections des zooms proches, leur animation
très lente, les dimensions d'origine (8/16/24/32 pixels et aperçu de 40 pixels),
la grille commune de deux pixels, les contours arrondis des
petites étoiles au dézoom, la conservation de la phase après navigation
et la libération des textures du cache. La galerie `galaxy-solar-review.html`
présente la carte et les étoiles isolées à plusieurs instants.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/Test-Visuals.ps1 -GalaxySolarOnly -OutputDirectory artifacts/visual-review/galaxy-solar-effects
```

`-GalaxyBaseline -SkipBuild -BinaryDirectory <dossier>` capture uniquement la
galaxie d'un ancien binaire. `galaxy-world-baseline.txt` conserve les positions,
graines et classes mesurées avant la refonte : ces identités restent vérifiées
même lorsque l'habillage visuel change.

`-PlanetRestoreOnly` capture les trois planètes de référence et leurs atlas bruts
(codes de relief et couleurs), puis contrôle la rotation, les anneaux, les lunes
et la sélection. Combiné à `-SkipBuild -BinaryDirectory <dossier>`, ce mode permet
de comparer la génération à une ancienne version compilée. Le mode normal
contrôle aussi la conservation des réglages de terrain entre deux systèmes.

`-SystemOnly` contrôle les soleils, les fonds et la grille de 2 × 2 pixels des
miniatures. Les compilations de validation utilisent un dossier temporaire et
n'écrasent pas les fichiers d'un jeu ouvert.

Depuis la racine du projet, sous Windows avec le SDK .NET 9 et les dépendances restaurées :

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/Test-Visuals.ps1
```

Le script construit le jeu puis un petit exécutable temporaire, sans ajouter de sources au projet principal. Il initialise le périphérique MonoGame avec une fenêtre SDL cachée, sans appeler `Game.Run`, dessine dans une cible 640 × 360 et exporte les captures dans `artifacts/visual-review`. Aucun écran du bureau n'est capturé.

Le rapport vérifie la génération déterministe du territoire, la périodicité de la rotation, les pôles, les palettes, les changements des images animées, les onglets et la sélection d'une planète. Un contrôle des pixels GPU isole le terrain avec un éclairage fixe : il se déplace après un quart de tour et retrouve exactement son image initiale après 84 secondes. Les contrôles F3, Rings, Moons et Clip sont exercés avec des entrées simulées dans le banc. Le rapport mesure aussi le temps CPU de préparation et de soumission du rendu et les allocations sur 120 images. Ces mesures excluent la présentation et la synchronisation GPU.

Les captures couvrent 0, 12, 30, 60 et 120 secondes pour trois planètes et la vue système. `-SkipBuild` utilise le dernier binaire construit ; `-OutputDirectory artifacts/visual-review/autre` change le dossier de sortie. `-Baseline` capture uniquement l'image initiale des deux vues.

`-SkyOnly` exécute uniquement la validation du ciel planétaire : même planète,
même graine de soleil et même instant, avec une température solaire de 3 200 puis
16 000. Le changement de couleur doit être visible immédiatement, et les
captures de jour et de nuit doivent montrer l'évolution de la palette.

La fenêtre reste cachée dès sa création : le moteur MonoGame 3.8.4.1 crée ses fenêtres avec le drapeau `Hidden` dans [SDLGameWindow](https://github.com/MonoGame/MonoGame/blob/v3.8.4.1/MonoGame.Framework/Platform/SDL/SDLGameWindow.cs), et les affiche uniquement dans la boucle `RunLoop` de [SDLGamePlatform](https://github.com/MonoGame/MonoGame/blob/v3.8.4.1/MonoGame.Framework/Platform/SDL/SDLGamePlatform.cs). Le banc vérifie les drapeaux SDL avant et après les captures.
