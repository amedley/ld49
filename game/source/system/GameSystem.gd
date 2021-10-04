extends Node

signal on_state_change(id, old_state, new_state)

var level_scene = preload("res://source/level/Level.tscn")

var state_interpreter: Array = []
var state: Array = []

var num_states = 0

func new_state(name, initial):
  num_states += 1
  state_interpreter.append("interpret_" + name)
  state.append(initial)
  return num_states - 1

var currency_id: int = new_state("currency", 0)
var saplings_id: int = new_state("saplings", 1)
var torch_id: int = new_state("torch", 0)

var is_start: bool = false
var is_reset: bool = false
var is_win: bool = false

func _ready():
  pass

func start_run():
  self.is_start = true
  self.is_reset = false
  self.is_win = false
  get_tree().change_scene_to(level_scene)
  pass

func reset_run():
  self.is_start = false
  self.is_reset = true
  self.is_win = false
  get_tree().change_scene_to(level_scene)
  pass

func win():
  self.is_win = true

func interpret(id, value = null):
  if value == null:
    return interpret(id, state[id])
  return self.call(state_interpreter[id], value)

func interpret_currency(value = null):
  if value == null:
    return interpret_currency(state[currency_id])
  return value

func interpret_saplings(value = null):
  if value == null:
    return interpret_saplings(state[saplings_id])
  return value

func interpret_torch(value = null):
  if value == null:
    return interpret_torch(state[torch_id])
  return value * 42

func change_state(id, amount, clamp_min = 0, clamp_max = 999999999):
  var old_state = state[id]
  var new_state = clamp(old_state + amount, clamp_min, clamp_max)
  if new_state != old_state:
    state[id] = new_state
    emit_signal("on_state_change", id, old_state, new_state)

func get_upgrade_cost(level):
  return 2000 + (level - 1) * 1500
