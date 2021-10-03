extends Node2D

var sapling_scene = preload("res://source/train/Sapling.tscn")
var saplings = []
var saplings_sorted = []

export (int) var train_links = 10
export (int) var jostle_ease = 35
export (int) var spawn_separation = 90
export (int) var closeness_ease = 25

var closeness_hard_go = 100
var jostle_hard_stop = 45

func _ready():
  for i in range(0, train_links):
    var sapling = sapling_scene.instance()
    add_child(sapling)
    saplings.append(sapling)
    sapling.position.x = i * spawn_separation

func compare_x(a, b):
  return a.position.x < b.position.x

func update_jostling():
  for i in range(0, len(self.saplings_sorted) - 1):
    var s1 = self.saplings_sorted[i] # to the left
    var s2 = self.saplings_sorted[i + 1] # to the right
    var unclamped = max(0.0, (s1.position.distance_to(s2.position) - jostle_hard_stop)) / max(1.0, jostle_ease)
    s1.jostle_multiplier = max(0.0, min(1.0, unclamped))
    s2.jostle_multiplier = 1.0

func update_closeness():
  for i in range(len(self.saplings_sorted) - 1, 0, -1):
    var s1 = self.saplings_sorted[i - 1] # to the left
    var s2 = self.saplings_sorted[i] # to the right
    var unclamped = 1.0 - max(0.0, (s1.position.distance_to(s2.position)) - closeness_hard_go) / max(1.0, closeness_ease)
    s1.closeness_multiplier = 1.0
    s2.closeness_multiplier = max(0.0, min(1.0, unclamped))

func _physics_process(dt):
  self.saplings_sorted = saplings.duplicate(false)
  saplings_sorted.sort_custom(self, "compare_x")
  update_jostling()
  update_closeness()

