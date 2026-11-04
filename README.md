# Jogo

Protótipo de um jogo de extração com magia. A ideia é entrar numa masmorra, saquear equipamento e tentar extrair com os itens. O jogo usa uma câmera em terceira pessoa. A versão atual é uma arena local de testes, com três baús e um personagem jogável.

## Como rodar

Importe `project.godot` na Godot **4.7.2**. Aguarde a importação dos recursos e pressione **F5**. A cena inicial é `masmorra.tscn`.

## Controles

| Controle | Ação |
| --- | --- |
| WASD, Shift, Espaço | Andar, correr e pular |
| Mouse | Mover a câmera e mirar |
| Clique esquerdo / direito | Ataque básico / habilidade da arma |
| E perto de um baú | Abrir a tela do baú |
| E ou B perto de itens no chão | Abrir a mochila com a lista de itens próximos |
| B longe do saque | Abrir apenas a mochila e o equipamento |
| 1, 2, 3 | Equipar varinha, cajado e grimório depois de coletá-los |
| Esc | Fechar o inventário ou liberar o cursor durante o jogo |

Arraste itens entre as grades de mochila e baú. Use a rodinha sobre o item ou durante o arrasto para girá-lo. O clique direito sobre o saque recolhe o item no primeiro espaço livre. Dê duplo clique numa peça da mochila ou arraste-a até o espaço do corpo correspondente para equipá-la. Dê duplo clique num espaço equipado para devolver a peça à mochila, se houver lugar. Para largar algo, arraste-o até **Soltar no chão**.

## Estado do protótipo

- O personagem começa sem arma e com a mochila vazia. Os três baús contêm as três armas e seis peças de roupa ou acessórios.
- A varinha dispara um projétil e faz uma rajada de quatro tiros. O cajado cria zonas no chão. O grimório arremessa uma pedra e conjura um martelo. O básico recarrega em 0,35 s e a habilidade em 10 s. Na rajada, a recarga começa após o último tiro.
- A mochila tem 5 × 4 células. Baús e chão mantêm os itens durante a sessão. Os espaços de equipamento aparecem ao redor da prévia 3D do mago.
- Chapéu dá +15 mana, anel +8 poder, manto +10 defesa, botas +1 m/s, calças +20 vida e colar +10 mana. As botas já afetam o movimento. Vida, mana, defesa e poder estão registrados na ficha e ainda aguardam a lógica de combate correspondente.
- Os efeitos de ataque funcionam para teste visual. Ainda faltam alvos, dano, classes jogáveis, a masmorra, o portal de extração, persistência e multiplayer.

## Decisões para continuar

- Cada classe terá **três habilidades próprias**. A arma equipada fornece **um ataque básico e uma habilidade**.
- As armas são **varinha, cajado e grimório**. Cada tipo tem um estilo de ataque diferente.
- A próxima etapa proposta é adicionar um alvo de teste com vida e conectar dano, atributos e efeitos das três armas antes de montar uma incursão completa.

## Créditos

O modelo do mago e as armas incluídas vêm do [KayKit Adventurers, de Kay Lousberg](https://kaylousberg.itch.io/kaykit-adventurers), sob licença CC0. As peças de equipamento de teste são geradas no projeto.
