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
create table ImatgesProducte(
producte_id number primary key,
descripcio varchar2(250),
imatge BLOB DEFAULT EMPTY_BLOB(),
format varchar2(250)
);
/
--Crear la taula AudiosComanda(comanda_id, audio BLOB,durada_segons).
create table AudiosComanda(
comanda_id number primary key,
audio BLOB DEFAULT EMPTY_BLOB(),
durada_segons number(2)
);
/
--Crear una funció xml_producte(producte_id) que generi un document XML amb les dades del producte i referències a les imatges relacionades
Create or replace procedure xml_producte (producte_id in number) as
 v_file BFILE;
 v_clo CLOB;
BEGIN
 v_file := BFILENAME('DOCS_DIR', 'xml_dades');
 if dbms_lob.fileexists(v_file) = 1 Then
    select contenido into v_clo from documentos where id = producte_id for update;
    dmb_lob.open(v_file, dbms_lob.lob_readonly);
    dmb_lob.loadfromfile(v_clo, v_file, dbms_lob.getlength(v_file));
    dmb_lob.close(v_file);
 end if;
end;
/
 
CREATE OR REPLACE PROCEDURE load_doc (p_id IN NUMBER, p_file IN VARCHAR2) AS
  v_bfile BFILE;
  v_clob CLOB;
BEGIN
  v_bfile := BFILENAME('DOCS_DIR', p_file);
  IF DBMS_LOB.FILEEXISTS(v_bfile) = 1 THEN
    SELECT contenido INTO v_clob FROM documentos WHERE id = p_id FOR UPDATE;
    DBMS_LOB.OPEN(v_bfile, DBMS_LOB.LOB_READONLY);
    DBMS_LOB.LOADFROMFILE(v_clob, v_bfile, DBMS_LOB.GETLENGTH(v_bfile));
    DBMS_LOB.CLOSE(v_bfile);
  END IF;
END;
--para llamar
?CALL load_doc(1, 'ia_articulo.txt');

--Crear una taula DocumentsXML(id, xml_data XMLType) per emmagatzemar documents XML
create or replace table DocumentsXML(
id number primary key,
xml_data XMLType
);
/
