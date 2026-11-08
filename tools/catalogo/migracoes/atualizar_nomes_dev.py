"""Academia Grazi — prévia e atualização controlada de nomes de exercícios.

Somente Firebase DEV. Não modifica orientações, imagens ou fichas de alunos.
Requer firebase-admin no ambiente virtual do usuário.
"""
from __future__ import annotations

import argparse
import csv
import json
import os
import re
import sys
import unicodedata
from collections import Counter
from datetime import datetime
from pathlib import Path
from typing import Any

PROJECT_ID = "academia-grazi-dev-ab105"
CSV_FILE = Path(__file__).resolve().parent / "Grazi_Catalogo_698_Revisao_PTBR.csv"
EXPECTED_TOTAL = 698
BACKUP_DIR = Path(r"C:\Projetos\_backups_grazi")
SOURCE = "repdb-free"
FIELDS_TO_RESTORE = (
    "name", "nameNormalized", "nameReviewStatus", "nameReviewSource", "nameReviewUpdatedAt"
)


def normalize(value: str) -> str:
    normalized = unicodedata.normalize("NFD", value.strip())
    normalized = "".join(ch for ch in normalized if not unicodedata.combining(ch))
    return " ".join(normalized.lower().split())


def parse_rows(csv_file: Path = CSV_FILE) -> list[dict[str, str]]:
    if not csv_file.is_file():
        raise ValueError(f"CSV nao encontrado: {csv_file}")
    with csv_file.open("r", encoding="utf-8-sig", newline="") as file:
        reader = csv.DictReader(file, delimiter=";")
        required = {"id", "nome_original", "nome_ptbr_proposto", "prioridade"}
        if not reader.fieldnames or not required.issubset(reader.fieldnames):
            raise ValueError(f"CSV sem colunas obrigatorias: {sorted(required)}")
        rows = list(reader)
    if len(rows) != EXPECTED_TOTAL:
        raise ValueError(f"Esperados {EXPECTED_TOTAL} registros; vieram {len(rows)}. Nada foi alterado.")
    ids = set()
    for index, row in enumerate(rows, start=2):
        doc_id = (row["id"] or "").strip()
        name = (row["nome_ptbr_proposto"] or "").strip()
        original = (row["nome_original"] or "").strip()
        level = (row["prioridade"] or "").strip()
        if not re.fullmatch(r"repdb-[a-z0-9][a-z0-9-]*", doc_id):
            raise ValueError(f"ID invalido na linha {index}: {doc_id!r}")
        if doc_id in ids:
            raise ValueError(f"ID duplicado na linha {index}: {doc_id}")
        if not original or not name or len(name) > 160:
            raise ValueError(f"Nome original/proposto invalido na linha {index}: {doc_id}")
        if level not in ("NORMAL", "ALTA", "CRÍTICA"):
            raise ValueError(f"Prioridade desconhecida na linha {index}: {level!r}")
        ids.add(doc_id)
    return rows


def validate_credential() -> Path:
    cred = os.environ.get("GOOGLE_APPLICATION_CREDENTIALS", "")
    if not cred:
        raise ValueError("Defina GOOGLE_APPLICATION_CREDENTIALS para C:\\Segredos\\firebase-grazi-dev.json")
    path = Path(cred)
    if not path.is_file():
        raise ValueError("Arquivo da credencial nao encontrado. Nao envie a chave no chat.")
    obj = json.loads(path.read_text(encoding="utf-8-sig"))
    if obj.get("project_id") != PROJECT_ID:
        raise ValueError("ABORTADO: credencial nao pertence ao Firebase DEV esperado.")
    return path


def load_firestore(cred_path: Path):
    try:
        import firebase_admin
        from firebase_admin import credentials, firestore
    except ImportError as exc:
        raise ValueError("Instale firebase-admin no venv grazi-tradutor.") from exc
    app = firebase_admin.initialize_app(
        credentials.Certificate(str(cred_path)), {"projectId": PROJECT_ID}
    )
    return app, firestore.client(app=app), firestore


def get_existing(db, rows: list[dict[str, str]]) -> dict[str, Any]:
    results: dict[str, Any] = {}
    ids = [r["id"] for r in rows]
    for offset in range(0, len(ids), 100):
        chunk = ids[offset:offset + 100]
        refs = [db.collection("exerciseCatalog").document(value) for value in chunk]
        for snap in db.get_all(refs):
            results[snap.id] = snap
    return results


def build_report(rows, snapshots):
    result = []
    for row in rows:
        doc_id = row["id"]
        snap = snapshots.get(doc_id)
        current = snap.to_dict() if snap is not None and snap.exists else None
        status = "pronto"
        if current is None:
            status = "ausente"
        elif current.get("source") != SOURCE:
            status = "fonte_incorreta"
        elif normalize(str(current.get("nameEnglish") or "")) != normalize(row["nome_original"]):
            status = "nome_original_diferente"
        elif current.get("translationStatus") == "reviewed" or current.get("nameReviewStatus") == "reviewed":
            status = "ja_revisado"
        elif current.get("language") == "pt-BR" and current.get("translator") == "argos-en-pb":
            status = "ja_traduzido"
        elif (str(current.get("name", "")).strip() == row["nome_ptbr_proposto"].strip()
              and current.get("nameReviewStatus") == "editorial_pending_review"):
            status = "ja_atualizado"
        result.append({
            "id": doc_id, "prioridade": row["prioridade"],
            "nome_atual": str(current.get("name", "")) if current else "",
            "nome_ptbr_proposto": row["nome_ptbr_proposto"],
            "status": status,
        })
    return result


def export_preview(rows) -> Path:
    destination = Path(__file__).resolve().parent / "auditoria_nomes_v6.csv"
    with destination.open("w", encoding="utf-8-sig", newline="") as fd:
        writer = csv.DictWriter(fd, fieldnames=["id", "prioridade", "nome_atual", "nome_ptbr_proposto", "status"], delimiter=";")
        writer.writeheader()
        writer.writerows(rows)
    return destination


def json_serializable(value):
    if isinstance(value, datetime):
        return {"_date_time_iso": value.isoformat()}
    raise TypeError(f"Valor JSON inesperado: {type(value).__name__}")


def save_backup(rows, snapshots) -> Path:
    BACKUP_DIR.mkdir(parents=True, exist_ok=True)
    stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    destination = BACKUP_DIR / f"grazi_nomes_antes_v6_{stamp}.json"
    snapshot_data = {}
    for item in rows:
        doc_id = item["id"]
        current = snapshots[doc_id].to_dict()
        snapshot_data[doc_id] = {
            k: {"existia": k in current, "valor": current.get(k)} for k in FIELDS_TO_RESTORE
        }
    content = {"projectId": PROJECT_ID, "collection": "exerciseCatalog", "before": snapshot_data}
    destination.write_text(json.dumps(content, ensure_ascii=False, indent=2, default=json_serializable), encoding="utf-8")
    return destination


def main() -> None:
    parser = argparse.ArgumentParser(description="Academia Grazi: revisar e aplicar nomes PT-BR somente no DEV")
    parser.add_argument("--validar-csv", action="store_true", help="Valida o CSV sem Firebase")
    parser.add_argument("--csv", type=Path, default=CSV_FILE, help="CSV privado fora do Git (licenca RepDB)")
    parser.add_argument("--simular", action="store_true", help="Verifica os registros reais sem gravar")
    parser.add_argument("--aplicar-normais", action="store_true", help="Atualiza apenas nomes NORMAL (nao revisados)")
    parser.add_argument("--confirmar-dev", action="store_true", help="Confirma explicitamente alteracoes no DEV")
    parser.add_argument("--max", type=int, default=0, help="Limitar registros NORMAL gravados (0 = todos)")
    args = parser.parse_args()
    if args.max < 0:
        parser.error("--max deve ser >= 0")
    if sum([args.validar_csv, args.simular, args.aplicar_normais]) != 1:
        parser.error("Escolha um: --validar-csv, --simular, --aplicar-normais")
    if args.aplicar_normais and not args.confirmar_dev:
        parser.error("Para gravar, inclua --confirmar-dev")
    rows = parse_rows(args.csv)
    print(f"CSV: {len(rows)} exercicios | {dict(Counter(r['prioridade'] for r in rows))}")
    print("Regra: apenas nomes; imagens, instrucoes, fichas e linguagem ficam intactas.")
    if args.validar_csv:
        print("CSV VALIDADO. ZERO alteracoes no Firebase.")
        return
    cred = validate_credential()
    app, db, firestore = load_firestore(cred)
    from google.cloud.firestore_v1 import SERVER_TIMESTAMP
    try:
        snapshots = get_existing(db, rows)
        audit = build_report(rows, snapshots)
        preview = export_preview(audit)
        counts = Counter(x["status"] for x in audit)
        print(f"Firebase DEV: {PROJECT_ID}")
        print(f"Auditoria: {dict(counts)}")
        print(f"Relatorio: {preview}")
        normal = [x for x in audit if x["prioridade"] == "NORMAL" and x["status"] == "pronto"]
        flagged = sum(x["prioridade"] != "NORMAL" for x in audit)
        print(f"Nomes normais disponiveis: {len(normal)} | alertas ALTA/CRITICA reservados: {flagged}")
        if args.simular:
            print("SIMULACAO CONCLUIDA. ZERO gravacoes no Firebase.")
            return
        blocked_normals = [x for x in audit if x["prioridade"] == "NORMAL" and x["status"] in ("ausente", "fonte_incorreta", "nome_original_diferente")]
        if blocked_normals:
            raise ValueError(f"ABORTADO: {len(blocked_normals)} registros NORMAL inconsistentes. Veja auditoria_nomes_v6.csv")
        if args.max:
            normal = normal[:args.max]
        if not normal:
            print("Nenhum nome NORMAL elegivel para atualizar.")
            return
        by_id = {r["id"]: r for r in rows}
        backup = save_backup(normal, snapshots)
        print(f"BACKUP ANTES DA GRAVACAO: {backup}")
        done = 0
        for offset in range(0, len(normal), 150):
            batch = db.batch()
            for item in normal[offset:offset + 150]:
                proposed = by_id[item["id"]]["nome_ptbr_proposto"].strip()
                ref = db.collection("exerciseCatalog").document(item["id"])
                batch.update(ref, {
                    "name": proposed,
                    "nameNormalized": normalize(proposed),
                    "nameReviewStatus": "editorial_pending_review",
                    "nameReviewSource": "Grazi_Catalogo_698_Revisao_PTBR.csv",
                    "nameReviewUpdatedAt": SERVER_TIMESTAMP,
                })
            batch.commit()
            done += min(150, len(normal) - offset)
            print(f"Nomes atualizados: {done}/{len(normal)}")
        print(f"CONCLUIDO: {done} nomes propostos aplicados no Firebase DEV.")
        print(f"PENDENTES: {flagged} exercicios ALTA/CRITICA requerem revisao antes de gravar.")
        print("IMPORTANTE: instrucao de execucao nao foi alterada nem aprovada.")
    finally:
        import firebase_admin
        firebase_admin.delete_app(app)


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        print(f"ERRO: {error}", file=sys.stderr)
        sys.exit(1)
