extends MarginContainer

var opacity_scalar: float = 0.0

func _process(dt):
  if Input.is_action_just_pressed("start"):
    get_node("/root/GameSystem").start_run()

  opacity_scalar += dt * 1.5
  if opacity_scalar - floor(opacity_scalar) < 0.5:
    $VBoxContainer/VBoxContainer/Label2.modulate.a = 0.5
  else:
    $VBoxContainer/VBoxContainer/Label2.modulate.a = 1.0
