EMPTY = "-"


def cell(value):
    text = str(value)
    if "|" in text or "\n" in text:
        raise ValueError(f"unsafe table cell: {text!r}")
    return text or EMPTY


def table(headers, rows):
    lines = [
        "| " + " | ".join(headers) + " |",
        "|" + "|".join("---" for _ in headers) + "|",
    ]
    lines.extend("| " + " | ".join(cell(c) for c in row) + " |" for row in rows)
    return lines


def section(title, headers, rows):
    return [f"## {title}", "", *table(headers, rows), ""]


def split_row(line):
    cells = [c.strip() for c in line.strip().strip("|").split("|")]
    return ["" if c == EMPTY else c for c in cells]


def parse_sections(text):
    sections = {}
    title = None
    header = None
    skip_separator = False
    for line in text.splitlines():
        if line.startswith("## "):
            title = line[3:].strip()
            sections[title] = []
            header = None
        elif title is not None and line.startswith("|"):
            cells = split_row(line)
            if header is None:
                header = cells
                skip_separator = True
            elif skip_separator:
                skip_separator = False
            else:
                sections[title].append(dict(zip(header, cells, strict=True)))
    return sections
