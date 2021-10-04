extends KinematicBody2D

var disabled: bool = false
var final_velocity: Vector2 = Vector2()
var throw_velocity: Vector2 = Vector2()
var initial_throw_speed: float = 500

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
  if disabled:
    if !$CollisionShape2D.disabled:
      $CollisionShape2D.disabled = true
    return

  if $CollisionShape2D.disabled:
    $CollisionShape2D.disabled = false

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
  disabled = true
  return true

func character_put_down(character):
  disabled = false
  return true

func character_throw(character):
  disabled = false
  self.throw_velocity = Vector2(character.final_velocity.x, -initial_throw_speed)
  return true

func get_picked_height():
  return $Sprite.texture.get_height()

