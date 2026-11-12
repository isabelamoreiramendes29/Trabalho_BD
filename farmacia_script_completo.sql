DROP DATABASE IF EXISTS farmacia;
CREATE DATABASE farmacia;
USE farmacia;


CREATE TABLE laboratorio (
    id INT PRIMARY KEY NOT NULL AUTO_INCREMENT,
    nome VARCHAR(50) NOT NULL,
    cnpj CHAR(14) NOT NULL UNIQUE,
    pais_origem VARCHAR(50) NOT NULL
);

CREATE TABLE principio_ativo (
    id INT PRIMARY KEY NOT NULL AUTO_INCREMENT,
    nome VARCHAR(50) NOT NULL,
    descricao VARCHAR(255)
);

CREATE TABLE medicamento (
    id INT PRIMARY KEY NOT NULL AUTO_INCREMENT,
    nome_comercial VARCHAR(100) NOT NULL,
    preco DECIMAL(10,2) NOT NULL,
    tarja ENUM('Sem Tarja', 'Vermelha', 'Preta') NOT NULL,
    exigencia_receita BOOLEAN NOT NULL,
    quantidade_estoque INT NOT NULL,
    laboratorio_id INT NOT NULL,
    medicamento_referencia_id INT NULL,

    CONSTRAINT chk_medicamento_preco CHECK (preco >= 0),
    CONSTRAINT chk_medicamento_estoque CHECK (quantidade_estoque >= 0),
    CONSTRAINT fk_medicamento_laboratorio
        FOREIGN KEY (laboratorio_id)
        REFERENCES laboratorio(id),
    CONSTRAINT fk_medicamento_referencia
        FOREIGN KEY (medicamento_referencia_id)
        REFERENCES medicamento(id)
);

CREATE TABLE lote (
    id INT PRIMARY KEY NOT NULL AUTO_INCREMENT,
    codigo VARCHAR(30) NOT NULL UNIQUE,
    data_fabricacao DATE NOT NULL,
    data_validade DATE NOT NULL,
    quantidade INT NOT NULL,
    medicamento_id INT NOT NULL,

    CONSTRAINT chk_lote_quantidade CHECK (quantidade >= 0),
    CONSTRAINT fk_lote_medicamento
        FOREIGN KEY (medicamento_id)
        REFERENCES medicamento(id)
);

CREATE TABLE medicamento_has_principio_ativo (
    medicamento_id INT NOT NULL,
    principio_ativo_id INT NOT NULL,

    PRIMARY KEY (medicamento_id, principio_ativo_id),
    FOREIGN KEY (medicamento_id) REFERENCES medicamento(id),
    FOREIGN KEY (principio_ativo_id) REFERENCES principio_ativo(id)
);


CREATE TABLE farmaceutico (
    id INT PRIMARY KEY NOT NULL AUTO_INCREMENT,
    nome VARCHAR(100) NOT NULL,
    cpf CHAR(11) NOT NULL UNIQUE,
    data_admissao DATE NOT NULL,
    turno ENUM('MANHA', 'TARDE', 'NOITE') NOT NULL,
    laboratorio_id INT NOT NULL,

    CONSTRAINT fk_farmaceutico_laboratorio
        FOREIGN KEY (laboratorio_id)
        REFERENCES laboratorio(id)
);

CREATE TABLE registro_crf (
    farmaceutico_id INT NOT NULL,
    numero_crf VARCHAR(20) NOT NULL,
    uf CHAR(2) NOT NULL,
    data_validade DATE NOT NULL,

    PRIMARY KEY (farmaceutico_id),
    CONSTRAINT uq_registro_crf_numero UNIQUE (numero_crf),
    CONSTRAINT fk_registro_crf_farmaceutico
        FOREIGN KEY (farmaceutico_id)
        REFERENCES farmaceutico(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);

CREATE TABLE cliente (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nome VARCHAR(100) NOT NULL,
    cpf CHAR(11) NOT NULL UNIQUE,
    telefone VARCHAR(15),
    data_nascimento DATE
);

CREATE TABLE medicamento_has_cliente (
    medicamento_id INT NOT NULL,
    cliente_id INT NOT NULL,

    PRIMARY KEY (medicamento_id, cliente_id),
    CONSTRAINT fk_mhc_medicamento
        FOREIGN KEY (medicamento_id)
        REFERENCES medicamento(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT fk_mhc_cliente
        FOREIGN KEY (cliente_id)
        REFERENCES cliente(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);


CREATE TABLE venda (
    id INT PRIMARY KEY NOT NULL AUTO_INCREMENT,
    data_venda DATE NOT NULL,
    hora_venda TIME NOT NULL,
    valor_total DECIMAL(10,2) NOT NULL DEFAULT 0,
    forma_pagamento ENUM('DINHEIRO', 'PIX', 'CARTAO') NOT NULL,
    cliente_id INT NOT NULL,
    farmaceutico_id INT NOT NULL,

    CONSTRAINT chk_venda_valor CHECK (valor_total >= 0),
    CONSTRAINT fk_venda_cliente
        FOREIGN KEY (cliente_id)
        REFERENCES cliente(id),
    CONSTRAINT fk_venda_farmaceutico
        FOREIGN KEY (farmaceutico_id)
        REFERENCES farmaceutico(id)
);

CREATE TABLE item_venda (
    venda_id INT NOT NULL,
    medicamento_id INT NOT NULL,
    quantidade INT NOT NULL,
    preco_unitario DECIMAL(10,2) NOT NULL,

    PRIMARY KEY (venda_id, medicamento_id),
    CONSTRAINT chk_item_venda_quantidade CHECK (quantidade > 0),
    CONSTRAINT fk_item_venda_venda
        FOREIGN KEY (venda_id)
        REFERENCES venda(id),
    CONSTRAINT fk_item_venda_medicamento
        FOREIGN KEY (medicamento_id)
        REFERENCES medicamento(id)
);


DROP TRIGGER IF EXISTS baixa_estoque;
CREATE TRIGGER baixa_estoque AFTER INSERT
ON item_venda
FOR EACH ROW
UPDATE medicamento
SET quantidade_estoque = quantidade_estoque - NEW.quantidade
WHERE id = NEW.medicamento_id;

DROP TRIGGER IF EXISTS devolve_estoque;
CREATE TRIGGER devolve_estoque AFTER DELETE
ON item_venda
FOR EACH ROW
UPDATE medicamento
SET quantidade_estoque = quantidade_estoque + OLD.quantidade
WHERE id = OLD.medicamento_id;


INSERT INTO laboratorio (nome, cnpj, pais_origem) VALUES
('EMS', '57507378000101', 'Brasil'),
('Eurofarma', '61190096000192', 'Brasil'),
('Medley', '10588899000112', 'Brasil'),
('Sanofi', '02568580000183', 'França'),
('Laboratório Vale Verde', '12345678000190', 'Brasil');

INSERT INTO principio_ativo (nome, descricao) VALUES
('Dipirona Sódica', 'Analgésico e antitérmico'),
('Paracetamol', 'Analgésico e antitérmico'),
('Ibuprofeno', 'Anti-inflamatório'),
('Cafeína', 'Estimulante do sistema nervoso central'),
('Amoxicilina', 'Antibiótico'),
('Losartana Potássica', 'Anti-hipertensivo');

INSERT INTO medicamento
(nome_comercial, preco, tarja, exigencia_receita,
 quantidade_estoque, laboratorio_id, medicamento_referencia_id)
VALUES
('Novalgina', 12.50, 'Sem Tarja', FALSE, 100, 1, NULL),
('Tylenol', 15.90, 'Sem Tarja', FALSE, 80, 2, NULL),
('Advil', 18.00, 'Sem Tarja', FALSE, 60, 3, NULL),
('Amoxil', 25.00, 'Vermelha', TRUE, 40, 4, NULL),
('Cozaar', 30.00, 'Vermelha', TRUE, 50, 4, NULL);

INSERT INTO lote
(codigo, data_fabricacao, data_validade, quantidade, medicamento_id)
VALUES
('LOT001', '2026-01-10', '2027-01-10', 100, 1),
('LOT002', '2026-02-15', '2027-02-15', 80, 2),
('LOT003', '2026-03-20', '2027-03-20', 60, 3),
('LOT004', '2026-04-05', '2027-04-05', 40, 4),
('LOT005', '2026-05-12', '2027-05-12', 50, 5),
('LOT006', '2026-01-15', '2027-01-15', 70, 1),
('LOT007', '2026-02-20', '2027-02-20', 90, 2),
('LOT008', '2026-03-25', '2027-03-25', 55, 3),
('LOT009', '2026-04-10', '2027-04-10', 45, 4),
('LOT010', '2026-05-18', '2027-05-18', 65, 5),
('LOT011', '2026-06-01', '2027-06-01', 30, 4);

INSERT INTO medicamento_has_principio_ativo
(medicamento_id, principio_ativo_id)
VALUES
(1, 1),
(2, 2),
(3, 3),
(4, 5),
(5, 6);


INSERT INTO farmaceutico
    (nome, cpf, data_admissao, turno, laboratorio_id)
VALUES
    ('Ana Beatriz Costa', '12345678901', '2024-02-01', 'MANHA', 1),
    ('Rafael Mendes Lima', '23456789012', '2023-08-15', 'TARDE', 2),
    ('Juliana Ferreira Alves', '34567890123', '2025-01-10', 'NOITE', 1),
    ('Carlos Eduardo Rocha', '45678901235', '2022-06-20', 'MANHA', 3),
    ('Beatriz Nogueira Lima', '56789012346', '2025-03-03', 'NOITE', 4);

INSERT INTO registro_crf
    (farmaceutico_id, numero_crf, uf, data_validade)
VALUES
    (1, 'CRF-MG-10001', 'MG', '2028-12-31'),
    (2, 'CRF-MG-10002', 'MG', '2027-10-31'),
    (3, 'CRF-MG-10003', 'MG', '2029-05-31'),
    (4, 'CRF-MG-10004', 'MG', '2028-03-31'),
    (5, 'CRF-SP-20005', 'SP', '2026-10-31');

INSERT INTO cliente
    (nome, cpf, telefone, data_nascimento)
VALUES
    ('Mariana Oliveira', '45678901234', '35999990001', '2001-04-12'),
    ('Lucas Martins Souza', '56789012345', '35999990002', '1998-09-23'),
    ('Camila Ribeiro Santos', '67890123456', '35999990003', '2003-01-30'),
    ('Pedro Henrique Alves', '78901234567', '35999990004', '1995-07-08'),
    ('Fernanda Lopes Carvalho', '89012345670', '35999990005', '1990-11-15');

INSERT INTO medicamento_has_cliente
    (medicamento_id, cliente_id)
VALUES
    (1, 1),
    (2, 1),
    (3, 2),
    (4, 3),
    (5, 4),
    (1, 3);


INSERT INTO venda
    (data_venda, hora_venda, valor_total, forma_pagamento, cliente_id, farmaceutico_id)
VALUES
    ('2026-11-02', '09:15:00', 40.90, 'PIX',      1, 1),
    ('2026-11-03', '14:30:00', 43.00, 'CARTAO',   2, 2),
    ('2026-11-04', '10:00:00', 60.00, 'DINHEIRO', 3, 3),
    ('2026-11-05', '16:45:00', 48.50, 'PIX',      1, 4),
    ('2026-11-06', '11:20:00', 47.70, 'CARTAO',   4, 5),
    ('2026-11-07', '08:30:00', 28.40, 'DINHEIRO', 5, 1);

INSERT INTO item_venda
    (venda_id, medicamento_id, quantidade, preco_unitario)
VALUES
    (1, 1, 2, 12.50),
    (1, 2, 1, 15.90),
    (2, 4, 1, 25.00),
    (2, 3, 1, 18.00),
    (3, 5, 2, 30.00),
    (4, 3, 2, 18.00),
    (4, 1, 1, 12.50),
    (5, 2, 3, 15.90),
    (6, 1, 1, 12.50),
    (6, 2, 1, 15.90);


SELECT
    medicamento.nome_comercial AS medicamento,
    principio_ativo.nome AS principio_ativo,
    laboratorio.nome AS laboratorio
FROM medicamento
INNER JOIN medicamento_has_principio_ativo
    ON medicamento_has_principio_ativo.medicamento_id = medicamento.id
INNER JOIN principio_ativo
    ON principio_ativo.id = medicamento_has_principio_ativo.principio_ativo_id
INNER JOIN laboratorio
    ON laboratorio.id = medicamento.laboratorio_id
ORDER BY medicamento.nome_comercial;

SELECT
    f.id AS id_farmaceutico,
    f.nome AS nome_farmaceutico,
    f.cpf,
    f.data_admissao,
    f.turno,
    r.numero_crf,
    r.uf,
    r.data_validade
FROM farmaceutico AS f
INNER JOIN registro_crf AS r
    ON r.farmaceutico_id = f.id
ORDER BY f.nome;

SELECT
    c.nome AS cliente,
    COUNT(v.id) AS quantidade_compras,
    COALESCE(SUM(v.valor_total), 0) AS total_gasto
FROM cliente AS c
LEFT JOIN venda AS v
    ON v.cliente_id = c.id
GROUP BY c.id, c.nome
ORDER BY total_gasto DESC;

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


DELIMITER $$

DROP FUNCTION IF EXISTS estoque_nao_vazio$$
CREATE FUNCTION estoque_nao_vazio(medicamento_quantidade INT)
RETURNS VARCHAR(50)
DETERMINISTIC
BEGIN
    IF medicamento_quantidade > 0 THEN
        RETURN 'Disponivel';
    ELSE
        RETURN 'Indisponivel';
    END IF;
END $$

DELIMITER ;


CREATE OR REPLACE VIEW vw_farmaceuticos_crf AS
SELECT
    f.id AS id_farmaceutico,
    f.nome AS nome_farmaceutico,
    f.turno,
    l.nome AS laboratorio,
    r.numero_crf,
    r.uf,
    r.data_validade,
    CASE
        WHEN r.data_validade < CURRENT_DATE THEN 'VENCIDO'
        ELSE 'VÁLIDO'
    END AS situacao_crf
FROM farmaceutico AS f
INNER JOIN registro_crf AS r
    ON r.farmaceutico_id = f.id
INNER JOIN laboratorio AS l
    ON l.id = f.laboratorio_id;


DELIMITER $$

DROP PROCEDURE IF EXISTS AdicionarItem$$
CREATE PROCEDURE AdicionarItem(IN p_venda_id INT, IN p_medicamento_id INT, IN p_quantidade INT)
BEGIN
    DECLARE v_preco DECIMAL(10,2);

    SELECT preco INTO v_preco
    FROM medicamento
    WHERE id = p_medicamento_id;

    INSERT INTO item_venda (venda_id, medicamento_id, quantidade, preco_unitario)
    VALUES (p_venda_id, p_medicamento_id, p_quantidade, v_preco);

    UPDATE venda
    SET valor_total = valor_total + (v_preco * p_quantidade)
    WHERE id = p_venda_id;

    SELECT 'Item adicionado!' AS Resultado;
END $$

DELIMITER ;


DROP USER IF EXISTS 'atendente1'@'localhost', 'gerente1'@'localhost';
DROP ROLE IF EXISTS 'role_atendimento';

CREATE ROLE 'role_atendimento';

CREATE USER 'atendente1'@'localhost'
    IDENTIFIED BY 'Troque_Esta_Senha_123!';

CREATE USER 'gerente1'@'localhost'
    IDENTIFIED BY 'Troque_Esta_Senha_456!';

GRANT SELECT ON farmacia.vw_farmaceuticos_crf
    TO 'role_atendimento';

GRANT SELECT ON farmacia.medicamento
    TO 'role_atendimento';

GRANT SELECT ON farmacia.cliente
    TO 'role_atendimento';

GRANT INSERT ON farmacia.cliente
    TO 'role_atendimento';

GRANT 'role_atendimento' TO 'atendente1'@'localhost';
SET DEFAULT ROLE 'role_atendimento'
    TO 'atendente1'@'localhost';

GRANT 'role_atendimento' TO 'gerente1'@'localhost';

GRANT SELECT, INSERT, UPDATE, DELETE
    ON farmacia.cliente
    TO 'gerente1'@'localhost';

GRANT SELECT, UPDATE
    ON farmacia.medicamento
    TO 'gerente1'@'localhost';

SET DEFAULT ROLE 'role_atendimento'
    TO 'gerente1'@'localhost';


UPDATE medicamento
SET preco = ROUND(preco * 1.10, 2)
WHERE laboratorio_id = 3;

UPDATE medicamento
SET quantidade_estoque = 100
WHERE id = 5;

DELETE FROM medicamento_has_principio_ativo
WHERE medicamento_id = 5
AND principio_ativo_id = 6;

INSERT INTO medicamento_has_principio_ativo
(medicamento_id, principio_ativo_id)
VALUES (5, 6);


UPDATE cliente
SET telefone = '35988887777'
WHERE id = 1;

UPDATE farmaceutico
SET turno = 'TARDE'
WHERE id = 1;

DELETE FROM medicamento_has_cliente
WHERE medicamento_id = 1
AND cliente_id = 3;


UPDATE venda
SET forma_pagamento = 'CARTAO'
WHERE id = 3;

DELETE FROM item_venda
WHERE venda_id = 6;

DELETE FROM venda
WHERE id = 6;
