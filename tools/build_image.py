#!/usr/bin/env python3
"""Prepare the Nut ROM, seal the firmware image, or verify the reference build."""
import argparse
import hashlib
import json
from pathlib import Path
import struct

ROM = slice(0x100, 0x7100)
IMAGE_SIZE = 0x20000
CHECKSUM = 0x11c98
REFERENCE = '5222d4c01656773f5a63f158a374867bc9d4e6761ab94429ea5e3d6f740a75f2'


def verify_hash(data, expected, description):
    actual = hashlib.sha256(data).hexdigest()
    if actual != expected:
        raise ValueError(f'{description} SHA-256 is {actual}, expected {expected}')


def apply_patch(rom, path):
    seen = set()
    for number, line in enumerate(path.read_text().splitlines(), 1):
        fields = line.split('#', 1)[0].split()
        if not fields:
            continue
        address, before, after = (int(field, 16) for field in fields)
        if (address in seen or not 0 <= 2 * address < len(rom)
                or not 0 <= before <= 0x3ff or not 0 <= after <= 0x3ff):
            raise ValueError(f'{path.name}:{number}: invalid or duplicate Nut word edit')
        seen.add(address)
        actual, = struct.unpack_from('<H', rom, 2 * address)
        if actual != before:
            raise ValueError(f'{path.name}:{number}: word {address:04x} is {actual:03x}, expected {before:03x}')
        struct.pack_into('<H', rom, 2 * address, after)


def make_rom(stock, output):
    patches = Path(__file__).resolve().parents[1] / 'rom'
    revisions = json.loads((patches / 'revisions.json').read_text())
    revision = next((item for item in revisions['stock'] if item['file'] == stock.name), None)
    if revision is None:
        names = ', '.join(item['file'] for item in revisions['stock'])
        raise ValueError(f'Unsupported stock filename {stock.name!r}. Expected one of {names}')
    image = stock.read_bytes()
    if len(image) != IMAGE_SIZE:
        raise ValueError(f'{stock.name} must be {IMAGE_SIZE} bytes')
    verify_hash(image, revision['sha256'], stock.name)
    rom = bytearray(image[ROM])
    verify_hash(rom, revision['rom_sha256'], 'Extracted Nut ROM')
    if revision['normalize']:
        apply_patch(rom, patches / revision['normalize'])
    verify_hash(rom, revisions['base_rom_sha256'], 'April 15 Nut ROM')
    apply_patch(rom, patches / 'expanded.patch')
    verify_hash(rom, revisions['expanded_rom_sha256'], 'Expanded Nut ROM')
    output.write_bytes(rom)


def seal(raw, rom, output):
    image = bytearray(raw.read_bytes())
    if len(image) != IMAGE_SIZE or image[ROM] != rom.read_bytes() or image[CHECKSUM] != 0:
        raise ValueError('Unexpected linked image size, ROM region, or checksum placeholder')
    image[CHECKSUM] = sum(image) & 0xff
    output.write_bytes(image)
    print(f'{hashlib.sha256(image).hexdigest()}  {output.name}')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest='command', required=True)
    rom = commands.add_parser('rom')
    rom.add_argument('stock', type=Path)
    rom.add_argument('output', type=Path)
    image = commands.add_parser('seal')
    image.add_argument('raw', type=Path)
    image.add_argument('rom', type=Path)
    image.add_argument('output', type=Path)
    verify = commands.add_parser('verify')
    verify.add_argument('image', type=Path)
    args = parser.parse_args()
    try:
        if args.command == 'rom':
            make_rom(args.stock, args.output)
        elif args.command == 'seal':
            seal(args.raw, args.rom, args.output)
        else:
            verify_hash(args.image.read_bytes(), REFERENCE, 'Standalone firmware reference')
            print(f'{args.image.name} matches the standalone 2026-11-22 reference')
    except (OSError, ValueError) as error:
        parser.exit(1, f'{error}\n')


if __name__ == '__main__':
    main()
