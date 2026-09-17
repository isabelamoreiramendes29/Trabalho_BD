# Sistema de Gerenciamento de Farmácia

Projeto da disciplina de **Banco de Dados — C07**
Modelagem de banco de dados relacional feita no MySQL Workbench.

## Integrantes

- Isabela Moreira Mendes
- Maria Clara Pereira Campos
- Petrus de Souza Matos Pfaffenbach

## O tema

O sistema modela o funcionamento de uma **farmácia**: o catálogo de medicamentos,
quem os fabrica, do que eles são compostos, o controle de lotes e validade, os
farmacêuticos responsáveis pelo atendimento e as vendas feitas aos clientes.

A escolha veio de o domínio ter relacionamentos naturais dos três tipos vistos em
aula, sem precisar forçar nenhum deles:

- um medicamento **genérico** aponta para o medicamento de **referência** — e os
  dois são medicamentos, na mesma tabela;
- um medicamento tem vários **princípios ativos**, e um princípio ativo aparece
  em vários medicamentos diferentes;
- todo farmacêutico tem exatamente **um** registro no Conselho Regional de
  Farmácia (CRF), que é a licença que o autoriza a exercer a profissão.

## As entidades

| Entidade | O que representa |
|---|---|
| `laboratorio` | O fabricante do medicamento |
| `principio_ativo` | A substância que dá efeito ao remédio (ex.: Dipirona Sódica) |
| `medicamento` | O produto vendido, com preço, tarja e estoque |
| `lote` | O lote de fabricação, com data de validade |
| `farmaceutico` | O profissional que atende |
| `registro_crf` | A licença profissional do farmacêutico |
| `cliente` | Quem compra |
| `venda` | A transação realizada |

Mais as tabelas intermediárias `item_venda` e `composicao`, criadas pelos
relacionamentos N:M.

## Os relacionamentos

### 1:1 — `farmaceutico` ↔ `registro_crf`

Cada farmacêutico tem um único registro no CRF, e cada registro pertence a um
único farmacêutico.

A tabela `registro_crf` **não tem `id` próprio**: a coluna `farmaceutico_id` é
chave primária e chave estrangeira ao mesmo tempo. Sendo chave primária ela não
pode se repetir, e é isso que impede um farmacêutico de ter dois registros — o
banco garante a regra sozinho, sem precisar de verificação externa.

A separação em duas tabelas segue o critério visto em aula: os dados de emprego
(admissão, turno) e os dados da licença profissional (número, validade, estado
emissor) são lógicas distintas, e a licença é emitida por um órgão externo à
farmácia.

### 1:N — `laboratorio` → `medicamento`

Um laboratório fabrica vários medicamentos, e cada medicamento tem um único
fabricante. A chave estrangeira fica em `medicamento`, ou seja, no lado "N" —
que é onde ela sempre deve ficar num relacionamento 1:N.

O modelo tem outros relacionamentos 1:N: `medicamento` → `lote`,
`cliente` → `venda` e `farmaceutico` → `venda`.

### N:M — `venda` ↔ `medicamento` e `medicamento` ↔ `principio_ativo`

O modelo relacional não representa N:M diretamente, então cada um desses
relacionamentos gera uma tabela intermediária:

- **`item_venda`** — uma venda leva vários medicamentos, e um medicamento é
  vendido em várias vendas diferentes.
- **`composicao`** — um medicamento tem vários princípios ativos, e um princípio
  ativo entra na fórmula de vários medicamentos.

As duas recebem nomes próprios, e não o nome genérico que a ferramenta sugere a
partir das tabelas de origem.

### Auto-relacionamento — `medicamento` → `medicamento`

O campo `medicamento_referencia_id` aponta para a própria tabela `medicamento`:
é assim que o genérico se liga ao medicamento de referência.

Ele é o **único campo do modelo que aceita NULL**, e isso é proposital — um
medicamento de referência não é genérico de ninguém, então ali a ausência de
valor é a própria informação. É a diferença entre NULL e zero vista em aula:
não é "referência zero", é "não tem referência".

## Decisões de modelagem

**`CHAR` x `VARCHAR`** — `CHAR` nos campos de tamanho fixo (`cpf` com 11
caracteres, `cnpj` com 14, `uf` com 2) e `VARCHAR` onde o tamanho varia (nomes,
telefone). Usar `VARCHAR` num campo fixo desperdiça a verificação de tamanho que
o `CHAR` dá de graça.

**`DECIMAL` e não `FLOAT` para dinheiro** — `FLOAT` armazena valores
aproximados e acumula erro de arredondamento a cada operação. Em preço isso é
inaceitável, então `preco` e `valor_total` são `DECIMAL`.

**`BOOLEAN` em `exigencia_receita`** — guardar "sim" ou "não" em texto livre
permitiria "Sim", "SIM", "s" e "yes" convivendo na mesma coluna, tornando as
consultas não confiáveis. O MySQL armazena `BOOLEAN` como `TINYINT(1)`, com 1
para verdadeiro e 0 para falso.

**`DATE` e `TIME` separados em `venda`** — a data e a hora da venda ficam em
campos distintos, usando apenas os tipos apresentados em aula.

**`ENUM` nos campos de lista fechada** — `tarja`, `turno` e `forma_pagamento`
só aceitam um conjunto predefinido de valores, o que impede digitação livre.

**`UNIQUE` em `cpf`, `cnpj`, `numero_crf` e `codigo`** — são identificadores do
mundo real que não podem se repetir, mas que não são a chave primária da tabela.

**`DEFAULT` em `tarja`, `exigencia_receita` e `quantidade_estoque`** — os
valores mais frequentes já vêm preenchidos, evitando digitação repetida no
cadastro.

## Restrições CHECK

O editor de modelo do MySQL Workbench não permite declarar `CHECK` diretamente
no diagrama. As restrições abaixo devem ser aplicadas no script gerado pelo
Forward Engineer:

```sql
ALTER TABLE medicamento ADD CHECK (preco >= 0);
ALTER TABLE medicamento ADD CHECK (quantidade_estoque >= 0);
ALTER TABLE lote ADD CHECK (quantidade >= 0);
ALTER TABLE venda ADD CHECK (valor_total >= 0);
```

## Como abrir o modelo

No MySQL Workbench: **File > Open Model** e escolha `farmacia.mwb`.

Para gerar o script SQL a partir dele: **Database > Forward Engineer**.
