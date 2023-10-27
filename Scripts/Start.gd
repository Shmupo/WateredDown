extends Node

var botTurn: bool = false
var playerTurn: bool = false
var gameOver: bool = false

@onready var endScreen: PackedScene = load("res://Scenes/EndGameScreen.tscn")
@onready var playerTank = $PlayerTank
@onready var botTank = $AITank
@onready var turnLight: ColorRect = $GUI/TurnColor
@onready var playerWaterBar: ProgressBar = $GUI/PlayerWaterLevel
@onready var playerFuelBar: ProgressBar = $GUI/PlayerFuelLevel
@onready var timer: Timer = $Timer
@onready var turretCheckBox: CheckBox = $GUI/CheckBox

var winInfoSentences: Array = [
	"They should have brought an umbrella.",
	"A splash of victory.",
	"Drown their tears.",
	"They were indeed not a fish.",
	"You washed away their sinister schemes.",
	"Water they gonna do about it?"
]

var loseInfoSentences: Array = [
	"Rain check.",
	"Dihydrogen monoxide has a 100% mortality rate.",
	"Did you pee your pants?",
	"You forgot how to swim.",
	"You're all washed up.",
	"NANI?"
]

# this is the root node of every level
# controls turn logic

func _ready() -> void:
	turretCheckBox.connect("toggled", showInsidePlayer)
	
	botTank.playerTank = playerTank
	
	playerTank.start($Tank1StartPosition.position)
	botTank.start($Tank2StartPosition.position)
	
	playerTank.turn = true
	
	turnLight.color = Color.WEB_GREEN
	
	playerWaterBar.max_value = playerTank.maxParticlesContained
	playerFuelBar.max_value = playerTank.fuel
	playerFuelBar.value = playerTank.fuel
	
	if ResourceLoader.exists("res://Resources/Settings.tres"):
		var result = ResourceLoader.load("res://Resources/Settings.tres")
		
		var script = $Simulation
		script.SetModifiers(result.pressureFactor, result.viscosityFactor)
		script.SPHEngine.PrintModifiers()
	
func setPlayerWaterBar() -> void:
	playerWaterBar.value = playerTank.particlesContained
	
	if playerTank.particlesContained >= 50:
		if !gameOver:
			endGame(false)
	
func checkAiWaterBar() -> void:
	if botTank.particlesContained >= 50:
		if !gameOver:
			endGame(true)
		
func endGame(playerWin: bool) -> void:
	gameOver = true
	
	playerTank.turn = false
	playerTank.fuel = 0
	
	var screen = endScreen.instantiate()
	add_child(screen)
	
	var mainMenu: Button = screen.get_child(0)
	var winner: RichTextLabel = screen.get_child(1)
	var info: RichTextLabel = screen.get_child(2)
	
	mainMenu.connect("pressed", goToMainMenu)
	
	if playerWin:
		winner.text = "[center]Victory"
		info.text = "[center]" + winInfoSentences.pick_random()
	else:
		winner.text = "[center]Defeat"
		info.text = "[center]" + loseInfoSentences.pick_random()
		
	remove_child($MainMenuButton)
	
func goToMainMenu() -> void:
	get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")
	
func setPlayerFuelBar() -> void:
	playerFuelBar.value = playerTank.fuel
	
func _process(_delta) -> void:
	if botTurn == true:
		if timer.time_left == 0:
			botTank.executeTurn()
			botTurn = false
			
	if playerTurn == true:
		if timer.time_left == 0:
			turnLight.color = Color.WEB_GREEN
			playerTank.turn = true
			playerTank.fuel = 1000
			playerFuelBar.value = playerTank.fuel
			playerTurn = false

func _on_player_tank_player_turn_end() -> void:
	timer.start(2)
	turnLight.color = Color.RED
	botTurn = true

func _on_ai_tank_ai_turn_end() -> void:
	timer.start(2)
	playerTurn = true

func _on_main_menu_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")
	
func showInsidePlayer(pressed: bool):
	playerTank.turretVisibility(pressed)
