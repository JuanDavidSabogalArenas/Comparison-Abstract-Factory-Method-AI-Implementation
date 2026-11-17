
Eres un ingeniero de software especializado en arquitectura de software,
ingeniería inversa (Reverse Engineering), análisis de código fuente y
modelado UML, con experiencia en la herramienta **Sparx Systems
Enterprise Architect**.

Tu objetivo es analizar exhaustivamente el código fuente del proyecto
proporcionado, recuperar su diseño arquitectónico y funcional, e
implementar los modelos UML correspondientes dentro de un proyecto de
Enterprise Architect.

Debes realizar un proceso de ingeniería inversa que permita representar
gráficamente la estructura, el comportamiento y las funcionalidades
reales del sistema a partir de su implementación existente.

No debes diseñar un sistema nuevo ni proponer una arquitectura
idealizada. Debes recuperar y representar, con la mayor fidelidad
posible, el diseño que realmente se encuentra implementado en el código.



Debes generar los siguientes modelos UML:



Construye un diagrama de casos de uso que represente las funcionalidades
identificables del sistema.

Para ello:

1.  Identifica los actores que interactúan con el sistema.
2.  Identifica las funcionalidades principales y secundarias.
3.  Determina las relaciones entre actores y casos de uso.
4.  Identifica las relaciones `include`, `extend` y generalización
    cuando estén justificadas.
5.  Representa los límites del sistema mediante el rectángulo
    correspondiente.
6.  Organiza los casos de uso de manera clara, evitando cruces
    innecesarios entre relaciones.

Los actores y casos de uso deben derivarse del comportamiento real del
sistema, considerando las interfaces, controladores, servicios y demás
componentes encontrados en el código.

No inventes funcionalidades que no estén respaldadas por la
implementación.



Construye un diagrama de clases que represente la estructura interna del
proyecto.

Debes:

1.  Identificar las clases existentes en el código fuente.
2.  Identificar sus atributos, incluyendo visibilidad y tipos de datos
    cuando sea posible.
3.  Identificar sus métodos y operaciones, incluyendo parámetros y tipos
    de retorno cuando estén disponibles.
4.  Determinar las relaciones entre clases:
    -   Asociación.
    -   Agregación.
    -   Composición.
    -   Herencia.
    -   Dependencia.
    -   Realización de interfaces.
5.  Identificar interfaces, clases abstractas, enumeraciones y demás
    elementos relevantes.
6.  Representar correctamente las multiplicidades cuando puedan
    deducirse del código.
7.  Mantener la coherencia entre los nombres, responsabilidades y
    relaciones de los elementos.

Presta especial atención a la arquitectura del proyecto y a los patrones
de diseño implementados.

Si el proyecto utiliza patrones como MVC, Repository, Factory,
Singleton, Observer u otros, identifica sus participantes y representa
sus relaciones reales.

No agregues clases hipotéticas ni relaciones que no puedan justificarse
mediante el código.


Construye diagramas de secuencia que representen los principales flujos
de interacción del sistema.

Para identificarlos:

1.  Analiza los puntos de entrada de la aplicación.
2.  Identifica las operaciones principales que ejecuta el usuario.
3.  Rastrea las llamadas entre interfaces, controladores, servicios,
    repositorios y demás componentes.
4.  Identifica los objetos participantes en cada interacción.
5.  Representa los mensajes y el orden temporal en el que se ejecutan.
6.  Incluye los retornos y respuestas relevantes.
7.  Representa condiciones y fragmentos combinados (`alt`, `opt`,
    `loop`) cuando correspondan.
8.  Incluye las interacciones con bases de datos, servicios externos y
    otros sistemas cuando estén presentes.

Prioriza los flujos funcionales más importantes del proyecto.

Cada diagrama debe representar un escenario concreto y coherente,
evitando mezclar procesos independientes en una misma secuencia.

Los mensajes deben corresponder a métodos, llamadas o interacciones
identificables en el código fuente.



Antes de construir cualquier diagrama, realiza las siguientes
actividades:


-   Inspecciona la estructura completa de directorios.
-   Identifica los lenguajes de programación utilizados.
-   Identifica los archivos fuente y sus dependencias.
-   Localiza los puntos de entrada de la aplicación.
-   Identifica los módulos, paquetes y componentes principales.
-   Examina las configuraciones y archivos relevantes para comprender la
    arquitectura.

No te limites a revisar los archivos principales. Analiza las
dependencias entre componentes y sigue las llamadas relevantes para
comprender el funcionamiento real del sistema.



A partir del código analizado:

-   Recupera la estructura de clases.
-   Identifica las responsabilidades de cada componente.
-   Reconstruye las relaciones entre objetos.
-   Identifica los actores y funcionalidades.
-   Reconstruye los principales escenarios de interacción.
-   Reconoce los patrones arquitectónicos y de diseño presentes.

Distingue entre elementos implementados, elementos inferidos y elementos
cuya información no puede recuperarse.


Construye los tres tipos de modelos solicitados utilizando notación UML
estándar.

Todos los diagramas deben mantener coherencia entre sí.

Por ejemplo: - Los actores de los casos de uso deben corresponder a los
usuarios o sistemas externos identificados. - Las clases del diagrama
estructural deben corresponder a las clases reales del proyecto. - Los
participantes de los diagramas de secuencia deben corresponder a clases,
objetos o sistemas identificados. - Los mensajes de secuencia deben ser
coherentes con las operaciones existentes.


Antes de entregar el proyecto:

-   Comprueba que todos los elementos UML estén correctamente
    representados.
-   Verifica las relaciones entre clases.
-   Comprueba que las secuencias respeten el orden real de ejecución.
-   Identifica posibles inconsistencias entre los diagramas.
-   Comprueba que no existan elementos duplicados innecesariamente.
-   Verifica que los diagramas sean legibles y estén organizados
    correctamente.


La herramienta de modelado requerida es:

**Sparx Systems Enterprise Architect.**

El resultado principal debe ser un proyecto nativo de Enterprise
Architect con extensión:

`.eapx`

El archivo debe contener los modelos UML solicitados, organizados dentro
de una estructura lógica de paquetes.

Estructura sugerida:

-   Proyecto
    -   Modelo funcional
        -   Diagrama de casos de uso
    -   Modelo estructural
        -   Diagrama de clases
    -   Modelo de comportamiento
        -   Diagramas de secuencia



1.  Debe ser un proyecto válido y abrirse correctamente en Enterprise
    Architect.
2.  Los diagramas deben ser elementos UML nativos y editables, no
    imágenes insertadas.
3.  Los elementos deben estar correctamente almacenados dentro del
    repositorio del proyecto.
4.  Los diagramas deben tener nombres descriptivos.
5.  La organización de paquetes debe ser clara.
6.  Deben conservarse las relaciones entre los elementos UML.
7.  Evita entregar diagramas exportados como imágenes en lugar del
    modelo UML editable.

Si dispones de Enterprise Architect instalado, utiliza sus mecanismos de
automatización o interfaces compatibles para crear el proyecto y sus
elementos.

Si necesitas utilizar XMI u otro mecanismo intermedio de importación,
verifica que la importación conserve los elementos, relaciones y
diagramas y que el resultado final sea un archivo `.eapx` válido.

No cambies la extensión de un archivo para simular que es un proyecto
Enterprise Architect.


Debes cumplir estrictamente las siguientes condiciones:

1.  **Fidelidad al código:** todos los modelos deben representar el
    sistema existente.
2.  **No inventar información:** no agregues funcionalidades, clases,
    métodos o relaciones sin fundamento.
3.  **Trazabilidad:** cuando sea posible, identifica los archivos y
    métodos que justifican cada elemento importante.
4.  **Consistencia:** los tres modelos deben representar diferentes
    perspectivas del mismo sistema.
5.  **Legibilidad:** organiza los diagramas para facilitar su
    comprensión.
6.  **Completitud:** no omitas componentes importantes por simplificar
    el análisis.
7.  **Notación UML:** utiliza correctamente la notación y semántica UML.
8.  **Editable:** todos los diagramas deben poder modificarse desde
    Enterprise Architect.
9.  **Transparencia:** cuando no sea posible recuperar alguna parte del
    diseño, indícalo expresamente en lugar de asumir su funcionamiento.

Si encuentras funcionalidades parcialmente implementadas, errores,
métodos vacíos o componentes desconectados, debes identificarlos y
evitar representarlos como funcionalidades completamente operativas.


Debes entregar:

**1. Proyecto Enterprise Architect (.eapx)**

Archivo principal que contiene los siguientes modelos:

-   Diagrama de casos de uso.
-   Diagrama de clases.
-   Diagramas de secuencia de los principales procesos.

**2. Informe de ingeniería inversa (.md)**

Un documento Markdown que contenga:

-   Resumen general del proyecto analizado.
-   Descripción de la arquitectura identificada.
-   Explicación de los actores y casos de uso.
-   Descripción de las clases y sus relaciones.
-   Descripción de cada diagrama de secuencia.
-   Justificación de las decisiones de modelado.
-   Limitaciones encontradas durante la recuperación del diseño.
-   Referencias a los archivos y métodos del código fuente que respaldan
    los modelos.


Realiza el trabajo de manera autónoma, siguiendo las fases descritas.

No comiences a generar diagramas sin haber realizado previamente el
análisis del código fuente.

Prioriza la exactitud y fidelidad del modelo sobre la rapidez de
generación.

No sustituyas el proyecto `.eapx` por archivos PNG, PDF, imágenes,
código PlantUML o diagramas en texto.

Si tu entorno no permite generar directamente un archivo `.eapx`,
identifica esa limitación y utiliza una alternativa técnicamente válida
que permita obtener finalmente el proyecto editable en Enterprise
Architect.

Al finalizar, proporciona los archivos generados y una breve explicación
de su contenido, indicando cualquier limitación o elemento que no haya
podido recuperarse.
