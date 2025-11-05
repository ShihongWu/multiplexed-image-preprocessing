#!/usr/bin/env python3

import os
import xml.etree.ElementTree as ET
import csv
import re
import argparse

# Define lookup for filter based on channel name
FILTER_LOOKUP = {
    'dapi': ('DAPI', 395, 431),
    'fitc': ('FITC', 485, 525),
    'cy3':  ('Cy3',  555, 590),
    'cy5':  ('Cy5',  640, 690)
}

# Define autofluorescence background names
AF_BACKGROUND = {
    'fitc': 'AF488_background',
    'cy3':  'AF555_background',
    'cy5':  'AF647_background'
}

BLEACH_MARKER = {
    'fitc': 'AF488_bleach',
    'cy3':  'AF555_bleach',
    'cy5':  'AF647_bleach'
}

def parse_round(round_dir, cycle_number, bleach_tracking, total_cycles, prev_af_backgrounds):
    xml_file = os.path.join(round_dir, f"round_{cycle_number + 1}.xml")
    folder_name = os.path.basename(round_dir)

    is_background = 'bkgnd' in folder_name.lower()
    is_bleach = 'bleach' in folder_name.lower()

    with open(xml_file, 'r') as f:
        tree = ET.parse(f)
        root = tree.getroot()
        channels = root.find('RoundChannels').findall('RoundChannel')

    rows = []
    for i, channel in enumerate(channels):
        ch_name = channel.find('ChannelName').text.lower()
        exposure = float(channel.find('ExposureTimeMS').text)
        stain = channel.find('StainName').text

        if ch_name not in FILTER_LOOKUP:
            continue

        filter_name, ex_wl, em_wl = FILTER_LOOKUP[ch_name]

        if i == 0:
            marker_name = f"DNA_{cycle_number + 1}"
        elif is_background:
            marker_name = AF_BACKGROUND.get(ch_name, f"AF_{ch_name}_background")
        elif is_bleach:
            bleach_idx = sum(1 for r in bleach_tracking if r < cycle_number)
            marker_name = f"{BLEACH_MARKER.get(ch_name, f'{ch_name}_bleach')}_{bleach_idx}"
        else:
            marker_name = stain

        if is_background:
            background = ''
            remove = 'TRUE' if i > 0 else ''
        elif is_bleach:
            background = ''
            remove = 'TRUE'
        else:
            if ch_name == 'dapi':
                background = ''
            else:
                background = ''
                # Look for the latest bleach round before this one
                for prior in reversed(bleach_tracking):
                    if prior < cycle_number:
                        bleach_idx = sum(1 for r in bleach_tracking if r <= prior)
                        background = f"{BLEACH_MARKER[ch_name]}_{bleach_idx - 1}"
                        break
                # Special case: first stain round, no bleach seen yet
                if not background and cycle_number == 1 and prev_af_backgrounds:
                    background = prev_af_backgrounds.get(ch_name, '')
                if not background:
                    print(f"Warning: No bleach or background found for channel '{ch_name}' before cycle {cycle_number}. Leaving background blank.")
            remove = ''

        # keep only first and last DAPI channel
        if ch_name == 'dapi' and not (cycle_number == 0 or cycle_number == total_cycles - 1):
            remove = 'TRUE'

        row = {
            'channel_number': i,
            'cycle_number': cycle_number,
            'marker_name': marker_name,
            'Filter': filter_name,
            'excitation_wavelength': ex_wl,
            'emission_wavelength': em_wl,
            'background': background,
            'exposure': int(exposure),
            'remove': remove
        }
        rows.append(row)

    return rows

def generate_markers_csv(root_dir, output_csv):
    round_dirs = sorted([os.path.join(root_dir, d) for d in os.listdir(root_dir) if re.match(r'^S\d{3}_', d)])
    all_rows = []
    bleach_tracking = []
    total_cycles = len(round_dirs)

    # Pre-extract autofluorescence marker names from first round (assumed background)
    prev_af_backgrounds = {}
    if round_dirs:
        first_dir = round_dirs[0]
        xml_file = os.path.join(first_dir, f"round_1.xml")
        if os.path.exists(xml_file):
            with open(xml_file, 'r') as f:
                tree = ET.parse(f)
                root = tree.getroot()
                channels = root.find('RoundChannels').findall('RoundChannel')
                for i, ch in enumerate(channels):
                    ch_name = ch.find('ChannelName').text.lower()
                    if ch_name in AF_BACKGROUND:
                        prev_af_backgrounds[ch_name] = AF_BACKGROUND[ch_name]

    for cycle_number, rdir in enumerate(round_dirs):
        print(f"Processing cycle {cycle_number}: {rdir}")
        if 'bleach' in rdir.lower():
            bleach_tracking.append(cycle_number)
        rows = parse_round(rdir, cycle_number, bleach_tracking, total_cycles, prev_af_backgrounds)
        all_rows.extend(rows)

    # Make marker_name values unique
    name_counts = {}
    for row in all_rows:
        name = row['marker_name']
        if name not in name_counts:
            name_counts[name] = 1
        else:
            name_counts[name] += 1
            row['marker_name'] = f"{name}_{name_counts[name]}"

    # Write output
    fieldnames = ['channel_number', 'cycle_number', 'marker_name', 'Filter',
                  'excitation_wavelength', 'emission_wavelength', 'background',
                  'exposure', 'remove']
    with open(output_csv, 'w', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        for row in all_rows:
            writer.writerow({k: row.get(k, '') for k in fieldnames})

    print(f"✅ markers.csv written to: {output_csv}")

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description="Generate markers.csv from round folders and XML metadata")
    parser.add_argument('--root', type=str, required=True, help="Path to directory containing S###_* folders")
    parser.add_argument('--out', type=str, default='markers.csv', help="Output csv path (default: markers.csv)")
    args = parser.parse_args()

    generate_markers_csv(args.root, args.out)

