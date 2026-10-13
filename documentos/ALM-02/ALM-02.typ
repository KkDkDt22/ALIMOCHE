// PROYECTO ALIMOCHE · ALM-02
// Compilar desde la raíz del repositorio:
//   typst compile --root . documentos/ALM-02/ALM-02.typ compilados/ALM-02.pdf

#import "/plantillas/alimoche.typ": documento, esquema

#let meta = (
  codigo: "ALM-02",
  titulo: "Repositorio, herramientas y publicación",
  tipo: "Procedimiento",
  revision: "0.1",
  estado: "Borrador",
  creado: "13/10/2026",
  revisado: "13/10/2026",
  autor: "Equipo ALIMOCHE",
  revisores: (),
  aprobador: "Pendiente de designar",
  aprobacion: "Pendiente",
  padre: none,
  sigue-a: none,
  dependencias: ("ALM-01",),
)

#show: documento.with(meta)

#text(
  size: 8.2pt,
)[*Carácter:* procedimiento en borrador. Describe una implantación propuesta; las funciones del gestor marcadas como posteriores aún no existen.]

= Objeto y relación con ALM-01

Este documento describe cómo se aplican las reglas de ALM-01 con Git, GitHub, Typst y el gestor ALIMOCHE.exe: dónde se guardan los archivos, quién puede cambiar qué, cómo se compila un PDF y cómo se publica una emisión. No crea reglas documentales nuevas. Si una herramienta se sustituye, se revisa ALM-02 sin modificar ALM-01; si ambos discrepan, prevalece ALM-01.

#table(
  columns: (38mm, 1fr, 40mm),
  table.header([Componente], [Función], [Ubicación]),
  [Repositorio GitHub],
  [Fuente común, historial, permisos y propuestas de cambio.],
  [Organización del club, repositorio privado.],

  [Typst], [Compilación de los `.typ` a PDF con versión fijada.], [Incluido en el gestor; `herramientas/`.],
  [Plantilla común], [Cajetín, estilo y validación de metadatos.], [`plantillas/alimoche.typ`],
  [Comprobación automática], [Valida y compila cada propuesta antes de integrarla.], [`.github/workflows/`],
  [ALIMOCHE.exe], [Interfaz gráfica para Windows sobre Git y Typst.], [Repositorio propio del gestor.],
  [Git LFS], [Versiones de archivos CAD y binarios moderados.], [Mismo repositorio.],
)

= Estructura del repositorio

#figure(
  esquema(
    "ALIMOCHE/\n  documentos/        una carpeta por código\n    ALM-01/          ALM-01.typ y figuras propias\n    ALM-P00-A01/     ALM-P00-A01.typ, figuras/, datos/\n  plantillas/        alimoche.typ (común) y nuevo-documento.typ\n  recursos/          logos y marca de agua comunes\n  publicados/        emisiones aprobadas, nunca se modifican\n    ALM-P00/         ALM-P00_Rev-1.0_20270115.pdf + .toml (manifiesto)\n  cad/ calculos/ datos/   se abren con su familia documental\n  herramientas/      comprobador, generador de CODEOWNERS, versión de Typst\n  equipo.toml        personas, cuenta GitHub y roles\n  .github/           workflows/ y CODEOWNERS (generado)\n  compilados/        PDF de trabajo; excluido de Git\n  .gitattributes  .gitignore  README.md",
  ),
  kind: image,
  supplement: [Figura],
  caption: [Estructura de carpetas propuesta. La carpeta de un documento lleva su código, no su posición en la jerarquía.],
)

Las carpetas de `documentos/` están todas al mismo nivel. La jerarquía se lee del campo `padre` (ALM-01) y no de la ruta, de modo que un cambio de padre no mueve archivos ni rompe referencias. El nombre de carpeta y de archivo coincide con el código; ni revisión ni estado aparecen en él. Las imágenes comunes se citan desde la raíz (`/recursos/...`) y las propias del documento con ruta relativa a su carpeta.

Los PDF de trabajo se generan en `compilados/` y no se versionan, porque se pueden regenerar desde cualquier commit. Solo los PDF de emisiones aprobadas se guardan en `publicados/`, con su manifiesto.

= Personas, cuentas y roles

Cada integrante que redacta o revisa usa *su propia cuenta de GitHub*, invitada a la organización del club. No se utilizan cuentas ni credenciales compartidas: la cuenta es la identidad que registra quién cambió, revisó y aprobó cada documento. Quien solo consulta emisiones aprobadas no necesita cuenta si el club decide mantener una copia pública de `publicados/` (decisión pendiente, @sec-pend).

Las personas se registran una sola vez en `equipo.toml`. El nombre que figura allí es el que se escribe en `autor`, `revisores` y `aprobador` de los documentos; la comprobación automática rechaza nombres que no consten.

#figure(
  esquema(
    "[[persona]]\nnombre = \"Nombre Apellido\"      # igual que en los campos meta\ngithub = \"usuario-github\"\nroles  = [\"integrante\", \"aprobador\"]",
  ),
  kind: image,
  supplement: [Figura],
  caption: [Entrada de `equipo.toml`. Datos ficticios.],
)

#table(
  columns: (36mm, 1fr),
  table.header([Rol], [Puede hacer]),
  [Integrante], [Trabajar en ramas propias, crear documentos y abrir propuestas de cambio.],
  [Autor],
  [Responsable del documento declarado en `autor`. Su conformidad es necesaria para integrar cambios en ese documento.],

  [Revisor], [Examinar una revisión, comentar y dar conformidad a la propuesta.],
  [Aprobador], [Autorizar la emisión de los documentos que tiene asignados y crear su etiqueta de publicación.],
  [Team Leader], [Designar aprobadores, autorizar cambios de jerarquía o alcance y congelar configuraciones.],
  [Mantenedor],
  [Administrar plantillas, herramientas, permisos y copias de seguridad. No aprueba contenido técnico por serlo.],
)

Los permisos efectivos los impone GitHub, no el gestor. El gestor muestra u oculta acciones según `equipo.toml` para guiar a cada persona, pero cualquier cambio hecho con Git desde otra herramienta pasa por los mismos controles.

#table(
  columns: (1fr, 1fr),
  table.header([Regla de ALM-01], [Mecanismo en GitHub]),
  [Nadie modifica directamente la versión común.],
  [Rama `main` protegida: solo se integra mediante propuesta (pull request) con comprobación superada.],

  [El autor responde de su documento.],
  [`CODEOWNERS` asigna cada carpeta de `documentos/` a la cuenta de su autor; su conformidad es obligatoria. Se genera desde los metadatos y `equipo.toml`.],

  [El autor no aprueba su propia revisión.], [GitHub no admite la aprobación de una propuesta por quien la abrió.],
  [Solo el aprobador emite.],
  [Etiquetas `doc/*` restringidas; la comprobación verifica que quien etiqueta es el aprobador declarado.],

  [Una emisión no se sobrescribe.], [La comprobación rechaza cualquier modificación o borrado dentro de `publicados/`.],
)

Las ramas protegidas, la revisión obligatoria de propietarios y las reglas de etiquetas pueden depender del plan de la organización cuando el repositorio es privado. Debe confirmarse antes de implantar (@sec-pend); sin ellas, estas reglas quedan como norma de trabajo y no como bloqueo.

= Ramas y estados documentales

La rama `main` contiene el estado común del proyecto y siempre compila. Cada trabajo se hace en una rama con nombre `doc/<código>-<tema>`, por ejemplo `doc/alm-p00-requisitos-masa`. Una rama puede contener varios commits; su nombre no certifica nada. Integrar en `main` *no aprueba*: `main` contiene también borradores, que así quedan visibles para todo el equipo. El estado lo fija el campo `estado` del documento y la emisión, nunca la rama.

#table(
  columns: (25mm, 1fr, 30mm),
  table.header([Estado], [Situación en Git], [Lo hace]),
  [Borrador],
  [Commits en la rama de trabajo; propuesta abierta como borrador o integrada en `main` con estado Borrador.],
  [Autor],

  [En revisión], [Propuesta marcada para revisión y `estado` cambiado a «En revisión» en el mismo cambio.], [Autor],
  [Devuelto],
  [La propuesta recibe cambios solicitados; el autor vuelve el estado a Borrador y corrige.],
  [Revisor · autor],

  [Aprobado],
  [Propuesta conforme e integrada; commit de emisión con estado Aprobado y referencia en `aprobacion`; etiqueta `doc/<código>/<revisión>`; PDF y manifiesto en `publicados/`.],
  [Aprobador],

  [Obsoleto],
  [Commit en `main` con estado Obsoleto y motivo o sucesor; las emisiones previas se conservan.],
  [Aprobador · Team Leader],
)

Antes de empezar a trabajar se actualiza la copia local. Los commits llevan mensajes breves que nombran el documento, por ejemplo «ALM-P00: incorpora P00_REQ_05 desde A02». Un conflicto entre dos cambios del mismo texto nunca se resuelve automáticamente: la persona que integra elige el contenido correcto y, si afecta a una decisión técnica, consulta al autor. Los archivos CAD no se pueden fusionar, por lo que se bloquean antes de editarlos (@sec-cad).

= Compilación y PDF <sec-pdf>

La versión de Typst se fija en `herramientas/typst-version.txt` (0.15.1 en esta revisión) y es la que incluye el gestor. Se compila siempre desde la raíz del repositorio, pasando el commit:

#esquema(
  "typst compile --root . --input git_commit=$(git rev-parse --short=12 HEAD) \\\n    documentos/ALM-P00/ALM-P00.typ compilados/ALM-P00.pdf",
)

La plantilla valida los metadatos (ALM-01) y el commit aparece en el pie. Si el documento tiene cambios sin guardar en Git, el gestor añade «+cambios» al commit para que el PDF no se confunda con una versión registrada. Los metadatos de cualquier documento se obtienen en JSON con:

#esquema("typst eval --root . 'query(<meta>).first().value' --in documentos/ALM-01/ALM-01.typ")

#table(
  columns: (32mm, 1fr, 38mm),
  table.header([PDF], [Origen y uso], [Conservación]),
  [De trabajo], [Compilación local para leer y corregir.], [`compilados/`; no se versiona.],
  [De propuesta],
  [Generado por la comprobación automática al abrir o actualizar una propuesta; lo usan los revisores.],
  [Adjunto a la propuesta, temporal.],

  [Emisión], [Compilado desde la etiqueta de emisión; único válido para uso técnico.], [`publicados/`; inmutable.],
)

Cada emisión publica un PDF `<código>_Rev-<revisión>_<AAAAMMDD>.pdf` y un manifiesto `.toml` con el mismo nombre. El manifiesto registra código, revisión, fecha, commit, etiqueta, autor, revisores, aprobador, referencia de aprobación, versión de Typst, huella SHA-256 del PDF y revisión vigente de cada dependencia. Los nombres de emisión de este apartado son ilustrativos; la numeración de revisiones sigue ALM-01.

= Archivos CAD y datos voluminosos <sec-cad>

#table(
  columns: (40mm, 1fr, 1fr),
  table.header([Tipo], [Ubicación], [Motivo]),
  [Typst, TOML, scripts, CSV pequeños, figuras], [Git ordinario.], [Texto o tamaño moderado; diferencias legibles.],
  [CAD nativo, STEP, binarios moderados],
  [Git LFS, declarado en `.gitattributes`.],
  [Historial junto al proyecto sin inflar el repositorio.],

  [Mallas, barridos y resultados masivos],
  [Almacén externo con manifiesto (ubicación, huella, responsable).],
  [Git conserva la referencia, no los datos.],
)

Antes de editar un archivo CAD se bloquea (`git lfs lock`); el gestor lo ofrece como «Bloquear para editar» y muestra quién tiene cada bloqueo. Se libera al subir el cambio. Debe comprobarse la cuota de almacenamiento LFS de la organización antes de incorporar modelos.

= Comprobaciones automáticas

#table(
  columns: (28mm, 1fr, 32mm),
  table.header([Evento], [Comprobación], [Efecto si falla]),
  [Cada propuesta],
  [Compila los documentos modificados y sus dependientes; código igual a carpeta y archivo; códigos únicos; `padre`, `sigue-a` y `dependencias` existentes; sin ciclos de jerarquía; personas registradas en `equipo.toml`; `CODEOWNERS` actualizado; `publicados/` intacto.],
  [Bloquea la integración.],

  [Cambio en un documento con consumidores],
  [Lista los documentos que lo declaran en `dependencias` y lo comenta en la propuesta como alerta de impacto.],
  [Aviso; no cambia estados.],

  [Etiqueta `doc/*`],
  [Estado Aprobado, `aprobacion` distinta de «Pendiente», revisión igual a la de la etiqueta y autor de la etiqueta igual al aprobador.],
  [Rechaza la emisión.],

  [Etiqueta válida], [Compila, calcula huellas y añade PDF y manifiesto a `publicados/`.], [—],
)

Las comprobaciones verifican forma y coherencia, no contenido técnico. Un aviso de impacto no se resuelve cerrándolo: el autor del documento consumidor registra su evaluación según ALM-01.

= Gestor ALIMOCHE.exe

== Alcance e instalación

Aplicación para Windows que permite trabajar con el repositorio sin usar la terminal. Incluye Git, Git LFS y la versión fijada de Typst; no requiere permisos de administrador. Se descarga de la página de versiones de su repositorio y comprueba al arrancar si existe una más reciente. Al no estar firmado digitalmente, Windows puede mostrar un aviso de SmartScreen la primera vez.

En el primer arranque la persona inicia sesión con GitHub en el navegador, una sola vez; la credencial se guarda en el Administrador de credenciales de Windows. El gestor clona el repositorio en `Documentos\ALIMOCHE`, configura nombre y correo de Git desde la cuenta y localiza a la persona en `equipo.toml`. Una cuenta que no figure allí trabaja en modo de solo lectura.

== Vistas

- *Inicio:* indicador de sincronización (al día, cambios propios sin subir, novedades por traer, conflicto) y propuestas abiertas propias o pendientes de revisar.
- *Documentos:* árbol calculado desde `padre`, secuencia desde `sigue-a`, filtros por estado y autor; acciones según rol.
- *Historial:* gráfico de commits, ramas y etiquetas de emisión; desde cualquier punto puede generarse el PDF de ese estado.
- *Relaciones:* dependencias declaradas y documentos afectados por un cambio.
- *Publicados:* emisiones aprobadas con su manifiesto.

== Acciones y operación Git equivalente

#table(
  columns: (36mm, 1fr, 22mm),
  table.header([Acción], [Operación], [Fase]),
  [Traer cambios], [`git pull` sobre la rama actual; detiene y muestra cualquier conflicto.], [Inicial],
  [Empezar a trabajar], [Actualiza `main` y crea la rama `doc/<código>-<tema>`.], [Inicial],
  [Nuevo documento],
  [Pide código, título, tipo, padre y secuencia; valida unicidad y crea la carpeta desde `plantillas/nuevo-documento.typ`.],
  [Inicial],

  [Abrir para editar], [Abre el `.typ` en el editor elegido (VS Code con Tinymist recomendado).], [Inicial],
  [Generar PDF],
  [Compila con commit (@sec-pdf) y abre el PDF; muestra los errores de validación en lenguaje claro.],
  [Inicial],

  [Guardar versión], [Muestra los cambios; `git add` de los archivos elegidos y `git commit` con mensaje.], [Inicial],
  [Subir], [`git push` de la rama; nunca forzado.], [Inicial],
  [Pedir revisión], [Abre la propuesta y cambia el estado a En revisión con confirmación.], [Posterior],
  [PDF de esta versión], [Compila un commit o etiqueta del historial en una copia temporal.], [Posterior],
  [Bloquear CAD], [`git lfs lock` / `unlock`.], [Posterior],
  [Emitir], [Solo aprobador: commit de emisión, etiqueta y seguimiento de la publicación.], [Posterior],
)

El gestor no oculta conflictos ni errores, no cambia estado ni revisión sin una acción explícita de la persona autorizada, no fuerza subidas ni reescribe historial. Cada acción puede mostrar el comando Git equivalente, de modo que el gestor sirva también para aprender Git.

== Uso sin gestor

Quien trabaje en Linux o prefiera la terminal usa directamente `git` y `typst` con las mismas reglas: ramas `doc/...`, compilación desde la raíz con el commit, propuestas en GitHub. Las comprobaciones automáticas se aplican igual a todos.

= Decisiones pendientes <sec-pend>

#table(
  columns: (1fr, 1fr),
  table.header([Decisión], [Propuesta inicial]),
  [Plan de la organización GitHub y disponibilidad de ramas protegidas, propietarios obligatorios y reglas de etiquetas en repositorio privado.],
  [Comprobar el plan actual; solicitar el de equipo para educación si no las incluye.],

  [Personas, roles y aprobadores iniciales.], [Completar `equipo.toml` antes del primer documento real.],
  [Consulta sin cuenta.], [Copia pública solo de `publicados/`, generada automáticamente; o ninguna.],
  [Numeración de revisiones (borradores y primera emisión).], [Fijarla en ALM-01; ALM-02 la aplica.],
  [Cuota LFS y almacén de datos voluminosos.], [Git LFS al inicio; almacén externo cuando el volumen lo exija.],
  [Firma digital del gestor.], [Sin firma en el piloto; reconsiderar si se distribuye fuera del equipo.],
)

#v(3mm)
#text(
  size: 8pt,
)[*Nota de aplicación.* Antes de usar el sistema como oficial se hará un piloto con ALM-P00 y dos auxiliares: crear, revisar, emitir, modificar un auxiliar y comprobar la alerta de impacto sobre P00.]

Esta es una línea escrita por otro colaborador para comprobar las funcionalidades de github.
