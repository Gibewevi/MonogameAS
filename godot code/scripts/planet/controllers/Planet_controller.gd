extends Node2D

const PlanetPaletteFactory = preload("res://scripts/planet/planet_palette_factory.gd")

@onready var terrain = $terrain_generator
@onready var clouds  = $cloud_generator
@onready var regen_button: Button = $RegenerateButton

func _ready() -> void:
	print("🌍 PlanetController prêt")
	randomize()

	_set_random_palette()
	terrain.generate_planet()
	clouds.generate_clouds()
	queue_redraw()

	if regen_button:
		regen_button.text = "🔄 Régénérer (R)"
		regen_button.pressed.connect(_on_regen_pressed)

func _process(delta: float) -> void:
	clouds.update_clouds(delta)
	queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		_on_regen_pressed()

func _on_regen_pressed() -> void:
	print("🔄 Régénération planète...")
	_set_random_palette()
	terrain.regenerate()
	clouds.randomize_params()
	clouds.generate_clouds()
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), Color.BLACK, true)
	terrain.draw(self)
	clouds.draw_clouds(self)

# -------------------------------
# Palette aléatoire selon type
# -------------------------------
func _set_random_palette() -> void:
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	#var type = rng.randi_range(0, 1) # 0=sterile, 1=oceanic
	var type = 1

	match type:
		0:
			terrain.current_palette = PlanetPaletteFactory.make_sterile()
			print("🎨 Palette: stérile")
		1:
			terrain.current_palette = PlanetPaletteFactory.make_oceanic()
			print("🎨 Palette: océanique")
