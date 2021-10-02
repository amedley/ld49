extends KinematicBody2D

export (int) var initial_jump_speed = 500
export (int) var movement_speed = 250
export (int) var gravity_speed = 16
export (int) var gravity_speed_max = 1000

var movement_velocity = Vector2()
var gravity_velocity = Vector2()
var final_velocity = Vector2()
var jump_velocity = Vector2()
var may_jump = false

# TODO:
# - Spend 1 hour trying to make jump as good as possible (short-hop, full-hop)
# - You should be able to jump one time *after* walking off a ledge
# - Animations are working, scale.x = -1 (flip) when facing left
#   - Any concept of "facing direction?"

func update_movement_velocity():
  self.movement_velocity = Vector2()

  if Input.is_action_pressed("move_left"):
    self.movement_velocity.x -= movement_speed

  if Input.is_action_pressed("move_right"):
    self.movement_velocity.x += movement_speed

func update_gravity_velocity():
  if self.final_velocity.y < gravity_speed_max:
    self.gravity_velocity += Vector2(0, gravity_speed)

func update_jump_velocity():
  if jump_velocity.y < 0:
    jump_velocity.y += 0.5

  if jump_velocity.y > 0:
    jump_velocity.y = 0

  if may_jump && (Input.is_action_just_pressed("move_up") || Input.is_action_just_pressed("move_jump")):
    self.jump_velocity = Vector2(0, -initial_jump_speed)
    self.gravity_velocity = Vector2()
    self.may_jump = false

func reset_vertical_forces():
  # reset gravity and jump velocities
  self.gravity_velocity = Vector2()
  self.jump_velocity = Vector2()

func land():
  reset_vertical_forces()
  may_jump = true

func bonk():
  reset_vertical_forces()

func combine_forces():
  return self.movement_velocity + self.gravity_velocity + self.jump_velocity

func _physics_process(dt):
  update_movement_velocity()
  update_gravity_velocity()
  update_jump_velocity()

  self.final_velocity = combine_forces()
  var collision_test = self.move_and_collide(final_velocity * dt, true, true, true) # test only!
  if collision_test:
    # wall check
    if abs(collision_test.normal.x) > 0.85:
      # you hit a wall
      self.movement_velocity = Vector2()
      # fix final velocity based on reset gravity
      self.final_velocity = combine_forces()

    # landed check
    if collision_test.normal.y < -0.6:
      land()
      # fix final velocity based on reset gravity
      self.final_velocity = combine_forces()
    #else SLIDE DOWN (implicit)

    # bonk check
    if collision_test.normal.y > 0.6:
      bonk()
      # recombine
      self.final_velocity = combine_forces()

  # respond to the final collision
  self.final_velocity = self.move_and_slide(self.final_velocity, Vector2(0, -1))
