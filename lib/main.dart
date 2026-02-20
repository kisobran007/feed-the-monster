import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';

part 'app/game_shell.dart';
part 'app/dialogs/levels_menu_dialog.dart';
part 'app/dialogs/monster_menu_dialog.dart';
part 'app/dialogs/shop_dialog.dart';
part 'app/dialogs/level_complete_dialog.dart';
part 'app/widgets/pause_overlay.dart';
part 'app/widgets/start_overlay.dart';
part 'game/monster_tap_game.dart';
part 'game/models/game_world.dart';
part 'game/models/monster_character.dart';
part 'game/models/accessory_item.dart';
part 'game/models/level_progress.dart';
part 'game/services/objective_engine.dart';
part 'game/services/progress_repository.dart';
part 'game/services/spawn_controller.dart';
part 'game/services/audio_controller.dart';
part 'game/components/monster.dart';
part 'game/components/falling_item.dart';
part 'game/effects/tap_burst.dart';
part 'game/components/objective_display.dart';
part 'game/components/game_over_display.dart';

void main() {
  runApp(const GameApp());
}
