extends Node3D
## Spawns townspeople at random spots on the navigation mesh.

@export var npc_scene: PackedScene = preload("res://scenes/npc/npc.tscn")
@export var count := 14
## Your downloaded character files (.glb / .fbx). Each townsperson picks one at random.
## Leave empty to use placeholder people.
@export var character_models: Array[PackedScene] = []
## Hide parts of every character by node name, e.g. "*Sword*", "*Shield*".
@export var hide_nodes: PackedStringArray = []

const NAMES := ["Dana", "Marco", "Jess", "Big Ray", "Ollie", "Priya", "Tom", "Wendy", "Kev", "Nina", "Lou", "Sam", "Gus", "Ivy", "Dale", "Rosa"]
const LINES := [
	"Nice day, huh?",
	"You new around here?",
	"The corner store closes at ten.",
	"Don't touch my car.",
	"I lost my keys again.",
	"They say the old warehouse is empty. They say a lot of things.",
	"I'm late for work. Every day.",
	"Have you seen a small dog? Brown? Answers to Biscuit?",
	"Rent went up again.",
	"Lovely weather for standing around.",
]


func spawn() -> void:
	var map := get_world_3d().navigation_map
	for i in count:
		var npc := npc_scene.instantiate()
		var model: CharacterModel = npc.get_node("Model")
		if character_models.size() > 0:
			model.model_scene = character_models.pick_random()
		model.hide_nodes = hide_nodes
		var talk: Interactable = npc.get_node("Interactable")
		talk.display_name = NAMES[i % NAMES.size()]
		var l := LINES.duplicate()
		l.shuffle()
		talk.lines = PackedStringArray(l.slice(0, 3))
		add_child(npc)
		npc.global_position = NavigationServer3D.map_get_random_point(map, 1, false) + Vector3.UP * 0.2
