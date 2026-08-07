#!/usr/bin/env python3
"""
Genera JSON con análisis para bq-acts-1-9.

Este script lee:
  - source.txt  (texto plano con versículos numerados y títulos de sección)
  - Acts_1_9_Chapter_Analysis.md  (análisis por capítulo con versículos referenciados)

Y genera:
  - content/index.json
  - content/sections.json
  - content/chapters/NNN.json (con campo "analysis" y marcadores de sección en text)

Uso:
  python generate_analysis.py
"""

import json
import re
import unicodedata
from pathlib import Path
from typing import Dict, List, Tuple

# Rutas base
BASE_DIR = Path(__file__).parent / "content" / "bq-acts-1-9"
SOURCE_FILE = BASE_DIR / "source.txt"
ANALYSIS_FILE = BASE_DIR / "Acts_1_9_Chapter_Analysis.md"
OUTPUT_DIR = BASE_DIR / "content"

# Configuración del paquete
PACKAGE_ID = "bq-acts-1-9"
ABBREVIATION = "Acts"
ATTRIBUTION = "KING JAMES VERSION"


def slug(title: str) -> str:
    """Convierte un título a un slug válido para section IDs."""
    # Remover acentos
    normalized = unicodedata.normalize('NFD', title)
    without_accents = ''.join(c for c in normalized if unicodedata.category(c) != 'Mn')

    # Convertir a minúsculas y reemplazar caracteres especiales
    s = without_accents.lower()
    s = re.sub(r'[^a-z0-9]+', '-', s)
    s = s.strip('-')
    return s


def parse_source(file_path: Path) -> Tuple[Dict[int, Dict[int, str]], List[Dict]]:
    """
    Parsea source.txt y extrae texto por versículo, incluyendo marcadores de sección.

    Returns:
        Tuple de:
        - Dict[chapter][verse_number] = verse_text (con marcadores [[section:...]] si aplica)
        - List de secciones encontradas
    """
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    verses = {}
    sections = []
    current_chapter = None
    pending_title = None
    prev_blank = True

    lines = content.split('\n')

    for line in lines:
        line = line.strip()

        # Línea vacía
        if not line:
            prev_blank = True
            continue

        # Detectar cambio de capítulo
        chapter_match = re.match(r'^CHAPTER\s+(\d+)$', line, re.IGNORECASE)
        if chapter_match:
            current_chapter = int(chapter_match.group(1))
            verses[current_chapter] = {}
            prev_blank = False
            continue

        if current_chapter is None:
            continue

        # Detectar si es un número de versículo
        verse_match = re.match(r'^(\d+)\s+(.+)$', line)

        if verse_match:
            # Es un versículo
            verse_num = int(verse_match.group(1))
            verse_text = verse_match.group(2).strip()

            # Procesar títulos inline {{Title}} -> [[section:id|Title]]
            inline_titles = re.findall(r'\{\{(.+?)\}\}', verse_text)
            for inline_title in inline_titles:
                section_id = slug(inline_title)
                marker = f"[[section:{section_id}|{inline_title}]]"
                verse_text = verse_text.replace(f"{{{{{inline_title}}}}}", marker)
                
                # Registrar sección inline
                sections.append({
                    "sectionId": section_id,
                    "title": inline_title,
                    "startChapter": current_chapter,
                    "startVerse": verse_num,
                })

            # Si hay un título pendiente, insertar marcador al inicio
            if pending_title is not None:
                section_id = slug(pending_title)
                marker = f"[[section:{section_id}|{pending_title}]]"
                verse_text = f"{marker} {verse_text}"

                # Registrar sección
                sections.append({
                    "sectionId": section_id,
                    "title": pending_title,
                    "startChapter": current_chapter,
                    "startVerse": verse_num,
                })

                pending_title = None

            verses[current_chapter][verse_num] = verse_text
            prev_blank = False

        elif prev_blank and not line.startswith('CHAPTER'):
            # Es un título de sección (línea después de línea en blanco, sin número)
            pending_title = line
            prev_blank = False

    return verses, sections


def parse_analysis(file_path: Path) -> Dict[int, Dict]:
    """
    Parsea el markdown de análisis y extrae información por capítulo y versículo.

    Returns:
        Dict[chapter] = {
            'individuals': {verse_num: [names]},
            'deity': {verse_num: [names]},
            'locations': {verse_num: [locations]},
            'otReferences': {verse_num: [references]},
            'parenthetical': {verse_num: text},
            'questions': {verse_num: [questions]},
            'exclamations': {verse_num: [exclamations]}
        }
    """
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    chapters = {}
    current_chapter = None
    current_section = None

    lines = content.split('\n')

    for line in lines:
        line_stripped = line.strip()

        # Detectar capítulo
        chapter_match = re.match(r'^## Chapter Analysis \| Chapter (\d+)$', line_stripped)
        if chapter_match:
            current_chapter = int(chapter_match.group(1))
            chapters[current_chapter] = {
                'individuals': {},
                'deity': {},
                'locations': {},
                'otReferences': {},
                'parenthetical': {},
                'questions': {},
                'exclamations': {}
            }
            current_section = None
            continue

        if current_chapter is None:
            continue

        # Detectar secciones (solo headers exactos)
        if re.match(r'^\*\s+\*\*Individuals:\*\*\s*\d*$', line_stripped):
            current_section = 'individuals'
            continue
        elif re.match(r'^\*\s+\*\*Deity / Divine Persons:\*\*\s*\d*$', line_stripped):
            current_section = 'deity'
            continue
        elif re.match(r'^\*\s+\*\*Geographical Locations:\*\*\s*\d*$', line_stripped):
            current_section = 'locations'
            continue
        elif re.match(r'^\*\s+\*\*Old Testament Scriptures:\*\*\s*\d*$', line_stripped):
            current_section = 'otReferences'
            continue
        elif re.match(r'^\*\s+\*\*Parenthetical Statements:\*\*\s*\d*$', line_stripped):
            current_section = 'parenthetical'
            continue
        elif re.match(r'^\*\s+\*\*Questions:\*\*\s*\d*$', line_stripped):
            current_section = 'questions'
            continue
        elif re.match(r'^\*\s+\*\*Exclamations:\*\*\s*\d*$', line_stripped):
            current_section = 'exclamations'
            continue
        elif line_stripped == '---':
            current_section = None
            continue

        # Parsear entradas según sección actual
        if current_section and current_chapter:
            parse_entry(line_stripped, current_section, chapters[current_chapter])

    return chapters


def parse_entry(line: str, section: str, chapter_data: Dict):
    """Parsea una entrada específica del análisis."""
    line = line.lstrip()

    if not line.startswith('*'):
        return

    if section == 'parenthetical':
        # Formato: * 1:15 `(texto)`
        match = re.match(r'^\*\s+(\d+:\d+)\s+`(.+?)`$', line)
        if match:
            verse_ref = match.group(1)
            text = match.group(2)
            verse_num = int(verse_ref.split(':')[1])
            if verse_num not in chapter_data[section]:
                chapter_data[section][verse_num] = []
            chapter_data[section][verse_num].append(text)

    elif section in ('otReferences', 'questions', 'exclamations'):
        # Formato: * 1:20 `texto`  o  * 1:6 `texto?`
        match = re.match(r'^\*\s+(\d+:\d+(?:[–-]\d+:\d+)?)\s+`(.+?)`$', line)
        if match:
            verse_ref = match.group(1)
            text = match.group(2)

            # Manejar rangos como 2:17–2:21
            if '–' in verse_ref or '-' in verse_ref:
                parts = re.split(r'[–-]', verse_ref)
                start_ref = parts[0]
                verse_num = int(start_ref.split(':')[1])
            else:
                verse_num = int(verse_ref.split(':')[1])

            if verse_num not in chapter_data[section]:
                chapter_data[section][verse_num] = []
            chapter_data[section][verse_num].append(text)

    elif section in ('individuals', 'deity', 'locations'):
        # Formato: * **Name** (1:1, 1:5)
        match = re.match(r'^\*\s+\*\*([^*]+)\*\*\s+\(([^)]+)\)$', line)
        if match:
            name = match.group(1).strip()
            refs = match.group(2)

            for ref in refs.split(','):
                ref = ref.strip()
                if ':' in ref:
                    verse_num = int(ref.split(':')[1])
                else:
                    verse_num = int(ref)

                if verse_num not in chapter_data[section]:
                    chapter_data[section][verse_num] = []
                if name not in chapter_data[section][verse_num]:
                    chapter_data[section][verse_num].append(name)

        # Para locations (con asteriscos en markdown)
        match = re.match(r'^\*\s+\*([^*]+)\*\s+\(([^)]+)\)$', line)
        if match:
            location = match.group(1).strip()
            refs = match.group(2)

            for ref in refs.split(','):
                ref = ref.strip()
                if ':' in ref:
                    verse_num = int(ref.split(':')[1])
                else:
                    verse_num = int(ref)

                if verse_num not in chapter_data['locations']:
                    chapter_data['locations'][verse_num] = []
                if location not in chapter_data['locations'][verse_num]:
                    chapter_data['locations'][verse_num].append(location)


def build_sections_from_verses(
    verses: Dict[int, Dict[int, str]],
    found_sections: List[Dict]
) -> List[Dict]:
    """Construye las secciones basado en los marcadores encontrados en los versículos."""

    # Agrupar por capítulo y ordenar
    sections_by_chapter = {}
    for section in found_sections:
        ch = section['startChapter']
        if ch not in sections_by_chapter:
            sections_by_chapter[ch] = []
        sections_by_chapter[ch].append(section)

    result = []

    for ch, ch_sections in sections_by_chapter.items():
        ch_sections.sort(key=lambda s: s['startVerse'])

        for i, section in enumerate(ch_sections):
            start_verse = section['startVerse']

            # El final es el inicio de la siguiente sección - 1, o el último versículo
            if i + 1 < len(ch_sections):
                end_verse = ch_sections[i + 1]['startVerse'] - 1
            else:
                end_verse = max(verses.get(ch, {}).keys()) if ch in verses else start_verse

            # Generar verseRefs
            verse_refs = []
            if ch in verses:
                for v in range(start_verse, end_verse + 1):
                    if v in verses[ch]:
                        verse_refs.append(f"{ABBREVIATION} {ch}:{v}")

            if verse_refs:
                result.append({
                    "sectionId": section['sectionId'],
                    "title": section['title'],
                    "startVerseRef": verse_refs[0],
                    "endVerseRef": verse_refs[-1],
                    "verseRefs": verse_refs,
                })

    return result


def build_chapter_analysis(chapter: int, verse_count: int, analysis: Dict) -> Dict:
    """Construye el resumen de análisis para un capítulo."""

    # Extraer nombres únicos de individuos
    individuals_set = set()
    for verse_names in analysis.get('individuals', {}).values():
        individuals_set.update(verse_names)

    # Extraer nombres únicos de deidad
    deity_set = set()
    for verse_names in analysis.get('deity', {}).values():
        deity_set.update(verse_names)

    # Extraer ubicaciones únicas
    locations_set = set()
    for verse_locs in analysis.get('locations', {}).values():
        locations_set.update(verse_locs)

    # Contar referencias del AT
    ot_count = sum(len(refs) for refs in analysis.get('otReferences', {}).values())

    # Contar preguntas
    questions_count = sum(len(qs) for qs in analysis.get('questions', {}).values())

    # Contar exclamaciones
    exclamations_count = sum(len(excl) for excl in analysis.get('exclamations', {}).values())

    # Contar declaraciones paréntesis
    parenthetical_count = sum(len(paren) for paren in analysis.get('parenthetical', {}).values())

    return {
        "chapterNumber": chapter,
        "verseCount": verse_count,
        "summary": {
            "individuals": {
                "count": len(individuals_set),
                "names": sorted(list(individuals_set))
            },
            "deity": {
                "count": len(deity_set),
                "names": sorted(list(deity_set))
            },
            "locations": {
                "count": len(locations_set),
                "names": sorted(list(locations_set))
            },
            "otReferences": ot_count,
            "questions": questions_count,
            "exclamations": exclamations_count,
            "parenthetical": parenthetical_count
        }
    }


def build_chapter_json(chapter: int, verses: Dict[int, str], analysis: Dict) -> Dict:
    """Construye el JSON para un capítulo completo."""

    verse_list = []
    for verse_num in sorted(verses.keys()):
        verse_text = verses[verse_num]

        # Construir análisis para este versículo
        verse_analysis = {
            "individuals": analysis.get('individuals', {}).get(verse_num, []),
            "deity": analysis.get('deity', {}).get(verse_num, []),
            "locations": analysis.get('locations', {}).get(verse_num, []),
            "otReferences": analysis.get('otReferences', {}).get(verse_num, []),
            "parenthetical": analysis.get('parenthetical', {}).get(verse_num, []),
            "questions": analysis.get('questions', {}).get(verse_num, []),
            "exclamations": analysis.get('exclamations', {}).get(verse_num, [])
        }

        verse_list.append({
            "verseRef": f"{ABBREVIATION} {chapter}:{verse_num}",
            "verseNumber": verse_num,
            "text": verse_text,  # Ya incluye marcadores de sección si aplica
            "analysis": verse_analysis
        })

    return {
        "chapterNumber": chapter,
        "verses": verse_list
    }


def main():
    """Función principal."""
    print("Generando JSON con análisis para bq-acts-1-9...")

    # Verificar que existen los archivos de entrada
    if not SOURCE_FILE.exists():
        print(f"❌ No se encontró: {SOURCE_FILE}")
        return 1

    if not ANALYSIS_FILE.exists():
        print(f"❌ No se encontró: {ANALYSIS_FILE}")
        return 1

    # Parsear archivos
    print("   Parseando source.txt...")
    scripture_data, found_sections = parse_source(SOURCE_FILE)

    print("   Parseando análisis...")
    analysis_data = parse_analysis(ANALYSIS_FILE)

    # Crear directorio de salida
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    chapters_dir = OUTPUT_DIR / "chapters"
    chapters_dir.mkdir(exist_ok=True)

    # Generar JSON por capítulo
    verse_counts = {}

    for chapter_num in sorted(scripture_data.keys()):
        print(f"   Generando capítulo {chapter_num}...")

        chapter_analysis = analysis_data.get(chapter_num, {
            'individuals': {},
            'deity': {},
            'locations': {},
            'otReferences': {},
            'parenthetical': {},
            'questions': {},
            'exclamations': {}
        })

        chapter_json = build_chapter_json(chapter_num, scripture_data[chapter_num], chapter_analysis)

        # Guardar capítulo
        chapter_file = chapters_dir / f"{chapter_num:03d}.json"
        with open(chapter_file, 'w', encoding='utf-8') as f:
            json.dump(chapter_json, f, indent=2, ensure_ascii=False)

        verse_counts[chapter_num] = len(scripture_data[chapter_num])

    # Generar sections.json
    print("   Generando sections.json...")
    sections = build_sections_from_verses(scripture_data, found_sections)
    sections_json = {
        "packageId": PACKAGE_ID,
        "sections": sections
    }

    with open(OUTPUT_DIR / "sections.json", 'w', encoding='utf-8') as f:
        json.dump(sections_json, f, indent=2, ensure_ascii=False)

    # Generar chapter_analysis.json
    print("   Generando chapter_analysis.json...")
    chapter_analysis = {}
    for chapter_num in sorted(scripture_data.keys()):
        chapter_analysis_data = analysis_data.get(chapter_num, {
            'individuals': {},
            'deity': {},
            'locations': {},
            'otReferences': {},
            'parenthetical': {},
            'questions': {},
            'exclamations': {}
        })
        chapter_analysis[chapter_num] = build_chapter_analysis(
            chapter_num,
            len(scripture_data[chapter_num]),
            chapter_analysis_data
        )

    chapter_analysis_json = {
        "packageId": PACKAGE_ID,
        "chapters": chapter_analysis
    }

    with open(OUTPUT_DIR / "chapter_analysis.json", 'w', encoding='utf-8') as f:
        json.dump(chapter_analysis_json, f, indent=2, ensure_ascii=False)

    # Generar index.json
    print("   Generando index.json...")
    index_json = {
        "packageId": PACKAGE_ID,
        "abbreviation": ABBREVIATION,
        "attribution": ATTRIBUTION,
        "chapterOrder": list(scripture_data.keys()),
        "chapterVerseCounts": {str(k): v for k, v in verse_counts.items()},
        "availableSections": True,
        "availableAudio": False,
        "availableAnalysis": True
    }

    with open(OUTPUT_DIR / "index.json", 'w', encoding='utf-8') as f:
        json.dump(index_json, f, indent=2, ensure_ascii=False)

    # Resumen
    total_verses = sum(verse_counts.values())
    print("\n✅ ¡Generación completada!")
    print(f"   📁 Archivos generados en: {OUTPUT_DIR}")
    print(f"   📊 Capítulos: {len(scripture_data)}")
    print(f"   📊 Versículos totales: {total_verses}")
    print(f"   📊 Secciones: {len(sections)}")

    return 0


if __name__ == "__main__":
    exit(main())
