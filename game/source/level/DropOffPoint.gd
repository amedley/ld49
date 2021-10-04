extends Sprite

# Called when the node enters the scene tree for the first time.
func _ready():
  self.z_index = 0
  self.z_as_relative = false

  $Beam.z_index = 3
  $Beam.z_as_relative = false

  $SaplingDropOffBody.connect("body_entered", self, "on_sapling_drop_off_body_entered")
  $GroundedDropOffBody.connect("body_entered", self, "on_grounded_drop_off_body_entered")

func on_sapling_drop_off_body_entered(body):
  body.update_drop_off_priority(2, self.global_position)

func on_grounded_drop_off_body_entered(body):
  body.update_drop_off_priority(1, self.global_position)
