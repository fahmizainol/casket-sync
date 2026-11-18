"""Validate a staged world copy and merge good files into world/ and readable/.

Usage: python tools/merge.py <staging_dir> <world_dir> <readable_dir>

A file that fails to parse (e.g. caught mid-save while Minecraft is running) is skipped,
so the previously synced good copy is kept. Files deleted from the source are removed.
"""
import json, os, shutil, sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import nbt2json


def files_under(d):
    out = set()
    for root, _, fs in os.walk(d):
        for f in fs:
            out.add(os.path.relpath(os.path.join(root, f), d))
    return out


def main(stage, world, readable):
    staged = files_under(stage)
    bad = 0
    for rel in sorted(staged):
        src = os.path.join(stage, rel)
        dst = os.path.join(world, rel)
        try:
            if rel.endswith('.dat'):
                data = nbt2json.load(src)
                jp = os.path.join(readable, rel[:-4] + '.json')
                os.makedirs(os.path.dirname(jp), exist_ok=True)
                with open(jp, 'w', encoding='utf-8') as o:
                    json.dump(data, o, indent=1, ensure_ascii=False, sort_keys=True)
            elif rel.endswith('.json'):
                with open(src, encoding='utf-8') as fh:
                    json.load(fh)
        except Exception as e:
            bad += 1
            print(f'kept old copy of {rel} (incomplete: {e.__class__.__name__})')
            continue
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        shutil.copyfile(src, dst)

    # mirror deletions
    for rel in files_under(world) - staged:
        os.remove(os.path.join(world, rel))
        if rel.endswith('.dat'):
            jp = os.path.join(readable, rel[:-4] + '.json')
            if os.path.exists(jp):
                os.remove(jp)
    print(f'merged {len(staged) - bad} files, kept old copy for {bad}')


if __name__ == '__main__':
    main(*sys.argv[1:4])
