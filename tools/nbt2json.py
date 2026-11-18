"""Convert Minecraft gzip NBT files (.dat) to readable JSON.

Usage:
  python tools/nbt2json.py <file.dat> [out.json]
  python tools/nbt2json.py --tree <world_dir> <out_dir>   # convert every .dat under world_dir
"""
import gzip, json, os, struct, sys, uuid


def _rd(f, n):
    b = f.read(n)
    if len(b) != n:
        raise EOFError
    return b


def _name(f):
    n = struct.unpack('>H', _rd(f, 2))[0]
    return _rd(f, n).decode('utf8', 'replace')


def _payload(f, t):
    if t == 1: return struct.unpack('>b', _rd(f, 1))[0]
    if t == 2: return struct.unpack('>h', _rd(f, 2))[0]
    if t == 3: return struct.unpack('>i', _rd(f, 4))[0]
    if t == 4: return struct.unpack('>q', _rd(f, 8))[0]
    if t == 5: return round(struct.unpack('>f', _rd(f, 4))[0], 4)
    if t == 6: return round(struct.unpack('>d', _rd(f, 8))[0], 4)
    if t == 7:
        n = struct.unpack('>i', _rd(f, 4))[0]
        return list(_rd(f, n)) if n <= 64 else f'<{n} bytes>'
    if t == 8: return _name(f)
    if t == 9:
        et = _rd(f, 1)[0]
        n = struct.unpack('>i', _rd(f, 4))[0]
        return [_payload(f, et) for _ in range(n)]
    if t == 10:
        d = {}
        while True:
            tt = _rd(f, 1)[0]
            if tt == 0:
                return d
            k = _name(f)
            v = _payload(f, tt)
            # int[4] UUIDs -> readable string alongside the raw value
            if tt == 11 and isinstance(v, list) and len(v) == 4 and 'uuid' in k.lower():
                d[k + '_str'] = str(uuid.UUID(bytes=struct.pack('>4i', *v)))
            d[k] = v
    if t == 11:
        n = struct.unpack('>i', _rd(f, 4))[0]
        return list(struct.unpack(f'>{n}i', _rd(f, 4 * n)))
    if t == 12:
        n = struct.unpack('>i', _rd(f, 4))[0]
        return list(struct.unpack(f'>{n}q', _rd(f, 8 * n)))
    raise ValueError(f'unknown tag {t}')


def load(path):
    with open(path, 'rb') as raw:
        head = raw.read(2)
    opener = gzip.open if head == b'\x1f\x8b' else open
    with opener(path, 'rb') as f:
        t = _rd(f, 1)[0]
        _name(f)
        return _payload(f, t)


def convert(src, dst):
    data = load(src)
    os.makedirs(os.path.dirname(dst) or '.', exist_ok=True)
    with open(dst, 'w', encoding='utf-8') as o:
        json.dump(data, o, indent=1, ensure_ascii=False, sort_keys=True)


def tree(world, out):
    ok = bad = 0
    for root, _, files in os.walk(world):
        for fn in files:
            if not fn.endswith('.dat'):
                continue
            src = os.path.join(root, fn)
            rel = os.path.relpath(src, world)
            try:
                convert(src, os.path.join(out, rel[:-4] + '.json'))
                ok += 1
            except Exception as e:  # keep going on odd files
                bad += 1
                print(f'skip {rel}: {e}', file=sys.stderr)
    print(f'converted {ok} files, skipped {bad}')


if __name__ == '__main__':
    a = sys.argv[1:]
    if a and a[0] == '--tree':
        tree(a[1], a[2])
    elif a:
        if len(a) > 1:
            convert(a[0], a[1])
        else:
            sys.stdout.reconfigure(encoding='utf-8')
            print(json.dumps(load(a[0]), indent=1, ensure_ascii=False, sort_keys=True))
    else:
        print(__doc__)
