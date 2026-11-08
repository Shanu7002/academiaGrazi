#!/usr/bin/env python3
"""Conferencia SOMENTE LEITURA das orientacoes dos exercicios da RepDB no DEV.

Nao atualiza documentos; informa quantos possuem texto PT-BR e os pendentes.
Nunca imprime credenciais nem escreve o conjunto de dados da RepDB.
"""
from __future__ import annotations

import argparse
import csv
import json
import os
from pathlib import Path
import re
import sys

DEV_PROJECT = 'academia-grazi-dev-ab105'
DEFAULT_REPORT = Path(r'C:\Projetos\GRAZI_STATUS_ORIENTACOES_DEV.csv')
_ENGLISH = re.compile(r'\b(the|your|you|with|while|through|until|then|stand|hold|keep|lower|raise|bend|pull|push|feet|hands)\b', re.I)


def parece_ingles(texto: str) -> bool:
    return len(_ENGLISH.findall(texto)) >= 2


def classificar(data: dict) -> tuple[str, str]:
    oficial = str(data.get('instructions') or '').strip()
    rascunho = str(data.get('instructionsPtBrDraft') or '').strip()
    if data.get('language') == 'pt-BR' and oficial and not parece_ingles(oficial):
        return ('ptbr_na_biblioteca', str(data.get('translationStatus') or ''))
    if rascunho and not parece_ingles(rascunho):
        return ('ptbr_automatico_pendente_revisao', str(data.get('instructionsTranslationStatus') or ''))
    return ('sem_orientacao_ptbr', '')


def run() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--relatorio', type=Path, default=DEFAULT_REPORT)
    args = parser.parse_args()
    cred = Path(os.environ.get('GOOGLE_APPLICATION_CREDENTIALS') or '')
    if not cred.is_file():
        parser.error('Configure GOOGLE_APPLICATION_CREDENTIALS com o JSON DEV.')
    metadata = json.loads(cred.read_text(encoding='utf-8'))
    if metadata.get('project_id') != DEV_PROJECT:
        parser.error('O JSON nao pertence ao Firebase DEV. Nenhuma consulta iniciada.')
    import firebase_admin
    from firebase_admin import credentials, firestore
    from google.cloud.firestore_v1.base_query import FieldFilter

    app = firebase_admin.initialize_app(
        credentials.Certificate(str(cred)), {'projectId': DEV_PROJECT},
        name='grazi-orientacoes-dev-somente-leitura',
    )
    db = firestore.client(app=app)
    docs = db.collection('exerciseCatalog').where(
        filter=FieldFilter('source', '==', 'repdb-free'),
    ).stream()
    counts: dict[str, int] = {}
    items = []
    for doc in docs:
        data = doc.to_dict() or {}
        status, review = classificar(data)
        counts[status] = counts.get(status, 0) + 1
        items.append({'id': doc.id, 'status': status, 'revisao': review})
    items.sort(key=lambda row: row['id'])
    if not items:
        print('ERRO: nenhum exercicio RepDB encontrado no projeto DEV.')
        return 1
    args.relatorio.parent.mkdir(parents=True, exist_ok=True)
    with args.relatorio.open('w', encoding='utf-8-sig', newline='') as handle:
        writer = csv.DictWriter(handle, fieldnames=['id', 'status', 'revisao'], delimiter=';')
        writer.writeheader()
        writer.writerows(items)
    total = len(items)
    translated = total - counts.get('sem_orientacao_ptbr', 0)
    print(f'Firebase DEV: {DEV_PROJECT}')
    print(f'Total de exercicios RepDB: {total}')
    print(f'Com orientacao PT-BR disponivel: {translated}/{total}')
    print(f'Revisao tecnica pendente: {counts.get("ptbr_automatico_pendente_revisao", 0)} rascunhos')
    print(f'Em falta: {counts.get("sem_orientacao_ptbr", 0)}')
    print(f'Relatorio de IDs/status: {args.relatorio}')
    print('SOMENTE LEITURA. NENHUMA GRAVACAO NO FIREBASE.')
    return 0 if translated == total == 701 else 2


if __name__ == '__main__':
    try:
        sys.exit(run())
    except Exception as exc:
        print(f'ERRO: {exc}', file=sys.stderr)
        sys.exit(1)
