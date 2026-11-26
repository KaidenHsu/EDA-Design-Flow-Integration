"""Week 12 models. No PDK, router, timing engine or silicon measurements."""

import json
from collections import defaultdict

# The placement model uses two eight-site rows and four fixed-width cells.
WIDTHS = {'U1': 2, 'U2': 3, 'U3': 2, 'U4': 2}
BLOCKED = {('R0', 4), ('R0', 5)}
INITIAL = {'U1': ['R0', 0.5], 'U2': ['R0', 2], 'U3': ['R1', 3], 'U4': ['R1', 4]}


def utilization(cell, eligible):
    """Calculate the percentage of eligible area occupied by cells."""
    if not (eligible > 0 and cell >= 0):
        raise ValueError('Invalid area')
    return 100 * cell / eligible


def overflow(demand, capacity):
    """Calculate excess routing demand for each region."""
    if len(demand) != len(capacity) or any((x < 0 for x in demand + capacity)):
        raise ValueError('Invalid tracks')
    return [max(0, d - c) for d, c in zip(demand, capacity)]


def hpwl(pins):
    """Calculate the half-perimeter wirelength of a pin bounding box."""
    if not pins:
        raise ValueError('Missing pins')
    (x, y) = zip(*pins)
    return max(x) - min(x) + max(y) - min(y)


def stripe(width, pitch, min_spacing=8):
    """Calculate stripe geometry and metal fraction for the teaching model."""
    if not 0 < width <= pitch:
        raise ValueError('Invalid stripe')
    return {
        'width_um': width,
        'pitch_um': pitch,
        'spacing_um': pitch - width,
        'metal_fraction_pct': 100 * width / pitch,
        'meets_model_spacing': pitch - width >= min_spacing
    }


def pg_audit(edges):
    """Check supply-pin reachability and identify cross-supply edges."""
    nodes = {f'{n}.{p}' for n in ('VDD', 'VSS') for p in ('entry', 'strap', 'rail', 'P1', 'P2')}
    adj = defaultdict(set)
    shorts = []
    for a, b in edges:
        if a not in nodes or b not in nodes:
            raise ValueError('Unknown PG node')
        adj[a].add(b)
        adj[b].add(a)
        if a.split('.')[0] != b.split('.')[0]:
            shorts.append([a, b])

    # Trace each supply independently from its entry node.
    disconnected = []
    for n in ('VDD', 'VSS'):
        seen = {n + '.entry'}
        todo = list(seen)
        while todo:
            for v in adj[todo.pop()]:
                if v.startswith(n + '.') and v not in seen:
                    seen.add(v)
                    todo.append(v)
        disconnected += [n + '.' + p for p in ('P1', 'P2') if n + '.' + p not in seen]
    return {
        'disconnected_pins': disconnected,
        'cross_supply_edges': shorts,
        'connected_without_cross_supply_edges': not disconnected and (not shorts)
    }

# The starting graph deliberately leaves VDD.P2 disconnected.
PG_EDGES = [
    [f'{supply}.{source}', f'{supply}.{target}']
    for supply in ('VDD', 'VSS')
    for source, target in (
        ('entry', 'strap'),
        ('strap', 'rail'),
        ('rail', 'P1'),
        ('rail', 'P2'),
    )
    if (supply, source, target) != ('VDD', 'rail', 'P2')
]


def placement_audit(positions):
    """Check a candidate against the model placement rules."""
    if set(positions) != set(WIDTHS):
        raise ValueError('Require U1–U4 exactly once')
    errors = []
    intervals = []
    for (u, (r, x)) in positions.items():
        if r not in ('R0', 'R1') or not isinstance(x, (int, float)) or isinstance(x, bool):
            raise ValueError('Invalid row or coordinate')
        end = x + WIDTHS[u]
        if x != int(x):
            errors.append(f'{u}: off-grid')
        if x < 0 or end > 8:
            errors.append(f'{u}: out of row')
        for br, b in sorted(BLOCKED):
            if r == br and max(x, b) < min(end, b + 1):
                errors.append(f'{u}: overlaps blocked site {r}:{b}')
        for v, vr, vx, ve in intervals:
            if r == vr and max(x, vx) < min(end, ve):
                errors.append(f'{v}/{u}: overlap')
        intervals.append((u, r, x, end))
    return {
        'legal': not errors,
        'issues': errors,
        'eligible_sites': 14,
        'cell_footprint_sites': 9,
        'footprint_utilization_pct': utilization(9, 14)
    }


def report(lab, work):
    """Build the illustrative or model-only report for one experiment."""
    if lab == 'A':
        return {
            'evidence': 'ILLUSTRATIVE',
            'preclass': {
                'core_area_um2': 200 * 100,
                'excluded_area_um2': (40 + 10) * (30 + 10),
                'eligible_area_um2': 18000,
                'utilization_pct': utilization(10800, 18000),
                'target_pct': 65,
            },
            'growth_budget_um2': 9600 * 1.1 / 0.6,
            'candidates': {
                k: {
                    'core_area_um2': 160 * h,
                    'utilization_pct': utilization(9600, 160 * h),
                    'after_growth_pct': utilization(10560, 160 * h),
                }
                for k, h in [('A', 100), ('B', 120)]
            }
        }
    if lab == 'B':
        edges = json.loads((work / 'power_grid_edges.json').read_text())
        return {
            'evidence': 'MODEL_ONLY',
            'initial': pg_audit(PG_EDGES),
            'student_candidate': pg_audit(edges),
            'stripe_evidence': 'ILLUSTRATIVE',
            'stripes': [stripe(2, 10), stripe(3, 10)],
            'resistance_ratio_B_over_A': 2 / 3,
            'simple_path_drop_mV': [20 * 0.5, 20 * 0.25],
            'IR_EM_status': 'UNAVAILABLE'
        }
    if lab == 'C':
        pos = json.loads((work / 'placement.json').read_text())
        return {
            'evidence': 'MODEL_ONLY',
            'initial': placement_audit(INITIAL),
            'student_candidate': placement_audit(pos),
            'hpwl_example': hpwl([(1, 1), (5, 1), (5, 4)]),
            'overflow': {
                k: {
                    'demand': d,
                    'per_region': overflow(d, [10, 10, 10]),
                    'total': sum(overflow(d, [10, 10, 10])),
                }
                for k, d in [('A', [12, 8, 9]), ('B', [10, 10, 9])]
            }
        }

    # These values are illustrative inputs to the timing comparison.
    if lab == 'D':
        candidates = {
            'baseline': (-0.2, 0.05, 9600, 2),
            'A': (0.15, -0.05, 9800, 2),
            'B': (0.05, 0.02, 9900, 0)
        }
        return {
            'evidence': 'ILLUSTRATIVE',
            'week11_setup_slack_ns': round(10 - 1 - 0.3 - 0.7 - 6.5, 3),
            'placed_setup_slack_ns': round(10 - 1 - 0.3 - 0.7 - 8.2, 3),
            'candidates': {
                k: {
                    'setup_slack_ns': s,
                    'hold_slack_ns': h,
                    'cell_area_um2': a,
                    'area_overhead_pct': 100 * (a - 9600) / 9600,
                    'overflow_tracks': o,
                }
                for (k, (s, h, a, o)) in candidates.items()
            },
            'power_IR_EM': 'UNAVAILABLE'
        }
    raise ValueError(lab)
