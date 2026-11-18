# Pendências — Lumi e a Floresta Apagada (`Jogo-Plataforma-Lumi`)

Este documento consolida o estado técnico do jogo, separando os sistemas concluídos e verificados em testes automatizados do backlog de melhorias e dependências de publicação comercial.

---

## 1. Concluído e Homologado (Versão 1.0 — Godot 4.7)
- [x] **Motor & Física de Movimentação (CA-01 e CA-02):**
  - Aceleração (`0.133s <= 0.15s`) e frenagem rápida (`0.090s <= 0.10s`).
  - Pulo de altura variável com redução de 50.2% (exigência >= 40%) ao soltar precocemente.
  - Mecânica de planar (*glide*) e limite de morte por queda ajustado (`y > 356.0`).
- [x] **Mecânicas Avançadas & Expansão:**
  - *Dash de Luz:* Impulso horizontal de 48.3 px com partículas e cooldown.
  - *Stomp (mergulho aéreo):* Desbloqueado na Fase 2 para atordoar sombras por cima com ricochete dinâmico.
  - *Cogumelo Trampolim:* Impulso vertical calibrado (`vy = -435.0`).
  - *Updrafts / Correntes de Vento:* Elevação aerodinâmica na Fase 3.
  - Cristais de luz, fragmentos (*shards*) e fagulhas colecionáveis (*sparks*).
- [x] **Narrativa & Apresentação:**
  - Sistema de diálogos cinemáticos com escurecimento de cenário, pausa de física e foco de câmera no interlocutor.
  - Trailer interativo no Menu Principal com árvore de decisão e cutscenes 4.7.
- [x] **Persistência & Áudio:**
  - `SaveSystem` gravando progresso entre fases, desbloqueio de pulso/dash e níveis de brilho.
  - `AudioManager` com mixagem multicanal (`default_bus_layout.tres`) e SFX/BGM integrados.
- [x] **Suíte de Testes Automatizados Headless (4/4 suítes):**
  - `tests/test_acceptance_criteria.gd` (Critérios CA-01 a CA-10).
  - `tests/test_dialogue_cinematics.gd` (Controle de câmera e pausa cinemática).
  - `tests/test_interactive_trailer.gd` (Transição e lógica de escolhas).
  - `tests/test_stomp_and_level3_route.gd` (Mecânica de stomp, rotas de pulo duplo e vento).
- [x] **Esteira CI/CD:** Workflow `.github/workflows/godot-ci.yml` executando todos os testes e cold-boot em Godot 4.7.2 headless no GitHub Actions.

---

## 2. Melhorias Futuras Opcionais (Backlog de Engenharia)
- [ ] **Integração com Gamepad Rumble:** Habilitar feedback tátil em controles Xbox/PlayStation durante o Stomp e o Pulso de Luz.
- [ ] **Modo Speedrun / Timer na HUD:** Cronômetro de precisão na interface com registro de *best time* por fase no arquivo de save.
- [ ] **Controles Touchscreen:** Adaptar layout de botões na tela para exportação experimental Android/Web.

---

## 3. Dependências Externas (Publicação & Distribuição)
- [ ] **Export Templates Godot 4.7:** Download dos templates oficiais para geração dos executáveis finais (.exe para Windows e binário Linux).
- [ ] **Página no Itch.io / Steam:** Criação de arte de capa, banners de cápsula e cadastro para distribuição pública.
