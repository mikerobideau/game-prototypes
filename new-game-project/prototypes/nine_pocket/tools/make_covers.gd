extends SceneTree

const SRC := "res://prototypes/nine_pocket/art/album_photos"
const OUT := "res://prototypes/nine_pocket/art/covers"
const SIZE := 384
const GENRE_FIX := {"Psychadelic": "Psychedelic"}

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var re := RegEx.new()
	re.compile("^[^-]+-\\s*([^-]+?)\\s*-")
	var catalog: Array = []
	for genre in DirAccess.get_directories_at(SRC):
		for band in DirAccess.get_directories_at(SRC.path_join(genre)):
			var dir := SRC.path_join(genre).path_join(band)
			for f in DirAccess.get_files_at(dir):
				if not f.get_extension().to_lower() in ["jpg", "jpeg", "png", "webp"]:
					continue
				var m := re.search(f.get_basename())
				if m == null:
					print("skipped (name): ", f)
					continue
				var album := m.get_string(1)
				var img := Image.load_from_file(ProjectSettings.globalize_path(dir.path_join(f)))
				if img == null:
					print("skipped (load): ", f)
					continue
				var s := mini(img.get_width(), img.get_height())
				img = img.get_region(Rect2i((img.get_width() - s) / 2, (img.get_height() - s) / 2, s, s))
				img.resize(SIZE, SIZE, Image.INTERPOLATE_LANCZOS)
				var out := OUT.path_join("%s - %s.jpg" % [band, album].map(func(x): return x.validate_filename()))
				img.save_jpg(ProjectSettings.globalize_path(out), 0.9)
				catalog.append({"genre": GENRE_FIX.get(genre, genre), "band": band, "album": album, "cover": out})
				print("cover: ", out)
	var fa := FileAccess.open(OUT.path_join("catalog.json"), FileAccess.WRITE)
	fa.store_string(JSON.stringify(catalog, "\t"))
	fa.close()
	print("albums: ", catalog.size())
	quit()
