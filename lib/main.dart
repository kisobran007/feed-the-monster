import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';

part 'app/game_shell.dart';
part 'game/monster_tap_game.dart';
part 'game/models/game_world.dart';
part 'game/models/accessory_item.dart';
part 'game/components/monster.dart';
part 'game/components/falling_item.dart';
part 'game/effects/tap_burst.dart';
part 'game/overlays/world_transition_overlay.dart';
part 'game/components/score_display.dart';
part 'game/components/game_over_display.dart';

void main() {
  runApp(const GameApp());
}
