#!/usr/bin/env python3
"""Importa RASCUNHOS em PT-BR da revisao local para exerciseCatalog (DEV).

Nao altera `instructions`, `instructionsEnglish`, nomes ou imagens.
O CSV da RepDB e derivado/licenciado e NAO deve ser versionado no repositorio.
Requer uma conta de servico DEV somente com `--aplicar --confirmar-dev`.
"""
from __future__ import annotations

import argparse
import csv
import datetime as dt
import json
import os
from pathlib import Path
import sys

DEV_PROJECT = 'academia-grazi-dev-ab105'
DEFAULT_CSV = Path(r'C:\Projetos\_grazi_catalogo_nomes_v6\Grazi_Catalogo_698_Revisao_PTBR.csv')
COL_TEXT = 'orientacoes_ptbr_proposta_nao_validada'


def load_rows(csv_path: Path, limite: int) -> list[dict[str, str]]:
    if not csv_path.is_file():
        raise FileNotFoundError(f'CSV local nao encontrado: {csv_path}')
    with csv_path.open('r', encoding='utf-8-sig', newline='') as handle:
        reader = csv.DictReader(handle, delimiter=';')
        if not {'id', COL_TEXT, 'orientacoes_originais'}.issubset(reader.fieldnames or []):
            raise ValueError('CSV invalido: colunas de revisao ausentes.')
        result: list[dict[str, str]] = []
        seen: set[str] = set()
        for item in reader:
            rid = item['id'].strip()
            draft = (item[COL_TEXT] or '').strip()
            english = (item['orientacoes_originais'] or '').strip()
            if not rid.startswith('repdb-') or '/' in rid or not draft or not english:
                raise ValueError(f'Registro invalido: {rid}')
            if rid in seen:
                raise ValueError(f'ID repetido no CSV: {rid}')
            seen.add(rid)
            if draft == english:
                raise ValueError(f'Instrucao ainda em ingles, sem traducao: {rid}')
            result.append({'id': rid, 'pt': draft})
    return result[:limite] if limite > 0 else result


def run() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--csv', type=Path, default=DEFAULT_CSV)
    parser.add_argument('--limite', type=int, default=0)
    parser.add_argument('--simular', action='store_true')
    parser.add_argument('--aplicar', action='store_true')
    parser.add_argument('--confirmar-dev', action='store_true')
    args = parser.parse_args()
    if args.limite < 0 or args.simular == args.aplicar:
        parser.error('Escolha apenas --simular ou --aplicar; --limite nao pode ser negativo.')
    rows = load_rows(args.csv, args.limite)
    print(f'CSV validado: {len(rows)} exercicios. Nenhuma instrucao original sera alterada.')
    print('Traducao AUTOMATICA: requer validacao de um profissional de Educacao Fisica.')
    if args.simular:
        print('SIMULACAO CONCLUIDA: ZERO gravacoes no Firebase.')
        return
    if not args.confirmar_dev:
        parser.error('Para gravar, use --aplicar --confirmar-dev.')
    credential_path = Path(os.environ.get('GOOGLE_APPLICATION_CREDENTIALS', ''))
    if not credential_path.is_file():
        raise RuntimeError('Configure GOOGLE_APPLICATION_CREDENTIALS para o JSON DEV fora do Git.')
    key = json.loads(credential_path.read_text(encoding='utf-8'))
    if key.get('project_id') != DEV_PROJECT:
        raise RuntimeError('CREDENCIAL NAO E DO PROJETO DEV. Nenhuma gravacao.')
    import firebase_admin
    from firebase_admin import credentials, firestore

    app = firebase_admin.initialize_app(
        credentials.Certificate(str(credential_path)), {'projectId': DEV_PROJECT},
        name='grazi-traducoes-ptbr-v9',
    )
    db = firestore.client(app=app)
    updates: list[tuple[object, dict[str, str]]] = []
    backup: list[dict[str, object]] = []
    skipped = 0
    for row in rows:
        ref = db.collection('exerciseCatalog').document(row['id'])
        doc = ref.get()
        data = doc.to_dict() if doc.exists else None
        if not data or data.get('source') != 'repdb-free':
            raise RuntimeError(f'Documento ausente ou origem divergente: {row["id"]}. Nenhuma gravacao.')
        # Nao sobrescrever traducao ja estabelecida/revisada nem mudancas de outra fonte.
        if data.get('language') == 'pt-BR' or data.get('instructionsTranslationStatus') == 'reviewed':
            skipped += 1
            continue
        existing = str(data.get('instructionsPtBrDraft') or '').strip()
        if existing and existing != row['pt']:
            print(f'AVISO: rascunho diferente ja existe em {row["id"]}; ignorando.')
            skipped += 1
            continue
        if existing == row['pt']:
            skipped += 1
            continue
        backup.append({
            'id': row['id'],
            'hadField': 'instructionsPtBrDraft' in data,
            'instructionsPtBrDraft': data.get('instructionsPtBrDraft'),
            'instructionsTranslationStatus': data.get('instructionsTranslationStatus'),
            'instructionsDraftSource': data.get('instructionsDraftSource'),
        })
        updates.append((ref, {
            'instructionsPtBrDraft': row['pt'],
            'instructionsTranslationStatus': 'automatic_pending_review',
            'instructionsDraftSource': 'grazi-local-ptbr-v9',
        }))
    print(f'Projeto confirmado: {DEV_PROJECT} | a gravar: {len(updates)} | ignorados: {skipped}')
    if not updates:
        print('Nenhuma atualizacao necessaria.')
        return
    output = Path(r'C:\Projetos\_backups_grazi')
    output.mkdir(parents=True, exist_ok=True)
    ts = dt.datetime.now().strftime('%Y%m%d_%H%M%S')
    backup_file = output / f'grazi_orientacoes_ptbr_v9_antes_{ts}.json'
    backup_file.write_text(json.dumps({'project': DEV_PROJECT, 'records': backup},
                                      ensure_ascii=False, indent=2), encoding='utf-8')
    print(f'BACKUP ANTES DE ESCREVER: {backup_file}')
    for index in range(0, len(updates), 100):
        batch = db.batch()
        for ref, fields in updates[index:index + 100]:
            batch.update(ref, fields)
        batch.commit()
        print(f'Gravados {min(index + 100, len(updates))}/{len(updates)}')
    print('CONCLUIDO: textos PT-BR AUTOMATICOS de teste gravados no Firebase DEV.')
    print('Documentos publicados/sessoes e instrucoes originais nao foram modificados.')


if __name__ == '__main__':
    try:
        run()
    except Exception as exc:
        print(f'ERRO: {exc}', file=sys.stderr)
        sys.exit(1)
