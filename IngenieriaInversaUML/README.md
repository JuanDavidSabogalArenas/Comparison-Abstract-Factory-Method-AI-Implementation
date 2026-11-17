# Ingeniería inversa UML — AbstractFactoryReverseExample

Modelos UML recuperados por ingeniería inversa del proyecto Java
`AbstractFactoryReverseExample` (patrón **Abstract Factory**).

## Contenido

| Archivo / carpeta | Qué es |
|---|---|
| `AbstractFactoryReverseExample.eapx` | **Entregable principal.** Proyecto nativo de Sparx Enterprise Architect con los 6 diagramas como elementos UML editables. |
| `Informe_Ingenieria_Inversa.md` | Informe completo: arquitectura, actores/casos de uso, clases, secuencias, decisiones de modelado, limitaciones y trazabilidad. |
| `diagramas/*.puml` | Copia legible de cada diagrama en PlantUML (texto plano), por si se quiere ver sin abrir EA. |
| `build_eap_model.ps1` | Script que genera el `.eapx` usando la API COM de Enterprise Architect. |
| `export_previews.ps1` | Script que exporta un PNG de cada diagrama (verificación). |

## Diagramas

- **DCU01** — Casos de uso (`diagramas/01_casos_de_uso.puml`)
- **DC01** — Clases / Abstract Factory (`diagramas/02_clases.puml`)
- **DS01** — Iniciar la aplicación (`diagramas/03_secuencia_iniciar.puml`)
- **DS02** — Buscar vehículo de lujo (`diagramas/04_secuencia_buscar_lujo.puml`)
- **DS03** — Buscar vehículo no lujoso (`diagramas/05_secuencia_buscar_no_lujo.puml`)
- **DS04** — Salir de la aplicación (`diagramas/06_secuencia_salir.puml`)

## Cómo abrir

- **Enterprise Architect:** abrir `AbstractFactoryReverseExample.eapx`.
- **PlantUML:** abrir los `.puml` con cualquier visor PlantUML (extensión de
  VS Code, IntelliJ, o el servidor `plantuml.com`).

## Regenerar el `.eapx` (opcional)

```powershell
powershell -ExecutionPolicy Bypass -File build_eap_model.ps1
```

Requiere Enterprise Architect instalado (la API COM `EA.Repository`).
