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
