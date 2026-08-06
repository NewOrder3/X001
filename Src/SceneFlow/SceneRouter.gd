class_name SceneRouter
extends Node

const MAIN_MENU_SCENE_PATH: String = "res://Scenes/Game/MainMenu.tscn"
const GAME_SCENE_PATH: String = "res://Scenes/Game/GameRoot.tscn"
const BATTLE_SCENE_PATH: String = "res://Scenes/Battle/BattleRoot.tscn"

@export var scene_host: Node
var _session: GameSession = null
var _current_scene: Node = null

func _ready() -> void:
	go_to_main_menu()

func go_to_main_menu() -> void:
	_show_scene_path(MAIN_MENU_SCENE_PATH)

func enter_game(session: GameSession) -> void:
	if session == null or not session.has_active_state():
		push_error("SCENE: Cannot enter game without an active GameSession.")
		go_to_main_menu()
		return
	_session = session
	_bind_session_events()
	var game_root: GameRoot = _show_scene_path(GAME_SCENE_PATH) as GameRoot
	if game_root != null:
		game_root.bind_session(_session)

func enter_battle(context: Variant) -> void:
	if _session == null or not _session.has_active_state():
		push_error("SCENE: Cannot enter battle without an active GameSession.")
		go_to_main_menu()
		return
	var battle_root: BattleRoot = _show_scene_path(BATTLE_SCENE_PATH) as BattleRoot
	if battle_root != null:
		battle_root.bind_context(_session, context)

func return_to_game() -> void:
	if _session == null:
		go_to_main_menu()
		return
	enter_game(_session)


func get_current_scene() -> Node:
	return _current_scene


func _bind_session_events() -> void:
	if _session == null:
		return
	var events: SessionEvents = _session.get_session_events()
	if not events.battle_started.is_connected(_on_battle_started):
		events.battle_started.connect(_on_battle_started)
	if not events.battle_exited.is_connected(_on_battle_exited):
		events.battle_exited.connect(_on_battle_exited)


func _on_battle_started(boss_id: StringName) -> void:
	call_deferred("enter_battle", boss_id)


func _on_battle_exited() -> void:
	call_deferred("return_to_game")

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


func _show_scene_path(scene_path: String) -> Node:
	var packed_scene: PackedScene = load(scene_path) as PackedScene
	if packed_scene == null:
		push_error("SCENE: Failed to load scene '%s'." % scene_path)
		return null
	return _show_scene(packed_scene)
