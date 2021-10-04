extends Node2D

var train_scene = preload("res://source/train/Train.tscn")
var level_hud_scene = preload("res://source/ui/LevelHud.tscn")

onready var game_system = get_node("/root/GameSystem")

func _ready():
  for child in self.get_children():
    if child.name.find("TrainSpawner") > -1:
      var spawner = child
      var train = train_scene.instance()
      train.train_links = game_system.interpret_saplings()
      self.add_child_below_node(spawner, train)
      train.saplings[0].get_node("Torch").size = game_system.interpret_torch()
      train.position = spawner.position

  var level_hud_layer = CanvasLayer.new()
  self.add_child(level_hud_layer)
  level_hud_layer.layer = 10
  level_hud_layer.add_child(level_hud_scene.instance())

  game_system.connect("on_state_change", self, "on_state_change")

func on_state_change(id, old_value, new_value):
  pass
