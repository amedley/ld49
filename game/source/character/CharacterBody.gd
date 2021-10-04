extends KinematicBody2D

export (int) var initial_jump_speed = 450
export (int) var movement_speed = 250

var movement_velocity = Vector2()
var final_velocity = Vector2()
var jump_velocity = Vector2()
var may_jump = false
var jump_held = 0
var picked_object = null
var picked_object_parent = null
var picked_object_height = 0
var ghost_enabled: bool = false
var ghost_time: float = 0.0

func _ready():
  self.z_as_relative = false
  self.z_index = 4

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

  if self.may_jump && Input.is_action_just_pressed("move_jump"):
    self.jump()

  if Input.is_action_pressed("move_jump"):
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
  var try_pick_up = !self.picked_object && Input.is_action_just_pressed("pick_up")
  var did_pick_up = false
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

      if try_pick_up:
        if pick_up(collision_test.collider):
          did_pick_up = true

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

  var try_put_down = !did_pick_up && picked_object && Input.is_action_just_pressed("put_down")
  var did_put_down = false
  if try_put_down:
    did_put_down = put_down_picked_object()

  var try_throw = !did_pick_up && !did_put_down && picked_object && Input.is_action_just_pressed("throw")
  var did_throw = false
  if try_throw:
    did_throw = throw_picked_object()

  var try_toggle_ghost = !did_pick_up && !did_put_down && !try_throw && Input.is_action_just_pressed("toggle_ghost")
  var did_toggle_ghost = false
  if try_toggle_ghost:
    if !ghost_enabled:
      did_toggle_ghost = enable_ghost()
    else:
      did_toggle_ghost = disable_ghost()

func pick_up(object):
  if object.has_method("character_pick_up") && object.character_pick_up(self):
    self.picked_object = object
    self.picked_object_height = self.picked_object.get_picked_height() if self.picked_object.has_method("get_picked_height") else 0
    self.picked_object_parent = object.get_parent()
    self.picked_object_parent.remove_child(object)
    self.picked_object.position = Vector2(0, -picked_object_height * 0.5)
    self.picked_object.rotation = 0
    $PickedObjectContainer.call_deferred("add_child", self.picked_object)
    return true

  return false

func put_down_picked_object():
  if picked_object.has_method("character_put_down"):
    self.picked_object.character_put_down(self)

  $PickedObjectContainer.remove_child(self.picked_object)
  self.picked_object_parent.add_child(self.picked_object)
  var feet_offset = $FeetOffset.position
  self.picked_object.position = self.global_position + feet_offset - Vector2(0, self.picked_object_height * 0.5)
  self.position -= Vector2(0, self.picked_object_height)
  self.picked_object = null
  self.picked_object_parent = null
  return true

func throw_picked_object():
  if picked_object.has_method("character_throw"):
    self.picked_object.character_throw(self)

  $PickedObjectContainer.remove_child(self.picked_object)
  self.picked_object_parent.add_child(self.picked_object)
  var container_offset = $PickedObjectContainer.position
  self.picked_object.global_position = self.global_position + container_offset - Vector2(0, self.picked_object_height * 0.5)
  self.picked_object = null
  self.picked_object_parent = null
  return true

func enable_ghost():
  if picked_object:
    put_down_picked_object()

  self.ghost_enabled = true
  self.modulate.a = 0.5
  self.modulate.r = 3.0
  self.modulate.g = 3.0
  self.modulate.b = 3.0
  self.set_collision_layer_bit(2, false)
  return true

func disable_ghost():
  self.ghost_enabled = false
  self.modulate.a = 1.0
  self.modulate.r = 1.0
  self.modulate.g = 1.0
  self.modulate.b = 1.0
  self.set_collision_layer_bit(2, true)
  return true

