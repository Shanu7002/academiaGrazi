"""Localiza os exercicios RepDB do Firebase DEV usando tradutor OFFLINE.

A base e as imagens nao sao distribuidas por este pacote: a leitura e a
atualizacao sao feitas diretamente entre o Firestore DEV e a maquina do dono.
Nenhuma chave fica no codigo. A traducao e automatica e exige revisao tecnica.
"""
from __future__ import annotations

import argparse
import csv
import json
import os
import re
import sys
import unicodedata
from pathlib import Path

PROJECT_ID = "academia-grazi-dev-ab105"
SOURCE = "repdb-free"

# Correcoes pontuais conferidas na simulacao. Nenhum termo tecnico deve
# ser aprovado automaticamente para uso com alunos reais.
NOMES_PREFERIDOS = {
    "90-90-hold": "Sustentacao 90/90 de quadril",
    "90-90-switch": "Alternancia 90/90 de quadril",
    "ab-wheel-rollout": "Abdominal com roda",
}

# Corrige expressoes reconhecidamente inadequadas da traducao literal.
# Nao tenta inventar instrucoes tecnicas que nao constem da fonte.
SUBSTITUICOES = [
    (r"\bSegure o n[uú]cleo forte\b", "Mantenha o abdômen contraído"),
    (r"\bmantenha o n[uú]cleo apertado\b", "mantenha o abdômen contraído"),
    (r"\bn[uú]cleo forte\b", "abdômen contraído"),
    (r"\bseu n[uú]cleo\b", "seu abdômen"),
    (r"\bcanela corra pelo seu corpo\b", "canela fique posicionada à frente do corpo"),
]


def ajustar_portugues(texto: str) -> str:
    resultado = texto.strip()
    for padrao, substituicao in SUBSTITUICOES:
        resultado = re.sub(padrao, substituicao, resultado, flags=re.IGNORECASE)
    return resultado


def seguro_para_excel(valor: str) -> str:
    # As fontes sao externas. Nao permitir formulas em planilhas abertas por humanos.
    if valor.startswith(("=", "+", "-", "@")):
        return "'" + valor
    return valor



def normalizar(text: str) -> str:
    text = unicodedata.normalize("NFKD", text)
    text = "".join(c for c in text if not unicodedata.combining(c))
    return re.sub(r"\s+", " ", text).strip().lower()


def credencial_dev() -> Path:
    path = os.environ.get("GOOGLE_APPLICATION_CREDENTIALS", "")
    if not path:
        raise RuntimeError("Defina GOOGLE_APPLICATION_CREDENTIALS no CMD antes de executar.")
    file = Path(path)
    if not file.is_file():
        raise RuntimeError("O arquivo GOOGLE_APPLICATION_CREDENTIALS nao existe.")
    try:
        data = json.loads(file.read_text(encoding="utf-8-sig"))
    except (ValueError, OSError) as error:
        raise RuntimeError("Nao foi possivel ler o JSON da credencial.") from error
    if data.get("project_id") != PROJECT_ID:
        raise RuntimeError("ABORTADO: a chave nao pertence ao Firebase DEV autorizado.")
    return file


def tradutor_offline():
    try:
        import argostranslate.package
        import argostranslate.translate
    except ImportError as error:
        raise RuntimeError(
            "Argos Translate ausente. Execute: py -3 -m pip install argostranslate firebase-admin"
        ) from error

    def encontrado():
        idiomas = argostranslate.translate.get_installed_languages()
        origem = next((x for x in idiomas if x.code == "en"), None)
        alvo = next((x for x in idiomas if x.code == "pb"), None)
        return origem.get_translation(alvo) if origem and alvo else None

    modelo = encontrado()
    if modelo is None:
        print("Instalando modelo English -> Portugues (Brasil) para uso offline (download inicial)...")
        argostranslate.package.update_package_index()
        pacotes = argostranslate.package.get_available_packages()
        pacote = next((x for x in pacotes if x.from_code == "en" and x.to_code == "pb"), None)
        if pacote is None:
            raise RuntimeError("Modelo en -> pb nao encontrado no indice Argos. Nada foi alterado.")
        argostranslate.package.install_from_path(pacote.download())
        modelo = encontrado()
    if modelo is None:
        raise RuntimeError("Nao foi possivel carregar o modelo en -> pb. Nada foi alterado.")
    return modelo


def fonte_inglesa(data: dict) -> tuple[str, str]:
    titulo = (data.get("nameEnglish") or data.get("name") or "").strip()
    instrucoes = (data.get("instructionsEnglish") or data.get("instructions") or "").strip()
    return titulo, instrucoes


def main() -> None:
    parser = argparse.ArgumentParser(description="Traducao offline para portugues dos 701 exercicios RepDB (Firebase DEV).")
    parser.add_argument("--apply", action="store_true", help="Grava no Firebase DEV depois da simulacao.")
    parser.add_argument("--confirmar-dev", action="store_true", help="Confirmacao de que as alteracoes sao no DEV.")
    parser.add_argument("--max", type=int, default=0, help="Limita a quantidade de registros para teste; 0 = todos.")
    parser.add_argument("--sem-relatorio", action="store_true", help="Nao gera CSV local com a previa para revisao.")
    parser.add_argument("--relatorio", default="", help="Caminho local alternativo para o relatorio CSV de revisao.")
    args = parser.parse_args()
    if args.apply and not args.confirmar_dev:
        raise RuntimeError("Para gravar, informe --apply --confirmar-dev.")
    if args.max < 0:
        raise RuntimeError("--max deve ser 0 ou um inteiro positivo.")
    key = credencial_dev()
    try:
        import firebase_admin
        from firebase_admin import credentials, firestore
    except ImportError as error:
        raise RuntimeError("Instale firebase-admin: py -3 -m pip install firebase-admin") from error

    app = firebase_admin.initialize_app(credentials.Certificate(str(key)), {"projectId": PROJECT_ID})
    try:
        db = firestore.client(app=app)
        from google.cloud.firestore_v1.base_query import FieldFilter
        docs = list(db.collection("exerciseCatalog").where(filter=FieldFilter("source", "==", SOURCE)).stream())
        docs.sort(key=lambda document: document.id)
        docs = [d for d in docs if d.id.startswith("repdb-")]
        if args.max:
            docs = docs[:args.max]
        if not docs:
            raise RuntimeError("Nenhum exercicio RepDB encontrado no Firestore DEV.")
        print(f"Projeto: {PROJECT_ID} | registros selecionados: {len(docs)}")
        print("Nenhuma foto sera alterada ou baixada. Atribuicao RepDB sera mantida.")
        modelo = tradutor_offline()

        from google.cloud.firestore_v1 import SERVER_TIMESTAMP
        gravados = 0
        ignorados = 0
        lote = db.batch()
        pendentes_no_lote = 0
        revisao = []
        for indice, doc in enumerate(docs, start=1):
            data = doc.to_dict() or {}
            # Uma traducao revisada ou manual nao pode ser sobrescrita.
            if data.get("translationStatus") == "reviewed" or (
                data.get("language") == "pt-BR" and data.get("translator") == "argos-en-pb"
            ):
                ignorados += 1
                continue
            titulo_en, orientacoes_en = fonte_inglesa(data)
            if not titulo_en:
                ignorados += 1
                continue
            titulo_atual = str(data.get("name") or "").strip()
            # Preserva nomes conhecidos ja traduzidos manualmente no importador inicial.
            manter_nome_atual = bool(titulo_atual and normalizar(titulo_atual) != normalizar(titulo_en))
            source_id = str(data.get("sourceId") or doc.id.removeprefix("repdb-")).strip()
            titulo_pt = NOMES_PREFERIDOS.get(source_id) or (
                titulo_atual if manter_nome_atual else ajustar_portugues(modelo.translate(titulo_en))
            )
            orientacoes_pt = "\n".join(
                ajustar_portugues(modelo.translate(linha)) if linha.strip() else ""
                for linha in orientacoes_en.splitlines()
            ).strip()
            if not titulo_pt:
                raise RuntimeError(f"Traducao vazia no registro {doc.id}; nenhum lote novo sera enviado.")
            campos = {
                "name": titulo_pt,
                "nameNormalized": normalizar(titulo_pt),
                "instructions": orientacoes_pt,
                "instructionsEnglish": orientacoes_en,
                "language": "pt-BR",
                "translator": "argos-en-pb",
                "translationStatus": "automatic_pending_review",
                "translatedAt": SERVER_TIMESTAMP,
            }
            revisao.append({
                "id": doc.id,
                "nome_original": titulo_en,
                "nome_portugues_automatico": titulo_pt,
                "orientacoes_originais": orientacoes_en,
                "orientacoes_portugues_automaticas": orientacoes_pt,
                "revisao": "PENDENTE - Educacao Fisica",
            })
            if indice <= 5:
                print(f"Exemplo {indice}: {titulo_en} -> {titulo_pt}")
                print(f"  Orientacao (amostra): {orientacoes_pt[:120] or '[sem instrucoes na fonte]'}")
            if args.apply:
                lote.update(doc.reference, campos)
                pendentes_no_lote += 1
                if pendentes_no_lote == 100:
                    lote.commit()
                    gravados += pendentes_no_lote
                    pendentes_no_lote = 0
                    lote = db.batch()
                    print(f"Atualizados: {gravados}")
        if not args.sem_relatorio:
            destino = Path(args.relatorio).expanduser() if args.relatorio else Path.home() / "grazi_catalogo_ptbr_revisao.csv"
            destino.parent.mkdir(parents=True, exist_ok=True)
            with destino.open("w", encoding="utf-8-sig", newline="") as arquivo:
                writer = csv.DictWriter(arquivo, fieldnames=[
                    "id", "nome_original", "nome_portugues_automatico",
                    "orientacoes_originais", "orientacoes_portugues_automaticas", "revisao",
                ], delimiter=";")
                writer.writeheader()
                writer.writerows([
                    {chave: seguro_para_excel(str(valor)) for chave, valor in item.items()}
                    for item in revisao
                ])
            print(f"RELATORIO DE REVISAO: {destino} ({len(revisao)} registros).")
        if args.apply and pendentes_no_lote:
            lote.commit()
            gravados += pendentes_no_lote
        if args.apply:
            print(f"CONCLUIDO: {gravados} exercicios traduzidos no Firebase DEV; {ignorados} ignorados.")
        else:
            print(f"SIMULACAO: {len(docs) - ignorados} traducoes prontas; ZERO gravacoes no Firebase.")
        print("ATENCAO: traducoes automaticas precisam de revisao por profissional de Educacao Fisica.")
    finally:
        firebase_admin.delete_app(app)


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        print(f"ERRO: {exc}", file=sys.stderr)
        sys.exit(1)
