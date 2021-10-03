extends KinematicBody2D

var disabled: bool = false
var final_velocity: Vector2 = Vector2()
var throw_velocity: Vector2 = Vector2()
var initial_throw_speed: float = 500

func combine_forces():
  return $KinematicGravity2D.velocity + throw_velocity

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

  $KinematicGravity2D.update_velocity(self.final_velocity)
  self.final_velocity = combine_forces()

  var collision_test = self.move_and_collide(final_velocity * dt, true, true, true) # test only!
  if collision_test:
    # similar gravity/sliding to CharacterBody.gd
    if collision_test.normal.y < -0.6:
      $KinematicGravity2D.reset()
      self.throw_velocity = Vector2.ZERO
      # fix final velocity based on force changes
      self.final_velocity = combine_forces()

      var contact_edge_dir = collision_test.normal.rotated(PI*0.5)
      self.rotation = lerp(self.rotation, contact_edge_dir.angle(), dt * 2.0)

  var snap_length = 50.0
  var snap = -collision_test.normal * snap_length if collision_test else Vector2.ZERO
  self.final_velocity += snap
  self.final_velocity = self.move_and_slide_with_snap(self.final_velocity, snap, Vector2.UP)

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

