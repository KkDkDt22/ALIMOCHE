#!/usr/bin/env python3
"""Comprobaciones del repositorio ALIMOCHE (las ejecuta la CI y se pueden lanzar a mano).

    python herramientas/alimoche_ci.py validar [--pdf compilados]
    python herramientas/alimoche_ci.py publicados --base origin/main
    python herramientas/alimoche_ci.py rama doc/ALM-01-corrige-tabla
    python herramientas/alimoche_ci.py codeowners --comprobar | --escribir
    python herramientas/alimoche_ci.py emitir doc/ALM-01/1.0 --actor usuario [--fecha AAAAMMDD]

Solo usa la biblioteca estándar de Python (3.11+), git y typst.
"""
from __future__ import annotations

import argparse
import datetime as dt
import hashlib
import json
import re
import subprocess
import sys
import tomllib
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
RE_CODIGO = re.compile(r"^[A-Z0-9]+(-[A-Z0-9]+)*$")
RE_REV = re.compile(r"^\d+\.\d+$")
RE_FECHA = re.compile(r"^\d{2}/\d{2}/\d{4}$")
ESTADOS = ("Borrador", "En revisión", "Aprobado", "Obsoleto")
CAMPOS = ("codigo", "titulo", "tipo", "revision", "estado", "creado", "revisado", "autor",
          "revisores", "aprobador", "aprobacion", "padre", "sigue-a", "dependencias")
PREFIJOS_RAMA = ("doc/", "gestion/", "emision/", "herramientas/", "plantillas/")
RE_RAMA_DOC = re.compile(r"^doc/([A-Z0-9]+(?:-[A-Z0-9]+)*)-([a-z0-9]+(?:-[a-z0-9]+)*)$")
RE_PUBLICADO = re.compile(r"^publicados/([A-Z0-9-]+)/\1_Rev-(\d+\.\d+)_(\d{8})\.(pdf|toml)$")
CABECERA_CODEOWNERS = "# GENERADO por herramientas/alimoche_ci.py codeowners --escribir. No editar a mano.\n"

errores: list[str] = []
avisos: list[str] = []


def error(msg: str) -> None:
    errores.append(msg)
    print(f"::error::{msg}" if _en_actions() else f"ERROR: {msg}")


def aviso(msg: str) -> None:
    avisos.append(msg)
    print(f"::warning::{msg}" if _en_actions() else f"AVISO: {msg}")


def _en_actions() -> bool:
    import os
    return os.environ.get("GITHUB_ACTIONS") == "true"


def sh(*args: str, cwd: Path = RAIZ, comprobar: bool = True) -> subprocess.CompletedProcess:
    r = subprocess.run(list(args), cwd=cwd, capture_output=True, text=True, encoding="utf-8")
    if comprobar and r.returncode:
        raise SystemExit(f"Falló {' '.join(args)}:\n{r.stderr}")
    return r


# ------------------------------------------------------------------ catálogo

def leer_meta(codigo: str, raiz: Path = RAIZ) -> tuple[dict, str]:
    fuente = f"documentos/{codigo}/{codigo}.typ"
    r = sh("typst", "eval", "--root", ".", "query(<meta>).first().value", "--in", fuente,
           cwd=raiz, comprobar=False)
    if r.returncode:
        primera = next((l for l in r.stderr.splitlines() if "error:" in l), r.stderr.strip()[:200])
        return {}, primera.strip()
    return json.loads(r.stdout), ""


def catalogo(raiz: Path = RAIZ) -> dict[str, dict]:
    docs = {}
    base = raiz / "documentos"
    for carpeta in sorted(p for p in base.iterdir() if p.is_dir()) if base.exists() else []:
        if not (carpeta / f"{carpeta.name}.typ").exists():
            error(f"{carpeta.name}: falta documentos/{carpeta.name}/{carpeta.name}.typ")
            continue
        meta, fallo = leer_meta(carpeta.name, raiz)
        docs[carpeta.name] = {"meta": meta, "error": fallo}
    return docs


def equipo(raiz: Path = RAIZ) -> list[dict]:
    f = raiz / "equipo.toml"
    if not f.exists():
        return []
    d = tomllib.loads(f.read_text(encoding="utf-8"))
    personas = []
    for clave in ("persona", "personas", "miembro", "miembros"):
        v = d.get(clave)
        if isinstance(v, list):
            personas += v
        elif isinstance(v, dict):
            personas += [{"github": k, **x} for k, x in v.items() if isinstance(x, dict)]
    for p in personas:
        roles = p.get("roles", p.get("rol", []))
        p["roles"] = [roles] if isinstance(roles, str) else list(roles)
        p["github"] = str(p.get("github", p.get("usuario", ""))).lstrip("@")
    return [p for p in personas if p.get("activo", True)]


def _norm(s: str) -> str:
    import unicodedata
    s = unicodedata.normalize("NFKD", s).encode("ascii", "ignore").decode()
    return " ".join(s.lower().replace("_", " ").split())


ROLES_LIDER = {"lider", "team leader", "team-leader", "teamleader", "jefe de equipo", "coordinador"}


def con_rol(personas: list[dict], rol: str) -> list[dict]:
    objetivo = {_norm(r) for r in (ROLES_LIDER if rol == "lider" else {rol})}
    return [p for p in personas if objetivo & {_norm(r) for r in p["roles"]}]


def resolver(personas: list[dict], ref: str) -> dict | None:
    if not ref:
        return None
    r = ref.lstrip("@").lower()
    for p in personas:
        if p["github"].lower() == r:
            return p
    for p in personas:
        if _norm(str(p.get("nombre", ""))) == _norm(ref):
            return p
    return None


# ------------------------------------------------------------------- órdenes

def cmd_validar(args) -> None:
    docs = catalogo()
    for c, d in docs.items():
        m = d["meta"]
        if d["error"]:
            error(f"{c}: no compila o su bloque meta no es válido → {d['error']}")
            continue
        for campo in CAMPOS:
            if campo not in m:
                error(f"{c}: falta el campo «{campo}» en meta")
        if m.get("codigo") != c:
            error(f"{c}: la carpeta y el meta no coinciden (meta.codigo = «{m.get('codigo')}»)")
        if not RE_CODIGO.match(c):
            error(f"{c}: código con formato no válido")
        if m.get("estado") not in ESTADOS:
            error(f"{c}: estado no admitido «{m.get('estado')}»")
        if not RE_REV.match(str(m.get("revision", ""))):
            error(f"{c}: revisión no válida «{m.get('revision')}»")
        for f in ("creado", "revisado"):
            if not RE_FECHA.match(str(m.get(f, ""))):
                error(f"{c}: «{f}» debe ser DD/MM/AAAA")
        if m.get("estado") == "Aprobado" and m.get("aprobacion") in ("", "Pendiente", None):
            error(f"{c}: Aprobado exige «aprobacion»")
        if m.get("padre") and m["padre"] not in docs:
            error(f"{c}: el padre {m['padre']} no existe")
        if m.get("sigue-a") and m["sigue-a"] not in docs:
            error(f"{c}: «sigue-a» apunta a {m['sigue-a']}, que no existe")
        for dep in m.get("dependencias", []) or []:
            if dep not in docs:
                aviso(f"{c}: depende de {dep}, que no existe en documentos/")
    # Ciclos de padres
    for inicio in docs:
        camino, c = [], inicio
        while c and c in docs and c not in camino:
            camino.append(c)
            c = docs[c]["meta"].get("padre", "")
        if c and c in camino and c == inicio:
            error(f"{inicio}: ciclo de padres {' → '.join(camino + [c])}")
    # Compilar
    if args.pdf:
        destino = RAIZ / args.pdf
        destino.mkdir(parents=True, exist_ok=True)
        sha = sh("git", "rev-parse", "--short=12", "HEAD", comprobar=False).stdout.strip()
        for c, d in docs.items():
            if d["error"]:
                continue
            extra = ["--input", f"git_commit={sha}"] if sha else []
            r = sh("typst", "compile", "--root", ".", *extra, f"documentos/{c}/{c}.typ",
                   str(destino / f"{c}.pdf"), comprobar=False)
            if r.returncode:
                error(f"{c}: no compila:\n{r.stderr.strip()}")
    print(f"{len(docs)} documento(s) revisados.")


def cmd_publicados(args) -> None:
    """Las emisiones son inmutables: en una propuesta solo se pueden AÑADIR archivos
    con el nombre de emisión, nunca modificar, renombrar ni borrar."""
    r = sh("git", "diff", "--name-status", "-M", f"{args.base}...HEAD",
           "--", "publicados/")
    for linea in r.stdout.splitlines():
        partes = linea.split("\t")
        estado, ruta = partes[0], partes[-1]
        if ruta == "publicados/README.md":
            continue
        if not estado.startswith("A"):
            error(f"publicados/ es inmutable: «{linea.strip()}» (solo se admiten emisiones nuevas)")
        elif not RE_PUBLICADO.match(ruta):
            error(f"Nombre de emisión no válido: {ruta} (esperado publicados/<código>/<código>_Rev-<r>_<AAAAMMDD>.pdf|toml)")
    pdfs = {m.group(0)[:-4] for l in r.stdout.splitlines()
            if (m := RE_PUBLICADO.match(l.split("\t")[-1])) and l.endswith(".pdf")}
    tomls = {m.group(0)[:-5] for l in r.stdout.splitlines()
             if (m := RE_PUBLICADO.match(l.split("\t")[-1])) and l.endswith(".toml")}
    for falta in pdfs ^ tomls:
        error(f"Cada emisión lleva PDF y manifiesto .toml: falta la pareja de {falta}")


def cmd_rama(args) -> None:
    nombre = args.nombre
    if nombre in ("main",):
        return
    if not nombre.startswith(PREFIJOS_RAMA):
        error(f"Rama «{nombre}»: use doc/<código>-<tema> (o {', '.join(PREFIJOS_RAMA[1:])}…)")
        return
    if nombre.startswith("doc/"):
        m = RE_RAMA_DOC.match(nombre)
        if not m:
            error(f"Rama «{nombre}»: formato doc/<CÓDIGO>-<tema-en-minúsculas>")
        elif not (RAIZ / "documentos" / m.group(1)).exists():
            aviso(f"Rama «{nombre}»: el documento {m.group(1)} aún no existe en esta versión")


def generar_codeowners(raiz: Path = RAIZ) -> str:
    personas = equipo(raiz)
    lideres = sorted({"@" + p["github"] for p in con_rol(personas, "lider") if p["github"]})
    aprobadores = sorted({"@" + p["github"] for p in con_rol(personas, "aprobador") if p["github"]})
    mantenedores = sorted({"@" + p["github"] for p in con_rol(personas, "mantenedor") if p["github"]})
    tecnicos = list(dict.fromkeys(lideres + mantenedores))
    if not lideres:
        error("equipo.toml no tiene ninguna persona con rol «team-leader»")
    lineas = [CABECERA_CODEOWNERS,
              "# Origen: equipo.toml + campo «aprobador» del meta de cada documento.",
              "# Cada documento lo aprueba su aprobador; los líderes figuran siempre como",
              "# alternativa (el autor de una propuesta no puede aprobarla).", "",
              "*                      " + " ".join(lideres), ""]
    for c, d in sorted(catalogo(raiz).items()):
        ref = d["meta"].get("aprobador", "") if d["meta"] else ""
        p = resolver(personas, ref)
        duenos = (["@" + p["github"]] if p and p["github"] else []) + lideres
        if ref and not p and ref not in ("Pendiente", "Pendiente de designar"):
            aviso(f"{c}: el aprobador «{ref}» no está en equipo.toml; quedan los líderes")
        lineas.append(f"/documentos/{c}/".ljust(23) + " " + " ".join(dict.fromkeys(duenos)))
    lineas += ["",
               "/publicados/            " + " ".join(dict.fromkeys(aprobadores + lideres)),
               "/plantillas/            " + " ".join(tecnicos),
               "/equipo.toml            " + " ".join(lideres),
               "/herramientas/          " + " ".join(tecnicos),
               "/.github/               " + " ".join(tecnicos), ""]
    return "\n".join(lineas)


def cmd_codeowners(args) -> None:
    destino = RAIZ / ".github" / "CODEOWNERS"
    nuevo = generar_codeowners()
    if args.escribir:
        destino.parent.mkdir(exist_ok=True)
        destino.write_text(nuevo, encoding="utf-8", newline="\n")
        print(f"Escrito {destino.relative_to(RAIZ)}")
    else:
        actual = destino.read_text(encoding="utf-8") if destino.exists() else ""
        if actual != nuevo:
            error("CODEOWNERS no está al día con equipo.toml y los aprobadores. Ejecute "
                  "«python herramientas/alimoche_ci.py codeowners --escribir» e inclúyalo en la propuesta.")


def cmd_emitir(args) -> None:
    """Prepara una emisión a partir de un tag doc/<código>/<rev>: comprueba que el
    documento está Aprobado en ese commit y que quien emite es su aprobador o un
    líder; genera el PDF y su manifiesto en publicados/."""
    m = re.match(r"^(?:refs/tags/)?doc/([A-Z0-9-]+)/(\d+\.\d+)$", args.tag)
    if not m:
        raise SystemExit(f"Tag no válido «{args.tag}»: use doc/<código>/<revisión>, p. ej. doc/ALM-01/1.0")
    codigo, rev = m.groups()
    meta, fallo = leer_meta(codigo)
    if fallo:
        raise SystemExit(f"{codigo}: no se puede leer el meta en el tag: {fallo}")
    if meta.get("revision") != rev:
        error(f"El tag indica Rev {rev} pero el documento dice {meta.get('revision')}")
    if meta.get("estado") != "Aprobado":
        error(f"{codigo} no está «Aprobado» en el commit del tag (estado: {meta.get('estado')})")
    if meta.get("aprobacion") in ("", "Pendiente", None):
        error(f"{codigo}: falta «aprobacion»")
    personas = equipo()
    aprobador = resolver(personas, meta.get("aprobador", ""))
    lideres = {p["github"].lower() for p in con_rol(personas, "lider")}
    actor = (args.actor or "").lower()
    if actor and not ((aprobador and aprobador["github"].lower() == actor) or actor in lideres):
        error(f"@{args.actor} no es el aprobador de {codigo} ni líder: la emisión no es válida")
    base = f"publicados/{codigo}/{codigo}_Rev-{rev}_"
    if list(RAIZ.glob(base + "*.pdf")):
        error(f"Ya existe una emisión de {codigo} Rev {rev}; las emisiones no se sobrescriben")
    if errores:
        raise SystemExit(1)
    fecha = args.fecha or dt.date.today().strftime("%Y%m%d")
    sha = sh("git", "rev-parse", "HEAD").stdout.strip()
    pdf = RAIZ / f"{base}{fecha}.pdf"
    pdf.parent.mkdir(parents=True, exist_ok=True)
    sh("typst", "compile", "--root", ".", "--input", f"git_commit={sha[:12]}",
       f"documentos/{codigo}/{codigo}.typ", str(pdf))
    huella = hashlib.sha256(pdf.read_bytes()).hexdigest()
    version_typst = sh("typst", "--version").stdout.strip()
    manifiesto = pdf.with_suffix(".toml")
    campos = {
        "codigo": codigo, "titulo": meta.get("titulo", ""), "revision": rev, "estado": meta["estado"],
        "aprobador": meta.get("aprobador", ""), "aprobacion": meta.get("aprobacion", ""),
        "fecha": fecha, "tag": f"doc/{codigo}/{rev}", "commit": sha, "emitido_por": args.actor or "",
        "sha256_pdf": huella, "typst": version_typst,
    }
    manifiesto.write_text("# Manifiesto de emisión (inmutable)\n" + "".join(
        f'{k} = "{str(v).replace(chr(92), chr(92) * 2).replace(chr(34), chr(92) + chr(34))}"\n'
        for k, v in campos.items()), encoding="utf-8", newline="\n")
    print(pdf.relative_to(RAIZ))
    print(manifiesto.relative_to(RAIZ))


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = p.add_subparsers(dest="orden", required=True)
    v = sub.add_parser("validar")
    v.add_argument("--pdf", help="carpeta donde dejar los PDF compilados (p. ej. compilados)")
    v.set_defaults(fn=cmd_validar)
    g = sub.add_parser("publicados")
    g.add_argument("--base", required=True)
    g.set_defaults(fn=cmd_publicados)
    r = sub.add_parser("rama")
    r.add_argument("nombre")
    r.set_defaults(fn=cmd_rama)
    c = sub.add_parser("codeowners")
    grupo = c.add_mutually_exclusive_group(required=True)
    grupo.add_argument("--escribir", action="store_true")
    grupo.add_argument("--comprobar", action="store_true")
    c.set_defaults(fn=cmd_codeowners)
    e = sub.add_parser("emitir")
    e.add_argument("tag")
    e.add_argument("--actor", default="")
    e.add_argument("--fecha", default="")
    e.set_defaults(fn=cmd_emitir)
    args = p.parse_args(argv)
    args.fn(args)
    if errores:
        print(f"\n{len(errores)} error(es), {len(avisos)} aviso(s).")
        return 1
    print(f"Correcto ({len(avisos)} aviso(s)).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
