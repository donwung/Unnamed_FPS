extends Node

#Contains all the values necessary to be displayed on the Player's HUD.
#Other nodes will reference this list, and update the values as necessary.

#Considering removing this script, and moving this functionality into PlayerHUD.gd

@export var health = 100
@export var armor = 50
@export var ammo = 2
@export var devilTrigger = 50
