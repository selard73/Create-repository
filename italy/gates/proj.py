# projects world points into a Studio screen_capture (601x338 from the 666x374 phone-sim viewport, vertical FOV 70)
import math
def norm(v): l = math.sqrt(sum(t * t for t in v)); return [t / l for t in v]
def cross(a, b): return [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]]
def dot(a, b): return sum(x * y for x, y in zip(a, b))
class Cam:
    def __init__(s, pos, look, W=601, H=338, fov=70):
        s.c = pos; s.f = norm([l - p for l, p in zip(look, pos)])
        s.r = norm(cross(s.f, [0, 1, 0])); s.u = cross(s.r, s.f)
        s.W, s.H = W, H; s.k = (H / 2) / math.tan(math.radians(fov / 2))
    def __call__(s, p):
        d = [a - b for a, b in zip(p, s.c)]
        z = dot(d, s.f)
        if z <= 0.1: return None
        return (s.W / 2 + dot(d, s.r) / z * s.k, s.H / 2 - dot(d, s.u) / z * s.k)
def routes(path='../map/survey/porto_landmarks2.txt'):
    R = {}
    for line in open(path, encoding='utf-8'):
        if line.startswith('ROUTE|'):
            _, name, n, pts = line.rstrip('\n').split('|', 3)
            R[name] = [[float(t) for t in p.split(',')] for p in pts.split(';') if p]
    return R
