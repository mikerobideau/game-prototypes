extends SceneTree

const OUT := "res://prototypes/loop_deck/icon/type/"
const S := 256

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	for name in ["percussion", "rhythm", "chord", "lead"]:
		var img := Image.create(S, S, false, Image.FORMAT_RGBA8)
		for y in S:
			for x in S:
				var cov := 0.0
				for sy in 3:
					for sx in 3:
						var p := Vector2(x + (sx + 0.5) / 3.0, y + (sy + 0.5) / 3.0) / float(S)
						if _inside(name, p):
							cov += 1.0
				img.set_pixel(x, y, Color(0, 0, 0, cov / 9.0))
		img.save_png(ProjectSettings.globalize_path(OUT + name + ".png"))
	print("icons done")
	quit()

func _seg(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var t := clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
	return p.distance_to(a + ab * t)

func _ell(p: Vector2, c: Vector2, r: Vector2, rot: float = 0.0) -> bool:
	var q := (p - c).rotated(-rot)
	return (q.x * q.x) / (r.x * r.x) + (q.y * q.y) / (r.y * r.y) <= 1.0

func _inside(name: String, p: Vector2) -> bool:
	match name:
		"percussion":
			var top := _ell(p, Vector2(0.5, 0.46), Vector2(0.34, 0.11))
			var body := p.x >= 0.16 and p.x <= 0.84 and p.y >= 0.46 and p.y <= 0.78
			var bottom := _ell(p, Vector2(0.5, 0.78), Vector2(0.34, 0.11))
			var hole := _ell(p, Vector2(0.5, 0.46), Vector2(0.27, 0.065))
			var sticks := _seg(p, Vector2(0.2, 0.08), Vector2(0.46, 0.4)) < 0.03 or _seg(p, Vector2(0.8, 0.08), Vector2(0.54, 0.4)) < 0.03
			var tips := p.distance_to(Vector2(0.2, 0.08)) < 0.05 or p.distance_to(Vector2(0.8, 0.08)) < 0.05
			return ((top or body or bottom) and not hole) or sticks or tips
		"rhythm":
			var pts: Array[Vector2] = [Vector2(0.08, 0.68), Vector2(0.24, 0.68), Vector2(0.24, 0.3), Vector2(0.4, 0.3), Vector2(0.4, 0.68), Vector2(0.56, 0.68), Vector2(0.56, 0.3), Vector2(0.72, 0.3), Vector2(0.72, 0.68), Vector2(0.92, 0.68)]
			for k in pts.size() - 1:
				if _seg(p, pts[k], pts[k + 1]) < 0.05:
					return true
			return false
		"chord":
			for k in 3:
				if _ell(p, Vector2(0.42, 0.32 + k * 0.22), Vector2(0.135, 0.085), -0.35):
					return true
			return p.x >= 0.525 and p.x <= 0.58 and p.y >= 0.08 and p.y <= 0.75
		"lead":
			var head := _ell(p, Vector2(0.38, 0.74), Vector2(0.17, 0.12), -0.4)
			var stem := p.x >= 0.505 and p.x <= 0.565 and p.y >= 0.14 and p.y <= 0.72
			var flag := _seg(p, Vector2(0.535, 0.16), Vector2(0.76, 0.4)) < 0.045 or _seg(p, Vector2(0.76, 0.4), Vector2(0.7, 0.56)) < 0.04
			return head or stem or flag
	return false
