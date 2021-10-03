extends KinematicBody2D

export (int) var initial_jump_speed = 450
export (int) var movement_speed = 250
export (int) var gravity_speed = 16
export (int) var gravity_speed_max = 1000

var movement_velocity = Vector2()
var gravity_velocity = Vector2()
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


func update_gravity_velocity():
  if self.final_velocity.y < gravity_speed_max:
    self.gravity_velocity += Vector2(0, gravity_speed)

func update_jump_velocity():
  if self.jump_velocity.y < 0:
    if jump_held > 0 && jump_held <= 15:
      self.jump_velocity = Vector2(0, -initial_jump_speed)
      self.gravity_velocity = Vector2()
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
  self.gravity_velocity = Vector2()
  self.may_jump = false
  self.jump_held = 1
  $AnimationPlayer.current_animation = "jump"

func land():
  self.gravity_velocity = Vector2()
  self.jump_velocity = Vector2()

  if !self.may_jump:
    $AnimationPlayer.current_animation = "land"
    $AnimationPlayer.queue("idle")
    self.may_jump = true
    self.may_jump = true

func bonk():
  self.jump_velocity = Vector2()

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

    # bonk check
    if collision_test.normal.y > 0.6:
      bonk()
      # recombine
      self.final_velocity = combine_forces()

  # respond to the final collision
  self.final_velocity = self.move_and_slide(self.final_velocity, Vector2(0, -1))
