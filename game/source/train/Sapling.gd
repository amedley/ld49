extends KinematicBody2D

export (int) var movement_speed = 50

var jostle_multiplier: float = 1.0
var closeness_multiplier: float = 1.0

func contact_hash(contact):
  if !contact:
    return "-1_-1"
  return str(contact.collider_id) + "_" + str(contact.collider_shape_index)

var previous_terrain_hash = contact_hash(null)
var current_terrain_hash = contact_hash(null)
var final_velocity: Vector2 = Vector2()

func _ready():
  self.z_as_relative = false
  self.z_index = 1

func _physics_process(dt):
  var collision_count = get_slide_count()

  # look for the best terrain contact
  var contact = null
  var contact_is_terrain = false
  var found_previous_terrain_contact = null
  var found_current_terrain_contact = null
  for i in range(0, collision_count):
    var c = get_slide_collision(i)
    if c.collider.name.find("TerrainBody") > -1:
      var terrain_hash = contact_hash(c)
      if terrain_hash == previous_terrain_hash:
        found_previous_terrain_contact = c
      elif terrain_hash == current_terrain_hash:
        found_current_terrain_contact = c
      else:
        # done!
        contact = c
        contact_is_terrain = true
        break

  if !contact && found_current_terrain_contact:
    # stick to current
    contact = found_current_terrain_contact
    contact_is_terrain = true

  if !contact && found_previous_terrain_contact:
    # switch to previous
    contact = found_previous_terrain_contact
    contact_is_terrain = true

  if !contact:
    # fallback: pick that faces upward the most
    var most_up: float = 1.0
    for i in range(0, collision_count):
      var c = get_slide_collision(i)
      if c.normal.y < most_up:
        # this is not terrain
        most_up = c.normal.y
        contact = c

  # update terrain hashes if we need to
  if contact_is_terrain:
    var terrain_hash = contact_hash(contact)
    if terrain_hash != self.current_terrain_hash:
      self.previous_terrain_hash = self.current_terrain_hash
      self.current_terrain_hash = terrain_hash

  var snap_length = 50
  if !contact:
    $KinematicGravity2D.update_velocity(self.final_velocity)
    self.final_velocity = self.move_and_slide_with_snap($KinematicGravity2D.velocity, Vector2.DOWN * snap_length, Vector2.UP)
  else:
    $KinematicGravity2D.reset()
    var contact_edge_dir = contact.normal.rotated(PI*0.5)
    self.rotation = lerp(self.rotation, contact_edge_dir.angle(), dt * 2.0)
    var snap = -contact.normal * snap_length
    self.final_velocity = contact_edge_dir * movement_speed + snap

    if abs(self.jostle_multiplier - 1.0) > 0.00001:
      # jostling
      self.final_velocity = self.final_velocity * self.jostle_multiplier
    elif abs(self.closeness_multiplier - 1.0) > 0.00001:
      # closeness
      self.final_velocity = self.final_velocity * self.closeness_multiplier

    # slide
    if !self.final_velocity.is_equal_approx(Vector2.ZERO):
      self.final_velocity = self.move_and_slide_with_snap(self.final_velocity, snap, Vector2.UP)
