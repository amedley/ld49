extends Node2D

var train_scene = preload("res://source/train/Train.tscn")
onready var game_system = get_node("/root/GameSystem")

func _ready():
  for child in self.get_children():
    if child.name.find("TrainSpawner") > -1:
      var spawner = child
      var train = train_scene.instance()
      train.train_links = game_system.get_saplings_total()
      self.add_child(train)
      train.saplings[0].get_node("Torch").size = game_system.get_torch_height()
      train.position = spawner.position
      
