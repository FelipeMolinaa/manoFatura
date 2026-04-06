class_name MoneySystem
extends Node

signal money_changed(current_money: int, delta: int)

@export var starting_money := 1000

var money := 0


func _ready() -> void:
	money = starting_money
	money_changed.emit(money, 0)


func can_afford(amount: int) -> bool:
	return money >= amount


func spend(amount: int) -> bool:
	if amount <= 0:
		return true
	if not can_afford(amount):
		return false

	money -= amount
	money_changed.emit(money, -amount)
	return true


func earn(amount: int) -> void:
	if amount <= 0:
		return

	money += amount
	money_changed.emit(money, amount)
