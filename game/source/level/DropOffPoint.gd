extends Sprite

# Called when the node enters the scene tree for the first time.
func _ready():
  self.z_index = 0
  self.z_as_relative = false

  $Beam.z_index = 3
  $Beam.z_as_relative = false
  
  $SaplingDropOffBody.connect("area_entered", self, "on_sapling_drop_off_area_entered")
  $GroundedDropOffBody.connect("area_entered", self, "on_grounded_drop_off_area_entered")

func on_sapling_drop_off_area_entered(body):
  pass
  
func on_grounded_drop_off_area_entered(body):
  pass
