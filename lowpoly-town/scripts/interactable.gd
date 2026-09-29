class_name Interactable
extends Node
## Put this under anything that has a collision shape (a StaticBody3D, an NPC, a door...)
## and the player can look at it and press E.
##
## Connect the `interacted` signal to your own code, or just fill in `lines` for
## simple dialog.

signal interacted(by: Node)

## Shown as "[E] <prompt> <display_name>", e.g. "[E] Talk to Dana".
@export var prompt := "Use"
@export var display_name := ""
## Dialog lines, shown one per press.
@export_multiline var lines: PackedStringArray = []
@export var enabled := true

var _line := 0


func get_prompt() -> String:
	return prompt if display_name == "" else "%s %s" % [prompt, display_name]


func interact(by: Node) -> void:
	if not enabled:
		return
	interacted.emit(by)
	if lines.size() > 0:
		var speaker := display_name if display_name != "" else String(get_parent().name)
		get_tree().call_group("hud", "show_dialog", speaker, lines[_line % lines.size()])
		_line += 1


## Finds the Interactable on a collider: the node itself, one of its children, or
## its parent (so it works whether you hit the body or a child shape).
static func find_on(node: Node) -> Interactable:
	var n := node
	for i in 2:
		if n == null:
			return null
		if n is Interactable:
			return n
		for c in n.get_children():
			if c is Interactable:
				return c
		n = n.get_parent()
	return null
