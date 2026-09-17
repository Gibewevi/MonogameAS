# Vues galaxie, système et planète

Le rendu reste procédural, déterministe et dessiné en pixels à la résolution logique
640 × 360. Les planètes utilisent les palettes Oceanic, Sterile et Standard ; les soleils possèdent
une palette dédiée partagée entre les vues, déterminée par leur graine et leur classe.
Les textures utilisent `PointClamp` : pas de flou, de bloom ou de lissage ajouté.

## Utilisation

- Dans la **Galaxie**, cliquer une étoile puis **Voir le système** ; un double-clic
  ou **Entrée** ouvre également le système sélectionné.
- Glisser la carte avec le bouton gauche, milieu ou droit pour la déplacer.
  Les flèches, **ZQSD** et **WASD** restent disponibles. La molette zoome sous
  le curseur ; les boutons **− / +** offrent les mêmes quatre niveaux.
- **Origine** ou **Début/Home** revient au point de départ ; **Espace** ou
  **Centrer sur l'étoile** retrouve la sélection, conservée pendant la navigation.
- Cliquer une case **+** en bordure pour découvrir les secteurs voisins.
- Cliquer une planète dans **Système** puis ouvrir **Planète**.
- **F3** affiche ou masque les informations de débogage et les panneaux de réglage.
  Les paramètres de terrain, nuages et orbites restent disponibles.
- Dans les réglages planète, **Rings** et **Moons** permettent de choisir de zéro
  à trois anneaux ou lunes. **Clip** affiche aussi la carte complète à plat.
- Laisser tourner la vue planète pour découvrir les autres longitudes, les phases
  lumineuses et les passages des lunes devant et derrière le globe.

## Architecture

`src/Views/GalaxyView.cs` dessine la carte et gère ses interactions. La génération
est isolée dans `GalaxyView.Generation.cs` : les positions, graines, classes
d'étoiles et règles d'expansion du prototype sont conservées. Seuls les secteurs
visibles sont parcourus pour le dessin. Les dimensions d'origine sont restaurées :
toutes les étoiles partagent un diamètre de 8, 16, 24 ou 32 pixels selon le zoom,
avec des cellules de deux pixels à chaque niveau. L'aperçu de sélection mesure
40 pixels. La taille propre au système reste conservée dans son identité, mais
n'intervient plus dans les dimensions des symboles de la carte. Les silhouettes
gardent leur contour arrondi en escalier et les zones de clic suivent le diamètre
affiché.
Les sélections restent visibles et le clic ne déplace plus la caméra. La fiche de `GalaxyHud` contient
un aperçu animé et les commandes de visite et de recentrage.

Aux zooms ×3 et ×4, `PixelSunRenderer` dessine aussi la couronne, les arches de
plasma et les petites braises autour des étoiles. L'horloge solaire tourne à
4 % de sa vitesse système : un cycle de projection dure environ trois à cinq
minutes, pour une carte presque immobile mais vivante. L'aperçu de la fiche
partage cette lenteur. Le temps absolu conserve la phase lors des déplacements
et des changements de zoom ; les cadres et noms laissent de la place aux émanations.

`PixelGalaxyBackdrop` ajoute des nappes bleu nuit, lavande et menthe sous la carte.
Deux champs périodiques sont précalculés ; une texture de 160 × 90 texels est
actualisée à 8 Hz. La parallaxe, quelques étoiles lointaines d'un pixel et la
variation discrète des soleils animent l'ensemble. Les onglets, la fiche et les
commandes bloquent les clics destinés à l'interface ; glisser ne déclenche jamais
une sélection ni une exploration. Les miniatures des zooms éloignés sont conservées
dans un cache borné par niveau de zoom. `GalaxySunCache` garde jusqu'à 512 soleils
animés, indexés par identité et diamètre, et libère les textures les moins
récemment utilisées. Seules les étoiles visibles sont actualisées, sans allocation
de particules ni clé textuelle reconstruite à chaque accès.

`src/Rendering/PixelSpaceBackdrop.cs` partage le ciel entre les deux vues. Un champ
de poussière est précalculé à partir de la graine du système ; une petite texture
réactualisée à 8 Hz combine ses couleurs avec la position et la teinte du soleil.
Les étoiles avancent lentement sur plusieurs plans et scintillent par paliers.
En vue planète, le ciel utilise des bandes colorées plus présentes : sa teinte
principale provient de la couleur réellement générée du soleil, avec des nuances
voisines pour le ciel profond et l'horizon. Leur intensité suit le jour et la nuit,
et une lumière diffuse en paliers suit la position du soleil. Le changement de
couleur d'une étoile est appliqué immédiatement, même à graine et instant identiques.
En vue système, la palette solaire colore aussi le fond sombre et deux couches de
nébuleuses très légères. Un champ de bruit périodique de 128 × 128 valeurs est
généré une fois ; deux échantillonnages défilent lentement dans des directions
différentes, puis leurs densités sont réduites à quelques paliers. Le centre est
moins chargé pour préserver la lecture du soleil et des orbites. Aucun bruit ni
buffer n'est régénéré à chaque image.

`src/Galaxy/SolarPlasmaModel.cs` génère les soleils à partir de champs continus
qui se déplacent et se déforment, puis sont convertis en plages de sept couleurs.
Les nappes de plasma sont cohérentes dans l'espace ; la génération ne dépend
plus de l'ancien automate de terrain ni d'une variation aléatoire par pixel.
`SunGenerator.Bake` échantillonne le même modèle pour les miniatures galactiques.
`PixelSunRenderer` anime sa surface à 10 Hz et dessine la couronne et les petites
émanations : trois à sept arches s'élèvent, se courbent et se résorbent, avec une
petite braise qui s'éloigne. Leurs trajectoires sont calculées à partir du temps, sans accumulation
de particules. La teinte d'éclairage provient directement de la palette ; elle
reste identique entre les niveaux de détail.

Dans le système, soleils et miniatures planétaires partagent des cellules de
2 pixels logiques, agrandies avec `PointClamp`. Les miniatures stockent un seul
texel par cellule, et leurs zones de sélection suivent leur taille affichée.
Les miniatures retrouvent leur génération et leurs couleurs antérieures à la
refonte climatique, avec un minimum de quatre cellules de diamètre.
Le soleil garde un diamètre compris entre 32 et 128 pixels : le soleil initial
de 48 pixels est dessiné sur une grille de 24 × 24 cellules.
La vue planète emploie `DrawDistant` : un cœur simplifié de 5 × 3 pixels, trois
tons et un halo discret de 9 × 7 pixels, sans émanations. Il reste un petit repère
lointain parmi les étoiles.

`src/Planet/PlanetWorldMap.cs` représente le territoire entier en longitude et
latitude. La largeur de l'atlas dépend du rayon et de la taille de cellule de
la planète, avec une limite de 96 à 512 cellules. Le bruit est échantillonné sur une sphère pour raccorder les longitudes.
La vue détaillée et les miniatures système utilisent cette même génération.
La rotation change les coordonnées lues dans cette carte permanente ; elle ne
régénère pas les continents à chaque image. Un tour dure 84 secondes et les deux
vues utilisent le temps global du jeu pour garder la même orientation du sol.

La génération d'origine classe un champ d'altitude sphérique en six terrains :
océan profond, plateau côtier, plage, plaine, collines et montagnes. Les seuils
et la palette sont ceux de la version précédant la refonte climatique. Les
palettes océanique et stérile retrouvent leurs variations colorées déterministes.
Un cache CPU de 24 cartes évite de recalculer le territoire lors des changements
de vue ; il conserve la clé complète, y compris rayon et taille des cellules.
L'adaptateur `PlanetGenerator` projette cette même carte pour les consommateurs
de grilles. Les réglages de terrain sont conservés en mémoire par système et
par planète, même lorsque l'on navigue via la galaxie.

`src/Planet/PixelPlanetRenderer.cs` projette la carte sur une grille circulaire,
éclaire les cellules selon leur normale et anime les nuages indépendamment du sol.
Les anneaux inclinés et les lunes se dessinent en profondeur autour du globe.
Le cycle solaire de 224 secondes pilote ensemble le soleil de fond, l'éclairage
du globe et les nuances du ciel. Les buffers et textures sont réutilisés et
libérés avec les vues ; les couches du globe sont réactualisées à 12 Hz.

## Réinterprétation du prototype

Les références sont `ancien code/sun.lua`, `planet.lua`, `moon.lua` et `grid.lua` :
fonds colorés en bandes, défilement de grilles, ombres circulaires et passes
avant/arrière. La nouvelle version remplace les copies répétées de grilles par
l'échantillonnage d'une carte périodique, les sauts d'ombre par une direction de
lumière continue, et les animations dépendantes du nombre d'images par le temps.
Les fichiers du prototype restent intacts.

Les territoires et leurs couleurs ont été restaurés à partir de la version
antérieure à la refonte de l'algorithme des planètes. Les soleils, fonds spatiaux,
anneaux, lunes et cycles animés restent présents.

## Vérification

`powershell -File tools/Test-Visuals.ps1 -GalaxyOnly` capture la carte et vérifie
les systèmes initiaux, la sélection, le zoom ancré, les déplacements, l'exploration
et les commandes d'ouverture. Le banc contrôle également que les onglets, la fiche
et le letterboxing n'envoient pas de clics à la carte, ainsi que le rendu du fond.

`powershell -File tools/Test-Visuals.ps1 -GalaxySolarOnly` ajoute des captures aux
quatre zooms et à 0, 1, 60 et 240 secondes. Il vérifie les dimensions d'origine,
la conservation des identités des systèmes, la grille de deux pixels, la silhouette arrondie
au dézoom, les zones de clic et les projections au-delà de
la couronne, les cellules GPU de 2 × 2 pixels, la lenteur de l'animation, sa
répétabilité après navigation, ainsi que l'éviction et la libération du cache animé.
La galerie `galaxy-solar-review.html` permet de comparer les instants.

Construire avec `dotnet build --no-restore` lorsque les dépendances sont présentes,
ou `dotnet build` pour les restaurer.

Lancer `powershell -File tools/Test-Visuals.ps1` pour les contrôles de la carte et
les captures à plusieurs instants. Le script compile un petit outil dans le
répertoire temporaire, utilise le vrai rendu MonoGame dans une fenêtre SDL cachée
et écrit les images et son rapport dans `artifacts/visual-review`.
Le banc vérifie trois palettes, la reproductibilité du terrain, le raccord des
longitudes positives et négatives, les pôles et l'absence de pixels de terrain
transparents. Il compare également les pixels de la surface GPU : un quart de
tour doit déplacer le territoire, et un tour complet de 84 secondes doit rendre
exactement la même image lorsque l'éclairage est fixe et les nuages désactivés.
La navigation par onglets, la sélection d'une planète et les contrôles F3,
Rings, Moons et Clip sont exercés avec des entrées simulées dans le banc.
Les captures couvrent 0, 12, 30, 60 et 120 secondes, les trois palettes et les
panneaux de réglage. Le drapeau SDL de fenêtre cachée est contrôlé au début et
à la fin ; aucune image du bureau n'est utilisée.

`powershell -File tools/Test-Visuals.ps1 -SkyOnly` cible l'ambiance de la vue planète :
il change uniquement la température du soleil à graine, planète et instant
identiques, vérifie la réponse immédiate du ciel, puis capture le jour à 36 s et
la nuit à 148 s pour les deux palettes. Le soleil isolé est aussi mesuré sur le
rendu GPU pour contrôler ses petites dimensions.

`powershell -File tools/Test-Visuals.ps1 -SystemOnly` compare les systèmes chaud,
froid et vert à graine identique, aux instants 0, 30 et 90 secondes. Il vérifie
séparément que la texture des nébuleuses évolue à lumière fixe et redevient
identique au même instant, puis contrôle les cellules solaires de deux pixels et les
diamètres de 48 et 128 pixels. La navigation et la sélection sont aussi exercées.
Le nouveau plasma est capturé à 0, 2, 8 et 20 secondes pour les trois familles
de couleurs. Le banc vérifie le mouvement de sa surface, son déterminisme, sa
palette indépendante de la résolution et les blocs GPU de 2 × 2 pixels des
soleils et des planètes. `solar-review.html` permet de comparer les images
agrandies avec un échantillonnage au plus proche.

`powershell -File tools/Test-Visuals.ps1 -PlanetRestoreOnly` capture les trois
palettes historiques et exporte les codes et couleurs des atlas pour comparer
la restauration à l'ancien binaire. Le mode normal vérifie également qu'un
réglage F3 reste présent après un détour par la galaxie et un autre système.
Les compilations du banc sont isolées pour pouvoir tester même si le jeu est ouvert.

Les mesures CPU du rapport couvrent la mise à jour et la soumission du rendu ;
elles ne constituent pas une mesure du temps GPU ni du rafraîchissement écran.
