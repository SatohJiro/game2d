extends Node
class_name BaseManager

signal base_level_changed(new_level: int)
signal quest_updated(quest_title: String, quest_desc: String, progress_text: String)

var base_level: int = 1
var max_base_level: int = 5

var current_quest_idx: int = 0
var quest_completed: bool = false

var quests: Array[Dictionary] = [
	{
		"title": "Giai Đoạn 1: Sinh Tồn Dã Ngoại & Ẩm Thực",
		"desc": "Thu thập 8 Gỗ, 4 Đá, bắt 1 Pet và nấu 1 món ăn tại Bếp [E]",
		"req_wood": 8,
		"req_stone": 4,
		"req_pets": 1,
		"reward": "Mở khóa Lò Luyện Kim, Thùng Ủ Phân & Kiếm Sắt",
		"unlock_level": 2
	},
	{
		"title": "Giai Đoạn 2: Nông Nghiệp Hữu Cơ & Luyện Kim",
		"desc": "Ủ 1 túi Phân Bón tại Thùng Ủ, nung 3 Thỏi Sắt",
		"req_iron": 3,
		"req_fertilizer": 1,
		"reward": "Mở khóa Rương Kho Đồ & Cầu Siêu Cấp (Mega Sphere)",
		"unlock_level": 3
	},
	{
		"title": "Giai Đoạn 3: Tự Động Hóa Nông Nghiệp & Căn Cứ",
		"desc": "Thu hoạch 6 Quả Mọng, luyện 4 Thỏi Pal",
		"req_pal_ingot": 4,
		"req_berries": 6,
		"reward": "Mở khóa Tháp Phòng Thủ Tự Động & Giáp Chiến Binh",
		"unlock_level": 4
	},
	{
		"title": "Giai Đoạn 4: Pháo Đài Phòng Thủ & Đêm Xâm Lăng",
		"desc": "Xây dựng Tháp Canh Bắn Đá, chế tạo Kiếm Sắt và Cầu Giga",
		"req_turrets": 1,
		"req_mega_spheres": 2,
		"reward": "Mở khóa Bệ Triệu Hồi Boss & Đao Thần Long",
		"unlock_level": 5
	},
	{
		"title": "Giai Đoạn 5: Chúa Tể Paloria",
		"desc": "Dựng Bệ Triệu Hồi, thức tỉnh và tiêu diệt Hỏa Long Thần!",
		"req_boss": 1,
		"reward": "Hoàn thành cốt truyện & Danh hiệu Thần Vương",
		"unlock_level": 5
	}
]

func check_quest_progress(player: CharacterBody2D) -> void:
	if current_quest_idx >= quests.size():
		return
	
	var q = quests[current_quest_idx]
	var complete = true
	var progress_parts: Array[String] = []
	
	if q.has("req_wood"):
		var w = player.inventory.get("Gỗ", 0)
		progress_parts.append("Gỗ: %d/%d" % [w, q["req_wood"]])
		if w < q["req_wood"]: complete = false
	
	if q.has("req_stone"):
		var s = player.inventory.get("Đá", 0)
		progress_parts.append("Đá: %d/%d" % [s, q["req_stone"]])
		if s < q["req_stone"]: complete = false
	
	if q.has("req_pets"):
		var pet_count = get_tree().get_nodes_in_group("companion_pets").size()
		progress_parts.append("Pet: %d/%d" % [pet_count, q["req_pets"]])
		if pet_count < q["req_pets"]: complete = false
	
	if q.has("req_iron"):
		var iron = player.inventory.get("Thỏi Sắt", 0)
		progress_parts.append("Thỏi Sắt: %d/%d" % [iron, q["req_iron"]])
		if iron < q["req_iron"]: complete = false
	
	if q.has("req_fertilizer"):
		var fert = player.inventory.get("Phân Bón Hữu Cơ Pal", 0)
		progress_parts.append("Phân Bón: %d/%d" % [fert, q["req_fertilizer"]])
		if fert < q["req_fertilizer"]: complete = false
	
	if q.has("req_pal_ingot"):
		var pal = player.inventory.get("Thỏi Pal", 0)
		progress_parts.append("Thỏi Pal: %d/%d" % [pal, q["req_pal_ingot"]])
		if pal < q["req_pal_ingot"]: complete = false
	
	if q.has("req_berries"):
		var b = player.inventory.get("Quả Mọng Hồi Máu", 0)
		progress_parts.append("Quả Mọng: %d/%d" % [b, q["req_berries"]])
		if b < q["req_berries"]: complete = false
	
	if q.has("req_turrets"):
		var t = get_tree().get_nodes_in_group("turrets").size()
		progress_parts.append("Tháp Thủ: %d/%d" % [t, q["req_turrets"]])
		if t < q["req_turrets"]: complete = false
	
	var progress_str = " | ".join(progress_parts)
	emit_signal("quest_updated", q["title"], q["desc"], progress_str)
	
	if complete and not quest_completed:
		advance_quest(player)

func advance_quest(player: CharacterBody2D) -> void:
	quest_completed = true
	var q = quests[current_quest_idx]
	base_level = q["unlock_level"]
	emit_signal("base_level_changed", base_level)
	
	if AudioManager:
		AudioManager.play_sound("level_up")
	
	var huds = get_tree().get_nodes_in_group("hud")
	if huds.size() > 0:
		huds[0].show_banner("🎉 HOÀN THÀNH: %s!\nCĂN CỨ ĐẠT CẤP %d - %s" % [q["title"], base_level, q["reward"]], 6.5)
	
	# Add bonus EXP to player
	if player.has_method("add_exp"):
		player.add_exp(120 * base_level)
	
	current_quest_idx += 1
	quest_completed = false
