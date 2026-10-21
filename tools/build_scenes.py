"""
tools/build_scenes.py
Builds all Godot 4.x .tscn scene files cleanly and accurately.
"""

import os

scenes_to_create = {}

# 1. BanditPlayer.tscn
scenes_to_create["scenes/player/BanditPlayer.tscn"] = """[gd_scene load_steps=6 format=3]

[ext_resource type="Script" path="res://scripts/player/bandit_player.gd" id="1_player"]
[ext_resource type="Texture2D" path="res://assets/sprites/bandit_sheet.png" id="2_sheet"]
[ext_resource type="Texture2D" path="res://assets/sprites/bag_light.png" id="3_bag"]

[sub_resource type="CircleShape2D" id="CircleShape2D_player"]
radius = 16.0

[sub_resource type="CircleShape2D" id="CircleShape2D_interact"]
radius = 48.0

[node name="BanditPlayer" type="CharacterBody2D" groups=["player"]]
collision_layer = 2
collision_mask = 5
script = ExtResource("1_player")

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("CircleShape2D_player")

[node name="Sprite2D" type="Sprite2D" parent="."]
texture = ExtResource("2_sheet")
hframes = 4
vframes = 4
frame = 4

[node name="BagSprite" type="Sprite2D" parent="."]
texture = ExtResource("3_bag")
position = Vector2(0, 10)

[node name="InteractionArea" type="Area2D" parent="."]
collision_layer = 0
collision_mask = 4

[node name="CollisionShape2D" type="CollisionShape2D" parent="InteractionArea"]
shape = SubResource("CircleShape2D_interact")

[node name="PromptLabel" type="Label" parent="."]
offset_left = -90.0
offset_top = -48.0
offset_right = 90.0
offset_bottom = -25.0
horizontal_alignment = 1

[node name="InteractProgress" type="ProgressBar" parent="."]
offset_left = -24.0
offset_top = 22.0
offset_right = 24.0
offset_bottom = 28.0
show_percentage = false
"""

# 2. GuardBase.tscn
scenes_to_create["scenes/guards/GuardBase.tscn"] = """[gd_scene load_steps=6 format=3]

[ext_resource type="Script" path="res://scripts/guards/guard_base.gd" id="1_guard"]
[ext_resource type="Texture2D" path="res://assets/sprites/guard_rookie.png" id="2_tex"]
[ext_resource type="Texture2D" path="res://assets/sprites/light_cone_smooth.png" id="3_cone"]

[sub_resource type="CircleShape2D" id="CircleShape2D_guard"]
radius = 16.0

[sub_resource type="CircleShape2D" id="CircleShape2D_catch"]
radius = 22.0

[node name="GuardBase" type="CharacterBody2D" groups=["guards"]]
collision_layer = 4
collision_mask = 3
script = ExtResource("1_guard")

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("CircleShape2D_guard")

[node name="Sprite2D" type="Sprite2D" parent="."]
texture = ExtResource("2_tex")
hframes = 4

[node name="LightCone" type="PointLight2D" parent="."]
position = Vector2(12, 0)
shadow_enabled = true
shadow_filter = 1
shadow_filter_smooth = 1.5
texture = ExtResource("3_cone")
offset = Vector2(120, 0)

[node name="CatchArea" type="Area2D" parent="."]
collision_layer = 0
collision_mask = 2

[node name="CollisionShape2D" type="CollisionShape2D" parent="CatchArea"]
shape = SubResource("CircleShape2D_catch")

[node name="SuspicionBar" type="ProgressBar" parent="."]
offset_left = -20.0
offset_top = -32.0
offset_right = 20.0
offset_bottom = -26.0
show_percentage = false

[node name="StateIcon" type="Label" parent="."]
offset_left = -20.0
offset_top = -54.0
offset_right = 20.0
offset_bottom = -28.0
horizontal_alignment = 1

[connection signal="body_entered" from="CatchArea" to="." method="_on_catch_area_body_entered"]
"""

# 3. MasterKey.tscn
scenes_to_create["scenes/objects/MasterKey.tscn"] = """[gd_scene load_steps=5 format=3]

[ext_resource type="Script" path="res://scripts/objects/master_key.gd" id="1_key"]
[ext_resource type="Texture2D" path="res://assets/sprites/master_key.png" id="2_tex"]
[ext_resource type="Texture2D" path="res://assets/sprites/light_radial_soft.png" id="3_glow"]

[sub_resource type="CircleShape2D" id="CircleShape2D_key"]
radius = 24.0

[node name="MasterKey" type="Area2D"]
collision_layer = 8
collision_mask = 2
script = ExtResource("1_key")

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("CircleShape2D_key")

[node name="Sprite2D" type="Sprite2D" parent="."]
texture = ExtResource("2_tex")

[node name="PointLight2D" type="PointLight2D" parent="."]
color = Color(1, 0.9, 0.3, 1)
energy = 1.2
texture = ExtResource("3_glow")
texture_scale = 0.6
"""

# 4. CoinPickup.tscn
scenes_to_create["scenes/objects/CoinPickup.tscn"] = """[gd_scene load_steps=4 format=3]

[ext_resource type="Script" path="res://scripts/objects/coin_pickup.gd" id="1_coin"]
[ext_resource type="Texture2D" path="res://assets/sprites/coin_gold.png" id="2_tex"]

[sub_resource type="CircleShape2D" id="CircleShape2D_coin"]
radius = 16.0

[node name="CoinPickup" type="Area2D"]
collision_layer = 8
collision_mask = 2
script = ExtResource("1_coin")

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("CircleShape2D_coin")

[node name="Sprite2D" type="Sprite2D" parent="."]
texture = ExtResource("2_tex")
"""

# 5. ShutterDoor.tscn
scenes_to_create["scenes/objects/ShutterDoor.tscn"] = """[gd_scene load_steps=4 format=3]

[ext_resource type="Script" path="res://scripts/objects/shutter_door.gd" id="1_shutter"]
[ext_resource type="Texture2D" path="res://assets/sprites/shutter_door.png" id="2_tex"]

[sub_resource type="RectangleShape2D" id="RectangleShape2D_shut"]
size = Vector2(64, 64)

[node name="ShutterDoor" type="StaticBody2D"]
collision_layer = 1
collision_mask = 6
script = ExtResource("1_shutter")

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("RectangleShape2D_shut")

[node name="Sprite2D" type="Sprite2D" parent="."]
texture = ExtResource("2_tex")
hframes = 3
"""

# 6. VentGrate.tscn
scenes_to_create["scenes/objects/VentGrate.tscn"] = """[gd_scene load_steps=4 format=3]

[ext_resource type="Script" path="res://scripts/objects/vent_grate.gd" id="1_vent"]
[ext_resource type="Texture2D" path="res://assets/sprites/vent_grate.png" id="2_tex"]

[sub_resource type="RectangleShape2D" id="RectangleShape2D_vent"]
size = Vector2(64, 64)

[node name="VentGrate" type="StaticBody2D"]
collision_layer = 5
collision_mask = 6
script = ExtResource("1_vent")

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("RectangleShape2D_vent")

[node name="Sprite2D" type="Sprite2D" parent="."]
texture = ExtResource("2_tex")
hframes = 2
"""

# 7. ExitVaultDoor.tscn
scenes_to_create["scenes/objects/ExitVaultDoor.tscn"] = """[gd_scene load_steps=4 format=3]

[ext_resource type="Script" path="res://scripts/objects/exit_vault_door.gd" id="1_exit"]
[ext_resource type="Texture2D" path="res://assets/sprites/exit_vault_door.png" id="2_tex"]

[sub_resource type="RectangleShape2D" id="RectangleShape2D_vault"]
size = Vector2(64, 64)

[node name="ExitVaultDoor" type="Area2D"]
collision_layer = 8
collision_mask = 2
script = ExtResource("1_exit")

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("RectangleShape2D_vault")

[node name="Sprite2D" type="Sprite2D" parent="."]
texture = ExtResource("2_tex")
hframes = 2
"""

# 8. LockerHideout.tscn
scenes_to_create["scenes/objects/LockerHideout.tscn"] = """[gd_scene load_steps=4 format=3]

[ext_resource type="Script" path="res://scripts/objects/locker_hideout.gd" id="1_locker"]
[ext_resource type="Texture2D" path="res://assets/sprites/locker_hideout.png" id="2_tex"]

[sub_resource type="RectangleShape2D" id="RectangleShape2D_lock"]
size = Vector2(64, 64)

[node name="LockerHideout" type="Area2D"]
collision_layer = 8
collision_mask = 2
script = ExtResource("1_locker")

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("RectangleShape2D_lock")

[node name="Sprite2D" type="Sprite2D" parent="."]
texture = ExtResource("2_tex")

[node name="PromptLabel" type="Label" parent="."]
offset_left = -60.0
offset_top = -45.0
offset_right = 60.0
offset_bottom = -22.0
horizontal_alignment = 1
"""

# 9. ProceduralLevel.tscn
scenes_to_create["scenes/world/ProceduralLevel.tscn"] = """[gd_scene load_steps=4 format=3]

[ext_resource type="Script" path="res://scripts/systems/procedural_level.gd" id="1_level"]
[ext_resource type="Script" path="res://scripts/systems/lockdown_manager.gd" id="2_lockdown"]
[ext_resource type="Texture2D" path="res://assets/sprites/master_key.png" id="3_key_tex"]

[node name="ProceduralLevel" type="Node2D"]
script = ExtResource("1_level")

[node name="CanvasModulate" type="CanvasModulate" parent="."]
color = Color(0.07, 0.15, 0.25, 1)

[node name="Floors" type="Node2D" parent="."]

[node name="Walls" type="Node2D" parent="."]

[node name="Objects" type="Node2D" parent="."]

[node name="Guards" type="Node2D" parent="."]

[node name="ChalkHints" type="Node2D" parent="."]

[node name="Camera2D" type="Camera2D" parent="."]
zoom = Vector2(1.2, 1.2)
position_smoothing_enabled = true
position_smoothing_speed = 8.0

[node name="LockdownManager" type="Node2D" parent="." node_paths=PackedStringArray("canvas_modulate", "level_camera")]
script = ExtResource("2_lockdown")
canvas_modulate = NodePath("../CanvasModulate")
level_camera = NodePath("../Camera2D")

[node name="HUD" type="CanvasLayer" parent="."]

[node name="TopBar" type="HBoxContainer" parent="HUD"]
anchors_preset = 10
anchor_right = 1.0
offset_left = 20.0
offset_top = 16.0
offset_right = -20.0
offset_bottom = 56.0
grow_horizontal = 2
theme_override_constants/separation = 24

[node name="FloorLabel" type="Label" parent="HUD/TopBar"]
layout_mode = 2
text = "FLOOR 01"

[node name="CoinLabel" type="Label" parent="HUD/TopBar"]
layout_mode = 2
text = "LOOT: 0 / 20"

[node name="TimerLabel" type="Label" parent="HUD/TopBar"]
layout_mode = 2
text = "00:00"

[node name="CuffsLabel" type="Label" parent="HUD/TopBar"]
layout_mode = 2
text = "CUFFS: 1"

[node name="KeyIcon" type="TextureRect" parent="HUD/TopBar"]
custom_minimum_size = Vector2(32, 32)
layout_mode = 2
texture = ExtResource("3_key_tex")
expand_mode = 1
stretch_mode = 5

[node name="BtnPause" type="Button" parent="HUD/TopBar"]
custom_minimum_size = Vector2(80, 32)
layout_mode = 2
text = "PAUSE"

[node name="LockdownBanner" type="Panel" parent="HUD"]
anchors_preset = 14
anchor_top = 0.5
anchor_right = 1.0
anchor_bottom = 0.5
offset_top = -40.0
offset_bottom = 40.0
grow_horizontal = 2
grow_vertical = 2

[node name="Label" type="Label" parent="HUD/LockdownBanner"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
theme_override_colors/font_color = Color(1, 0.2, 0.2, 1)
theme_override_font_sizes/font_size = 28
text = "LOCKDOWN INITIATED — ESCAPE TO THE VAULT!"
horizontal_alignment = 1
vertical_alignment = 1

[node name="TouchControls" type="Control" parent="HUD"]
visible = false
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2

[connection signal="pressed" from="HUD/TopBar/BtnPause" to="." method="_on_pause_button_pressed"]
"""

# 10. LoadingScreen.tscn
scenes_to_create["scenes/ui/LoadingScreen.tscn"] = """[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/ui/loading_screen.gd" id="1_load"]

[node name="LoadingScreen" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
script = ExtResource("1_load")

[node name="ColorRect" type="ColorRect" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
color = Color(0.06, 0.12, 0.2, 1)

[node name="CenterContainer" type="CenterContainer" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2

[node name="VBoxContainer" type="VBoxContainer" parent="CenterContainer"]
custom_minimum_size = Vector2(600, 0)
layout_mode = 2
theme_override_constants/separation = 16

[node name="FloorLabel" type="Label" parent="CenterContainer/VBoxContainer"]
layout_mode = 2
theme_override_font_sizes/font_size = 26
text = "UNROLLING BLUEPRINT — FLOOR 01"
horizontal_alignment = 1

[node name="SpecsLabel" type="Label" parent="CenterContainer/VBoxContainer"]
layout_mode = 2
theme_override_colors/font_color = Color(0.4, 0.8, 1, 1)
text = "GRID: 21x21 | SEED: #1337"
horizontal_alignment = 1

[node name="ProgressBar" type="ProgressBar" parent="CenterContainer/VBoxContainer"]
custom_minimum_size = Vector2(0, 20)
layout_mode = 2
value = 45.0
show_percentage = false

[node name="TipLabel" type="Label" parent="CenterContainer/VBoxContainer"]
custom_minimum_size = Vector2(500, 40)
layout_mode = 2
theme_override_colors/font_color = Color(0.8, 0.85, 0.9, 0.8)
text = "Tip: Sneaking emits ZERO noise ripples, even on creaky floorboards."
horizontal_alignment = 1
autowrap_mode = 2
"""

# 11. MainMenu.tscn
scenes_to_create["scenes/ui/MainMenu.tscn"] = """[gd_scene load_steps=5 format=3]

[ext_resource type="Script" path="res://scripts/ui/main_menu.gd" id="1_menu"]
[ext_resource type="Texture2D" path="res://assets/sprites/light_cone_smooth.png" id="2_cone"]
[ext_resource type="Texture2D" path="res://assets/sprites/bandit_sheet.png" id="3_bandit"]
[ext_resource type="Texture2D" path="res://assets/ui/portrait_bandit.png" id="4_portrait"]

[node name="MainMenu" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
script = ExtResource("1_menu")

[node name="Background" type="ColorRect" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
color = Color(0.05, 0.1, 0.18, 1)

[node name="FlashlightBeams" type="Node2D" parent="Background"]
position = Vector2(200, 200)

[node name="Cone" type="Sprite2D" parent="Background/FlashlightBeams"]
modulate = Color(1, 0.95, 0.7, 0.35)
texture = ExtResource("2_cone")
offset = Vector2(180, 0)

[node name="BanditPeek" type="Sprite2D" parent="Background"]
position = Vector2(1050, 520)
scale = Vector2(2, 2)
texture = ExtResource("3_bandit")
hframes = 4
vframes = 4
frame = 12

[node name="TitleBox" type="VBoxContainer" parent="."]
layout_mode = 1
anchors_preset = 5
anchor_left = 0.5
anchor_right = 0.5
offset_left = -350.0
offset_top = 40.0
offset_right = 350.0
offset_bottom = 140.0
grow_horizontal = 2

[node name="Title" type="Label" parent="TitleBox"]
layout_mode = 2
theme_override_colors/font_color = Color(0, 0.9, 1, 1)
theme_override_font_sizes/font_size = 42
text = "LOCKDOWN HEIST: BANDIT"
horizontal_alignment = 1

[node name="Tagline" type="Label" parent="TitleBox"]
layout_mode = 2
theme_override_colors/font_color = Color(0.8, 0.85, 0.95, 1)
theme_override_font_sizes/font_size = 18
text = "Steal the Key. Outsmart the Light. Escape the Lockdown."
horizontal_alignment = 1

[node name="VBoxContainer" type="VBoxContainer" parent="."]
layout_mode = 1
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -160.0
offset_top = -120.0
offset_right = 160.0
offset_bottom = 260.0
grow_horizontal = 2
grow_vertical = 2
theme_override_constants/separation = 12

[node name="BtnCampaign" type="Button" parent="VBoxContainer"]
custom_minimum_size = Vector2(0, 44)
layout_mode = 2
text = "PLAY CAMPAIGN"

[node name="BtnDaily" type="Button" parent="VBoxContainer"]
custom_minimum_size = Vector2(0, 44)
layout_mode = 2
text = "DAILY HEIST (DATE SEED)"

[node name="BtnCustom" type="Button" parent="VBoxContainer"]
custom_minimum_size = Vector2(0, 44)
layout_mode = 2
text = "CUSTOM SEED HEIST"

[node name="BtnHideout" type="Button" parent="VBoxContainer"]
custom_minimum_size = Vector2(0, 44)
layout_mode = 2
text = "THE HIDEOUT (SHOP)"

[node name="BtnManual" type="Button" parent="VBoxContainer"]
custom_minimum_size = Vector2(0, 44)
layout_mode = 2
text = "BANDIT'S FIELD MANUAL"

[node name="BtnSettings" type="Button" parent="VBoxContainer"]
custom_minimum_size = Vector2(0, 44)
layout_mode = 2
text = "SETTINGS"

[node name="BtnQuit" type="Button" parent="VBoxContainer"]
custom_minimum_size = Vector2(0, 44)
layout_mode = 2
text = "QUIT"

[node name="CustomSeedDialog" type="ConfirmationDialog" parent="."]
title = "Enter Custom Seed"
size = Vector2i(350, 140)

[node name="VBox" type="VBoxContainer" parent="CustomSeedDialog"]
offset_left = 8.0
offset_top = 8.0
offset_right = 342.0
offset_bottom = 91.0

[node name="Label" type="Label" parent="CustomSeedDialog/VBox"]
layout_mode = 2
text = "Seed Number or Word:"

[node name="SeedInput" type="LineEdit" parent="CustomSeedDialog/VBox"]
layout_mode = 2
placeholder_text = "e.g. 1337 or SHADOW"
"""

# 12. HowToPlayModal.tscn
scenes_to_create["scenes/ui/HowToPlayModal.tscn"] = """[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/ui/how_to_play_modal.gd" id="1_ht"]

[node name="HowToPlayModal" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
script = ExtResource("1_ht")

[node name="Dim" type="ColorRect" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
color = Color(0, 0, 0, 0.7)

[node name="Panel" type="Panel" parent="."]
layout_mode = 1
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -460.0
offset_top = -280.0
offset_right = 460.0
offset_bottom = 280.0
grow_horizontal = 2
grow_vertical = 2

[node name="Title" type="Label" parent="Panel"]
layout_mode = 1
anchors_preset = 10
anchor_right = 1.0
offset_top = 16.0
offset_bottom = 44.0
grow_horizontal = 2
theme_override_colors/font_color = Color(0, 0.9, 1, 1)
theme_override_font_sizes/font_size = 22
text = "BANDIT'S FIELD MANUAL"
horizontal_alignment = 1

[node name="TabContainer" type="TabContainer" parent="Panel"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
offset_left = 24.0
offset_top = 56.0
offset_right = -24.0
offset_bottom = -60.0
grow_horizontal = 2
grow_vertical = 2

[node name="1. Two Phases" type="VBoxContainer" parent="Panel/TabContainer"]
layout_mode = 2
theme_override_constants/separation = 12

[node name="Desc" type="Label" parent="Panel/TabContainer/1. Two Phases"]
layout_mode = 2
text = "1. INFILTRATION: The maze is calm. Shutters are open, vents are closed. Study guard patrol cones, collect loot, and reach the Master Key.

2. CRIMSON LOCKDOWN: Touching the Master Key triggers instant lockdown sirens! Shutters slam shut, green vents unlock, guards speed up +30%, and the Key Transponder pings your location every 8 seconds. Escape through the Vault Door!"
autowrap_mode = 2

[node name="2. Light & Sound" type="VBoxContainer" parent="Panel/TabContainer"]
visible = false
layout_mode = 2
theme_override_constants/separation = 12

[node name="Desc" type="Label" parent="Panel/TabContainer/2. Light & Sound"]
layout_mode = 2
text = "FLASH CONES & SUSPICION:
- Flashlights cast real wall shadows. Glimpsing the edge fills the [?] meter in 0.40s.
- Point-blank detection triggers [!] CHASE in 0.12s!
- Break line-of-sight behind walls to escape chase.

SOUND RIPPLES:
- Sneak (Silent): 0 px noise radius.
- Walk: 34 px soft step.
- Sprint: 110 px loud ring + Loot Bag jingle! Guard will investigate noise rings."
autowrap_mode = 2

[node name="3. Thief Tools" type="VBoxContainer" parent="Panel/TabContainer"]
visible = false
layout_mode = 2
theme_override_constants/separation = 12

[node name="Desc" type="Label" parent="Panel/TabContainer/3. Thief Tools"]
layout_mode = 2
text = "BACK-ONLY INTERACTIONS (Approach guard from behind):
- Tap [E]: Non-lethal Knockout! Drops +3 coins, knocks guard out for 35s (Zzz timer).
- Tap [E] on Sleeping Guard: Spend 1 Zip-Tie to CUFF them permanently!
- Hold [E] (0.6s) on Unaware Guard: Master Pickpocket steals +6 coins cleanly without raising alarm!"
autowrap_mode = 2

[node name="4. Greed Bag" type="VBoxContainer" parent="Panel/TabContainer"]
visible = false
layout_mode = 2
theme_override_constants/separation = 12

[node name="Desc" type="Label" parent="Panel/TabContainer/4. Greed Bag"]
layout_mode = 2
text = "THE GREED BAG RULE:
- Unbanked coins are ONLY saved if you reach the exit alive! Getting caught loses all level loot.
- Weight Slowdown:
    0-14 Coins: Light (100% speed)
    15-34 Coins: Medium (-6% speed)
    35+ Coins: Heavy (-12% speed)
- Coin Toss [Q]: Throw 1 coin to clink on the floor and distract guards away from your path!"
autowrap_mode = 2

[node name="5. Controls" type="VBoxContainer" parent="Panel/TabContainer"]
visible = false
layout_mode = 2
theme_override_constants/separation = 12

[node name="Desc" type="Label" parent="Panel/TabContainer/5. Controls"]
layout_mode = 2
text = "KEYBOARD & MOUSE:
- WASD / Arrow Keys: Move
- Shift: Sprint (Hold)
- E: Interact / Knockout / Cuff / Pickpocket
- Q: Toss Distraction Coin
- F: Use Equipped Gadget
- Esc: Pause Game

GAMEPAD (Xbox / PlayStation):
- Left Stick / D-Pad: Move
- RT / R2: Sprint
- A / Cross: Interact
- X / Square: Toss Coin
- RB / R1: Gadget
- Start: Pause"
autowrap_mode = 2

[node name="BtnClose" type="Button" parent="Panel"]
custom_minimum_size = Vector2(140, 36)
layout_mode = 1
anchors_preset = 7
anchor_left = 0.5
anchor_top = 1.0
anchor_right = 0.5
anchor_bottom = 1.0
offset_left = -70.0
offset_top = -48.0
offset_right = 70.0
offset_bottom = -12.0
grow_horizontal = 2
grow_vertical = 0
text = "CLOSE MANUAL"
"""

# 13. HideoutModal.tscn
scenes_to_create["scenes/ui/HideoutModal.tscn"] = """[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/ui/hideout_modal.gd" id="1_ho"]

[node name="HideoutModal" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
script = ExtResource("1_ho")

[node name="Dim" type="ColorRect" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
color = Color(0, 0, 0, 0.75)

[node name="Panel" type="Panel" parent="."]
layout_mode = 1
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -440.0
offset_top = -270.0
offset_right = 440.0
offset_bottom = 270.0
grow_horizontal = 2
grow_vertical = 2

[node name="Header" type="HBoxContainer" parent="Panel"]
layout_mode = 1
anchors_preset = 10
anchor_right = 1.0
offset_left = 32.0
offset_top = 20.0
offset_right = -32.0
offset_bottom = 54.0
grow_horizontal = 2

[node name="Title" type="Label" parent="Panel/Header"]
layout_mode = 2
size_flags_horizontal = 3
theme_override_colors/font_color = Color(0, 0.9, 1, 1)
theme_override_font_sizes/font_size = 22
text = "THE HIDEOUT — UPGRADES & SUITS"

[node name="BankedLabel" type="Label" parent="Panel/Header"]
layout_mode = 2
theme_override_colors/font_color = Color(1, 0.85, 0.2, 1)
text = "VAULT: 0 COINS"

[node name="StarsLabel" type="Label" parent="Panel/Header"]
layout_mode = 2
theme_override_colors/font_color = Color(0.9, 0.9, 1, 1)
text = "STARS: 0"

[node name="Grid" type="GridContainer" parent="Panel"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
offset_left = 32.0
offset_top = 70.0
offset_right = -32.0
offset_bottom = -60.0
grow_horizontal = 2
grow_vertical = 2
theme_override_constants/h_separation = 24
theme_override_constants/v_separation = 16
columns = 2

[node name="SuitClassic" type="VBoxContainer" parent="Panel/Grid"]
layout_mode = 2
size_flags_horizontal = 3

[node name="Label" type="Label" parent="Panel/Grid/SuitClassic"]
layout_mode = 2
text = "Classic Bandit Suit (Default)"

[node name="Btn" type="Button" parent="Panel/Grid/SuitClassic"]
layout_mode = 2
text = "EQUIPPED"

[node name="SuitVelvet" type="VBoxContainer" parent="Panel/Grid"]
layout_mode = 2
size_flags_horizontal = 3

[node name="Label" type="Label" parent="Panel/Grid/SuitVelvet"]
layout_mode = 2
text = "Velvet Paws (-35% Noise)"

[node name="Btn" type="Button" parent="Panel/Grid/SuitVelvet"]
layout_mode = 2
text = "BUY (50)"

[node name="SuitSilk" type="VBoxContainer" parent="Panel/Grid"]
layout_mode = 2
size_flags_horizontal = 3

[node name="Label" type="Label" parent="Panel/Grid/SuitSilk"]
layout_mode = 2
text = "Silk Sack (+25% Bag Capacity)"

[node name="Btn" type="Button" parent="Panel/Grid/SuitSilk"]
layout_mode = 2
text = "BUY (80)"

[node name="SuitSprinter" type="VBoxContainer" parent="Panel/Grid"]
layout_mode = 2
size_flags_horizontal = 3

[node name="Label" type="Label" parent="Panel/Grid/SuitSprinter"]
layout_mode = 2
text = "Lockdown Sprinter (+10% Escape Speed)"

[node name="Btn" type="Button" parent="Panel/Grid/SuitSprinter"]
layout_mode = 2
text = "BUY (120)"

[node name="GadgetSmoke" type="VBoxContainer" parent="Panel/Grid"]
layout_mode = 2
size_flags_horizontal = 3

[node name="Label" type="Label" parent="Panel/Grid/GadgetSmoke"]
layout_mode = 2
text = "Smoke Pellet (Blinds Guards)"

[node name="Btn" type="Button" parent="Panel/Grid/GadgetSmoke"]
layout_mode = 2
text = "BUY (40)"

[node name="GadgetCuff" type="VBoxContainer" parent="Panel/Grid"]
layout_mode = 2
size_flags_horizontal = 3

[node name="Label" type="Label" parent="Panel/Grid/GadgetCuff"]
layout_mode = 2
text = "Extra Zip-Tie (+1 Free Cuff)"

[node name="Btn" type="Button" parent="Panel/Grid/GadgetCuff"]
layout_mode = 2
text = "BUY (60)"

[node name="GadgetMarbles" type="VBoxContainer" parent="Panel/Grid"]
layout_mode = 2
size_flags_horizontal = 3

[node name="Label" type="Label" parent="Panel/Grid/GadgetMarbles"]
layout_mode = 2
text = "Bag of Marbles (Trips Heavy Guards)"

[node name="Btn" type="Button" parent="Panel/Grid/GadgetMarbles"]
layout_mode = 2
text = "BUY (70)"

[node name="GadgetFaraday" type="VBoxContainer" parent="Panel/Grid"]
layout_mode = 2
size_flags_horizontal = 3

[node name="Label" type="Label" parent="Panel/Grid/GadgetFaraday"]
layout_mode = 2
text = "Faraday Pouch (+5s Radar Delay)"

[node name="Btn" type="Button" parent="Panel/Grid/GadgetFaraday"]
layout_mode = 2
text = "BUY (100)"

[node name="BtnClose" type="Button" parent="Panel"]
custom_minimum_size = Vector2(140, 36)
layout_mode = 1
anchors_preset = 7
anchor_left = 0.5
anchor_top = 1.0
anchor_right = 0.5
anchor_bottom = 1.0
offset_left = -70.0
offset_top = -48.0
offset_right = 70.0
offset_bottom = -12.0
grow_horizontal = 2
grow_vertical = 0
text = "EXIT HIDEOUT"
"""

# 14. SettingsModal.tscn
scenes_to_create["scenes/ui/SettingsModal.tscn"] = """[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/ui/settings_modal.gd" id="1_set"]

[node name="SettingsModal" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
script = ExtResource("1_set")

[node name="Dim" type="ColorRect" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
color = Color(0, 0, 0, 0.7)

[node name="Panel" type="Panel" parent="."]
layout_mode = 1
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -320.0
offset_top = -240.0
offset_right = 320.0
offset_bottom = 240.0
grow_horizontal = 2
grow_vertical = 2

[node name="Title" type="Label" parent="Panel"]
layout_mode = 1
anchors_preset = 10
anchor_right = 1.0
offset_top = 18.0
offset_bottom = 44.0
grow_horizontal = 2
theme_override_colors/font_color = Color(0, 0.9, 1, 1)
theme_override_font_sizes/font_size = 20
text = "SETTINGS & ACCESSIBILITY"
horizontal_alignment = 1

[node name="VBox" type="VBoxContainer" parent="Panel"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
offset_left = 36.0
offset_top = 60.0
offset_right = -36.0
offset_bottom = -55.0
grow_horizontal = 2
grow_vertical = 2
theme_override_constants/separation = 10

[node name="LblMaster" type="Label" parent="Panel/VBox"]
layout_mode = 2
text = "Master Volume"

[node name="MasterSlider" type="HSlider" parent="Panel/VBox"]
layout_mode = 2
value = 100.0

[node name="LblMusic" type="Label" parent="Panel/VBox"]
layout_mode = 2
text = "Dual-Stem Music Volume"

[node name="MusicSlider" type="HSlider" parent="Panel/VBox"]
layout_mode = 2
value = 80.0

[node name="LblSFX" type="Label" parent="Panel/VBox"]
layout_mode = 2
text = "SFX Volume"

[node name="SFXSlider" type="HSlider" parent="Panel/VBox"]
layout_mode = 2
value = 90.0

[node name="LblShake" type="Label" parent="Panel/VBox"]
layout_mode = 2
text = "Screen Shake Intensity"

[node name="ShakeSlider" type="HSlider" parent="Panel/VBox"]
layout_mode = 2
value = 100.0

[node name="LblTouch" type="Label" parent="Panel/VBox"]
layout_mode = 2
text = "On-Screen Touch Controls"

[node name="TouchOption" type="OptionButton" parent="Panel/VBox"]
layout_mode = 2

[node name="ColorblindCheck" type="CheckBox" parent="Panel/VBox"]
layout_mode = 2
text = "High Contrast / Colorblind Vision Markers"

[node name="StatsCheck" type="CheckBox" parent="Panel/VBox"]
layout_mode = 2
button_pressed = true
text = "Show Seed & Timers on HUD"

[node name="BtnClose" type="Button" parent="Panel"]
custom_minimum_size = Vector2(120, 34)
layout_mode = 1
anchors_preset = 7
anchor_left = 0.5
anchor_top = 1.0
anchor_right = 0.5
anchor_bottom = 1.0
offset_left = -60.0
offset_top = -44.0
offset_right = 60.0
offset_bottom = -10.0
grow_horizontal = 2
grow_vertical = 0
text = "SAVE & CLOSE"
"""

# 15. PauseMenu.tscn
scenes_to_create["scenes/ui/PauseMenu.tscn"] = """[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/ui/pause_menu.gd" id="1_pm"]

[node name="PauseMenu" type="Control"]
process_mode = 3
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
script = ExtResource("1_pm")

[node name="Dim" type="ColorRect" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
color = Color(0, 0, 0, 0.7)

[node name="Panel" type="Panel" parent="."]
layout_mode = 1
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -180.0
offset_top = -180.0
offset_right = 180.0
offset_bottom = 180.0
grow_horizontal = 2
grow_vertical = 2

[node name="Title" type="Label" parent="Panel"]
layout_mode = 1
anchors_preset = 10
anchor_right = 1.0
offset_top = 16.0
offset_bottom = 44.0
grow_horizontal = 2
theme_override_colors/font_color = Color(0, 0.9, 1, 1)
theme_override_font_sizes/font_size = 22
text = "HEIST PAUSED"
horizontal_alignment = 1

[node name="VBox" type="VBoxContainer" parent="Panel"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
offset_left = 32.0
offset_top = 60.0
offset_right = -32.0
offset_bottom = -20.0
grow_horizontal = 2
grow_vertical = 2
theme_override_constants/separation = 12

[node name="BtnResume" type="Button" parent="Panel/VBox"]
custom_minimum_size = Vector2(0, 40)
layout_mode = 2
text = "RESUME HEIST"

[node name="BtnManual" type="Button" parent="Panel/VBox"]
custom_minimum_size = Vector2(0, 40)
layout_mode = 2
text = "FIELD MANUAL"

[node name="BtnSettings" type="Button" parent="Panel/VBox"]
custom_minimum_size = Vector2(0, 40)
layout_mode = 2
text = "SETTINGS"

[node name="BtnRestart" type="Button" parent="Panel/VBox"]
custom_minimum_size = Vector2(0, 40)
layout_mode = 2
text = "RESTART LEVEL"

[node name="BtnMenu" type="Button" parent="Panel/VBox"]
custom_minimum_size = Vector2(0, 40)
layout_mode = 2
text = "MAIN MENU"
"""

# 16. LevelComplete.tscn
scenes_to_create["scenes/ui/LevelComplete.tscn"] = """[gd_scene load_steps=5 format=3]

[ext_resource type="Script" path="res://scripts/ui/level_complete.gd" id="1_comp"]
[ext_resource type="Texture2D" path="res://assets/ui/star_filled.png" id="2_star"]
[ext_resource type="Texture2D" path="res://assets/ui/ribbon_ghost.png" id="3_ghost"]
[ext_resource type="Texture2D" path="res://assets/ui/ribbon_cleansweep.png" id="4_sweep"]

[node name="LevelComplete" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
script = ExtResource("1_comp")

[node name="Dim" type="ColorRect" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
color = Color(0, 0, 0, 0.75)

[node name="PaperPanel" type="Panel" parent="."]
layout_mode = 1
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -340.0
offset_top = -240.0
offset_right = 340.0
offset_bottom = 240.0
grow_horizontal = 2
grow_vertical = 2

[node name="PaperHeader" type="Label" parent="PaperPanel"]
layout_mode = 1
anchors_preset = 10
anchor_right = 1.0
offset_top = 16.0
offset_bottom = 40.0
grow_horizontal = 2
theme_override_colors/font_color = Color(0.9, 0.8, 0.5, 1)
theme_override_font_sizes/font_size = 14
text = "— THE DAILY GAZETTE — SPECIAL HEIST EDITION —"
horizontal_alignment = 1

[node name="Headline" type="Label" parent="PaperPanel"]
layout_mode = 1
anchors_preset = 10
anchor_right = 1.0
offset_top = 44.0
offset_bottom = 84.0
grow_horizontal = 2
theme_override_colors/font_color = Color(1, 0.95, 0.8, 1)
theme_override_font_sizes/font_size = 24
text = "BANDIT BAFFLES POLICE ON FLOOR 01!"
horizontal_alignment = 1

[node name="StarsBox" type="HBoxContainer" parent="PaperPanel"]
layout_mode = 1
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -120.0
offset_top = -70.0
offset_right = 120.0
offset_bottom = -10.0
grow_horizontal = 2
grow_vertical = 2
theme_override_constants/separation = 24
alignment = 1

[node name="Star1" type="TextureRect" parent="PaperPanel/StarsBox"]
custom_minimum_size = Vector2(48, 48)
layout_mode = 2
texture = ExtResource("2_star")
expand_mode = 1
stretch_mode = 5

[node name="Star2" type="TextureRect" parent="PaperPanel/StarsBox"]
custom_minimum_size = Vector2(48, 48)
layout_mode = 2
texture = ExtResource("2_star")
expand_mode = 1
stretch_mode = 5

[node name="Star3" type="TextureRect" parent="PaperPanel/StarsBox"]
custom_minimum_size = Vector2(48, 48)
layout_mode = 2
texture = ExtResource("2_star")
expand_mode = 1
stretch_mode = 5

[node name="StatsBox" type="VBoxContainer" parent="PaperPanel"]
layout_mode = 1
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -160.0
offset_top = 10.0
offset_right = 160.0
offset_bottom = 70.0
grow_horizontal = 2
grow_vertical = 2

[node name="LootCount" type="Label" parent="PaperPanel/StatsBox"]
layout_mode = 2
theme_override_colors/font_color = Color(1, 0.85, 0.2, 1)
text = "COINS BANKED: +20 COINS"
horizontal_alignment = 1

[node name="TimeCount" type="Label" parent="PaperPanel/StatsBox"]
layout_mode = 2
text = "ESCAPE TIME: 00:42"
horizontal_alignment = 1

[node name="RibbonsBox" type="HBoxContainer" parent="PaperPanel"]
layout_mode = 1
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -100.0
offset_top = 80.0
offset_right = 100.0
offset_bottom = 124.0
grow_horizontal = 2
grow_vertical = 2
alignment = 1

[node name="RibbonGhost" type="TextureRect" parent="PaperPanel/RibbonsBox"]
custom_minimum_size = Vector2(44, 44)
layout_mode = 2
texture = ExtResource("3_ghost")
expand_mode = 1
stretch_mode = 5

[node name="RibbonSweep" type="TextureRect" parent="PaperPanel/RibbonsBox"]
custom_minimum_size = Vector2(44, 44)
layout_mode = 2
texture = ExtResource("4_sweep")
expand_mode = 1
stretch_mode = 5

[node name="ActionsBox" type="HBoxContainer" parent="PaperPanel"]
layout_mode = 1
anchors_preset = 7
anchor_left = 0.5
anchor_top = 1.0
anchor_right = 0.5
anchor_bottom = 1.0
offset_left = -220.0
offset_top = -60.0
offset_right = 220.0
offset_bottom = -16.0
grow_horizontal = 2
grow_vertical = 0
theme_override_constants/separation = 16
alignment = 1

[node name="BtnNext" type="Button" parent="PaperPanel/ActionsBox"]
custom_minimum_size = Vector2(130, 40)
layout_mode = 2
text = "NEXT FLOOR"

[node name="BtnCopySeed" type="Button" parent="PaperPanel/ActionsBox"]
custom_minimum_size = Vector2(110, 40)
layout_mode = 2
text = "COPY SEED"

[node name="BtnMenu" type="Button" parent="PaperPanel/ActionsBox"]
custom_minimum_size = Vector2(110, 40)
layout_mode = 2
text = "MAIN MENU"
"""

# 17. GameOver.tscn
scenes_to_create["scenes/ui/GameOver.tscn"] = """[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/ui/game_over.gd" id="1_go"]

[node name="GameOver" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
script = ExtResource("1_go")

[node name="Dim" type="ColorRect" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
color = Color(0.1, 0.02, 0.02, 0.88)

[node name="Panel" type="Panel" parent="."]
layout_mode = 1
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -220.0
offset_top = -180.0
offset_right = 220.0
offset_bottom = 180.0
grow_horizontal = 2
grow_vertical = 2

[node name="Title" type="Label" parent="Panel"]
layout_mode = 1
anchors_preset = 10
anchor_right = 1.0
offset_top = 20.0
offset_bottom = 60.0
grow_horizontal = 2
theme_override_colors/font_color = Color(1, 0.2, 0.2, 1)
theme_override_font_sizes/font_size = 32
text = "BUSTED!"
horizontal_alignment = 1

[node name="VBox" type="VBoxContainer" parent="Panel"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
offset_left = 32.0
offset_top = 80.0
offset_right = -32.0
offset_bottom = -24.0
grow_horizontal = 2
grow_vertical = 2
theme_override_constants/separation = 12

[node name="CauseLabel" type="Label" parent="Panel/VBox"]
layout_mode = 2
theme_override_colors/font_color = Color(0.9, 0.8, 0.8, 1)
text = "CAPTURED BY: POLICE ROOKIE!"
horizontal_alignment = 1

[node name="LostLabel" type="Label" parent="Panel/VBox"]
layout_mode = 2
theme_override_colors/font_color = Color(1, 0.7, 0.2, 1)
text = "LOST IN SACK: 18 COINS"
horizontal_alignment = 1

[node name="BtnRetry" type="Button" parent="Panel/VBox"]
custom_minimum_size = Vector2(0, 44)
layout_mode = 2
text = "INSTANT RETRY (0.1s)"

[node name="BtnNewSeed" type="Button" parent="Panel/VBox"]
custom_minimum_size = Vector2(0, 40)
layout_mode = 2
text = "TRY NEW SEED"

[node name="BtnMenu" type="Button" parent="Panel/VBox"]
custom_minimum_size = Vector2(0, 40)
layout_mode = 2
text = "MAIN MENU"
"""

for path, content in scenes_to_create.items():
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        f.write(content)
    print(f"Created {path}")

print("=== ALL SCENES CREATED SUCCESSFULLY ===")
