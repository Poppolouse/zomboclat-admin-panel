import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

part 'models.dart';
part 'api_client.dart';
part 'update_service.dart';
part 'app_shell.dart';
part 'dash_core.dart';
part 'dash_players.dart';
part 'dash_server.dart';
part 'dash_support.dart';
part 'dash_layout.dart';
part 'dash_dashboard.dart';
part 'dash_players_view.dart';
part 'dash_studio_core.dart';
part 'dash_studio_body.dart';
part 'dash_studio_items.dart';
part 'dash_mods.dart';
part 'dash_sandbox.dart';
part 'dash_users.dart';
part 'dash_console.dart';
part 'live_metric_chart.dart';

void main() => runApp(const App());
