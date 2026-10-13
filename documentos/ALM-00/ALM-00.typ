// PROYECTO ALIMOCHE · esqueleto de documento nuevo.
// El gestor ALIMOCHE.exe lo copia a documentos/<CÓDIGO>/<CÓDIGO>.typ y rellena «meta».
// A mano: copie este archivo con ese nombre, complete «meta» y escriba el cuerpo.
// Crear el archivo con estado Borrador y cuerpo vacío es reservar el código (ALM-01).

#import "/plantillas/alimoche.typ": documento, esquema

#let meta = (
  codigo: "ALM-00",           // Código asignado; igual al nombre de archivo y carpeta.
  titulo: "Enunciado y bases de diseño",
  tipo: "Informe técnico",
  revision: "0.1",
  estado: "En revisión",          // Borrador | En revisión | Aprobado | Obsoleto
  creado: "13/10/2026",
  revisado: "13/10/2026",
  autor: "Augusto Aizpún",    // Igual que en equipo.toml.
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


HOLA MUNDO PRUEBA





= Salidas
