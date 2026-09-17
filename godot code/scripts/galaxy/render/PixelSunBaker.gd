extends RefCounted
class_name PixelSunBaker
## Fabrique deux textures (disque + halo) pour un soleil.
## Retour: { "albedo": Texture2D, "halo": Texture2D }

# --- palettes par classes spectrales ---
const CLASS_NAMES := ["O", "B", "A", "F", "G", "K", "M"]

const PALETTES := {
	"O": [Color8( 40,120,255), Color8( 80,180,255), Color8(150,215,255), Color8(210,240,255)],
	"B": [Color8( 70,150,255), Color8(120,195,255), Color8(185,225,255), Color8(225,245,255)],
	"A": [Color8(200,210,255), Color8(230,235,255), Color8(245,248,255), Color8(255,255,255)],
	"F": [Color8(255,235,190), Color8(255,245,210), Color8(255,252,230), Color8(255,255,245)],
	"G": [Color8(255,210,120), Color8(255,225,150), Color8(255,240,185), Color8(255,250,210)],
	"K": [Color8(255,160, 90), Color8(255,180,115), Color8(255,205,150), Color8(255,220,175)],
	"M": [Color8(255,100,100), Color8(255,130,110), Color8(255,160,140), Color8(255,185,165)]
}

static func _class_key(class_id:int) -> String:
	var i:int = clamp(class_id, 0, CLASS_NAMES.size() - 1)
	return CLASS_NAMES[i]

static func _palette_for(class_id:int, steps:int) -> Array[Color]:
	# Convertit l’Array non typé en Array[Color] typé (Godot 4 strict typing)
	var src:Array = PALETTES[_class_key(class_id)] as Array
	var all:Array[Color] = []
	for c in src:
		all.append(c as Color)

	steps = clamp(steps, 2, 4)
	if steps >= all.size():
		return all

	var out:Array[Color] = []
	for i in range(steps):
		out.append(all[i])
	return out

static func _lerp_color(a:Color, b:Color, t:float) -> Color:
	return Color(
		lerp(a.r, b.r, t),
		lerp(a.g, b.g, t),
		lerp(a.b, b.b, t),
		lerp(a.a, b.a, t)
	)

## _p_seed conservé pour compat (non utilisé)
static func bake(_p_seed:int, class_id:int, grid:int, steps:int) -> Dictionary:
	grid = max(grid, 8)
	steps = clamp(steps, 2, 4)

	var pal:Array[Color] = _palette_for(class_id, steps)

	# --- disque "albedo" ---
	var img: Image = Image.create(grid, grid, false, Image.FORMAT_RGBA8)

	var cx: float = (grid - 1) * 0.5
	var cy: float = (grid - 1) * 0.5
	var r:  float = min(cx, cy)

	for y in range(grid):
		for x in range(grid):
			var dx: float = float(x) - cx
			var dy: float = float(y) - cy
			var d:  float = sqrt(dx * dx + dy * dy)

			if d <= r:
				var t: float = clamp(d / r, 0.0, 1.0)            # 0 centre → 1 bord
				var bands: float = t * float(steps - 1)         # bande couleur
				var k: int = int(floor(bands))
				k = clamp(k, 0, steps - 2)
				var tt: float = bands - float(k)                # “fract”
				var c: Color = _lerp_color(pal[k], pal[k + 1], tt)
				img.set_pixel(x, y, c)
			else:
				img.set_pixel(x, y, Color(0, 0, 0, 0))

	# --- halo doux ---
	var halo: Image = Image.create(grid, grid, false, Image.FORMAT_RGBA8)

	var halo_c: Color = pal[0]
	var hr: float = r * 1.1

	for y2 in range(grid):
		for x2 in range(grid):
			var dx2: float = float(x2) - cx
			var dy2: float = float(y2) - cy
			var d2:  float = sqrt(dx2 * dx2 + dy2 * dy2)

			if d2 <= hr:
				var a: float = clamp(pow(1.0 - (d2 / hr), 3.0), 0.0, 1.0) * 0.5
				halo.set_pixel(x2, y2, Color(halo_c.r, halo_c.g, halo_c.b, a))
			else:
				halo.set_pixel(x2, y2, Color(0, 0, 0, 0))

	var sun_tex:  Texture2D = ImageTexture.create_from_image(img)
	var halo_tex: Texture2D = ImageTexture.create_from_image(halo)

	return { "albedo": sun_tex, "halo": halo_tex }
