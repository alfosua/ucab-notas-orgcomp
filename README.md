# Proyecto de Organización del Computador

## Sistema de Gestión Académica Seguro

### Primer avance

**Plataforma:** EMU8086  
**Lenguaje objetivo:** Ensamblador 8086  
**Archivos del sistema:** `CALIF.TXT` y `FINAL.XLS`

---

## 1. Informe del Proyecto

### Introducción

La gestión de calificaciones es una actividad fundamental dentro de cualquier proceso académico, ya que permite registrar el desempeño de los estudiantes, organizar la información obtenida durante una evaluación y generar reportes que faciliten el análisis administrativo. En este proyecto se propone el desarrollo de un Sistema de Gestión Académica Seguro, orientado al registro, procesamiento y consulta de notas mediante un programa autónomo elaborado en lenguaje ensamblador para la plataforma EMU8086.

El sistema permitirá ingresar por teclado el nombre de cada estudiante y tres calificaciones, validar que los valores estén dentro del rango permitido y guardar la información en un archivo de texto llamado `CALIF.TXT`. Posteriormente, el programa podrá procesar los registros almacenados, aplicar un Cifrado César con desplazamiento de tres posiciones al nombre del alumno, calcular el promedio entero de las notas y determinar si el estudiante se encuentra aprobado o reprobado. El resultado será exportado al archivo `FINAL.XLS`, usando un formato delimitado por comas compatible con Excel.

Este proyecto integra varios contenidos de la asignatura Organización del Computador, entre ellos el uso de registros, manejo de memoria, instrucciones aritméticas, saltos condicionales, procedimientos, macros, interrupciones del sistema, validación de entrada, manejo de archivos y salida por pantalla. Además, incorpora una noción básica de seguridad mediante el cifrado del nombre del estudiante, lo que permite relacionar el procesamiento académico con la protección elemental de datos.

### Objetivo General

Desarrollar un sistema en lenguaje ensamblador 8086 que permita registrar, almacenar, cifrar, procesar y reportar calificaciones académicas de estudiantes, utilizando archivos persistentes y una interfaz de menú ejecutada en la consola de EMU8086.

### Objetivos Específicos

El sistema busca registrar nombres de estudiantes junto con tres calificaciones, validar que cada nota ingresada se encuentre entre 0 y 20 puntos, almacenar los datos originales en `CALIF.TXT` y generar un reporte procesado en `FINAL.XLS`. También se plantea aplicar Cifrado César con desplazamiento `n + 3` sobre el nombre del estudiante, calcular el promedio entero de las tres notas, determinar el estado académico como `APROBADO` o `REPROBADO`, mostrar estadísticas generales del procesamiento e incorporar macros, procedimientos, validaciones y sonidos de sistema.

### Descripción General del Sistema

Al ejecutar el programa, se mostrará un menú principal con cuatro opciones: registrar alumnos y notas, generar reporte y estadísticas, ver el reporte final `.XLS` y salir del sistema. Esta estructura permitirá que el usuario navegue por las funciones principales de forma directa desde la consola del emulador.

En la opción de registro, el usuario ingresará el nombre del estudiante y sus tres calificaciones. Antes de guardar la información, el programa verificará que cada nota esté dentro del rango válido de 0 a 20. Si los datos son correctos, se almacenarán en el archivo `CALIF.TXT` bajo el siguiente formato:

```text
Nombre,Nota1,Nota2,Nota3
```

En la opción de generación de reporte, el programa leerá el archivo `CALIF.TXT`, separará cada registro en sus campos correspondientes, cifrará el nombre del estudiante, calculará el promedio y determinará el estado académico. Luego escribirá los resultados en `FINAL.XLS` con el siguiente formato:

```text
NombreCifrado,Nota1,Nota2,Nota3,Promedio,Estado
```

Un ejemplo de línea generada sería:

```text
Mxdq,15,18,16,16,APROBADO
```

La opción de visualización permitirá mostrar en pantalla el contenido actual de `FINAL.XLS`, mientras que la opción de salida finalizará la ejecución del sistema. Durante el proceso también se contemplan mensajes de error cuando una opción sea inválida, una nota esté fuera del rango permitido o un archivo requerido no exista.

### Plataforma Tecnológica

El proyecto será desarrollado en EMU8086, un emulador del microprocesador 8086 que permite escribir, ejecutar y depurar programas en lenguaje ensamblador. Esta plataforma resulta adecuada para el proyecto porque permite trabajar directamente con registros, memoria, interrupciones y operaciones de bajo nivel, elementos esenciales para comprender el funcionamiento interno de un computador.

Para la entrada y salida de datos se utilizará principalmente la interrupción `21h` de DOS, junto con funciones para lectura por teclado, escritura en pantalla, creación de archivos, apertura de archivos, escritura, lectura y cierre. Los archivos se manejarán como texto plano: `CALIF.TXT` funcionará como archivo de entrada generado por el propio programa y `FINAL.XLS` funcionará como archivo de salida delimitado por comas, compatible con Excel aunque no sea un archivo binario nativo de dicha aplicación.

### Limitaciones Encontradas

El desarrollo en EMU8086 presenta restricciones propias del entorno 8086, especialmente en el manejo de memoria, cadenas y archivos. A diferencia de los lenguajes de alto nivel, el ensamblador no ofrece estructuras automáticas para manipular textos, separar campos o convertir datos numéricos, por lo que será necesario diseñar procedimientos específicos para cada tarea.

Otra limitación importante es que el archivo `FINAL.XLS` no será un documento Excel nativo, sino un archivo de texto con extensión `.XLS` y campos delimitados por comas. Esta decisión cumple con el requerimiento de compatibilidad básica, pero no permite utilizar características internas de Excel como fórmulas, hojas múltiples o formato visual avanzado. Asimismo, el Cifrado César propuesto es un mecanismo de seguridad elemental, útil para fines académicos, pero insuficiente para proteger información sensible en un sistema real.

También debe considerarse que el promedio se calculará como un valor entero, por lo que cualquier parte decimal será descartada. Esta simplificación facilita la implementación en ensamblador y mantiene el proceso dentro del alcance técnico del proyecto.

---

## 2. Objetivos de Desarrollo Sostenible

### ODS 4: Educación de Calidad

El ODS 4 tiene como propósito garantizar una educación inclusiva, equitativa y de calidad, promoviendo oportunidades de aprendizaje para todos. Este proyecto contribuye a dicho objetivo porque permite organizar información académica, facilitar el seguimiento del rendimiento estudiantil y apoyar la toma de decisiones a partir de reportes claros y estructurados.

### ODS 9: Industria, Innovación e Infraestructura

El ODS 9 busca promover la innovación, el desarrollo tecnológico y la construcción de infraestructuras sostenibles. El proyecto se relaciona con este objetivo porque impulsa el desarrollo de una solución tecnológica desde bajo nivel, fortaleciendo competencias en programación, automatización, procesamiento de datos y diseño de sistemas informáticos.

### ODS 16: Paz, Justicia e Instituciones Sólidas

El ODS 16 promueve instituciones eficaces, responsables y transparentes. El sistema aporta a este objetivo al utilizar archivos persistentes, reportes verificables y un procesamiento organizado de las calificaciones, lo cual favorece una gestión académica más ordenada, trazable y transparente.

---

## 3. Algoritmos de los Procesos

### Algoritmo 1: Menú Principal

```text
Cabecera: Menú Principal del Sistema
Variables:
opción : Entero

Cuerpo:
Inicio
    opción = 0

    Mientras opción <> 4:
        Escribir("====================================")
        Escribir(" SISTEMA DE GESTIÓN ACADÉMICA")
        Escribir("====================================")
        Escribir("1. Registrar Alumnos y Notas")
        Escribir("2. Generar Reporte y Estadísticas")
        Escribir("3. Ver Reporte Final (.XLS)")
        Escribir("4. Salir")
        Escribir("Seleccione una opción:")
        Leer(opción)

        Si opción = 1:
            RegistrarAlumno()
        Sino, si opción = 2:
            GenerarReporte()
        Sino, si opción = 3:
            VerReporteFinal()
        Sino, si opción = 4:
            Escribir("Saliendo del sistema...")
        Sino:
            Escribir("Opción inválida.")
            SonidoError()
        Fin-Si
    Fin-Mientras
Fin
```

### Algoritmo 2: Registrar Alumnos y Notas

```text
Cabecera: Registrar Alumnos y Notas
Variables:
nombre : Cadena
nota1, nota2, nota3 : Entero
archivo : Archivo

Cuerpo:
Inicio
    Escribir("Ingrese el nombre del alumno:")
    Leer(nombre)

    Escribir("Ingrese la nota 1:")
    Leer(nota1)
    Mientras nota1 < 0 O nota1 > 20:
        Escribir("Error. La nota debe estar entre 0 y 20.")
        SonidoError()
        Escribir("Ingrese la nota 1 nuevamente:")
        Leer(nota1)
    Fin-Mientras

    Escribir("Ingrese la nota 2:")
    Leer(nota2)
    Mientras nota2 < 0 O nota2 > 20:
        Escribir("Error. La nota debe estar entre 0 y 20.")
        SonidoError()
        Escribir("Ingrese la nota 2 nuevamente:")
        Leer(nota2)
    Fin-Mientras

    Escribir("Ingrese la nota 3:")
    Leer(nota3)
    Mientras nota3 < 0 O nota3 > 20:
        Escribir("Error. La nota debe estar entre 0 y 20.")
        SonidoError()
        Escribir("Ingrese la nota 3 nuevamente:")
        Leer(nota3)
    Fin-Mientras

    Abrir archivo CALIF.TXT en modo agregar
    Si archivo no existe:
        Crear archivo CALIF.TXT
    Fin-Si

    Escribir en archivo nombre
    Escribir en archivo ","
    Escribir en archivo nota1
    Escribir en archivo ","
    Escribir en archivo nota2
    Escribir en archivo ","
    Escribir en archivo nota3
    Escribir en archivo salto de línea

    Cerrar archivo
    Escribir("Datos guardados correctamente.")
    SonidoÉxito()
Fin
```

### Algoritmo 3: Cifrado César del Nombre

```text
Cabecera: Cifrar Nombre con César n + 3
Variables:
nombre : Cadena
nombreCifrado : Cadena
i : Entero
carácter : Carácter

Cuerpo:
Inicio
    nombreCifrado = ""

    Para i = 1, Longitud(nombre), +1:
        carácter = nombre[i]

        Si carácter <> " ":
            carácter = carácter + 3
        Fin-Si

        nombreCifrado = nombreCifrado + carácter
    Fin-Para

    Retornar nombreCifrado
Fin
```

### Algoritmo 4: Generar Reporte y Estadísticas

```text
Cabecera: Generar Reporte y Estadísticas
Variables:
nombre, nombreCifrado, estado : Cadena
nota1, nota2, nota3, promedio : Entero
total, aprobados, reprobados : Entero
archivoEntrada, archivoSalida : Archivo

Cuerpo:
Inicio
    total = 0
    aprobados = 0
    reprobados = 0

    Abrir archivo CALIF.TXT en modo lectura

    Si archivoEntrada no existe:
        Escribir("Error. No existe el archivo CALIF.TXT.")
        SonidoError()
        Retornar
    Fin-Si

    Crear archivo FINAL.XLS en modo escritura

    Mientras no sea fin de archivoEntrada:
        Leer nombre, nota1, nota2, nota3 desde archivoEntrada

        nombreCifrado = CifrarNombre(nombre)
        promedio = (nota1 + nota2 + nota3) // 3

        Si promedio >= 10:
            estado = "APROBADO"
            aprobados = aprobados + 1
        Sino:
            estado = "REPROBADO"
            reprobados = reprobados + 1
        Fin-Si

        Escribir en FINAL.XLS nombreCifrado
        Escribir en FINAL.XLS ","
        Escribir en FINAL.XLS nota1
        Escribir en FINAL.XLS ","
        Escribir en FINAL.XLS nota2
        Escribir en FINAL.XLS ","
        Escribir en FINAL.XLS nota3
        Escribir en FINAL.XLS ","
        Escribir en FINAL.XLS promedio
        Escribir en FINAL.XLS ","
        Escribir en FINAL.XLS estado
        Escribir en FINAL.XLS salto de línea

        total = total + 1
    Fin-Mientras

    Cerrar archivoEntrada
    Cerrar archivoSalida

    Escribir("Reporte generado correctamente.")
    SonidoÉxito()

    Escribir("===== ESTADÍSTICAS =====")
    Escribir("Total de alumnos procesados: ", total)
    Escribir("Cantidad de aprobados: ", aprobados)
    Escribir("Cantidad de reprobados: ", reprobados)
Fin
```

### Algoritmo 5: Ver Reporte Final

```text
Cabecera: Ver Reporte Final XLS
Variables:
línea : Cadena
archivo : Archivo

Cuerpo:
Inicio
    Abrir archivo FINAL.XLS en modo lectura

    Si archivo no existe:
        Escribir("Error. No existe el archivo FINAL.XLS.")
        SonidoError()
        Retornar
    Fin-Si

    Escribir("===== CONTENIDO DE FINAL.XLS =====")

    Mientras no sea fin de archivo:
        Leer línea desde archivo
        Escribir(línea)
    Fin-Mientras

    Cerrar archivo
Fin
```

### Algoritmo 6: Sonidos de Sistema

```text
Cabecera: Sonidos de Error y Éxito
Variables:
tipo : Cadena

Cuerpo:
Inicio
    Si tipo = "ERROR":
        Emitir sonido corto de advertencia
    Sino, si tipo = "ÉXITO":
        Emitir sonido corto de confirmación
    Fin-Si
Fin
```

---

## 4. Modelo de Pantallas de la Herramienta

Las capturas tipo terminal se encuentran en la carpeta `capturas/`:

- `capturas/01_menu_principal.png`
- `capturas/02_registro_alumno.png`
- `capturas/03_error_nota.png`
- `capturas/04_reporte_estadisticas.png`
- `capturas/05_error_archivo.png`
- `capturas/06_ver_reporte_final.png`
- `capturas/07_salida_sistema.png`

### Pantalla 1: Menu Principal

```text
====================================
 SISTEMA DE GESTION ACADEMICA
====================================
1. Registrar Alumnos y Notas
2. Generar Reporte y Estadisticas
3. Ver Reporte Final (.XLS)
4. Salir
------------------------------------
Seleccione una opcion: _
```

### Pantalla 2: Registro de Alumno

```text
====================================
 REGISTRO DE ALUMNOS Y NOTAS
====================================
Ingrese el nombre del alumno: Juan
Ingrese la nota 1: 15
Ingrese la nota 2: 18
Ingrese la nota 3: 16

Datos guardados correctamente.
Presione una tecla para continuar...
```

### Pantalla 3: Error de Nota

```text
====================================
 REGISTRO DE ALUMNOS Y NOTAS
====================================
Ingrese el nombre del alumno: Ana
Ingrese la nota 1: 25

Error. La nota debe estar entre 0 y 20.
Ingrese la nota 1 nuevamente: _
```

### Pantalla 4: Generar Reporte y Estadisticas

```text
====================================
 GENERAR REPORTE Y ESTADISTICAS
====================================
Procesando archivo CALIF.TXT...
Generando archivo FINAL.XLS...

Reporte generado correctamente.

===== ESTADISTICAS =====
Total de alumnos procesados: 3
Cantidad de aprobados: 2
Cantidad de reprobados: 1

Presione una tecla para continuar...
```

### Pantalla 5: Error de Archivo No Encontrado

```text
====================================
 GENERAR REPORTE Y ESTADISTICAS
====================================
Error. No existe el archivo CALIF.TXT.

Presione una tecla para continuar...
```

### Pantalla 6: Ver Reporte Final

```text
====================================
 CONTENIDO DE FINAL.XLS
====================================
Mxdq,15,18,16,16,APROBADO
Dqd,08,09,10,09,REPROBADO
Shgur,12,14,13,13,APROBADO

Presione una tecla para continuar...
```

### Pantalla 7: Salida del Sistema

```text
====================================
 SISTEMA DE GESTION ACADEMICA
====================================
Saliendo del sistema...
```

---

## 6. Conclusión

El Sistema de Gestión Académica Seguro propuesto representa una aplicación práctica de los conceptos estudiados en Organización del Computador, ya que exige trabajar con instrucciones de bajo nivel para resolver un problema concreto: registrar, procesar y reportar calificaciones académicas. A través del diseño del sistema se evidencia la importancia de planificar correctamente la entrada de datos, la validación de valores, el almacenamiento persistente y la generación de salidas comprensibles para el usuario.

El proyecto también permite comprender las diferencias entre desarrollar una solución en un lenguaje de alto nivel y hacerlo en ensamblador. Operaciones que normalmente serían simples, como leer una cadena, separar campos, convertir notas o escribir un archivo, requieren en EMU8086 una organización detallada de registros, memoria, interrupciones y procedimientos. Por esta razón, la modularidad mediante macros y subrutinas será un aspecto clave para lograr una herramienta ordenada, defendible y fácil de depurar.

Aunque el cifrado César utilizado no constituye una técnica de seguridad avanzada, su incorporación aporta valor académico porque introduce la idea de transformar información antes de publicarla en un reporte. De igual manera, el cálculo del promedio, la clasificación entre aprobado y reprobado, y el conteo estadístico de resultados permiten que el programa no solo almacene datos, sino que también los convierta en información útil para el análisis administrativo.

En conclusión, este avance establece la base documental, lógica y visual del sistema que será implementado en la entrega final. La propuesta cumple con los requerimientos iniciales del proyecto, define con claridad los procesos principales y anticipa las limitaciones técnicas propias de EMU8086. A partir de esta estructura, la siguiente fase deberá enfocarse en traducir los algoritmos planteados a lenguaje ensamblador, probar el manejo de archivos y verificar que cada opción del menú funcione correctamente dentro del emulador.
