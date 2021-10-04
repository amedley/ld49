extends Node

var level_scene = preload("res://source/level/Level.tscn")

var upgrades: Array = [0, 0]
var currency: int = 0

func start_run():
  get_tree().change_scene_to(level_scene)
  pass

func get_saplings_total():
  return upgrades[0] + 1

func get_torch_height():
  return upgrades[1] * 42 + 42
