part of 'main.dart';

class AppUser {
  final int id;
  final String username;
  final String role;
  final bool isAdmin;
  final String? createdAt;

  const AppUser({
    required this.id,
    required this.username,
    required this.role,
    required this.isAdmin,
    this.createdAt,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final role = (json['role'] as String? ?? 'OPERATOR').toUpperCase();
    return AppUser(
      id: json['id'] as int? ?? 0,
      username: json['username'] as String? ?? '',
      role: role,
      isAdmin: role == 'ADMIN',
      createdAt: json['created_at'] as String?,
    );
  }
}

class AuditLog {
  final int id;
  final String username;
  final String action;
  final String details;
  final String createdAt;

  const AuditLog({
    required this.id,
    required this.username,
    required this.action,
    required this.details,
    required this.createdAt,
  });

  factory AuditLog.fromJson(Map<String, dynamic> json) {
    return AuditLog(
      id: json['id'] as int? ?? 0,
      username: json['username'] as String? ?? 'Bilinmeyen',
      action: json['action'] as String? ?? 'ACTION',
      details: json['details'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}

class ModErrorGroup {
  final String modId;
  final String modName;
  final String? workshopId;
  final String? previewUrl;
  final List<String> errorLines;

  ModErrorGroup({
    required this.modId,
    required this.modName,
    this.workshopId,
    this.previewUrl,
    required this.errorLines,
  });
}

class GamePlayer {
  final int id;
  final String username;
  final String charName;
  final String? lastConnection;
  final String? steamid;
  final String? steamPersona;
  final String? steamAvatar;
  final String? pixelAvatar;
  final int roleId;
  final String roleName;
  final String? roleDesc;
  final double? posX;
  final double? posY;
  final int? posZ;
  final bool isDead;
  final String profession;
  final List<String> traits;
  final Map<String, int> skills;
  final double hoursSurvived;
  final int zombieKills;
  final double weight;
  final double health;
  final bool isInfected;
  final double hunger;
  final double thirst;
  final double fatigue;
  final double stress;
  final double boredom;
  final List<Map<String, dynamic>> inventory;

  GamePlayer({
    required this.id,
    required this.username,
    required this.charName,
    this.lastConnection,
    this.steamid,
    this.steamPersona,
    this.steamAvatar,
    this.pixelAvatar,
    required this.roleId,
    required this.roleName,
    this.roleDesc,
    this.posX,
    this.posY,
    this.posZ,
    this.isDead = false,
    this.profession = 'unemployed',
    this.traits = const [],
    this.skills = const {},
    this.hoursSurvived = 0.0,
    this.zombieKills = 0,
    this.weight = 80.0,
    this.health = 100.0,
    this.isInfected = false,
    this.hunger = 0.0,
    this.thirst = 0.0,
    this.fatigue = 0.0,
    this.stress = 0.0,
    this.boredom = 0.0,
    this.inventory = const [],
  });

  factory GamePlayer.fromJson(Map<String, dynamic> json) {
    return GamePlayer(
      id: json['id'] as int? ?? 0,
      username: json['username'] as String? ?? '',
      charName: json['char_name'] as String? ?? json['displayName'] as String? ?? json['username'] as String? ?? '',
      lastConnection: json['lastConnection'] as String?,
      steamid: json['steamid'] as String?,
      steamPersona: json['steam_persona'] as String?,
      steamAvatar: json['steam_avatar'] as String?,
      pixelAvatar: json['pixel_avatar'] as String?,
      roleId: json['role_id'] as int? ?? 2,
      roleName: json['role_name'] as String? ?? 'user',
      roleDesc: json['role_desc'] as String?,
      posX: (json['pos_x'] is num) ? (json['pos_x'] as num).toDouble() : null,
      posY: (json['pos_y'] is num) ? (json['pos_y'] as num).toDouble() : null,
      posZ: json['pos_z'] as int?,
      isDead: json['is_dead'] == true,
      profession: json['profession'] as String? ?? 'unemployed',
      traits: (json['traits'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      skills: (json['skills'] as Map<String, dynamic>?)?.map((k, v) => MapEntry(k, (v is num) ? v.toInt() : 0)) ?? {},
      hoursSurvived: (json['hours_survived'] is num) ? (json['hours_survived'] as num).toDouble() : 0.0,
      zombieKills: (json['zombie_kills'] is num) ? (json['zombie_kills'] as num).toInt() : 0,
      weight: (json['weight'] is num) ? (json['weight'] as num).toDouble() : 80.0,
      health: (json['health'] is num) ? (json['health'] as num).toDouble() : 100.0,
      isInfected: json['is_infected'] == true,
      hunger: (json['hunger'] is num) ? (json['hunger'] as num).toDouble() : 0.0,
      thirst: (json['thirst'] is num) ? (json['thirst'] as num).toDouble() : 0.0,
      fatigue: (json['fatigue'] is num) ? (json['fatigue'] as num).toDouble() : 0.0,
      stress: (json['stress'] is num) ? (json['stress'] as num).toDouble() : 0.0,
      boredom: (json['boredom'] is num) ? (json['boredom'] as num).toDouble() : 0.0,
      inventory: (json['inventory'] as List<dynamic>?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [],
    );
  }
}

class GameUserLog {
  final int id;
  final String username;
  final String type;
  final String text;
  final String issuedBy;
  final int amount;
  final String lastUpdate;

  GameUserLog({
    required this.id,
    required this.username,
    required this.type,
    required this.text,
    required this.issuedBy,
    required this.amount,
    required this.lastUpdate,
  });

  factory GameUserLog.fromJson(Map<String, dynamic> json) {
    return GameUserLog(
      id: json['id'] as int? ?? 0,
      username: json['username'] as String? ?? '',
      type: json['type'] as String? ?? '',
      text: json['text'] as String? ?? '',
      issuedBy: json['issuedBy'] as String? ?? '',
      amount: json['amount'] as int? ?? 1,
      lastUpdate: json['lastUpdate'] as String? ?? '',
    );
  }
}

class PzSkillInfo {
  final String id;
  final String name;
  final String cat;
  final IconData icon;
  final bool isMod;
  final String? modName;

  const PzSkillInfo({
    required this.id,
    required this.name,
    required this.cat,
    required this.icon,
    this.isMod = false,
    this.modName,
  });
}

class PzTraitInfo {
  final String id;
  final String name;
  final IconData icon;
  final bool isMod;
  final String? modName;

  const PzTraitInfo({
    required this.id,
    required this.name,
    required this.icon,
    this.isMod = false,
    this.modName,
  });
}

const List<PzSkillInfo> _allPzSkills = [
  // Pasif
  PzSkillInfo(id: 'Fitness', name: 'Fitness', cat: 'Passive', icon: Icons.fitness_center_rounded),
  PzSkillInfo(id: 'Strength', name: 'Strength', cat: 'Passive', icon: Icons.sports_mma_rounded),
  // Ã‡eviklik
  PzSkillInfo(id: 'Sprinting', name: 'Sprinting', cat: 'Agility', icon: Icons.directions_run_rounded),
  PzSkillInfo(id: 'Lightfoot', name: 'Lightfooted', cat: 'Agility', icon: Icons.do_not_disturb_on_total_silence_rounded),
  PzSkillInfo(id: 'Nimble', name: 'Nimble', cat: 'Agility', icon: Icons.accessibility_new_rounded),
  PzSkillInfo(id: 'Sneak', name: 'Sneaking', cat: 'Agility', icon: Icons.visibility_off_rounded),
  // YakÄ±n DÃ¶vÃ¼ÅŸ
  PzSkillInfo(id: 'Axe', name: 'Axe', cat: 'Combat', icon: Icons.carpenter_rounded),
  PzSkillInfo(id: 'Blunt', name: 'Long Blunt', cat: 'Combat', icon: Icons.sports_cricket_rounded),
  PzSkillInfo(id: 'SmallBlunt', name: 'Short Blunt', cat: 'Combat', icon: Icons.gavel_rounded),
  PzSkillInfo(id: 'LongBlade', name: 'Long Blade', cat: 'Combat', icon: Icons.shield_rounded),
  PzSkillInfo(id: 'SmallBlade', name: 'Short Blade', cat: 'Combat', icon: Icons.hardware_rounded),
  PzSkillInfo(id: 'Spear', name: 'Spear', cat: 'Combat', icon: Icons.sports_kabaddi_rounded),
  PzSkillInfo(id: 'Maintenance', name: 'Maintenance', cat: 'Combat', icon: Icons.build_rounded),
  // AteÅŸli Silahlar
  PzSkillInfo(id: 'Aiming', name: 'Aiming', cat: 'Firearms', icon: Icons.gps_fixed_rounded),
  PzSkillInfo(id: 'Reloading', name: 'Reloading', cat: 'Firearms', icon: Icons.replay_rounded),
  // Zanaat
  PzSkillInfo(id: 'Woodwork', name: 'Carpentry', cat: 'Crafting', icon: Icons.handyman_rounded),
  PzSkillInfo(id: 'Cooking', name: 'Cooking', cat: 'Crafting', icon: Icons.restaurant_rounded),
  PzSkillInfo(id: 'Farming', name: 'Farming', cat: 'Crafting', icon: Icons.grass_rounded),
  PzSkillInfo(id: 'Doctor', name: 'First Aid', cat: 'Crafting', icon: Icons.local_hospital_rounded),
  PzSkillInfo(id: 'Electricity', name: 'Electrical', cat: 'Crafting', icon: Icons.bolt_rounded),
  PzSkillInfo(id: 'MetalWelding', name: 'Metalworking', cat: 'Crafting', icon: Icons.precision_manufacturing_rounded),
  PzSkillInfo(id: 'Mechanics', name: 'Mechanics', cat: 'Crafting', icon: Icons.directions_car_rounded),
  PzSkillInfo(id: 'Tailoring', name: 'Tailoring', cat: 'Crafting', icon: Icons.content_cut_rounded),
  // Hayatta Kalma
  PzSkillInfo(id: 'Fishing', name: 'Fishing', cat: 'Survivalist', icon: Icons.phishing_rounded),
  PzSkillInfo(id: 'Trapping', name: 'Trapping', cat: 'Survivalist', icon: Icons.pest_control_rounded),
  PzSkillInfo(id: 'PlantScavenging', name: 'Foraging', cat: 'Survivalist', icon: Icons.eco_rounded),
  // B42 & Mod Becerileri
  PzSkillInfo(id: 'Blacksmith', name: 'Blacksmith', cat: 'Build 42 & Mods', icon: Icons.whatshot_rounded, isMod: true, modName: 'Build 42 / Mod'),
  PzSkillInfo(id: 'Glassmaking', name: 'Glassmaking', cat: 'Build 42 & Mods', icon: Icons.local_drink_rounded, isMod: true, modName: 'Build 42 / Mod'),
  PzSkillInfo(id: 'Pottery', name: 'Pottery', cat: 'Build 42 & Mods', icon: Icons.cookie_rounded, isMod: true, modName: 'Build 42 / Mod'),
  PzSkillInfo(id: 'Masonry', name: 'Masonry', cat: 'Build 42 & Mods', icon: Icons.foundation_rounded, isMod: true, modName: 'Build 42 / Mod'),
  PzSkillInfo(id: 'Carving', name: 'Carving', cat: 'Build 42 & Mods', icon: Icons.carpenter_rounded, isMod: true, modName: 'Build 42 / Mod'),
  PzSkillInfo(id: 'Tracking', name: 'Tracking', cat: 'Build 42 & Mods', icon: Icons.pets_rounded, isMod: true, modName: 'Build 42 / Mod'),
  PzSkillInfo(id: 'Archery', name: 'Archery', cat: 'Build 42 & Mods', icon: Icons.track_changes_rounded, isMod: true, modName: 'Build 42 / Mod'),
  PzSkillInfo(id: 'Husbandry', name: 'Husbandry', cat: 'Build 42 & Mods', icon: Icons.cruelty_free_rounded, isMod: true, modName: 'Build 42 / Mod'),
  PzSkillInfo(id: 'Butchery', name: 'Butchery', cat: 'Build 42 & Mods', icon: Icons.set_meal_rounded, isMod: true, modName: 'Build 42 / Mod'),
];

const List<Map<String, String>> _allPzProfessions = [
  {'id': 'unemployed', 'name': 'Unemployed', 'desc': '8 Free Points'},
  {'id': 'policeofficer', 'name': 'Police Officer', 'desc': '+3 Aiming, +2 Reloading, +1 Sprinting'},
  {'id': 'fireofficer', 'name': 'Fire Officer', 'desc': '+1 Axe, +1 Fitness, +1 Sprinting, +1 Strength'},
  {'id': 'parkranger', 'name': 'Park Ranger', 'desc': '+2 Foraging, +1 Axe, +1 Carpentry, +1 Trapping'},
  {'id': 'constructionworker', 'name': 'Construction Worker', 'desc': '+3 Short Blunt, +1 Carpentry'},
  {'id': 'securityguard', 'name': 'Security Guard', 'desc': '+2 Sprinting, +1 Lightfooted, Night Owl'},
  {'id': 'carpenter', 'name': 'Carpenter', 'desc': '+3 Carpentry, +1 Short Blunt'},
  {'id': 'burglar', 'name': 'Burglar', 'desc': '+2 Sneaking, +2 Lightfooted, +2 Nimble, Hotwire'},
  {'id': 'chef', 'name': 'Chef', 'desc': '+3 Cooking, +1 Short Blade, +1 Maintenance'},
  {'id': 'repairman', 'name': 'Repairman', 'desc': '+2 Maintenance, +1 Carpentry, +1 Short Blunt'},
  {'id': 'farmer', 'name': 'Farmer', 'desc': '+3 Farming'},
  {'id': 'fisherman', 'name': 'Fisherman', 'desc': '+3 Fishing, +1 Foraging'},
  {'id': 'doctor', 'name': 'Doctor', 'desc': '+3 First Aid, +1 Short Blade'},
  {'id': 'nurse', 'name': 'Nurse', 'desc': '+2 First Aid, +1 Lightfooted'},
  {'id': 'lumberjack', 'name': 'Lumberjack', 'desc': '+2 Axe, +1 Strength, Axe Man'},
  {'id': 'fitnessInstructor', 'name': 'Fitness Instructor', 'desc': '+3 Fitness, +2 Sprinting'},
  {'id': 'electrician', 'name': 'Electrician', 'desc': '+3 Electrical, Generator Operation'},
  {'id': 'engineer', 'name': 'Engineer', 'desc': '+1 Electrical, +1 Carpentry, Explosive Recipes'},
  {'id': 'metalworker', 'name': 'Metalworker', 'desc': '+3 Metalworking'},
  {'id': 'mechanics', 'name': 'Mechanics', 'desc': '+3 Mechanics, +1 Short Blunt'},
  {'id': 'veteran', 'name': 'Veteran', 'desc': '+2 Aiming, +2 Reloading, Desensitized'},
];

const List<PzTraitInfo> _allPzPositiveTraits = [
  // Vanilla Positive Traits
  PzTraitInfo(id: 'FastLearner', name: 'Fast Learner', icon: Icons.school_rounded),
  PzTraitInfo(id: 'Brave', name: 'Brave', icon: Icons.shield_rounded),
  PzTraitInfo(id: 'KeenHearing', name: 'Keen Hearing', icon: Icons.hearing_rounded),
  PzTraitInfo(id: 'Dexterous', name: 'Dexterous', icon: Icons.pan_tool_rounded),
  PzTraitInfo(id: 'Organized', name: 'Organized', icon: Icons.inventory_2_rounded),
  PzTraitInfo(id: 'Athletic', name: 'Athletic', icon: Icons.directions_run_rounded),
  PzTraitInfo(id: 'Strong', name: 'Strong', icon: Icons.sports_mma_rounded),
  PzTraitInfo(id: 'Fit', name: 'Fit', icon: Icons.fitness_center_rounded),
  PzTraitInfo(id: 'Stout', name: 'Stout', icon: Icons.accessibility_new_rounded),
  PzTraitInfo(id: 'SpeedDemon', name: 'Speed Demon', icon: Icons.speed_rounded),
  PzTraitInfo(id: 'ThickSkinned', name: 'Thick Skinned', icon: Icons.security_rounded),
  PzTraitInfo(id: 'Handy', name: 'Handy', icon: Icons.handyman_rounded),
  PzTraitInfo(id: 'FastHealer', name: 'Fast Healer', icon: Icons.healing_rounded),
  PzTraitInfo(id: 'Lucky', name: 'Lucky', icon: Icons.auto_awesome_rounded),
  PzTraitInfo(id: 'Inconspicuous', name: 'Inconspicuous', icon: Icons.visibility_off_rounded),
  PzTraitInfo(id: 'Graceful', name: 'Graceful', icon: Icons.airline_seat_legroom_extra_rounded),
  PzTraitInfo(id: 'Outdoorsman', name: 'Outdoorsman', icon: Icons.forest_rounded),
  PzTraitInfo(id: 'Wakeful', name: 'Wakeful', icon: Icons.wb_sunny_rounded),
  PzTraitInfo(id: 'NightVision', name: "Cat's Eyes", icon: Icons.nightlight_round_rounded),
  PzTraitInfo(id: 'NightOwl', name: 'Night Owl', icon: Icons.bedtime_rounded),
  PzTraitInfo(id: 'FastReader', name: 'Fast Reader', icon: Icons.menu_book_rounded),
  PzTraitInfo(id: 'LightEater', name: 'Light Eater', icon: Icons.restaurant_rounded),
  PzTraitInfo(id: 'LowThirst', name: 'Low Thirst', icon: Icons.water_drop_rounded),
  PzTraitInfo(id: 'Nutritionist', name: 'Nutritionist', icon: Icons.local_dining_rounded),
  PzTraitInfo(id: 'Desensitized', name: 'Desensitized', icon: Icons.sentiment_neutral_rounded),
  PzTraitInfo(id: 'IronGut', name: 'Iron Gut', icon: Icons.health_and_safety_rounded),
  PzTraitInfo(id: 'AdrenalineJunkie', name: 'Adrenaline Junkie', icon: Icons.local_fire_department_rounded),
  
  // Mod Traits (More Traits)
  PzTraitInfo(id: 'packmule', name: 'Pack Mule', icon: Icons.backpack_rounded, isMod: true, modName: 'More Traits'),
  PzTraitInfo(id: 'olympian', name: 'Olympian', icon: Icons.emoji_events_rounded, isMod: true, modName: 'More Traits'),
  PzTraitInfo(id: 'quickrest', name: 'Quick Rest', icon: Icons.bolt_rounded, isMod: true, modName: 'More Traits'),
  PzTraitInfo(id: 'secondwind', name: 'Second Wind', icon: Icons.air_rounded, isMod: true, modName: 'More Traits'),
  PzTraitInfo(id: 'gordanite', name: 'Gordanite', icon: Icons.hardware_rounded, isMod: true, modName: 'More Traits'),
  PzTraitInfo(id: 'bouncer', name: 'Bouncer', icon: Icons.sports_kabaddi_rounded, isMod: true, modName: 'More Traits'),
  PzTraitInfo(id: 'expertdriver', name: 'Expert Driver', icon: Icons.sports_motorsports_rounded, isMod: true, modName: 'More Traits'),
  PzTraitInfo(id: 'graverobber', name: 'Grave Robber', icon: Icons.lock_open_rounded, isMod: true, modName: 'More Traits'),
  PzTraitInfo(id: 'tavernbrawler', name: 'Tavern Brawler', icon: Icons.sports_bar_rounded, isMod: true, modName: 'More Traits'),
  PzTraitInfo(id: 'martial', name: 'Martial Artist', icon: Icons.sports_martial_arts_rounded, isMod: true, modName: 'More Traits'),
  PzTraitInfo(id: 'gunspecialist', name: 'Gun Specialist', icon: Icons.gps_fixed_rounded, isMod: true, modName: 'More Traits'),
  PzTraitInfo(id: 'progun', name: 'Pro Gunner', icon: Icons.military_tech_rounded, isMod: true, modName: 'More Traits'),
  PzTraitInfo(id: 'problade', name: 'Pro Blade', icon: Icons.content_cut_rounded, isMod: true, modName: 'More Traits'),
  PzTraitInfo(id: 'problunt', name: 'Pro Blunt', icon: Icons.sports_cricket_rounded, isMod: true, modName: 'More Traits'),
  PzTraitInfo(id: 'prospear', name: 'Pro Spear', icon: Icons.north_east_rounded, isMod: true, modName: 'More Traits'),
  PzTraitInfo(id: 'tinkerer', name: 'Tinkerer', icon: Icons.construction_rounded, isMod: true, modName: 'More Traits'),
  PzTraitInfo(id: 'wildsman', name: 'Wildsman', icon: Icons.nature_people_rounded, isMod: true, modName: 'More Traits'),
  PzTraitInfo(id: 'superimmune', name: 'Super Immune', icon: Icons.vaccines_rounded, isMod: true, modName: 'More Traits'),
  PzTraitInfo(id: 'actionhero', name: 'Action Hero', icon: Icons.star_rounded, isMod: true, modName: 'More Traits'),
  PzTraitInfo(id: 'terminator', name: 'Terminator', icon: Icons.smart_toy_rounded, isMod: true, modName: 'More Traits'),
  PzTraitInfo(id: 'indefatigable', name: 'Indefatigable', icon: Icons.shield_moon_rounded, isMod: true, modName: 'More Traits'),
  PzTraitInfo(id: 'hardy', name: 'Hardy', icon: Icons.favorite_rounded, isMod: true, modName: 'More Traits'),
  PzTraitInfo(id: 'evasive', name: 'Evasive', icon: Icons.run_circle_rounded, isMod: true, modName: 'More Traits'),
  PzTraitInfo(id: 'ingenuitive', name: 'Ingenuitive', icon: Icons.psychology_rounded, isMod: true, modName: 'More Traits'),
  PzTraitInfo(id: 'swift', name: 'Swift', icon: Icons.flash_on_rounded, isMod: true, modName: 'More Traits'),
  PzTraitInfo(id: 'batteringram', name: 'Battering Ram', icon: Icons.door_sliding_rounded, isMod: true, modName: 'More Traits'),
  PzTraitInfo(id: 'scrapper', name: 'Scrapper', icon: Icons.recycling_rounded, isMod: true, modName: 'More Traits'),
  PzTraitInfo(id: 'scrounger', name: 'Scrounger', icon: Icons.search_rounded, isMod: true, modName: 'More Traits'),
  PzTraitInfo(id: 'generator', name: 'Generator Expert', icon: Icons.electric_meter_rounded, isMod: true, modName: 'More Traits'),
  PzTraitInfo(id: 'restfulsleeper', name: 'Restful Sleeper', icon: Icons.airline_seat_flat_rounded, isMod: true, modName: 'More Traits'),
  PzTraitInfo(id: 'fast', name: 'Fast Walker', icon: Icons.directions_walk_rounded, isMod: true, modName: 'More Traits'),
  PzTraitInfo(id: 'quickworker', name: 'Quick Worker', icon: Icons.timer_rounded, isMod: true, modName: 'More Traits'),
  PzTraitInfo(id: 'gymgoer', name: 'Gym Goer', icon: Icons.fitness_center_rounded, isMod: true, modName: 'More Traits'),
  PzTraitInfo(id: 'unwavering', name: 'Unwavering', icon: Icons.self_improvement_rounded, isMod: true, modName: 'More Traits'),
];

const List<PzTraitInfo> _allPzNegativeTraits = [
  // Vanilla Negative Traits
  PzTraitInfo(id: 'SlowLearner', name: 'Slow Learner', icon: Icons.psychology_alt_rounded),
  PzTraitInfo(id: 'Cowardly', name: 'Cowardly', icon: Icons.sentiment_very_dissatisfied_rounded),
  PzTraitInfo(id: 'HardOfHearing', name: 'Hard of Hearing', icon: Icons.hearing_disabled_rounded),
  PzTraitInfo(id: 'Clumsy', name: 'Clumsy', icon: Icons.personal_injury_rounded),
  PzTraitInfo(id: 'Disorganized', name: 'Disorganized', icon: Icons.layers_clear_rounded),
  PzTraitInfo(id: 'Smoker', name: 'Smoker', icon: Icons.smoking_rooms_rounded),
  PzTraitInfo(id: 'Asthmatic', name: 'Asthmatic', icon: Icons.masks_rounded),
  PzTraitInfo(id: 'Claustrophobic', name: 'Claustrophobic', icon: Icons.meeting_room_rounded),
  PzTraitInfo(id: 'Agoraphobic', name: 'Agoraphobic', icon: Icons.open_in_full_rounded),
  PzTraitInfo(id: 'Weak', name: 'Weak', icon: Icons.trending_down_rounded),
  PzTraitInfo(id: 'Feeble', name: 'Feeble', icon: Icons.battery_alert_rounded),
  PzTraitInfo(id: 'Unfit', name: 'Unfit', icon: Icons.heart_broken_rounded),
  PzTraitInfo(id: 'Out of Shape', name: 'Out of Shape', icon: Icons.airline_seat_recline_normal_rounded),
  PzTraitInfo(id: 'SundayDriver', name: 'Sunday Driver', icon: Icons.slow_motion_video_rounded),
  PzTraitInfo(id: 'ProneToIllness', name: 'Prone to Illness', icon: Icons.coronavirus_rounded),
  PzTraitInfo(id: 'SlowHealer', name: 'Slow Healer', icon: Icons.medical_information_rounded),
  PzTraitInfo(id: 'Unlucky', name: 'Unlucky', icon: Icons.mood_bad_rounded),
  PzTraitInfo(id: 'Conspicuous', name: 'Conspicuous', icon: Icons.visibility_rounded),
  PzTraitInfo(id: 'ShortSighted', name: 'Short Sighted', icon: Icons.visibility_off_outlined),
  PzTraitInfo(id: 'HeartyAppetit', name: 'Hearty Appetite', icon: Icons.soup_kitchen_rounded),
  PzTraitInfo(id: 'HighThirst', name: 'High Thirst', icon: Icons.opacity_rounded),
  PzTraitInfo(id: 'Sleepyhead', name: 'Sleepyhead', icon: Icons.snooze_rounded),
  PzTraitInfo(id: 'Underweight', name: 'Underweight', icon: Icons.scale_rounded),
  PzTraitInfo(id: 'Overweight', name: 'Overweight', icon: Icons.scale_rounded),
  PzTraitInfo(id: 'Obese', name: 'Obese', icon: Icons.scale_rounded),
  PzTraitInfo(id: 'WeakStomach', name: 'Weak Stomach', icon: Icons.sick_rounded),
  PzTraitInfo(id: 'Hemophobic', name: 'Hemophobic', icon: Icons.bloodtype_rounded),
  PzTraitInfo(id: 'Pacifist', name: 'Pacifist', icon: Icons.back_hand_rounded),
  PzTraitInfo(id: 'AllThumbs', name: 'All Thumbs', icon: Icons.front_hand_rounded),
  PzTraitInfo(id: 'SlowReader', name: 'Slow Reader', icon: Icons.auto_stories_rounded),
  
  // Mod Negative Traits (More Traits)
  PzTraitInfo(id: 'immunocompromised', name: 'Immunocompromised', icon: Icons.warning_rounded, isMod: true, modName: 'More Traits'),
  PzTraitInfo(id: 'anemic', name: 'Anemic', icon: Icons.bloodtype_outlined, isMod: true, modName: 'More Traits'),
  PzTraitInfo(id: 'butterfingers', name: 'Butterfingers', icon: Icons.dry_cleaning_rounded, isMod: true, modName: 'More Traits'),
  PzTraitInfo(id: 'paranoia', name: 'Paranoia', icon: Icons.remove_red_eye_rounded, isMod: true, modName: 'More Traits'),
  PzTraitInfo(id: 'gimp', name: 'Gimp', icon: Icons.accessible_rounded, isMod: true, modName: 'More Traits'),
  PzTraitInfo(id: 'glassbody', name: 'Glass Body', icon: Icons.local_drink_rounded, isMod: true, modName: 'More Traits'),
  PzTraitInfo(id: 'motionsickness', name: 'Motion Sickness', icon: Icons.car_crash_rounded, isMod: true, modName: 'More Traits'),
  PzTraitInfo(id: 'noodlelegs', name: 'Noodle Legs', icon: Icons.airline_seat_legroom_reduced_rounded, isMod: true, modName: 'More Traits'),
  PzTraitInfo(id: 'poordriver', name: 'Poor Driver', icon: Icons.crisis_alert_rounded, isMod: true, modName: 'More Traits'),
  PzTraitInfo(id: 'fearful', name: 'Fearful', icon: Icons.emergency_rounded, isMod: true, modName: 'More Traits'),
  PzTraitInfo(id: 'depressive', name: 'Depressive', icon: Icons.sentiment_dissatisfied_rounded, isMod: true, modName: 'More Traits'),
  PzTraitInfo(id: 'selfdestructive', name: 'Self Destructive', icon: Icons.heart_broken_outlined, isMod: true, modName: 'More Traits'),
  PzTraitInfo(id: 'slowworker', name: 'Slow Worker', icon: Icons.hourglass_bottom_rounded, isMod: true, modName: 'More Traits'),
  PzTraitInfo(id: 'antigun', name: 'Anti-Gun', icon: Icons.do_not_disturb_on_rounded, isMod: true, modName: 'More Traits'),
  PzTraitInfo(id: 'drinker', name: 'Drinker', icon: Icons.wine_bar_rounded, isMod: true, modName: 'More Traits'),
  PzTraitInfo(id: 'HeavyDrinker', name: 'Heavy Drinker', icon: Icons.liquor_rounded, isMod: true, modName: 'More Traits'),
  PzTraitInfo(id: 'LightDrinker', name: 'Light Drinker', icon: Icons.local_bar_rounded, isMod: true, modName: 'More Traits'),
  PzTraitInfo(id: 'albino', name: 'Albino', icon: Icons.wb_sunny_outlined, isMod: true, modName: 'More Traits'),
  PzTraitInfo(id: 'amputee', name: 'Amputee', icon: Icons.pan_tool_outlined, isMod: true, modName: 'More Traits'),
  PzTraitInfo(id: 'burned', name: 'Burned', icon: Icons.whatshot_rounded, isMod: true, modName: 'More Traits'),
  PzTraitInfo(id: 'injured', name: 'Injured', icon: Icons.healing_outlined, isMod: true, modName: 'More Traits'),
  PzTraitInfo(id: 'badteeth', name: 'Bad Teeth', icon: Icons.medical_services_outlined, isMod: true, modName: 'More Traits'),
  PzTraitInfo(id: 'broke', name: 'Broke', icon: Icons.money_off_rounded, isMod: true, modName: 'More Traits'),
  PzTraitInfo(id: 'incomprehensive', name: 'Incomprehensive', icon: Icons.help_outline_rounded, isMod: true, modName: 'More Traits'),
  PzTraitInfo(id: 'mundane', name: 'Mundane', icon: Icons.interests_rounded, isMod: true, modName: 'More Traits'),
  PzTraitInfo(id: 'leadfoot', name: 'Lead Foot', icon: Icons.speed_outlined, isMod: true, modName: 'More Traits'),
  PzTraitInfo(id: 'thickblood', name: 'Thick Blood', icon: Icons.water_damage_rounded, isMod: true, modName: 'More Traits'),
  PzTraitInfo(id: 'vagabond', name: 'Vagabond', icon: Icons.travel_explore_rounded, isMod: true, modName: 'More Traits'),
];
