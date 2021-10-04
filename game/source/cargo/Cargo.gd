extends KinematicBody2D

var text_particle_scene = preload("res://source/misc/TextParticle.tscn")

onready var game_system = get_node("/root/GameSystem")

var disabled: bool = false
var final_velocity: Vector2 = Vector2.ZERO
var throw_velocity: Vector2 = Vector2.ZERO
var initial_throw_speed: float = 500
var drop_off_priority: int = 0
var drop_off_global_position: Vector2 = Vector2.ZERO
var drop_off_committed = false
var drop_off_committed_time = 0.0
var drop_off_physics_time = 0.0
var drop_off_rewarded = false

export (int) var currency_value: float = 0

func contact_hash(contact):
  if !contact:
    return "-1_-1"
  return str(contact.collider_id) + "_" + str(contact.collider_shape_index)

var previous_sapling_hash = contact_hash(null)
var current_sapling_hash = contact_hash(null)

func is_cargo():
  return true

func combine_forces():
  return $KinematicGravity2D.velocity + throw_velocity

func _ready():
  self.z_as_relative = false
  self.z_index = 2

func _physics_process(dt):
  if self.drop_off_priority == 0:
    if self.disabled:
      if !$CollisionShape2D.disabled:
        $CollisionShape2D.disabled = true
      return

    if $CollisionShape2D.disabled:
      $CollisionShape2D.disabled = false
  else:
    drop_off_committed = true

  if drop_off_committed:
    drop_off_committed_time += dt * 2.0 + self.final_velocity.length() * 0.00025

  if drop_off_committed_time > 3.0:
    drop_off_physics_update(dt)
    return

  if !throw_velocity.is_equal_approx(Vector2.ZERO):
    throw_velocity = throw_velocity.move_toward(Vector2.ZERO, 0.1)
  else:
    throw_velocity = Vector2.ZERO

  var collision_count = get_slide_count()

  # look for sapling contacts
  var contact = null
  var found_previous_contact = null
  var found_current_contact = null
  for i in range(0, collision_count):
    var c = get_slide_collision(i)
    if c.collider.name.find("SaplingPlatform") > -1:
      var h = contact_hash(c)
      if h == previous_sapling_hash:
        found_previous_contact = c
      elif h == current_sapling_hash:
        found_current_contact = c
      else:
        # done!
        contact = c
        break

  if !contact && found_current_contact:
    # stick to current
    contact = found_current_contact

  if !contact && found_previous_contact:
    # switch to previous
    contact = found_previous_contact

  if contact:
    var contact_hash = contact_hash(contact)
    if contact_hash != self.current_sapling_hash:
      self.previous_sapling_hash = self.current_sapling_hash
      self.current_sapling_hash = contact_hash

  var contact_is_sapling = contact != null

  if !contact:
    # fallback: pick that faces upward the most
    var most_up: float = 1.0
    for i in range(0, collision_count):
      var c = get_slide_collision(i)
      if c.normal.y < most_up:
        # this is not terrain
        most_up = c.normal.y
        contact = c

  var did_move = false
  var rotate = false
  if !contact:
    # no contact, just gravity
    $KinematicGravity2D.update_velocity(self.final_velocity)
    self.final_velocity = combine_forces()
    self.final_velocity = self.move_and_slide(self.final_velocity, Vector2.UP)
    did_move = true
  else:
    throw_velocity = Vector2.ZERO
    if !contact_is_sapling:
      # the contact is not a sapling, check landing
      if contact.normal.y < -0.6:
        # landed, rotate + snap
        rotate = true
        $KinematicGravity2D.reset()
        self.final_velocity = combine_forces() # should be zero
        self.final_velocity = self.move_and_slide_with_snap(Vector2.ZERO, contact.collider_velocity.rotated(PI*0.5), Vector2.UP)
        did_move = true
      else:
        # not landed, no snap
        $KinematicGravity2D.update_velocity(self.final_velocity)
        self.final_velocity = combine_forces()
        self.final_velocity = self.move_and_slide(self.final_velocity, Vector2.UP)
        did_move = true

    else:
      # contact is a sapling
      $KinematicGravity2D.reset()
      self.final_velocity = combine_forces() # should be zero

      # snap if the contact is from above the platform
      if contact.normal.y < -0.08:
        # landed, rotate + snap
        rotate = true
        self.final_velocity = self.move_and_slide_with_snap(Vector2.ZERO, contact.collider_velocity.rotated(PI*0.5), Vector2.UP)
        did_move = true

  if rotate:
    var contact_edge_dir = contact.normal.rotated(PI*0.5)
    self.rotation = lerp(self.rotation, contact_edge_dir.angle(), dt * 2.0)

  if !did_move:
    $KinematicGravity2D.reset()
    self.final_velocity = self.move_and_slide(Vector2.ZERO, Vector2.UP)

func character_pick_up(character):
  if self.drop_off_priority > 0:
    return false

  disabled = true
  return true

func character_put_down(character):
  if self.drop_off_priority > 0:
    return false

  disabled = false
  return true

func character_throw(character):
  if self.drop_off_priority > 0:
    return false

  disabled = false
  self.throw_velocity = Vector2(character.final_velocity.x, -initial_throw_speed)
  return true

func get_picked_height():
  return $Sprite.texture.get_height()

func update_drop_off_priority(priority, global_position):
  if !drop_off_committed && priority > self.drop_off_priority:
    self.drop_off_priority = priority
    self.drop_off_global_position = global_position
    $CollisionShape2D.disabled = true

func drop_off_physics_update(dt):
  self.drop_off_physics_time += dt

  var target_dir = ((self.drop_off_global_position - Vector2(0, 2000)) - self.global_position).normalized()
  var current_dir = self.final_velocity.normalized().move_toward(target_dir, 0.2)

  var speed: float = 110
  var rotation: float = self.rotation
  if self.drop_off_priority == 2:
    speed = 260
    rotation += PI*0.020

  self.final_velocity = current_dir * dt * speed
  self.global_position += self.final_velocity
  self.rotation = rotation

  if self.drop_off_physics_time > 0.25:
    if !self.drop_off_rewarded:
      self.drop_off_rewarded = true
      self.reward_drop_off()
    if self.drop_off_priority == 1:
      self.modulate.a -= 0.025
    else:
      self.modulate = Color(self.modulate.r + 0.1, self.modulate.g + 0.1, self.modulate.b + 0.1, self.modulate.a)
      if self.drop_off_physics_time > 2.5:
        self.modulate.a -= 0.1

  if self.drop_off_physics_time > 3.0:
    self.queue_free()

func reward_drop_off():
  var reward = self.currency_value * (1 if drop_off_priority < 2 else 2)
  game_system.change_state(game_system.currency_id, reward)
  var text_particle = text_particle_scene.instance()
  var level = get_node("/root/Level")
  var character = level.get_node("CharacterBody")

  if drop_off_priority == 1:
    text_particle.modulate = Color(0.7, 0.9, 0.25)
    text_particle.font_size = 24
  else:
    text_particle.modulate = Color(0.15, 1.0, 0.15)
    text_particle.font_size = 32

  text_particle.text = "+$" + str(reward)
  level.world_hud.add_child(text_particle)

  text_particle.rect_global_position = self.global_position - (text_particle.rect_size * text_particle.rect_scale) * 0.5
  text_particle.velocity = (character.global_position - self.global_position).normalized() * self.final_velocity.length()
