extends Sprite

var drop_off_index = -1

# Called when the node enters the scene tree for the first time.
func _ready():
  self.z_index = 0
  self.z_as_relative = false

  $Beam.z_index = 3
  $Beam.z_as_relative = false

  $SaplingDropOffArea.connect("body_entered", self, "on_sapling_drop_off_body_entered")
  $GroundedDropOffArea.connect("body_entered", self, "on_grounded_drop_off_body_entered")
  $UpgradeArea.connect("body_entered", self, "on_upgrade_body_entered")
  $UpgradeArea.connect("body_exited", self, "on_upgrade_body_exited")

func on_sapling_drop_off_body_entered(body):
  body.update_drop_off_priority(2, self.global_position)

func on_grounded_drop_off_body_entered(body):
  body.update_drop_off_priority(1, self.global_position)

func on_upgrade_body_entered(body):
  body.in_upgrade_area = self.drop_off_index
  body.just_entered_upgrade_area = true

func on_upgrade_body_exited(body):
  body.in_upgrade_area = -1
