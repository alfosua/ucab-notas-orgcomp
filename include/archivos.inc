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
