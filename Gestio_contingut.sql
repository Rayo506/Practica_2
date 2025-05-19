/*
Objectiu: Gestionar imatges i àudios relacionats amb productes i comandes, i
treballar amb documents XML i consultes XQuery mitjançant Oracle i Python.
Part Oracle:
1. Crear la taula ImatgesProducte(producte_id, descripcio, imatge
BLOB, format).

2. Crear la taula AudiosComanda(comanda_id, audio BLOB,
durada_segons).

3. Crear una funció xml_producte(producte_id) que generi un document
XML amb les dades del producte i referències a les imatges relacionades.

4. Crear una taula DocumentsXML(id, xml_data XMLType) per
emmagatzemar documents XML.

5. Implementar consultes amb XQuery per:
• Obtenir imatges de productes amb format específic
• Llistar productes amb més d'una imatge
*/

--La taula ImatgesProducte(producte_id, descripcio, imatge BLOB, format)
create table ImatgesProducte(
producte_id number primary key,
descripcio varchar2(250),
imatge BLOB DEFAULT EMPTY_BLOB(),
format varchar2(250)
);
/
--La taula AudiosComanda(comanda_id, audio BLOB,durada_segons).
create table AudiosComanda(
comanda_id number primary key,
audio BLOB DEFAULT EMPTY_BLOB(),
durada_segons number
);
/

--Funció xml_producte(producte_id) que generi un document XML amb les dades del producte i referències a les imatges relacionades
CREATE OR REPLACE FUNCTION xml_producte(p_producte_id IN NUMBER) RETURN XMLType IS
  v_xml XMLType;
  v_count NUMBER;
BEGIN
  -- Verificar si el producto existe
  SELECT COUNT(*) INTO v_count 
  FROM ImatgesProducte 
  WHERE producte_id = p_producte_id;
  
  IF v_count = 0 THEN
    RETURN XMLType('<error>Producte no trobat</error>');
  END IF;
  
  -- Generar el XML con los datos del producto y sus imágenes
  SELECT XMLELEMENT("producte",
           XMLATTRIBUTES(
             p_producte_id AS "id",
             (SELECT descripcio FROM ImatgesProducte WHERE producte_id = p_producte_id) AS "descripcio",
             (SELECT format FROM ImatgesProducte WHERE producte_id = p_producte_id) AS "format"
           ),
           XMLELEMENT("imatges",
             (SELECT XMLAGG(
                        XMLELEMENT("imatge",
                          XMLATTRIBUTES(
                            producte_id AS "producte_id",
                            descripcio AS "descripcio_imatge",
                            format AS "format_imatge"
                          )
                        )
                      )
              FROM ImatgesProducte
              WHERE producte_id = p_producte_id)
           )
         )
  INTO v_xml
  FROM dual;
  
  RETURN v_xml;
EXCEPTION
  WHEN OTHERS THEN
    RETURN XMLType('<error>'||SQLERRM||'</error>');
END xml_producte;
/

-- Crear una taula DocumentsXML(id, xml_data XMLType) per emmagatzemar documents XML
create table DocumentsXML(
    id number primary key,
    xml_data XMLType
)XMLTYPE xml_data STORE AS BASICFILE BINARY XML;
/

--Inserts
--Ruta 
CREATE OR REPLACE DIRECTORY DOCS_DIR AS '/home/oracle/Documents';
GRANT READ ON DIRECTORY DOCS_DIR TO PUBLIC;
/
--Inserts ImatgesProducte
DECLARE
  v_bfile BFILE;
  v_blob  BLOB;
BEGIN
  -- Producto 1
  INSERT INTO ImatgesProducte (producte_id, descripcio, imatge, format)
  VALUES (1, 'Imatge de producte 1', EMPTY_BLOB(), 'jpg')
  RETURNING imatge INTO v_blob;

  v_bfile := BFILENAME('DOCS_DIR', 'imagen1.jpg');
  dbms_lob.fileopen(v_bfile, dbms_lob.file_readonly);
  dbms_lob.loadfromfile(v_blob, v_bfile, dbms_lob.getlength(v_bfile));
  dbms_lob.fileclose(v_bfile);

  -- Producto 2
  INSERT INTO ImatgesProducte (producte_id, descripcio, imatge, format)
  VALUES (2, 'Imatge de producte 2', EMPTY_BLOB(), 'jpg')
  RETURNING imatge INTO v_blob;

  v_bfile := BFILENAME('DOCS_DIR', 'imagen2.jpg');
  dbms_lob.fileopen(v_bfile, dbms_lob.file_readonly);
  dbms_lob.loadfromfile(v_blob, v_bfile, dbms_lob.getlength(v_bfile));
  dbms_lob.fileclose(v_bfile);
  COMMIT;
END;
/
--Inserts AudiosComanda
DECLARE
  v_bfile BFILE;
  v_blob  BLOB;
BEGIN
  -- Comanda 1
  INSERT INTO AudiosComanda (comanda_id, audio, durada_segons)
  VALUES (1, EMPTY_BLOB(), 15)
  RETURNING audio INTO v_blob;

  v_bfile := BFILENAME('DOCS_DIR', 'audio1.mp3');
  dbms_lob.fileopen(v_bfile, dbms_lob.file_readonly);
  dbms_lob.loadfromfile(v_blob, v_bfile, dbms_lob.getlength(v_bfile));
  dbms_lob.fileclose(v_bfile);

  -- Comanda 2
  INSERT INTO AudiosComanda (comanda_id, audio, durada_segons)
  VALUES (2, EMPTY_BLOB(), 25)
  RETURNING audio INTO v_blob;

  v_bfile := BFILENAME('DOCS_DIR', 'audio2.mp3');
  dbms_lob.fileopen(v_bfile, dbms_lob.file_readonly);
  dbms_lob.loadfromfile(v_blob, v_bfile, dbms_lob.getlength(v_bfile));
  dbms_lob.fileclose(v_bfile);
  COMMIT;
END;
/
--XML meidnate funcion
INSERT INTO DocumentsXML (id, xml_data)
VALUES (1, xml_producte(1));

INSERT INTO DocumentsXML (id, xml_data)
VALUES (2, xml_producte(2));
COMMIT;
/

--Implementar consultes amb XQuery per:
--Obtenir imatges de productes amb format específic en este caso jpg
SELECT x.*
FROM DocumentsXML d,
     XMLTABLE(
       '/producte/imatges/imatge[@format_imatge="jpg"]'
       PASSING d.xml_data
       COLUMNS
         producte_id     NUMBER       PATH '@producte_id',
         descripcio      VARCHAR2(250) PATH '@descripcio_imatge',
         format_imatge   VARCHAR2(250) PATH '@format_imatge'
     ) x;
/
--Llistar productes amb més d'una imatge
SELECT id
FROM DocumentsXML d
WHERE XMLExists(
  'count(/producte/imatges/imatge) > 1'
  PASSING d.xml_data
);
/

--drop table DocumentsXML;
--drop table AudiosComanda;
--drop table ImatgesProducte;




