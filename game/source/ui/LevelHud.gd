extends MarginContainer

onready var game_system = get_node("/root/GameSystem")
onready var state_nodes = get_node("MarginContainer2/MarginContainer/HBoxContainer/State").get_children()

func _ready():
  game_system.connect("on_state_change", self, "on_state_change")
  for id in range(0, len(state_nodes)):
    sync_state(id)

func on_state_change(id, old_state, new_state):
  # TODO(amedley): something that looks cooler?
  sync_state(id)

func sync_state(id):
  state_nodes[id].text = str(game_system.state[id])
