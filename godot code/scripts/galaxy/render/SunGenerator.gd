extends RefCounted
class_name SunGenerator
## Mosaïque identique au prototype (cellules), couleurs pilotées par la température,
## variations HSV (palette + micro-variations par cellule), boost blanc pour T élevées.
## Retour : { "albedo": Texture2D, "halo": Texture2D }

# ---------------------------
# Paramètres "proto" — forme/tailles
# ---------------------------
const CELL_PX := 2       # taille d’une cellule (garde la forme/cercle inchangée)
const LUCK    := 45      # proportion de 10 vs 20 à l'initialisation
const BIRTH   := 4       # valeur par défaut si tu appelles bake(...) sans passer d'autres seuils
const DEATH   := 3

# ---------------------------
# Couleur — réglages de variété
# ---------------------------
const PAL_JITTER_H := 0.012   # ± teinte (palette)
const PAL_JITTER_S := 0.08    # ± saturation palette
const PAL_JITTER_V := 0.06    # ± valeur/brightness palette

const ENABLE_CELL_DITHER := true   # micro-variation par cellule (déterministe)
const CELL_JITTER_H := 0.0
const CELL_JITTER_S := 0.04
const CELL_JITTER_V := 0.06

const WHITE_BOOST_START_K := 9000  # à partir de cette T, on tire vers le blanc
const WHITE_BOOST_MAX      := 0.55 # poids max du mélange vers le blanc
const HOT_WHITE_PROB       := 0.15 # proba cœur blanc pur si T >= 11000K

# ---------------------------
# Utils
# ---------------------------
static func _rand_range_i(rng: RandomNumberGenerator, lo:int, hi:int) -> int:
	return lo + int(floor(rng.randf() * float(hi - lo + 1)))

static func _C(r:int, g:int, b:int) -> Color:
	return Color8(r, g, b, 255)

static func _jitter_hsv(c: Color, rng: RandomNumberGenerator, dh: float, ds: float, dv: float) -> Color:
	var h: float = wrapf(c.h + rng.randf_range(-dh, dh), 0.0, 1.0)
	var s: float = clamp(c.s + rng.randf_range(-ds, ds), 0.0, 1.0)
	var v: float = clamp(c.v + rng.randf_range(-dv, dv), 0.0, 1.0)
	return Color.from_hsv(h, s, v, c.a)

# petit hash simple pour un seed cellule (déterministe)
static func _hash_cell(p_seed:int, l:int, c:int) -> int:
	return int(p_seed) ^ (l * 73856093) ^ (c * 19349663)

# ---------------------------
# Grille (fidèle au proto)
# ---------------------------
static func _grid_init_telluric(rng:RandomNumberGenerator, lines:int, cols:int, luck:int, birth:int, death:int) -> Array:
	var grid:Array = []
	var transfer:Array = []
	grid.resize(lines)
	transfer.resize(lines)

	for l:int in range(lines):
		grid[l] = []
		transfer[l] = []
		grid[l].resize(cols)
		transfer[l].resize(cols)
		for c:int in range(cols):
			transfer[l][c] = false
			grid[l][c] = 10 if _rand_range_i(rng, 1, 100) < luck else 20

	for l:int in range(1, lines - 1):
		for c:int in range(1, cols - 1):
			var cnt:int = 0
			if grid[l-1][c-1] == 10: cnt += 1
			if grid[l-1][c  ] == 10: cnt += 1
			if grid[l-1][c+1] == 10: cnt += 1
			if grid[l  ][c-1] == 10: cnt += 1
			if grid[l  ][c+1] == 10: cnt += 1
			if grid[l+1][c-1] == 10: cnt += 1
			if grid[l+1][c  ] == 10: cnt += 1
			if grid[l+1][c+1] == 10: cnt += 1

			if grid[l][c] == 10:
				transfer[l][c] = 20 if cnt < death else 10
			else:
				transfer[l][c] = 10 if cnt > birth else 20

	for l:int in range(1, lines - 1):
		for c:int in range(1, cols - 1):
			grid[l][c] = transfer[l][c]

	return grid

static func _grid_init_continent(rng:RandomNumberGenerator, grid:Array, lines:int, cols:int, luck:int) -> Array:
	for l:int in range(lines):
		for c:int in range(cols):
			if grid[l][c] == 10 and _rand_range_i(rng, 0, 100) < luck:
				grid[l][c] = 11

	for l:int in range(1, lines - 1):
		for c:int in range(1, cols - 1):
			if grid[l][c] == 11:
				if grid[l-1][c-1] == 11 and _rand_range_i(rng, 2, 3) == 3: grid[l-1][c-1] = 11
				if grid[l-1][c  ] == 11 and _rand_range_i(rng, 2, 3) == 3: grid[l-1][c  ] = 11
				if grid[l-1][c+1] == 11 and _rand_range_i(rng, 2, 3) == 3: grid[l-1][c+1] = 11
				if grid[l  ][c-1] == 11 and _rand_range_i(rng, 2, 3) == 3: grid[l  ][c-1] = 11
				if grid[l  ][c+1] == 11 and _rand_range_i(rng, 2, 3) == 3: grid[l  ][c+1] = 11
				if grid[l+1][c-1] == 11 and _rand_range_i(rng, 2, 3) == 3: grid[l+1][c-1] = 11
				if grid[l+1][c  ] == 11 and _rand_range_i(rng, 2, 3) == 3: grid[l+1][c  ] = 11
				if grid[l+1][c+1] == 11 and _rand_range_i(rng, 2, 3) == 3: grid[l+1][c+1] = 11
	return grid

static func _grid_init_ocean(grid:Array, lines:int, cols:int) -> Array:
	for l:int in range(1, lines - 1):
		for c:int in range(1, cols - 1):
			var cnt:int = 0
			if grid[l-1][c-1] == 10: cnt += 1
			if grid[l-1][c  ] == 10: cnt += 1
			if grid[l-1][c+1] == 10: cnt += 1
			if grid[l  ][c-1] == 10: cnt += 1
			if grid[l  ][c+1] == 10: cnt += 1
			if grid[l+1][c-1] == 10: cnt += 1
			if grid[l+1][c  ] == 10: cnt += 1
			if grid[l+1][c+1] == 10: cnt += 1
			if grid[l][c] == 20 and cnt == 0:
				grid[l][c] = 21
	return grid

# ---------------------------
# Palette « prototype » pilotée par la température (K)
# + variations HSV + boost blanc
# ---------------------------
static func _colors_from_celsus(rng:RandomNumberGenerator, celsus:int) -> Dictionary:
	var col:Dictionary = {}

	if celsus >= 0 and celsus < 5000:
		col["first"]  = _C(255, _rand_range_i(rng, 230, 255), 25)
		col["second"] = _C(255, _rand_range_i(rng, 130, 186), 25)
		col["third"]  = _C(255, _rand_range_i(rng, 137, 255), 25)
		col["fourth"] = _C(_rand_range_i(rng, 235, 255), _rand_range_i(rng, 107, 140), _rand_range_i(rng, 25, 45))

	elif celsus >= 5000 and celsus < 8000:
		var g:int = _rand_range_i(rng, 25, 178)
		col["first"]  = _C(255, g, 25)
		col["second"] = _C(255, min(g + 40, 255), 65)
		col["third"]  = _C(255, _rand_range_i(rng, 25, 178), 25)
		col["fourth"] = _C(255, _rand_range_i(rng, 25, 178), 25)

	elif celsus >= 8000 and celsus <= 10000:
		# vert / émeraude
		col["first"]  = _C(_rand_range_i(rng, 0, 90),  _rand_range_i(rng, 150, 200), 25)
		col["second"] = _C(_rand_range_i(rng, 80,155), 255, _rand_range_i(rng, 0, 40))
		col["third"]  = _C(_rand_range_i(rng, 30,140), _rand_range_i(rng, 180, 210), 25)
		col["fourth"] = _C(_rand_range_i(rng, 0, 40),  _rand_range_i(rng, 145, 155), 25)

	else: # > 10000 : turquoise/cyan + tirage vers blanc
		col["first"]  = _C( 68, 255, 255)
		col["second"] = _C( 25, 204, 255)
		col["third"]  = _C( 25, 158, 255)
		col["fourth"] = _C( 25, 114, 255)

	# variations HSV sur la PALETTE
	for key in ["first","second","third","fourth"]:
		col[key] = _jitter_hsv(col[key], rng, PAL_JITTER_H, PAL_JITTER_S, PAL_JITTER_V)

	# boost « blanc » progressif pour T élevées
	if celsus >= WHITE_BOOST_START_K:
		var t:float = clamp((float(celsus) - WHITE_BOOST_START_K) / 12000.0, 0.0, 1.0) # 9000→21000
		for key in ["first","second","third"]:
			col[key] = col[key].lerp(Color(1,1,1,1), WHITE_BOOST_MAX * t)
		if celsus >= 11000 and rng.randf() < HOT_WHITE_PROB:
			col["first"] = Color(1,1,1,1) # cœur blanc occasionnel

	return col

# ---------------------------
# B A K E
# ---------------------------
static func bake(p_seed:int, class_id:int, tex_size:int, _steps:int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = p_seed

	# cercle plein au centre, rayon multiple de CELL_PX
	var tiles:int  = max(1, int(floor(float(tex_size) / float(CELL_PX))))
	var usable:int = tiles * CELL_PX
	var lines:int  = int(floor(float(usable) / float(CELL_PX)))
	var cols:int   = int(floor(float(usable) / float(CELL_PX)))

	var cx:float = float(tex_size) * 0.5
	var cy:float = float(tex_size) * 0.5
	var radius:float = float(usable) * 0.5

	# température (K) — possibilité de passer la T directement via class_id ≥ 1000
	var celsus:int
	if class_id >= 1000:
		celsus = class_id
	else:
		match _rand_range_i(rng, 1, 4):
			1: celsus = _rand_range_i(rng,    0,  5000)
			2: celsus = _rand_range_i(rng, 5000,  8000)
			3: celsus = _rand_range_i(rng, 8000, 10000)
			4: celsus = _rand_range_i(rng, 10000, 25000)

	var cols_dict:Dictionary = _colors_from_celsus(rng, celsus)
	var col10:Color = cols_dict["first"]
	var col11:Color = cols_dict["second"]
	var col20:Color = cols_dict["third"]
	var col21:Color = cols_dict["fourth"]

	# grille : init → continent → océan
	var grid:Array = _grid_init_telluric(rng, lines, cols, LUCK, BIRTH, DEATH)
	grid = _grid_init_continent(rng, grid, lines, cols, LUCK)
	grid = _grid_init_ocean(grid, lines, cols)

	# rendu par cellules (mosaïque)
	var img:Image = Image.create(tex_size, tex_size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	var start_x:int = int(cx - radius)
	var start_y:int = int(cy - radius)

	for l:int in range(lines):
		for c:int in range(cols):
			var cell_cx:float = float(start_x + c * CELL_PX) + float(CELL_PX) * 0.5
			var cell_cy:float = float(start_y + l * CELL_PX) + float(CELL_PX) * 0.5
			if Vector2(cell_cx, cell_cy).distance_to(Vector2(cx, cy)) > radius:
				continue

			var code:int = int(grid[l][c])
			var base_col:Color
			match code:
				10: base_col = col10
				11: base_col = col11
				20: base_col = col20
				21: base_col = col21
				_:  base_col = col20

			var cc:Color = base_col
			if ENABLE_CELL_DITHER:
				var cell_rng := RandomNumberGenerator.new()
				cell_rng.seed = _hash_cell(p_seed, l, c)
				cc = _jitter_hsv(base_col, cell_rng, CELL_JITTER_H, CELL_JITTER_S, CELL_JITTER_V)

			var ox:int = start_x + c * CELL_PX
			var oy:int = start_y + l * CELL_PX
			for yy:int in range(oy, oy + CELL_PX):
				if yy < 0 or yy >= tex_size: continue
				for xx:int in range(ox, ox + CELL_PX):
					if xx < 0 or xx >= tex_size: continue
					img.set_pixel(xx, yy, cc)

	# halo discret (comme proto : vide par défaut)
	var halo:Image = Image.create(tex_size, tex_size, false, Image.FORMAT_RGBA8)
	halo.fill(Color(0,0,0,0))

	var sun_tex:Texture2D  = ImageTexture.create_from_image(img)
	var halo_tex:Texture2D = ImageTexture.create_from_image(halo)
	return { "albedo": sun_tex, "halo": halo_tex }
