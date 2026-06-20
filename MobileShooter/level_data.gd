# level_data.gd
# Defines all 20 levels. Each level has:
#   enemy_count   — total enemies to kill to complete the level (boss counts as 1)
#   scout_ratio   — fraction of enemies that are Scouts (rest are Destroyers)
#   boss          — true if a boss spawns at the START of this level
#   boss_hp       — hit points for the boss on this level
#   spawn_interval— seconds between enemy spawn waves
#   enemy_speed   — base speed multiplier for all enemies this level
#   coins_reward  — coins awarded on level completion
#   score_per_kill— score per regular enemy kill

extends Node

const LEVELS: Array[Dictionary] = [
	{ "enemy_count": 8,  "scout_ratio": 1.0, "boss": false, "boss_hp": 0,  "spawn_interval": 2.2, "enemy_speed": 1.0,  "coins_reward": 5,  "score_per_kill": 1 },
	{ "enemy_count": 10, "scout_ratio": 1.0, "boss": false, "boss_hp": 0,  "spawn_interval": 2.0, "enemy_speed": 1.05, "coins_reward": 5,  "score_per_kill": 1 },
	{ "enemy_count": 12, "scout_ratio": 0.8, "boss": false, "boss_hp": 0,  "spawn_interval": 1.9, "enemy_speed": 1.1,  "coins_reward": 6,  "score_per_kill": 1 },
	{ "enemy_count": 14, "scout_ratio": 0.7, "boss": false, "boss_hp": 0,  "spawn_interval": 1.8, "enemy_speed": 1.15, "coins_reward": 6,  "score_per_kill": 1 },
	{ "enemy_count": 10, "scout_ratio": 0.6, "boss": true,  "boss_hp": 8,  "spawn_interval": 1.8, "enemy_speed": 1.2,  "coins_reward": 15, "score_per_kill": 2 },
	{ "enemy_count": 16, "scout_ratio": 0.65,"boss": false, "boss_hp": 0,  "spawn_interval": 1.7, "enemy_speed": 1.25, "coins_reward": 7,  "score_per_kill": 2 },
	{ "enemy_count": 18, "scout_ratio": 0.6, "boss": false, "boss_hp": 0,  "spawn_interval": 1.6, "enemy_speed": 1.3,  "coins_reward": 8,  "score_per_kill": 2 },
	{ "enemy_count": 18, "scout_ratio": 0.5, "boss": false, "boss_hp": 0,  "spawn_interval": 1.5, "enemy_speed": 1.35, "coins_reward": 8,  "score_per_kill": 2 },
	{ "enemy_count": 20, "scout_ratio": 0.5, "boss": false, "boss_hp": 0,  "spawn_interval": 1.4, "enemy_speed": 1.4,  "coins_reward": 9,  "score_per_kill": 2 },
	{ "enemy_count": 14, "scout_ratio": 0.5, "boss": true,  "boss_hp": 14, "spawn_interval": 1.4, "enemy_speed": 1.45, "coins_reward": 20, "score_per_kill": 3 },
	{ "enemy_count": 22, "scout_ratio": 0.45,"boss": false, "boss_hp": 0,  "spawn_interval": 1.3, "enemy_speed": 1.5,  "coins_reward": 10, "score_per_kill": 3 },
	{ "enemy_count": 22, "scout_ratio": 0.4, "boss": false, "boss_hp": 0,  "spawn_interval": 1.25,"enemy_speed": 1.55, "coins_reward": 10, "score_per_kill": 3 },
	{ "enemy_count": 24, "scout_ratio": 0.4, "boss": false, "boss_hp": 0,  "spawn_interval": 1.2, "enemy_speed": 1.6,  "coins_reward": 11, "score_per_kill": 3 },
	{ "enemy_count": 24, "scout_ratio": 0.35,"boss": false, "boss_hp": 0,  "spawn_interval": 1.1, "enemy_speed": 1.65, "coins_reward": 12, "score_per_kill": 3 },
	{ "enemy_count": 16, "scout_ratio": 0.4, "boss": true,  "boss_hp": 20, "spawn_interval": 1.1, "enemy_speed": 1.7,  "coins_reward": 25, "score_per_kill": 4 },
	{ "enemy_count": 26, "scout_ratio": 0.3, "boss": false, "boss_hp": 0,  "spawn_interval": 1.0, "enemy_speed": 1.75, "coins_reward": 13, "score_per_kill": 4 },
	{ "enemy_count": 26, "scout_ratio": 0.3, "boss": false, "boss_hp": 0,  "spawn_interval": 0.95,"enemy_speed": 1.8,  "coins_reward": 14, "score_per_kill": 4 },
	{ "enemy_count": 28, "scout_ratio": 0.25,"boss": false, "boss_hp": 0,  "spawn_interval": 0.9, "enemy_speed": 1.85, "coins_reward": 15, "score_per_kill": 4 },
	{ "enemy_count": 28, "scout_ratio": 0.25,"boss": false, "boss_hp": 0,  "spawn_interval": 0.85,"enemy_speed": 1.9,  "coins_reward": 16, "score_per_kill": 5 },
	{ "enemy_count": 20, "scout_ratio": 0.3, "boss": true,  "boss_hp": 30, "spawn_interval": 0.85,"enemy_speed": 2.0,  "coins_reward": 50, "score_per_kill": 5 },
]

const MAX_LEVEL: int = 20


func get_level(level_number: int) -> Dictionary:
	var idx := clampi(level_number - 1, 0, MAX_LEVEL - 1)
	return LEVELS[idx]
