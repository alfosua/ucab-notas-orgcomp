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
