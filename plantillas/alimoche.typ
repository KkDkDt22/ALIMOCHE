// PROYECTO ALIMOCHE · plantilla común de documentos técnicos.
// Contiene el marco, el cajetín, el estilo y la validación de metadatos.
// No se copia en cada documento: cada .typ la importa con
//   #import "/plantillas/alimoche.typ": documento
//   #show: documento.with(meta)
// Compilar siempre desde la raíz del repositorio:
//   typst compile --root . documentos/ALM-01/ALM-01.typ compilados/ALM-01.pdf
// Un cambio de formato aquí afecta a todos los documentos al recompilarlos;
// las emisiones ya publicadas conservan su PDF original (ALM-02).

#let ESTADOS = ("Borrador", "En revisión", "Aprobado", "Obsoleto")

#let CAMPOS = (
  "codigo", "titulo", "tipo", "revision", "estado", "creado", "revisado",
  "autor", "revisores", "aprobador", "aprobacion", "padre", "sigue-a", "dependencias",
)

#let patron-codigo = regex("^ALM-[A-Z0-9]+(-[A-Z0-9]+)*$")
#let patron-fecha = regex("^[0-3][0-9]/[01][0-9]/[0-9]{4}$")
#let patron-revision = regex("^[0-9]+[.][0-9]+$")

// ── Validación: un error detiene la compilación con un mensaje claro ───────
#let mostrar(v) = if type(v) == str { v } else { repr(v) }

#let validar(m) = {
  for c in CAMPOS {
    assert(c in m, message: "Falta el campo «" + c + "» en el bloque meta.")
  }
  let cod = m.codigo
  assert(type(cod) == str and cod.match(patron-codigo) != none,
    message: "Código no válido: «" + mostrar(cod) + "». Forma esperada: ALM-P00, ALM-P00-A01…")
  assert(m.estado in ESTADOS,
    message: "Estado no permitido: «" + mostrar(m.estado) + "». Use: " + ESTADOS.join(", ") + ".")
  assert(type(m.revision) == str and m.revision.match(patron-revision) != none,
    message: "La revisión debe escribirse como texto «0.1», «1.0»…")
  for f in ("creado", "revisado") {
    assert(type(m.at(f)) == str and m.at(f).match(patron-fecha) != none,
      message: "La fecha «" + f + "» debe tener la forma DD/MM/AAAA.")
  }
  for f in ("padre", "sigue-a") {
    let v = m.at(f)
    assert(v == none or (type(v) == str and v.match(patron-codigo) != none),
      message: "«" + f + "» debe ser none o un código ALM válido.")
    assert(v != cod, message: "Un documento no puede ser su propio «" + f + "».")
  }
  assert(type(m.revisores) == array,
    message: "«revisores» es una lista: () o (\"Nombre\",). Ojo a la coma final con un solo elemento.")
  assert(type(m.dependencias) == array,
    message: "«dependencias» es una lista: () o (\"ALM-00\",). Ojo a la coma final con un solo elemento.")
  for d in m.dependencias {
    assert(type(d) == str and d.match(patron-codigo) != none,
      message: "Dependencia no válida: «" + mostrar(d) + "».")
    assert(d != cod, message: "Un documento no puede depender de sí mismo.")
  }
  if m.estado == "Aprobado" {
    assert(m.aprobacion != "Pendiente",
      message: "Un documento Aprobado debe indicar en «aprobacion» la referencia de su autorización.")
  }
}

// ── Commit: lo inserta la herramienta de compilación, nunca se escribe a mano
#let commit-git = sys.inputs.at("git_commit", default: none)

// ── Cajetín, reproducción de la plantilla original (texto centrado en su celda) ──
#let borde = .65pt + black

// Cada celda: etiqueta pequeña y valor, centrados en vertical y con margen
// interior igual en todas las celdas (el texto no toca las líneas).
#let campo(nombre, valor, tam: 8pt, extra: none) = box(inset: (x: 2.5mm, y: 1.2mm))[
  #set par(justify: false, leading: .42em, spacing: .42em)
  #text(size: 6.8pt, weight: "bold")[#nombre] \
  #text(size: tam, weight: "bold")[#valor]
  #if extra != none [ \ #extra]
]

#let cabecera(d) = {
  let elaboracion = if d.revisores.len() == 0 { d.autor } else {
    d.autor + " / " + d.revisores.join(", ")
  }
  table(
    columns: (36mm, 75mm, 28mm, 19mm, 32mm),
    rows: (17mm, 11mm, 13mm),
    stroke: borde,
    inset: 0pt,
    align: (x, y) => if x == 0 { center + horizon } else { left + horizon },
    table.cell(x: 0, y: 0, rowspan: 3)[#image("/recursos/logo-cuadrado.jpeg", width: 31mm)],
    table.cell(x: 1, y: 0)[#campo("DOCUMENTO", d.titulo, tam: 10pt)],
    table.cell(x: 2, y: 0)[#campo("CÓDIGO", d.codigo, tam: 10pt)],
    table.cell(x: 3, y: 0)[#campo("REVISIÓN", d.revision, tam: 10pt)],
    table.cell(x: 4, y: 0)[#campo("HOJA", context counter(page).display("1 / 1", both: true), tam: 9pt)],
    table.cell(x: 1, y: 1)[#campo("TIPO", d.tipo, tam: 9pt)],
    table.cell(x: 2, y: 1, colspan: 2)[#campo("CREACIÓN / ÚLT. REVISIÓN", [#d.creado / #d.revisado], tam: 8pt)],
    table.cell(x: 4, y: 1)[#campo("ESTADO", d.estado, tam: 9pt)],
    table.cell(x: 1, y: 2, colspan: 3)[#campo("ELABORACIÓN / REVISIÓN", elaboracion, tam: 9pt)],
    table.cell(x: 4, y: 2)[#campo("FIRMA / APROBACIÓN", d.aprobacion, tam: 8pt,
      extra: text(size: 5.8pt)[Resp.: #d.aprobador])],
  )
}

#let pie(d) = {
  let c = if commit-git == none { "sin commit (compilación local)" } else { "commit " + commit-git }
  text(size: 6.5pt, fill: luma(90))[
    #d.codigo · Rev. #d.revision · #d.estado · #c
    #h(1fr)
    PROYECTO ALIMOCHE
  ]
}

// ── Función principal ──────────────────────────────────────────────────────
#let documento(meta, cuerpo) = {
  let m = (proyecto: "PROYECTO ALIMOCHE") + meta
  validar(m)

  set document(title: m.titulo, author: m.autor, keywords: ("ALIMOCHE", m.codigo, m.tipo))
  set text(font: ("Arial", "Liberation Sans"), size: 9.2pt, lang: "es", fill: black)
  set par(justify: true, leading: .44em, spacing: .48em)
  set heading(numbering: "1.1")
  show heading.where(level: 1): set text(size: 11pt, weight: "bold")
  show heading.where(level: 2): set text(size: 9.5pt, weight: "bold")
  show heading: set block(above: 1.1em, below: .6em)
  set table(stroke: .45pt + black, inset: (x: 2mm, y: 1.3mm))
  show table.cell.where(y: 0): set text(weight: "bold")
  show table: set par(justify: false)
  show raw.where(block: true): set text(size: 7.6pt)
  set page(
    paper: "a4",
    margin: (left: 18mm, right: 18mm, top: 57mm, bottom: 21mm),
    footer: none,
    background: context {
      place(top + left, dx: 10mm, dy: 11mm, rect(width: 190mm, height: 275mm, stroke: borde))
      place(top + left, dx: 52mm, dy: 96mm, image("/recursos/logo-marca-agua-gris.png", width: 106mm))
      place(top + left, dx: 10mm, dy: 11mm, cabecera(m))
      place(top + left, dx: 13mm, dy: 281mm, box(width: 184mm, pie(m)))
    },
  )

  // Metadatos legibles por máquina (JSON):
  //   typst eval --root . 'query(<meta>).first().value' --in <archivo.typ>
  [#metadata(m + (commit: commit-git)) <meta>]

  align(center)[#text(size: 13pt, weight: "bold")[#m.codigo · #m.titulo]]
  v(2mm)
  cuerpo
}

// Recuadro de esquema (texto monoespaciado), usado en figuras de estructura.
#let esquema(contenido) = block(width: 100%, inset: 4mm, stroke: .5pt + black, fill: white)[
  #align(left)[#text(size: 8.1pt)[#raw(contenido, block: true)]]
]
