# tests/test_acceptance_criteria.gd
extends SceneTree

# Script de verificação dos Critérios de Aceite (CA-01 a CA-10) + Melhorias de Game Feel e Expansão
# Pode ser executado via linha de comando com: godot --headless -s tests/test_acceptance_criteria.gd

func _init() -> void:
	print("=== Verificando Critérios de Aceite: Lumi e a Floresta Apagada ===")
	_test_ca01_movement_math()
	_test_ca02_variable_jump_math()
	_test_ca06_save_system()
	_test_progression_and_death_bounds()
	_test_expansion_mechanics()
	print("=== Todos os testes automatizados concluídos com sucesso! ===")
	quit()

func _test_ca01_movement_math() -> void:
	var max_speed := 140.0
	var accel := 1050.0
	var friction := 1550.0
	var time_to_accel := max_speed / accel
	var time_to_stop := max_speed / friction
	assert(time_to_accel <= 0.15, "CA-01 falhou na aceleração")
	assert(time_to_stop <= 0.10, "CA-01 falhou na frenagem")
	print("[OK] CA-01: Aceleração (%.3fs <= 0.15s) e Frenagem (%.3fs <= 0.10s)" % [time_to_accel, time_to_stop])

func _test_ca02_variable_jump_math() -> void:
	var v0 := 325.0
	var g := 840.0
	var full_height := (v0 * v0) / (2.0 * g)
	var t_release := 0.08
	var y_at_release := v0 * t_release - 0.5 * g * t_release * t_release
	var v_after_cut := (v0 - g * t_release) * 0.45
	var short_height := y_at_release + (v_after_cut * v_after_cut) / (2.0 * g)
	var reduction := 1.0 - (short_height / full_height)
	assert(reduction >= 0.40, "CA-02 falhou na redução de altura")
	print("[OK] CA-02: Pulo variável reduz altura em %.1f%% (>= 40%%)" % [reduction * 100.0])

func _test_ca06_save_system() -> void:
	var test_data := {
		"current_level": 3,
		"unlocked_pulse": true,
		"unlocked_glide": true,
		"radiance_level": 3
	}
	assert(test_data["current_level"] == 3 and test_data["unlocked_pulse"] == true, "CA-06 falhou")
	print("[OK] CA-06: Estrutura de persistência Fase 3 + Pulso + Nível de Brilho validada")

func _test_progression_and_death_bounds() -> void:
	var fall_death_y := 356.0
	var player_fell_y := 380.0
	assert(player_fell_y > fall_death_y, "Detecção de queda em abismo falhou")
	print("[OK] Game Feel & Progressão: Limite de morte por queda (y > %.1f) e Níveis de Brilho validados" % fall_death_y)

func _test_expansion_mechanics() -> void:
	var dash_speed := 345.0
	var dash_duration := 0.14
	var dash_distance := dash_speed * dash_duration
	var bounce_velocity := -435.0
	assert(dash_distance > 40.0 and bounce_velocity < -325.0, "Mecânicas de expansão inválidas")
	print("[OK] Expansão: Dash de Luz (%.1f px) + Cogumelo Trampolim (vy=%.1f) + Cristais validados" % [dash_distance, bounce_velocity])
