# Andamento do projeto

Arquivo de controle entre as integrantes. Atualize ao terminar sua parte.

## Regra importante sobre o `.mwb`

O `farmacia.mwb` é um arquivo binário — **o Git não consegue mesclar duas
versões dele.** Se duas pessoas editarem ao mesmo tempo, o trabalho de uma
será perdido.

Por isso, uma pessoa por vez:

1. Avise no grupo que vai mexer
2. `git pull` **antes** de abrir o Workbench
3. Edite, salve com Ctrl+S, faça commit e push
4. Avise que terminou

## Feito

- [x] **Entidades e atributos** — Isabela
  8 entidades criadas com todos os campos, tipos, `NOT NULL`, `UNIQUE`,
  `AUTO_INCREMENT` e valores `DEFAULT`:
  `laboratorio`, `principio_ativo`, `medicamento`, `lote`, `farmaceutico`,
  `registro_crf`, `cliente`, `venda`
- [x] Rascunho do `README.md`

## Falta

- [ ] **Criar as duas tabelas N:M** (não use o botão `n:m` do Workbench — ele
      cria só as chaves, sem os atributos próprios, e dá nome genérico)

  ```
  item_venda
    venda_id            INT             -> PK, NN
    medicamento_id      INT             -> PK, NN
    quantidade          INT             -> NN
    preco_unitario      DECIMAL(10,2)   -> NN

  composicao
    medicamento_id      INT             -> PK, NN
    principio_ativo_id  INT             -> PK, NN
    dosagem_mg          DECIMAL(8,2)    -> NN
  ```

- [ ] **Ligar as 10 chaves estrangeiras** (aba *Foreign Keys* da tabela filha)

  | Tabela | Coluna | Aponta para |
  |---|---|---|
  | `medicamento` | `laboratorio_id` | `laboratorio.id` |
  | `medicamento` | `medicamento_referencia_id` | `medicamento.id` (ela mesma) |
  | `registro_crf` | `farmaceutico_id` | `farmaceutico.id` |
  | `lote` | `medicamento_id` | `medicamento.id` |
  | `venda` | `cliente_id` | `cliente.id` |
  | `venda` | `farmaceutico_id` | `farmaceutico.id` |
  | `item_venda` | `venda_id` | `venda.id` |
  | `item_venda` | `medicamento_id` | `medicamento.id` |
  | `composicao` | `medicamento_id` | `medicamento.id` |
  | `composicao` | `principio_ativo_id` | `principio_ativo.id` |

- [ ] **Preencher os nomes das integrantes** no `README.md`
- [ ] **Forward Engineer** para gerar o `.sql`, colar os `ALTER TABLE` com os
      `CHECK` (estão no `README.md`) e rodar no MySQL para confirmar que cria
      sem erro

## Conferir antes de entregar

- [ ] 8 entidades + 2 tabelas N:M no diagrama
- [ ] A linha entre `registro_crf` e `farmaceutico` marcada como **1:1**
      (o Workbench assume `1:n` por padrão — conferir na aba *Foreign Keys*)
- [ ] `item_venda` e `composicao` com **duas** colunas marcadas como PK
- [ ] Linha saindo de `medicamento` e voltando para ela mesma
- [ ] Nenhuma coluna duplicada (ex.: `medicamento_id` e `medicamento_id1`)
- [ ] `medicamento_referencia_id` é o único campo sem `NOT NULL`

## Prazo

**17/09** — entregas posteriores não são aceitas.
