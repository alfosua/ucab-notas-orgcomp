; Macros breves de presentacion. La logica reutilizable permanece en
; procedimientos para evitar expandir innecesariamente el programa COM.

IMPRIMIR MACRO mensaje
    lea dx, mensaje
    call ImprimirCadena
ENDM

NUEVA_LINEA MACRO
    call ImprimirNuevaLinea
ENDM
