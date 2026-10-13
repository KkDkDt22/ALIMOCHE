// PROYECTO ALIMOCHE · ALM-01
// Edite solo el bloque «meta» y el cuerpo. El cajetín, el estilo y las
// comprobaciones están en /plantillas/alimoche.typ (común a todos).
// Compilar desde la raíz del repositorio:
//   typst compile --root . documentos/ALM-01/ALM-01.typ compilados/ALM-01.pdf

#import "/plantillas/alimoche.typ": documento, esquema

// ── METADATOS: única fuente de información del cajetín ──────────────────────
#let meta = (
  codigo: "ALM-01",
  titulo: "Bases y Arquitectura Documental",
  tipo: "Normas documentales",
  revision: "0.2",
  estado: "Borrador",          // Borrador | En revisión | Aprobado | Obsoleto
  creado: "13/10/2026",        // Primera creación del documento: no se modifica.
  revisado: "13/10/2026",      // Fecha de la última revisión de contenido.
  autor: "Equipo ALIMOCHE",    // Responsable de redacción.
  revisores: (),               // Lista de nombres: ("Nombre Apellido",)
  aprobador: "Pendiente de designar",
  aprobacion: "Pendiente",     // Referencia de la autorización al aprobar.
  padre: none,                 // Código del padre, o none si es documento raíz.
  sigue-a: none,               // Documento previo en la secuencia, o none.
  dependencias: (),            // Entradas técnicas declaradas; no son jerarquía.
)

#show: documento.with(meta)

#text(size: 8.2pt)[*Carácter:* norma documental en borrador. Su aplicación formal comienza tras la aprobación indicada en el cajetín.]

= Objeto y regla de gobierno

Este documento define cómo se ordenan, identifican, relacionan y revisan los documentos técnicos del Proyecto ALIMOCHE. Se aplica a prediseño, diseño, fabricación y ensayos. Cada documento conserva sus métodos, datos y conclusiones; ALM-01 establece únicamente las reglas comunes de control documental. ALM-02 describe cómo se aplican estas reglas con el repositorio, la compilación y el gestor ALIMOCHE.exe; si ambos discrepan, prevalece ALM-01 y se corrige ALM-02.

La jerarquía expresa *subordinación*: un documento auxiliar desarrolla una parte delimitada de su documento padre y declara ese único padre. Un documento sin padre se registra como independiente. La *secuencia* expresa el orden de trabajo entre documentos del mismo nivel y no crea filiación. Las referencias y entradas técnicas pueden cruzar ramas sin cambiar ninguna de esas relaciones.

= Jerarquía documental

Los códigos existentes sirven como punto de partida. ALM-00, ALM-01 y ALM-02 son documentos generales independientes y previos a la serie P; aquí no se establece una relación padre–hijo entre ellos ni de ellos hacia P00. Para ilustrar la serie P se muestran P00, P01 y P02: P01 sigue a P00 y P02 sigue a P01, sin que esa secuencia fije el catálogo definitivo. Los auxiliares A01 y A02 ilustran la subordinación a P00. Proceden de documentos ficticios de ejemplo y no representan emisiones aprobadas.

#figure(
  esquema("DOCUMENTOS GENERALES INDEPENDIENTES\nALM-00  Enunciado y bases de diseño\nALM-01  Bases y Arquitectura Documental\nALM-02  Repositorio, herramientas y publicación\n\nSUBORDINACIÓN EN LA SERIE P\nALM-P00  Pliego de especificaciones\n├── ALM-P00-A01  Estudio operativo (ejemplo)\n└── ALM-P00-A02  Aeronaves de referencia (ejemplo)\n\nSECUENCIA EN LA SERIE P (NO SUBORDINACIÓN)\nALM-P00  →  ALM-P01  →  ALM-P02"),
  kind: image,
  supplement: [Figura],
  caption: [Esquema ilustrativo: P00 es padre de A01/A02; las flechas P00–P01–P02 indican orden, no parentesco documental.],
)

Cada relación se declara una sola vez, en el documento que la origina. El hijo declara su `padre`; el documento siguiente declara `sigue-a`. Ningún documento enumera sus hijos ni sus sucesores: el árbol, la secuencia y la lista de afectados se calculan leyendo los metadatos de todos los documentos. Así una relación no puede quedar escrita de forma distinta en dos sitios.

Las familias posteriores de aerodinámica, estructuras, estabilidad y vuelo, CAD, cálculo, fabricación y ensayos se abrirán solo al definir su alcance y responsable. Su código se reservará antes de redactar; no se crean ramas por mera afinidad temática. La jerarquía se modifica mediante una decisión documental explícita, con actualización de las referencias afectadas.

= Identificación y salidas técnicas

El identificador es único, permanente y no reutilizable. `ALM-00`, `ALM-01` y `ALM-02` son documentos generales; `ALM-P00` identifica una pieza principal de prediseño; `ALM-P00-A01` identifica un auxiliar subordinado a P00. El sufijo `A##` expresa subordinación documental. El nombre del archivo fuente es el código seguido de `.typ`; título, revisión y estado no se añaden al nombre. Una revisión nueva conserva el mismo código.

Un código se *reserva* creando su archivo fuente con el bloque de metadatos completo, estado Borrador y cuerpo vacío. Ese archivo es el registro de la reserva: no existe una lista paralela que pueda contradecirlo. Un código que se abandona no se borra ni se reutiliza; su archivo pasa a Obsoleto con el motivo en el cuerpo.

Una *salida* (output) es un requisito, parámetro, dato, criterio o evidencia que se incorpora a un documento de uso. Su código breve tiene la forma `P00_TIPO_NN`: `P00` identifica ese documento, `TIPO` clasifica la salida y `NN` es un número correlativo de dos cifras dentro de cada tipo. `P00_REQ_05` identifica, por ejemplo, el requisito 05 usado en P00. Aunque su definición técnica esté en `ALM-P00-A02`, el identificador pertenece a P00: allí se registra y se cita expresamente el código, la revisión y el apartado de A02. El nombre descriptivo, valor, unidad y fuente se escriben en la ficha o el texto, nunca dentro del identificador.

#table(
  columns: (22mm, 45mm, 1fr),
  table.header([Tipo], [Significado], [Uso de la salida]),
  [REQ], [Requisito], [Condición verificable que limita el diseño.],
  [CRIT], [Criterio], [Regla de comparación, selección o aceptación.],
  [DEC], [Decisión], [Elección documentada entre alternativas.],
  [HIP], [Hipótesis], [Supuesto de cálculo o diseño que debe poder revisarse.],
  [PAR], [Parámetro], [Variable de diseño; código breve como `P00_PAR_05`.],
  [DAT], [Dato o resultado], [Valor o resultado; magnitud, unidad y fuente van fuera del código.],
  [INT], [Interfaz], [Condición que vincula dos subsistemas o entregables.],
  [VER], [Verificación], [Evidencia de ensayo, cálculo o comprobación.],
  [RIE], [Riesgo], [Condición adversa y efecto sobre el proyecto.],
)

Los tipos `LEG` (hallazgo legal u operativo) y `REF` (dato de aeronave de referencia) aparecen en ejemplos previos; si se conservan, siguen la misma regla corta. Cada serie numérica es local al documento de uso y al tipo: `P00_REQ_05` y `P00_PAR_05` no se confunden. No se reutiliza un número anulado. Una salida definida en un auxiliar recibe código P00 solo cuando P00 la incorpora y documenta su procedencia.

#figure(
  block(width: 100%, inset: 3mm, stroke: .5pt + black, fill: white)[
    #align(center)[
      #text(weight: "bold")[Definición:]
      ALM-P00-A02
      #h(4mm) →
      #text(weight: "bold")[Registro y uso:]
      P00_REQ_05 en ALM-P00
      #h(4mm) →
      #text(weight: "bold")[Referencia posterior:]
      ALM-P01
    ]
  ],
  kind: image,
  supplement: [Figura],
  caption: [El código de la salida corresponde a P00; P00 identifica la fuente A02. P01 puede citarla sin pasar a ser hijo de P00.],
)

Un documento posterior que use `P00_REQ_05` cita P00 y su revisión, y declara `ALM-P00` en `dependencias`. P00 conserva la referencia precisa a A02 y su revisión. Si cambia A02, se examina primero el efecto en P00 y después en los consumidores de P00. Estas dependencias técnicas no modifican la subordinación documental: A02 sigue siendo hijo de P00, mientras P01 permanece al mismo nivel que P00.

= Cabecera y control de revisión

Cada documento contiene un único bloque `meta` al principio de su archivo `.typ`; es la sola fuente de los datos del cajetín y de sus relaciones. La maquetación, el cajetín y las comprobaciones residen en una plantilla común, `plantillas/alimoche.typ`, que todos los documentos importan. Un cambio de formato se hace una vez en la plantilla; no se copia el cajetín en cada documento.

#table(
  columns: (32mm, 1fr),
  table.header([Campo], [Regla de cumplimentación]),
  [`codigo` · `titulo`], [Código único asignado antes de redactar y título descriptivo.],
  [`tipo`], [Función documental, no fase ni estado. En ALM-01: «Normas documentales».],
  [`revision`], [Número de emisión controlada, como texto («0.2»); los commits intermedios no lo incrementan por sí solos.],
  [`estado`], [Una de las cuatro opciones cerradas definidas abajo.],
  [`creado`], [Fecha en que se abrió por primera vez el documento (DD/MM/AAAA); permanece fija.],
  [`revisado`], [Fecha de la última revisión de contenido; cambia al emitir una revisión.],
  [`autor`], [Responsable de redacción; responde del contenido y de evaluar el impacto de sus entradas.],
  [`revisores`], [Lista de personas que examinan la revisión; vacía mientras no se designen.],
  [`aprobador`], [Persona designada para autorizar la emisión.],
  [`aprobacion`], [Referencia de la autorización (acta, fecha, propuesta); «Pendiente» hasta aprobar.],
  [`padre`], [Código del único padre, o `none` si es independiente.],
  [`sigue-a`], [Documento previo en la secuencia de trabajo, o `none`. No crea filiación.],
  [`dependencias`], [Códigos cuyas salidas usa el documento; base de la evaluación de impacto.],
  [Hoja · commit], [Se calculan al compilar; nunca se escriben a mano.],
)

Al compilar, la plantilla comprueba los metadatos y detiene la compilación con un mensaje explicativo si un campo falta o no es válido: estado fuera de la lista, código, fecha o revisión mal escritos, documento que es su propio padre o dependencia, o estado Aprobado sin referencia de aprobación. Estas comprobaciones verifican la forma, no el contenido técnico. La existencia de padres y dependencias se comprueba en el repositorio (ALM-02).

El campo `estado` admite solo *Borrador*, *En revisión*, *Aprobado* u *Obsoleto*. Borrador permite redacción; En revisión significa que se ha enviado para examen; Aprobado exige decisión del aprobador designado y evidencia conservada; Obsoleto retira la revisión de uso corriente sin borrar el histórico. Las transiciones normales son Borrador → En revisión → Aprobado → Obsoleto; una revisión devuelta pasa de En revisión a Borrador. Un contenido aprobado que cambia inicia nueva revisión en Borrador. El autor no aprueba su propia revisión.

Git conserva la historia de edición. Un *commit* identifica una modificación, una *rama* agrupa trabajo y la *revisión documental* identifica una emisión controlada. La fecha de revisión y el número de revisión cambian cuando se emite contenido nuevo para examen o aprobación; correcciones editoriales durante el mismo examen pueden quedar en commits de la misma revisión. El commit del que procede un PDF lo inserta la herramienta de compilación y aparece en el pie; una compilación local sin él se identifica como tal. La versión aprobada conserva el PDF, el `.typ`, el commit y la evidencia de aprobación. La aprobación no se deduce del nombre de archivo ni de la compilación.

Cuando cambie una entrada técnica, el autor del documento consumidor evalúa el impacto y registra «sin impacto», «actualizar» o «pendiente». No se cambian automáticamente su estado ni su revisión. Solo después de revisar el contenido afectado se emite una nueva revisión si procede.

#v(3mm)
#text(size: 8pt)[*Nota de aplicación.* Los códigos y ramas de los ejemplos previos se muestran para explicar la estructura; su aprobación y la designación de responsables quedan sujetas al control del proyecto.]
