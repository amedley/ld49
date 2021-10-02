tool
extends Node2D

export(float) var speed
export(float) var target_margin
export(NodePath) var target_path

func _ready():
  var target = get_target()
  self.global_position = target.global_position

func get_target():
  var target = get_node_or_null(target_path)
  if target:
    return target

  return self

func _physics_process(dt):
  var global_position_target = self.get_target().global_position
  var distance_sq = self.global_position.distance_squared_to(global_position_target)
  if distance_sq > target_margin * target_margin:
    self.global_position = lerp(self.global_position, global_position_target, dt * speed)
