extends Node
## Cache LRU de sprites de soleils (par LOD).
## À mettre en **Autoload** (nom conseillé : GlobalSunCache)

@export var capacity_per_lod:int = 2048  # LRU par LOD
const GEN_VER := 1                       # incrémente si l’algo change pour invalider le cache

# clef -> {albedo, halo}
var _map_lod0:Dictionary = {}
var _order_lod0:Array[String] = []       # plus ancien en tête

var _map_lod1:Dictionary = {}
var _order_lod1:Array[String] = []

# stats publiques (lisibles depuis la vue)
var hits:int = 0
var misses:int = 0

# --- debug (limiter le spam console) ---
var _dbg_bakes:int = 0
const _DBG_BAKE_PRINT_LIMIT := 5  # on affiche les 5 premiers bakes, puis silence

# ---------- util ----------
func _maps_for(lod:int) -> Array:
	if lod == 0:
		return [_map_lod0, _order_lod0]
	else:
		return [_map_lod1, _order_lod1]

func _make_key(p_seed:int, class_id:int, size:int, steps:int) -> String:
	return "%d_%d_%d_%d_%d" % [p_seed, class_id, size, steps, GEN_VER]

func _evict_if_needed(lod:int) -> void:
	var pair := _maps_for(lod)
	var map:Dictionary = pair[0]
	var order:Array[String] = pair[1]
	while order.size() > capacity_per_lod:
		var oldest:String = order.pop_front()
		map.erase(oldest)

# ---------- API ----------
## Retourne {albedo:Texture2D, halo:Texture2D} depuis le cache, ou lance un bake si miss.
func get_or_bake(lod:int, p_seed:int, class_id:int, size:int, steps:int) -> Dictionary:
	var key := _make_key(p_seed, class_id, size, steps)
	var pair := _maps_for(lod)
	var map:Dictionary = pair[0]
	var order:Array[String] = pair[1]

	# hit
	if map.has(key):
		order.erase(key)      # LRU: on remet au bout
		order.append(key)
		hits += 1
		return map[key]

	# miss -> bake via la classe globale
	var baked:Dictionary = SunGenerator.bake(p_seed, class_id, size, steps)
	map[key] = baked
	order.append(key)
	misses += 1

	# petit log pour vérifier que SunGenerator est bien appelé
	_dbg_bakes += 1
	if _dbg_bakes <= _DBG_BAKE_PRINT_LIMIT:
		print("[GlobalSunCache] bake #", _dbg_bakes,
			" → SunGenerator (lod=", lod, ", size=", size, ", steps=", steps,
			", class=", class_id, ", seed=", p_seed, ")")

	_evict_if_needed(lod)
	return baked

func reset_stats() -> void:
	hits = 0
	misses = 0
