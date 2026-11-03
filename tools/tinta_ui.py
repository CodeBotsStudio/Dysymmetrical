import numpy as np
from PIL import Image, ImageFilter
rng = np.random.default_rng(7)

def smooth_noise(n, scale, amp):
    g = np.exp(-0.5 * (np.arange(-3 * scale, 3 * scale + 1) / scale) ** 2)
    k = np.convolve(rng.normal(0, 1, n + 6 * scale), g / g.sum(), "valid")[:n]
    return k / k.std() * amp

W, H = 2048, 512
x = np.arange(W)[None, :].repeat(H, 0).astype(float)
y = np.arange(H)[:, None].repeat(W, 1).astype(float)
edge = 1024 + smooth_noise(H, 64, 46)[:, None] + smooth_noise(H, 16, 5)[:, None]
d = x - edge
alpha = np.clip(d / 60 + 0.5, 0, 1)
dry = rng.random((H, W)) < np.clip(0.55 - d / 70, 0, 0.55)
alpha[dry & (d < 30)] *= 0.25
hatch = (np.sin((x + y * 0.9) * 0.22) > 0.86) & (rng.random((H, W)) > 0.35)
ink = np.stack([np.full((H, W), 18.0), np.full((H, W), 17.0), np.full((H, W), 15.0)], -1)
ivory = np.array([236, 228, 210], float)
mix = np.where(hatch, 0.09, 0.0)[..., None]
lead = (np.abs(d - 4) < 2.2) & (rng.random((H, W)) > 0.25)
mix = np.where(lead[..., None], 0.75, mix)
rgb = ink * (1 - mix) + ivory * mix
a = np.where(lead, np.maximum(alpha, 0.85), alpha)
img = Image.fromarray(np.dstack([rgb, a * 255]).clip(0, 255).astype(np.uint8), "RGBA").filter(ImageFilter.GaussianBlur(0.6))
img.save("UI texturas/efectos/velo_tinta.png")

S = 512
yy, xx = np.mgrid[0:S, 0:S].astype(float) - S / 2
r = np.hypot(xx, yy)
th = np.arctan2(yy, xx)
canvas = np.zeros((S, S))
for k in range(3):
    phase = rng.uniform(0, 6.28)
    rad = 196 + k * 7 + 8 * np.sin(th * 3 + phase) + 4 * np.sin(th * 7 + phase * 2)
    width = 5 + 4 * (0.5 + 0.5 * np.sin(th * 2 + phase))
    stroke = np.clip(1 - np.abs(r - rad) / width, 0, 1)
    gaps = 0.5 + 0.5 * np.sin(th * 11 + phase * 3)
    canvas = np.maximum(canvas, stroke * (0.55 + 0.45 * gaps) * (1 - 0.35 * k))
canvas *= (rng.random((S, S)) > 0.18)
ticks = (np.abs(r - 228) < 14) & (np.abs(np.sin(th * 36)) < 0.08)
pass
ring = np.zeros((S, S, 4), np.uint8)
ring[..., :3] = [236, 228, 210]
ring[..., 3] = (canvas.clip(0, 1) * 255).astype(np.uint8)
Image.fromarray(ring, "RGBA").filter(ImageFilter.GaussianBlur(0.7)).save("UI texturas/efectos/anillo_tinta.png")
prev = Image.new("RGBA", (W // 2 + S // 2, H // 2), (60, 70, 60, 255))
prev.alpha_composite(img.resize((W // 2, H // 2)))
prev.alpha_composite(Image.open("UI texturas/efectos/anillo_tinta.png").resize((S // 2, S // 2)), (W // 2, 0))
prev.save("UI texturas/efectos/vista_previa.png")

D = 256
yy, xx = np.mgrid[0:D, 0:D].astype(float) - D / 2
r, th = np.hypot(xx, yy), np.arctan2(yy, xx)
rim = 118 + 3 * np.sin(th * 3 + 1.3) + 2 * np.sin(th * 5 + 0.4)
body = np.clip((rim - r) / 4, 0, 1)
hatch = (np.sin((xx + yy * 0.9) * 0.45) > 0.8) & (rng.random((D, D)) > 0.3)
disc = np.zeros((D, D, 4), np.uint8)
disc[..., :3] = np.where(hatch[..., None], [44, 42, 38], [16, 15, 13])
edge = np.clip(1 - np.abs(r - rim + 2) / 2.2, 0, 1) * 0.6
disc[..., :3] = (disc[..., :3] * (1 - edge[..., None]) + np.array([236, 228, 210]) * edge[..., None]).astype(np.uint8)
disc[..., 3] = (body * 255).astype(np.uint8)
Image.fromarray(disc, "RGBA").filter(ImageFilter.GaussianBlur(0.5)).save("UI texturas/efectos/disco_tinta.png")
