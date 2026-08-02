class_name SceneRouter
extends Node

const MAIN_MENU_SCENE: PackedScene = preload("res://Scenes/Game/MainMenu.tscn")
const GAME_SCENE: PackedScene = preload("res://Scenes/Game/GameRoot.tscn")
const BATTLE_SCENE: PackedScene = preload("res://Scenes/Battle/BattleRoot.tscn")

@export var scene_host: Node
var _session: GameSession = null
var _current_scene: Node = null

func _ready() -> void:
	go_to_main_menu()

func go_to_main_menu() -> void:
	_show_scene(MAIN_MENU_SCENE)

func enter_game(session: GameSession) -> void:
	if session == null or not session.has_active_state():
		push_error("SCENE: Cannot enter game without an active GameSession.")
		go_to_main_menu()
		return
	_session = session
	var game_root: GameRoot = _show_scene(GAME_SCENE) as GameRoot
	if game_root != null:
		game_root.bind_session(_session)

func enter_battle(context: Variant) -> void:
	if _session == null or not _session.has_active_state():
		push_error("SCENE: Cannot enter battle without an active GameSession.")
		go_to_main_menu()
		return
	var battle_root: BattleRoot = _show_scene(BATTLE_SCENE) as BattleRoot
	if battle_root != null:
		battle_root.bind_context(_session, context)

func return_to_game() -> void:
	if _session == null:
		go_to_main_menu()
		return
	enter_game(_session)


func get_current_scene() -> Node:
	return _current_scene

func _show_scene(packed_scene: PackedScene) -> Node:
	if scene_host == null:
		push_error("SCENE: SceneRouter requires a scene_host.")
		return null
	if _current_scene != null:
		_current_scene.queue_free()
	var next_scene: Node = packed_scene.instantiate()
	scene_host.add_child(next_scene)
	_current_scene = next_scene
	return next_scene
