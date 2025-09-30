CREATE PROCEDURE SBO_SP_TransactionNotification
(
	in object_type nvarchar(30), 				-- SBO Object Type
	in transaction_type nchar(1),			-- [A]dd, [U]pdate, [D]elete, [C]ancel, C[L]ose
	in num_of_cols_in_key int,
	in list_of_key_cols_tab_del nvarchar(255),
	in list_of_cols_val_tab_del nvarchar(255)
)
LANGUAGE SQLSCRIPT
AS
-- Return values
error  int;				-- Result (0 for no error)
error_message nvarchar (5000); 		-- Error string to be displayed
currDbNameForTaxOne nvarchar(128);
 
 
companyDbIntBank nvarchar(128);
begin
 
error := 0;
error_message := N'Ok';


IF((:object_type = '10000044') AND (:transaction_type = 'A' OR :transaction_type = 'U'))
	THEN
		error = 1799;
		error_message = 'Trans Lote funfando';

END IF;

 
--------------------------------------------------------------------------------------------------------------------------------
-----Pedido de Vendas
--------------------------------------------------------------------------------------------------------------------------------
-----Cabeçalho
-------------------
--Consultor: Gabriel Domingues
--Data: 13/09/2024
--Objetivo1: Verificar os campos Origem do Pedido e Ciclo do Pedido.
--Objetivo2: Validar se o valor total do pedido está de acordo com a política da condição de pagamento.
-------------------
IF((:object_type = '17') AND (:transaction_type = 'A' OR :transaction_type = 'U' OR :transaction_type = 'C'))
	THEN
		DECLARE contador BIGINT;
		DECLARE contador2 BIGINT;
        DECLARE idMercos NVARCHAR(20);

		SELECT COUNT("DocNum") INTO contador FROM ORDR 
		WHERE "DocEntry" = :list_of_cols_val_tab_del
		AND (("U_Ciclo_Pedido" IS NULL OR "U_Ciclo_Pedido" = '') 
		OR  ("U_Origem" IS NULL OR "U_Origem" = '')
        OR  ("U_Tipo_Pedido" IS NULL OR "U_Tipo_Pedido" = ''));
		
		IF contador > 0
			THEN
				error = 1701;
				error_message = 'Os campos Ciclo do Pedido, Origem do Pedido e Tipo do Pedido são obrigatórios!!!';
        ELSE
------------------------------------------------------Proibi o uso dos Campos Mercos-----------------------------------------------------------
            SELECT COUNT(T0."DocEntry") INTO contador2 FROM ORDR T0  
            WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
            AND T0."U_Origem" <> 2
            AND ((T0."U_Id_Mercos" IS NOT NULL OR T0."U_Id_Mercos" <> '') 
                OR (T0."U_Obs_Mercos" IS NOT NULL OR T0."U_Obs_Mercos" NOT LIKE ''));
            
            IF contador2 > 0
                THEN
                    error = 1705;
                    error_message = 'Proíbido o uso dos campos Mercos para os pedidos cujo não sejam do Mercos!!!';
            END IF;
		END IF;
--------------------------------------------------------------------------------------------------------------------------------		
		SELECT COUNT(T0."DocEntry") INTO contador2 FROM ORDR T0  
		INNER JOIN OCTG T1 
		ON T0."GroupNum" = T1."GroupNum"
		WHERE "DocEntry" = :list_of_cols_val_tab_del 
		AND T0."DocTotal" <  T1."U_Min_Valor";
		
		IF contador2 > 0
			THEN
				error = 1703;
				error_message = 'O valor total do documento não está de acordo com a política da condição de pagamento!!!';
		END IF;
------------------------------------------------------Valida Id Mercos-----------------------------------------------------------
        SELECT COUNT(*) INTO contador
        FROM ORDR T0 
                WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
                AND (T0."U_Id_Mercos" IS NOT NULL OR T0."U_Id_Mercos" <> '');
        IF contador > 0
            THEN
            SELECT IFNULL("U_Id_Mercos",'0') INTO idMercos
                FROM ORDR T0 
                WHERE T0."DocEntry" = :list_of_cols_val_tab_del 
                AND (T0."U_Id_Mercos" IS NOT NULL OR T0."U_Id_Mercos" <> '');

                IF idMercos IS NOT NULL OR  idMercos = '0' 
                THEN
                    SELECT COUNT("DocNum") INTO contador
                    FROM ORDR
                    WHERE "U_Id_Mercos" = :idMercos;
                    IF contador > 1
                    THEN
                        error = 1704;
                        error_message = 'Id Mercos já possui um pedido!';
                    END IF;
                END IF;
        END IF;
---------------------------------------Trava Ped Em Picking-------------------------------------
       SELECT
            COUNT(T0."DocEntry") INTO contador
        FROM
            ORDR T0
        WHERE T0."GroupNum" = '19'
        AND T0."DocEntry" = :list_of_cols_val_tab_del;
        IF contador > 0
            THEN
                error = 1705;
                error_message = 'O Pedido está com a condição de pagamento errada, favor colocar uma condição de pagamento válida';

        END IF;
        SELECT
            COUNT(T0."DocEntry") INTO contador
        FROM
            ORDR T0
            INNER JOIN (
                SELECT
                    T0."AbsEntry",
                    T1."OrderEntry",
                    T0."U_Status",
                    T0."Canceled",
                    T0."Status"
                FROM
                    OPKL T0
                    INNER JOIN PKL1 T1 ON T0."AbsEntry" = T1."AbsEntry"
                WHERE
                    T1."BaseObject" = '17'
                    AND T0."Status" NOT IN ('C', 'Y')
                GROUP BY
                    T0."AbsEntry",
                    T1."OrderEntry",
                    T0."U_Status",
                    T0."Canceled",
                    T0."Status"
            ) T1 ON T0."DocEntry" = T1."OrderEntry"
            INNER JOIN OUSR T2 
            ON T0."UserSign2" = T2."USERID"
            AND T2."Department" NOT IN (3,6)
        WHERE T0."DocStatus" = 'O'
        AND T0."U_Ciclo_Pedido" IN ('3', '4')
        AND T0."DocEntry" = :list_of_cols_val_tab_del;
        IF contador > 0
            THEN
                error = 1706;
                error_message = 'O Pedido está em picking!';

        END IF;
------------------------------------------------------FIM-----------------------------------------------------------		
END IF;
-------------------
--Consultor: Gabriel Domingues
--Data: 13/09/2024
--Objetivo: Proíbe fechar o documento.
-------------------
IF((:object_type = '17') AND (:transaction_type = 'L'))
	THEN
		error = 1799;
		error_message = 'O documento não pode ser fechado, favor realizar processo corretamente!!!';

END IF;

-----Linha
-------------------
--Consultor: Gabriel Domingues
--Data: 13/09/2024
--Objetivo: Não permitir preço zero.
-------------------
IF((:object_type = '17') AND (:transaction_type = 'A' OR :transaction_type = 'U' OR :transaction_type = 'C'))
	THEN
		DECLARE contador BIGINT;
		SELECT COUNT("ItemCode") INTO contador FROM RDR1
		WHERE "DocEntry" = :list_of_cols_val_tab_del
		AND ("Price" <= 0 OR "Price" IS NULL);
		
		IF contador > 0
			THEN
				error = 1702;
				error_message = 'O preço do produto deve ser maior que 0!';
		END IF;

        SELECT COUNT("ItemCode") INTO contador FROM RDR1
		WHERE "DocEntry" = :list_of_cols_val_tab_del
		AND ("Quantity" < "U_QtdPicking");
		
		IF contador > 0
			THEN
				error = 1703;
				error_message = 'Quantidade Picking não pode ser maior que a quantidade do Pedido!!!';
		END IF;

        SELECT COUNT(T0."ItemCode") INTO contador FROM RDR1 T0
        INNER JOIN RDR1 T1
        ON T0."DocEntry" = T1."DocEntry"
        AND T0."ItemCode" = T1."ItemCode"
        AND T0."LineNum" <> T1."LineNum"
        WHERE T0."DocEntry" = :list_of_cols_val_tab_del;

        IF contador > 0
			THEN
				error = 1704;
				error_message = 'Pedido com item duplicado favor ajustar!!!';
		END IF;

END IF;
--------------------------------------------------------------------------------------------------------------------------------
-----Nota Fiscal de Saída
--------------------------------------------------------------------------------------------------------------------------------
-----Cabeçalho
-------------------
IF((:object_type = '13') AND (:transaction_type = 'A' OR :transaction_type = 'U' OR :transaction_type = 'C'))
    THEN
    DECLARE contador BIGINT;
----------------------------Obriga ter Transportadora---------------------------
    SELECT COUNT(NF1."DocEntry") INTO contador 
    FROM INV12 NF1
    INNER JOIN OINV NF0
    ON NF1."DocEntry" = NF0."DocEntry"
    AND NF0.CANCELED = 'N'
    WHERE  NF1."DocEntry" = :list_of_cols_val_tab_del
    AND (NF1."Carrier" IS NULL OR NF1."Carrier" LIKE '');

    IF  contador > 0
        THEN
        error := 1300;
        error_message = 'Na aba *Imposto* o campo **Cód. Transportadora** deve ser preenchido';
    END IF;
----------------------------Obriga ter Volume----------------------------
    SELECT COUNT(NF1."DocEntry") INTO contador 
    FROM INV12 NF1
    INNER JOIN OINV NF0
    ON NF1."DocEntry" = NF0."DocEntry"
    AND NF0.CANCELED = 'N'
    WHERE  NF1."DocEntry" = :list_of_cols_val_tab_del
    AND (NF1."QoP" IS NULL OR NF1."QoP" LIKE '');
    
    IF  contador > 0
        THEN           
            IF  contador > 0
                THEN
                error := 1301;
                error_message = 'Na aba *Imposto* o campo **Qtd. Embalagens** deve ser preenchido';
            END IF;
    ELSE
         SELECT COUNT(NF1."DocEntry") INTO contador 
            FROM INV12 NF1
            INNER JOIN OINV NF0
            ON NF1."DocEntry" = NF0."DocEntry"
            AND NF0.CANCELED = 'N'
            WHERE  NF1."DocEntry" = :list_of_cols_val_tab_del
            AND NF1."QoP" <= 0;
            
            IF  contador > 0
                THEN
                error := 1301;
                error_message = 'Na aba *Imposto* o campo **Qtd. Embalagens** deve ser maior que 0';
            END IF;
    END IF;
----------------------------Obriga ter Descrição de embalagem----------------------------
    SELECT COUNT(NF1."DocEntry") INTO contador 
    FROM INV12 NF1
    INNER JOIN OINV NF0
    ON NF1."DocEntry" = NF0."DocEntry"
    AND NF0.CANCELED = 'N'
    WHERE  NF1."DocEntry" = :list_of_cols_val_tab_del
    AND (NF1."PackDesc" IS NULL OR NF1."PackDesc" LIKE '');
    
    IF  contador > 0
        THEN           
            IF  contador > 0
                THEN
                error := 1302;
                error_message = 'Na aba *Imposto* o campo **Descrição Embalagem** deve ser preenchido';
            END IF;
    ELSE
         SELECT COUNT(NF1."DocEntry") INTO contador 
            FROM INV12 NF1
            INNER JOIN OINV NF0
            ON NF1."DocEntry" = NF0."DocEntry"
            AND NF0.CANCELED = 'N'
            WHERE  NF1."DocEntry" = :list_of_cols_val_tab_del
            AND NF1."PackDesc" NOT LIKE 'CAIXA';
            
            IF  contador > 0
                THEN
                error := 1302;
                error_message = 'Na aba *Imposto* o campo **Descrição Embalagem** está fora do padrão, Padrão = *CAIXA*';
            END IF;
    END IF;
----------------------------Obriga ter Incoterms----------------------------
    SELECT COUNT(NF1."DocEntry") INTO contador 
    FROM INV12 NF1
    INNER JOIN OINV NF0
    ON NF1."DocEntry" = NF0."DocEntry"
    AND NF0.CANCELED = 'N'
    WHERE  NF1."DocEntry" = :list_of_cols_val_tab_del
    AND (NF1."Incoterms" IS NULL OR NF1."Incoterms" LIKE '');
    
    IF  contador > 0
        THEN           
            IF  contador > 0
                THEN
                error := 1303;
                error_message = 'Na aba *Imposto* o campo **Incoterms** deve ser preenchido';
            END IF;
    ELSE
         SELECT COUNT(NF1."DocEntry") INTO contador 
            FROM INV12 NF1
            INNER JOIN OINV NF0
            ON NF1."DocEntry" = NF0."DocEntry"
            AND NF0.CANCELED = 'N'
            WHERE  NF1."DocEntry" = :list_of_cols_val_tab_del
            AND NF1."Incoterms" NOT IN ('0','9');
            
            IF  contador > 0
                THEN
                error := 1303;
                error_message = 'Na aba *Imposto* o campo **Incoterms** está fora do padrão, Padrão 0 OU 9';
            END IF;
    END IF;
END IF;
-------------------
-----Linhas
-------------------
 --Consultor: Gabriel Domingues
--Data: 27/09/2024
-------------------
IF((:object_type = '13') AND (:transaction_type = 'A' OR :transaction_type = 'U' OR :transaction_type = 'C'))
    THEN
    DECLARE contador BIGINT;

    SELECT COUNT(NF1."ItemCode") INTO contador 
    FROM INV1 NF1
    INNER JOIN OINV NF0
    ON NF1."DocEntry" = NF0."DocEntry"
    AND NF0.CANCELED = 'N'
    WHERE  NF1."DocEntry" = :list_of_cols_val_tab_del
    AND (NF1."BaseEntry" IS NULL OR NF1."BaseType" <> '17');
    
    IF  contador > 0
        THEN
        error := 1304;
        error_message = 'Nota gerada de forma incorreta, todos os itens da nota devem estar vincualdo a um pedido de venda';
    ELSE
        SELECT
        COUNT(PV1."ItemCode") INTO contador
        FROM ORDR PV0
        INNER JOIN RDR1 PV1 
        ON PV0."DocEntry" = PV1."DocEntry"
        INNER JOIN INV1 NF1
        ON NF1."BaseEntry" = PV1."DocEntry"
        AND NF1."BaseLine" = PV1."LineNum"
        AND NF1."Quantity" <> PV1."U_QtdPicking"
        AND NF1."BaseType" = '17'
        AND PV1."TargetType" = '13'
        INNER JOIN OINV NF0
        ON  NF0."DocEntry" = NF1."DocEntry"
        AND NF0."CANCELED" = 'N'
        WHERE  NF1."DocEntry" = :list_of_cols_val_tab_del;
        IF contador > 0
            THEN
            error := 1305;
            error_message = 'Quantidade da Nota divergente da quantidade de picking do pedido!';
        END IF;
    END IF;
END IF;

--------------------------------------------------------------------------------------------------------------------------------
-----Cadastro de Itens
--------------------------------------------------------------------------------------------------------------------------------
 
--------------------------------------------------------------------------------------------------------------------------------
-----Parceiro de Negócios
--------------------------------------------------------------------------------------------------------------------------------
IF((:object_type = '2') AND (:transaction_type = 'A' OR :transaction_type = 'U'))
        THEN
            DECLARE contador BIGINT;
            DECLARE adress NVARCHAR(20);
            DECLARE idMercos NVARCHAR(20);
        ----------------------------Proíbe Cliente Potencial----------------------------
                    SELECT DISTINCT COUNT("CardCode") INTO contador
                    FROM OCRD T0 
                    WHERE T0."CardCode" = :list_of_cols_val_tab_del 
                    AND T0."CardType" = 'L';

                    IF contador > 0
                    THEN
                        error = 2000;
                        error_message = 'Proíbido criar ou  atualizar para cliente potencial!';
                    END IF;
        ----------------------------Valída Id Mercos----------------------------
                    SELECT COUNT(*) INTO contador
                    FROM OCRD T0 
                    WHERE T0."CardCode" = :list_of_cols_val_tab_del 
                    AND (T0."U_Id_Mercos" IS NOT NULL OR T0."U_Id_Mercos" <> '');

                    IF contador > 0
                        THEN
                        SELECT "U_Id_Mercos" INTO idMercos
                        FROM OCRD T0 
                        WHERE T0."CardCode" = :list_of_cols_val_tab_del 
                        AND (T0."U_Id_Mercos" IS NOT NULL OR T0."U_Id_Mercos" <> '');

                        IF idMercos IS NOT NULL OR  idMercos <> '' 
                        THEN
                            SELECT COUNT("CardCode") INTO contador
                            FROM OCRD
                            WHERE "U_Id_Mercos" = :idMercos;
                            IF contador > 1
                            THEN
                                error = 2001;
                                error_message = 'Id Mercos já possui um cliente, favor rever dados cadastrais!';
                            END IF;
                        END IF;
                    END IF;
    ----------------------------Campos Obrigatórios----------------------------
    ----------------------------CardCode
            SELECT COUNT(C0."CardCode") INTO contador
            FROM  OCRD C0
            WHERE C0."CardCode" = :list_of_cols_val_tab_del
            AND (C0."CardCode" IS NULL OR C0."CardCode" = '');

            IF contador > 0
                THEN
                    error = 2002;
                    error_message = 'Necessário preencher o Campo **Código do Cliente**!';
            ELSE
            ----------------------------Padrão CardCode----------------------------
            ----------------------------Fornecedor
                SELECT COUNT(C0."CardCode") INTO contador FROM  OCRD C0
                INNER JOIN CRD7 C7 
                ON C0."CardCode" = C7."CardCode"
                AND (C7."Address" IS NULL OR C7."Address" = '')
                WHERE C0."CardCode" NOT LIKE 'F'||REPLACE(REPLACE(REPLACE(C7."TaxId0", '.', ''), '-', ''), '/','')
                AND C0."CardType" = 'S'
                AND C0."GroupCode" IN (101)
                AND C0."CardCode" = :list_of_cols_val_tab_del;

                IF contador > 0
                    THEN
                        error = 2003;
                        error_message = 'Código do Fornecedor não está no padrão!';
                END IF;
            ----------------------------Cliente Pessoa Jurudica
                SELECT COUNT(C0."CardCode") INTO contador FROM  OCRD C0
                INNER JOIN CRD7 C7 
                ON C0."CardCode" = C7."CardCode"
                AND (C7."Address" IS NULL OR C7."Address" = '')
                WHERE C0."CardCode" NOT LIKE 'C'||REPLACE(REPLACE(REPLACE(C7."TaxId0", '.', ''), '-', ''), '/','')
                AND C0."CardType" = 'C'
                AND C0."GroupCode" IN (100)
                AND C0."CardCode" = :list_of_cols_val_tab_del;

                IF contador > 0
                    THEN
                        error = 2004;
                        error_message = 'Código do Cliente Pessoa Jurídica não está no padrão!';
                END IF;
            ----------------------------Cliente Pessoa Fisica
                SELECT COUNT(C0."CardCode") INTO contador FROM  OCRD C0
                INNER JOIN CRD7 C7 
                ON C0."CardCode" = C7."CardCode"
                AND (C7."Address" IS NULL OR C7."Address" = '')
                WHERE C0."CardCode" NOT LIKE 'C'||REPLACE(REPLACE(REPLACE(C7."TaxId4", '.', ''), '-', ''), '/','')
                AND C0."CardType" = 'C'
                AND C0."GroupCode" IN (102)
                AND C0."CardCode" = :list_of_cols_val_tab_del;

                IF contador > 0
                    THEN
                        error = 2005;
                        error_message = 'Código do Cliente Pessoa Física não está no padrão!';
                END IF;

            END IF;
     ----------------------------CardName
            SELECT COUNT(C0."CardCode") INTO contador
            FROM  OCRD C0
            WHERE C0."CardCode" = :list_of_cols_val_tab_del
            AND (C0."CardName" IS NULL OR C0."CardName" = '');

            IF contador > 0
                THEN
                    error = 2006;
                    error_message = 'Necessário preencher o Campo **Nome do Cliente**!';
            ELSE
                 SELECT COUNT(C0."CardCode") INTO contador
                FROM  OCRD C0
                WHERE C0."CardCode" = :list_of_cols_val_tab_del
                AND C0."CardName" <> UPPER(C0."CardName");

                IF contador > 0
                    THEN
                        error = 2006;
                        error_message = 'O Campo **Nome do Cliente** está fora do padrão, deixar em maiúsculas!';
                END IF;
            END IF;
    ----------------------------Telefone/Celular
            SELECT COUNT(C0."CardCode") INTO contador
            FROM  OCRD C0
            WHERE C0."CardCode" = :list_of_cols_val_tab_del
            AND((C0."Phone1" IS NULL OR C0."Phone1" = '')
                AND (C0."Cellular" IS NULL OR C0."Cellular" = ''));
            
            IF contador > 0
                THEN
                error = 2007;
                error_message = 'Necessário preencher o Campo **Telefone** ou  **Celular**!';
            ELSE
                ----------------------------Padrão Telefone----------------------------
                SELECT COUNT("CardCode") INTO contador FROM  OCRD  
                WHERE "Phone1" NOT LIKE_REGEXPR '^\(\d{2}\)\d{4}-\d{4}$'
                AND "CardCode" = :list_of_cols_val_tab_del;
                IF contador > 0
                    THEN
                        error = 2007;
                        error_message = 'O Telefone não está no formato correto!EX: (11)9999-9999';
                END IF;
                ----------------------------Padrão Celular----------------------------
                SELECT COUNT("CardCode") INTO contador FROM  OCRD  
                WHERE "Cellular" NOT LIKE_REGEXPR '^\(\d{2}\)9\d{4}-\d{4}$'
                AND "CardCode" = :list_of_cols_val_tab_del;

                IF contador > 0
                    THEN
                        error = 2007;
                        error_message = 'O Celular não está no formato correto!EX: (11)99999-9999';
                END IF;
            END IF;

            ----------------------------Email
            SELECT COUNT(C0."CardCode") INTO contador
            FROM  OCRD C0
            WHERE C0."CardCode" = :list_of_cols_val_tab_del
            AND(C0."E_Mail" IS NULL OR  C0."E_Mail" = '');
            
            IF contador > 0
                THEN
                error = 2008;
                error_message = 'Necessário preencher o Campo **E-mail**!';
            ELSE
            ----------------------------Padronização EMAIL----------------------------
                SELECT COUNT("CardCode") INTO contador FROM  OCRD 
                WHERE "E_Mail" NOT LIKE_REGEXPR '^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}$'
                AND "CardCode" = :list_of_cols_val_tab_del;

                IF contador > 0
                    THEN
                        error = 2008;
                        error_message = 'O email está incorreto favor corrigir';
                END IF;
            END IF;

            ----------------------------Nome Fantasia
            SELECT COUNT(C0."CardCode") INTO contador
            FROM  OCRD C0
            WHERE C0."CardCode" = :list_of_cols_val_tab_del
            AND(C0."AliasName" IS NOT NULL OR  C0."AliasName" NOT LIKE '');
            
            IF contador > 0
                THEN
            ----------------------------Padronização Nome Fantasia----------------------------
                    SELECT COUNT(C0."CardCode") INTO contador FROM  OCRD C0
                    WHERE C0."CardCode" = :list_of_cols_val_tab_del
                    AND C0."AliasName" NOT LIKE UPPER(C0."AliasName");

                IF contador > 0
                    THEN
                        error = 2009;
                        error_message = 'O Campo **Nome Fantasia** está fora do padrão, deixar em maiúsculas!';
                END IF;
            END IF;
            ----------------------------Obrigar Ter Info na CRD1
            SELECT COUNT(C1."CardCode") INTO contador
            FROM  CRD1 C1
            WHERE C1."CardCode" = :list_of_cols_val_tab_del;
            
            IF contador = 0
                THEN
                error = 2010;
                error_message = 'Necessário preencher os endereços na aba **Endereços**!!';
            ELSE
            ----------------------------Obrigar Endereço de Cobrança
                SELECT COUNT(C1."CardCode") INTO contador
                FROM  CRD1 C1
                WHERE C1."CardCode" = :list_of_cols_val_tab_del
                AND C1."AdresType" = 'B';
            
                IF contador = 0
                    THEN
                        error = 2011;
                        error_message = 'Necessário preencher **Endereço de Cobrança** na aba *Endereços*!!';
                ELSE
                    IF contador > 1
                    THEN
                        error = 2012;
                        error_message = 'Só Pode haver 1 **Endereço de Cobrança** na aba *Endereços*!!';
                    ELSE
                    ----------------------------Obrigar Tipo de Logradouro
                        SELECT COUNT(C1."CardCode") INTO contador
                        FROM  CRD1 C1
                        WHERE C1."CardCode" = :list_of_cols_val_tab_del
                        AND C1."AdresType" = 'B'
                        AND (C1."AddrType" IS NULL OR C1."AddrType" = '');
                        IF contador > 0
                        THEN
                            error = 2013;
                            error_message = 'Preencher Campo **Tipo de Logradouro** no **Endereço de Cobrança** na aba *Endereços*!!';
                        ELSE
                            SELECT DISTINCT COUNT("AdresType") INTO contador
                            FROM CRD1 T0 
                            WHERE T0."CardCode" = :list_of_cols_val_tab_del
                            AND T0."AdresType" = 'B'
                            AND ((T0."AddrType" NOT IN (SELECT UPPER("Name") 
                                                        FROM "@LOGRADOURO")));

                            IF contador > 0
                            THEN
                                error = 2013;
                                error_message = 'Campo **Tipo de Logradouro** no **Endereço de Cobrança** na aba *Endereços* não existe,
                                                 favor informar um **Tipo de Logradouro** válido!';
                            END IF;
                        END IF;
                    ----------------------------Obrigar Rua na Cobrança
                        SELECT COUNT(C1."CardCode") INTO contador
                        FROM  CRD1 C1
                        WHERE C1."CardCode" = :list_of_cols_val_tab_del
                        AND C1."AdresType" = 'B'
                        AND (C1."Street" IS NULL OR C1."Street" = '');
                        IF contador > 0
                        THEN
                            error = 2014;
                            error_message = 'Preencher Campo **Rua** no **Endereço de Cobrança** na aba *Endereços*!!';
                        ELSE
                            SELECT COUNT(C1."CardCode") INTO contador
                            FROM  CRD1 C1
                            WHERE C1."CardCode" = :list_of_cols_val_tab_del
                            AND C1."AdresType" = 'B'
                            AND C1."Street" <> UPPER(C1."Street");
                            IF contador > 0
                            THEN
                                error = 2014;
                                error_message = 'O Campo **Rua** no **Endereço de Cobrança** na aba *Endereços*, não está Maíusculo!!';
                            END IF;
                        END IF;
                    ----------------------------Obrigar Numero da Rua na Cobrança
                        SELECT COUNT(C1."CardCode") INTO contador
                        FROM  CRD1 C1
                        WHERE C1."CardCode" = :list_of_cols_val_tab_del
                        AND C1."AdresType" = 'B'
                        AND (C1."StreetNo" IS NULL OR C1."StreetNo" = '');
                        IF contador > 0
                        THEN
                            error = 2015;
                            error_message = 'Preencher Campo **Rua Nº** no **Endereço de Cobrança** na aba *Endereços*!!';
                        END IF;
                    ----------------------------Verifica Complemento
                        SELECT COUNT(C1."CardCode") INTO contador
                        FROM  CRD1 C1
                        WHERE C1."CardCode" = :list_of_cols_val_tab_del
                        AND C1."AdresType" = 'B'
                        AND (C1."Building" IS NOT NULL OR C1."Building" NOT LIKE '');
                        IF contador > 0
                        THEN
                            SELECT COUNT(C1."CardCode") INTO contador
                            FROM  CRD1 C1
                            WHERE C1."CardCode" = :list_of_cols_val_tab_del
                            AND C1."AdresType" = 'B'
                            AND C1."Building" NOT LIKE UPPER(C1."Building");
                            IF contador > 0
                            THEN
                                error = 2016;
                                error_message = 'O Campo **Complemento** no **Endereço de Cobrança** na aba *Endereços*, não está Maiúsculo!!';
                            END IF;
                        END IF;
                    ----------------------------Obrigar CEP
                        SELECT COUNT(C1."CardCode") INTO contador
                        FROM  CRD1 C1
                        WHERE C1."CardCode" = :list_of_cols_val_tab_del
                        AND C1."AdresType" = 'B'
                        AND (C1."ZipCode" IS NULL OR C1."ZipCode" = '');
                        IF contador > 0
                        THEN
                            error = 2017;
                            error_message = 'Preencher Campo **CEP** no **Endereço de Cobrança** na aba *Endereços*!!';
                        ELSE
                            SELECT COUNT(C1."CardCode") INTO contador FROM  CRD1 C1
                            WHERE C1."ZipCode" NOT LIKE_REGEXPR '^[0-9]{5}-[0-9]{3}$'
                            AND C1."AdresType" = 'B'
                            AND C1."CardCode" = :list_of_cols_val_tab_del;

                            IF contador > 0
                                THEN
                                    error = 2017;
                                    error_message = 'O Campo **CEP** no **Endereço de Cobrança** na aba *Endereços*,não está no formato correto. EX: 00000-000';
                            END IF;
                        END IF;

                        ----------------------------Obrigar Bairro
                        SELECT COUNT(C1."CardCode") INTO contador
                        FROM  CRD1 C1
                        WHERE C1."CardCode" = :list_of_cols_val_tab_del
                        AND C1."AdresType" = 'B'
                        AND (C1."Block" IS NULL OR C1."Block" = '');
                        IF contador > 0
                        THEN
                            error = 2018;
                            error_message = 'Preencher Campo **Bairro** no **Endereço de Cobrança** na aba *Endereços*!!';
                        ELSE
                            SELECT COUNT(C1."CardCode") INTO contador
                            FROM  CRD1 C1
                            WHERE C1."CardCode" = :list_of_cols_val_tab_del
                            AND C1."AdresType" = 'B'
                            AND C1."Block" <> UPPER(C1."Block");
                            IF contador > 0
                            THEN
                                error = 2018;
                                error_message = 'O Campo **Bairro** no **Endereço de Cobrança** na aba *Endereços*, não está Maíusculo!!';
                            END IF;
                        END IF;

                        ----------------------------Obrigar Cidade
                        SELECT COUNT(C1."CardCode") INTO contador
                        FROM  CRD1 C1
                        WHERE C1."CardCode" = :list_of_cols_val_tab_del
                        AND C1."AdresType" = 'B'
                        AND (C1."City" IS NULL OR C1."City" = '');
                        IF contador > 0
                        THEN
                            error = 2019;
                            error_message = 'Preencher Campo **Cidade** no **Endereço de Cobrança** na aba *Endereços*!!';
                        ELSE
                            SELECT DISTINCT COUNT(C1."AdresType") INTO contador
                            FROM CRD1 C1 
                            WHERE C1."CardCode" = :list_of_cols_val_tab_del 
                            AND ((C1."City" <> (SELECT "Name" 
                                                    FROM OCNT C0 WHERE C0."AbsId" = C1."County")));
                            IF contador > 0
                            THEN
                                error = 2019;
                                error_message = 'O Campo **Cidade** no **Endereço de Cobrança** na aba *Endereços* está fora do padrão, deixar igual o campo Munícipio!';
                            END IF;
                        END IF;

                        ----------------------------Obrigar Estado
                        SELECT COUNT(C1."CardCode") INTO contador
                        FROM  CRD1 C1
                        WHERE C1."CardCode" = :list_of_cols_val_tab_del
                        AND C1."AdresType" = 'B'
                        AND (C1."State" IS NULL OR C1."State" = '');
                        IF contador > 0
                        THEN
                            error = 2020;
                            error_message = 'Preencher Campo **Estado** no **Endereço de Cobrança** na aba *Endereços*!!';
                        END IF;

                         ----------------------------Obrigar Municipio
                        SELECT COUNT(C1."CardCode") INTO contador
                        FROM  CRD1 C1
                        WHERE C1."CardCode" = :list_of_cols_val_tab_del
                        AND C1."AdresType" = 'B'
                        AND (C1."County" IS NULL OR C1."County" = '');
                        IF contador > 0
                        THEN
                            error = 2021;
                            error_message = 'Preencher Campo **Município** no **Endereço de Cobrança** na aba *Endereços*!!';
                        END IF;

                        ----------------------------Obrigar País
                        SELECT COUNT(C1."CardCode") INTO contador
                        FROM  CRD1 C1
                        WHERE C1."CardCode" = :list_of_cols_val_tab_del
                        AND C1."AdresType" = 'B'
                        AND (C1."Country" IS NULL OR C1."Country" = '');
                        IF contador > 0
                        THEN
                            error = 2022;
                            error_message = 'Preencher Campo **País/Região** no **Endereço de Cobrança** na aba *Endereços*!!';
                        END IF;

                        -----------------------Valida Id Cobrança  
                        SELECT TOP 1 "Address" INTO adress FROM CRD1
                        WHERE "AdresType" = 'B'
                        AND "CardCode" = :list_of_cols_val_tab_del;
                        
                        IF adress <> 'COBRANÇA'
                            THEN
                                error = 2023;
                                error_message = 'O Id do endereço de cobrança está incorreto, o padrão é COBRANÇA';
                        END IF;
                    END IF;
                END IF;
                
            ----------------------------Obrigar Endereço de Entrega
                SELECT COUNT(C1."CardCode") INTO contador
                FROM  CRD1 C1
                WHERE C1."CardCode" = :list_of_cols_val_tab_del
                AND C1."AdresType" = 'S';
            
                IF contador = 0
                    THEN
                        error = 2024;
                        error_message = 'Necessário preencher **Endereço de Entrega** na aba *Endereços*!!';
                ELSE
                    IF contador > 1
                    THEN
                        error = 2025;
                        error_message = 'Só Pode haver 1 **Endereço de Entrega** na aba *Endereços*!!';
                    ELSE
                    ----------------------------Obrigar Tipo de Logradouro
                        SELECT COUNT(C1."CardCode") INTO contador
                        FROM  CRD1 C1
                        WHERE C1."CardCode" = :list_of_cols_val_tab_del
                        AND C1."AdresType" = 'S'
                        AND (C1."AddrType" IS NULL OR C1."AddrType" = '');
                        IF contador > 0
                        THEN
                            error = 2026;
                            error_message = 'Preencher Campo **Tipo de Logradouro** no **Endereço de Entrega** na aba *Endereços*!!';
                        ELSE
                            SELECT DISTINCT COUNT("AdresType") INTO contador
                            FROM CRD1 T0 
                            WHERE T0."CardCode" = :list_of_cols_val_tab_del
                            AND T0."AdresType" = 'S'
                            AND ((T0."AddrType" NOT IN (SELECT UPPER("Name") 
                                                        FROM "@LOGRADOURO")));

                            IF contador > 0
                            THEN
                                error = 2026;
                                error_message = 'Campo **Tipo de Logradouro** no **Endereço de Entrega** na aba *Endereços* não existe,
                                                 favor informar um **Tipo de Logradouro** válido!';
                            END IF;
                        END IF;
                    ----------------------------Obrigar Rua na Entrega
                        SELECT COUNT(C1."CardCode") INTO contador
                        FROM  CRD1 C1
                        WHERE C1."CardCode" = :list_of_cols_val_tab_del
                        AND C1."AdresType" = 'S'
                        AND (C1."Street" IS NULL OR C1."Street" = '');
                        IF contador > 0
                        THEN
                            error = 2027;
                            error_message = 'Preencher Campo **Rua** no **Endereço de Entrega** na aba *Endereços*!!';
                        ELSE
                            SELECT COUNT(C1."CardCode") INTO contador
                            FROM  CRD1 C1
                            WHERE C1."CardCode" = :list_of_cols_val_tab_del
                            AND C1."AdresType" = 'S'
                            AND C1."Street" <> UPPER(C1."Street");
                            IF contador > 0
                            THEN
                                error = 2027;
                                error_message = 'O Campo **Rua** no **Endereço de Entrega** na aba *Endereços*, não está Maíusculo!!';
                            END IF;
                        END IF;
                    ----------------------------Obrigar Numero da Rua na Entrega
                        SELECT COUNT(C1."CardCode") INTO contador
                        FROM  CRD1 C1
                        WHERE C1."CardCode" = :list_of_cols_val_tab_del
                        AND C1."AdresType" = 'S'
                        AND (C1."StreetNo" IS NULL OR C1."StreetNo" = '');
                        IF contador > 0
                        THEN
                            error = 2028;
                            error_message = 'Preencher Campo **Rua Nº** no **Endereço de Entrega** na aba *Endereços*!!';
                        END IF;
                    ----------------------------Verifica Complemento
                        SELECT COUNT(C1."CardCode") INTO contador
                        FROM  CRD1 C1
                        WHERE C1."CardCode" = :list_of_cols_val_tab_del
                        AND C1."AdresType" = 'S'
                        AND (C1."Building" IS NOT NULL OR C1."Building" NOT LIKE '');
                        IF contador > 0
                        THEN
                            SELECT COUNT(C1."CardCode") INTO contador
                            FROM  CRD1 C1
                            WHERE C1."CardCode" = :list_of_cols_val_tab_del
                            AND C1."AdresType" = 'S'
                            AND C1."Building" NOT LIKE UPPER(C1."Building");
                            IF contador > 0
                            THEN
                                error = 2028;
                                error_message = 'O Campo **Complemento** no **Endereço de Entrega** na aba *Endereços*, não está Maiúsculo!!';
                            END IF;
                        END IF;
                    ----------------------------Obrigar CEP
                        SELECT COUNT(C1."CardCode") INTO contador
                        FROM  CRD1 C1
                        WHERE C1."CardCode" = :list_of_cols_val_tab_del
                        AND C1."AdresType" = 'S'
                        AND (C1."ZipCode" IS NULL OR C1."ZipCode" = '');
                        IF contador > 0
                        THEN
                            error = 2029;
                            error_message = 'Preencher Campo **CEP** no **Endereço de Entrega** na aba *Endereços*!!';
                        ELSE
                            SELECT COUNT(C1."CardCode") INTO contador FROM  CRD1 C1
                            WHERE C1."ZipCode" NOT LIKE_REGEXPR '^[0-9]{5}-[0-9]{3}$'
                            AND C1."AdresType" = 'S'
                            AND C1."CardCode" = :list_of_cols_val_tab_del;

                            IF contador > 0
                                THEN
                                    error = 2029;
                                    error_message = 'O Campo **CEP** no **Endereço de Entrega** na aba *Endereços*,não está no formato correto. EX: 00000-000';
                            END IF;
                        END IF;

                        ----------------------------Obrigar Bairro
                        SELECT COUNT(C1."CardCode") INTO contador
                        FROM  CRD1 C1
                        WHERE C1."CardCode" = :list_of_cols_val_tab_del
                        AND C1."AdresType" = 'S'
                        AND (C1."Block" IS NULL OR C1."Block" = '');
                        IF contador > 0
                        THEN
                            error = 2030;
                            error_message = 'Preencher Campo **Bairro** no **Endereço de Entrega** na aba *Endereços*!!';
                        ELSE
                            SELECT COUNT(C1."CardCode") INTO contador
                            FROM  CRD1 C1
                            WHERE C1."CardCode" = :list_of_cols_val_tab_del
                            AND C1."AdresType" = 'S'
                            AND C1."Block" <> UPPER(C1."Block");
                            IF contador > 0
                            THEN
                                error = 2030;
                                error_message = 'O Campo **Bairro** no **Endereço de Entrega** na aba *Endereços*, não está Maíusculo!!';
                            END IF;
                        END IF;

                        ----------------------------Obrigar Cidade
                        SELECT COUNT(C1."CardCode") INTO contador
                        FROM  CRD1 C1
                        WHERE C1."CardCode" = :list_of_cols_val_tab_del
                        AND C1."AdresType" = 'S'
                        AND (C1."City" IS NULL OR C1."City" = '');
                        IF contador > 0
                        THEN
                            error = 2031;
                            error_message = 'Preencher Campo **Cidade** no **Endereço de Entrega** na aba *Endereços*!!';
                        ELSE
                            SELECT DISTINCT COUNT(C1."AdresType") INTO contador
                            FROM CRD1 C1 
                            WHERE C1."CardCode" = :list_of_cols_val_tab_del 
                            AND ((C1."City" <> (SELECT "Name" 
                                                    FROM OCNT C0 WHERE C0."AbsId" = C1."County")));
                            IF contador > 0
                            THEN
                                error = 2031;
                                error_message = 'O Campo **Cidade** no **Endereço de Entrega** na aba *Endereços* está fora do padrão, deixar igual o campo Munícipio!';
                            END IF;
                        END IF;

                        ----------------------------Obrigar Estado
                        SELECT COUNT(C1."CardCode") INTO contador
                        FROM  CRD1 C1
                        WHERE C1."CardCode" = :list_of_cols_val_tab_del
                        AND C1."AdresType" = 'S'
                        AND (C1."State" IS NULL OR C1."State" = '');
                        IF contador > 0
                        THEN
                            error = 2032;
                            error_message = 'Preencher Campo **Estado** no **Endereço de Entrega** na aba *Endereços*!!';
                        END IF;

                         ----------------------------Obrigar Municipio
                        SELECT COUNT(C1."CardCode") INTO contador
                        FROM  CRD1 C1
                        WHERE C1."CardCode" = :list_of_cols_val_tab_del
                        AND C1."AdresType" = 'S'
                        AND (C1."County" IS NULL OR C1."County" = '');
                        IF contador > 0
                        THEN
                            error = 2033;
                            error_message = 'Preencher Campo **Município** no **Endereço de Entrega** na aba *Endereços*!!';
                        END IF;

                        ----------------------------Obrigar País
                        SELECT COUNT(C1."CardCode") INTO contador
                        FROM  CRD1 C1
                        WHERE C1."CardCode" = :list_of_cols_val_tab_del
                        AND C1."AdresType" = 'S'
                        AND (C1."Country" IS NULL OR C1."Country" = '');
                        IF contador > 0
                        THEN
                            error = 2034;
                            error_message = 'Preencher Campo **País/Região** no **Endereço de Entrega** na aba *Endereços*!!';
                        END IF;

                        -----------------------Valida Id Entrega  
                        SELECT TOP 1 "Address" INTO adress FROM CRD1
                        WHERE "AdresType" = 'S'
                        AND "CardCode" = :list_of_cols_val_tab_del;
                        
                        IF adress <> 'ENTREGA'
                            THEN
                                error = 2035;
                                error_message = 'O Id do endereço de Entrega está incorreto, o padrão é ENTREGA';
                        END IF;

                    END IF;

                END IF;
            END IF;
            ----------------------------Obrigar Ter Info na CRD7
            SELECT COUNT(C7."CardCode") INTO contador
            FROM  CRD7 C7
            WHERE C7."CardCode" = :list_of_cols_val_tab_del
            AND (C7."Address"  IS NULL OR C7."Address" LIKE '');
            IF contador = 0
                THEN
                error = 2036;
                error_message = 'Necessário preencher **Informações Fiscais** na Aba *Contabilidade* > *Imposto* ';
            ELSE    
            ----------------------------Obrigar ter CNAE
                SELECT COUNT(C0."CardCode") INTO contador 
                FROM OCRD C0  
                INNER JOIN CRD7 C7
                ON C7."CardCode" = C0."CardCode"
                WHERE C7."CardCode" = :list_of_cols_val_tab_del
                AND C0."GroupCode" IN (101,100)
                AND (C7."Address" IS NULL OR C7."Address" = '')
                AND (C7."CNAEId" IS NULL OR C7."CNAEId" = -1);
                
                IF contador > 0
                    THEN
                        error = 2037;
                        error_message = 'Necessário preencher **Código CNAE** na Aba *Contabilidade* > *Imposto* > *Identif.Fiscais*';
                END IF;
            ----------------------------Obrigar ter CNPJ
                SELECT COUNT(C0."CardCode") INTO contador 
                FROM OCRD C0  
                INNER JOIN CRD7 C7
                ON C7."CardCode" = C0."CardCode"
                WHERE C7."CardCode" = :list_of_cols_val_tab_del
                AND C0."GroupCode" IN (101,100)
                AND (C7."Address" IS NULL OR C7."Address" = '')
                AND (C7."TaxId0" IS NULL OR C7."TaxId0" = '');
                
                IF contador > 0
                    THEN
                        error = 2038;
                        error_message = 'Necessário preencher **CNPJ** na Aba *Contabilidade* > *Imposto* > *Identif.Fiscais*';
                END IF;

            ----------------------------Obrigar ter CPF
                SELECT COUNT(C0."CardCode") INTO contador 
                FROM OCRD C0  
                INNER JOIN CRD7 C7
                ON C7."CardCode" = C0."CardCode"
                WHERE C7."CardCode" = :list_of_cols_val_tab_del
                AND C0."GroupCode" IN (102)
                AND (C7."Address" IS NULL OR C7."Address" = '')
                AND (C7."TaxId4" IS NULL OR C7."TaxId4" = '');
                
                IF contador > 0
                    THEN
                        error = 2039;
                        error_message = 'Necessário preencher **CPF** na Aba *Contabilidade* > *Imposto* > *Identif.Fiscais*';
                END IF;
             ----------------------------Obrigar ter INSCRIÇÃO ESTADUAL
                SELECT COUNT(C0."CardCode") INTO contador 
                FROM OCRD C0  
                INNER JOIN CRD7 C7
                ON C7."CardCode" = C0."CardCode"
                WHERE C7."CardCode" = :list_of_cols_val_tab_del
                AND C0."GroupCode" IN (101,100)
                AND (C7."Address" IS NULL OR C7."Address" = '')
                AND (C7."TaxId1" IS NULL OR C7."TaxId1" = '');
                
                IF contador > 0
                    THEN
                        error = 2040;
                        error_message = 'Necessário preencher **Inscrição Estadual** na Aba *Contabilidade* > *Imposto* > *Identif.Fiscais*';
                END IF;
            END IF;

            SELECT DISTINCT COUNT(*) INTO contador
            FROM OCRD T0 
            WHERE T0."CardCode" = :list_of_cols_val_tab_del 
            AND T0."U_Regime_Tributario" IS NULL;
            IF contador > 0
            THEN
                error = 2014;
                error_message = 'Preencher campo Regime Tributário na aba de campos de ususário!';
            END IF;
END IF;

--------------------------------------------------------------------------------------------------------------------------------
 
--Start IntegrationBank
 
SELECT CURRENT_SCHEMA INTO companyDbIntBank FROM DUMMY;
Call "IV_IB_TransNotificationValidateIntBank"(companyDbIntBank, companyDbIntBank, 'IV_IB_Setting', 'IV_IB_BillOfExchange', 'IV_IB_BillOfExchangeInstallment', 'IV_IB_CompanyLocal', object_type, transaction_type, list_of_cols_val_tab_del, error, error_message);
--End IntegrationBank--Start BankPlus
Call "IV_IB_TransacaoValidacaoPagamentoBankPlus"(companyDbIntBank, object_type, transaction_type, list_of_cols_val_tab_del, error, error_message);
--End BankPlus
 
--Start TaxOne
SELECT CURRENT_SCHEMA INTO currDbNameForTaxOne FROM DUMMY;
 
                IF (IFNULL(error,0)=0)
                THEN
 
                    Call "TransNotificationValidate"(currDbNameForTaxOne, object_type, list_of_cols_val_tab_del, error, error_message);
 
                END IF;
--End TaxOne
-- Select the return values
 
 
select :error, :error_message FROM dummy;
 
end;