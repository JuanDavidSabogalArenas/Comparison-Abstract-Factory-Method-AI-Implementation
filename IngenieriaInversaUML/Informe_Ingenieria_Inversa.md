# Informe de ingeniería inversa — AbstractFactoryReverseExample

Recuperación del diseño (modelos UML) a partir del código fuente Java del
proyecto `AbstractFactoryReverseExample`, siguiendo las fases del prompt
`prompt_ingenieria_inversa_UML.md`.

> **Actualización (tipo de vehículo BYCICLE).** El proyecto se amplió para
> agregar un tercer tipo de vehículo, **BYCICLE**, siguiendo el mismo patrón
> Abstract Factory. Se añadieron la fábrica concreta `BYCICLEVehicleFactory` y
> los productos `LuxuryBYCICLE` / `NonLuxuryBYCICLE`, se agregó la constante
> `VehicleFactory.BYCICLE = "Bycicle"` con su rama en `getVehicleFactory`, y el
> combo de tipo de `AutoSearchUI` ahora ofrece también *Bycicle*. El proyecto
> recompila sin errores. Todos los modelos de este informe y del `.eapx` ya
> reflejan este cambio. Nota de fidelidad: el identificador está escrito
> **`BYCICLE`** (no el inglés "BICYCLE") tal como aparece en el código.

---

## 1. Resumen general del proyecto analizado

- **Tipo de aplicación:** aplicación de escritorio Java SE con interfaz gráfica
  **Swing** (ventana `JFrame`) titulada *"Abstract Factory - Example"*.
- **Propósito funcional:** el usuario elige una **categoría** de vehículo
  (Luxury / Non-Luxury) y un **tipo** (Car / Suv / Bycicle) y pulsa *Search*; la
  aplicación construye el objeto vehículo correspondiente y muestra su nombre y
  sus características en una etiqueta.
- **Organización:** 14 archivos `.java`, todos en el **paquete por defecto**
  (ninguno declara `package`). Proyecto IntelliJ IDEA (`.idea/`, `.iml`); el JDK
  del proyecto es `openjdk-26` (`.idea/misc.xml`). Las clases compiladas están
  en `out/production/AbstractFactoryReverseExample`.
- **Punto de entrada:** `AutoSearchUI.main(String[])` en `AutoSearchUI.java`.
- **Dependencias externas:** solo la biblioteca estándar de Java
  (`javax.swing.*`, `java.awt.*`, `java.awt.event.*`, `java.lang.System`). No
  hay base de datos, red, archivos ni servicios externos.
- **Patrón de diseño principal:** **Abstract Factory** (fábrica abstracta de
  familias de productos). Secundariamente, `getVehicleFactory` funciona como un
  **Simple Factory / selector** estático.

> Trazabilidad: las afirmaciones de este informe se sustentan en los archivos
> citados entre paréntesis. Las firmas se confirmaron recompilando las fuentes
> con `javac` y revisando el bytecode con `javap -p`.

---

## 2. Arquitectura identificada

La aplicación es monolítica, de una sola capa, pero el código separa con
claridad los roles del patrón Abstract Factory y un conato de separación
vista/controlador:

| Rol (Abstract Factory) | Clase(s) | Archivo |
|---|---|---|
| Fábrica abstracta | `VehicleFactory` (abstracta) | `VehicleFactory.java` |
| Fábricas concretas | `CARVehicleFactory`, `SUVVehicleFactory`, `BYCICLEVehicleFactory` | `CARVehicleFactory.java`, `SUVVehicleFactory.java`, `BYCICLEVehicleFactory.java` |
| Productos abstractos | `Luxury`, `NonLuxury` (interfaces) | `Luxury.java`, `NonLuxury.java` |
| Productos concretos | `LuxuryCAR`, `LuxurySUV`, `LuxuryBYCICLE`, `NonLuxuryCAR`, `NonLuxurySUV`, `NonLuxuryBYCICLE` | archivos homónimos |
| Cliente | `ButtonHandler` | `AutoSearchUI.java` |
| Vista / arranque | `AutoSearchUI` (+ clase anónima `AutoSearchUI$1`) | `AutoSearchUI.java` |

Puntos de arquitectura relevantes recuperados del código:

1. **Familias de productos por variante.** Cada fábrica concreta produce la
   familia completa de una variante: `CARVehicleFactory` crea `LuxuryCAR` y
   `NonLuxuryCAR`; `SUVVehicleFactory` crea `LuxurySUV` y `NonLuxurySUV`;
   `BYCICLEVehicleFactory` crea `LuxuryBYCICLE` y `NonLuxuryBYCICLE`. Así se
   garantiza que los productos obtenidos de una misma fábrica son coherentes
   entre sí.
2. **Selector estático.** `VehicleFactory.getVehicleFactory(String)` decide la
   fábrica concreta según el tipo: `SUV` → `SUVVehicleFactory`; `BYCICLE` →
   `BYCICLEVehicleFactory`; `CAR` **o cualquier otro valor** →
   `CARVehicleFactory` (valor por defecto). Esto introduce una dependencia de la
   clase abstracta hacia sus subclases.
3. **Retornos covariantes.** Las fábricas concretas declaran tipos de retorno
   más específicos (`LuxuryCAR` en vez de `Luxury`). El compilador genera
   *métodos puente* (`getLuxury(): Luxury`, `getNonLuxury(): NonLuxury`),
   confirmado en el bytecode.
4. **Cliente desacoplado.** `ButtonHandler` solo depende de las abstracciones
   `VehicleFactory`, `Luxury` y `NonLuxury`; nunca nombra una clase de producto
   concreto. Es el punto donde el patrón aporta su valor.
5. **GUI fuera del EDT.** `main` crea la ventana directamente, sin
   `SwingUtilities.invokeLater`; es una desviación de la práctica recomendada en
   Swing (se documenta, no se "corrige").

---

## 3. Modelo funcional — actores y casos de uso

**Actor único: `Usuario`.** Es el único agente que interactúa con el sistema; no
hay sistemas externos. Todos los casos de uso se derivan de `ButtonHandler`
(manejo de botones) y de los métodos de `AutoSearchUI`.

| Caso de uso | Descripción | Respaldo en código |
|---|---|---|
| **CU01 - Buscar vehículo** | Al pulsar *Search* se lee la selección, se obtiene la fábrica, se crea el producto y se muestra el resultado. | `ButtonHandler.actionPerformed`, rama `SEARCH` |
| **CU02 - Buscar vehículo de lujo** | Especialización de CU01 cuando la categoría es *Luxury* (`getLuxury()`, `getLuxuryName()`, `getLuxuryFeatures()`). | `if (vhCategory.equals(LUXURY))` |
| **CU03 - Buscar vehículo no lujoso** | Especialización de CU01 cuando la categoría es *Non-Luxury* (`getNonLuxury()`, `getNLName()`, `getNLFeatures()`). | `if (vhCategory.equals(NON_LUXURY))` |
| **CU04 - Obtener criterios de búsqueda** | Lectura de categoría y tipo de los combos. | `getSelectedCategory()`, `getSelectedType()` |
| **CU05 - Mostrar resultado** | Escribe el resultado en `lblCarNameValue`. | `setResult(String)` |
| **CU06 - Salir de la aplicación** | Botón *Exit* → `System.exit(1)`; cierre de ventana → `System.exit(0)`. | rama `EXIT`; `AutoSearchUI$1.windowClosing` |

**Relaciones:** `Usuario` se asocia con CU01 y CU06. CU02 y CU03 **generalizan**
CU01 (son variantes de la búsqueda). CU01 **incluye** (`<<include>>`) CU04 y
CU05, porque leer los criterios y mostrar el resultado se ejecutan siempre en
toda búsqueda. No se modela `extend`: no se halló comportamiento condicional
*opcional* que extienda otro caso (las variantes son excluyentes → generalización).

Diagrama: `DCU01` en el `.eapx` / `diagramas/01_casos_de_uso.puml`.

---

## 4. Modelo estructural — clases y relaciones

Clases del proyecto (paquete por defecto) con sus miembros recuperados del
código y del bytecode:

- **`Luxury`** «interface» — `getLuxuryName()`, `getLuxuryFeatures()`.
- **`NonLuxury`** «interface» — `getNLName()`, `getNLFeatures()`.
- **`LuxuryCAR` / `LuxurySUV`** — `-name: String`; constructor con nombre;
  implementan `Luxury`. `getLuxuryFeatures()` devuelve cadenas constantes
  (`"Luxury Car Features "` / `"Luxury SUV Features "`).
- **`NonLuxuryCAR` / `NonLuxurySUV`** — `-name: String`; constructor con nombre;
  implementan `NonLuxury`. Características: `"Non-Luxury CAR Features "` /
  `"Non-Luxury SUV Features "`.
- **`LuxuryBYCICLE` / `NonLuxuryBYCICLE`** — productos concretos de la variante
  Bycicle (agregada); `-name: String`; constructor con nombre; implementan
  `Luxury` / `NonLuxury`. Características: `"Luxury Bycicle Features "` /
  `"Non-Luxury BYCICLE Features "`.
- **`VehicleFactory`** «abstract» — constantes `CAR = "Car"`, `SUV = "Suv"`,
  `BYCICLE = "Bycicle"`; métodos abstractos `getLuxury(): Luxury`,
  `getNonLuxury(): NonLuxury`; estático `getVehicleFactory(String): VehicleFactory`.
- **`CARVehicleFactory` / `SUVVehicleFactory` / `BYCICLEVehicleFactory`** —
  heredan de `VehicleFactory` y redefinen los métodos de creación con retorno
  covariante.
- **`AutoSearchUI`** — hereda de `JFrame`; constantes de texto (`SEARCH`,
  `EXIT`, `LUXURY`, `NON_LUXURY`, `newline`); atributos privados de los
  controles Swing (`cmbVehicleCategory`, `cmbVehicleType`, cuatro `JLabel`);
  `main`, constructor, `getSelectedCategory`, `getSelectedType`, `setResult`.
- **`ButtonHandler`** — clase de nivel superior **no pública** (visibilidad de
  paquete); implementa `ActionListener`; atributo `objAutoSearchUI`;
  `actionPerformed` y dos constructores (con y sin vista).
- **`AutoSearchUI$1`** «anonymous» — subclase anónima de `WindowAdapter` creada
  en `main`; redefine `windowClosing`.

**Relaciones recuperadas:**

- **Realización:** `LuxuryCAR`, `LuxurySUV`, `LuxuryBYCICLE` → `Luxury`;
  `NonLuxuryCAR`, `NonLuxurySUV`, `NonLuxuryBYCICLE` → `NonLuxury`;
  `ButtonHandler` → `ActionListener`.
- **Herencia:** `CARVehicleFactory`, `SUVVehicleFactory`, `BYCICLEVehicleFactory`
  → `VehicleFactory`; `AutoSearchUI` → `JFrame`; `AutoSearchUI$1` → `WindowAdapter`.
- **Asociación:** `ButtonHandler → AutoSearchUI` por el atributo
  `objAutoSearchUI`, con multiplicidad **0..1** (el constructor sin argumentos lo
  deja en `null`). Extremo del lado `ButtonHandler` = `*` (la vista no guarda a
  sus manejadores; solo los registra como *listeners*).
- **Dependencia «create»:** `AutoSearchUI → ButtonHandler` y `→ AutoSearchUI$1`;
  `VehicleFactory → CARVehicleFactory`, `→ SUVVehicleFactory` y
  `→ BYCICLEVehicleFactory`; cada fábrica concreta → sus dos productos.
- **Dependencia «use»:** `AutoSearchUI → VehicleFactory` (constantes
  `CAR`/`SUV`/`BYCICLE`); `ButtonHandler → VehicleFactory`, `→ Luxury`, `→ NonLuxury`.

**Multiplicidades deducibles:** solo la de la asociación `ButtonHandler`–
`AutoSearchUI` (0..1 / *). El resto de colaboraciones son creaciones o usos de
variables locales, que se modelan como dependencias, no como asociaciones con
multiplicidad.

Diagrama: `DC01` en el `.eapx` / `diagramas/02_clases.puml`.

---

## 5. Modelo de comportamiento — diagramas de secuencia

Se recuperaron cuatro escenarios concretos. Cada mensaje corresponde a una
llamada identificable en el código.

### DS01 — Iniciar la aplicación
`AutoSearchUI.main` crea `frame = new AutoSearchUI()`; el constructor instancia
los dos `JComboBox` y los llena (`addItem`, incluido `VehicleFactory.BYCICLE` en
el combo de tipo), crea los botones *Search*/*Exit* con
sus mnemónicos, crea `new ButtonHandler(this)` para *Search* y
`new ButtonHandler()` para *Exit*, y los registra con `addActionListener`.
De vuelta en `main`, se crea la clase anónima `AutoSearchUI$1`, se registra con
`addWindowListener` y la ventana se dimensiona y se muestra
(`setSize(1050,600)`, `setVisible(true)`). Se omiten por abstracción las
etiquetas, el `JPanel`, el `GridBagLayout`/`GridBagConstraints` y
`SwingUtilities.updateComponentTreeUI`, por no afectar a la lógica.
Archivo: `diagramas/03_secuencia_iniciar.puml`.

### DS02 — Buscar vehículo de lujo
Flujo de CU02. `actionPerformed` (dentro de `opt` SEARCH) lee categoría y tipo,
invoca `getVehicleFactory(vhType)` (fragmento `alt` con tres ramas: CAR-por-defecto
/ SUV / BYCICLE) y, como la categoría es *Luxury*, llama `vf.getLuxury()`. El
segundo `alt` (`vf es CARVehicleFactory` / `SUVVehicleFactory` /
`BYCICLEVehicleFactory`) modela el **despacho polimórfico**: según la fábrica real
se crea `LuxuryCAR("Luxury-Car")`, `LuxurySUV("Luxury-SUV")` o
`LuxuryBYCICLE("Luxury-Bycicle")` y se consultan `getLuxuryName()`/`getLuxuryFeatures()`.
Finalmente `setResult(...)` → `lblCarNameValue.setText(...)`.
Archivo: `diagramas/04_secuencia_buscar_lujo.puml`.

### DS03 — Buscar vehículo no lujoso
Flujo de CU03, simétrico a DS02 con la rama *Non-Luxury*: `vf.getNonLuxury()`,
productos `NonLuxuryCAR("NonLuxuryL-Car")`, `NonLuxurySUV("Non-Luxury-SUV")` o
`NonLuxuryBYCICLE("NonLuxuryL-Bycicle")`, y métodos `getNLName()`/`getNLFeatures()`.
Archivo: `diagramas/05_secuencia_buscar_no_lujo.puml`.

### DS04 — Salir de la aplicación
Flujo de CU06, con `alt` de dos operandos: (a) botón *Exit* →
`actionPerformed` → `opt` EXIT → `System.exit(1)`; (b) cierre de ventana →
`AutoSearchUI$1.windowClosing` → `System.exit(0)`.
Archivo: `diagramas/06_secuencia_salir.puml`.

---

## 6. Justificación de las decisiones de modelado

- **Interfaces como «interface» y clase abstracta como «abstract».** Refleja
  exactamente el código (`interface Luxury`, `abstract class VehicleFactory`).
- **`ButtonHandler` como CLIENTE del patrón.** Aunque también cumple de hecho el
  rol de un pequeño controlador (lee la vista, invoca la fábrica, escribe el
  resultado), su dependencia exclusiva de abstracciones es lo que ejemplifica
  Abstract Factory, de ahí el énfasis.
- **Retornos covariantes mostrados con el tipo específico.** En el diagrama de
  clases `CARVehicleFactory.getLuxury()` se muestra devolviendo `LuxuryCAR`,
  igual que en el código; los métodos puente no se dibujan por ser detalle del
  compilador (se mencionan en notas).
- **Creaciones modeladas como dependencia «create», no como asociación.** Los
  objetos producto son variables locales de corta vida; no hay campos que los
  retengan, así que una asociación con multiplicidad sería falsa.
- **`include` vs `extend` vs generalización en casos de uso.** Lo invariable de
  toda búsqueda (leer criterios, mostrar resultado) se modela con `include`; las
  dos categorías, al ser alternativas del mismo objetivo, con generalización.
- **Tipos de Java SE en un paquete aparte** («Bibliotecas externas»), sin
  miembros, para distinguir con claridad lo que es del proyecto de lo que no.

---

## 7. Limitaciones encontradas durante la recuperación

- **Diseño vs. implementación (elementos inferidos).** Las multiplicidades, los
  estereotipos de rol del patrón y las distinciones `include`/generalización son
  **inferencias** a partir del comportamiento; el código no las declara
  explícitamente.
- **Detalles de maquetación omitidos.** La construcción de la GUI
  (`GridBagLayout`, `GridBagConstraints`, posiciones, `JLabel`, `JPanel`) no se
  modela en secuencia por ser ruido sin valor arquitectónico; queda documentado.
- **Herencia Swing resumida.** Solo se representan los tipos externos
  directamente referenciados (`JFrame`, `JComboBox`, `JButton`, `JLabel`,
  `WindowAdapter`, `ActionListener`, `ActionEvent`, `WindowEvent`, `System`), no
  toda su jerarquía.
- **Marcas automáticas de EA.** En el `.eapx`, las líneas de vida creadas con
  mensaje `new` muestran la "X" de destrucción que Enterprise Architect añade por
  defecto; es una convención de la herramienta, no implica que el código destruya
  explícitamente esos objetos (en Java la liberación la hace el recolector de
  basura). Las copias en PlantUML no añaden esa marca.

### Defectos / rarezas del código original (representados tal cual, sin "arreglar")
- **`NonLuxuryCAR` se crea con el nombre `"NonLuxuryL-Car"`** (una "L" de más),
  en `CARVehicleFactory.getNonLuxury()`. Es un error del código; se modela tal
  cual por fidelidad. **La misma rareza se repite en la variante nueva:**
  `BYCICLEVehicleFactory.getNonLuxury()` crea `"NonLuxuryL-Bycicle"`.
- **Identificador `BYCICLE` mal escrito.** El tipo agregado usa `BYCICLE`
  (valor `"Bycicle"`) en vez del inglés correcto "BICYCLE". Se conserva tal cual.
- **Mayúsculas inconsistentes en las *features* de BYCICLE.** `LuxuryBYCICLE`
  devuelve `"Luxury Bycicle Features "` mientras que `NonLuxuryBYCICLE` devuelve
  `"Non-Luxury BYCICLE Features "` (una en minúsculas, la otra en mayúsculas).
- **Códigos de salida distintos:** botón *Exit* usa `System.exit(1)` y el cierre
  de ventana `System.exit(0)`.
- **`ButtonHandler` del botón Exit sin vista.** Se crea con `new ButtonHandler()`
  (`objAutoSearchUI = null`). Solo funciona porque la rama EXIT invoca
  `System.exit` antes de tocar la vista; si ese manejador recibiera *Search*
  lanzaría `NullPointerException`.
- **Constante `newline` declarada y no usada** en `AutoSearchUI`.
- **GUI construida fuera del EDT** (sin `invokeLater`).
- `JComboBox` se usa como *raw type* (sin genéricos).

---

## 8. Referencias de trazabilidad (archivo → elemento del modelo)

| Archivo fuente | Elementos / mensajes del modelo |
|---|---|
| `Luxury.java`, `NonLuxury.java` | interfaces producto; operaciones `getLuxury*` / `getNL*` |
| `LuxuryCAR/LuxurySUV/NonLuxuryCAR/NonLuxurySUV.java` | productos concretos; atributos `name`; cadenas de *features* |
| `LuxuryBYCICLE.java`, `NonLuxuryBYCICLE.java` | productos concretos de la variante Bycicle; atributos `name`; cadenas de *features* |
| `VehicleFactory.java` | fábrica abstracta; constantes CAR/SUV/BYCICLE; `getVehicleFactory` (fragmento `alt` de DS02/DS03); dependencias «create» a fábricas concretas |
| `CARVehicleFactory.java`, `SUVVehicleFactory.java`, `BYCICLEVehicleFactory.java` | fábricas concretas; «create» a productos; mensajes `getLuxury`/`getNonLuxury` |
| `AutoSearchUI.java` (clase `AutoSearchUI`) | vista/arranque; CU04/CU05; DS01 completo (incluye `addItem(VehicleFactory.BYCICLE)`); `getSelected*`, `setResult` |
| `AutoSearchUI.java` (clase `ButtonHandler`) | cliente; CU01–CU03, CU06 (rama EXIT); cuerpo de DS02/DS03/DS04 |
| `AutoSearchUI.java` (anónima) → `AutoSearchUI$1.class` | `windowClosing` → `System.exit(0)` en DS04 |

---

## 9. Entregables

- **`AbstractFactoryReverseExample.eapx`** — proyecto nativo de Enterprise
  Architect con los paquetes *01 Modelo funcional*, *02 Modelo estructural* y
  *03 Modelo de comportamiento*, y los diagramas `DCU01`, `DC01`, `DS01`–`DS04`
  como elementos UML editables. **Incluye el tipo BYCICLE.**
- **`diagramas/*.puml`** — copia legible y editable de los seis diagramas en
  PlantUML (texto plano), por si se desea revisarlos sin abrir Enterprise
  Architect.
- **`Informe_Ingenieria_Inversa.md`** — este documento.
- **Scripts de apoyo:** `build_eap_model.ps1` (genera el `.eapx` vía la API COM
  de EA) y `export_previews.ps1` (exporta PNG de verificación).
