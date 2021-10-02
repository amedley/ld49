extends Camera2D

func _physics_process(dt):
  self.global_position = get_parent().global_position.floor()
