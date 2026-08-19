extends "res://scripts/game_v23_balance.gd"

func _show_main_menu() -> void:
    super._show_main_menu()
    if not is_instance_valid(hud):
        return
    for child in hud.get_children():
        if child is Label:
            if child.text == "ANDROID • v2.2":
                child.text = "ANDROID • v2.3"
            elif child.text == "60 HARİTA EŞİĞİ • İLK DÖNEM FİNALİ":
                child.text = "v2.3 • OYNANIŞ DENGE / HATA TARAMASI"
            elif child.text.begins_with("v2.2 GELİŞTİRMELER"):
                child.text = "v2.3 OYNANIŞ DÜZELTMELERİ\n\n• 1-3 ve 3-3 geçilebilirlik düzeltmesi\n• Chase duvarlarına global hız sınırı\n• Trap / platform / ters kontrol dengelemesi\n• 60 harita otomatik doğrulama testi"

func _build_hud() -> void:
    super._build_hud()
    if not is_instance_valid(hud):
        return
    var badge := Label.new()
    badge.position = Vector2(620, 18)
    badge.size = Vector2(115, 28)
    badge.text = "DENGE v2.3"
    badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    badge.add_theme_font_size_override("font_size", 11)
    badge.add_theme_color_override("font_color", V23_CYAN)
    hud.add_child(badge)
