import json, shutil, os, sys
SRC = sys.argv[1] if len(sys.argv) > 1 else r'C:\Users\micha\Downloads\Loop Mixer'
DST = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RES = 'res://prototypes/loop_deck/loops/'
m = json.load(open(os.path.join(SRC, 'manifest.json')))
ok = set('ACDEG')
pool = [l for l in m['loops'] if set(l['pitches']) <= ok]
os.makedirs(os.path.join(DST, 'loops'), exist_ok=True)
for l in pool:
    if not os.path.exists(os.path.join(DST, 'loops', l['file'])):
        shutil.copy(os.path.join(SRC, 'loops', l['file']), os.path.join(DST, 'loops', l['file']))

def instrument(l):
    desc = l['desc']
    if l['role'] == 'drums':
        return 'Drum Kit'
    if l['role'] == 'perc':
        return 'Hand Percussion'
    if l['role'] == 'pad':
        return 'Synth Pad'
    for key, name in [('electric piano', 'Electric Piano'), ('organ', 'Organ'), ('plucked', 'Pluck'), ('flute', 'Flute'), ('FM bell', 'FM Bell'), ('square', 'Square Synth'), ('sine', 'Sine Synth'), ('saw', 'Saw Synth')]:
        if key in desc:
            return name
    raise ValueError(l['file'])

def ltype(l):
    f = l['file']
    if l['role'] in ('drums', 'perc'):
        return 'Percussion'
    if l['role'] == 'pad' or (f.startswith('chord_') and l['role'] == 'rhythm'):
        return 'Chord'
    if l['role'] in ('bass', 'rhythm'):
        return 'Rhythm'
    return 'Lead'

# file -> (title, band, points, rarity, condition, cond_param, effect, value, target, target_param)
SPEC = {
    'drums_100_X_2bar_01.wav': ('Four on the Floor', 'Drums', 5, 'common', 'first', '', 'mult', 2, 'self', ''),
    'drums_100_X_2bar_02.wav': ('Rock Beat', 'Drums', 7, 'common', 'always', '', 'none', 0, 'self', ''),
    'drums_100_X_2bar_03.wav': ('Half-Time', 'Drums', 5, 'common', 'next_is', 'Lead', 'flow_add', 1, 'set', ''),
    'drums_100_X_2bar_04.wav': ('Breakbeat', 'Drums', 5, 'uncommon', 'odd', '', 'points', 6, 'self', ''),
    'perc_100_X_2bar_01.wav': ('Shaker', 'Percussion', 4, 'common', 'prev_is', 'Percussion', 'flow_add', 1, 'set', ''),
    'perc_100_X_2bar_02.wav': ('Rim Clicks', 'Percussion', 4, 'uncommon', 'always', '', 'points', 3, 'later_genre', 'Rhythm'),
    'perc_100_X_2bar_03.wav': ('Congas', 'Percussion', 4, 'uncommon', 'per_hand', 'Percussion', 'points', 3, 'self', ''),
    'bass_100_A_2bar_01.wav': ('Sub Bass', 'Bass', 5, 'common', 'prev_is', 'Percussion', 'mult', 2, 'self', ''),
    'bass_100_A_2bar_02.wav': ('Pentatonic Walk', 'Bass', 7, 'common', 'always', '', 'none', 0, 'self', ''),
    'rhythm_100_A_2bar_01.wav': ('Detuned Pad', 'Synth', 5, 'uncommon', 'always', '', 'points', 4, 'next', ''),
    'rhythm_100_A_2bar_02.wav': ('Plucked Arp', 'Synth', 5, 'common', 'next_is', 'Pluck', 'flow_add', 1, 'set', ''),
    'chord_Am_01_bass.wav': ('Am Sub Bass', 'Bass', 5, 'common', 'next_is', 'Chord', 'flow_add', 1, 'set', ''),
    'chord_Am_02_bass.wav': ('Am Bass Walk', 'Bass', 4, 'uncommon', 'per_before', 'Percussion', 'points', 3, 'self', ''),
    'chord_C_01_bass.wav': ('C Sub Bass', 'Bass', 5, 'common', 'last', '', 'mult', 2, 'self', ''),
    'chord_C_02_bass.wav': ('C Bass Walk', 'Bass', 5, 'uncommon', 'prev_is', 'Rhythm', 'cash', 2, 'self', ''),
    'chord_Em_02_bass.wav': ('Em Bass Walk', 'Bass', 4, 'rare', 'last', '', 'consumable', 1, 'self', ''),
    'chord_Am_00_pad.wav': ('Am Pad', 'Pad', 4, 'common', 'always', '', 'flow_add', 0.5, 'set', ''),
    'chord_C_00_pad.wav': ('C Pad', 'Pad', 4, 'uncommon', 'always', '', 'points', 3, 'later_genre', 'Lead'),
    'chord_Am_03_rhythm.wav': ('Am Pluck', 'Keys', 4, 'common', 'prev_is', 'Rhythm', 'mult', 2, 'self', ''),
    'chord_Am_04_rhythm.wav': ('Am Keys', 'Keys', 4, 'common', 'next_is', 'Lead', 'flow_add', 1, 'set', ''),
    'chord_Am_05_rhythm.wav': ('Am Organ', 'Organ', 3, 'rare', 'always', '', 'copy', 0, 'self', ''),
    'chord_C_03_rhythm.wav': ('C Pluck', 'Keys', 4, 'uncommon', 'per_hand', 'Pluck', 'points', 5, 'self', ''),
    'chord_C_04_rhythm.wav': ('C Keys', 'Keys', 4, 'common', 'odd', '', 'points', 5, 'self', ''),
    'chord_C_05_rhythm.wav': ('C Organ', 'Organ', 4, 'rare', 'last', '', 'flow_mult', 1.5, 'set', ''),
    'lead_100_A_2bar_01.wav': ('Square Lead', 'Lead', 6, 'common', 'last', '', 'mult', 3, 'self', ''),
    'lead_100_A_2bar_02.wav': ('Breathy Flute', 'Flute', 6, 'common', 'prev_is', 'Chord', 'mult', 2, 'self', ''),
    'lead_100_A_2bar_03.wav': ('FM Bell', 'Bell', 5, 'uncommon', 'per_empty', '', 'points', 5, 'self', ''),
    'chord_Am_06_lead.wav': ('Am Square', 'Lead', 6, 'common', 'prev_is', 'Rhythm', 'flow_add', 1, 'set', ''),
    'chord_Am_07_lead.wav': ('Am Flute', 'Flute', 8, 'common', 'always', '', 'none', 0, 'self', ''),
    'chord_Am_08_lead.wav': ('Am Bell', 'Bell', 5, 'uncommon', 'per_before', 'Percussion', 'mult', 1.5, 'self', ''),
    'chord_Am_09_lead.wav': ('Am Saw Lead', 'Lead', 6, 'common', 'prev_is', 'Saw Synth', 'mult', 2, 'self', ''),
    'chord_Am_10_lead.wav': ('Am Vibrato', 'Lead', 5, 'uncommon', 'prev_is', 'Sine Synth', 'flow_add', 1, 'set', ''),
    'chord_C_06_lead.wav': ('C Square', 'Lead', 6, 'common', 'prev_is', 'Chord', 'mult', 2, 'self', ''),
    'chord_C_07_lead.wav': ('C Flute', 'Flute', 8, 'common', 'always', '', 'none', 0, 'self', ''),
    'chord_C_08_lead.wav': ('C Bell', 'Bell', 5, 'uncommon', 'per_hand', 'Lead', 'points', 3, 'self', ''),
    'chord_C_09_lead.wav': ('C Saw Lead', 'Lead', 5, 'uncommon', 'per_before', 'Saw Synth', 'points', 4, 'self', ''),
    'chord_C_10_lead.wav': ('C Vibrato', 'Lead', 6, 'uncommon', 'prev_empty', '', 'points', 6, 'self', ''),
    'chord_Em_06_lead.wav': ('Em Square', 'Lead', 6, 'uncommon', 'slot4', '', 'mult', 2, 'self', ''),
    'chord_Em_10_lead.wav': ('Em Vibrato', 'Lead', 5, 'uncommon', 'prev_is', 'Lead', 'flow_add', 1, 'set', ''),
    'chord_G_06_lead.wav': ('G Square', 'Lead', 5, 'uncommon', 'per_before', 'Rhythm', 'points', 3, 'self', ''),
    'chord_G_07_lead.wav': ('G Flute', 'Flute', 7, 'common', 'always', '', 'none', 0, 'self', ''),
    'chord_G_08_lead.wav': ('G Bell', 'Bell', 5, 'common', 'always', '', 'points', 4, 'next', ''),
    'chord_G_10_lead.wav': ('G Vibrato', 'Lead', 5, 'rare', 'always', '', 'mult', 1.25, 'later', ''),
}
cards = []
for l in pool:
    s = SPEC[l['file']]
    cid = l['file'].replace('.wav', '').replace('_2bar', '').lower()
    cards.append({
        'id': cid, 'title': s[0], 'band': instrument(l), 'instrument': instrument(l), 'genre': ltype(l), 'decade': '', 'cover': '',
        'song': RES + l['file'], 'points': s[2], 'rarity': s[3], 'condition': s[4], 'cond_param': s[5],
        'effect': s[6], 'value': s[7], 'target': s[8], 'target_param': s[9], 'desc': l['desc'],
    })
assert len(cards) == len(SPEC), (len(cards), len(SPEC))
json.dump(cards, open(os.path.join(DST, 'data', 'cards.json'), 'w', encoding='utf-8'), indent=1)

# Pitched starter cards are generated loops (loop_deck_gen.gd): <pattern file name>#<variant>.
starter = ['drums_100_x_01', 'drums_100_x_02', 'drums_100_x_03', 'perc_100_x_01', 'perc_100_x_02',
           'rhythm_root_fifth_bass#0', 'rhythm_root_fifth_bass#1', 'rhythm_walking_bass#0', 'rhythm_octave_pump#0', 'rhythm_tresillo_bass#0',
           'chord_whole_note_chords#0', 'chord_whole_note_chords#1', 'chord_offbeat_stabs#0', 'chord_tresillo_hits#0',
           'lead_triplet_descent#0', 'lead_triplet_descent#1', 'lead_hook#0', 'lead_hook#1', 'lead_call_and_response#0', 'lead_turnaround_run#0']
ids = {c['id'] for c in cards}
for s in starter:
    assert s in ids or '#' in s, s
json.dump([{'id': 'starter', 'name': 'Starter Crate', 'idea': 'Five percussion, five rhythm, four chord and six lead loops.', 'enabled': True, 'mixes': 0, 'cards': {s: 1 for s in starter}}],
          open(os.path.join(DST, 'data', 'decks.json'), 'w', encoding='utf-8'), indent=1)

def gear(id, name, text, price, rule, activates='song', levels=True):
    base = {'when': 'each', 'requires': 'none', 'applies': 'any', 'aparam': '', 'effect': 'points', 'amount': 0, 'per': 'none', 'cap': 0, 'label': name, 'rparam': '', 'rn': 0}
    base.update(rule)
    return {'id': id, 'name': name, 'text': text, 'size': 'half', 'price': price, 'look': '', 'active': False, 'activates': activates, 'params': {}, 'enabled': True, 'rule': base, 'levels': levels}

G = [
    gear('clean_boost', 'Clean Boost', '+{amount} points to the loop in this tray.', 5, {'effect': 'points', 'amount': 10}),
    gear('backbeat', 'Backbeat', '+{amount} points if this tray is {aparam}.', 5, {'applies': 'genre', 'aparam': 'Percussion', 'effect': 'points', 'amount': 15}),
    gear('low_end', 'Low End', '+{amount} flow if this tray is {aparam}.', 6, {'applies': 'genre', 'aparam': 'Rhythm', 'effect': 'flow', 'amount': 1}),
    gear('harmonizer', 'Harmonizer', 'x{amount} points if this tray is {aparam}.', 6, {'applies': 'genre', 'aparam': 'Chord', 'effect': 'mult', 'amount': 1.5}),
    gear('spotlight', 'Spotlight', 'x{amount} points if this tray is {aparam} and it is the only {aparam} loop.', 7, {'applies': 'genre', 'aparam': 'Lead', 'requires': 'type_exactly', 'rparam': 'Lead', 'rn': 1, 'effect': 'mult', 'amount': 2}),
    gear('duet', 'Duet', '+{amount} flow if Rhythm and Lead loops both play.', 6, {'requires': 'types_all', 'rparam': 'Rhythm+Lead', 'effect': 'flow', 'amount': 1.5}, 'anywhere'),
    gear('full_band', 'Full Band', '+{amount} flow if all four loop types play.', 8, {'requires': 'all_types', 'effect': 'flow', 'amount': 2}, 'anywhere'),
    gear('click_track', 'Click Track', '+${amount} if exactly {rn} {rparam} loop plays.', 5, {'requires': 'type_exactly', 'rparam': 'Percussion', 'rn': 1, 'effect': 'cash', 'amount': 2}, 'anywhere'),
    gear('stack', 'Stack', '+{amount} points for each loop already playing.', 6, {'per': 'loops_before', 'effect': 'points', 'amount': 4}),
    gear('unison', 'Unison', '+{amount} flow if two loops share an instrument.', 6, {'requires': 'instrument_pair', 'effect': 'flow', 'amount': 1.5}, 'anywhere'),
    gear('ensemble', 'Ensemble', '+{amount} points if this loop shares its instrument with another loop.', 5, {'requires': 'instrument_shared', 'effect': 'points', 'amount': 15}),
    gear('orchestra', 'Orchestra', '+{amount} flow if {rn} loops all use different instruments.', 7, {'requires': 'instruments_differ', 'rn': 4, 'effect': 'flow', 'amount': 2}, 'anywhere'),
    gear('tape_deck', 'Tape Deck', 'Makes a cassette the first time its tray is played each gig.', 6, {'effect': 'consumable', 'amount': 1}, 'gig', False),
]
json.dump(G, open(os.path.join(DST, 'data', 'gear.json'), 'w', encoding='utf-8'), indent='\t')
print(len(pool), 'loops', len(cards), 'cards', len(G), 'gear')
from collections import Counter
print(Counter(c['genre'] for c in cards))
inst = {}
for c in cards:
    inst.setdefault(c['instrument'], Counter())[c['genre']] += 1
for k, v in inst.items():
    print(k, dict(v))
