#!/usr/bin/env python3
"""Configura en GitHub las reglas que hacen cumplir el flujo documental.

Lo ejecuta UNA persona administradora de la organización, con GitHub CLI (`gh`)
autenticado (`gh auth login`, permisos admin:org y repo):

    python herramientas/configurar_github.py --org ORGANIZACION --repo ALIMOCHE --simular
    python herramientas/configurar_github.py --org ORGANIZACION --repo ALIMOCHE

Qué hace (idempotente, se puede repetir tras cambiar equipo.toml):
  1. Equipos de la organización a partir de equipo.toml:
       alimoche              todas las personas activas  → permiso «write» en el repo
       alimoche-aprobadores  aprobador o team-leader     → pueden crear tags doc/**
       alimoche-lideres      team-leader o mantenedor    → permiso «maintain» en el repo
  2. Regla «main protegida»: sin push directo ni forzado, propuesta (PR) obligatoria
     con 1 aprobación, revisión de CODEOWNERS, aprobación tras el último push y la
     comprobación «validar» en verde.
  3. Reglas de tags doc/**: solo alimoche-aprobadores los crea; nadie los mueve ni borra.

Las invitaciones a la organización NO se envían desde aquí: las personas deben
aceptar la invitación del admin (web o panel de Gestión del gestor) antes de
poder añadirse a los equipos. Las que aún no son miembros se listan al final.
"""
from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import alimoche_ci as ci  # noqa: E402

SIMULAR = False


def gh(metodo: str, ruta: str, datos: dict | None = None, permitir: tuple[int, ...] = ()) -> dict | list | None:
    if SIMULAR and metodo != "GET":
        print(f"  [simulado] {metodo} {ruta} {json.dumps(datos, ensure_ascii=False) if datos else ''}")
        return {}
    args = ["gh", "api", "-X", metodo, ruta, "-H", "Accept: application/vnd.github+json"]
    if datos is not None:
        args += ["--input", "-"]
    r = subprocess.run(args, input=json.dumps(datos) if datos is not None else None,
                       capture_output=True, text=True, encoding="utf-8")
    if r.returncode:
        for codigo in permitir:
            if f"HTTP {codigo}" in r.stderr:
                return None
        raise SystemExit(f"Falló gh api {metodo} {ruta}:\n{r.stderr.strip()}")
    return json.loads(r.stdout) if r.stdout.strip() else None


def asegurar_equipo(org: str, slug: str, nombre: str, descripcion: str) -> int | None:
    t = gh("GET", f"/orgs/{org}/teams/{slug}", permitir=(404,))
    if t is None:
        print(f"· Creando equipo {slug}")
        t = gh("POST", f"/orgs/{org}/teams", {"name": nombre, "description": descripcion, "privacy": "closed"})
    return (t or {}).get("id")


def sincronizar_miembros(org: str, slug: str, logins: set[str], miembros_org: set[str]) -> list[str]:
    pendientes = []
    actuales = {m["login"].lower() for m in (gh("GET", f"/orgs/{org}/teams/{slug}/members?per_page=100", permitir=(404,)) or [])}
    for login in sorted(logins):
        if login.lower() not in miembros_org:
            pendientes.append(login)
            continue
        if login.lower() not in actuales:
            print(f"  + @{login} → {slug}")
            gh("PUT", f"/orgs/{org}/teams/{slug}/memberships/{login}", {"role": "member"})
    for login in sorted(actuales - {l.lower() for l in logins}):
        print(f"  - @{login} sale de {slug}")
        gh("DELETE", f"/orgs/{org}/teams/{slug}/memberships/{login}")
    return pendientes


def regla(org: str, repo: str, cuerpo: dict) -> None:
    existentes = gh("GET", f"/repos/{org}/{repo}/rulesets?per_page=100") or []
    previa = next((r for r in existentes if r.get("name") == cuerpo["name"]), None)
    if previa:
        print(f"· Actualizando regla «{cuerpo['name']}»")
        gh("PUT", f"/repos/{org}/{repo}/rulesets/{previa['id']}", cuerpo)
    else:
        print(f"· Creando regla «{cuerpo['name']}»")
        gh("POST", f"/repos/{org}/{repo}/rulesets", cuerpo)


def main() -> int:
    global SIMULAR
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--org", required=True)
    p.add_argument("--repo", default="ALIMOCHE")
    p.add_argument("--simular", action="store_true", help="muestra los cambios sin aplicarlos")
    a = p.parse_args()
    SIMULAR = a.simular

    personas = ci.equipo()
    todos = {x["github"] for x in personas if x["github"]}
    aprobadores = {x["github"] for x in ci.con_rol(personas, "aprobador") + ci.con_rol(personas, "lider")}
    lideres = {x["github"] for x in ci.con_rol(personas, "lider") + ci.con_rol(personas, "mantenedor")}
    if not lideres:
        raise SystemExit("equipo.toml no tiene ningún team-leader.")
    miembros_org = {m["login"].lower() for m in (gh("GET", f"/orgs/{a.org}/members?per_page=100") or [])}

    equipos = [("alimoche", "ALIMOCHE", "Personas que editan el repositorio documental", todos, "push"),
               ("alimoche-aprobadores", "ALIMOCHE aprobadores", "Pueden emitir (tags doc/**)", aprobadores, None),
               ("alimoche-lideres", "ALIMOCHE lideres", "Gestión del equipo y del repositorio", lideres, "maintain")]
    ids, pendientes = {}, set()
    for slug, nombre, desc, logins, permiso in equipos:
        ids[slug] = asegurar_equipo(a.org, slug, nombre, desc)
        pendientes |= set(sincronizar_miembros(a.org, slug, logins, miembros_org))
        if permiso:
            gh("PUT", f"/orgs/{a.org}/teams/{slug}/repos/{a.org}/{a.repo}", {"permission": permiso})

    regla(a.org, a.repo, {
        "name": "main protegida", "target": "branch", "enforcement": "active",
        "conditions": {"ref_name": {"include": ["~DEFAULT_BRANCH"], "exclude": []}},
        "rules": [
            {"type": "deletion"},
            {"type": "non_fast_forward"},
            {"type": "pull_request", "parameters": {
                "required_approving_review_count": 1, "dismiss_stale_reviews_on_push": True,
                "require_code_owner_review": True, "require_last_push_approval": True,
                "required_review_thread_resolution": False, "allowed_merge_methods": ["merge"]}},
            {"type": "required_status_checks", "parameters": {
                "strict_required_status_checks_policy": False,
                "required_status_checks": [{"context": "validar"}]}},
        ],
        "bypass_actors": [],
    })
    aprob_id = ids.get("alimoche-aprobadores")
    regla(a.org, a.repo, {
        "name": "tags doc: solo aprobadores", "target": "tag", "enforcement": "active",
        "conditions": {"ref_name": {"include": ["refs/tags/doc/**"], "exclude": []}},
        "rules": [{"type": "creation"}],
        "bypass_actors": [{"actor_id": aprob_id, "actor_type": "Team", "bypass_mode": "always"}] if aprob_id else [],
    })
    regla(a.org, a.repo, {
        "name": "tags doc: inmutables", "target": "tag", "enforcement": "active",
        "conditions": {"ref_name": {"include": ["refs/tags/doc/**"], "exclude": []}},
        "rules": [{"type": "update"}, {"type": "deletion"}],
        "bypass_actors": [],
    })
    if pendientes:
        print("\nAún no son miembros de la organización (invítelos y repita):",
              ", ".join("@" + x for x in sorted(pendientes)))
    print("\nListo." + (" (simulación: no se ha cambiado nada)" if SIMULAR else ""))
    return 0


if __name__ == "__main__":
    sys.exit(main())
