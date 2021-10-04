extends Node2D

var train_scene = preload("res://source/train/Train.tscn")
var level_hud_scene = preload("res://source/ui/LevelHud.tscn")

onready var game_system = get_node("/root/GameSystem")

var trains: Array = []
var drop_offs: Array = []
var drop_off_exits: Array = []
var character_next_drop_off_index: int = 0
var trains_next_drop_off_index: Array = []

func _ready():
  for child in self.get_children():
    if child.name.find("TrainSpawner") > -1:
      var spawner = child
      var train = train_scene.instance()
      train.name = "TrainNode"
      train.train_links = game_system.interpret_saplings()
      self.add_child_below_node(spawner, train)
      train.saplings[0].get_node("Torch").size = game_system.interpret_torch()
      train.position = spawner.position
      self.trains.append(train)
      self.trains_next_drop_off_index.append(0)

  var level_hud_layer = CanvasLayer.new()
  self.add_child(level_hud_layer)
  level_hud_layer.layer = 10
  level_hud_layer.add_child(level_hud_scene.instance())

  game_system.connect("on_state_change", self, "on_state_change")

  for child in self.get_children():
    if child.name.find("DropOffPoint") > -1:
      self.drop_offs.append(child)
      self.drop_off_exits.append(child.position.x + 250)

func get_next_drop_off_index(position):
  var result = 0
  for exit in drop_off_exits:
    if position.x > exit:
      result += 1
    else:
      break
  return result

func _physics_process(dt):
  character_next_drop_off_index = get_next_drop_off_index($CharacterBody.position)
  for i in range(0, len(trains)):
    var saplings = trains[i].saplings
    var drop_off_index = max(trains_next_drop_off_index[i], get_next_drop_off_index(saplings[0].global_position))
    trains_next_drop_off_index[i] = drop_off_index
    saplings[len(saplings) - 1].stop_moving = drop_off_index > character_next_drop_off_index

func on_state_change(id, old_state, new_state):
  pass
