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

--Crear la taula ImatgesProducte(producte_id, descripcio, imatge BLOB, format)
create or replace table  ImatgesProducte(
producte_id number primary key,
descripcio varchar2(250),
imatge BLOB,
format varchar2(250)
);

--Crear la taula AudiosComanda(comanda_id, audio BLOB,durada_segons).
create or replace table AudiosComanda(
comanda_id number primary key,
audio BLOB,
durada_segons number(2)
);

--Crear una funció xml_producte(producte_id) que generi un document XML amb les dades del producte i referències a les imatges relacionades
CREATE OR REPLACE PROCEDURE load_doc (producte_id IN NUMBER) AS
  v_bfile BFILE;
BEGIN
  v_bfile := BFILENAME('DOCS_DIR', p_file);
  IF DBMS_LOB.FILEEXISTS(v_bfile) = 1 THEN
    SELECT contenido INTO v_clob FROM documentos WHERE id = p_id FOR UPDATE;
    DBMS_LOB.OPEN(v_bfile, DBMS_LOB.LOB_READONLY);
    DBMS_LOB.LOADFROMFILE(v_clob, v_bfile, DBMS_LOB.GETLENGTH(v_bfile));
    DBMS_LOB.CLOSE(v_bfile);
  END IF;
END;
?CALL load_doc(1, 'ia_articulo.txt');

--Crear una taula DocumentsXML(id, xml_data XMLType) per emmagatzemar documents XML
create or replace table DocumentsXML(
id number primary key,
xml_data XMLType
);