# Sistema de Gerenciamento de Farmácia

Projeto da disciplina de **Banco de Dados — C07**
Modelagem de banco de dados relacional em MySQL Workbench.

## Integrantes

- Isabela Moreira Mendes
- *(preencher)*
- *(preencher)*

## O tema

O sistema modela o funcionamento de uma **farmácia**: o catálogo de medicamentos,
quem os fabrica, do que eles são compostos, o controle de lotes e validade, os
farmacêuticos responsáveis pelo atendimento e as vendas feitas aos clientes.

A escolha veio de o domínio ter relacionamentos naturais dos três tipos, sem
precisar forçar nenhum deles:

- um medicamento **genérico** aponta para o medicamento de **referência** —
  e os dois são medicamentos, na mesma tabela;
- um medicamento tem vários **princípios ativos**, e um princípio ativo aparece
  em vários medicamentos;
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

## Os relacionamentos

### 1:1 — `farmaceutico` ↔ `registro_crf`

Cada farmacêutico tem um único registro no CRF, e cada registro pertence a um
único farmacêutico.

A tabela `registro_crf` **não tem `id` próprio**: o `farmaceutico_id` é chave
primária e chave estrangeira ao mesmo tempo. Sendo chave primária ele não pode
repetir, e é isso que impede um farmacêutico de ter dois registros — o banco
garante a regra sozinho, sem precisar de nenhuma verificação extra.

A separação em duas tabelas segue o critério visto em aula: os dados de emprego
(admissão, turno) e os dados da licença profissional (número, validade, estado
emissor) são lógicas distintas, e a licença vem de um órgão externo à farmácia.

### 1:N — `laboratorio` → `medicamento`

Um laboratório fabrica vários medicamentos, e cada medicamento tem um único
fabricante. A chave estrangeira fica em `medicamento`, no lado "N".

Também são 1:N: `medicamento` → `lote`, `cliente` → `venda` e
`farmaceutico` → `venda`.

### N:M — `venda` ↔ `medicamento` e `medicamento` ↔ `principio_ativo`

Como o modelo relacional não representa N:M diretamente, cada um desses
relacionamentos gera uma tabela intermediária:

- **`item_venda`** — uma venda leva vários medicamentos, e um medicamento
  aparece em várias vendas. Guarda `quantidade` e `preco_unitario`, porque o
  preço praticado na venda precisa ficar registrado mesmo que o preço de
  tabela mude depois.
- **`composicao`** — um medicamento tem vários princípios ativos, e um
  princípio ativo está em vários medicamentos. Guarda a `dosagem_mg` de cada
  substância na fórmula.

As duas têm **chave primária composta** pelas duas chaves estrangeiras.

### Auto-relacionamento — `medicamento` → `medicamento`

O campo `medicamento_referencia_id` aponta para a própria tabela `medicamento`:
é como o genérico se liga ao medicamento de referência.

Ele é o **único campo do modelo que aceita NULL**, e isso é proposital — um
medicamento de referência não é genérico de ninguém, então ali a ausência de
valor é a informação. É a diferença entre NULL e zero: não é "referência zero",
é "não tem referência".

## Decisões de modelagem

**`CHAR` x `VARCHAR`** — `CHAR` nos campos de tamanho fixo (`cpf` com 11,
`cnpj` com 14, `uf` com 2) e `VARCHAR` onde o tamanho varia (nomes, telefone,
e-mail).

**`DECIMAL` e não `FLOAT` para dinheiro** — `FLOAT` armazena valores
aproximados e acumula erro de arredondamento. Em preço isso é inaceitável.

**`BOOLEAN` em `exigencia_receita`** — guardar "sim" ou "não" em texto livre
permitiria "Sim", "SIM", "s", "yes" e qualquer variação, tornando as consultas
não confiáveis. O MySQL armazena `BOOLEAN` como `TINYINT(1)`, com 1 para
verdadeiro e 0 para falso.

**`DATE` e `TIME` separados em `venda`** — a data e a hora da venda ficam em
campos distintos, usando apenas os tipos apresentados em aula.

**`UNIQUE` em `cpf`, `cnpj`, `numero_crf` e `codigo`** — são identificadores
do mundo real que não podem se repetir, mas que não são a chave primária da
tabela.

## Restrições CHECK

O editor de modelo do MySQL Workbench não permite declarar `CHECK` diretamente
no diagrama. As restrições abaixo devem ser aplicadas no script gerado pelo
Forward Engineer:

```sql
ALTER TABLE medicamento ADD CHECK (preco >= 0);
ALTER TABLE medicamento ADD CHECK (quantidade_estoque >= 0);
ALTER TABLE lote ADD CHECK (quantidade >= 0);
ALTER TABLE venda ADD CHECK (valor_total >= 0);
ALTER TABLE item_venda ADD CHECK (quantidade > 0);
ALTER TABLE composicao ADD CHECK (dosagem_mg > 0);
```

## Como abrir o modelo

No MySQL Workbench: **File > Open Model** e escolha `farmacia.mwb`.

Para gerar o script SQL a partir dele: **Database > Forward Engineer**.
