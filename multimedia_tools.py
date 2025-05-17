#6. Desenvolupar el script multimedia_tools.py que:
#• Carrega imatges (.jpg) i àudios (.mp3) des del sistema de fitxers.
#• Desa els fitxers com a BLOB a les respectives taules.
#• Desa documents XML a la taula DocumentsXML. ==> MEDIANTE EL PROCESO
#• Executa consultes XQuery sobre els documents XML i mostra els resultats.
#• Consulta la mida dels fitxers desats i mostra un resum.

#• Els scripts Python han d'utilitzar el mòdul cx_Oracle i gestionar connexions amb control d'errors.
#• Tots els scripts Python han d'imprimir per pantalla els resultats de les operacions 
# i indicar clarament si les validacions han estat correctes.

import cx_Oracle

def cargar_img_audio(extension, ruta):
    #• Carrega imatges (.jpg) i àudios (.mp3) des del sistema de fitxers.
    conn = cx_Oracle.connect('SYSTEM', 'oracle', '192.168.56.2/FREEPDB1')
    cursor = conn.cursor()

    archivo = ruta + "" + extension #EL ARCHIVO 

    # Leer y cargar la imagen
    with open(archivo, 'rb') as f:
        blob_data = f.read()

    cursor.execute("""
        INSERT INTO my_docs (doc_id, doc_title, doc_blob)
        VALUES (:1, :2, :3)
    """, (doc_id, titulo, blob_data)) #CAMBIAR

    conn.commit()
    cursor.close()
    conn.close()
    print("Imagen cargada correctamente.")


# Llamada funcion
if __name__ == "__main__":
   extension = ".mp3"
   ruta = ""  # Ejemplo: "C:/Users/TuUsuario/Desktop/foto.jpg"

   cargar_img_audio(extension, ruta)