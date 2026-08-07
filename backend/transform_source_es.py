#!/usr/bin/env python3
"""
Transforma el source.txt existente de español al formato correcto (un versículo por línea).
"""

import re
from pathlib import Path

BASE_DIR = Path(__file__).parent / "content" / "cb-hechos-1-9"
SOURCE_FILE = BASE_DIR / "source.txt"
OUTPUT_FILE = BASE_DIR / "source_formatted.txt"


def main():
    with open(SOURCE_FILE, 'r', encoding='utf-8') as f:
        content = f.read()

    lines = content.split('\n')
    output_lines = []
    current_chapter = None

    for line in lines:
        line_stripped = line.strip()

        # Detectar capítulo
        if re.match(r'^CHAPTER\s+\d+$', line_stripped, re.IGNORECASE):
            output_lines.append(line_stripped)
            output_lines.append('')
            continue

        # Detectar líneas que son solo números de capítulo (como "1", "2", etc.)
        if re.match(r'^\d+$', line_stripped):
            chapter_num = int(line_stripped)
            if current_chapter is None or chapter_num != current_chapter:
                output_lines.append(f'CHAPTER {chapter_num}')
                output_lines.append('')
                current_chapter = chapter_num
            continue

        # Detectar títulos de sección (líneas que no empiezan con número y no están vacías)
        if line_stripped and not re.match(r'^\d+', line_stripped):
            # Podría ser un título de sección o parte de un versículo
            # Si es una línea corta y no tiene números al inicio, podría ser título
            if len(line_stripped) < 100 and not re.match(r'^\d+\w', line_stripped):
                # Verificar si es título de sección (está entre líneas vacías o después de capítulo)
                output_lines.append('')
                output_lines.append(line_stripped)
                output_lines.append('')
                continue

        # Procesar línea de versículos (puede contener múltiples versículos)
        if line_stripped:
            # Buscar patrón: número seguido de texto
            # Ejemplo: "1En el primer tratado..." o "1En el primer tratado... 2hasta el día..."
            verse_pattern = re.compile(r'(\d+)([A-ZÁ-Ú][^.]*?\.)')
            matches = list(verse_pattern.finditer(line_stripped))

            if matches:
                for match in matches:
                    verse_num = match.group(1)
                    verse_text = match.group(2).strip()
                    output_lines.append(f'{verse_num} {verse_text}')
            else:
                # Línea que no matchea el patrón, agregar tal cual
                output_lines.append(line_stripped)

    # Limpiar líneas vacías múltiples
    cleaned_lines = []
    prev_empty = False
    for line in output_lines:
        if not line:
            if not prev_empty:
                cleaned_lines.append(line)
            prev_empty = True
        else:
            cleaned_lines.append(line)
            prev_empty = False

    with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
        f.write('\n'.join(cleaned_lines))

    print(f"✅ Archivo formateado guardado en: {OUTPUT_FILE}")
    print(f"   Líneas originales: {len(lines)}")
    print(f"   Líneas formateadas: {len(cleaned_lines)}")


if __name__ == "__main__":
    main()
