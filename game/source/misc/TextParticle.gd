extends Label

export (float) var time = 2.5
export (Vector2) var velocity = Vector2.ZERO
export (int) var font_size = 16

func _ready():
  self.set("custom_fonts/font", load("res://content/fonts/Alice" + str(font_size) + ".tres"))

func _physics_process(dt):
  time -= dt
  if time < 0:
    self.modulate.a -= 0.05

  if self.modulate.a < 0.0:
    queue_free()

  self.rect_position += velocity
  velocity = velocity.move_toward(Vector2.ZERO, dt * 2.5)
