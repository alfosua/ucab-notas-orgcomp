; Sistema de Gestion Academica para EMU8086.
; Se compila como programa COM y debe ejecutarse en un directorio donde DOS
; pueda crear y modificar CALIF.TXT y FINAL.XLS.

org 100h
jmp Inicio

; ===================== constantes.inc =====================
; Limites de entrada y tamanos de los buffers del sistema.

MAXIMO_NOMBRE         EQU 50
MAXIMO_LINEA          EQU 127
TAMANO_BUFFER_VISTA EQU 512

; Secuencia DOS/Windows usada para terminar cada registro de texto.
CR                 EQU 13
LF                 EQU 10

; ===================== macros.inc =========================
; Macros breves de presentacion. La logica reutilizable permanece en
; procedimientos para evitar expandir innecesariamente el programa COM.

IMPRIMIR MACRO mensaje
    lea dx, mensaje
    call ImprimirCadena
ENDM

NUEVA_LINEA MACRO
    call ImprimirNuevaLinea
ENDM

; ===================== datos.inc ==========================
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

; ===================== entrada_salida.inc =================
; Entrada/salida por consola, conversion numerica y avisos sonoros.

ImprimirCadena PROC NEAR
    ; Entrada: DS:DX apunta a una cadena terminada en '$'.
    mov ah, 09h
    int 21h
    ret
ImprimirCadena ENDP

ImprimirNuevaLinea PROC NEAR
    push ax
    push dx
    mov ah, 02h
    mov dl, CR
    int 21h
    mov dl, LF
    int 21h
    pop dx
    pop ax
    ret
ImprimirNuevaLinea ENDP

LimpiarPantalla PROC NEAR
    ; Restablecer el modo de texto 80x25 tambien limpia la pantalla.
    push ax
    mov ax, 0003h
    int 10h
    pop ax
    ret
LimpiarPantalla ENDP

LeerEntradaBuffer PROC NEAR
    ; Entrada: DS:DX apunta a un buffer con formato de INT 21h/0Ah.
    ; Se borra la longitud anterior para poder reutilizar el mismo buffer.
    push ax
    push bx
    mov bx, dx
    mov byte ptr [bx + 1], 0
    mov ah, 0Ah
    int 21h
    pop bx
    pop ax
    ret
LeerEntradaBuffer ENDP

LeerOpcionMenu PROC NEAR
    ; Salida: AL contiene el caracter escrito, o cero si no fue exactamente uno.
    push bx
    push dx
    lea dx, buffer_menu
    call LeerEntradaBuffer
    lea bx, buffer_menu
    cmp byte ptr [bx + 1], 1
    jne EntradaMenuInvalida
    mov al, [bx + 2]
    jmp FinEntradaMenu

EntradaMenuInvalida:
    xor al, al

FinEntradaMenu:
    pop dx
    pop bx
    ret
LeerOpcionMenu ENDP

LeerNumeroBuffer PROC NEAR
    ; Convierte el contenido decimal de buffer_entrada a AX.
    ; Salida: CF=0 y AX=0..20 si es valido; CF=1 en cualquier otro caso.
    push bx
    push cx
    push dx
    push si
    push di

    xor ax, ax
    xor cx, cx
    mov cl, byte ptr buffer_entrada[1]
    cmp cx, 0
    jne NumeroTieneEntrada
    jmp NumeroSinSignoInvalido
NumeroTieneEntrada:
    lea si, buffer_entrada[2]

BucleNumeroSinSigno:
    mov dl, [si]
    cmp dl, '0'
    jb NumeroSinSignoInvalido
    cmp dl, '9'
    ja NumeroSinSignoInvalido
    sub dl, '0'
    xor dh, dh
    ; DI conserva el digito porque MUL utiliza DX:AX para el resultado.
    mov di, dx
    mov bx, 10
    mul bx
    or dx, dx
    jnz NumeroSinSignoInvalido
    add ax, di
    cmp ax, 20
    ja NumeroSinSignoInvalido
    inc si
    loop BucleNumeroSinSigno
    clc
    jmp FinNumeroSinSigno

NumeroSinSignoInvalido:
    stc

FinNumeroSinSigno:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    ret
LeerNumeroBuffer ENDP

LeerNota PROC NEAR
    ; Entrada: DS:DX apunta al mensaje de solicitud.
    ; Salida: AX contiene una nota validada entre 0 y 20.
    ; El procedimiento no retorna hasta recibir una entrada correcta.
    push bx
    push dx
    mov bx, dx

LeerNotaNuevamente:
    mov dx, bx
    call ImprimirCadena
    lea dx, buffer_entrada
    call LeerEntradaBuffer
    call LeerNumeroBuffer
    jnc FinLecturaNota
    IMPRIMIR msg_nota_invalida
    call SonidoError
    jmp LeerNotaNuevamente

FinLecturaNota:
    pop dx
    pop bx
    ret
LeerNota ENDP

NumeroATexto PROC NEAR
    ; Entrada: AX contiene un entero sin signo.
    ; Salida: DS:DX apunta al primer digito y CX indica cuantos bytes escribir.
    ; Los digitos se generan de derecha a izquierda dentro de buffer_numero.
    push ax
    push bx
    push di

    lea di, buffer_numero[6]
    xor cx, cx
    mov bx, 10
    cmp ax, 0
    jne BucleConversionNumero
    dec di
    mov byte ptr [di], '0'
    inc cx
    jmp FinConversionNumero

BucleConversionNumero:
    xor dx, dx
    div bx
    add dl, '0'
    dec di
    mov [di], dl
    inc cx
    cmp ax, 0
    jne BucleConversionNumero

FinConversionNumero:
    mov dx, di
    pop di
    pop bx
    pop ax
    ret
NumeroATexto ENDP

ImprimirSinSigno PROC NEAR
    ; El manejador 1 representa la salida estandar de DOS.
    push ax
    push bx
    push cx
    push dx
    call NumeroATexto
    mov bx, 1
    mov ah, 40h
    int 21h
    pop dx
    pop cx
    pop bx
    pop ax
    ret
ImprimirSinSigno ENDP

PausarPantalla PROC NEAR
    push ax
    IMPRIMIR msg_pausa
    mov ah, 08h
    int 21h
    pop ax
    ret
PausarPantalla ENDP

SonidoError PROC NEAR
    ; El caracter BEL (07h) solicita un aviso al altavoz de la consola.
    push ax
    push dx
    mov ah, 02h
    mov dl, 07h
    int 21h
    pop dx
    pop ax
    ret
SonidoError ENDP

SonidoExito PROC NEAR
    push ax
    push dx
    mov ah, 02h
    mov dl, 07h
    int 21h
    pop dx
    pop ax
    ret
SonidoExito ENDP

; ===================== archivos.inc =======================
; Operaciones de archivo mediante INT 21h y funciones auxiliares de escritura.

EscribirBytes PROC NEAR
    ; Entrada: BX=manejador, DS:DX=datos, CX=longitud.
    ; Salida: CF=1 si DOS falla o escribe menos bytes de los solicitados.
    push ax
    mov ah, 40h
    int 21h
    jc ErrorEscribirBytes
    cmp ax, cx
    jne ErrorEscribirBytes
    clc
    jmp FinEscribirBytes

ErrorEscribirBytes:
    stc

FinEscribirBytes:
    pop ax
    ret
EscribirBytes ENDP

EscribirNumeroArchivo PROC NEAR
    ; Entrada: AX=numero sin signo y BX=manejador abierto.
    ; NumeroATexto evita guardar la representacion binaria en el CSV.
    push ax
    push cx
    push dx
    call NumeroATexto
    call EscribirBytes
    pop dx
    pop cx
    pop ax
    ret
EscribirNumeroArchivo ENDP

AnexarAlumno PROC NEAR
    ; Anexa nombre, nota1, nota2 y nota3 a CALIF.TXT.
    ; Primero intenta abrir el archivo en lectura/escritura. Si no existe, lo
    ; crea; si existe, mueve el puntero al final antes de escribir el registro.
    push ax
    push bx
    push cx
    push dx

    lea dx, nombre_archivo_calif
    mov ax, 3D02h
    int 21h
    jnc ArchivoAnexoAbierto

    xor cx, cx
    lea dx, nombre_archivo_calif
    mov ah, 3Ch
    int 21h
    jnc ArchivoAnexoCreado
    jmp ErrorAbrirAnexo
ArchivoAnexoCreado:
    mov manejador_archivo, ax
    jmp ArchivoAnexoListo

ArchivoAnexoAbierto:
    mov manejador_archivo, ax
    mov bx, ax
    mov ax, 4202h
    xor cx, cx
    xor dx, dx
    int 21h
    jnc ArchivoAnexoListo
    jmp ErrorCerrarAnexo

ArchivoAnexoListo:
    mov bx, manejador_archivo
    xor cx, cx
    mov cl, byte ptr buffer_entrada[1]
    lea dx, buffer_entrada[2]
    call EscribirBytes
    jnc NombreAnexoEscrito
    jmp ErrorCerrarAnexo
NombreAnexoEscrito:

    mov cx, 1
    lea dx, coma
    call EscribirBytes
    jnc Coma1AnexoEscrita
    jmp ErrorCerrarAnexo
Coma1AnexoEscrita:
    mov ax, nota1
    call EscribirNumeroArchivo
    jnc Nota1AnexoEscrita
    jmp ErrorCerrarAnexo
Nota1AnexoEscrita:

    mov cx, 1
    lea dx, coma
    call EscribirBytes
    jnc Coma2AnexoEscrita
    jmp ErrorCerrarAnexo
Coma2AnexoEscrita:
    mov ax, nota2
    call EscribirNumeroArchivo
    jnc Nota2AnexoEscrita
    jmp ErrorCerrarAnexo
Nota2AnexoEscrita:

    mov cx, 1
    lea dx, coma
    call EscribirBytes
    jnc Coma3AnexoEscrita
    jmp ErrorCerrarAnexo
Coma3AnexoEscrita:
    mov ax, nota3
    call EscribirNumeroArchivo
    jnc Nota3AnexoEscrita
    jmp ErrorCerrarAnexo
Nota3AnexoEscrita:

    mov cx, 2
    lea dx, bytes_nueva_linea
    call EscribirBytes
    jnc LineaAnexoEscrita
    jmp ErrorCerrarAnexo
LineaAnexoEscrita:

    mov bx, manejador_archivo
    mov ah, 3Eh
    int 21h
    clc
    jmp FinAnexarAlumno

ErrorCerrarAnexo:
    mov bx, manejador_archivo
    mov ah, 3Eh
    int 21h

ErrorAbrirAnexo:
    stc

FinAnexarAlumno:
    pop dx
    pop cx
    pop bx
    pop ax
    ret
AnexarAlumno ENDP

LeerLineaArchivo PROC NEAR
    ; Lee una linea no vacia desde manejador_entrada sin cargar todo el archivo.
    ; Salida: AX=longitud, AX=0 al terminar el archivo y AX=FFFFh si la linea
    ; supera MAXIMO_LINEA. CF=1 indica un error real de entrada/salida.
    push bx
    push cx
    push dx
    push si
    push di

ReiniciarLecturaLinea:
    lea si, buffer_linea
    xor di, di
    mov linea_desbordada, 0

LeerCaracterLinea:
    mov bx, manejador_entrada
    mov ah, 3Fh
    mov cx, 1
    lea dx, caracter_archivo
    int 21h
    jnc CaracterLeido
    jmp ErrorLeerLinea
CaracterLeido:
    cmp ax, 0
    jne CaracterDisponible
    jmp FinArchivoEnLinea
CaracterDisponible:

    mov al, caracter_archivo
    cmp al, CR
    je LeerCaracterLinea
    cmp al, LF
    je LineaLeidaCompleta
    cmp di, MAXIMO_LINEA
    jae MarcarDesbordeLinea
    mov [si], al
    inc si
    inc di
    jmp LeerCaracterLinea

MarcarDesbordeLinea:
    ; Se consumen los caracteres restantes para que la siguiente llamada
    ; comience exactamente al inicio del proximo registro.
    mov linea_desbordada, 1
    jmp LeerCaracterLinea

LineaLeidaCompleta:
    cmp di, 0
    jne DevolverLinea
    cmp linea_desbordada, 0
    jne DevolverLineaLarga
    jmp ReiniciarLecturaLinea

FinArchivoEnLinea:
    cmp linea_desbordada, 0
    jne DevolverLineaLarga
    mov ax, di
    clc
    jmp FinLeerLinea

DevolverLinea:
    cmp linea_desbordada, 0
    jne DevolverLineaLarga
    mov ax, di
    clc
    jmp FinLeerLinea

DevolverLineaLarga:
    mov ax, 0FFFFh
    clc
    jmp FinLeerLinea

ErrorLeerLinea:
    stc

FinLeerLinea:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    ret
LeerLineaArchivo ENDP

VerReporteFinal PROC NEAR
    ; Lee FINAL.XLS por bloques y los copia a la salida estandar. El uso de un
    ; buffer fijo permite visualizar reportes mayores que la memoria reservada.
    call LimpiarPantalla
    IMPRIMIR encabezado_visualizacion

    lea dx, nombre_archivo_final
    mov ax, 3D00h
    int 21h
    jnc ArchivoVistaAbierto
    jmp FaltaArchivoVista
ArchivoVistaAbierto:
    mov manejador_entrada, ax

BucleVisualizacion:
    mov bx, manejador_entrada
    mov ah, 3Fh
    mov cx, TAMANO_BUFFER_VISTA
    lea dx, buffer_visualizacion
    int 21h
    jc ErrorLecturaVista
    cmp ax, 0
    je CerrarVista

    mov cx, ax
    mov bx, 1
    mov ah, 40h
    int 21h
    jc ErrorLecturaVista
    jmp BucleVisualizacion

ErrorLecturaVista:
    IMPRIMIR msg_error_reporte
    call SonidoError

CerrarVista:
    mov bx, manejador_entrada
    mov ah, 3Eh
    int 21h
    ret

FaltaArchivoVista:
    IMPRIMIR msg_falta_final
    call SonidoError
    ret
VerReporteFinal ENDP

; ===================== academico.inc ======================
; Registro de alumnos, analisis CSV, cifrado Cesar y generacion del reporte.

ValidarNombre PROC NEAR
    ; Rechaza nombres vacios, compuestos solo por espacios o con comas.
    ; Salida: CF=1 si es invalido; AL=1 distingue el caso de nombre vacio.
    push bx
    push cx
    push si

    xor cx, cx
    mov cl, byte ptr buffer_entrada[1]
    jcxz NombreValidadoVacio
    lea si, buffer_entrada[2]
    xor bl, bl

BucleValidarNombre:
    cmp byte ptr [si], ','
    je NombreValidadoConComa
    cmp byte ptr [si], ' '
    je SiguienteCaracterNombre
    mov bl, 1
SiguienteCaracterNombre:
    inc si
    loop BucleValidarNombre
    cmp bl, 0
    je NombreValidadoVacio
    clc
    jmp FinValidarNombre

NombreValidadoVacio:
    mov al, 1
    stc
    jmp FinValidarNombre

NombreValidadoConComa:
    xor al, al
    stc

FinValidarNombre:
    pop si
    pop cx
    pop bx
    ret
ValidarNombre ENDP

RegistrarAlumno PROC NEAR
    ; Conserva las notas validadas en variables globales antes de anexar una
    ; unica linea CSV. Asi nunca se guarda un registro con datos incompletos.
    call LimpiarPantalla
    IMPRIMIR encabezado_registro

LeerNombreAlumno:
    IMPRIMIR solicitud_nombre
    lea dx, buffer_entrada
    call LeerEntradaBuffer
    cmp byte ptr buffer_entrada[1], 0
    jne VerificarNombreAlumno
    IMPRIMIR msg_nombre_vacio
    call SonidoError
    jmp LeerNombreAlumno

VerificarNombreAlumno:
    call ValidarNombre
    jnc LeerNotasAlumno
    cmp al, 1
    je NombreAlumnoVacio
    IMPRIMIR msg_nombre_invalido
    call SonidoError
    jmp LeerNombreAlumno

NombreAlumnoVacio:
    IMPRIMIR msg_nombre_vacio
    call SonidoError
    jmp LeerNombreAlumno

LeerNotasAlumno:
    lea dx, solicitud_nota1
    call LeerNota
    mov nota1, ax
    lea dx, solicitud_nota2
    call LeerNota
    mov nota2, ax
    lea dx, solicitud_nota3
    call LeerNota
    mov nota3, ax

    call AnexarAlumno
    jc ErrorGuardarRegistro
    IMPRIMIR msg_guardado
    call SonidoExito
    ret

ErrorGuardarRegistro:
    IMPRIMIR msg_error_guardado
    call SonidoError
    ret
RegistrarAlumno ENDP

AnalizarNumeroCsv PROC NEAR
    ; Entrada: SI apunta al primer digito y fin_analisis al final de la linea.
    ; Salida: AX=valor, SI avanza al campo siguiente y DL indica el delimitador
    ; (1 para coma, 0 para fin de linea). CF=1 si el campo no es un 0..20.
    push bx
    push cx

    xor bx, bx
    xor cx, cx

AnalizarCaracterNumero:
    cmp si, fin_analisis
    jb CaracterNumeroDisponible
    jmp NumeroTerminaEnLinea
CaracterNumeroDisponible:
    mov al, [si]
    cmp al, ','
    jne CaracterNumeroNoEsComa
    jmp NumeroTerminaEnComa
CaracterNumeroNoEsComa:
    cmp al, '0'
    jae LimiteInferiorNumeroValido
    jmp NumeroCsvInvalido
LimiteInferiorNumeroValido:
    cmp al, '9'
    jbe CaracterNumeroEsDigito
    jmp NumeroCsvInvalido
CaracterNumeroEsDigito:
    sub al, '0'
    xor ah, ah
    push ax
    mov ax, bx
    mov dx, 10
    mul dx
    mov bx, ax
    pop ax
    add bx, ax
    cmp bx, 20
    jbe NumeroAnalizadoEnRango
    jmp NumeroCsvInvalido
NumeroAnalizadoEnRango:
    inc cx
    inc si
    jmp AnalizarCaracterNumero

NumeroTerminaEnComa:
    cmp cx, 0
    je NumeroCsvInvalido
    inc si
    mov ax, bx
    mov dl, 1
    clc
    jmp FinAnalizarNumero

NumeroTerminaEnLinea:
    cmp cx, 0
    je NumeroCsvInvalido
    mov ax, bx
    mov dl, 0
    clc
    jmp FinAnalizarNumero

NumeroCsvInvalido:
    stc

FinAnalizarNumero:
    pop cx
    pop bx
    ret
AnalizarNumeroCsv ENDP

AnalizarRegistro PROC NEAR
    ; Entrada: AX contiene la longitud de buffer_linea.
    ; Salida: nombre_cifrado, notas y promedio quedan preparados para escritura.
    ; CF=1 permite omitir lineas externas mal formadas sin detener el reporte.
    push bx
    push cx
    push dx
    push si
    push di
    push bp

    lea si, buffer_linea
    mov bp, si
    add bp, ax
    mov fin_analisis, bp
    lea di, nombre_cifrado
    xor bx, bx

AnalizarCaracterNombre:
    cmp si, bp
    jb CaracterNombreDisponible
    jmp RegistroAnalizadoInvalido
CaracterNombreDisponible:
    lodsb
    cmp al, ','
    jne NombreNoTerminado
    jmp FinAnalizarNombre
NombreNoTerminado:
    cmp bx, MAXIMO_NOMBRE
    jb HayEspacioParaNombre
    jmp RegistroAnalizadoInvalido
HayEspacioParaNombre:

    cmp al, 'a'
    jb IntentarMayuscula
    cmp al, 'z'
    ja IntentarMayuscula
    add al, 3
    cmp al, 'z'
    jbe GuardarCaracterCifrado
    ; Al superar 'z' se vuelve al inicio del alfabeto: x->a, y->b, z->c.
    sub al, 26
    jmp GuardarCaracterCifrado

IntentarMayuscula:
    cmp al, 'A'
    jb GuardarCaracterCifrado
    cmp al, 'Z'
    ja GuardarCaracterCifrado
    add al, 3
    cmp al, 'Z'
    jbe GuardarCaracterCifrado
    ; Se aplica la misma rotacion a las letras mayusculas.
    sub al, 26

GuardarCaracterCifrado:
    stosb
    inc bx
    jmp AnalizarCaracterNombre

FinAnalizarNombre:
    cmp bx, 0
    jne NombreAnalizadoNoVacio
    jmp RegistroAnalizadoInvalido
NombreAnalizadoNoVacio:
    mov longitud_cifrado, bx

    call AnalizarNumeroCsv
    jnc PrimeraNotaAnalizada
    jmp RegistroAnalizadoInvalido
PrimeraNotaAnalizada:
    cmp dl, 1
    je PrimeraNotaDelimitada
    jmp RegistroAnalizadoInvalido
PrimeraNotaDelimitada:
    mov nota1, ax

    call AnalizarNumeroCsv
    jnc SegundaNotaAnalizada
    jmp RegistroAnalizadoInvalido
SegundaNotaAnalizada:
    cmp dl, 1
    je SegundaNotaDelimitada
    jmp RegistroAnalizadoInvalido
SegundaNotaDelimitada:
    mov nota2, ax

    call AnalizarNumeroCsv
    jnc TerceraNotaAnalizada
    jmp RegistroAnalizadoInvalido
TerceraNotaAnalizada:
    cmp dl, 0
    je TerceraNotaDelimitada
    jmp RegistroAnalizadoInvalido
TerceraNotaDelimitada:
    mov nota3, ax

    mov ax, nota1
    add ax, nota2
    add ax, nota3
    xor dx, dx
    mov bx, 3
    ; DIV entera descarta la fraccion, segun el requisito del proyecto.
    div bx
    mov promedio, ax
    clc
    jmp FinAnalizarRegistro

RegistroAnalizadoInvalido:
    stc

FinAnalizarRegistro:
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    ret
AnalizarRegistro ENDP

EscribirRegistroReporte PROC NEAR
    ; Escribe un registro procesado campo por campo. Todas las salidas pasan por
    ; EscribirBytes para detectar errores DOS y escrituras incompletas.
    push ax
    push bx
    push cx
    push dx

    mov bx, manejador_salida
    mov cx, longitud_cifrado
    lea dx, nombre_cifrado
    call EscribirBytes
    jnc NombreReporteEscrito
    jmp ErrorEscribirReporte
NombreReporteEscrito:

    mov cx, 1
    lea dx, coma
    call EscribirBytes
    jnc Coma1ReporteEscrita
    jmp ErrorEscribirReporte
Coma1ReporteEscrita:
    mov ax, nota1
    call EscribirNumeroArchivo
    jnc Nota1ReporteEscrita
    jmp ErrorEscribirReporte
Nota1ReporteEscrita:

    mov cx, 1
    lea dx, coma
    call EscribirBytes
    jnc Coma2ReporteEscrita
    jmp ErrorEscribirReporte
Coma2ReporteEscrita:
    mov ax, nota2
    call EscribirNumeroArchivo
    jnc Nota2ReporteEscrita
    jmp ErrorEscribirReporte
Nota2ReporteEscrita:

    mov cx, 1
    lea dx, coma
    call EscribirBytes
    jnc Coma3ReporteEscrita
    jmp ErrorEscribirReporte
Coma3ReporteEscrita:
    mov ax, nota3
    call EscribirNumeroArchivo
    jnc Nota3ReporteEscrita
    jmp ErrorEscribirReporte
Nota3ReporteEscrita:

    mov cx, 1
    lea dx, coma
    call EscribirBytes
    jnc Coma4ReporteEscrita
    jmp ErrorEscribirReporte
Coma4ReporteEscrita:
    mov ax, promedio
    call EscribirNumeroArchivo
    jnc PromedioReporteEscrito
    jmp ErrorEscribirReporte
PromedioReporteEscrito:

    mov cx, 1
    lea dx, coma
    call EscribirBytes
    jnc Coma5ReporteEscrita
    jmp ErrorEscribirReporte
Coma5ReporteEscrita:

    cmp promedio, 10
    jb EscribirEstadoReprobado
    mov cx, LONGITUD_APROBADO
    lea dx, texto_aprobado
    call EscribirBytes
    jnc FinEscribirEstado
    jmp ErrorEscribirReporte

EscribirEstadoReprobado:
    mov cx, LONGITUD_REPROBADO
    lea dx, texto_reprobado
    call EscribirBytes
    jnc FinEscribirEstado
    jmp ErrorEscribirReporte

FinEscribirEstado:
    mov cx, 2
    lea dx, bytes_nueva_linea
    call EscribirBytes
    jnc LineaReporteEscrita
    jmp ErrorEscribirReporte
LineaReporteEscrita:
    clc
    jmp FinEscribirReporte

ErrorEscribirReporte:
    stc

FinEscribirReporte:
    pop dx
    pop cx
    pop bx
    pop ax
    ret
EscribirRegistroReporte ENDP

GenerarReporte PROC NEAR
    ; FINAL.XLS se recrea para que represente exactamente el contenido actual
    ; de CALIF.TXT y no acumule resultados de ejecuciones anteriores.
    call LimpiarPantalla
    IMPRIMIR encabezado_reporte

    lea dx, nombre_archivo_calif
    mov ax, 3D00h
    int 21h
    jnc EntradaReporteAbierta
    jmp FaltaEntradaReporte
EntradaReporteAbierta:
    mov manejador_entrada, ax

    lea dx, nombre_archivo_final
    xor cx, cx
    mov ah, 3Ch
    int 21h
    jnc SalidaReporteCreada
    jmp ErrorCrearReporte
SalidaReporteCreada:
    mov manejador_salida, ax

    mov contador_total, 0
    mov contador_aprobados, 0
    mov contador_reprobados, 0
    mov contador_invalidos, 0
    IMPRIMIR msg_procesando

BucleGenerarReporte:
    call LeerLineaArchivo
    jnc LineaReporteLeida
    jmp ErrorEntradaSalidaReporte
LineaReporteLeida:
    cmp ax, 0
    jne ReporteTieneLinea
    jmp ReporteGenerado
ReporteTieneLinea:
    cmp ax, 0FFFFh
    je ContarRegistroInvalido
    call AnalizarRegistro
    jnc RegistroReporteAnalizado
    jmp ContarRegistroInvalido
RegistroReporteAnalizado:
    call EscribirRegistroReporte
    jnc RegistroReporteEscrito
    jmp ErrorEntradaSalidaReporte
RegistroReporteEscrito:

    inc contador_total
    cmp promedio, 10
    jb ContarAlumnoReprobado
    inc contador_aprobados
    jmp BucleGenerarReporte

ContarAlumnoReprobado:
    inc contador_reprobados
    jmp BucleGenerarReporte

ContarRegistroInvalido:
    inc contador_invalidos
    jmp BucleGenerarReporte

ReporteGenerado:
    mov bx, manejador_entrada
    mov ah, 3Eh
    int 21h
    mov bx, manejador_salida
    mov ah, 3Eh
    int 21h

    IMPRIMIR msg_reporte_correcto
    call SonidoExito
    IMPRIMIR titulo_estadisticas
    IMPRIMIR msg_total
    mov ax, contador_total
    call ImprimirSinSigno
    NUEVA_LINEA
    IMPRIMIR msg_aprobados
    mov ax, contador_aprobados
    call ImprimirSinSigno
    NUEVA_LINEA
    IMPRIMIR msg_reprobados
    mov ax, contador_reprobados
    call ImprimirSinSigno
    NUEVA_LINEA
    cmp contador_invalidos, 0
    je FinGenerarReporte
    IMPRIMIR msg_registros_invalidos
    mov ax, contador_invalidos
    call ImprimirSinSigno
    NUEVA_LINEA

FinGenerarReporte:
    ret

ErrorEntradaSalidaReporte:
    mov bx, manejador_salida
    mov ah, 3Eh
    int 21h

ErrorCrearReporte:
    mov bx, manejador_entrada
    mov ah, 3Eh
    int 21h
    IMPRIMIR msg_error_reporte
    call SonidoError
    ret

FaltaEntradaReporte:
    IMPRIMIR msg_falta_calif
    call SonidoError
    ret
GenerarReporte ENDP

; ===================== programa principal =================
Inicio:
    ; En un programa COM, codigo y datos comparten segmento. Inicializar DS y
    ; ES con CS permite acceder correctamente a variables mediante sus offsets.
    push cs
    pop ds
    push cs
    pop es

MenuPrincipal:
    call LimpiarPantalla
    IMPRIMIR texto_menu
    call LeerOpcionMenu

    ; AL contiene un unico caracter validado por LeerOpcionMenu.
    cmp al, '1'
    je OpcionRegistrar
    cmp al, '2'
    je OpcionReporte
    cmp al, '3'
    jne VerificarOpcionSalir
    jmp OpcionVerReporte
VerificarOpcionSalir:
    cmp al, '4'
    jne OpcionPrincipalInvalida
    jmp SalirPrograma

OpcionPrincipalInvalida:
    IMPRIMIR msg_opcion_invalida
    call SonidoError
    call PausarPantalla
    jmp MenuPrincipal

OpcionRegistrar:
    call RegistrarAlumno
    call PausarPantalla
    jmp MenuPrincipal

OpcionReporte:
    call GenerarReporte
    call PausarPantalla
    jmp MenuPrincipal

OpcionVerReporte:
    call VerReporteFinal
    call PausarPantalla
    jmp MenuPrincipal

SalirPrograma:
    call LimpiarPantalla
    IMPRIMIR encabezado_salida
    IMPRIMIR msg_salida
    mov ax, 4C00h
    int 21h
