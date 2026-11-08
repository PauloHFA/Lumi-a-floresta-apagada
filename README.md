# Lumi e a Floresta Apagada

Jogo de plataforma 2D de aventura curta desenvolvido para **Godot 4.7 (GDScript)** seguindo integralmente a especificação técnica e artística do projeto.

## Como Abrir e Executar

1. Instale ou baixe o **Godot Engine 4.7** (Standard / GDScript). O executável portátil em `.tools` não faz parte do repositório.
2. Clique em **Importar (Import)** e selecione o arquivo `project.godot` na raiz do projeto.
3. Pressione **F5** (ou clique no botão *Play*) para iniciar pelo fluxo completo (`scenes/main.tscn` -> Menu Principal -> Fases 1 a 4 -> Créditos).
4. Para testar qualquer fase isoladamente, abra a cena em `scenes/levels/level_01.tscn` (até `level_04.tscn`) e pressione **F6**.
5. No menu principal, selecione **Trailer Interativo** para ver a história com as animações de Lumi e escolher como ela responde à sombra.

Durante os diálogos, o jogo pausa, escurece o cenário e aproxima a câmera de quem está falando. Ao final da fala, a câmera retorna ao enquadramento do jogo.

Os testes de rota, combate, abertura cinematográfica e trailer podem ser executados no PowerShell a partir da raiz do projeto. Ajuste `$godot` para o caminho do executável de console do Godot 4.7:

```powershell
$godot = ".tools\godot-4.7\Godot_v4.7-stable_win64_console.exe"
& $godot --headless --path . -s tests\test_stomp_and_level3_route.gd
& $godot --headless --path . -s tests\test_dialogue_cinematics.gd
& $godot --headless --path . -s tests\test_interactive_trailer.gd
```

## Controles (Teclado e Gamepad)

| Ação | Teclado | Gamepad |
| :--- | :--- | :--- |
| **Mover** | `A` / `D` ou Setas | Analógico esquerdo / D-Pad |
| **Pular / Planar** | `Espaço` / `W` / `Seta Cima` | Botão `A` (Xbox) / `Cruz` (PS) |
| **Pulso de Luz** | `J` / `X` / `K` | Botão `X` (Xbox) / `Quadrado` (PS) |
| **Stomp (mergulho)** | `S` / `Seta Baixo` (no ar) | D-Pad para baixo (no ar) |
| **Avançar Diálogo** | `Espaço` / `Enter` / `E` | Botão `A` / `B` |
| **Pausar** | `Esc` / `P` | `Start` |

O Stomp é liberado na fase 2: acerte uma sombra por cima para atordoá-la e ricochetear. Na fase 3, siga o cogumelo azul até o primeiro galho; use o pulo duplo e plane sobre a corrente azul para alcançar as plataformas mais altas.

*As teclas de Pulo e Pulso de Luz podem ser remapeadas diretamente no menu de Configurações ou Pausa.*
