// PROYECTO ALIMOCHE · esqueleto de documento nuevo.
// El gestor ALIMOCHE.exe lo copia a documentos/<CÓDIGO>/<CÓDIGO>.typ y rellena «meta».
// A mano: copie este archivo con ese nombre, complete «meta» y escriba el cuerpo.
// Crear el archivo con estado Borrador y cuerpo vacío es reservar el código (ALM-01).

#import "/plantillas/alimoche.typ": documento, esquema

#let meta = (
  codigo: "ALM-XXX",           // Código asignado; igual al nombre de archivo y carpeta.
  titulo: "Título del documento",
  tipo: "Tipo documental",
  revision: "0.1",
  estado: "Borrador",          // Borrador | En revisión | Aprobado | Obsoleto
  creado: "DD/MM/AAAA",
  revisado: "DD/MM/AAAA",
  autor: "Nombre Apellido",    // Igual que en equipo.toml.
  revisores: (),               // ("Nombre Apellido",) — coma final con un solo nombre.
  aprobador: "Pendiente de designar",
  aprobacion: "Pendiente",
  padre: none,                 // "ALM-P00" si es auxiliar de P00; none si es independiente.
  sigue-a: none,               // "ALM-P00" si continúa la secuencia de P00; si no, none.
  dependencias: (),            // ("ALM-P00",) si usa salidas de P00.
)

#show: documento.with(meta)

= Objeto

= Entradas

= Desarrollo

= Salidas
