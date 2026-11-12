## Entrega 2 — Script SQL

O script completo está no arquivo `farmacia_script_completo.sql`. Ele cria o banco
`farmacia` do zero, então pode ser executado inteiro no MySQL Workbench quantas
vezes for preciso.

### 1. Estrutura do Banco de Dados

laboratorio: é a tabela que guarda os dados correspondentes aos laboratórios que produzem os remédios.

principio_ativo: registra os princípios ativos dos medicamentos e suas descrições.

medicamento: contém informações sobre os medicamentos.

lote: armazena informações sobre os lotes dos medicamentos.

medicamento_has_principio_ativo: tabela intermediária responsável por relacionar medicamentos e princípios ativos.

As tabelas utilizam chaves primárias para identificar seus registros e chaves estrangeiras para estabelecer os relacionamentos entre elas.

Na segunda etapa do desenvolvimento do banco de dados `farmacia`, a modelagem foi expandida para contemplar o cadastro de pessoas (farmacêuticos e clientes), seus registros profissionais e o vínculo de consumo de medicamentos. Inicialmente, foram executados comandos `DROP TABLE IF EXISTS` para remover a tabela obsoleta `composição` e reestruturar a tabela `registro_crf`, garantindo a integridade do esquema antes da criação das novas entidades:

- **registro_crf:** armazena os dados do registro profissional de cada farmacêutico no Conselho Regional de Farmácia (CRF), contendo `numero_crf` (com restrição `UNIQUE`), `uf` e `data_validade`. A coluna `farmaceutico_id` atua simultaneamente como chave primária e chave estrangeira referenciando `farmaceutico(id)`.
- **cliente:** guarda os dados cadastrais dos clientes da farmácia, incluindo `id` (chave primária com `AUTO_INCREMENT`), `nome`, `cpf` (único e obrigatório), `telefone` e `data_nascimento`.
- **medicamento_has_cliente:** tabela intermediária responsável por registrar a associação entre clientes e medicamentos adquiridos ou vinculados, utilizando chave primária composta por `medicamento_id` e `cliente_id`.

Todas as chaves estrangeiras das tabelas criadas foram configuradas com as regras de integridade referencial `ON UPDATE CASCADE` (propagando automaticamente atualizações de identificadores) e `ON DELETE RESTRICT` (impedindo a exclusão de registros pai enquanto houver vínculos ativos).

| Tabela | Chave Primária (PK) | Chaves Estrangeiras / Restrições | Finalidade Principal |
|---|---|---|---|
| `registro_crf` | farmaceutico_id | FK -> farmaceutico(id); UNIQUE(numero_crf) | Registro profissional CRF do farmacêutico (1:1) |
| `cliente` | id (AUTO_INCREMENT) | UNIQUE(cpf); nome NOT NULL | Cadastro de clientes da farmácia |
| `medicamento_has_cliente` | (medicamento_id, cliente_id) | FK -> medicamento(id); FK -> cliente(id) | Tabela associativa Cliente x Medicamento (N:M) |

| Tabela | O que guarda |
|---|---|
| `venda` | Cada venda feita: data, hora, valor total, forma de pagamento, o cliente que comprou e o farmacêutico que atendeu |
| `item_venda` | Os medicamentos de cada venda, com a quantidade e o preço unitário. É a tabela intermediária do N:M venda × medicamento |

Restrições e decisões das tabelas de venda:

- **`ENUM`** em `forma_pagamento`: só aceita `'DINHEIRO'`, `'PIX'` ou `'CARTAO'`.
- **`CHECK`**: `valor_total >= 0` em `venda` e `quantidade > 0` em `item_venda`,
  porque não existe item vendido com zero unidades.
- **`DEFAULT 0`** em `valor_total`: uma venda nova começa zerada e vai somando os
  itens (ver a procedure).
- **`DATE` e `TIME` separados** em `data_venda` e `hora_venda`, como no modelo.
- **Colunas novas em `item_venda`:** no modelo da entrega 1, a tabela só tinha as
  chaves. Foram acrescentadas:
  - `quantidade`: sem ela, não dá para saber quantas unidades foram vendidas nem
    baixar o estoque;
  - `preco_unitario`: guarda o preço **do dia da venda**. Se o preço do medicamento
    mudar depois, como no reajuste feito com `UPDATE`, as vendas antigas continuam
    com o valor que foi cobrado.

### 2. Inserção de Dados no Banco

Foi utilizado o INSERT INTO para inserir os registros iniciais.

Foram cadastrados quatro laboratórios, seis princípios ativos, cinco medicamentos e onze lotes.

Também foram inseridos registros na tabela intermediária, relacionando cada medicamento ao seu respectivo princípio ativo.

Foi utilizado o comando `INSERT INTO` para popular as tabelas referentes aos profissionais, clientes e suas respectivas associações no banco de dados:

- **Farmacêuticos (farmaceutico):** foram cadastrados três profissionais — Ana Beatriz Costa (turno `MANHA`, laboratório 1), Rafael Mendes Lima (turno `TARDE`, laboratório 2) e Juliana Ferreira Alves (turno `NOITE`, laboratório 1).
- **Registros CRF (registro_crf):** foram inseridos três registros profissionais (`CRF-MG-10001`, `CRF-MG-10002` e `CRF-MG-10003`), todos vinculados à UF `MG` e atribuídos individualmente aos farmacêuticos de ID 1, 2 e 3, com datas de validade distintas.
- **Clientes (cliente):** foram cadastrados quatro clientes — Mariana Oliveira, Lucas Martins Souza, Camila Ribeiro Santos e Pedro Henrique Alves — com seus respectivos CPFs, telefones de contato e datas de nascimento.
- **Associações (medicamento_has_cliente):** foram inseridos seis registros na tabela intermediária, relacionando cada cliente aos medicamentos correspondentes (por exemplo, o cliente 1 vinculado aos medicamentos 1 e 2, e o medicamento 1 associado tanto ao cliente 1 quanto ao cliente 3).

| Tabela | Registros |
|---|---|
| `venda` | 6 |
| `item_venda` | 10 |

Algumas vendas têm mais de um medicamento, o que mostra o N:M na prática. O
`valor_total` de cada venda é a soma dos seus itens (`quantidade × preco_unitario`).
A venda 6 foi cadastrada para ser cancelada no exemplo de `DELETE`.

### 3. Relacionamentos (1:1, 1:N e N:M)

**Relacionamento entre Medicamentos e Princípios Ativos (N:M)**

O relacionamento entre medicamentos e princípios ativos é do tipo muitos para muitos (N:M).

Isso significa que um medicamento pode possuir mais de um princípio ativo e que um mesmo princípio ativo pode estar presente em diferentes medicamentos.

Para representar esse relacionamento, foi criada a tabela ***medicamento_has_principio_ativo***, que possui duas chaves estrangeiras: ***medicamento_id*** e ***principio_ativo_id***.

A chave primária composta pelas duas colunas impede a repetição da mesma associação.

**Relacionamentos Implementados (1:1 e N:M)**

Nesta etapa, dois tipos fundamentais de cardinalidade relacional foram modelados e aplicados:

**Relacionamento 1:1 entre Farmacêutico e Registro CRF:** cada farmacêutico cadastrado possui exatamente um registro profissional CRF correspondente, e cada registro CRF pertence a um único farmacêutico. Estruturalmente, essa regra é garantida na tabela `registro_crf` pelo fato de a coluna `farmaceutico_id` ser definida como chave primária e, ao mesmo tempo, chave estrangeira para `farmaceutico(id)`, impedindo que um mesmo profissional possua múltiplos registros duplicados na tabela.

**Relacionamento N:M entre Clientes e Medicamentos:** o relacionamento entre `cliente` e `medicamento` é do tipo muitos para muitos (N:M). Isso significa que um cliente pode adquirir ou utilizar diversos medicamentos e que um mesmo medicamento pode estar associado a vários clientes. Para representar esse vínculo, foi criada a tabela `medicamento_has_cliente`, que contém as chaves estrangeiras `medicamento_id` e `cliente_id`. A chave primária composta pelas duas colunas impede a repetição da mesma associação.

**Relacionamentos das vendas (1:N e N:M)**

- `venda.cliente_id` → `cliente(id)`: um cliente faz várias compras, e cada venda
  é de um único cliente (1:N).
- `venda.farmaceutico_id` → `farmaceutico(id)`: um farmacêutico atende várias
  vendas, e cada venda tem um único farmacêutico responsável (1:N).
- `item_venda` liga `venda` e `medicamento` (N:M): uma venda leva vários
  medicamentos, e um medicamento aparece em várias vendas. A chave primária composta
  `(venda_id, medicamento_id)` impede repetir o mesmo remédio duas vezes na mesma
  venda; para levar mais unidades, aumenta-se a `quantidade`.

### 4. Consultas usando o JOIN

Para consultar a qual laboratório cada medicamento pertence e quais são seus princípios ativos, foi utilizado o comando "SELECT" em conjunto com "INNER JOIN".

A consulta reúne informações das tabelas "medicamento", "medicamento_has_principio_ativo", "principio_ativo" e "laboratorio", permitindo visualizar esses dados em um único resultado.

Para consultar os dados cadastrais dos farmacêuticos juntamente com as informações de sua habilitação profissional em um único resultado, foi utilizado o comando `SELECT` em conjunto com `INNER JOIN`.

A consulta reúne colunas das tabelas `farmaceutico` (identificada pelo alias `f`) e `registro_crf` (alias `r`), realizando a junção por meio da condição `r.farmaceutico_id = f.id`. Ao final, a cláusula `ORDER BY f.nome` organiza a listagem em ordem alfabética pelo nome do farmacêutico, exibindo identificador, nome, CPF, data de admissão, turno, número do CRF, UF e data de validade.

**1:N — cliente → venda:** quantas compras cada cliente fez e quanto gastou no
total.

```sql
SELECT
    c.nome AS cliente,
    COUNT(v.id) AS quantidade_compras,
    COALESCE(SUM(v.valor_total), 0) AS total_gasto
FROM cliente AS c
LEFT JOIN venda AS v
    ON v.cliente_id = c.id
GROUP BY c.id, c.nome
ORDER BY total_gasto DESC;
```

- `LEFT JOIN`: mostra todos os clientes, inclusive quem ainda não comprou nada.
- `COUNT` e `SUM` com `GROUP BY`: juntam as vendas de cada cliente numa linha só.
- `COALESCE(..., 0)`: para quem não tem compra, o `SUM` daria `NULL`; o
  `COALESCE` mostra 0 no lugar.

| cliente | quantidade_compras | total_gasto |
|---|---|---|
| Mariana Oliveira | 2 | 89.40 |
| Camila Ribeiro Santos | 1 | 60.00 |
| Pedro Henrique Alves | 1 | 47.70 |
| Lucas Martins Souza | 1 | 43.00 |
| Fernanda Lopes Carvalho | 1 | 28.40 |

**Busca completa de cada venda:** quem comprou, quem atendeu e o que levou. A
consulta junta cinco tabelas: os dois relacionamentos 1:N (cliente → venda e
farmacêutico → venda) e o N:M venda × medicamento.

```sql
SELECT
    v.id AS venda,
    v.data_venda,
    c.nome AS cliente,
    f.nome AS farmaceutico,
    m.nome_comercial AS medicamento,
    iv.quantidade,
    iv.preco_unitario,
    iv.quantidade * iv.preco_unitario AS subtotal
FROM venda AS v
INNER JOIN cliente AS c ON c.id = v.cliente_id
INNER JOIN farmaceutico AS f ON f.id = v.farmaceutico_id
INNER JOIN item_venda AS iv ON iv.venda_id = v.id
INNER JOIN medicamento AS m ON m.id = iv.medicamento_id
ORDER BY v.data_venda, v.id;
```

| venda | data_venda | cliente | farmaceutico | medicamento | quantidade | preco_unitario | subtotal |
|---|---|---|---|---|---|---|---|
| 1 | 2026-11-02 | Mariana Oliveira | Ana Beatriz Costa | Novalgina | 2 | 12.50 | 25.00 |
| 1 | 2026-11-02 | Mariana Oliveira | Ana Beatriz Costa | Tylenol | 1 | 15.90 | 15.90 |
| 2 | 2026-11-03 | Lucas Martins Souza | Rafael Mendes Lima | Advil | 1 | 18.00 | 18.00 |
| 2 | 2026-11-03 | Lucas Martins Souza | Rafael Mendes Lima | Amoxil | 1 | 25.00 | 25.00 |
| 3 | 2026-11-04 | Camila Ribeiro Santos | Juliana Ferreira Alves | Cozaar | 2 | 30.00 | 60.00 |
| 4 | 2026-11-05 | Mariana Oliveira | Carlos Eduardo Rocha | Novalgina | 1 | 12.50 | 12.50 |
| 4 | 2026-11-05 | Mariana Oliveira | Carlos Eduardo Rocha | Advil | 2 | 18.00 | 36.00 |
| 5 | 2026-11-06 | Pedro Henrique Alves | Beatriz Nogueira Lima | Tylenol | 3 | 15.90 | 47.70 |
| 6 | 2026-11-07 | Fernanda Lopes Carvalho | Ana Beatriz Costa | Novalgina | 1 | 12.50 | 12.50 |
| 6 | 2026-11-07 | Fernanda Lopes Carvalho | Ana Beatriz Costa | Tylenol | 1 | 15.90 | 15.90 |

### 5. FUNCTION

Foi criada uma FUNCTION para averiguar se o estoque tem determinado medicamento disponível. Para isso ele averigua:

- se, a quantidade do medicamento é maior do que 0, ele retorna ‘DISPONIVEL’
- se, a quantidade do medicamento é igual a 0, ele retorna ‘INDISPONIVEL’.

A função foi testada com os valores 0 e 50. Também foi utilizada em uma consulta na tabela lote, permitindo verificar a situação do estoque de cada lote.

### 6. VIEW (Consulta Consolidada de Farmacêuticos e CRF)

Foi criada a visão `vw_farmaceuticos_crf` (utilizando `CREATE OR REPLACE VIEW`) com o objetivo de encapsular e simplificar a consulta integrada entre farmacêuticos, seus registros CRF e o laboratório ao qual estão vinculados.

A estrutura da visão realiza dois `INNER JOIN` sucessivos conectando as tabelas `farmaceutico`, `registro_crf` e `laboratorio`. Além disso, incorpora uma expressão condicional `CASE WHEN` para avaliar automaticamente a validade do registro profissional em relação à data atual (`CURRENT_DATE`):

- **Registro expirado:** se `r.data_validade < CURRENT_DATE`, a coluna calculada `situacao_crf` retorna `'VENCIDO'`.
- **Registro regular:** caso contrário, a coluna `situacao_crf` retorna `'VÁLIDO'`.

Após sua criação, a visão foi testada por meio do comando `SELECT * FROM vw_farmaceuticos_crf;`, permitindo visualizar rapidamente a situação regular de todos os farmacêuticos cadastrados.

### 7. PROCEDURE

**`AdicionarItem` — o que faz:** recebe o id da venda, o id do medicamento e a
quantidade, e então:

1. busca o preço atual do medicamento (`SELECT preco INTO v_preco`);
2. insere o item em `item_venda`, com esse preço como `preco_unitario`;
3. soma `preço × quantidade` no `valor_total` da venda;
4. mostra a mensagem `'Item adicionado!'`.

**Por que foi criada:** colocar um item numa venda envolve três passos que precisam
acontecer sempre juntos. Com a procedure, um único `CALL` faz tudo do mesmo jeito,
sem o risco de inserir o item e esquecer de atualizar o total. Como o `INSERT`
dispara o trigger `baixa_estoque`, o estoque também é atualizado.

Os parâmetros começam com `p_` (`p_venda_id`, `p_medicamento_id` e `p_quantidade`)
para não terem o mesmo nome das colunas. Com nomes iguais, um `WHERE id = id` seria
sempre verdadeiro e alteraria todas as linhas.

### 8. TRIGGER

Os dois triggers foram criados **antes** dos `INSERT`s, logo depois das tabelas. Um
trigger só age nos comandos feitos depois que ele existe; criando antes, todas as
vendas cadastradas já descontam do estoque.

**`baixa_estoque`** (`AFTER INSERT` em `item_venda`)

- **O que faz:** depois de cada item inserido, diminui o `quantidade_estoque` do
  medicamento vendido, usando `NEW.quantidade` e `NEW.medicamento_id`. O `NEW` é a
  linha que acabou de entrar.
- **Por que foi criado:** toda venda tem que baixar o estoque. Com o trigger isso
  acontece sozinho, sem depender de alguém lembrar de fazer o `UPDATE`, e o estoque
  nunca fica desatualizado. Como a tabela `medicamento` tem
  `CHECK (quantidade_estoque >= 0)`, uma venda maior do que o estoque é barrada
  pelo banco.
- **Resultado:** depois das vendas cadastradas, o estoque ficou assim: Novalgina
  100 → 96, Tylenol 80 → 75, Advil 60 → 57, Amoxil 40 → 39 e Cozaar 50 → 48.

**`devolve_estoque`** (`AFTER DELETE` em `item_venda`), implementação extra

- **O que faz:** quando um item é apagado, devolve a quantidade ao estoque, usando
  `OLD.quantidade` e `OLD.medicamento_id`. No `DELETE` só existe o `OLD`, que é a
  linha apagada.
- **Por que foi criado:** quando uma venda é cancelada, os remédios voltam para a
  prateleira. Sem esse trigger, o estoque ficaria menor do que o real.

### 9. Controle de Acesso: ROLE e Usuários

Para aplicar o princípio do menor privilégio e organizar a segurança de acesso ao banco `farmacia`, foi criado o papel (perfil de permissões) `'role_atendimento'` e dois usuários locais: `'atendente1'@'localhost'` e `'gerente1'@'localhost'`.

Inicialmente, foram concedidos à `'role_atendimento'` apenas os privilégios necessários para a rotina de balcão: leitura (`SELECT`) na visão `vw_farmaceuticos_crf` e na tabela `medicamento`, além de consulta (`SELECT`) e cadastro (`INSERT`) na tabela `cliente`. Em seguida, os privilégios foram distribuídos conforme o cargo de cada usuário, ativados via `SET DEFAULT ROLE` e auditados com o comando `SHOW GRANTS`:

| Perfil / Usuário | Papel Atribuído | Permissões Concedidas | Escopo Operacional |
|---|---|---|---|
| `'role_atendimento'` | Papel Base (ROLE) | SELECT em vw_farmaceuticos_crf e medicamento; SELECT, INSERT em cliente | Consultas de balcão e cadastro de novos clientes |
| `'atendente1'@'localhost'` | role_atendimento | Herda exclusivamente as permissões de role_atendimento | Não pode editar nem excluir registros existentes |
| `'gerente1'@'localhost'` | role_atendimento + Extras | Herda role_atendimento + SELECT, INSERT, UPDATE, DELETE em cliente e SELECT, UPDATE em medicamento | Gestão completa de clientes e atualização de medicamentos |

### 10. UPDATE

Foram usados dois comandos UPDATE para atualizar os dados cadastrados.

O primeiro aplica um aumento de 10% aos medicamentos que pertencem ao laboratório de id 3. Para isso foi usada a função ROUND, que arredonda o resultado para duas casas decimais.

O segundo atualiza a quantidade do estoque para 100 unidades do medicamento de id 5.

A utilização da cláusula WHERE garante que somente os registros correspondentes às condições sejam alterados.

Foram executados dois comandos `UPDATE` para demonstrar a alteração controlada de registros já existentes no banco de dados:

- **Atualização de telefone do cliente:** o primeiro comando altera o campo `telefone` para `'35988887777'` exclusivamente para o cliente cujo `id` é igual a `1` (Mariana Oliveira).
- **Atualização de turno do farmacêutico:** o segundo comando modifica o `turno` de trabalho para `'TARDE'` exclusivamente para a farmacêutica com `id = 1` (Ana Beatriz Costa).

> **Importância da Cláusula WHERE no Comando UPDATE**
>
> Em ambas as operações, a utilização da cláusula WHERE (WHERE id = 1) é indispensável para restringir a modificação apenas ao registro alvo. Caso o comando UPDATE seja executado sem a cláusula WHERE, todas as linhas da tabela correspondente seriam sobrescritas com o mesmo valor.

A forma de pagamento da venda 3 foi corrigida de `'DINHEIRO'` para `'CARTAO'`.
**Motivo:** corrigir um dado digitado errado no caixa. O `WHERE id = 3` usa a chave
primária, então só essa venda muda.

### 11. DELETE

Foi usado o comando DELETE para deletar a associação da tabela **medicamento_has_principio_ativo**, quando o medicamento tiver id 5 e o principio ativo tiver id 6.

Em seguida, foi utilizado um comando INSERT INTO para inserir novamente essa associação, demonstrando como restaurar o relacionamento excluído.

A venda 6 foi cancelada: primeiro são apagados os itens dela em `item_venda` e
depois a própria venda.

**Motivo da ordem:** os itens apontam para a venda pela chave estrangeira. Se a
venda fosse apagada antes, o MySQL bloquearia o `DELETE`, porque os itens ficariam
apontando para uma venda que não existe mais (integridade referencial).

Ao apagar os itens, o trigger `devolve_estoque` devolveu os remédios ao estoque:
Novalgina 96 → 97 e Tylenol 75 → 76.

### 12. Implementações Extras

- Trigger **`devolve_estoque`**, que devolve o estoque quando uma venda é cancelada.
- Coluna **`preco_unitario`** em `item_venda`, que guarda o preço cobrado em cada
  venda mesmo depois de um reajuste.
- **Venda sem estoque barrada:** o trigger `baixa_estoque` junto com o `CHECK` de
  `medicamento` impede vender mais do que tem.
- **Busca completa da venda**, juntando cinco tabelas numa só consulta.
