extends Node

signal on_state_change(id, old_value, new_value)

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
var torch_id: int = new_state("torch", 1)

func _ready():
  pass

func start_run():
  get_tree().change_scene_to(level_scene)
  pass

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
  var old_value = state[id]
  var new_value = clamp(old_value + amount, clamp_min, clamp_max)
  if new_value != old_value:
    state[id] = new_value
    emit_signal("on_state_change", old_value, new_value)