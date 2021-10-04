tool
extends Node2D

var ready = false
export (float) var size setget set_size

func set_size(v):
    size = v
    self.update()

func _ready():
  self.ready = true
  self.update()

func update():
  if !self.ready:
    return
  $Stake.rect_size.y = self.size
  $Stake.rect_position.y = -self.size
  $Flame.position.y = -self.size - 8
  $CollisionShape2D.shape.extents.y = self.size / 2
  $CollisionShape2D.position.y = -self.size / 2
