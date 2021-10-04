extends MarginContainer

onready var game_system = get_node("/root/GameSystem")
onready var level_hud = get_parent().get_parent()

func _ready():
  self.update_render()
  $MarginContainer/HBoxContainer/VBoxContainer/TorchUpgrade.connect("pressed", self, "upgrade_torch")
  $MarginContainer/HBoxContainer/VBoxContainer2/SaplingUpgrade.connect("pressed", self, "upgrade_sapling")

func upgrade_torch():
  var torch_level = game_system.state[game_system.torch_id]
  var cost = game_system.get_upgrade_cost(torch_level + 1)
  var money = game_system.interpret_currency()
  if cost > money:
    level_hud.render_on_screen_message_once("You're not THAT rich...", Color.red)
  else:
    game_system.change_state(game_system.currency_id, -cost)
    game_system.change_state(game_system.torch_id, 1)
    self.update_render()

func upgrade_sapling():
  var saplings_level = game_system.state[game_system.saplings_id]
  var cost = game_system.get_upgrade_cost(saplings_level + 1)
  var money = game_system.interpret_currency()
  if cost > money:
    level_hud.render_on_screen_message_once("You're not THAT rich...", Color.red)
  else:
    game_system.change_state(game_system.currency_id, -cost)
    game_system.change_state(game_system.saplings_id, 1)
    self.update_render()

func update_render():
  var torch_level = game_system.state[game_system.torch_id]    
  $MarginContainer/HBoxContainer/VBoxContainer/TorchUpgrade.text = "GROW TORCH: $" + str(game_system.get_upgrade_cost(torch_level + 1))
  if torch_level == 0:
    $MarginContainer/HBoxContainer/VBoxContainer/TorchUpgrade.text = $MarginContainer/HBoxContainer/VBoxContainer/TorchUpgrade.text.replace("GROW TORCH", "CREATE TORCH")
    $MarginContainer/HBoxContainer/VBoxContainer/Label.text = $MarginContainer/HBoxContainer/VBoxContainer/Label.text.replace("Grows the", "Creates a")
  var sapling_level = game_system.state[game_system.saplings_id]
  $MarginContainer/HBoxContainer/VBoxContainer2/SaplingUpgrade.text = "SPAWN SAPLING: $" + str(game_system.get_upgrade_cost(sapling_level + 1))
