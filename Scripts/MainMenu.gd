extends Node2D

var menuPage: Node2D
var t = 0.1

var target: Vector2

var selectSound: AudioStreamPlayer;

var globals: SettingsValues = SettingsValues.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	selectSound = $SelectSound
	menuPage = $MainMenuPage
	target = Vector2(0, 0)
	selectSound.volume_db = -20
	$BackgroundSprite.play()
	
func _physics_process(_delta) -> void:
	if (menuPage.position != target):
		menuPage.position = menuPage.position.lerp(target, t)

func back_button_pressed() -> void:
	target = Vector2(0, 0)
	selectSound.play()

func _on_start_button_pressed() -> void:
	target = Vector2 (-1920, 0)
	selectSound.play()
	
func _on_setting_button_pressed() -> void:
	target = Vector2 (1920, 0)
	selectSound.play()

func _on_level_1_pressed() -> void:
	selectSound.play()
	get_tree().change_scene_to_file("res://Scenes/ForestLevel1.tscn")

func _on_sound_slider_value_changed(value: float) -> void:
	globals.soundEffectVolume = value
	print("Sound set to ", globals.soundEffectVolume)
	ResourceSaver.save(globals, "res://Resources/Settings.tres")
	
	selectSound.volume_db = -100 + value
	selectSound.play()

func _on_pressure_slider_value_changed(value: float) -> void:
	globals.pressureFactor = value
	ResourceSaver.save(globals, "res://Resources/Settings.tres")

func _on_viscosity_force_amount_value_changed(value: float) -> void:
	globals.viscosityFactor = value
	ResourceSaver.save(globals, "res://Resources/Settings.tres")
