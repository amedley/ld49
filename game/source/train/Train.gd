extends Node2D

onready var game_system = get_node("/root/GameSystem")

var sapling_scene = preload("res://source/train/Sapling.tscn")
var saplings = []

export (int) var train_links = 10
export (int) var jostle_ease = 35
export (int) var spawn_separation = 90
export (int) var closeness_ease = 40

var closeness_hard_go = 80
var jostle_hard_stop = 45

func _ready():
  for i in range(0, train_links):
    add_sapling(game_system.state[game_system.torch_id] > 0 && i == 0)

func add_sapling(torch = false):
    var sapling = sapling_scene.instance()
    add_child(sapling)
    sapling.position.x = (saplings[len(saplings) - 1].position.x if len(saplings) > 0 else 0) + spawn_separation
    saplings.append(sapling)
    if !torch:
      sapling.remove_child(sapling.get_node("Torch"))

func update_jostling():
  for i in range(0, len(self.saplings) - 1):
    var s1 = self.saplings[i] # to the left
    var s2 = self.saplings[i + 1] # to the right
    var unclamped = max(0.0, (s1.position.distance_to(s2.position) - jostle_hard_stop)) / max(1.0, jostle_ease)
    s1.jostle_multiplier = max(0.0, min(1.0, unclamped))
    s2.jostle_multiplier = 1.0

func update_closeness():
  for i in range(len(self.saplings) - 1, 0, -1):
    var s1 = self.saplings[i - 1] # to the left
    var s2 = self.saplings[i] # to the right
    var unclamped = 1.0 - max(0.0, (s1.position.distance_to(s2.position)) - closeness_hard_go) / max(1.0, closeness_ease)
    s1.closeness_multiplier = 1.0
    s2.closeness_multiplier = max(0.0, min(1.0, unclamped))

func _physics_process(dt):
  update_jostling()
  update_closeness()

