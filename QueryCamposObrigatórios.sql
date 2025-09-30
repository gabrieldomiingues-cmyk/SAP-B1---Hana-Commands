SELECT C0."CardCode" 
FROM  OCRD C0
WHERE (C0."CardName" IS NULL OR  C0."CardName" = ''
    OR ((C0."Phone1" IS NULL OR C0."Phone1" = '')
        AND (C0."Cellular" IS NULL OR C0."Cellular" = ''))
    OR C0."E_Mail" IS NULL OR  C0."E_Mail" = ''
    /*TRATATIVA VALIDA QTD DE ENDEREÇOS*/
    OR (SELECT DISTINCT COUNT("AdresType") FROM CRD1 T0 
        WHERE T0."CardCode" = C0."CardCode") < 2
    /*VALIDA INFORMAÇÕES INDENTIFICAÇÕES FISCAIS*/
    OR (SELECT COUNT(*) FROM CRD7 T0 
        WHERE T0."CardCode" = C0."CardCode"
        AND C0."GroupCode" IN (101,100)
        AND (T0."Address" IS NULL OR T0."Address" = '')
        AND ((T0."TaxId0" IS NULL OR T0."TaxId0" = '')
        OR (T0."TaxId1" IS NULL OR T0."TaxId1" = '')
        OR (T0."CNAEId" IS NULL OR T0."CNAEId" = -1))) = 1
    OR (SELECT COUNT(*) FROM CRD7 T0 
        WHERE T0."CardCode" = C0."CardCode"
        AND C0."GroupCode" IN (102)
        AND (T0."Address" IS NULL OR T0."Address" = '')
        AND (T0."TaxId4" IS NULL OR T0."TaxId4" = '')) = 1
    /*VALIDA INFORMAÇÕES DE ENDEREÇO*/
    OR (SELECT DISTINCT COUNT("AdresType") FROM CRD1 T0 
        WHERE T0."CardCode" = C0."CardCode"
        AND ((T0."Street" IS NULL OR T0."Street" = '')
            OR (T0."Block" IS NULL OR T0."Block" = '')
            OR (T0."ZipCode" IS NULL OR T0."ZipCode" = '')
            OR (T0."City" IS NULL OR T0."City" = '')
            OR (T0."County" IS NULL OR T0."County" = '')
            OR (T0."Country" IS NULL OR T0."Country" = '')
            OR (T0."State" IS NULL OR T0."State" = '')
            OR (T0."AddrType" IS NULL OR T0."AddrType" = ''))) <> 0);