extends Node3D
## Sets the level up: builds the placeholder town, bakes the navigation mesh so
## people can walk around, then spawns the townspeople.

@onready var nav_region: NavigationRegion3D = $NavigationRegion3D
@onready var town: Node3D = $NavigationRegion3D/Town
@onready var npcs: Node3D = $NPCs
@onready var player: CharacterBody3D = $Player


func _ready() -> void:
	town.build()
	if town.enabled:
		player.global_position = town.spawn_point()
	nav_region.bake_navigation_mesh(false)
	# the navigation map picks up the new mesh on the next physics frames
	await get_tree().physics_frame
	await get_tree().physics_frame
	npcs.spawn()
	DevTools.attach_if_requested(self)
