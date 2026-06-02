shader_type canvas_item;

// Controla o fechamento/abertura da transição (0.0 = totalmente visível, 1.0 = tela preta)
uniform float progress : hint_range(0.0, 1.0) = 0.0;

// Tamanho dos blocos quadriculados na tela (em pixels)
uniform vec2 size = vec2(32.0, 32.0);

void fragment() {
    // Divide as coordenadas UV em blocos discretos (pixelizados)
    vec2 uv = floor(UV * size) / size;

    // Cria um padrão quadriculado pseudo-aleatório baseado na posição do bloco
    float value = fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453);

    // Se o progresso for maior que o valor do bloco, ele pinta de preto (ou a cor do ColorRect)
    if (value < progress) {
        COLOR = vec4(0.0, 0.0, 0.0, 1.0); // Preto absoluto
    } else {
        COLOR = vec4(0.0, 0.0, 0.0, 0.0); // Transparente
    }
}
