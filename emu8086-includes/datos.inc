; Las funciones de archivo de DOS esperan nombres terminados en cero.
nombre_archivo_calif db 'CALIF.TXT', 0
nombre_archivo_final db 'FINAL.XLS', 0

; Cadenas terminadas en '$' para la funcion 09h de INT 21h.
texto_menu          db '====================================', CR, LF
                    db ' SISTEMA DE GESTION ACADEMICA', CR, LF
                    db '====================================', CR, LF
                    db '1. Registrar Alumnos y Notas', CR, LF
                    db '2. Generar Reporte y Estadisticas', CR, LF
                    db '3. Ver Reporte Final (.XLS)', CR, LF
                    db '4. Salir', CR, LF
                    db '------------------------------------', CR, LF
                    db 'Seleccione una opcion: $'

encabezado_registro db '====================================', CR, LF
                     db ' REGISTRO DE ALUMNOS Y NOTAS', CR, LF
                     db '====================================', CR, LF, '$'
encabezado_reporte  db '====================================', CR, LF
                     db ' GENERAR REPORTE Y ESTADISTICAS', CR, LF
                     db '====================================', CR, LF, '$'
encabezado_visualizacion db '====================================', CR, LF
                          db ' CONTENIDO DE FINAL.XLS', CR, LF
                          db '====================================', CR, LF, '$'
encabezado_salida   db '====================================', CR, LF
                     db ' SISTEMA DE GESTION ACADEMICA', CR, LF
                     db '====================================', CR, LF, '$'

solicitud_nombre     db 'Ingrese el nombre del alumno: $'
solicitud_nota1      db 'Ingrese la nota 1: $'
solicitud_nota2      db 'Ingrese la nota 2: $'
solicitud_nota3      db 'Ingrese la nota 3: $'
msg_nombre_vacio     db 'Error. El nombre no puede estar vacio.', CR, LF, '$'
msg_nombre_invalido  db 'Error. El nombre no puede contener comas.', CR, LF, '$'
msg_nota_invalida    db 'Error. La nota debe ser un entero entre 0 y 20.', CR, LF, '$'
msg_opcion_invalida  db CR, LF, 'Opcion invalida.', CR, LF, '$'
msg_guardado         db CR, LF, 'Datos guardados correctamente.', CR, LF, '$'
msg_error_guardado   db CR, LF, 'Error. No se pudo escribir CALIF.TXT.', CR, LF, '$'

msg_procesando       db 'Procesando archivo CALIF.TXT...', CR, LF
                     db 'Generando archivo FINAL.XLS...', CR, LF, '$'
msg_falta_calif      db 'Error. No existe el archivo CALIF.TXT.', CR, LF, '$'
msg_falta_final      db 'Error. No existe el archivo FINAL.XLS.', CR, LF, '$'
msg_error_reporte    db 'Error. No se pudo generar FINAL.XLS.', CR, LF, '$'
msg_reporte_correcto db CR, LF, 'Reporte generado correctamente.', CR, LF, '$'
titulo_estadisticas  db CR, LF, '===== ESTADISTICAS =====', CR, LF, '$'
msg_total            db 'Total de alumnos procesados: $'
msg_aprobados        db 'Cantidad de aprobados: $'
msg_reprobados       db 'Cantidad de reprobados: $'
msg_registros_invalidos db 'Registros invalidos omitidos: $'

msg_pausa            db CR, LF, 'Presione una tecla para continuar...$'
msg_salida           db 'Saliendo del sistema...', CR, LF, '$'

; Estas cadenas no llevan '$': se escriben indicando una longitud explicita.
coma                db ','
bytes_nueva_linea   db CR, LF
texto_aprobado      db 'APROBADO'
LONGITUD_APROBADO   EQU ($ - texto_aprobado)
texto_reprobado     db 'REPROBADO'
LONGITUD_REPROBADO  EQU ($ - texto_reprobado)

; Formato requerido por INT 21h/0Ah:
; [cantidad maxima][cantidad leida][caracteres...][CR].
buffer_entrada      db MAXIMO_NOMBRE, 0, (MAXIMO_NOMBRE + 1) dup (0)
buffer_menu         db 2, 0, 3 dup (0)

buffer_linea        db (MAXIMO_LINEA + 1) dup (0)
buffer_visualizacion db TAMANO_BUFFER_VISTA dup (0)
nombre_cifrado      db (MAXIMO_NOMBRE + 1) dup (0)
buffer_numero       db 6 dup (0)
caracter_archivo    db 0

manejador_archivo   dw 0
manejador_entrada   dw 0
manejador_salida    dw 0
fin_analisis        dw 0
longitud_cifrado    dw 0
linea_desbordada    db 0

nota1                dw 0
nota2                dw 0
nota3                dw 0
promedio             dw 0
contador_total       dw 0
contador_aprobados   dw 0
contador_reprobados  dw 0
contador_invalidos   dw 0
