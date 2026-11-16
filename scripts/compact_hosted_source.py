"""Remove nonsemantic source weight while preserving every original line number.

Canonical files are untouched. Strings and licensing/compiler comments are kept.
Backtick interpolation is deliberately left unmodified rather than reinterpreted.
"""
import re

LONG = re.compile(r'\[(=*)\[')
NOTICE = re.compile(r'copyright|license|spdx|third.party', re.I)


def compact(source):
    output = []
    position = 0
    line_start = True
    while position < len(source):
        char = source[position]
        if source.startswith('--', position):
            opening = LONG.match(source, position+2)
            if opening:
                closing = ']'+opening[1]+']'
                ending = source.find(closing, opening.end())
                if ending < 0:
                    return source
                ending += len(closing)
            else:
                ending = source.find('\n', position)
                if ending < 0:
                    ending = len(source)
            comment = source[position:ending]
            if comment.startswith('--!') or NOTICE.search(comment):
                output.append(comment)
            else:
                output.append(' ' + '\n'*comment.count('\n'))
            if '\n' in comment:
                line_start = True
            position = ending
            continue
        opening = LONG.match(source, position) if char=='[' else None
        if char in ('"', "'") or opening:
            if opening:
                closing = ']'+opening[1]+']'
                ending = source.find(closing, opening.end())
                if ending < 0:
                    return source
                ending += len(closing)
            else:
                ending = position+1
                while ending < len(source):
                    if source[ending]=='\\':
                        ending += 2
                    elif source[ending]==char:
                        ending += 1
                        break
                    else:
                        ending += 1
            literal = source[position:ending]
            output.append(literal)
            line_start = literal.endswith('\n')
            position = ending
            continue
        if char=='`':
            return source
        if char not in (' ', '\t') or not line_start:
            output.append(char)
        if char=='\n':
            line_start = True
        elif char not in (' ', '\t', '\r'):
            line_start = False
        position += 1
    return ''.join(output)
