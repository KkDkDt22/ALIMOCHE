# PROYECTO ALIMOCHE · repositorio documental

Normas: `documentos/ALM-01/ALM-01.typ`. Repositorio, herramientas y publicación: `documentos/ALM-02/ALM-02.typ`.

## Compilar un documento

Desde esta carpeta (raíz del repositorio), con Typst 0.15.1 (`herramientas/typst-version.txt`):

```
typst compile --root . documentos/ALM-01/ALM-01.typ compilados/ALM-01.pdf
```

Para que el PDF muestre el commit en el pie:

```
typst compile --root . --input git_commit=$(git rev-parse --short=12 HEAD) documentos/ALM-01/ALM-01.typ compilados/ALM-01.pdf
```

En PowerShell: `--input git_commit=$(git rev-parse --short=12 HEAD)` funciona igual.

En VS Code con Tinymist, abra la carpeta raíz del repositorio (no la del documento) para que se resuelvan las rutas `/plantillas` y `/recursos`.

## Documento nuevo

Copie `plantillas/nuevo-documento.typ` a `documentos/<CÓDIGO>/<CÓDIGO>.typ`, complete el bloque `meta` y escriba el cuerpo. Las fechas de ejemplo `DD/MM/AAAA` impiden compilar hasta rellenarlas.

## Estructura

| Carpeta | Contenido |
|---|---|
| `documentos/` | Una carpeta por código con su `.typ` y figuras propias. |
| `plantillas/` | `alimoche.typ` (cajetín, estilo y validación comunes) y `nuevo-documento.typ`. |
| `recursos/` | Logos y marca de agua. |
| `publicados/` | Emisiones aprobadas; inmutables. |
| `herramientas/` | Versión de Typst y futuras comprobaciones. |
| `equipo.toml` | Personas y roles. |
| `compilados/` | PDF de trabajo; excluido de Git. |
