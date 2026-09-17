extends Node

# ---- utilitaires ----
static func _variant(base: Color, delta_h: float, delta_v: float, delta_s: float = 0.0) -> Color:
	var h: float = base.h + delta_h
	var s: float = clamp(base.s + delta_s, 0.0, 1.0)
	var v: float = clamp(base.v + delta_v, 0.0, 1.0)
	return Color.from_hsv(h, s, v)

static func _cap_sv_variant(base: Color, delta_h: float, delta_v: float, delta_s: float = 0.0) -> Color:
	return _variant(base, delta_h, delta_v, delta_s)


# ---- PALETTE STÉRILE ----
static func make_sterile() -> Dictionary:
	randomize()

	var fam: int = randi() % 5
	var base_h: float = 0.0
	match fam:
		0: base_h = randf_range(0.02, 0.08)   # rouille/terre cuite
		1: base_h = randf_range(0.48, 0.55)   # sarcelle/teal
		2: base_h = randf_range(0.58, 0.64)   # ardoise/bleu-gris
		3: base_h = randf_range(0.20, 0.25)   # mousse/olive
		4: base_h = randf_range(0.78, 0.85)   # prune/violet doux

	var base_s: float = randf_range(0.55, 0.75)
	var base_v: float = randf_range(0.55, 0.72)
	var base: Color = Color.from_hsv(base_h, base_s, base_v)

	var plains: Color = _cap_sv_variant(base, 0.0, -0.02, 0.00)
	var hills:  Color = _cap_sv_variant(base, 0.0, -0.10, +0.01)
	var mountains: Color = _cap_sv_variant(base, 0.0, +0.06, -0.02)

	var shelf_water: Color = _cap_sv_variant(base, 0.0, -0.15, +0.05)
	var deep_water:  Color = _cap_sv_variant(base, 0.0, -0.25, +0.08)

	return {
		"deep_water": deep_water,
		"shelf_water": shelf_water,
		"beach": Color(0.5, 0.45, 0.4), # neutre mais inutilisé
		"plains": plains,
		"hills": hills,
		"mountains": mountains,
		"_has_beaches": false
	}


# ---- PALETTE OCÉANIQUE (plus large et variée) ----
static func make_oceanic() -> Dictionary:
	randomize()

	# Tirage aléatoire dans tout le cercle chromatique
	var base_h = randf()                          # 0.0–1.0 → toutes les teintes
	var base_s = randf_range(0.35, 0.7)           # saturation moyenne → pas fluo
	var base_v = randf_range(0.45, 0.8)           # luminosité moyenne → pas trop sombre
	var land_base = Color.from_hsv(base_h, base_s, base_v)

	# Variantes altitude
	var plains: Color = _variant(land_base, 0.0, -0.02, 0.0)
	var hills:  Color = _variant(land_base, 0.0, -0.08, +0.02)
	var mountains: Color = _variant(land_base, 0.0, +0.10, -0.05)

	# Océans (palette restreinte turquoise/bleu pour lisibilité)
	var ocean_families = [
		[Color8(124,193,165), Color8(112,170,130)], # turquoise
		[Color8(124,193,219), Color8(112,170,196)]  # bleu
	]
	var ocean_choice = ocean_families[randi() % ocean_families.size()]
	var shelf_water: Color = ocean_choice[0]
	var deep_water:  Color = ocean_choice[1]

	return {
		"deep_water": deep_water,
		"shelf_water": shelf_water,
		"beach": Color(0.95, 0.9, 0.55),
		"plains": plains,
		"hills": hills,
		"mountains": mountains,
		"_has_beaches": true
	}


# ---- Alias ----
static func make_standard() -> Dictionary:
	return make_sterile()
