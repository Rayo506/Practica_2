# Desenvolupar el script multimedia_tools.py que:
#• Carrega imatges (.jpg) i àudios (.mp3) des del sistema de fitxers.
#• Desa els fitxers com a BLOB a les respectives taules.
#• Desa documents XML a la taula DocumentsXML. ==> MEDIANTE EL PROCESO
#• Executa consultes XQuery sobre els documents XML i mostra els resultats.
#• Consulta la mida dels fitxers desats i mostra un resum.

#• Els scripts Python han d'utilitzar el mòdul cx_Oracle i gestionar connexions amb control d'errors.
#• Tots els scripts Python han d'imprimir per pantalla els resultats de les operacions 
# i indicar clarament si les validacions han estat correctes.
import cx_Oracle
import os
import sys

# Configuració de la connexió a la base de dades Oracle
DB_USER = "SYSTEM"
DB_PASS = "oracle"
DB_DSN  = "192.168.56.2/FREEPDB1"

def obtenir_connexio():
    
    #Intenta establir una connexió amb la base de dades Oracle.
    #En cas d'error, mostra missatge i surt del programa.
    
    try:
        conn = cx_Oracle.connect(DB_USER, DB_PASS, DB_DSN)
        return conn
    except cx_Oracle.Error as e:
        print(f"[ERROR] No s'ha pogut connectar a la base de dades: {e}")
        print("Comprova les credencials o la configuració de connexió.")
        sys.exit(1)

def cargar_img_audio(extension, ruta, id, descripcio='', format=''):

    #Carrega un fitxer (imatge o àudio) des del sistema de fitxers i el desa a la base de dades
    #com a BLOB a la taula corresponent segons l'extensió.
    
    conn = obtenir_connexio()
    cursor = None
    try:
        cursor = conn.cursor()

        if not os.path.exists(ruta):
            print(f"Archivo no encontrado: {ruta}")
            return

        with open(ruta, 'rb') as f:
            blob_data = f.read()

        file_size = len(blob_data)
        print(f"Cargando archivo: {ruta} ({file_size} bytes)")

        if extension.lower() in ['.jpg', '.png']:
            cursor.execute("""
                INSERT INTO ImatgesProducte (producte_id, descripcio, imatge, format)
                VALUES (:1, :2, :3, :4)
            """, (id, descripcio, blob_data, format))
            print("Imagen guardada correctamente en ImatgesProducte.")

        elif extension.lower() in ['.mp3', '.mov']:
            durada = int(input(f"Introduce duración (segundos) para el audio {ruta}: "))
            cursor.execute("""
                INSERT INTO AudiosComanda (comanda_id, audio, durada_segons)
                VALUES (:1, :2, :3)
            """, (id, blob_data, durada))
            print("Audio guardado correctamente en AudiosComanda.")

        else:
            print(f"Extensión no soportada: {extension}")
            return

        conn.commit()

    except cx_Oracle.Error as e:
        print(f"Error en la base de datos: {e}")
    finally:
        if cursor:
            cursor.close()
        conn.close()

def guardar_xml(producte_id):
    
    #Desa un document XML generat per la funció PL/SQL `xml_producte` a la taula DocumentsXML.
    
    conn = obtenir_connexio()
    cursor = None
    try:
        cursor = conn.cursor()

        cursor.execute("""
            INSERT INTO DocumentsXML (id, xml_data)
            VALUES (:1, xml_producte(:2))
        """, (producte_id, producte_id))
        conn.commit()
        print(f"XML del producte {producte_id} guardat correctament.")

    except cx_Oracle.Error as e:
        print(f"Error al guardar XML: {e}")
    finally:
        if cursor:
            cursor.close()
        conn.close()

def consultar_xquery():
    
    #Executa diferents consultes XQuery sobre la taula DocumentsXML:
    #- Obté imatges en format JPG
    #- Llista productes amb més d'una imatge
    #- Mostra un resum de mida de fitxers (imatges i àudios)
    
    conn = obtenir_connexio()
    cursor = None
    try:
        cursor = conn.cursor()

        print("\n--- Consultes XQuery ---")

        print("Imatges amb format JPG:")
        cursor.execute("""
            SELECT id, extractValue(value(t), '/imatge/@format_imatge')
            FROM DocumentsXML d,
                 TABLE(XMLSequence(
                     EXTRACT(d.xml_data, '/producte/imatges/imatge[@format_imatge="jpg"]')
                 )) t
        """)
        for row in cursor:
            print(row)

        print("\nProductes amb més d'una imatge:")
        cursor.execute("""
            SELECT id
            FROM DocumentsXML
            WHERE XMLExists('count(/producte/imatges/imatge) > 1' PASSING xml_data)
        """)
        for row in cursor:
            print(f"Producte ID: {row[0]}")

        print("\n--- Mida dels fitxers desats ---")
        cursor.execute("""
            SELECT COUNT(*), NVL(SUM(DBMS_LOB.getlength(imatge)), 0)
            FROM ImatgesProducte
        """)
        img_count, img_size = cursor.fetchone()
        print(f"ImatgesProducte - Total: {img_count} fitxers, Mida total: {img_size} bytes")

        cursor.execute("""
            SELECT COUNT(*), NVL(SUM(DBMS_LOB.getlength(audio)), 0)
            FROM AudiosComanda
        """)
        audio_count, audio_size = cursor.fetchone()
        print(f"AudiosComanda - Total: {audio_count} fitxers, Mida total: {audio_size} bytes")

        total_files = img_count + audio_count
        total_size = img_size + audio_size
        print(f"\nResum total: {total_files} fitxers, {total_size} bytes")

    except cx_Oracle.Error as e:
        print(f"Error XQuery: {e}")
    finally:
        if cursor:
            cursor.close()
        conn.close()

# Programa principal
if __name__ == "__main__":
    print("Iniciant càrrega multimedia...")

    # Càrrega d’imatges
    cargar_img_audio('.jpg', 'imagen1.jpg', 3, 'Imatge del producte A', 'jpg')
    cargar_img_audio('.jpg', 'imagen2.jpg', 4, 'Imatge del producte B', 'jpg')

    # Càrrega d’àudios
    cargar_img_audio('.mp3', 'audio1.mp3', 3)
    cargar_img_audio('.mp3', 'audio2.mp3', 4)

    # Guardar XMLs generats amb la funció xml_producte
    guardar_xml(3)
    guardar_xml(4)

    # Executar consultes XQuery
    consultar_xquery()

    print("Script finalitzat.")
