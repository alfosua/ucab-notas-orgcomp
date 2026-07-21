; Sistema de Gestion Academica para EMU8086.
; Se compila como programa COM y debe ejecutarse en un directorio donde DOS
; pueda crear y modificar CALIF.TXT y FINAL.XLS.
;
; IMPORTANTE (EMU8086): todos los archivos .inc deben estar en la MISMA carpeta
; que este main.asm. Los include usan solo el nombre del archivo, sin subcarpeta,
; porque EMU8086 no resuelve de forma fiable rutas con subdirectorio.

org 100h
jmp Inicio

include 'constantes.inc'
include 'macros.inc'
include 'datos.inc'
include 'entrada_salida.inc'
include 'archivos.inc'
include 'academico.inc'

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
