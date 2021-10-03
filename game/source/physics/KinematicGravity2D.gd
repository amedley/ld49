extends Node

export (int) var gravity_speed = 16
export (int) var gravity_speed_max = 1000

var velocity = Vector2()

func update_velocity(velocity_in: Vector2):
  if velocity_in.y < gravity_speed_max:
    self.velocity += Vector2(0, gravity_speed)

func reset():
  self.velocity = Vector2()
