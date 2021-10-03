extends KinematicBody2D

export (int) var initial_jump_speed = 450
export (int) var movement_speed = 250

var movement_velocity = Vector2()
var final_velocity = Vector2()
var jump_velocity = Vector2()
var may_jump = false
var jump_held = 0

func update_movement_velocity():
  self.movement_velocity = Vector2()

  if Input.is_action_pressed("move_left"):
    self.movement_velocity.x -= movement_speed

  if Input.is_action_pressed("move_right"):
    self.movement_velocity.x += movement_speed

  var anim = $AnimationPlayer
  var sprite = $Sprite
  if self.movement_velocity.x == 0 && anim.current_animation == "run":
    anim.current_animation = "idle"
  elif self.movement_velocity.x != 0:
    # update facing direction
    if sprite.flip_h && self.movement_velocity.x > 0:
      sprite.flip_h = false
    elif !sprite.flip_h && self.movement_velocity.x < 0:
      sprite.flip_h = true

    # show running anim
    if anim.current_animation == "idle":
      anim.current_animation = "run"

func update_jump_velocity():
  if self.jump_velocity.y < 0:
    if jump_held > 0 && jump_held <= 15:
      self.jump_velocity = Vector2(0, -initial_jump_speed)
      $KinematicGravity2D.reset()
    else:
      self.jump_velocity.y += 10.0

  if self.jump_velocity.y > 0:
    self.jump_velocity.y = 0

  if self.may_jump && (Input.is_action_just_pressed("move_up") || Input.is_action_just_pressed("move_jump")):
    self.jump()

  if Input.is_action_pressed("move_up") || Input.is_action_pressed("move_jump"):
    if jump_held > 0:
      jump_held += 1
  else:
    jump_held = 0

func jump():
  self.jump_velocity = Vector2(0, -initial_jump_speed)
  $KinematicGravity2D.reset()
  self.may_jump = false
  self.jump_held = 1
  $AnimationPlayer.current_animation = "jump"

func land():
  $KinematicGravity2D.reset()
  self.jump_velocity = Vector2()

  if !self.may_jump:
    $AnimationPlayer.current_animation = "land"
    $AnimationPlayer.queue("idle")
    self.may_jump = true

func bonk():
  self.jump_velocity = Vector2()

func combine_forces():
  return self.movement_velocity + $KinematicGravity2D.velocity + self.jump_velocity

func _physics_process(dt):
  update_movement_velocity()
  $KinematicGravity2D.update_velocity(self.final_velocity)
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

    # bonk check
    if collision_test.normal.y > 0.6:
      bonk()
      # recombine
      self.final_velocity = combine_forces()

  # respond to the final collision
  var snap_length = 50.0
  var snap = -collision_test.normal * snap_length if collision_test else Vector2.ZERO
  self.final_velocity += snap
  if may_jump:
    self.final_velocity = self.move_and_slide_with_snap(self.final_velocity, snap, Vector2.UP)
  else:
    self.final_velocity = self.move_and_slide(self.final_velocity, Vector2.UP)
