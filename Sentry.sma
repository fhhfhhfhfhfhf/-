#include <amxmodx>
#include <amxmisc>                                                                                                  
#include <engine>                                                 
#include <fun>                                                                                                            
#include <cstrike>                                                                                       
#include <fakemeta>                                                                                          
#include <hamsandwich>                     
#include <xs>               
#include <fakemeta_stocks>                                                                                                        
#include <dhudmessage>
                                                                                                                                                             
#define THINKFIREFREQUENCY		0.11				// the rate in seconds between each                                                  
                                             
#define DMG_SHOCK (1 << 8)                                                  
                                        
#define is_valid_player(%1) ( 1 <= %1 <= g_iMaxPlayers )
#define is_valid_team(%1) ( 0 < %1 < 3 )
                          
#define is_entity_on_ground(%1) ( entity_get_int ( %1, EV_INT_flags ) & FL_ONGROUND )
                                                                     
#define is_team(%1,%2)        (bool:(get_user_team(%1) == %2))
                                       
// СЃРєРѕР»СЊРєРѕ РїСѓС€РµРє Сѓ РёРіСЂРѕРєР° СѓР¶Рµ РїРѕСЃС‚СЂРѕРµРЅРѕ            
#define GetSentryCount(%1) g_iPlayerSentries[%1]

// Р·Р° СЂР°Р·СЂСѓС€РµРЅРёРµ РїСѓС€РєРё
#define REWARD_MONEY 3000 // Р·Р°РјРµРЅРµРЅРѕ

#define MAXUPGRADERANGE            75.0
#define SENTRYEXPLODERADIUS        1.0            // СЂР°РґРёСѓСЃ РѕС‚Р±СЂРѕСЃР° РїСЂРё РІР·СЂС‹РІРµ
#define SENTRYTILTRADIUS        30000.0            // likely you won't need to touch this. it's how accurate the cannon will aim at the target vertically (up/down, just for looks, aim is calculated differently)
#define PLANTWAITTIME           5.0
#define SENTRYMINDISTANCE        150.0  

#define MAXSENTRIES                500
#define BOT_MAXSENTRIESDISTANCE	500.0

#define SENTRY_INT_TARGET        EV_INT_iuser3
#define SENTRY_TARGET_BITS        6                                                                     
#define TARGET                    0
#define MASK_TARGET                0xFFFFFFC0 // 11111111111111111111111111000000
 //native give_shield_grenade ( id )
 new max_sentry_acess
 new max_sentry
new const MASKS_TARGET[15] = {MASK_TARGET}
              
GetSentryTarget(const SENTRY, const WHO) {
    new data = entity_get_int(SENTRY, SENTRY_INT_TARGET)
    data |= MASKS_TARGET[WHO]
    data ^= MASKS_TARGET[WHO]        
    data = (data>>(WHO*SENTRY_TARGET_BITS))
    return data
}
SetSentryTarget(const SENTRY, const WHO, const IS) {
    new data = entity_get_int(SENTRY, SENTRY_INT_TARGET)
    data &= MASKS_TARGET[WHO] // nullify the setting
    data |= (IS<<(WHO*SENTRY_TARGET_BITS)) // set the setting
    entity_set_int(SENTRY, SENTRY_INT_TARGET, data) // store
}

#define SENTRY_INT_UGPRADERS    EV_INT_iuser2 // max 5 users using 6 bits!
#define SENTRY_UGPRADERS_BITS    6
#define OWNER                    0
#define UPGRADER_1                1
#define UPGRADER_2                2
#define UPGRADER_3                3
#define UPGRADER_4                4
#define MASK_OWNER                0xFFFFFFC0 // 11111111111111111111111111000000
#define MASK_UPGRADER_1            0xFFFFF03F // 11111111111111111111000000111111
#define MASK_UPGRADER_2            0xFFFC0FFF // 11111111111111000000111111111111
#define MASK_UPGRADER_3            0xFF03FFFF // 11111111000000111111111111111111
#define MASK_UPGRADER_4            0xC0FFFFFF // 11000000111111111111111111111111
new const MASKS_PEOPLE[5] = {MASK_OWNER, MASK_UPGRADER_1, MASK_UPGRADER_2, MASK_UPGRADER_3, MASK_UPGRADER_4}

GetSentryUpgrader(const SENTRY, const WHO) {
    new data = entity_get_int(SENTRY, SENTRY_INT_UGPRADERS)
    data |= MASKS_PEOPLE[WHO]
    data ^= MASKS_PEOPLE[WHO]
    data = (data>>(WHO*SENTRY_UGPRADERS_BITS))
    return data
}
SetSentryUpgrader(const SENTRY, const WHO, const IS) {
    new data = entity_get_int(SENTRY, SENTRY_INT_UGPRADERS)
    data &= MASKS_PEOPLE[WHO] // nullify the setting
    data |= (IS<<(WHO*SENTRY_UGPRADERS_BITS)) // set the setting
    entity_set_int(SENTRY, SENTRY_INT_UGPRADERS, data) // store
}

#define BLAST_TASK_ID 9864 //Р”Р»СЏ РІРµСЂРЅРѕР№ СЂР°Р±РѕС‚С‹ С‚Р°СЃРєР° СЃРІРµС‡РµРЅРёСЏ
#define FREEZ_TASK_ID 9865 //Р”Р»СЏ РІРµСЂРЅРѕР№ СЂР°Р±РѕС‚С‹ С‚Р°СЃРєР° Р·Р°РјРѕСЂРѕР·РєРё                                            
#define FREEZ_ENT_TIME EV_FL_teleport_time
#define BOT_MAXSENTRIESNEAR		155
#define TASKID_BOTBUILDRANDOMLY	2000
#define TASKID_BOTBUILDRANDOMLY	2000
#define TASKID_SENTRYSTATUS		3000
#define TASKID_THINK			4000
#define TASKID_THINKPENDULUM	5000
#define TASKID_SENTRYONRADAR	6000
#define TASKID_SPYCAM			7000
#define BOT_OBJECTIVEWAIT		10
#define SENTRY_INT_SETTINGS        EV_INT_iuser1
#define SENTRY_ROCKET_TIME        EV_FL_teleport_time
#define SENTRY_FREEZ_TIME    EV_FL_scale
#define SENTRY_SETTINGS_BITS    3
#define SENTRY_SETTING_FIREMODE    0
#define SENTRY_SETTING_TEAM        1
#define SENTRY_SETTING_LEVEL    2
#define SENTRY_SETTING_PENDDIR    3
#define MASK_FIREMODE            0xFFFFFFF8 // 11111111111111111111111111111000 = FFFFFFFC
#define MASK_TEAM                0xFFFFFFC7 // 11111111111111111111111111000111 = FFFFFFF3
#define MASK_LEVEL                0xFFFFFE3F // 11111111111111111111111000111111 = FFFFFFCF
#define MASK_PENDDIR            0xFFFFF1FF // 11111111111111111111000111111111 = FFFFFF3F
new const MASKS_SETTINGS[4] = {MASK_FIREMODE, MASK_TEAM, MASK_LEVEL, MASK_PENDDIR}
 public plugin_cfg()
{

	new file[128]; get_localinfo("amxx_configsdir",file,63)
	format(file, 127, "%s/Supremej/SentryBuild/SentryBuildSettings.cfg", file)
	if(file_exists(file)) server_cmd("exec %s", file), server_exec()
}
GetSentrySettings(const SENTRY, const SETTING) {
    new data = entity_get_int(SENTRY, SENTRY_INT_SETTINGS)
    data |= MASKS_SETTINGS[SETTING]
    data ^= MASKS_SETTINGS[SETTING]                      
    //data = (data>>(SETTING*SENTRY_SETTINGS_BITS))
    return (data>>(SETTING*SENTRY_SETTINGS_BITS))
}
SetSentrySettings(const SENTRY, const SETTING, const VALUE) {
    new data = entity_get_int(SENTRY, SENTRY_INT_SETTINGS)
    data &= MASKS_SETTINGS[SETTING] // nullify the setting
    //data |= (VALUE<<(SETTING*SENTRY_SETTINGS_BITS)) // set the setting
    entity_set_int(SENTRY, SENTRY_INT_SETTINGS, data | (VALUE<<(SETTING*SENTRY_SETTINGS_BITS))) // store
}
#define MAXPLAYERSENTRIES         2  
GetSentryFiremode(const SENTRY) {
    return GetSentrySettings(SENTRY, SENTRY_SETTING_FIREMODE)
}
SetSentryFiremode(const SENTRY, const MODE) {                                                            
    SetSentrySettings(SENTRY, SENTRY_SETTING_FIREMODE, MODE)
}
CsTeams:GetSentryTeam(const SENTRY) {                                      
    return CsTeams:GetSentrySettings(SENTRY, SENTRY_SETTING_TEAM)
}
SetSentryTeam(const SENTRY, const CsTeams:TEAM) {
    SetSentrySettings(SENTRY, SENTRY_SETTING_TEAM, int:TEAM)
}
GetSentryLevel(const SENTRY) {
    return GetSentrySettings(SENTRY, SENTRY_SETTING_LEVEL)
}
SetSentryLevel(const SENTRY, const LEVEL) {
    SetSentrySettings(SENTRY, SENTRY_SETTING_LEVEL, LEVEL)
}
GetSentryPenddir(const SENTRY) {
    return GetSentrySettings(SENTRY, SENTRY_SETTING_PENDDIR)
}                           
SetSentryPenddir(const SENTRY, const PENDDIR) {
    SetSentrySettings(SENTRY, SENTRY_SETTING_PENDDIR, PENDDIR)
}   
new String:CSSB_NAME[68] = "CSSB SENTRY";                                                                                                            
new const BALL__MODEL[   ]        =    "sprites/CSSB/sentry_guns/spr_1.spr";
new const MOROZ__MODEL[   ]        =    "sprites/CSSB/sentry_guns/spr_10.spr";
#define DATA_CUBE_OWNER             EV_INT_iuser1
#define SENTRY_ENT_BASE            EV_ENT_euser1

#define SENTRY_FL_ANGLE            EV_FL_fuser1                                                                             
#define SENTRY_FL_SPINSPEED        EV_FL_fuser2
#define SENTRY_FL_MAXSPIN        EV_FL_fuser3
#define SENTRY_FL_LASTTHINK        EV_FL_fuser4
#define SENTRY_FL_LASTTHIN       21
#define SENTRY_FL_LASTTHINKA       15
#define SENTRY_FL_LASTTHINKAF       16
#define SENTRY_FL_LASTTHINKAFB       14
#define SENTRY_FL_LASTTHINKAFV       19
#define SENTRY_FL_LASTTHINKAFVA       20
#define SENTRY_FL_LASTTHIN       21
#define SENTRY_FL_LASTTH    22
#define SENTRY_FL_LASTTV    23
#define SENTRY_FL_LASTTVH    24
#define SENTRY_FL_LASTTHINKAFAB 25
#define ABA1 26
#define ABA2 27
#define ABA3 28
#define ABA4 29
#define ABA5 30
#define ABA6 31
#define ABA7 32
#define ABA8 8
#define ABA9 34
#define TASK_GODMODE 114455
#define SENTRY_DIR_CANNON        0

#define BASE_ENT_SENTRY            EV_ENT_euser1
#define BASE_INT_TEAM            EV_INT_iuser1

#define SENTRY_LEVEL_1            0
#define SENTRY_LEVEL_2            1
#define SENTRY_LEVEL_3            2
#define SENTRY_LEVEL_4            3
#define SENTRY_LEVEL_5            4
#define SENTRY_FIREMODE_NO        0
#define SENTRY_FIREMODE_YES        1
#define SENTRY_FIREMODE_NUTS    2
#define TARGETUPMODIFIER        16.0 // if player ducks on ground, traces don't hit...
#define DMG_BULLET                (1<<1)    //РІС‹СЃС‚СЂРµР»
#define DMG_BLAST                (1<<6)    // explosive blast damage
#define TE_EXPLFLAG_NONE        0   
#define TE_EXPLOSION            3
#define TE_TRACER                6
#define TE_BREAKMODEL            108
#define PENDULUM_MAX            45.0 // how far sentry turret turns in each direction when idle, before turning back
#define PENDULUM_INCREMENT        300.0 // speed of turret turning...
#define SENTRYSHOCKPOWER        3.0 // multiplier, increase to make exploding sentries throw stuff further away
#define CANNONHEIGHTFROMFEET    20.0 // tweakable to make tracer originate from the same height as the sentry's cannon. Also traces rely on this Y-wise offset.
#define PLAYERORIGINHEIGHT        36.0 // this is the distance from a player's EV_VEC_origin to ground, if standing up
#define HEIGHTDIFFERENCEALLOWED    17.0 // increase value to allow building in slopes with higher angles. You can set to 0.0 and you will only be able to build on exact flat ground. note: mostly applies to downhill building, uphill is still likely to "collide" with ground...

#define PLACE_RANGE             45.0

#define SENTRY_RADAR            (1<<4)  // 16
#define SENTRY_RADAR_TEAMBUILT  (1<<5)  // 32

#define RPG_DAMAGE 100.0

#define TASK_LEAVE_ID 10100
#define TASK_CHECK_ACCU 0.05                                                             
new const szModels[][] =
{                         
    "models/cssb/sentry_v6/base.mdl",  
    "models/cssb/sentry_v6/missile.mdl",
    "models/cssb/sentry_v5/ice_cube.mdl", 
    "models/computergibs.mdl" 	                
}                   

                                                                                                                     
new const szSounds[][] =
{  
    "CSSB/sentry_gun/metal_2.wav",
    "debris/bustmetal1.wav",
    "debris/bustmetal2.wav",                                 
    "debris/metal1.wav",
    "debris/metal3.wav",
    "NewGameCsdm_New/sentry/turridle.wav",                                                                                    
    "NewGameCsdm_New/sentry/turrset.wav",
    "NewGameCsdm_New/sentry/turrspot.wav",
    "NewGameCsdm_New/sentry/building.wav",
    "NewGameCsdm_New/sentry/fire.wav",         
    "NewGameCsdm_New/sentry/rocket1.wav",
    "NewGameCsdm_New/sentry/fail_update_1.wav",
    "NewGameCsdm_New/sentry/sentry_exp.wav",
    "NewGameCsdm_New/sentry/freez_1.wav",  
    "NewGameCsdm_New/sentry/tesla.wav",
    "NewGameCsdm_New/sentry/laser.wav",
    "CSSB/sentry_gunfire_charge_1.wav",                                
    "player/bhit_helmet-1.wav",		
    "CSSB/sentry_gun/rotate_2.wav",  
    "CSSB/sentry_gun/turret_up_2.wav", 	
    "CSSB/sentry_gun/build_1.wav",
    "CSSB/sentry_gun/alert_3.wav",
    "CSSB/sentry_gun/fire_5.wav",
    "CSSB/sentry_gun/enemy_died_1.wav", 	
    "CSSB/sentry_gun/rocketfire_1.wav",
	"CSSB/sentry_gun/rocket_explosion.wav",
    "CSSB/sentry_gun/fail_update_1.wav",
    "CSSB/sentry_gun/sentry_exp.wav",
    "CSSB/sentry_gun/fire_charge_3.wav",  
    "CSSB/sentry_gun/tesla_lightning_2.wav",
    "CSSB/sentry_gun/laser_1.wav",
    "CSSB/sentry_gun/fire_charge_1.wav",
    "CSSB/sentry_gun/nuke_fly.wav"   	
}                                              
                         
#define SENTRYASSISTAWARD    150
#define SENTRYLVL1  300
#define SENTRYLVL2  300
#define SENTRYLVL3  300
#define SENTRYLVL4  300
#define SENTRYLVL5  300               
#define BOT_WAITTIME_MIN        450.5                // waittime = the time a bot will wait after he's decided to build a sentry, before actually building (seconds)
#define BOT_WAITTIME_MAX        1450.5                            
#define BOT_NEXT_MIN            900.0                // next = after building a sentry, this specifies the time a bot will wait until considering about waittime again (seconds)
#define BOT_NEXT_MAX            1500.0      
                             // РєРѕР»РёС‡РµСЃС‚РІРѕ СѓСЂРѕРЅР° РѕС‚ РїСѓС€РєРё РІ Р·Р°РІРёСЃРёРјРѕСЃС‚Рё РѕС‚ РµРµ СѓСЂРѕРІРЅСЏ
new const Float:g_THINKFREQUENCIES =  0.5		            // С‡РµСЂРµР· СЃРєРѕР»СЊРєРѕ Р·Р°С…РІР°С‚С‹РІР°РµС‚СЃСЏ С†РµР»СЊ
new const Float:g_HITRATIOS[5] = {1.0, 1.0, 1.0, 1.0,1.0}            // СЂР°Р·Р±СЂРѕСЃ
new g_HEALTHS[5]
new g_COST[2]
//new const SENTRYCOSTS[][15] = {900, 1050,1250,2400,2500,2600,2700,2800,2900,3000,3100,3200,3300,3400,3500}                  // СЃС‚РѕРёРјРѕСЃС‚СЊ СѓСЃС‚Р°РЅРѕРІРєРё/СѓР»СѓС‡С€РµРЅРёСЏ РїСѓС€РµРє 
new MONEY[4]
new const g_iColors[][] = {{255, 45,45}, {45, 45, 255}}
#define g_sentriesNum (g_teamsentriesNum[0]+g_teamsentriesNum[1])
new g_teamsentriesNum[2]                                     
new g_sentries[MAXSENTRIES]
new g_iPlayerSentries[33]                     
new g_iPlayerSentriesEdicts[33][100]
new Float:TimerTesla
new g_sModelIndexFireball
new g_msgDamage
new g_msgDeathMsg
new g_msgScoreInfo                                                                                         
new g_msgHostagePos
new g_msgHostageK   
new g_iMaxPlayers  
new Float:g_ONEEIGHTYTHROUGHPI                                                   
new Float:g_sentryOrigins[33][3]
new sentries_num[33]
new gMsgID     
new szTime = 0
new ColorTeam
new g_OffSpam[33];               
new g_iKillSentry[32000];
new g_SentryLaser[33];
new g_SentryTesla[33];
new g_SentryFreezing[33];
new g_lastObjectiveBuild[32]
new g_OwnName[33];                                                               
new g_StatsKill[33];     
new urag_damage_sec
new higher_score; 
new g_iSPR_Explo2

new keys = MENU_KEY_1|MENU_KEY_2|MENU_KEY_3|MENU_KEY_4|MENU_KEY_5|MENU_KEY_6|MENU_KEY_7|MENU_KEY_8|MENU_KEY_9;
                                                                                                               
new g_Sprite      
new g_Chastic                 
new g_sModelIndexMoroz   
new g_Moroz
new g_Tesssla                      
new g_Tesla                      
new g_Tessla

new g_regen
new g_auracveta
new g_blue
new g_red
new g_SentryMode[32000]
new g_SentryModem[32000]
new g_SentryId[33];
new gHealingBeam

new Float:g_fTime[33]
new Float:Time[33]                                                   
                                                                                                                                                                                                                                                                                                                                                   
new g_dmga1, g_dmga2, g_dmga3, g_dmga4, g_dmga5                                                  
new g_Cvar_mode_cost[7], g_Cvar_mode_aktiv[7], g_Cvar_mode_rpg[4], g_Cvar_mode_led[2], g_Cvar_remont[2], g_Cvar_Radius, g_Cvar_mode_urag[3]
new g_Cvar_mode_cost_vip[7]
new g_Cvar_smokesentry, g_smoke
new g_Cvar_mode_tesla[3]
new g_Cvar_mode_moroz[3]
new g_iCvar[8], g_DMG[5]
new takehpar, max_hp_regenSentry, radiuslechenia, max_ar_regenSentry
new cvar_admin_mul_cost;
new cvar_admin_mul_upg_cost
new sg_cost_new;
new sg_rpg_shot_money, sg_tesla_shot_money,sg_hurricane_shot_money
new sb_tesla_damage
new g_Cvar_nagryzka[2]
new dhud_sentryct_te_ON_OFF
new sg_player_min
new sg_money_upgdate_owner
new g_COST_VIP[2]
new szVampirFlag[64];
new sg_dist_update_in_menu_sentry
new max_sentry5_lvl[3]
new g_Classname [ ] = "roflmao"
new moroztime;
new moroztime2;
new uragtime;
new uragradius;
new sentry_max_money;
new sentrycost;
new sentry_proc_money;
public plugin_init() {                                                                                              
	sentrycost = register_cvar("sg_sentrycost", "1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18");
    register_plugin("Sentry gun", "1.1", "TEXT [vk.com/csplugin_text]")
    register_event ( "Spectator", "ev_Spectation", "a" )  
    register_dictionary("sentry_gun.txt") 
    register_clcmd("sentry_build", "cmd_CreateSentry", 0, "- build a sentry gun where you are") 
    RegisterHam ( Ham_Spawn, "player", "fw_PlayerSpawn_Post", 1 )                                    
    register_forward ( FM_TraceLine, "fw_TraceLine_Post", 1 )
    RegisterHam( Ham_TakeDamage, "func_breakable", "bacon_TakeDamage", 1 );
    RegisterHam ( Ham_TakeDamage, "func_breakable", "fw_TakeDamage" )
	RegisterHam ( Ham_TakeDamage, "func_breakable", "CEntity__TraceAttack_Sentry")
    register_menu("Menu", keys, "MenuFunc");         
    register_menu("Sentry_4", keys, "Sentry4_Func");                      
    register_touch ( "sentry", "player", "fw_TouchSentry" )                                            
    register_touch("rpg_rocket","*","fw_RpgTouch")
    register_touch("urag","*","fw_UragTouch")	
register_touch("moroz","*","fw_MorozTouch")
	
    register_message ( 23, "msg_TempEntity" )
    register_think ( "sentry", "fw_ThinkSentry" )
    sg_money_upgdate_owner  = register_cvar("sg_money_upgdate_owner","1")
    register_event(    "TextMsg",    "EventGameRestart",    "a",    "2&#Game_will_restart_in"    );
    register_event(    "TextMsg",    "EventGameRestart",    "a",    "2&#Game_C"                    );
	sentry_max_money = register_cvar("sg_max_money_for_kill","16000")
    max_hp_regenSentry = register_cvar("max_hp_regenSentry","255")
	max_ar_regenSentry = register_cvar("max_ar_regenSentry","255")
	max_sentry5_lvl[0] = register_cvar("max_sentry_moroz","1")
	max_sentry5_lvl[1] = register_cvar("max_sentry_tesla","3")
	max_sentry5_lvl[2] = register_cvar("max_sentry_laser","2")
    g_Cvar_mode_cost[0] = register_cvar("sb_mode_cost_auralechenia","75") // РђСѓСЂР° Р»РµС‡РµРЅРёСЏ
    g_Cvar_mode_cost[1] = register_cvar("sb_mode_cost_laser","225") // Р›Р°Р·РµСЂРЅС‹Р№ РІС‹Р¶РёРіР°С‚РµР»СЊ
    g_Cvar_mode_cost[2] = register_cvar("sb_mode_cost_zamorozka","75") // Р—Р°РјРѕСЂРѕР·РєР°           
    g_Cvar_mode_cost[3] = register_cvar("sb_mode_cost_tesla","115") // РўРµСЃР»Р°
    g_Cvar_mode_cost[4] = register_cvar("sb_mode_cost_rokets","150") // Р Р°РєРµС‚С‹ "СЃР°С‚Р°РЅР°"
	g_Cvar_mode_cost[5] = register_cvar("sb_mode_cost_uragan","225") //РЈСЂР°РіР°РЅРЅС‹Р№ РІС‹СЃС‚СЂРµР»
	g_Cvar_mode_cost[6] = register_cvar("sg_mode_cost_auralight","750") //РђСѓСЂР° СЃРІРµС‚Р°
	moroztime = register_cvar("sb_moroz_time", "3")
	moroztime2 = register_cvar("sg_upgrade_moroz_time", "3")
	uragtime = register_cvar("sg_upgrade_charge_time", "1.5")
	uragradius = register_cvar("sg_hurricane_shot_radius", "3")
	g_DMG[0] = register_cvar("sg_dmg_lvl_1", "5")
	g_DMG[1] = register_cvar("sg_dmg_lvl_2", "15")
	g_DMG[2] = register_cvar("sg_dmg_lvl_3", "25")
	g_DMG[3] = register_cvar("sg_dmg_lvl_4", "35")
	g_DMG[4] = register_cvar("sg_dmg_lvl_5", "65")
	g_COST[0] = register_cvar("sg_money_upgdate_sg_lvl_2", "100")
	g_COST[1] = register_cvar("sg_money_upgdate_sg_lvl_3", "200")
	g_COST_VIP[0] = register_cvar("sg_money_upgdate_sg_lvl_2_vip", "0")
	g_COST_VIP[1] = register_cvar("sg_money_upgdate_sg_lvl_3_vip", "0")
	MONEY[0] = register_cvar("sg_money_bonus_update_lvl_2", "111")
	MONEY[1] = register_cvar("sg_money_bonus_update_lvl_3", "333")
	MONEY[2] = register_cvar("sg_money_bonus_update_lvl_4", "444")
	MONEY[3] = register_cvar("sg_money_bonus_update_lvl_5", "555")
	g_HEALTHS[0] = register_cvar("sg_hp_lvl_1", "500")
	g_HEALTHS[1] = register_cvar("sg_hp_lvl_2", "1000")
	g_HEALTHS[2] = register_cvar("sg_hp_lvl_3", "2500")
	g_HEALTHS[3] = register_cvar("sg_hp_lvl_4", "5000")
	g_HEALTHS[4] = register_cvar("sg_hp_lvl_5", "7500")
    register_forward(125, "fm_cmdstart", xs__ITaskId)
    g_iCvar[0]=register_cvar("sb_remont_max","12000.0")    //РґРѕ СЃРєРѕР»СЊРєРё С…Рї РјРѕР¶РЅРѕ Р»РµС‡РёС‚СЊ
	cvar_admin_mul_upg_cost = register_cvar("sentry_admin_mul_upg_cost", "0.8")
	sg_cost_new = register_cvar("sg_cost_new", "0.8")
    g_Cvar_remont[0]=register_cvar("sb_remont_cost","1")
    g_Cvar_remont[1]=register_cvar("sb_remont_health","25.0") 
    takehpar = register_cvar("takehpregenaura","5.0")  
    radiuslechenia = register_cvar("radiuslechenia","225.0") 
    g_Cvar_mode_aktiv[0] = register_cvar("sg_mode_aura_light_on","1") 
    g_Cvar_mode_aktiv[1] = register_cvar("sg_mode_laser_onoff","1") 
    g_Cvar_mode_aktiv[2] = register_cvar("sg_mode_moroz_onoff","1") 
    g_Cvar_mode_aktiv[3] = register_cvar("sg_mode_tesla_onoff","1")
    g_Cvar_mode_aktiv[4] = register_cvar("sg_mode_rocket_onoff","1")
	g_Cvar_mode_aktiv[5] = register_cvar("sg_mode_aura_lechenia_onoff","1")
	g_Cvar_mode_aktiv[6] = register_cvar("sg_mode_urag_onoff","1")
    g_Cvar_smokesentry = register_cvar("sg_smokesentry_hp", "1000")
    cvar_admin_mul_cost = register_cvar("sg_cost_for_vip", "85");                                       
    g_Cvar_mode_led[0] =  register_cvar("sg_led_stop","2.0")
    g_Cvar_mode_led[1] =  register_cvar("sg_led_vreme","7.0")
     dhud_sentryct_te_ON_OFF = register_cvar("dhud_sentryct_te_on_off","1")                            
    g_Cvar_mode_rpg[0] = register_cvar("sb_rpg_radius", "300.0")
    g_Cvar_mode_rpg[1] = register_cvar("sb_rpg_damage", "100.0")         
    g_Cvar_mode_rpg[2] = register_cvar("sb_rpg_dist", "10.0") 
	g_Cvar_mode_rpg[3] = register_cvar("sg_shoot_rocket_time", "2.0") 
	g_Cvar_mode_urag[1] = register_cvar("sg_hurricane_shoot_dmg", "30.0")  
	g_Cvar_mode_tesla[0] = register_cvar("sb_tesla_radius", "200.0")
	g_Cvar_mode_tesla[1] = register_cvar("sg_update_tesla_time", "2.0")
    g_Cvar_mode_moroz[0] =  register_cvar("sg_moroz_radius", "150.0")                          
   sg_dist_update_in_menu_sentry =  register_cvar("sg_dist_update_in_menu_sentry", "250.0")   
     sb_tesla_damage = register_cvar("sb_tesla_damage","25")
sg_rpg_shot_money = register_cvar("sg_rpg_shot_money","25")
sg_tesla_shot_money = register_cvar("sg_tesla_shot_money","25")
sg_player_min = register_cvar("sg_player_min","5")
sg_hurricane_shot_money = register_cvar("sg_hurricane_shot_money","25")	    
    g_msgDamage = get_user_msgid("Damage")
    g_msgDeathMsg = get_user_msgid("DeathMsg")
    g_msgScoreInfo = get_user_msgid("ScoreInfo")
    g_msgHostagePos = get_user_msgid("HostagePos")
    g_msgHostageK = get_user_msgid("HostageK")                                                
    gMsgID = get_user_msgid("StatusIcon")
    g_iMaxPlayers = get_global_int(GL_maxClients)
    g_ONEEIGHTYTHROUGHPI = 180.0 / 3.141592654     
	g_Cvar_nagryzka[1] = register_cvar("nv_info_sentry","0.50")
	SUPREID()
	set_task ( 0.5, "botair", .flags = "b" )
	      /*  new Ent = create_entity ( "info_target" ) 
        register_think ( g_Classname, "frames" )
        entity_set_string ( Ent, EV_SZ_classname, g_Classname )
        entity_set_float ( Ent, EV_FL_nextthink, 1.0 )
		*/
			register_event("ResetHUD", "ResetHUD", "be")
} 
public ResetHUD(id)
{
	set_task(0.5, "VIP", id + 6910)
}
public VIP(TaskID)
{
	new id = TaskID - 6910

	if (is_user_connected(id) && get_user_flags(id) & _Uf_ID_45())
	{
		message_begin(MSG_ALL, get_user_msgid("ScoreAttrib"))
		write_byte(id)
		write_byte(4)
		message_end()
	}
}
SUPREID()
{
	if (get_pcvar_num (dhud_sentryct_te_ON_OFF) > 0 )
	{
	register_logevent("RoundStart", 2, "1=Round_Start")
}
}
public RoundStart()
{
	//remove_task(1)
	//remove_task(2)
		if (get_pcvar_num (dhud_sentryct_te_ON_OFF) > 0 )
	{
	set_task ( get_pcvar_float(g_Cvar_nagryzka[1]), "sgstats", _, _, _, "b" )
	}
}
public sgstats(id)
{
    new messageBuffer[64];  // Р±СѓС„РµСЂ РґР»СЏ С„РѕСЂРјР°С‚РёСЂРѕРІР°РЅРЅРѕР№ СЃС‚СЂРѕРєРё

    set_dhudmessage(15, 25, 255, 0.44, 0.07, 2, 0.0, 0.2, 0.0, 0.70);
    format(messageBuffer, sizeof(messageBuffer), "РљРў:[%d]", g_teamsentriesNum[1]);
    show_dhudmessage(id, messageBuffer);

    set_dhudmessage(255, 25, 25, 0.515, 0.07, 2, 0.0, 0.2, 0.0, 0.70);
    format(messageBuffer, sizeof(messageBuffer), "РўРў:[%d]", g_teamsentriesNum[0]);
    show_dhudmessage(id, messageBuffer);
}

new model_gibs
public getNextSentryCost(id)
{
	new cost
	new lasersmax[1024]
	get_pcvar_string(sentrycost,lasersmax,1023);
	new iCost[30]			
    new buf[30][5]
    
    parse(lasersmax, buf[0], charsmax(buf[]), buf[1], charsmax(buf[]), buf[2], charsmax(buf[]), buf[3], charsmax(buf[]), buf[4], charsmax(buf[]), buf[5], charsmax(buf[]), buf[6], charsmax(buf[]), buf[7], charsmax(buf[]), buf[8], charsmax(buf[]), buf[9], charsmax(buf[]), buf[10], charsmax(buf[]), buf[11], charsmax(buf[]), buf[12], charsmax(buf[]), buf[13], charsmax(buf[]), buf[14], charsmax(buf[]), buf[15], charsmax(buf[]), buf[16], charsmax(buf[]))
    parse(lasersmax, buf[17], charsmax(buf[]), buf[18], charsmax(buf[]), buf[19], charsmax(buf[]), buf[20], charsmax(buf[]), buf[21], charsmax(buf[]), buf[22], charsmax(buf[]), buf[23], charsmax(buf[]), buf[24], charsmax(buf[]), buf[25], charsmax(buf[]), buf[26], charsmax(buf[]), buf[27], charsmax(buf[]), buf[28], charsmax(buf[]), buf[29], charsmax(buf[]))
	new i = sentries_num[id]-1
    
    while(++i < 30)
    {
			    read_argv(i,lasersmax,1023)
        iCost[i] = str_to_num(buf[i])
        server_print("%i", iCost[i])
    
	/*	get_pcvar_string(sentrycost,lasersmax,1023);
	new gCost[100], iCost[100]

	parse(lasersmax, iCost[0], 5, iCost[1], 5, iCost[2], 5, iCost[3], 5, iCost[4], 5, iCost[5], 5, iCost[6], 5, iCost[7], 5, iCost[8], 5, iCost[9], 5, iCost[10], 5, iCost[11], 5, iCost[12], 5, iCost[13], 5, iCost[14], 5, iCost[15], 5, iCost[16], 5, iCost[17], 5, iCost[18], 5, iCost[19], 5, iCost[20], 5)
            parse(lasersmax, iCost[sentries_num[id]], 5);
            gCost[sentries_num[id]] = str_to_num(iCost[sentries_num[id]]);
    */
	//new beruska = SENTRYCOST + ( SENTRYCOST * (sentries_num[id] * floatround(get_pcvar_float(sg_cost_new))))/100
	

    if(get_user_flags(id) & _Uf_ID_45())  
    {
        if(GetSentryCount(id) >= max_sentry_acess) 
        {   	
cost = ((100 - get_pcvar_num(cvar_admin_mul_cost)) * iCost[i])/100	
        }                                               
    }                               
    else                                    
    if(GetSentryCount(id) >= max_sentry) 
{  
cost = iCost[i-1]
	}
		if (_Uf_ID_45() & get_user_flags(id))
	{
		cost = ((100 - get_pcvar_num(cvar_admin_mul_cost)) * iCost[i])/100	
	}
	else
	{
		cost = iCost[i]
	}
	return cost;
	}
		}
new g_MorozChastic
new m_spritetexture
new urag_damage_3, urag_damage_dist
new EFFECT_URAG[90],CILINDER_URAG[90]
new g_Urag, g_CILINDER
new item_On_Off;
new SENTRY_PLAYER_MODEL_1_LVL_TE, SENTRY_PLAYER_MODEL_2_LVL_TE, SENTRY_PLAYER_MODEL_3_LVL_TE, SENTRY_PLAYER_MODEL_4_LVL_TE, SENTRY_PLAYER_MODEL_5_LVL_TE, SENTRY_VIP_MODEL_1_LVL_TE,SENTRY_VIP_MODEL_2_LVL_TE,SENTRY_VIP_MODEL_3_LVL_TE,SENTRY_VIP_MODEL_4_LVL_TE,SENTRY_VIP_MODEL_5_LVL_TE
new SENTRY_PLAYER_MODEL_1_LVL_CT, SENTRY_PLAYER_MODEL_2_LVL_CT, SENTRY_PLAYER_MODEL_3_LVL_CT, SENTRY_PLAYER_MODEL_4_LVL_CT, SENTRY_PLAYER_MODEL_5_LVL_CT, SENTRY_VIP_MODEL_1_LVL_CT,SENTRY_VIP_MODEL_2_LVL_CT,SENTRY_VIP_MODEL_3_LVL_CT,SENTRY_VIP_MODEL_4_LVL_CT,SENTRY_VIP_MODEL_5_LVL_CT
new SENTRYPLAYERMODEL1_TE[90], SENTRYPLAYERMODEL2_TE[90],SENTRYPLAYERMODEL3_TE[90], SENTRYPLAYERMODEL4_TE[90], SENTRYPLAYERMODEL5_TE[90], SENTRYVIPMODEL1_TE[90], SENTRYVIPMODEL2_TE[90],SENTRYVIPMODEL3_TE[90], SENTRYVIPMODEL4_TE[90], SENTRYVIPMODEL5_TE[90]
new SENTRYPLAYERMODEL1_CT[90], SENTRYPLAYERMODEL2_CT[90],SENTRYPLAYERMODEL3_CT[90], SENTRYPLAYERMODEL4_CT[90], SENTRYPLAYERMODEL5_CT[90], SENTRYVIPMODEL1_CT[90], SENTRYVIPMODEL2_CT[90],SENTRYVIPMODEL3_CT[90], SENTRYVIPMODEL4_CT[90], SENTRYVIPMODEL5_CT[90]
new hp_for_kill, max_hp, max_hp_vip, blue_fade, dhudmessage, dhud_rgb, screen_rgb
new szItemMenuVipFlag[64];
new urag_radius;
new Float:urag_damage;
public plugin_precache() {
		new iFile = fopen("addons/amxmodx/configs/Supremej/SentryBuild/SentryBuildSettings.cfg", "rt");
	if(iFile){
		new szLineBuffer[600]
		while(!(feof(iFile))){
			fgets(iFile, szLineBuffer, charsmax(szLineBuffer));
				

			new Imeil[600]
			new Model[600]
			
			parse(szLineBuffer, Imeil, charsmax(Imeil),Model, charsmax(Model));
					
						if(equal(Imeil, "SENTRY_PLAYER_MODEL_1_LVL_TE")){	
				formatex(SENTRYPLAYERMODEL1_TE, charsmax(SENTRYPLAYERMODEL1_TE), "%s", Model);
			}
						if(equal(Imeil, "SENTRY_PLAYER_MODEL_2_LVL_TE")){	
				formatex(SENTRYPLAYERMODEL2_TE, charsmax(SENTRYPLAYERMODEL2_TE), "%s", Model);
			}
						if(equal(Imeil, "SENTRY_PLAYER_MODEL_3_LVL_TE")){	
				formatex(SENTRYPLAYERMODEL3_TE, charsmax(SENTRYPLAYERMODEL3_TE), "%s", Model);
			}
						if(equal(Imeil, "SENTRY_PLAYER_MODEL_4_LVL_TE")){	
				formatex(SENTRYPLAYERMODEL4_TE, charsmax(SENTRYPLAYERMODEL4_TE), "%s", Model);
			}
						if(equal(Imeil, "SENTRY_PLAYER_MODEL_5_LVL_TE")){	
				formatex(SENTRYPLAYERMODEL5_TE, charsmax(SENTRYPLAYERMODEL5_TE), "%s", Model);
			}
						if(equal(Imeil, "SENTRY_VIP_MODEL_1_LVL_TE")){	
				formatex(SENTRYVIPMODEL1_TE, charsmax(SENTRYVIPMODEL1_TE), "%s", Model);
			}
						if(equal(Imeil, "SENTRY_VIP_MODEL_2_LVL_TE")){	
				formatex(SENTRYVIPMODEL2_TE, charsmax(SENTRYVIPMODEL2_TE), "%s", Model);
			}
						if(equal(Imeil, "SENTRY_VIP_MODEL_3_LVL_TE")){	
				formatex(SENTRYVIPMODEL3_TE, charsmax(SENTRYVIPMODEL3_TE), "%s", Model);
			}
						if(equal(Imeil, "SENTRY_VIP_MODEL_4_LVL_TE")){	
				formatex(SENTRYVIPMODEL4_TE, charsmax(SENTRYVIPMODEL4_TE), "%s", Model);
			}
						if(equal(Imeil, "SENTRY_VIP_MODEL_5_LVL_TE")){	
				formatex(SENTRYVIPMODEL5_TE, charsmax(SENTRYVIPMODEL5_TE), "%s", Model);
			}
									if(equal(Imeil, "SENTRY_PLAYER_MODEL_1_LVL_CT")){	
				formatex(SENTRYPLAYERMODEL1_CT, charsmax(SENTRYPLAYERMODEL1_CT), "%s", Model);
			}
						if(equal(Imeil, "SENTRY_PLAYER_MODEL_2_LVL_CT")){	
				formatex(SENTRYPLAYERMODEL2_CT, charsmax(SENTRYPLAYERMODEL2_CT), "%s", Model);
			}
						if(equal(Imeil, "SENTRY_PLAYER_MODEL_3_LVL_CT")){	
				formatex(SENTRYPLAYERMODEL3_CT, charsmax(SENTRYPLAYERMODEL3_CT), "%s", Model);
			}
						if(equal(Imeil, "SENTRY_PLAYER_MODEL_4_LVL_CT")){	
				formatex(SENTRYPLAYERMODEL4_CT, charsmax(SENTRYPLAYERMODEL4_CT), "%s", Model);
			}
						if(equal(Imeil, "SENTRY_PLAYER_MODEL_5_LVL_CT")){	
				formatex(SENTRYPLAYERMODEL5_CT, charsmax(SENTRYPLAYERMODEL5_CT), "%s", Model);
			}
						if(equal(Imeil, "SENTRY_VIP_MODEL_1_LVL_CT")){	
				formatex(SENTRYVIPMODEL1_CT, charsmax(SENTRYVIPMODEL1_CT), "%s", Model);
			}
						if(equal(Imeil, "SENTRY_VIP_MODEL_2_LVL_CT")){	
				formatex(SENTRYVIPMODEL2_CT, charsmax(SENTRYVIPMODEL2_CT), "%s", Model);
			}
						if(equal(Imeil, "SENTRY_VIP_MODEL_3_LVL_CT")){	
				formatex(SENTRYVIPMODEL3_CT, charsmax(SENTRYVIPMODEL3_CT), "%s", Model);
			}
						if(equal(Imeil, "SENTRY_VIP_MODEL_4_LVL_CT")){	
				formatex(SENTRYVIPMODEL4_CT, charsmax(SENTRYVIPMODEL4_CT), "%s", Model);
			}
						if(equal(Imeil, "SENTRY_VIP_MODEL_5_LVL_CT")){	
				formatex(SENTRYVIPMODEL5_CT, charsmax(SENTRYVIPMODEL5_CT), "%s", Model);
			}
									if (equal(Imeil, "sg_max_build_sentry"))
						{
							max_sentry = str_to_num(Model);
						}
												if (equal(Imeil, "sg_max_access_build_sentry"))
						{
							max_sentry_acess = str_to_num(Model);
						}
																		if (equal(Imeil, "sg_sentry_damage_money"))
						{
							sentry_proc_money = str_to_num(Model);
						}
												if (equal(Imeil, "sg_flag_access_build_sentry"))
						{
							copy(szItemMenuVipFlag, 63, Model);
						}

												if (equal(Imeil, "SG_HURRICANE_SHOT_RADIUS"))
						{
							urag_radius = str_to_num(Model);
						}
																		if (equal(Imeil, "SG_HURRICANE_SHOT_DMG"))
						{
							urag_damage = str_to_float(Model);
						}
		}
	}
	new iFile1 = fopen("addons/amxmodx/configs/SupremeJ/vampire/vampire.cfg", "rt");
	if(iFile1){
		new szLineBuffer[600]
		while(!(feof(iFile1))){
			fgets(iFile1, szLineBuffer, charsmax(szLineBuffer));
				
			if(!(szLineBuffer[0]) || szLineBuffer[0] == ';' || szLineBuffer[0] == '#')
			{
				continue;
			}
			new Imeil[600]
			new Model[600]
			
			parse(szLineBuffer, Imeil, charsmax(Imeil),Model, charsmax(Model));
						if (equal(Imeil, "VAMPIRE_BASE_FLAG_ACCESS"))
						{
							copy(szVampirFlag, 63, Model);
						}						
						if (equal(Imeil, "VAMPIRE_SENTRY_GUN_HP"))
						{
							hp_for_kill = str_to_num(Model);
						}	
						if (equal(Imeil, "VAMPIRE_BASE_MAX_HP"))
						{
							max_hp = str_to_num(Model);
						}
						if (equal(Imeil, "VAMPIRE_BASE_MAX_VIP_HP"))
						{
							max_hp_vip = str_to_num(Model);
						}						
						if (equal(Imeil, "VAMPIRE_SENTRY_GUN_SCREEN_ON_OFF"))
						{
							blue_fade = str_to_num(Model);
						}
						if (equal(Imeil, "VAMPIRE_SENTRY_GUN_DHUD_ON_OFF"))
						{
							dhudmessage = str_to_num(Model);
						}
						if (equal(Imeil, "VAMPIRE_SENTRY_GUN_SCREEN_RGB"))
						{
							screen_rgb = str_to_num(Model);
						}						
						if (equal(Imeil, "VAMPIRE_SENTRY_GUN_RGB"))
						{
							dhud_rgb = str_to_num(Model);
						}							
		}
		}
			g_Urag=precache_model("sprites/CSSB/sentry_guns/spr_1.spr")
			g_CILINDER = engfunc(EngFunc_PrecacheModel, CILINDER_URAG)
    for(new i=0;i<sizeof(szModels);i++)                                                     
    precache_model(szModels[i])                                                    
    for(new i=0;i<sizeof(szSounds);i++)                                              
    precache_sound(szSounds[i])
    engfunc(EngFunc_PrecacheModel, SENTRYPLAYERMODEL1_TE)
	engfunc(EngFunc_PrecacheModel, SENTRYPLAYERMODEL2_TE)
	engfunc(EngFunc_PrecacheModel, SENTRYPLAYERMODEL3_TE)
	engfunc(EngFunc_PrecacheModel, SENTRYPLAYERMODEL4_TE)
	engfunc(EngFunc_PrecacheModel, SENTRYPLAYERMODEL5_TE)
	engfunc(EngFunc_PrecacheModel, SENTRYPLAYERMODEL1_CT)
	engfunc(EngFunc_PrecacheModel, SENTRYPLAYERMODEL2_CT)
	engfunc(EngFunc_PrecacheModel, SENTRYPLAYERMODEL3_CT)
	engfunc(EngFunc_PrecacheModel, SENTRYPLAYERMODEL4_CT)
	engfunc(EngFunc_PrecacheModel, SENTRYPLAYERMODEL5_CT)
	engfunc(EngFunc_PrecacheModel, SENTRYVIPMODEL1_TE)
	engfunc(EngFunc_PrecacheModel, SENTRYVIPMODEL2_TE)
	engfunc(EngFunc_PrecacheModel, SENTRYVIPMODEL3_TE)
	engfunc(EngFunc_PrecacheModel, SENTRYVIPMODEL4_TE)
	engfunc(EngFunc_PrecacheModel, SENTRYVIPMODEL5_TE)
	engfunc(EngFunc_PrecacheModel, SENTRYVIPMODEL1_CT)
	engfunc(EngFunc_PrecacheModel, SENTRYVIPMODEL2_CT)
	engfunc(EngFunc_PrecacheModel, SENTRYVIPMODEL3_CT)
	engfunc(EngFunc_PrecacheModel, SENTRYVIPMODEL4_CT)
	engfunc(EngFunc_PrecacheModel, SENTRYVIPMODEL5_CT)
    gHealingBeam = precache_model("sprites/CSSB/sentry_guns/spr_3.spr")
	g_Tesla=precache_model("sprites/CSSB/sentry_guns/spr_9.spr")
    g_iSPR_Explo2=precache_model("sprites/CSSB/sentry_guns/spr_5.spr")   	
    g_Sprite=precache_model("sprites/CSSB/sentry_guns/spr_14.spr")  
    g_sModelIndexMoroz=precache_model("sprites/CSSB/sentry_guns/spr_6.spr")                                        
    g_Chastic=precache_model("sprites/CSSB/sentry_guns/spr_1.spr")
    g_Tessla=precache_model("sprites/CSSB/sentry_guns/spr_13.spr")
	g_Moroz=precache_model("sprites/CSSB/sentry_guns/spr_10.spr") 
	//g_MorozChastic=precache_model("sprites/CSSB/sentry_guns/spr_11.spr") 
	g_Tesssla=precache_model("sprites/CSSB/sentry_guns/spr_12.spr")
	g_blue=precache_model("sprites/laserb.spr")
	g_red=precache_model("sprites/laserr.spr")
	g_auracveta=precache_model("sprites/CSSB/sentry_guns/spr_5.spr")
    g_regen=precache_model("sprites/CSSB/sentry_guns/spr_4.spr")
	g_smoke=precache_model("sprites/CSSB/sentry_guns/spr_8.spr")
	m_spritetexture=precache_model("sprites/CSSB/sentry_guns/spr_7.spr")
}
_Uf_ID_46(id, szShowMessage[256], iRed, iGreen, iBlue)
{
			set_dhudmessage(iRed, iGreen, iBlue,  0.05, 0.96, 2, 0.0, 2.0, 0.02, 0.02);
	show_dhudmessage(id, szShowMessage);
	return 0;
}
public plugin_natives()
{                           
    register_native ( "get_sentry_t", "native_get_sentry_t", 1 )
    register_native ( "get_sentry_ct", "native_get_sentry_ct", 1 )
	register_native ( "get_sentry_team", "native_get_sentry_team", 1 )
	register_native ( "native_Sentry_Build", "native_Sentry_Build", 1 )
	register_native ( "native_Sentry_Menu", "native_Sentry_Menu", 2 )
	register_native ( "native_get_sentry_lvl", "native_get_sentry_lvl", 1 )
}	
public native_get_sentry_lvl(sentry)
{
new level = GetSentryLevel ( sentry )
	return level
}
new vip_menu_block[1]
public native_Sentry_Menu(id, menu)
{
		new iSentryCount = GetSentryCount ( id )
	//iLen += formatex(menu[iLen], charsmax(menu) - iLen, "%L%L%L%L%L%L%L %L %L %L %L^n",id, "VIP", id, "MG_COLOR1", id, "MG[", id, "MG_COLOR2", id, "AWP", id, "MG_COLOR1", id, "MG]", id, "-", id, "MG_COLOR", id, "ITEM_23", id, "COST1", get_pcvar_num(ak_cost_winter) )    
	new szKeyItem[128];
			if (item_On_Off <= 0)
	{
		return 0;
	}
	else
	{
	    if(get_user_flags(id) & _Uf_ID_45())  
    {
        if(GetSentryCount(id) >= max_sentry_acess) 
        {   	
formatex(CSSB_NAME, 255, "%L %L", -1, "ITEM_3_BOLOTO", -1, "BOLOTO_SHOP_COST", 0); 
        }                                               
    }                               
    else                                    
    if(GetSentryCount(id) >= max_sentry) 
{  
formatex(CSSB_NAME, 255, "%L %L", -1, "ITEM_3_BOLOTO", -1, "BOLOTO_SHOP_COST", 0); 
	}
	}
		if (item_On_Off <= 0)
	{
		return 0;
	}
	else
	{
			    if(get_user_flags(id) & _Uf_ID_45())  
    {
		if(GetSentryCount(id) < max_sentry_acess)
		{			
		formatex(CSSB_NAME, 255, "%L %L", -1, "ITEM_3_BOLOTO", -1, "BOLOTO_SHOP_COST", getNextSentryCost(id)); 
		}
	}
	else
	{
				if(GetSentryCount(id) < max_sentry)
		{			
		formatex(CSSB_NAME, 255, "%L %L", -1, "ITEM_3_BOLOTO", -1, "BOLOTO_SHOP_COST", getNextSentryCost(id)); 
		}
	}
	menu_additem(menu, CSSB_NAME); 
}
}
public native_Sentry_Build ( id )
{ 
		if (item_On_Off <= 0)
	{
		//karo4eday_awp_faust(iPlayer)
		return 0
	}
else
{	

    if ( !is_user_alive ( id ) )              
    {
        ChatColor ( id, "%L", id, "SG_ZAPRET_1" )
        return
    }    
		    if ( g_sentriesNum > 60)
	{
	return
	}
        if (get_playersnum() <= get_pcvar_num(sg_player_min))
	{
		ChatColor ( id, "%L", id, "SG_ZAPRET_18", get_pcvar_num(sg_player_min) )
        return
	}
    new iSentryCount = GetSentryCount ( id ) 
    /*                                                                                                   
    if ( iSentryCount == 4 ) //РўРµСЃС‚
    {
        ChatColor ( id, "^4[^3РџСѓС€РєР° Р“РѕР»РёР°С„^4]^1 РќРµР»СЊР·СЏ СѓСЃС‚Р°РЅРѕРІРёС‚СЊ Р±РѕР»РµРµ 4 РїСѓС€РµРє!" )
        return                   
    }                                         
    */ 
    // =======================================================================================================================                             
    if(get_user_flags(id) & _Uf_ID_45())  
    {
        if(GetSentryCount(id) >= max_sentry_acess) 
        {                                          
            ChatColor ( id, "%L", id, "SG_ZAPRET_2", max_sentry_acess )
			emit_sound( id,CHAN_VOICE,"CSSB/sentry_gun/fail_update_1.wav",1.0,0.5,0,PITCH_NORM)
            return                                                              
        }                                               
    }                               
    else                                    
    if(GetSentryCount(id) >= max_sentry) 
    {                                                                           
        ChatColor ( id, "%L", id, "SG_ZAPRET_3", max_sentry)
		emit_sound( id,CHAN_VOICE,"CSSB/sentry_gun/fail_update_1.wav",1.0,0.5,0,PITCH_NORM)
        return                                                              
    }   
    // ======================================================================================================================
    /*if ( g_inBuilding[id] )
    {
        ChatColor ( id,  "%L", id, "SG_ZAPRET_4" )
        return
    }
	*/
    if ( !is_entity_on_ground ( id ) )
    {
        ChatColor ( id, "%L", id, "SG_ZAPRET_5" )
        return
    }
    
    new Float:origin[3],classname[32],e
    entity_get_vector(id,EV_VEC_origin,origin)
                                                               
    while((e = find_ent_in_sphere(e,origin,SENTRYMINDISTANCE))){
        entity_get_string(e,EV_SZ_classname,classname,charsmax(classname))
        
      if(strcmp(classname,"sentrybase") == 0 && GetSentryUpgrader ( e, OWNER ) == id){
            ChatColor(id,"%L", id, "SG_ZAPRET_6")
            emit_sound( id,CHAN_VOICE,"CSSB/sentry_gun/fail_update_1.wav",1.0,0.5,0,PITCH_NORM)
            return                                                                                  
        }
		      if(strcmp(classname,"sentrybase") == 0 && cs_get_user_team(GetSentryUpgrader ( e, OWNER )) == cs_get_user_team(id) && GetSentryUpgrader ( e, OWNER ) != id){
            ChatColor(id,"%L", id, "SG_ZAPRET_13")
            emit_sound( id,CHAN_VOICE,"CSSB/sentry_gun/fail_update_1.wav",1.0,0.5,0,PITCH_NORM)
            return                                                                                  
        }
    }                   
    
    if ( cs_get_user_money ( id ) < getNextSentryCost(id))
    {
        ChatColor ( id, "%L", id, "SG_ZAPRET_7", getNextSentryCost(id))
    emit_sound( id,CHAN_VOICE,"CSSB/sentry_gun/fail_update_1.wav",1.0,0.5,0,PITCH_NORM)
        return                                                                  
    }
	

    new Float:fPlayerOrigin[3], Float:fOrigin[3], Float:fAngle[3]
    pev ( id, pev_origin, fPlayerOrigin )
    pev ( id, pev_angles, fAngle )                      
    fOrigin = fPlayerOrigin

    fOrigin[0] += floatcos ( fAngle[1], degrees ) * PLACE_RANGE
    fOrigin[1] += floatsin ( fAngle[1], degrees ) * PLACE_RANGE
    fOrigin[0] += floatcos ( fAngle[0], degrees) * PLACE_RANGE
    fOrigin[1] += floatcos ( fAngle[1], degrees )
    fOrigin[0] -= floatsin ( fAngle[1], degrees )
    fOrigin[1] += floatcos ( fAngle[2], degrees )
    fOrigin[1] -= floatsin ( fAngle[2], degrees ) * PLACE_RANGE
    fOrigin[0] -= floatsin ( fAngle[0], degrees ) * PLACE_RANGE
    fOrigin[0] -= PLACE_RANGE

    if ( pev ( id, pev_flags ) & FL_DUCKING )
    fOrigin[2] += 18.0, fPlayerOrigin[2] += 18.0
                                                                                           
    new tr = 0, Float:fFraction
    engfunc ( EngFunc_TraceLine, fPlayerOrigin, fOrigin, 0, id, tr )
    get_tr2 ( tr, TR_flFraction, fFraction )

    if ( fFraction != 1.0 )
    {                                                              
        ChatColor ( id, "%L", id, "SG_ZAPRET_8" )
        return  
    }                                        

    if ( CreateSentryBase ( fOrigin, id ) )
    {
 		       cs_set_user_money(id, cs_get_user_money(id) - getNextSentryCost(id));
			   	ChatColor ( id, "%L %L", -1, "PREFIX_CSDM_SHOP", -1, "BOLOTO_BUY_ITEM", -1, "ITEM_3_BOLOTO", getNextSentryCost(id))	
        ammo_hud ( id, 0 )
		sentries_num[id] += 1
		ammo_hud ( id, 1 )
    }
    else
    ChatColor ( id, "%L", id, "SG_ZAPRET_8" )       
    return                                       
} 
}
public frames (ent)
{      
    new tempSentries[MAXSENTRIES], tempSentriesNum = 0
    for (new i = 0; i < g_sentriesNum; i++) {
        tempSentries[i] = g_sentries[i]
        tempSentriesNum++
    }

    for (new i = 0; i < tempSentriesNum; i++) {
        if (!is_valid_ent(tempSentries[i]))
            continue

        if (!sentry_pendulum(tempSentries[i]))
            continue
    }

    // РР·РјРµРЅРµРЅРѕ СЃ 0.05 РЅР° 0.0167 РґР»СЏ 60 FPS (1/60 = 0.0167)
    entity_set_float(ent, EV_FL_nextthink, get_gametime() + 0.0167) 
    return PLUGIN_CONTINUE
}
_Uf_ID_47()
{
	return read_flags(szItemMenuVipFlag);
}
_Uf_ID_45()
{
	return read_flags(szVampirFlag);
}
public native_get_sentry_t()
{
    return g_teamsentriesNum[0]
}
                                                                                                            
public native_get_sentry_ct()
{
    return g_teamsentriesNum[1]       
} 
                                                                                                                           
public native_get_sentry_people ( sentry, who )        
{                                                                                 
    //РР·РјРµРЅРёС‚СЊ РґР»СЏ РІРµСЂРЅРѕР№ СЂР°Р±РѕС‚С‹, СѓР·РЅР°С‚СЊ РіРґРµ РѕРЅ РїРѕР»СѓС‡Р°РµС‚СЃСЏ Рё РїРѕРјРµРЅСЏС‚СЊ РЅР°С‚РёРІС‹.
    return GetSentryUpgrader ( sentry, who )    
}

public CsTeams:native_get_sentry_team ( sentry ) 
{                                                            
    return GetSentryTeam ( sentry )  
}                                                   

public native_sentry_detonate_by_owner ( id )
{
    while(GetSentryCount(id) > 0)    
    sentry_detonate_by_owner(id)
}   
public EventGameRestart()
{                                                                                                       
    higher_score = 0;             
    g_OwnName = "РћСЃС‚СѓС‚СЃС‚РІСѓРµС‚";                                                   
}

public ev_Spectation ()
{
    new id = read_data ( 1 )

    if ( is_user_connected ( id ) && cs_get_user_team ( id ) == CS_TEAM_SPECTATOR )
    while ( GetSentryCount ( id ) > 0 )                 
    sentry_detonate_by_owner ( id )
}
public fw_TakeDamage( ent, damage, idinflictor, idattacker, sentry )
{                                                       
    if ( !pev_valid ( ent ) )
    return HAM_IGNORED

    new sClassname[11]      
    pev ( ent, pev_classname, sClassname, charsmax ( sClassname ) )
                        
    if ( equal ( sClassname, "sentry" ) || equal ( sClassname, "sentrybase" ) )
    {   
		 new iOwner = GetSentryUpgrader ( ent, OWNER )
        if ( !is_user_connected ( iOwner ) || !is_valid_player ( iOwner ) || !is_user_connected ( idattacker ) || !is_valid_player ( idattacker ) )
        return HAM_IGNORED
                 
        if ( cs_get_user_team ( iOwner ) == cs_get_user_team ( idattacker ) && idattacker != iOwner )
        return HAM_SUPERCEDE   

        if ( idattacker == iOwner )
        return HAM_IGNORED 
   
				cs_set_user_money ( idattacker, cs_get_user_money (idattacker) + (floatround(damage) * sentry_proc_money)/100)
	
        new Float:entorigin[3]
        pev( ent, pev_origin, entorigin )

        
        
        message_begin(MSG_ALL, SVC_TEMPENTITY);                                                                            
        write_byte(TE_SPRITETRAIL);
        engfunc(EngFunc_WriteCoord, entorigin[0] + random_num(- 15, 15));
        engfunc(EngFunc_WriteCoord, entorigin[1] + random_num(- 15, 15));
        engfunc(EngFunc_WriteCoord, entorigin[2] + random_num(10, 30));
        engfunc(EngFunc_WriteCoord, entorigin[0] - random_num(- 30, 30));
        engfunc(EngFunc_WriteCoord, entorigin[1] - random_num(- 30, 30));
        engfunc(EngFunc_WriteCoord, entorigin[2] + random_num(- 30, 30));
        write_short(g_Chastic); // РРЅРґРµРєСЃ СЃРїСЂР°Р№С‚Р° РёР· РїСЂРµРєРµС€Р° (index of precached sprite)
        write_byte(random_num(3,6));    //РєРѕР»Р»РёС‡РµСЃС‚РІРѕ СЃРїСЂР°Р№С‚РѕРІ
        write_byte(1); //РІСЂРѕРґРµ РІСЂРµРјСЏ СЃСѓС‰РёСЃС‚РІРѕРІР°РЅРёСЏ                         
        write_byte(1); //СЂР°Р·РјРµСЂ     
        write_byte(1); // 10's
        write_byte(5); // 10's         
        message_end();        
          emit_sound ( ent, CHAN_AUTO, "CSSB/sentry_gun/metal_2.wav", 1.0, ATTN_NORM, 0, PITCH_NORM )                                                 
                    

    }      
    return HAM_IGNORED    
}
public CEntity__TraceAttack_Sentry(victim, inflictor, attacker, Float:damage)
{
		new ent
  		while( ( ent = find_ent_by_class( ent, "sentry" ) ) )
	{
		new level = GetSentryLevel ( ent )
	if (GetSentryTeam(ent) == cs_get_user_team(attacker))
	{
		if (ent == victim)
		{
			if ( level < 1)
		{
	SetHamParamFloat(4, damage * 0 +300 );
		}
		else
		{
			SetHamParamFloat(4, damage * 0);
		}
	}
	}
	else
	{
		cs_set_user_money ( attacker, cs_get_user_money (attacker) + (floatround(damage) * sentry_proc_money)/100)
	}
}
}

public cmd_CreateSentry ( id )
{                                               
    new iSentry = AimingAtSentry ( id )

    if ( iSentry && entity_range ( iSentry, id ) <= MAXUPGRADERANGE )              
    SentryUpgrade ( id, iSentry, 0)
    else  
    SentryBuild ( id )

	
    return PLUGIN_HANDLED
}

public SentryBuild ( id )
{                                                                                                                           
    if ( !is_user_alive ( id ) )              
    {
        ChatColor ( id, "%L", id, "SG_ZAPRET_1" )
        return
    }    
	    if ( g_sentriesNum > 60)
	{
	return
	}
    if (get_playersnum() <= get_pcvar_num(sg_player_min))
	{
		ChatColor ( id, "%L", id, "SG_ZAPRET_18", get_pcvar_num(sg_player_min) )
        return
	}
    new iSentryCount = GetSentryCount ( id ) 
    /*                                                                                                   
    if ( iSentryCount == 4 ) //РўРµСЃС‚
    {
        ChatColor ( id, "^4[^3РџСѓС€РєР° Р“РѕР»РёР°С„^4]^1 РќРµР»СЊР·СЏ СѓСЃС‚Р°РЅРѕРІРёС‚СЊ Р±РѕР»РµРµ 4 РїСѓС€РµРє!" )
        return                   
    }                                         
    */ 
    // =======================================================================================================================                             
    if(get_user_flags(id) & _Uf_ID_47())  
    {
        if(GetSentryCount(id) >= max_sentry_acess) 
        {                                          
            ChatColor ( id, "%L", id, "SG_ZAPRET_2", max_sentry_acess )
            emit_sound( id,CHAN_VOICE,"CSSB/sentry_gun/fail_update_1.wav",1.0,0.5,0,PITCH_NORM)
            return                                                              
        }                                               
    }                               
    else                                    
    if(GetSentryCount(id) >= max_sentry) 
    {                                                                           
        ChatColor ( id, "%L", id, "SG_ZAPRET_3", max_sentry)
        emit_sound( id,CHAN_VOICE,"CSSB/sentry_gun/fail_update_1.wav",1.0,0.5,0,PITCH_NORM)
        return                                                              
    }   
    // ======================================================================================================================
  /* if ( g_inBuilding[id] )
    {
        ChatColor ( id,  "%L", id, "SG_ZAPRET_4" )

        return
    }
	*/
    if ( !is_entity_on_ground ( id ) )
    {
        ChatColor ( id, "%L", id, "SG_ZAPRET_5" )
        return
    }
    
    new Float:origin[3],classname[32],e
    entity_get_vector(id,EV_VEC_origin,origin)
                                                             
    while((e = find_ent_in_sphere(e,origin,SENTRYMINDISTANCE))){
        entity_get_string(e,EV_SZ_classname,classname,charsmax(classname))
        
      if(strcmp(classname,"sentrybase") == 0 && GetSentryUpgrader ( e, OWNER ) == id){
            ChatColor(id,"%L", id, "SG_ZAPRET_6")
            emit_sound( id,CHAN_VOICE,"CSSB/sentry_gun/fail_update_1.wav",1.0,0.5,0,PITCH_NORM)
            return                                                                                  
        }
		      if(strcmp(classname,"sentrybase") == 0 && GetSentryTeam(e) == _:cs_get_user_team(id) && GetSentryUpgrader ( e, OWNER ) != id){
            ChatColor(id,"%L", id, "SG_ZAPRET_6")
            emit_sound( id,CHAN_VOICE,"CSSB/sentry_gun/fail_update_1.wav",1.0,0.5,0,PITCH_NORM)
            return                                                                                  
        }
    }               
    
    if ( cs_get_user_money ( id ) < getNextSentryCost(id))
    {
        ChatColor ( id, "%L", id, "SG_ZAPRET_7", getNextSentryCost(id))
		emit_sound( id,CHAN_VOICE,"CSSB/sentry_gun/fail_update_1.wav",1.0,0.5,0,PITCH_NORM)
        return                                                                  
    }
	

    new Float:fPlayerOrigin[3], Float:fOrigin[3], Float:fAngle[3]
    pev ( id, pev_origin, fPlayerOrigin )
    pev ( id, pev_angles, fAngle )                      
    fOrigin = fPlayerOrigin

    fOrigin[0] += floatcos ( fAngle[1], degrees ) * PLACE_RANGE
    fOrigin[1] += floatsin ( fAngle[1], degrees ) * PLACE_RANGE
    fOrigin[0] += floatcos ( fAngle[0], degrees) * PLACE_RANGE
    fOrigin[1] += floatcos ( fAngle[1], degrees )
    fOrigin[0] -= floatsin ( fAngle[1], degrees )
    fOrigin[1] += floatcos ( fAngle[2], degrees )
    fOrigin[1] -= floatsin ( fAngle[2], degrees ) * PLACE_RANGE
    fOrigin[0] -= floatsin ( fAngle[0], degrees ) * PLACE_RANGE
    fOrigin[0] -= PLACE_RANGE

    if ( pev ( id, pev_flags ) & FL_DUCKING )
    fOrigin[2] += 18.0, fPlayerOrigin[2] += 18.0
                                                                                           
    new tr = 0, Float:fFraction
    engfunc ( EngFunc_TraceLine, fPlayerOrigin, fOrigin, 0, id, tr )
    get_tr2 ( tr, TR_flFraction, fFraction )

    if ( fFraction != 1.0 )
    {                                                              
        ChatColor ( id, "%L", id, "SG_ZAPRET_8" )
        return  
    }                                        

    if ( CreateSentryBase ( fOrigin, id ) )
    {     
		       cs_set_user_money(id, cs_get_user_money(id) - getNextSentryCost(id));
			   
        ammo_hud ( id, 0 )
		sentries_num[id] += 1
		ammo_hud ( id, 1 )
    }
    else
    ChatColor ( id, "%L", id, "SG_ZAPRET_8" )       
    return                                       
}                              

public fm_cmdstart(id, uc_handle, seed) {
if(!is_user_alive(id)) return
if(g_fTime[id]>get_gametime()) return

static Button, OldButtons;
Button = get_uc(uc_handle, UC_Buttons);
OldButtons = pev(id, pev_oldbuttons);
new iTime
new Float:Max=get_pcvar_float(g_iCvar[0])
new Masx=get_pcvar_num(g_iCvar[0])
new Float:Health
if(Button & IN_USE && !(OldButtons & IN_USE))
{
new target, body
get_user_aiming(id, target, body, 128)

static ClassName[32]
pev(target, pev_classname, ClassName, charsmax(ClassName))
if (equal(ClassName, "sentry"))
{
	pev(target, pev_health, Health)
	if(Health>=Max)
	{
		message_begin(MSG_ONE, 108, _, id)
write_byte(iTime)
write_byte(0)
message_end()
	}
	else
	{
message_begin(MSG_ONE, 108, _, id)
write_byte(4)
write_byte(1)
message_end()
	}
}
}
if((Button & IN_USE))
{
new target, body
get_user_aiming(id, target, body, 128)

static ClassName[32]
pev(target, pev_classname, ClassName, charsmax(ClassName))
if (equal(ClassName, "sentry"))
{

g_fTime[id]=get_gametime()+0.2


pev(target, pev_health, Health)
if(cs_get_user_money(id) < 1) return

if(Health>=Max)return


	new szShowMessage[256]
	_Uf_ID_44(id, szShowMessage, 252, 230, 38);	
show_dhudmessage (id, "Р—РґРѕСЂРѕРІСЊРµ РїСѓС€РєРё %d РёР· %d", floatround(Health), floatround(Max))
g_fTime[id]=get_gametime()+0.1

Health+=get_pcvar_float(g_Cvar_remont[1])
cs_set_user_money( id, cs_get_user_money( id ) - get_pcvar_num(g_Cvar_remont[0])*get_pcvar_num(g_Cvar_remont[1]))

set_pev(target, pev_health, Health)

}
}
if(!(Button & IN_USE))
{
message_begin(MSG_ONE, 108, _, id)
write_byte(iTime)
write_byte(0)
message_end()
}
}
_Uf_ID_29(id, iClear)
{
	new iDHUD;
	while (iDHUD < iClear)
	{
		set_dhudmessage(0, 0, 0, 0.0, 0.0, 0, 0.0, 0.0, 0.0, 0.0);
		show_dhudmessage(id, "");
		iDHUD++;
	}
	return 0;
}
_Uf_ID_44(id, szShowMessage[256], iRed, iGreen, iBlue)
{
	_Uf_ID_29(id, 9);
	set_dhudmessage(iRed, iGreen, iBlue, -1.0, -1.0, 2, 0.0, 0.2, 0.0, 0.50);
		show_dhudmessage(id, szShowMessage);
	return 0;
}



DecreaseSentryCount ( id, sentry )
{
    for ( new i; i < g_iPlayerSentries[id]; i++ )
    {                                         
        if ( g_iPlayerSentriesEdicts[id][i] == sentry )
        {
            g_iPlayerSentriesEdicts[id][i] = g_iPlayerSentriesEdicts[id][g_iPlayerSentries[id] - 1]
            g_iPlayerSentriesEdicts[id][g_iPlayerSentries[id] - 1] = 0
  
        }                                                   
    }
    if ( g_iPlayerSentries[id] > 0 ) g_iPlayerSentries[id]--                                          
}

stock bool:CreateSentryBase ( Float:origin[3], creator, level = SENTRY_LEVEL_1 )
{                                                                                                
    if ( !CheckLocation ( origin ) )
        return false

    new Float:hitPoint[3], Float:originDown[3]
    originDown = origin
    originDown[2] -= 500.0; // dunno the lowest possible height...
    trace_line(0, origin, originDown, hitPoint)
    new Float:baDistanceFromGround = vector_distance(origin, hitPoint)
                                               
    new Float:difference = PLAYERORIGINHEIGHT - baDistanceFromGround
    if (difference < -1 * HEIGHTDIFFERENCEALLOWED || difference > HEIGHTDIFFERENCEALLOWED) return false

    new entbase = create_entity("func_breakable") // func_wall               
    if (!entbase)
        return false                  

    #define SIZE 16.0
                                                                                                              
    new Float:fTraceEnds[5][3], Float:fTraceHit[3], iType, tr = create_tr2 ()
    fTraceEnds[0][0] = origin[0] - SIZE
    fTraceEnds[0][1] = origin[1] - SIZE
    fTraceEnds[0][2] = origin[2] + SIZE + SIZE
    fTraceEnds[1][0] = origin[0] + SIZE
    fTraceEnds[1][1] = origin[1] - SIZE 
    fTraceEnds[1][2] = origin[2] + SIZE + SIZE
    fTraceEnds[2][0] = origin[0] - SIZE
    fTraceEnds[2][1] = origin[1] + SIZE
    fTraceEnds[2][2] = origin[2] + SIZE + SIZE
    fTraceEnds[3][0] = origin[0] + SIZE
    fTraceEnds[3][1] = origin[1] + SIZE
    fTraceEnds[3][2] = origin[2] + SIZE + SIZE
    fTraceEnds[4][0] = origin[0]
    fTraceEnds[4][1] = origin[1]
    fTraceEnds[4][2] = origin[2] + SIZE + SIZE

    for ( new i; i < 5; i++ )
    {
        fTraceHit = fTraceEnds[i]
        fTraceHit[2] += 40.0

        engfunc ( EngFunc_TraceLine, fTraceEnds[i], fTraceHit, 0, 0, tr )
        get_tr2 ( tr, TR_vecEndPos, fTraceHit )

        if ( fTraceHit[2] - fTraceEnds[i][2] != 40.0 )
        {
            iType = 1
            
        }
    }

    if ( iType )
    {
        fTraceEnds[0][0] = origin[0] - SIZE
        fTraceEnds[0][1] = origin[1] - SIZE
        fTraceEnds[0][2] = origin[2] - SIZE - SIZE
        fTraceEnds[1][0] = origin[0] + SIZE
        fTraceEnds[1][1] = origin[1] - SIZE
        fTraceEnds[1][2] = origin[2] - SIZE - SIZE
        fTraceEnds[2][0] = origin[0] - SIZE
        fTraceEnds[2][1] = origin[1] + SIZE
        fTraceEnds[2][2] = origin[2] - SIZE - SIZE
        fTraceEnds[3][0] = origin[0] + SIZE
        fTraceEnds[3][1] = origin[1] + SIZE
        fTraceEnds[3][2] = origin[2] - SIZE - SIZE                                                                    
        fTraceEnds[4][0] = origin[0]
        fTraceEnds[4][1] = origin[1]
        fTraceEnds[4][2] = origin[2] - SIZE - SIZE
        new Float:fMinDistance, Float:fDistance
        for ( new i; i < 5; i++ )
        {
            fTraceHit[0] = fTraceEnds[i][0]
            fTraceHit[1] = fTraceEnds[i][1]
            fTraceHit[2] = -8192.0
    
            engfunc ( EngFunc_TraceLine, fTraceEnds[i], fTraceHit, IGNORE_MONSTERS, 0, tr )
            get_tr2 ( tr, TR_vecEndPos, fTraceHit )
    
            fDistance = vector_distance ( fTraceEnds[i], fTraceHit )
    
            if ( fDistance < fMinDistance || fMinDistance <= 0.0 )
            {
                fMinDistance = fDistance
                origin[2] = fTraceHit[2]                                                                                      
            }
        }
    }

    new Float:fHighest[3]
    fHighest = origin
    fHighest[2] = 0.0
    engfunc ( EngFunc_TraceLine, origin, fHighest, DONT_IGNORE_MONSTERS, 0, tr )
    get_tr2 ( tr, TR_vecEndPos, fHighest )
    free_tr2 ( tr )

    new healthstring[16]               
    num_to_str(floatround(get_pcvar_float(g_HEALTHS[0])), healthstring, 15)
    DispatchKeyValue(entbase, "health", healthstring)
    DispatchKeyValue(entbase, "material", "6")  
new ent = create_entity("func_breakable")
    DispatchSpawn(entbase)                      
    entity_set_string(entbase, EV_SZ_classname, "sentrybase")
    entity_set_model(entbase, "models/cssb/sentry_v6/base.mdl") // later set according to level
    SetSentryUpgrader ( entbase, OWNER, creator )   
    new Float:mins[3], Float:maxs[3]
    mins[0] = -16.0
    mins[1] = -16.0
    mins[2] = 0.0
    maxs[0] = 16.0                                                            
    maxs[1] = 16.0
    maxs[2] = floatclamp ( vector_distance ( origin, fHighest ), 128.0, 1000.0 ) // Set to 16.0 later.
    entity_set_origin(entbase, origin)
    entity_set_int(entbase, EV_INT_solid, SOLID_SLIDEBOX)
    entity_set_int(entbase, EV_INT_movetype, iType ? MOVETYPE_FLY : MOVETYPE_TOSS) // head flies base falls
	entity_set_edict(ent, SENTRY_ENT_BASE, entbase)
    entity_set_int(entbase, BASE_INT_TEAM, ent)
            entity_set_size(entbase, mins, maxs)
             drop_to_floor(entbase)       
emit_sound(entbase, CHAN_VOICE, "CSSB/sentry_gun/build_1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)			 
    new parms[4]
    parms[0] = entbase
    parms[1] = creator
    parms[3] = iType

    if ( iType ) origin[2] += 0.0                     

    g_sentryOrigins[creator - 1] = origin
                              
     createsentryhead( parms, 4)
    return true
}
                                                       
public createsentryhead(parms[4], id)
{ 
    new entbase = parms[0]
    new level = parms[2]
    new creator = parms[1]
    new iType = parms[3]

    if ( !is_user_connected ( creator )  )
    {
        if (is_valid_ent(entbase))
        remove_entity(entbase)

        return       
    }
    new CsTeams:crteam = cs_get_user_team(creator)
    if ( !is_valid_team ( _:crteam ) )
    {
        if (is_valid_ent(entbase))
        remove_entity(entbase)

        sentries_num[creator]--
			g_SentryLaser[creator]--
	g_SentryFreezing[creator]--
	g_SentryTesla[creator]--
        return
    }

    new Float:origin[3]                  
    origin = g_sentryOrigins[creator - 1]

    new ent = create_entity("func_breakable")
    if (!ent)                              
    {
        if (is_valid_ent(entbase))
        {
            remove_entity(entbase)
        }
        return
    }

    new Float:mins[3], Float:maxs[3]
    if (is_valid_ent(entbase)) {
        mins[0] = -10.0
        mins[1] = -10.0
        mins[2] = 0.0       
                              
        maxs[0] = 10.0
        maxs[1] = 10.0
        maxs[2] = 22.5
        entity_set_size(entbase, mins, maxs)
                                                      
        entity_set_edict(ent, SENTRY_ENT_BASE, entbase)
        entity_set_edict(entbase, BASE_ENT_SENTRY, ent)
    }                  

    g_sentries[g_sentriesNum] = ent

    new healthstring[16]
    num_to_str(floatround(get_pcvar_float(g_HEALTHS[0])), healthstring, 15)
    DispatchKeyValue(ent, "health", healthstring)
    DispatchKeyValue(ent, "material", "6")

    DispatchSpawn(ent)
    entity_set_string(ent, EV_SZ_classname, "sentry")
	
	 new Vipsenrty = get_user_flags(creator) & _Uf_ID_47()
	  if (get_user_flags(creator) & _Uf_ID_47())
	 {
		switch(_:crteam)
	{
    case 1:
        {
            switch(level)     
            {
            case SENTRY_LEVEL_1: entity_set_model(ent, SENTRYVIPMODEL1_TE)
            }
          }		
    case 2:
        {
            switch(level)
            {
            case SENTRY_LEVEL_1: entity_set_model(ent, SENTRYVIPMODEL1_CT)
            }
        }
    }
	 }
	 else 
	 {
	switch(_:crteam)
	{
    case 1:
        {
            switch(level)     
            {
            case SENTRY_LEVEL_1: entity_set_model(ent, SENTRYPLAYERMODEL1_TE)
            }
          }		
    case 2:
        {
            switch(level)
            {
            case SENTRY_LEVEL_1: entity_set_model(ent, SENTRYPLAYERMODEL1_CT)
            }
        }
    }
	 }
    mins[0] = -16.0
    mins[1] = -16.0
    mins[2] = 0.0
    maxs[0] = 16.0
    maxs[1] = 16.0
    maxs[2] = 16.0 
    entity_set_size(ent, mins, maxs)
    entity_set_origin(ent, origin)
    entity_get_vector(creator, EV_VEC_angles, origin)                               
    origin[0] = 0.0
    origin[1] += 180.0
    entity_set_float(ent, SENTRY_FL_ANGLE, origin[1])
    origin[2] = 0.0
    entity_set_vector(ent, EV_VEC_angles, origin)                            
    entity_set_int(ent, EV_INT_solid, SOLID_BBOX) // SOLID_SLIDEBOX       
    entity_set_int(ent, EV_INT_movetype,  iType ? MOVETYPE_FLY : MOVETYPE_TOSS) // head flies, base doesn't
	drop_to_floor(ent) 

    
           
    SetSentryUpgrader(ent, OWNER, creator)
    
    SetSentryTeam ( ent, crteam )
    SetSentryLevel ( ent, level )

    g_teamsentriesNum[_:crteam-1]++

    new directions = (random_num(0, 1)<<SENTRY_DIR_CANNON)
 IncreaseSentryCount(creator, ent)

    entity_set_float ( ent, SENTRY_FL_LASTTHINK, get_gametime () + g_THINKFREQUENCIES )
    entity_set_float ( ent, EV_FL_nextthink, get_gametime () + 0.01 )
                                                                
    /*static bool:bHamRegistred

    if ( !bHamRegistred )
    {
        RegisterHamFromEntity ( Ham_Think, ent, "fw_ThinkSentry", 1 )
        bHamRegistred = true
    }*/
}
IncreaseSentryCount ( id, sentry )
{
    g_iPlayerSentriesEdicts[id][g_iPlayerSentries[id]] = sentry
    g_iPlayerSentries[id]++
    new Float:fSentryOrigin[3], iSentryOrigin[3], iPlayerOrigin[3]
    entity_get_vector ( sentry, EV_VEC_origin, fSentryOrigin )
    FVecIVec ( fSentryOrigin, iSentryOrigin )

    new sName[32]
    get_user_name ( id, sName, charsmax ( sName ) )
    new CsTeams:iTeam = cs_get_user_team ( id )

    for ( new i = 1; i <= g_iMaxPlayers; i++ )
    {
        if ( !is_user_connected ( i ) || !is_user_alive ( i ) || cs_get_user_team ( i ) != iTeam || id == i )
        continue

        get_user_origin ( i, iPlayerOrigin )                                                           
        ChatColor ( i, "%L", i, "SG_INFORMER_1",  sName, get_distance ( iPlayerOrigin, iSentryOrigin ) )
        
        message_begin ( MSG_ONE_UNRELIABLE, g_msgHostagePos, .player = i )
        write_byte ( i )
        write_byte ( SENTRY_RADAR_TEAMBUILT )
        write_coord ( iSentryOrigin[0] )
        write_coord ( iSentryOrigin[1] )
        write_coord ( iSentryOrigin[2] )
        message_end ()

        message_begin ( MSG_ONE_UNRELIABLE, g_msgHostageK, .player = i )
        write_byte ( SENTRY_RADAR_TEAMBUILT )
        message_end ()                                                                            
    }
}
stock bool:CheckLocation ( const Float:origin[3] )
{                                                                             
    if ( engfunc ( EngFunc_PointContents, origin ) != CONTENTS_EMPTY )
    return false

    new tr = create_tr2 ()

    engfunc ( EngFunc_TraceHull, origin, origin, 0, HULL_HEAD/*HUMAN*/, 0, tr )
    if ( !get_tr2 ( tr, TR_InOpen ) || get_tr2 ( tr, TR_StartSolid ) || get_tr2 ( tr, TR_AllSolid ) )
    {             
        free_tr2 ( tr )
        return false
    }

    #define SIZE 16.0

    new Float:fTraceEnds[9][3], Float:fTraceHit[3], iHitEnt
    fTraceEnds[0][0] = origin[0]
    fTraceEnds[0][1] = origin[1]
    fTraceEnds[0][2] = origin[2] - SIZE - SIZE
    fTraceEnds[1][0] = origin[0] - SIZE                
    fTraceEnds[1][1] = origin[1] - SIZE
    fTraceEnds[1][2] = origin[2] - SIZE - SIZE
    fTraceEnds[2][0] = origin[0] + SIZE
    fTraceEnds[2][1] = origin[1] - SIZE
    fTraceEnds[2][2] = origin[2] - SIZE - SIZE
    fTraceEnds[3][0] = origin[0] - SIZE
    fTraceEnds[3][1] = origin[1] + SIZE
    fTraceEnds[3][2] = origin[2] - SIZE - SIZE
    fTraceEnds[4][0] = origin[0] + SIZE
    fTraceEnds[4][1] = origin[1] + SIZE
    fTraceEnds[4][2] = origin[2] - SIZE - SIZE
    fTraceEnds[5][0] = origin[0] - SIZE
    fTraceEnds[5][1] = origin[1] - SIZE
    fTraceEnds[5][2] = origin[2] + SIZE + SIZE
    fTraceEnds[6][0] = origin[0] + SIZE
    fTraceEnds[6][1] = origin[1] - SIZE
    fTraceEnds[6][2] = origin[2] + SIZE + SIZE
    fTraceEnds[7][0] = origin[0] - SIZE
    fTraceEnds[7][1] = origin[1] + SIZE
    fTraceEnds[7][2] = origin[2] + SIZE + SIZE
    fTraceEnds[8][0] = origin[0] + SIZE                                                                
    fTraceEnds[8][1] = origin[1] + SIZE
    fTraceEnds[8][2] = origin[2] + SIZE + SIZE

    for (new i = 0, b = 0; i < 9; i++)
    {
        if ( engfunc ( EngFunc_PointContents, fTraceEnds[i] ) != CONTENTS_EMPTY )
        {
            free_tr2 ( tr )
            return false
        }

        engfunc ( EngFunc_TraceLine, origin, fTraceEnds[i], 0, 0, tr )
        iHitEnt = get_tr2 ( tr, TR_pHit )

        if ( iHitEnt != -1 )
        {
            free_tr2 ( tr )
            return false
        }

        get_tr2 ( tr, TR_vecEndPos, fTraceHit )

        for ( b = 0; b < 3; b++ )
        {
            if ( fTraceEnds[i][b] != fTraceHit[b] )
            {
                free_tr2 ( tr )
                return false
            }
        }
        if ( i < 5 )
        {
            fTraceHit[0] = fTraceEnds[i][0]
            fTraceHit[1] = fTraceEnds[i][1]
            fTraceHit[2] = -8192.0

            engfunc ( EngFunc_TraceLine, fTraceEnds[i], fTraceHit, 0, 0, tr )
            //get_tr2 ( tr, TR_vecEndPos, fTraceHit )
            iHitEnt = get_tr2 ( tr, TR_pHit )

            if ( pev_valid ( iHitEnt ) )
            {
                new sClassname[16]
                pev ( iHitEnt, pev_classname, sClassname, charsmax ( sClassname ) )
                if ( equal ( sClassname, "sentry" ) || equal ( sClassname, "NDispenser" ) )
                {
                    free_tr2 ( tr )
                    return false
                }
            }
        }
    }
    free_tr2 ( tr )
    return true
}

bool:sentry_pendulum ( sentry )
{
    switch ( GetSentryFiremode ( sentry ) )
    {
    case SENTRY_FIREMODE_NO:
        {
            new Float:fAngles[3]
            entity_get_vector ( sentry, EV_VEC_angles, fAngles )
            new Float:fBaseAngle = entity_get_float ( sentry, SENTRY_FL_ANGLE )
            new iDirections = GetSentryPenddir ( sentry )
            
            // РЈРјРµРЅСЊС€РµРЅРЅР°СЏ СЃРєРѕСЂРѕСЃС‚СЊ РґР»СЏ РїР»Р°РІРЅРѕСЃС‚Рё (Р±С‹Р»Рѕ 0.6, СЃС‚Р°Р»Рѕ 0.2 РіСЂР°РґСѓСЃР° Р·Р° РєР°РґСЂ)
            new Float:fTurnSpeed = PENDULUM_INCREMENT * 0.00167 // 0.2 РіСЂР°РґСѓСЃР° Р·Р° РєР°РґСЂ РїСЂРё 60 FPS
            
            if ( iDirections & (1<<SENTRY_DIR_CANNON) )
            {
                fAngles[1] -= fTurnSpeed
                if ( fAngles[1] < fBaseAngle - PENDULUM_MAX )
                {
                    fAngles[1] = fBaseAngle - PENDULUM_MAX
                    iDirections &= ~(1<<SENTRY_DIR_CANNON)
                    SetSentryPenddir ( sentry, iDirections )
                }
            }
            else 
            {
                fAngles[1] += fTurnSpeed
                if ( fAngles[1] > fBaseAngle + PENDULUM_MAX ) 
                {
                    fAngles[1] = fBaseAngle + PENDULUM_MAX
                    iDirections |= (1<<SENTRY_DIR_CANNON)
                    SetSentryPenddir ( sentry, iDirections )
                }
            }                                                                                        
            entity_set_vector ( sentry, EV_VEC_angles, fAngles )
            return true
        }
    case SENTRY_FIREMODE_NUTS:
        {
            new Float:fAngles[3]
            entity_get_vector ( sentry, EV_VEC_angles, fAngles )
            new Float:fSpinSpeed = entity_get_float ( sentry, SENTRY_FL_SPINSPEED )
            
            // РџР»Р°РІРЅРѕРµ СѓСЃРєРѕСЂРµРЅРёРµ РґР»СЏ СЂРµР¶РёРјР° NUTS
            new Float:fCurrentTurnRate = fSpinSpeed * 0.00167 // РљРѕРЅРІРµСЂСЃРёСЏ РІ РіСЂР°РґСѓСЃС‹ Р·Р° РєР°РґСЂ
            
            if ( GetSentryPenddir ( sentry ) & (1<<SENTRY_DIR_CANNON) )
            {
                fAngles[1] -= fCurrentTurnRate
                if ( fAngles[1] < 0.0 )
                fAngles[1] = 360.0 + fAngles[1]
            }
            else
            {
                fAngles[1] += fCurrentTurnRate
                if ( fAngles[1] > 360.0 )
                fAngles[1] = fAngles[1] - 360.0
            }
            
            // РџР»Р°РІРЅРѕРµ СѓРІРµР»РёС‡РµРЅРёРµ СЃРєРѕСЂРѕСЃС‚Рё (РјРµРЅСЊС€РµРµ РїСЂРёСЂР°С‰РµРЅРёРµ)
            entity_set_float ( sentry, SENTRY_FL_SPINSPEED, ( fSpinSpeed += random_float ( 0.3, 0.7 ) ) )
                                   
            new Float:fMaxSpin = entity_get_float ( sentry, SENTRY_FL_MAXSPIN )
            if ( fMaxSpin == 0.0 )
            {
                entity_set_float ( sentry, SENTRY_FL_LASTTHINK, 0.5 )
                entity_set_float ( sentry, SENTRY_FL_MAXSPIN, fMaxSpin = random_float ( 500.0, 750.0 ) )
            }
            else if ( fSpinSpeed >= fMaxSpin )
            {
                sentry_detonate ( sentry, false, false )
                return false
            }
            entity_set_vector ( sentry, EV_VEC_angles, fAngles )
            return true
        }
    }
    return true
}
                                                                                  
//#define    TE_TRACER            6        // tracer effect from point to point
tracer(Float:start[3], Float:end[3]) {
    new start_[3], end_[3]
    FVecIVec(start, start_)
    FVecIVec(end, end_)
    message_begin(MSG_BROADCAST, SVC_TEMPENTITY) //  MSG_PAS MSG_BROADCAST
    write_byte(TE_TRACER)
    write_coord(start_[0])
    write_coord(start_[1])
    write_coord(start_[2])                          
    write_coord(end_[0])
    write_coord(end_[1])
    write_coord(end_[2])
    message_end()
}

tracer2(Float:start[3], Float:end[3]) {
    new start_[3], end_[3]
    FVecIVec(start, start_)
    FVecIVec(end, end_)
    message_begin(MSG_BROADCAST, SVC_TEMPENTITY) //  MSG_PAS MSG_BROADCAST
    write_byte(TE_TRACER)
    write_coord(start_[0])
    write_coord(start_[1] + 18)  
    write_coord(start_[2] + 7)   
    write_coord(end_[0])   
    write_coord(end_[1])
    write_coord(end_[2])
    message_end()
    
    message_begin(MSG_BROADCAST, SVC_TEMPENTITY) //  MSG_PAS MSG_BROADCAST
    write_byte(TE_TRACER)
    write_coord(start_[0])
    write_coord(start_[1] - 18)  
    write_coord(start_[2] + 7)   
    write_coord(end_[0])   
    write_coord(end_[1])
    write_coord(end_[2])
    message_end()
}



CreateExplosion(iCurrent)
{
    new Float:vOrigin[3] 
    pev(iCurrent,pev_origin,vOrigin)

    

    message_begin (MSG_BROADCAST,SVC_TEMPENTITY)
    write_byte(TE_SPRITETRAIL) // Throws a shower of sprites or models
    engfunc(EngFunc_WriteCoord, vOrigin[ 0 ]) // start pos
    engfunc(EngFunc_WriteCoord, vOrigin[ 1 ])
    engfunc(EngFunc_WriteCoord, vOrigin[ 2 ])
    engfunc(EngFunc_WriteCoord, vOrigin[ 0 ]) // velocity
    engfunc(EngFunc_WriteCoord, vOrigin[ 1 ])
    engfunc(EngFunc_WriteCoord, vOrigin[ 2 ]+6.0)
    write_short(g_iSPR_Explo2) // spr
    write_byte(random_num(30,40)) // (count)
    write_byte(30) // (life in 0.1's)
    write_byte(1) // byte (scale in 0.1's)
    write_byte(20) // (velocity along vector in 10's)
    write_byte(20) // (randomness of velocity in 10's)
    message_end() 
    
} 
CreateRocketex(iCurrent)
{
    new Float:vOrigin[3] 
    pev(iCurrent,pev_origin,vOrigin) 

    

    message_begin (MSG_BROADCAST,SVC_TEMPENTITY)
    write_byte(TE_SPRITETRAIL) // Throws a shower of sprites or models
    engfunc(EngFunc_WriteCoord, vOrigin[ 0 ]) // start pos
    engfunc(EngFunc_WriteCoord, vOrigin[ 1 ])
    engfunc(EngFunc_WriteCoord, vOrigin[ 2 ])
    engfunc(EngFunc_WriteCoord, vOrigin[ 0 ]) // velocity
    engfunc(EngFunc_WriteCoord, vOrigin[ 1 ])
    engfunc(EngFunc_WriteCoord, vOrigin[ 2 ]+6.0)
    write_short(model_gibs) // spr
    write_byte(random_num(8,13)) // (count)
    write_byte(30) // (life in 0.1's)
    write_byte(1) // byte (scale in 0.1's)
    write_byte(30) // (velocity along vector in 10's)
    write_byte(20) // (randomness of velocity in 10's)
    message_end()  
    
} 
CreateExplosion1(iCurrent)
{
    new Float:vOrigin[3] 
    pev(iCurrent,pev_origin,vOrigin) 

    

    message_begin (MSG_BROADCAST,SVC_TEMPENTITY)
    write_byte(TE_SPRITETRAIL) // Throws a shower of sprites or models
    engfunc(EngFunc_WriteCoord, vOrigin[ 0 ]) // start pos
    engfunc(EngFunc_WriteCoord, vOrigin[ 1 ])
    engfunc(EngFunc_WriteCoord, vOrigin[ 2 ])
    engfunc(EngFunc_WriteCoord, vOrigin[ 0 ]) // velocity
    engfunc(EngFunc_WriteCoord, vOrigin[ 1 ])
    engfunc(EngFunc_WriteCoord, vOrigin[ 2 ]+6.0)
    write_short(g_Sprite) // spr
    write_byte(random_num(30,40)) // (count)
    write_byte(30) // (life in 0.1's)
    write_byte(1) // byte (scale in 0.1's)
    write_byte(30) // (velocity along vector in 10's)
    write_byte(20) // (randomness of velocity in 10's)
    message_end()  
    
} 
CreateExplosion2(iCurrent)
{
    new Float:vOrigin[3] 
    pev(iCurrent,pev_origin,vOrigin) 

    

    message_begin (MSG_BROADCAST,SVC_TEMPENTITY)
    write_byte(TE_SPRITETRAIL) // Throws a shower of sprites or models
    engfunc(EngFunc_WriteCoord, vOrigin[ 0 ]) // start pos
    engfunc(EngFunc_WriteCoord, vOrigin[ 1 ])
    engfunc(EngFunc_WriteCoord, vOrigin[ 2 ]) 
    engfunc(EngFunc_WriteCoord, vOrigin[ 0 ]) // velocity
    engfunc(EngFunc_WriteCoord, vOrigin[ 1 ])
    engfunc(EngFunc_WriteCoord, vOrigin[ 2 ]+6.0)
    write_short(g_Urag) // spr
    write_byte(random_num(30,40)) // (count)
    write_byte(20) // (life in 0.1's)
    write_byte(1) // byte (scale in 0.1's)
    write_byte(25) // (velocity along vector in 10's)
    write_byte(15) // (randomness of velocity in 10's)
    message_end()  
    
}
CreateExplosion3(iCurrent)
{
    new Float:vOrigin[3] 
    pev(iCurrent,pev_origin,vOrigin) 

    

    message_begin (MSG_BROADCAST,SVC_TEMPENTITY)
    write_byte(TE_SPRITETRAIL) // Throws a shower of sprites or models
    engfunc(EngFunc_WriteCoord, vOrigin[ 0 ]) // start pos
    engfunc(EngFunc_WriteCoord, vOrigin[ 1 ])
    engfunc(EngFunc_WriteCoord, vOrigin[ 2 ]) 
    engfunc(EngFunc_WriteCoord, vOrigin[ 0 ]) // velocity
    engfunc(EngFunc_WriteCoord, vOrigin[ 1 ])
    engfunc(EngFunc_WriteCoord, vOrigin[ 2 ]+6.0)
    write_short(g_regen) // spr
    write_byte(random_num(30,40)) // (count)
    write_byte(30) // (life in 0.1's)
    write_byte(2) // byte (scale in 0.1's)
    write_byte(30) // (velocity along vector in 10's)
    write_byte(20) // (randomness of velocity in 10's)
    message_end()  
    
}  
CreateExplosion4(iCurrent)
{
    new Float:vOrigin[3] 
    pev(iCurrent,pev_origin,vOrigin) 

    

    message_begin (MSG_BROADCAST,SVC_TEMPENTITY)
    write_byte(TE_SPRITETRAIL) // Throws a shower of sprites or models
    engfunc(EngFunc_WriteCoord, vOrigin[ 0 ]) // start pos
    engfunc(EngFunc_WriteCoord, vOrigin[ 1 ])
    engfunc(EngFunc_WriteCoord, vOrigin[ 2 ])
    engfunc(EngFunc_WriteCoord, vOrigin[ 0 ]) // velocity
    engfunc(EngFunc_WriteCoord, vOrigin[ 1 ])
    engfunc(EngFunc_WriteCoord, vOrigin[ 2 ]+6.0)
    write_short(g_sModelIndexMoroz) // spr
    write_byte(random_num(30,40)) // (count)
    write_byte(20) // (life in 0.1's)
    write_byte(1) // byte (scale in 0.1's)
    write_byte(20) // (velocity along vector in 10's)
    write_byte(20) // (randomness of velocity in 10's)
    message_end()  
    
}
CreateExplosion5(iCurrent)
{
    new Float:vOrigin[3] 
    pev(iCurrent,pev_origin,vOrigin) 

    

    message_begin (MSG_BROADCAST,SVC_TEMPENTITY)
    write_byte(TE_SPRITETRAIL) // Throws a shower of sprites or models
    engfunc(EngFunc_WriteCoord, vOrigin[ 0 ]) // start pos
    engfunc(EngFunc_WriteCoord, vOrigin[ 1 ])
    engfunc(EngFunc_WriteCoord, vOrigin[ 2 ])
    engfunc(EngFunc_WriteCoord, vOrigin[ 0 ]) // velocity
    engfunc(EngFunc_WriteCoord, vOrigin[ 1 ])
    engfunc(EngFunc_WriteCoord, vOrigin[ 2 ]+6.0)
    write_short(g_Moroz) // spr
    write_byte(random_num(20,30)) // (count)
    write_byte(20) // (life in 0.1's)
    write_byte(1) // byte (scale in 0.1's)
    write_byte(20) // (velocity along vector in 10's)
    write_byte(20) // (randomness of velocity in 10's)
    message_end()  
    
}
CreateExplosion15(iCurrent)
{
    new Float:vOrigin[3] 
    pev(iCurrent,pev_origin,vOrigin) 

    

    message_begin (MSG_BROADCAST,SVC_TEMPENTITY)
    write_byte(TE_SPRITETRAIL) // Throws a shower of sprites or models
    engfunc(EngFunc_WriteCoord, vOrigin[ 0 ]) // start pos
    engfunc(EngFunc_WriteCoord, vOrigin[ 1 ])
    engfunc(EngFunc_WriteCoord, vOrigin[ 2 ])
    engfunc(EngFunc_WriteCoord, vOrigin[ 0 ]) // velocity
    engfunc(EngFunc_WriteCoord, vOrigin[ 1 ])
    engfunc(EngFunc_WriteCoord, vOrigin[ 2 ]+6.0)
    write_short(g_MorozChastic) // spr
    write_byte(random_num(8,12)) // (count)
    write_byte(20) // (life in 0.1's)
    write_byte(1) // byte (scale in 0.1's)
    write_byte(20) // (velocity along vector in 10's)
    write_byte(20) // (randomness of velocity in 10's)
    message_end()  
    
}
CreateExplosion6(iCurrent)
{
    new Float:vOrigin[3] 
    pev(iCurrent,pev_origin,vOrigin) 

    

    message_begin (MSG_BROADCAST,SVC_TEMPENTITY)
    write_byte(TE_SPRITETRAIL) // Throws a shower of sprites or models
    engfunc(EngFunc_WriteCoord, vOrigin[ 0 ]) // start pos
    engfunc(EngFunc_WriteCoord, vOrigin[ 1 ])
    engfunc(EngFunc_WriteCoord, vOrigin[ 2 ])
    engfunc(EngFunc_WriteCoord, vOrigin[ 0 ]) // velocity
    engfunc(EngFunc_WriteCoord, vOrigin[ 1 ])
    engfunc(EngFunc_WriteCoord, vOrigin[ 2 ]+6.0)
    write_short(g_Tesssla) // spr
    write_byte(random_num(15,25)) // (count)
    write_byte(20) // (life in 0.1's)
    write_byte(1) // byte (scale in 0.1's)
    write_byte(20) // (velocity along vector in 10's)
    write_byte(20) // (randomness of velocity in 10's)
    message_end()  
    
}
CreateExplosion7(iCurrent)
{
    new Float:vOrigin[3] 
    pev(iCurrent,pev_origin,vOrigin) 

    

    message_begin (MSG_BROADCAST,SVC_TEMPENTITY)
    write_byte(TE_SPRITETRAIL) // Throws a shower of sprites or models
    engfunc(EngFunc_WriteCoord, vOrigin[ 0 ]) // start pos
    engfunc(EngFunc_WriteCoord, vOrigin[ 1 ])
    engfunc(EngFunc_WriteCoord, vOrigin[ 2 ])
    engfunc(EngFunc_WriteCoord, vOrigin[ 0 ]) // velocity
    engfunc(EngFunc_WriteCoord, vOrigin[ 1 ])
    engfunc(EngFunc_WriteCoord, vOrigin[ 2 ]+6.0)
    write_short(g_auracveta) // spr
    write_byte(random_num(15,25)) // (count)
    write_byte(20) // (life in 0.1's)
    write_byte(1) // byte (scale in 0.1's)
    write_byte(20) // (velocity along vector in 10's)
    write_byte(20) // (randomness of velocity in 10's)
    message_end()  
    
}
prite_zona_1(Float:start[3])
{
    new start_[3]
    FVecIVec(start, start_)

    message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
    write_byte(TE_SPRITE)//РіРѕРІРѕСЂРёРј С‡С‚Рѕ С…РѕС‚РёРј СЃРѕР·РґР°С‚СЊ, РІ РґР°РЅРЅРѕРј СЃР»СѓС‡Р°Рµ СЃРїСЂР°Р№С‚
    write_coord(start_[0])//С… - РєРѕРѕСЂРґРёРЅР°С‚Р°
    write_coord(start_[1])//Сѓ - РєРѕРѕСЂРґРёРЅР°С‚Р°
    write_coord(start_[2] - 12)//z - РєРѕРѕСЂРґРёРЅР°С‚Р°
    write_short(g_Sprite)// id СЃРїСЂР°Р№С‚Р°
    write_byte(2) //РјР°СЃС€С‚Р°Р±
    write_byte(1000)//СЏСЂРєРѕСЃС‚СЊ
    message_end()
	}

prite_zona_2(Float:start[3])
{
    new start_[3]
    FVecIVec(start, start_)

    message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
    write_byte(TE_SPRITE)//РіРѕРІРѕСЂРёРј С‡С‚Рѕ С…РѕС‚РёРј СЃРѕР·РґР°С‚СЊ, РІ РґР°РЅРЅРѕРј СЃР»СѓС‡Р°Рµ СЃРїСЂР°Р№С‚
    write_coord(start_[0])//С… - РєРѕРѕСЂРґРёРЅР°С‚Р°
    write_coord(start_[1])//Сѓ - РєРѕРѕСЂРґРёРЅР°С‚Р°
    write_coord(start_[2] - 12)//z - РєРѕРѕСЂРґРёРЅР°С‚Р°
    write_short(g_sModelIndexMoroz)// id СЃРїСЂР°Р№С‚Р°
    write_byte(2) //РјР°СЃС€С‚Р°Р±
    write_byte(1000)//СЏСЂРєРѕСЃС‚СЊ
    message_end()
}
prite_zona_3(Float:start[3])
{
    new start_[3]
    FVecIVec(start, start_)

    message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
    write_byte(TE_SPRITE)//РіРѕРІРѕСЂРёРј С‡С‚Рѕ С…РѕС‚РёРј СЃРѕР·РґР°С‚СЊ, РІ РґР°РЅРЅРѕРј СЃР»СѓС‡Р°Рµ СЃРїСЂР°Р№С‚
    write_coord(start_[0])//С… - РєРѕРѕСЂРґРёРЅР°С‚Р°
    write_coord(start_[1])//Сѓ - РєРѕРѕСЂРґРёРЅР°С‚Р°
    write_coord(start_[2] - 12)//z - РєРѕРѕСЂРґРёРЅР°С‚Р°
    write_short(g_Moroz)// id СЃРїСЂР°Р№С‚Р°
    write_byte(3) //РјР°СЃС€С‚Р°Р±
    write_byte(1000)//СЏСЂРєРѕСЃС‚СЊ
    message_end()
}
prite_zona_4(Float:start[3])
{
    new start_[3]
    FVecIVec(start, start_)

    message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
    write_byte(TE_SPRITE)//РіРѕРІРѕСЂРёРј С‡С‚Рѕ С…РѕС‚РёРј СЃРѕР·РґР°С‚СЊ, РІ РґР°РЅРЅРѕРј СЃР»СѓС‡Р°Рµ СЃРїСЂР°Р№С‚
    write_coord(start_[0])//С… - РєРѕРѕСЂРґРёРЅР°С‚Р°
    write_coord(start_[1])//Сѓ - РєРѕРѕСЂРґРёРЅР°С‚Р°
    write_coord(start_[2] - 12)//z - РєРѕРѕСЂРґРёРЅР°С‚Р°
    write_short(g_Tesssla)// id СЃРїСЂР°Р№С‚Р°
    write_byte(2) //РјР°СЃС€С‚Р°Р±
    write_byte(1000)//СЏСЂРєРѕСЃС‚СЊ
    message_end()
}
prite_zona_5(Float:start[3])
{
    new start_[3]
    FVecIVec(start, start_)

    message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
    write_byte(TE_SPRITE)//РіРѕРІРѕСЂРёРј С‡С‚Рѕ С…РѕС‚РёРј СЃРѕР·РґР°С‚СЊ, РІ РґР°РЅРЅРѕРј СЃР»СѓС‡Р°Рµ СЃРїСЂР°Р№С‚
    write_coord(start_[0])//С… - РєРѕРѕСЂРґРёРЅР°С‚Р°
    write_coord(start_[1])//Сѓ - РєРѕРѕСЂРґРёРЅР°С‚Р°
    write_coord(start_[2] - 12)//z - РєРѕРѕСЂРґРёРЅР°С‚Р°
    write_short(g_Urag)// id СЃРїСЂР°Р№С‚Р°
    write_byte(3) //РјР°СЃС€С‚Р°Р±
    write_byte(1000)//СЏСЂРєРѕСЃС‚СЊ
    message_end()
}
prite_zona_6(Float:start[3])
{
    new start_[3]
    FVecIVec(start, start_)

    message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
    write_byte(TE_SPRITE)//РіРѕРІРѕСЂРёРј С‡С‚Рѕ С…РѕС‚РёРј СЃРѕР·РґР°С‚СЊ, РІ РґР°РЅРЅРѕРј СЃР»СѓС‡Р°Рµ СЃРїСЂР°Р№С‚
    write_coord(start_[0])//С… - РєРѕРѕСЂРґРёРЅР°С‚Р°
    write_coord(start_[1])//Сѓ - РєРѕРѕСЂРґРёРЅР°С‚Р°
    write_coord(start_[2] - 12)//z - РєРѕРѕСЂРґРёРЅР°С‚Р°
    write_short(g_regen)// id СЃРїСЂР°Р№С‚Р°
    write_byte(5) //РјР°СЃС€С‚Р°Р±
    write_byte(1000)//СЏСЂРєРѕСЃС‚СЊ
    message_end()
}
prite_zona_7(Float:start[3])
{
    new start_[3]
    FVecIVec(start, start_)

    message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
    write_byte(TE_SPRITE)//РіРѕРІРѕСЂРёРј С‡С‚Рѕ С…РѕС‚РёРј СЃРѕР·РґР°С‚СЊ, РІ РґР°РЅРЅРѕРј СЃР»СѓС‡Р°Рµ СЃРїСЂР°Р№С‚
    write_coord(start_[0])//С… - РєРѕРѕСЂРґРёРЅР°С‚Р°
    write_coord(start_[1])//Сѓ - РєРѕРѕСЂРґРёРЅР°С‚Р°
    write_coord(start_[2] - 12)//z - РєРѕРѕСЂРґРёРЅР°С‚Р°
    write_short(g_auracveta)// id СЃРїСЂР°Р№С‚Р°
    write_byte(2) //РјР°СЃС€С‚Р°Р±
    write_byte(1000)//СЏСЂРєРѕСЃС‚СЊ
    message_end()
}
prite_zona_8(Float:start[3])
{
    new start_[3]
    FVecIVec(start, start_)

    message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
    write_byte(TE_SPRITE)//РіРѕРІРѕСЂРёРј С‡С‚Рѕ С…РѕС‚РёРј СЃРѕР·РґР°С‚СЊ, РІ РґР°РЅРЅРѕРј СЃР»СѓС‡Р°Рµ СЃРїСЂР°Р№С‚
    write_coord(start_[0])//С… - РєРѕРѕСЂРґРёРЅР°С‚Р°
    write_coord(start_[1])//Сѓ - РєРѕРѕСЂРґРёРЅР°С‚Р°
    write_coord(start_[2]+25)//z - РєРѕРѕСЂРґРёРЅР°С‚Р°
    write_short(g_smoke)// id СЃРїСЂР°Р№С‚Р°
    write_byte(11) //РјР°СЃС€С‚Р°Р±
    write_byte(1000)//СЏСЂРєРѕСЃС‚СЊ
    message_end()
}

public TicketToHell(player) {
    if (!is_user_connected(player))
    return
    new frags = get_user_frags(player)
    user_kill(player, 1) // don't decrease frags
    new parms[4]
    parms[0] = player
    parms[1] = frags
    parms[2] = cs_get_user_deaths(player)
    parms[3] = int:cs_get_user_team(player)
    set_task(0.0, "DelayedScoreInfoUpdate", 0, parms, 4)
}

public DelayedScoreInfoUpdate(parms[4]) {
    scoreinfo_update(parms[0], parms[1], parms[2], parms[3])
}
    
KnockBack ( Float:origin[3] )
{
	new iEntList[32]
	new iEntsFound = find_sphere_class ( 0, "player", SENTRYEXPLODERADIUS, iEntList, g_iMaxPlayers, origin )

	if ( !iEntsFound )
		return

	new Float:fOriginEnt[3]
	new Float:fVelocity[3]
	new Float:fOriginEnd[3]
	new Float:fDistance
	new iPlayer

	for ( new i; i < iEntsFound; i++ )
	{
		iPlayer = iEntList[i]

		if ( !is_user_alive ( iPlayer ) )
			continue

		entity_get_vector ( iPlayer, EV_VEC_origin, fOriginEnt )

		fDistance = vector_distance ( fOriginEnt, origin )

		if ( is_entity_on_ground ( iPlayer ) && fOriginEnt[2] < origin[2] )
			fOriginEnt[2] = origin[2] + fDistance

		entity_get_vector ( iPlayer, EV_VEC_velocity, fVelocity )

		fOriginEnd[0] = ( fOriginEnt[0] - origin[0] ) * SENTRYEXPLODERADIUS / fDistance + origin[0]
		fOriginEnd[1] = ( fOriginEnt[1] - origin[1] ) * SENTRYEXPLODERADIUS / fDistance + origin[1]
		fOriginEnd[2] = ( fOriginEnt[2] - origin[2] ) * SENTRYEXPLODERADIUS / fDistance + origin[2]

		fVelocity[0] += ( fOriginEnd[0] - fOriginEnt[0] ) * SENTRYSHOCKPOWER
		fVelocity[1] += ( fOriginEnd[1] - fOriginEnt[1] ) * SENTRYSHOCKPOWER
		fVelocity[2] += ( fOriginEnd[2] - fOriginEnt[2] ) * SENTRYSHOCKPOWER

		entity_set_vector ( iPlayer, EV_VEC_velocity, fVelocity )
	}
}
public msg_TempEntity ()
{
    if ( get_msg_args () != 15 && get_msg_arg_int ( 1 ) != TE_BREAKMODEL )
    return PLUGIN_CONTINUE

    for ( new i; i < g_sentriesNum; i++ )
    {
        if ( entity_get_float ( g_sentries[i], EV_FL_health ) <= 0.0 )
        {
            sentry_detonate ( i, false, true )
            i--                                         
        }                                           
    }
    return PLUGIN_CONTINUE
}

public fw_ThinkSentry ( ent )
{
	if ( !is_valid_ent ( ent ) )
		return

	static iOwner; iOwner = GetSentryUpgrader ( ent, OWNER )

	if ( !is_user_connected ( iOwner ) )
		return

	if ( cs_get_user_team ( iOwner ) == CS_TEAM_SPECTATOR )
	{
		sentry_detonate ( ent, true, false )
		return
	}
	
	
	

	
		new Float:fOriginSentry[3], Float:fOriginHit[3], iHitEnt
		entity_get_vector ( ent, EV_VEC_origin, fOriginSentry )
		fOriginSentry[2] += CANNONHEIGHTFROMFEET // Move up some, this should be the Y origin of the cannon
		
	                                 	new HP = pev(ent, 41);
										new sentryLevel = GetSentryLevel ( ent )
	    if ( !sentry_pendulum ( ent ) )
    return								
    static Float:fGameTimea; fGameTimea = get_gametime ()              
    if ( entity_get_float ( ent, SENTRY_FL_LASTTHINKA ) <= fGameTimea )
{
entity_set_float ( ent, SENTRY_FL_LASTTHINKA, fGameTimea + 1.5 )	
		if (HP <= get_pcvar_float(g_Cvar_smokesentry))
		{
prite_zona_8(fOriginSentry)	
		}
}
if (sentryLevel >= 3 )
{
if(g_SentryModem[ent] == 7)
{
sentry_blast(ent)
}
if ( entity_get_float ( ent, SENTRY_FL_LASTTHINKAFB ) <= fGameTimea )
{
entity_set_float ( ent, SENTRY_FL_LASTTHINKAFB, fGameTimea + 0.55 )
if(g_SentryMode[ent] == 4)
{
prite_zona_4(fOriginSentry)
}
if(g_SentryMode[ent] == 6)
{
prite_zona_6(fOriginSentry)
}
if(g_SentryMode[ent] == 2)
{
prite_zona_1(fOriginSentry)
}
}
if(g_SentryMode[ent] == 3)
{
prite_zona_3(fOriginSentry)
}       
	if ( entity_get_float ( ent, SENTRY_FL_LASTTHINKAFV ) <= fGameTimea )
{
	entity_set_float ( ent, SENTRY_FL_LASTTHINKAFV, fGameTimea + 0.12)
if(g_SentryMode[ent] == 5)
{
prite_zona_5(fOriginSentry)
}
}
if(g_SentryMode[ent] == 1)
{
prite_zona_2(fOriginSentry)
}
if(g_SentryMode[ent] == 7)
{
prite_zona_7(fOriginSentry)
}
}
static Float:fGameTime; fGameTime = get_gametime ()
if ( entity_get_float ( ent, SENTRY_FL_LASTTHINK ) <= fGameTime )
{
		new firemode = GetSentryFiremode ( ent )
		new target = GetSentryTarget ( ent, TARGET )
        if ( firemode == SENTRY_FIREMODE_YES && is_valid_ent ( target ) && is_user_alive ( target ) && cs_get_user_team ( target ) != GetSentryTeam ( ent ) && !IsInSphere ( target ))
        {
            
            new Float:fOriginTarget[3]
            entity_get_vector ( target, EV_VEC_origin, fOriginTarget )
                                                                         
            if ( entity_get_int ( target, EV_INT_flags ) & FL_DUCKING )
            fOriginTarget[2] += TARGETUPMODIFIER
	
            iHitEnt = trace_line ( ent, fOriginSentry, fOriginTarget, fOriginHit )
            if ( iHitEnt == entity_get_edict ( ent, SENTRY_ENT_BASE ) )                                                        
            iHitEnt = trace_line ( iHitEnt, fOriginHit, fOriginTarget, fOriginHit )
                                                              
            if ( iHitEnt != target && is_user_alive ( iHitEnt ) && GetSentryTeam ( ent ) != cs_get_user_team ( iHitEnt ) && !IsInSphere ( iHitEnt ))
            {
                target = iHitEnt                                    
                SetSentryTarget(ent, TARGET, iHitEnt)
            }
			if ( iHitEnt == target )
			{
				SentryTurnToTarget ( ent, fOriginSentry, fOriginTarget )
                                if(entity_get_int(ent, EV_INT_sequence)!= 1){
                                UTIL_PlayAnimation(ent, 1)
                                }

								if(GetSentryLevel(ent) == SENTRY_LEVEL_5)
								{
								    if ( entity_get_float ( ent, SENTRY_FL_LASTTH ) <= fGameTimea )
{
entity_set_float ( ent, SENTRY_FL_LASTTH, fGameTimea + 0.66 )										
									if(g_SentryMode[ent] == 2)      
                {
                   emit_sound(ent, CHAN_WEAPON , "CSSB/sentry_gun/laser_1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
				}
				}
																    if ( entity_get_float ( ent, ABA2 ) <= fGameTimea )
{		
entity_set_float ( ent, ABA2, fGameTimea + 0.744 )	
													if(g_SentryMode[ent] == 3)      
                {
					emit_sound(ent, CHAN_WEAPON , "CSSB/sentry_gun/fire_5.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
				}
														if(g_SentryMode[ent] == 4)      
                {
					emit_sound(ent, CHAN_WEAPON , "CSSB/sentry_gun/fire_5.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
				}
								}	
								}								
								else
								{
												    if ( entity_get_float ( ent, SENTRY_FL_LASTTVH ) <= fGameTimea )
{	
	
entity_set_float ( ent, SENTRY_FL_LASTTVH, fGameTimea + 0.744 )	
                   emit_sound(ent, CHAN_WEAPON , "CSSB/sentry_gun/fire_5.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
                
}				
								}
				new Float:fHitRatio = 0.0
     if(GetSentryLevel(ent) == SENTRY_LEVEL_4)
                {                                       
                    if(g_SentryMode[ent] == 1) 
                    {             		
                         if ( entity_get_float ( ent, ABA6 ) <= fGameTimea )
						{
                            if(entity_range(ent,target) >= get_pcvar_float(g_Cvar_mode_rpg[2])){
                                new data[2]                                                  
                                data[0] = ent
                            
                                ShootRockets(data) 
}	
                            entity_set_float(ent,ABA6,get_gametime() + get_pcvar_float(g_Cvar_mode_rpg[3]))
                        }      
                    }
                }
                
                if(GetSentryLevel(ent) == SENTRY_LEVEL_5)
                {
                    if(g_SentryMode[ent] == 2)
                    {
                        if(entity_range(ent,target) >= 1)
                        {                     
                            new data[2]
                            data[0] = ent  
                            ShootFreezing(data)	
				

					}
                } 
				}
                if(GetSentryLevel(ent) == SENTRY_LEVEL_5)             
                {
                    if(g_SentryMode[ent] == 3)  				
                    {                        
                            new data[2]
                            data[0] = ent    
							if ( entity_get_float ( ent, ABA7 ) <= fGameTimea )
							{
                            ShootFreezing_cub(data)                                                        
                            entity_set_float(ent,ABA7,get_gametime() +  get_pcvar_num(moroztime2))
                        }      
					}					
                }
                
                if(GetSentryLevel(ent) == SENTRY_LEVEL_5)
                {                              
                    if(g_SentryMode[ent] == 4)   
                    {                                            
                            if(entity_range(ent,target) >= 1){                            
                            new data[2] 
                            data[0] = ent    
							if ( entity_get_float ( ent, ABA8 ) <= fGameTimea )
							{
                            ShootFreezingTesla(data)
							}
                            entity_set_float(ent,ABA8,get_gametime() +  get_pcvar_num(uragtime)) 
                                                                                                         
                        }
                    } 	
				}				
                if(GetSentryLevel(ent) == SENTRY_LEVEL_4)
                {                                       
                    if(g_SentryMode[ent] == 5)   
                    {                                            
                            if(entity_range(ent,target) >= 1){                            
                            new data[2] 
                            data[0] = ent    
							if ( entity_get_float ( ent, ABA9 ) <= fGameTimea )
							{
								 entity_set_float(ent,ABA9,get_gametime() +  get_pcvar_num(uragtime)) 
                            ShootUrag(data)
							
                        
                            }                                                                             
                        }
                    }
				}			
static Float:flTakeDamage; 
pev(target, pev_takedamage, flTakeDamage);

if (!get_user_godmode(target) && fHitRatio <= 0.0 && 
    entity_get_float(iHitEnt, EV_FL_takedamage) != 0.0 && 
    flTakeDamage != DAMAGE_NO)
{
    sentry_damagetoplayer(ent, sentryLevel, fOriginSentry, target)
}
else
{
    new Float:fSentryAngle[3] = {0.0, 0.0, 0.0}
    
    new Float:x = fOriginHit[0] - fOriginSentry[0]
    new Float:y = fOriginHit[1] - fOriginSentry[1]
    
    // РџСЂР°РІРёР»СЊРЅРѕРµ РёСЃРїРѕР»СЊР·РѕРІР°РЅРёРµ floatatan СЃ РїСЂРѕРІРµСЂРєРѕР№ РєРІР°РґСЂР°РЅС‚Р°
    if (x != 0.0) {
        new Float:radians = floatatan(y/x, radian)
        fSentryAngle[1] = radians * (180.0 / 3.14159265)
        
        if (x < 0.0)
            fSentryAngle[1] += 180.0
    }
    
    // Р’РµСЂС‚РёРєР°Р»СЊРЅС‹Р№ СѓРіРѕР»
    new Float:h = fOriginHit[2] - fOriginSentry[2]
    new Float:distance = floatsqroot(x*x + y*y)
    
    if (distance != 0.0) {
        new Float:radians = floatatan(h/distance, radian)
        fSentryAngle[0] = -radians * (180.0 / 3.14159265)
    }
    
    // Р”РѕР±Р°РІР»РµРЅРёРµ СЂР°Р·Р±СЂРѕСЃР°
    fSentryAngle[0] += random_float(-10.0 * fHitRatio, 10.0 * fHitRatio)
    fSentryAngle[1] += random_float(-10.0 * fHitRatio, 10.0 * fHitRatio)
    
    engfunc(EngFunc_MakeVectors, fSentryAngle)
    new Float:vector[3]
    get_global_vector(GL_v_forward, vector)
    
    for (new i = 0; i < 3; i++)
        vector[i] *= 1000.0

	
					new Float:traceEnd[3]
					for ( new i = 0; i < 3; i++ )
						traceEnd[i] = vector[i] + fOriginSentry[i]
	
					new iHitEnt2 = ent
					static lolcheck = 0
					while ( ( iHitEnt2 = trace_line ( iHitEnt2, fOriginHit, traceEnd, fOriginHit ) ) )
						if ( lolcheck++ > 700 ) break
	
				}
								                if(GetSentryLevel(ent) == SENTRY_LEVEL_1)
                {
				                    tracer ( fOriginSentry, fOriginHit )
       
                }                                       
                else if(GetSentryLevel(ent) <= SENTRY_LEVEL_4)
                {                  
                    tracer2(fOriginSentry, fOriginHit)
    
                }
				else if(g_SentryMode[ent] == 3)
					                {                  
                    tracer2(fOriginSentry, fOriginHit)
      
                }
				else if(g_SentryMode[ent] == 4)
					                {                  
                    tracer2(fOriginSentry, fOriginHit)
             
                }

				
				entity_set_float ( ent, EV_FL_nextthink, get_gametime() + THINKFIREFREQUENCY )
				return
			}
		}
		else
		{
if (sentryLevel >= 3 )
{					
 if(g_SentryMode[ent] == 6)
        {                            
				new victim = -1;
				new Float:radius = get_pcvar_float( radiuslechenia );
				new Float:Health = 0.0;
				new Float:takehp = get_pcvar_float( takehpar );
				new Float:Armor = 0.0;
				radius = 500.0;
				while ((victim = engfunc(14, victim, fOriginSentry, radius)))
				{
					new var1;
					if (is_user_alive(victim) && GetSentryTeam(ent) == cs_get_user_team(victim) && 0 != pev(victim, 43) && pev(victim, 70))
					{
						pev(victim, 41, Health);
						pev(victim, 47, Armor);
						new heal;
		if( Health <= 0.0 )
		{
              heal = 0;
		}
											new Float:origin[ 3 ] ;
		pev( victim, pev_origin, origin );
							if( UTIL_IsVisible( victim, ent, fOriginSentry, origin) && (Health < get_pcvar_num(max_hp_regenSentry) || Armor < get_pcvar_num(max_ar_regenSentry)))
					{
						if (Health < get_pcvar_num(max_hp_regenSentry))
						{
							set_pev(victim, 41, floatadd(takehp, Health));
							heal = 1;
						}
												if (Armor < get_pcvar_num(max_ar_regenSentry))
						{
							set_pev(victim, 47, floatadd(takehp, Armor));
							heal = 1;
						}
						if (heal)
						{
							heal_effect(origin, fOriginSentry);
						}
					}	
						else
						{
						}
					}
				}
        }
			}
		}
		
		if ( random_num ( 0, 99 ) < 10 )
		       emit_sound ( ent, CHAN_VOICE, "CSSB/sentry_gun/rotate_2.wav", 1.0, ATTN_NORM, 0, PITCH_NORM ) 
        set_anim(ent, 0) 

		new closestTarget = 0, Float:closestDistance, Float:distance, Float:closestOrigin[3], Float:playerOrigin[3], CsTeams:sentryTeam = GetSentryTeam ( ent )
		for ( new i = 1; i <= g_iMaxPlayers; i++ )
		{
			if ( !is_user_connected ( i ) || !is_user_alive ( i ) || cs_get_user_team ( i ) == sentryTeam  )
				continue
	
			entity_get_vector ( i, EV_VEC_origin, playerOrigin )
	
			if ( entity_get_int ( i, EV_INT_flags ) & FL_DUCKING )
				playerOrigin[2] += TARGETUPMODIFIER
	
			iHitEnt = trace_line ( ent, fOriginSentry, playerOrigin, fOriginHit )
			if ( iHitEnt == entity_get_edict ( ent, SENTRY_ENT_BASE ) )
				iHitEnt = trace_line(iHitEnt, fOriginHit, playerOrigin, fOriginHit)
	
			if ( iHitEnt == i )
			{
				distance = vector_distance ( fOriginSentry, playerOrigin )
				closestOrigin = playerOrigin
	
				if ( distance < closestDistance || closestTarget == 0 )
				{
					closestTarget = i
					closestDistance = distance
				}
			}
		}
	
		if ( closestTarget )
		{
															    if ( entity_get_float ( ent, ABA5 ) <= fGameTimea )
{	
entity_set_float ( ent, ABA5, fGameTimea + 1.35 )	
			 emit_sound ( ent, CHAN_VOICE, "CSSB/sentry_gun/alert_3.wav", 1.0, ATTN_NORM, 0, PITCH_NORM )
}
			SentryTurnToTarget ( ent, fOriginSentry, closestOrigin )
	
			SetSentryFiremode ( ent, SENTRY_FIREMODE_YES )
			SetSentryTarget ( ent, TARGET, closestTarget )
		}
		else
		{
			            new Float:fAngles[3]
            entity_get_vector ( ent, EV_VEC_angles, fAngles )
			 fAngles[0] = 360.0
			 entity_set_vector ( ent, EV_VEC_angles, fAngles )
			SetSentryFiremode ( ent, SENTRY_FIREMODE_NO )
        }        
		
	
	entity_set_float ( ent, EV_FL_nextthink, get_gametime() + g_THINKFREQUENCIES )
}
	new firemode = GetSentryFiremode ( ent )
			new target = GetSentryTarget ( ent, TARGET )
if ( firemode == SENTRY_FIREMODE_NO || firemode == SENTRY_FIREMODE_NUTS && is_valid_ent ( target ) && is_user_alive ( target ) )
{
 entity_set_float ( ent, EV_FL_nextthink, fGameTime + 0.1 )
}
}
stock UTIL_PlayAnimation( const entity, const sequence, const Float:framerate = 1.0 )

{

        entity_set_float(entity, EV_FL_animtime, get_gametime());

        entity_set_float(entity, EV_FL_framerate, framerate);

        entity_set_float(entity, EV_FL_frame, 0.0);

       

        entity_set_int(entity, EV_INT_sequence, sequence);

}
stock CREATE_DLIGHT(Float:fOrigin[3], iRadius, iRed, iGreen, iBlue, iBrightness, iLife, iDecayRate = 0, iReliable = 0)
{
        message_begin(iReliable ? MSG_ALL : MSG_BROADCAST, SVC_TEMPENTITY);
        write_byte(TE_DLIGHT);
        engfunc(EngFunc_WriteCoord, fOrigin[0]);
        engfunc(EngFunc_WriteCoord, fOrigin[1]);
        engfunc(EngFunc_WriteCoord, fOrigin[2]);
        write_byte(iRadius);
        write_byte(iRed);
        write_byte(iGreen);
        write_byte(iBlue);
        write_byte(iBrightness);
        write_byte(iLife); // 0.1's
        write_byte(iDecayRate);
        message_end();
}   
stock bool:UTIL_IsVisible( index, entity, Float:origin[3], Float:flStart[ 3 ]) {
	new Float:flDest[ 3 ];
	pev( index, pev_view_ofs, flDest );
	xs_vec_add( flStart, flDest, flStart );
	engfunc( EngFunc_TraceLine, flStart, origin, 0, index, 0 );
	new Float:flFraction;
	get_tr2( 0, TR_flFraction, flFraction );
	if( flFraction == 1.0 || get_tr2( 0, TR_pHit) == entity ) return true;
	return false;
}

heal_effect(Float:flStart[ 3 ], Float:flEnd[ 3 ])
{
	engfunc( EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, flStart );
	write_byte(TE_BEAMPOINTS);
	engfunc( EngFunc_WriteCoord, flStart[ 0 ]);
	engfunc( EngFunc_WriteCoord, flStart[ 1 ]);
	engfunc( EngFunc_WriteCoord, flStart[ 2 ] -10);
	engfunc( EngFunc_WriteCoord, flEnd[ 0 ] );
	engfunc( EngFunc_WriteCoord, flEnd[ 1 ]);
	engfunc( EngFunc_WriteCoord, flEnd[ 2 ] -10);
	write_short( gHealingBeam );
	write_byte( 5 );
	write_byte( 2 );
	write_byte( 1 );
	write_byte( 20 );
	write_byte( 3 );
	write_byte( 0 );
	write_byte( 255 );
	write_byte( 0 );
	write_byte( 130 );
	write_byte( 30 );
	message_end( );
}
sentry_detonate(sentry, bool:quiet, bool:isIndex) {
    new level = GetSentryLevel ( sentry )

    new i
    if (isIndex)
    {
        i = sentry
        sentry = g_sentries[sentry]
        if (!is_valid_ent(sentry))
        return
    }
    else
    {
        if (!is_valid_ent(sentry))
        return

        for (new j = 0; j < g_sentriesNum; j++) {
            if (g_sentries[j] == sentry) {
                i = j
                //break
            }
        }
    }
	 new owner = GetSentryUpgrader(sentry, OWNER) 
    entity_set_float ( sentry, EV_FL_nextthink, 0.0 )

	    
    
   new iSentryCount = GetSentryCount ( owner ) 
   new team = cs_get_user_team(owner)
        new Float:origin[3]                             
        entity_get_vector(sentry, EV_VEC_origin, origin)
    DecreaseSentryCount(owner, sentry)

    // Remove base first
    if (GetSentryFiremode ( sentry ) != SENTRY_FIREMODE_NUTS)
    set_task ( 0.1, "DelayRemoveEntity", entity_get_edict ( sentry, SENTRY_ENT_BASE ) )
    //remove_entity(entity_get_edict(sentry, SENTRY_ENT_BASE))
                                                                            
    new iSentryTeam = _:GetSentryTeam ( sentry )

    set_task ( 0.1, "DelayRemoveEntity", sentry )
    //remove_entity(sentry)
    // Put the last sentry in the deleted entity's place
    if(0 > (g_sentriesNum - 1) > MAXSENTRIES) return
    g_sentries[i] = g_sentries[g_sentriesNum - 1]
				g_SentryLaser[owner] -= g_SentryLaser[owner]
	g_SentryFreezing[owner] -= g_SentryFreezing[owner]
	g_SentryTesla[owner] -= g_SentryTesla[owner]
    if ( iSentryTeam ) g_teamsentriesNum[iSentryTeam-1]--
} 
public vzriv_mozga(sentry)
{
	new level = GetSentryLevel ( sentry )
	new team =  GetSentryTeam ( sentry )  
	if(level < 3)
	{
if (team == 1)
{		
		CreateExplosion4(sentry)
}
if (team == 2)
{
	CreateExplosion(sentry)
}
	}
	else
	{
	if(g_SentryMode[sentry] == 3)
	{
		CreateExplosion5(sentry)
	}
		if(g_SentryMode[sentry] == 6) 
		{			
        CreateExplosion3(sentry)     
        }
        if(g_SentryMode[sentry] == 5) 
		{			
        CreateExplosion2(sentry)     
        }
		if(g_SentryMode[sentry] == 1) 
		{			
        CreateExplosion4(sentry)     
        }
		if(g_SentryMode[sentry] == 2) 
		{			
        CreateExplosion1(sentry)     
        }
		if(g_SentryMode[sentry] == 4) 
		{			
        CreateExplosion6(sentry)     
        }
		if(g_SentryMode[sentry] == 7) 
		{			
        CreateExplosion7(sentry)     
        }
	}
}
public bacon_TakeDamage( sentry, idinflictor, idattacker, Float:damage, damagebits )
{	
	if ( !is_valid_ent ( sentry ) )
	return HAM_IGNORED
	new sClassname[ 32 ];
	pev( sentry, pev_classname, sClassname, charsmax( sClassname ) );
 new level = GetSentryLevel ( sentry )
	if ( equal ( sClassname, "sentry" ) || equal ( sClassname, "sentrybase" ) )
	{
		 new owner = GetSentryUpgrader(sentry, OWNER) 
		if(!is_user_connected(owner) || 1 > owner > 32 || !is_user_connected(idattacker) || 1 > idattacker > 32)
			return HAM_SUPERCEDE
new ent
		if(cs_get_user_team(owner)==cs_get_user_team(idattacker) && idattacker != owner)
			return HAM_SUPERCEDE
					new szName[ 32 ];
			get_user_name( idattacker, szName, charsmax( szName ) );
		if( pev( sentry, pev_health ) <= 0.0 )
		{
						 if (g_SentryMode[sentry] == 2)
			 {
				g_SentryLaser[owner] -= 1
			 }
			 			 					 if (g_SentryMode[sentry] == 1)
			 {
	g_SentryFreezing[owner] -= 1
			 }
						 if (g_SentryMode[sentry] == 4)
			 {
	g_SentryTesla[owner] -= 1
			 }
			new sName[ 32 ];
			get_user_name( owner, sName, charsmax( sName ) );
			if( idattacker == owner )
			{ 
		new iSentryCount = GetSentryCount ( owner )
				ChatColor(owner,"%L", owner, "SG_REWARD", 500)// СѓРЅРёС‡С‚РѕР¶РµРЅРёРµ РїСѓС€РєРё РІ СЂР°Р·СЂР°Р±РѕС‚РєРµ
				cs_set_user_money(owner,cs_get_user_money(owner) + 500) //SENTRYCOST[0]) 	РЅР°РіСЂР°РґР° Р·Р° Р°С‚Р°РєРєСѓ РїРѕ РїСѓС€РєРµ РІР°Рј
				 sentry_detonate ( ent, true, false )
			}
	else
			{
	    ChatColor ( owner, "%L", owner, "SG_EXPLOSION", level +1, szName)// СѓРЅРёС‡С‚РѕР¶РµРЅРёРµ РїСѓС€РєРё РІ СЂР°Р·СЂР°Р±РѕС‚РєРµ(РїРѕРєР° С‡С‚Рѕ Р»РµРЅСЊ)
		cs_set_user_money(idattacker, cs_get_user_money(idattacker) + 500) //SENTRYCOST[0]) РЅР°РіСЂР°РґР° Р·Р° Р°С‚Р°РєРєСѓ РїРѕ РїСѓС€РєРµ РІСЂР°РіСѓ
		ChatColor ( idattacker, "%L", idattacker, "SG_REWARD_1", level +1, sName)
		}
		ammo_hud(owner, 0)
		sentries_num[owner] -= 1
		ammo_hud(owner, 1)
		     vzriv_mozga(sentry)
	 emit_sound( sentry ,CHAN_VOICE,"CSSB/sentry_gun/sentry_exp.wav",1.0,0.5,0,PITCH_NORM)
	}
	}
	return HAM_IGNORED
}
public DelayRemoveEntity ( ent )
{             
    if ( pev_valid ( ent ) )
    remove_entity ( ent )
}

sentry_detonate_by_owner(owner, bool:quiet = false) {
		new sClassname[ 32 ];
		new sentry
	pev( sentry, pev_classname, sClassname, charsmax( sClassname ) );
 new level = GetSentryLevel ( sentry )
    for(new i = 0; i < g_sentriesNum; i++) {
        if (GetSentryUpgrader(g_sentries[i], OWNER) == owner) {
            sentry_detonate(i, quiet, true)
            //g_iKillSentry[g_sentries[i]] = 0;
            g_iKillSentry[g_sentries[i]] = 0;
        }
    }
}
     
public client_disconnect(id) {
    g_StatsKill[id] = 0;
    while (GetSentryCount(id) > 0)
    sentry_detonate_by_owner(id)
}

// СѓСЂРѕРЅ РёРіСЂРѕРєСѓ
stock sentry_damagetoplayer(sentry, sentryLevel, Float:sentryOrigin[3], target) {
 sentryLevel = GetSentryLevel (sentry)
   new newHealth = get_user_health(target) - get_pcvar_num(g_DMG[0])
   new newHealth1 = get_user_health(target) - get_pcvar_num(g_DMG[1])
   new newHealth2 = get_user_health(target) - get_pcvar_num(g_DMG[2])
   new newHealth3 = get_user_health(target) - get_pcvar_num(g_DMG[3])
   new newHealth4 = get_user_health(target) - get_pcvar_num(g_DMG[4])
            new level = GetSentryLevel ( sentry )
if (level == SENTRY_LEVEL_1 && newHealth <= 0 || level == SENTRY_LEVEL_2 && newHealth1 <= 0 || level == SENTRY_LEVEL_3 && newHealth2 <= 0 || level == SENTRY_LEVEL_4 && newHealth3 <= 0 || level == SENTRY_LEVEL_5 && newHealth4 <= 0 )
	{
		new targetFrags = get_user_frags(target) + 1
        new owner = GetSentryUpgrader(sentry, OWNER)
        
        if(!is_user_connected(owner))
        return
        
        new ownerFrags = get_user_frags(owner) + 1
        set_user_frags(target, targetFrags) // otherwise frags are subtracted from victim for dying (!!)
        set_user_frags(owner, ownerFrags)
        
        new contributors[5]
        contributors[0] = owner
        contributors[1] = GetSentryUpgrader(sentry, UPGRADER_1)
        contributors[2] = GetSentryUpgrader(sentry, UPGRADER_2)
        contributors[3] = GetSentryUpgrader(sentry, UPGRADER_3)
        contributors[4] = GetSentryUpgrader(sentry, UPGRADER_4)
        
        for(new i ; i < sizeof contributors ; i++){                    
            if(!contributors[i])
            continue
            
            if(!is_user_connected(contributors[i]) || get_user_team(contributors[i]) != get_user_team(contributors[0])){
                switch(i){ // yao face
                case 1: SetSentryUpgrader(sentry,UPGRADER_1,0)
                case 2: SetSentryUpgrader(sentry,UPGRADER_2,0)
                case 3: SetSentryUpgrader(sentry,UPGRADER_3,0)
                case 4: SetSentryUpgrader(sentry,UPGRADER_4,0)
                }
                
                continue
            }
			if(level == SENTRY_LEVEL_1)
			{
            // izvini 4yvak, no menya nakrilo
            cs_set_user_money(contributors[i],
            clamp(
            cs_get_user_money(contributors[i]) + (i == 0 ? SENTRYLVL1 : SENTRYLVL1),
            0,
            get_pcvar_num(sentry_max_money)
            )
            )
			}
						if(level == SENTRY_LEVEL_2)
			{
            // izvini 4yvak, no menya nakrilo
            cs_set_user_money(contributors[i],
            clamp(
            cs_get_user_money(contributors[i]) + (i == 0 ? SENTRYLVL2 : SENTRYLVL2),
            0,
            get_pcvar_num(sentry_max_money)
            )
            )
			}
									if(level == SENTRY_LEVEL_3)
			{
            // izvini 4yvak, no menya nakrilo
            cs_set_user_money(contributors[i],
            clamp(
            cs_get_user_money(contributors[i]) + (i == 0 ? SENTRYLVL3 : SENTRYLVL3),
            0,
            get_pcvar_num(sentry_max_money)
            )
            )
			}
									if(level == SENTRY_LEVEL_4)
			{
            // izvini 4yvak, no menya nakrilo
            cs_set_user_money(contributors[i],
            clamp(
            cs_get_user_money(contributors[i]) + (i == 0 ? SENTRYLVL4 : SENTRYLVL4),
            0,
            get_pcvar_num(sentry_max_money)
            )
            )
			}
									if(level == SENTRY_LEVEL_5)
			{
            // izvini 4yvak, no menya nakrilo
            cs_set_user_money(contributors[i],
            clamp(
            cs_get_user_money(contributors[i]) + (i == 0 ? SENTRYLVL5 : SENTRYLVL5),
            0,
            get_pcvar_num(sentry_max_money)
            )
            )
			}
        }

        // ny ebatb kakoy frag
        message_begin(MSG_ALL, g_msgDeathMsg, {0, 0, 0} ,0)
        write_byte(owner)
        write_byte(target)
        write_byte(0)
        write_string("sentry gun")
        message_end()
        
        //add_user_exp ( owner )
        scoreinfo_update(owner, ownerFrags, cs_get_user_deaths(owner), int:cs_get_user_team(owner))
        set_msg_block(g_msgDeathMsg, BLOCK_ONCE)
        
        g_iKillSentry[sentry]++;
        g_StatsKill[owner]++;
		
		new szShowMessage[256]
        				if (_Uf_ID_45() & get_user_flags(owner))
		{
									if (get_user_health(owner) + hp_for_kill >= max_hp_vip )
			{
			}
			else
			{
						if (get_user_health(owner) < max_hp_vip )
			{
			set_user_health(owner,get_user_health(owner) + hp_for_kill)
			}
										if (dhudmessage >0)
							{
			_Uf_ID_46(owner, szShowMessage, 0, 255, 0);	
			show_dhudmessage ( owner, "+%d", hp_for_kill )
							}
			if (blue_fade > 0)
{
	_Uf_ID_34(owner, 1<<10, 1<<10, 0x0000, 0, 0, 250, 75);
}
			}
		}
			else
			{
							if (get_user_health(owner) + hp_for_kill >= max_hp )
			{
			}
			else
			{
			if (get_user_health(owner) < max_hp )
			{
							set_user_health(owner,get_user_health(owner) + hp_for_kill)
			}
         
							if (dhudmessage >0)
							{
			_Uf_ID_46(owner, szShowMessage, 0, 255, 0);	
			show_dhudmessage ( owner, "+%d", hp_for_kill )
							}
			if (blue_fade > 0)
{
	_Uf_ID_34(owner, 1<<10, 1<<10, 0x0000, 0, 0, 250, 75);
}
			}
			}
        for (new i = 1; i <= g_iMaxPlayers; i++)
        {
            if( is_user_connected( i ) && !is_user_bot( i ) )
            {
                new sentry_frags = g_StatsKill[i];
                
                if( sentry_frags > higher_score )
                {
                    higher_score = sentry_frags;
                    get_user_name( i, g_OwnName, 31 );
                }
            }
        }
    }
	
if (level == SENTRY_LEVEL_1)
{
    set_user_health(target, newHealth)
	message_begin(MSG_ONE_UNRELIABLE, g_msgDamage, {0,0,0}, target)
    write_byte(get_pcvar_num(g_DMG[0]))
    write_byte(get_pcvar_num(g_DMG[0]))
    write_long(DMG_BULLET)
    write_coord(floatround(sentryOrigin[0]))
    write_coord(floatround(sentryOrigin[1]))
    write_coord(floatround(sentryOrigin[2]))
    message_end()
}
if (level == SENTRY_LEVEL_2)
{
    set_user_health(target, newHealth1)
		message_begin(MSG_ONE_UNRELIABLE, g_msgDamage, {0,0,0}, target)
    write_byte(get_pcvar_num(g_DMG[1]))
    write_byte(get_pcvar_num(g_DMG[1]))
    write_long(DMG_BULLET)
    write_coord(floatround(sentryOrigin[0]))
    write_coord(floatround(sentryOrigin[1]))
    write_coord(floatround(sentryOrigin[2]))
    message_end()
}
if (level == SENTRY_LEVEL_3)
{
    set_user_health(target, newHealth2)
		message_begin(MSG_ONE_UNRELIABLE, g_msgDamage, {0,0,0}, target)
    write_byte(get_pcvar_num(g_DMG[2]))
    write_byte(get_pcvar_num(g_DMG[2]))
    write_long(DMG_BULLET)
    write_coord(floatround(sentryOrigin[0]))
    write_coord(floatround(sentryOrigin[1]))
    write_coord(floatround(sentryOrigin[2]))
    message_end()
}
if (level == SENTRY_LEVEL_4)
{
    set_user_health(target, newHealth3)
		message_begin(MSG_ONE_UNRELIABLE, g_msgDamage, {0,0,0}, target)
    write_byte(get_pcvar_num(g_DMG[3]))
    write_byte(get_pcvar_num(g_DMG[3]))
    write_long(DMG_BULLET)
    write_coord(floatround(sentryOrigin[0]))
    write_coord(floatround(sentryOrigin[1]))
    write_coord(floatround(sentryOrigin[2]))
    message_end()
}
if (level == SENTRY_LEVEL_5)
{
    set_user_health(target, newHealth4)
		message_begin(MSG_ONE_UNRELIABLE, g_msgDamage, {0,0,0}, target)
    write_byte(get_pcvar_num(g_DMG[4]))
    write_byte(get_pcvar_num(g_DMG[4]))
    write_long(DMG_BULLET)
    write_coord(floatround(sentryOrigin[0]))
    write_coord(floatround(sentryOrigin[1]))
    write_coord(floatround(sentryOrigin[2]))
    message_end()
}
}

scoreinfo_update(id, frags, deaths, team) {
    message_begin(MSG_ALL, g_msgScoreInfo)
    write_byte(id)                           
    write_short(frags)
    write_short(deaths)
    write_short(0)
    write_short(team)
    message_end()
}
_Uf_ID_34(owner, number, number2, number3, red, green, blue, alpha)
{
			message_begin(MSG_ONE, get_user_msgid("ScreenFade"), {0,0,0}, owner)
        write_short(number)
        write_short(number2)
        write_short(number3)
        write_byte(red)
        write_byte(green)
        write_byte(blue)
        write_byte(alpha)
        message_end()
	return 0;
}
SentryTurnToTarget ( ent, Float:sentry_origin[3], Float:closest_origin[3] )
{
    new Float:fAngle[3]
    entity_get_vector ( ent, EV_VEC_angles, fAngle )
    new Float:x = closest_origin[0] - sentry_origin[0]
    new Float:z = closest_origin[1] - sentry_origin[1]
    new Float:y = closest_origin[2] - sentry_origin[2]

    new Float:fRadians = floatatan ( z/x, radian )
    fAngle[1] = fRadians * g_ONEEIGHTYTHROUGHPI
    if ( closest_origin[0] < sentry_origin[0] )
    fAngle[1] -= 180.0
        
    new Float:RADIUS = 180.0
    new Float:degreeByte = RADIUS/256.0
                
    new Float:tilt = 127.0+(degreeByte*fAngle[1])
    
    new Float:h = closest_origin[2] - sentry_origin[2]
    new Float:b = vector_distance(sentry_origin, closest_origin)
    fRadians = floatatan (h/b, radian)
    fAngle[0] = fRadians * (180.0 / 3.141592654)
    
    RADIUS = 360.0    
    degreeByte = RADIUS/256.0
    tilt = 127.0-degreeByte * fAngle[0]

    entity_set_float(ent,SENTRY_FL_ANGLE,floatround(fAngle[0]))
    entity_set_vector(ent,EV_VEC_angles,fAngle)
} 

AimingAtSentry ( id )
{
    if ( !is_user_alive ( id ) )
    return 0

    new hitEnt, bodyPart
    if (get_user_aiming(id, hitEnt, bodyPart) == 0.0)
    return 0

    if ( is_valid_ent ( hitEnt ) )
    {
        new classname[32], l_sentry
        entity_get_string(hitEnt, EV_SZ_classname, classname, 31)
        if (equal(classname, "sentry_base"))           
        l_sentry = entity_get_edict(hitEnt, BASE_ENT_SENTRY)
        else if (equal(classname, "sentry"))
        l_sentry = hitEnt
        else
        l_sentry = 0

        return l_sentry
    }
    return 0           
} 

public taimer_obnul2 (id)
{
    szTime = 0
}

public taimer_obnul (id)
{               
    set_task(1.0, "taimer_obnul2")
}
                                         
// СѓР»СѓС‡С€РµРЅРёРµ СѓСЂРѕРІРЅСЏ РїСѓС€РєРё
bool:SentryUpgrade ( id, sentry, num ) 
{   
    if(szTime > 0)
    return false 

  
    new iLevel = GetSentryLevel ( sentry )
    if ( iLevel >= SENTRY_LEVEL_5 )
	{
		
		if(g_OffSpam[id] == 1) {
	if(g_SentryMode[sentry] == 2)	
	{		
	ChatColor( id, "%L", id, "SG_ZAPRET_14", -1, "SG_HUD_MODE_2")
	}
		if(g_SentryMode[sentry] == 3)
	{		
	ChatColor( id, "%L", id, "SG_ZAPRET_14", -1, "SG_HUD_MODE_3")
	}
		if(g_SentryMode[sentry] == 4)
	{		
	ChatColor( id, "%L", id, "SG_ZAPRET_14", -1, "SG_HUD_MODE_4")
	}
	}
    return false
	}
    if(get_user_flags(id) & _Uf_ID_47())
    {
        //РђРґРјРёРЅР°Рј РјРѕР¶РЅРѕ РїСЂРѕРєР°С‡РёРІР°С‚СЊ РїСѓС€РєСѓ РїРѕ РјР°РєСЃРёРјСѓРјСѓ.
        //if ( GetSentryUpgrader ( sentry, OWNER ) == id )
        //    return false
        
    } 
    
    if(cs_get_user_team(id) != GetSentryTeam(sentry))
    return false
                                  new iOwner = GetSentryUpgrader ( sentry, OWNER )     
 new iVip = get_user_flags( id ) & _Uf_ID_47()								  
new level = GetSentryLevel ( sentry )
    if(iVip)
    {
	}
	else
	{
	if (id == iOwner)
	{     
					if(g_OffSpam[id] == 1)
			{
		ChatColor( id, "%L", id, "SG_ZAPRET_12")
			}
		return false
		} 
	}
    iLevel++
		        if(iLevel == SENTRY_LEVEL_2)
		{	
    if ( (cs_get_user_money ( id ) - get_pcvar_num(iVip ? g_COST_VIP[0] : g_COST[0])) < 0 )
    {                        
        if(g_OffSpam[id] == 1) {                  
            ChatColor( id, "%L", id, "SG_ZAPRET_10", get_pcvar_num(iVip ? g_COST_VIP[0] : g_COST[0]))
           emit_sound( id,CHAN_VOICE,"CSSB/sentry_gun/fail_update_1.wav",1.0,0.5,0,PITCH_NORM)			
            taimer_obnul (id)
        }                                                                         
        return false                            

    }
else
{
	cs_set_user_money ( id, cs_get_user_money ( id ) - get_pcvar_num(iVip ? g_COST_VIP[0] : g_COST[0]) ) 
}	
		}
		        if(iLevel == SENTRY_LEVEL_3)
		{	
    if ( (cs_get_user_money ( id ) - get_pcvar_num(iVip ? g_COST_VIP[1] : g_COST[1])) < 0 )
    {                        
        if(g_OffSpam[id] == 1) {                  
            ChatColor( id, "%L", id, "SG_ZAPRET_10", get_pcvar_num(iVip ? g_COST_VIP[1] : g_COST[1]))
           emit_sound( id,CHAN_VOICE,"CSSB/sentry_gun/fail_update_1.wav",1.0,0.5,0,PITCH_NORM)			
            taimer_obnul (id)
        }                                                                         
        return false                            

    }
else
{
	cs_set_user_money ( id, cs_get_user_money ( id ) - get_pcvar_num(iVip ? g_COST_VIP[1] : g_COST[1]) ) 
}	
		}
    if(iLevel == SENTRY_LEVEL_5 && num == 0) 
    {
        g_SentryId[id] = sentry 
if(g_OffSpam[id] == 1) {		
        MenuUpgrade(id)
}
        return 0
    }
    if(iLevel == SENTRY_LEVEL_4 && num == 0) 
    {
        g_SentryId[id] = sentry
		if(g_OffSpam[id] == 1) {
        Sentry_4_Upgrade(id)
		}
        return 0
    }
                                                          
    taimer_obnul (id)                          
                    
    /*if(!is_user_admin(id))       
    {
        cs_set_user_money ( id, cs_get_user_money ( id ) - g_COST[iLevel] )
    }*/
if (get_pcvar_num(sg_money_upgdate_owner) > 0 || id != iOwner)
{	
		        if(iLevel == SENTRY_LEVEL_2)
		{			
                    
    cs_set_user_money( id, cs_get_user_money( id ) + get_pcvar_num(MONEY[0]))        //РўРѕС‚ СЃР°РјС‹Р№ РєРѕРґ РІРѕР·РЅР°РіСЂР°Р¶РґРµРЅРёСЏ 
                                                
    ChatColor(id, "%L", id, "SG_NAGRADA", get_pcvar_num(MONEY[0]))   
		}	
		        if(iLevel == SENTRY_LEVEL_3)
		{			
                    
    cs_set_user_money( id, cs_get_user_money( id ) + get_pcvar_num(MONEY[1]))        //РўРѕС‚ СЃР°РјС‹Р№ РєРѕРґ РІРѕР·РЅР°РіСЂР°Р¶РґРµРЅРёСЏ 
                                                
    ChatColor(id, "%L", id, "SG_NAGRADA", get_pcvar_num(MONEY[1]))   
		}	
		        if(iLevel == SENTRY_LEVEL_4)
		{			
                    
    cs_set_user_money( id, cs_get_user_money( id ) + get_pcvar_num(MONEY[2]))        //РўРѕС‚ СЃР°РјС‹Р№ РєРѕРґ РІРѕР·РЅР°РіСЂР°Р¶РґРµРЅРёСЏ 
                                                
    ChatColor(id, "%L", id, "SG_NAGRADA", get_pcvar_num(MONEY[2]))   
		}	
		        if(iLevel == SENTRY_LEVEL_5)
		{			
                    
    cs_set_user_money( id, cs_get_user_money( id ) + get_pcvar_num(MONEY[3]))        //РўРѕС‚ СЃР°РјС‹Р№ РєРѕРґ РІРѕР·РЅР°РіСЂР°Р¶РґРµРЅРёСЏ 
                                                
    ChatColor(id, "%L", id, "SG_NAGRADA", get_pcvar_num(MONEY[3]))   
		}	
}
new ent	
    new iTeam = get_user_team ( id ), iUpgraderField
	if (get_user_flags(iOwner) & _Uf_ID_47())
	{
    switch ( iLevel )                  
    {                                                                      
        // this kod is very zaebisb
    case SENTRY_LEVEL_2:                                     
    {                    	
            switch ( iTeam )
            {                                               
            case 1:entity_set_model ( sentry, SENTRYVIPMODEL2_TE )
            case 2:entity_set_model ( sentry, SENTRYVIPMODEL2_CT )
            }                                                  
            iUpgraderField = UPGRADER_1
	}
    case SENTRY_LEVEL_3:                    
    {                                                           
            switch ( iTeam )
            {                                               
            case 1:entity_set_model ( sentry, SENTRYVIPMODEL3_TE )
            case 2:entity_set_model ( sentry, SENTRYVIPMODEL3_CT )
            }                                                  
            iUpgraderField = UPGRADER_2
        }
    case SENTRY_LEVEL_4:                   
    {                                                           
            switch ( iTeam )
            {                                               
            case 1:entity_set_model ( sentry, SENTRYVIPMODEL4_TE )
            case 2:entity_set_model ( sentry, SENTRYVIPMODEL4_CT )
            }                                                  
        
            
            entity_set_byte(sentry,EV_BYTE_controller2,120)
            entity_set_byte(sentry,EV_BYTE_controller3,120)
                                           
            iUpgraderField = UPGRADER_3
	}
    case SENTRY_LEVEL_5:{
            
            new Float:fOriginSentry[3];
            entity_get_vector ( sentry , EV_VEC_origin, fOriginSentry )
            new origin[3],data[6];
            FVecIVec(fOriginSentry,origin)
            data[3] =  origin[0];
            data[4] =  origin[1];
            data[5] =  origin[2];
                               
    {                                                           
            switch ( iTeam )
            {                                               
            case 1:entity_set_model ( sentry, SENTRYVIPMODEL5_TE )
            case 2:entity_set_model ( sentry, SENTRYVIPMODEL5_CT )
            }                                                  
        }                                   
      //      set_task(1.0,"sentry_blast", sentry + BLAST_TASK_ID , data ,6 ,"b"); //РЈСЃС‚Р°РЅР°РІР»РёРІР°РµРј СЃРІРµС‡РµРЅРёРµ
            
            entity_set_byte(sentry,EV_BYTE_controller2,120)
            entity_set_byte(sentry,EV_BYTE_controller3,120)
                                               
            iUpgraderField = UPGRADER_4                       
        }
		}
	}
	else
	{
		    switch ( iLevel )                  
    {                                                                      
        // this kod is very zaebisb
    case SENTRY_LEVEL_2:                                     
    {                    	
            switch ( iTeam )
            {                                               
            case 1:entity_set_model ( sentry, SENTRYPLAYERMODEL2_TE )
            case 2:entity_set_model ( sentry, SENTRYPLAYERMODEL2_CT )
            }                                                  
            iUpgraderField = UPGRADER_1
	}
    case SENTRY_LEVEL_3:                    
    {                                                           
            switch ( iTeam )
            {                                               
            case 1:entity_set_model ( sentry, SENTRYPLAYERMODEL3_TE )
            case 2:entity_set_model ( sentry, SENTRYPLAYERMODEL3_CT )
            }                                                  
            iUpgraderField = UPGRADER_2
        }
    case SENTRY_LEVEL_4:                   
    {                                                           
            switch ( iTeam )
            {                                               
            case 1:entity_set_model ( sentry, SENTRYPLAYERMODEL4_TE )
            case 2:entity_set_model ( sentry, SENTRYPLAYERMODEL4_CT )
            }                                                  
        
            
            entity_set_byte(sentry,EV_BYTE_controller2,120)
            entity_set_byte(sentry,EV_BYTE_controller3,120)
                                           
            iUpgraderField = UPGRADER_3
	}
    case SENTRY_LEVEL_5:{
            
            new Float:fOriginSentry[3];
            entity_get_vector ( sentry , EV_VEC_origin, fOriginSentry )
            new origin[3],data[6];
            FVecIVec(fOriginSentry,origin)
            data[3] =  origin[0];
            data[4] =  origin[1];
            data[5] =  origin[2];
                               
    {                                                           
            switch ( iTeam )
            {                                               
            case 1:entity_set_model ( sentry, SENTRYPLAYERMODEL5_TE )
            case 2:entity_set_model ( sentry, SENTRYPLAYERMODEL5_CT )
            }                                                  
        }                                   
      //      set_task(1.0,"sentry_blast", sentry + BLAST_TASK_ID , data ,6 ,"b"); //РЈСЃС‚Р°РЅР°РІР»РёРІР°РµРј СЃРІРµС‡РµРЅРёРµ
            
            entity_set_byte(sentry,EV_BYTE_controller2,120)
            entity_set_byte(sentry,EV_BYTE_controller3,120)
                                               
            iUpgraderField = UPGRADER_4                       
        }
		}
	}

    new Float:fMins[3], Float:fMaxs[3]                                     
    fMins[0] = -16.0     
    fMins[1] = -16.0
    fMins[2] = 0.0                                                                     
    fMaxs[0] = 16.0
    fMaxs[1] = 16.0                        
    fMaxs[2] = 35.0 // 4.0
    entity_set_size ( sentry, fMins, fMaxs )
    emit_sound ( sentry, CHAN_VOICE, "CSSB/sentry_gun/turret_up_2.wav", 1.0, ATTN_NORM, 0, PITCH_NORM )
    SetSentryLevel ( sentry, iLevel )
	if(iLevel == SENTRY_LEVEL_1)
	{
    entity_set_float ( sentry, EV_FL_health, get_pcvar_float(g_HEALTHS[0]) )
    }
		if(iLevel == SENTRY_LEVEL_2)
	{
    entity_set_float ( sentry, EV_FL_health, get_pcvar_float(g_HEALTHS[1]) )
    }
		if(iLevel == SENTRY_LEVEL_3)
	{
    entity_set_float ( sentry, EV_FL_health, get_pcvar_float(g_HEALTHS[2]) )
    }
		if(iLevel == SENTRY_LEVEL_4)
	{
    entity_set_float ( sentry, EV_FL_health, get_pcvar_float(g_HEALTHS[3]) )
    }
		if(iLevel == SENTRY_LEVEL_5)
	{
    entity_set_float ( sentry, EV_FL_health, get_pcvar_float(g_HEALTHS[4]) )
    }
    entity_set_float ( entity_get_edict ( sentry, SENTRY_ENT_BASE ), EV_FL_health, 100000.0 )                    
    SetSentryUpgrader ( sentry, iUpgraderField, id )
                                                   
		    new OwnName[33]
	new szShowMessage[256]
    get_user_name ( iOwner, OwnName, 32 )
    new sName[32]
    get_user_name ( id, sName, charsmax ( sName ) )   
    szTime = 1                      
    taimer_obnul (id)  
if (get_pcvar_num(sg_money_upgdate_owner) > 0 || id != iOwner)
{	
if (iLevel < 3 )
{
		ChatColor( iOwner, "%L",iOwner, "SG_UPGRADE",  sName, iLevel +1 )	
		ChatColor(  id , "%L", id , "SG_UPGRADE2",  OwnName, iLevel + 1 )	
}
}
return true
                                            
}                                                         
                                                
public MenuUpgrade(id)
{
    static menu[512], len=0;
    len = formatex(menu[len], charsmax(menu) - len, "%L", id, "SG_MENU_NAZ_5");   
    if(get_pcvar_num(g_Cvar_mode_aktiv[1]) == 1)
    {
        len += formatex(menu[len], charsmax(menu) - len, "%L", id, "SG_MENU_KEY_1_LVL_5", sentry_4_5_lvlcost(1,id),g_SentryLaser[id],get_pcvar_num(max_sentry5_lvl[0]));
    }
	    if(get_pcvar_num(g_Cvar_mode_aktiv[2]) == 1)
    {
        len += formatex(menu[len], charsmax(menu) - len, "%L", id, "SG_MENU_KEY_2_LVL_5", sentry_4_5_lvlcost(2,id),g_SentryFreezing[id],get_pcvar_num(max_sentry5_lvl[1]));
    }
			    if(get_pcvar_num(g_Cvar_mode_aktiv[3]) == 1)
    {
        len += formatex(menu[len], charsmax(menu) - len, "%L", id, "SG_MENU_KEY_3_LVL_5", sentry_4_5_lvlcost(3,id),g_SentryTesla[id],get_pcvar_num(max_sentry5_lvl[2]));
    }	
if(get_pcvar_num(g_Cvar_mode_aktiv[1]) != 1 && get_pcvar_num(g_Cvar_mode_aktiv[2]) != 1 && get_pcvar_num(g_Cvar_mode_aktiv[3]) != 1)
{
return false
}
    
    //Р’С‹РІРѕРґ РЅР° РїРѕРєР°Р· РјРµРЅСЋ
    show_menu(id, keys, menu, 4, "Menu");
    return PLUGIN_HANDLED;
}

public sentry_4_5_lvlcost(i, id)
{
	new cost
			if (_Uf_ID_45() & get_user_flags(id))
	{
		cost = ((100 - get_pcvar_num(cvar_admin_mul_cost)) * get_pcvar_num(g_Cvar_mode_cost[i]))/100	
	}
	else
	{
		cost = get_pcvar_num(g_Cvar_mode_cost[i])
	}
	return cost;
}
public Sentry_4_Upgrade(id)
{                 
    static menu[512], len=0;
    len = formatex(menu[len], charsmax(menu) - len, "%L", id, "SG_MENU_NAZ_4");
    if(get_pcvar_num(g_Cvar_mode_aktiv[4]) == 1) 
    {                          
        len += formatex(menu[len], charsmax(menu) - len, "%L", id, "SG_MENU_KEY_1_ONN_4", sentry_4_5_lvlcost(4,id));  
    }                                                                                 
    if(get_pcvar_num(g_Cvar_mode_aktiv[1]) == 1) 
    {                          
        len += formatex(menu[len], charsmax(menu) - len, "%L", id, "SG_MENU_KEY_2_ONN_4", sentry_4_5_lvlcost(5,id));                                                        
    }                                                                                 
	    if(get_pcvar_num(g_Cvar_mode_aktiv[0]) == 1) 
    {                          
        len += formatex(menu[len], charsmax(menu) - len, "%L", id, "SG_MENU_KEY_3_ONN_4", sentry_4_5_lvlcost(0,id));                                                        
    }
	    if(get_pcvar_num(g_Cvar_mode_aktiv[5]) == 1) 
    {                          
        len += formatex(menu[len], charsmax(menu) - len, "%L", id, "SG_MENU_KEY_4_ONN_4", sentry_4_5_lvlcost(6,id));                                                        
    } 	
    
    //Р’С‹РІРѕРґ РЅР° РїРѕРєР°Р· РјРµРЅСЋ   
    show_menu(id, keys, menu, 4, "Sentry_4");
    return PLUGIN_HANDLED;                                         
}

public Sentry4_Func(id, key) 
{
			    new OwnName[33], idName[33]
				new owner = GetSentryUpgrader ( g_SentryId[id], OWNER )
    get_user_name ( owner, OwnName, 32 )
	get_user_name ( id, idName, 32 )
	    new Float:origin[3],classname[32],e, Float:distance
    entity_get_vector(id,EV_VEC_origin,origin)
                                                               
     new Float:fSentryOrigin[3]
    entity_get_vector ( g_SentryId[id], EV_VEC_origin, fSentryOrigin )
        entity_get_string(e,EV_SZ_classname,classname,charsmax(classname))
		   distance = vector_distance(origin, fSentryOrigin)
		     if (distance > get_pcvar_float(sg_dist_update_in_menu_sentry)) {
				  
            ChatColor(id,"%L", id, "SG_ZAPRET_9", get_pcvar_float(sg_dist_update_in_menu_sentry))
            emit_sound( id,CHAN_VOICE,"CSSB/sentry_gun/fail_update_1.wav",1.0,0.5,0,PITCH_NORM)
            return 0                                                                                  
        }      		
    switch(key)
    {
        case 0: {                                  
            if(szTime == 0)
            {
                if(get_pcvar_num(g_Cvar_mode_aktiv[4]) == 1)         
                {
                    if(cs_get_user_money(id) >= sentry_4_5_lvlcost(4,id))
                    {
                        if(is_valid_ent(g_SentryId[id])) {
                            SentryUpgrade ( id, g_SentryId[id], 1);
                            g_SentryMode[g_SentryId[id]] = 1                             
                            cs_set_user_money( id, cs_get_user_money( id ) - sentry_4_5_lvlcost(4,id) )
							if (get_pcvar_num(sg_money_upgdate_owner) > 0 || id != owner)
{	
							ChatColor(  id , "%L", id , "SG_UPGRADE3",  OwnName, -1, "SG_HUD_MODE_1")
                            ChatColor(  owner , "%L", owner , "SG_UPGRADE4", idName, -1, "SG_HUD_MODE_1")	
}							
                        }
                    }                                             
                    else                                     
                    {
                        ChatColor(id,"%L", id, "SG_ZAPRET_7",sentry_4_5_lvlcost(4,id))
						emit_sound( id,CHAN_VOICE,"CSSB/sentry_gun/fail_update_1.wav",1.0,0.5,0,PITCH_NORM)
                    }
                }                            
            }      
        }
         case 1: { 
            if(szTime == 0)
            {                                             
                if(get_pcvar_num(g_Cvar_mode_aktiv[1]) == 1)         
                {                                   
                    if(cs_get_user_money(id) >= sentry_4_5_lvlcost(5,id))
                    {                                     
                        if(is_valid_ent(g_SentryId[id])) {
                            SentryUpgrade ( id, g_SentryId[id], 1);
                            g_SentryMode[g_SentryId[id]] = 5   
                            cs_set_user_money( id, cs_get_user_money( id ) - sentry_4_5_lvlcost(5,id) )
							if (get_pcvar_num(sg_money_upgdate_owner) > 0 || id != owner)
{	
                            ChatColor(  id , "%L", id , "SG_UPGRADE3",  OwnName, -1, "SG_HUD_MODE_5")
                            ChatColor(  owner , "%L", owner , "SG_UPGRADE4", idName, -1, "SG_HUD_MODE_5")	
}
                        }
                    }
                    else                                     
                    {
                        ChatColor(id,"%L", id, "SG_ZAPRET_7",sentry_4_5_lvlcost(5,id))
						emit_sound( id,CHAN_VOICE,"CSSB/sentry_gun/fail_update_1.wav",1.0,0.5,0,PITCH_NORM)
                    }
                }       
            }
        }
		case 2: { 
            if(szTime == 0)
            {                                             
                if(get_pcvar_num(g_Cvar_mode_aktiv[0]) == 1)         
                {                                   
                    if(cs_get_user_money(id) >= sentry_4_5_lvlcost(0,id))
                    {                                     
                        if(is_valid_ent(g_SentryId[id])) {
                            SentryUpgrade ( id, g_SentryId[id], 1);
                            g_SentryMode[g_SentryId[id]] = 6   
                            cs_set_user_money( id, cs_get_user_money( id ) - sentry_4_5_lvlcost(0,id) )	
							if (get_pcvar_num(sg_money_upgdate_owner) > 0 || id != owner)
{	
							ChatColor(  id , "%L", id , "SG_UPGRADE3",  OwnName, -1, "SG_HUD_MODE_6")
                            ChatColor(  owner , "%L", owner , "SG_UPGRADE4", idName, -1, "SG_HUD_MODE_6")	
}
                        }
                    }
                    else                                     
                    {
                        ChatColor(id,"%L", id, "SG_ZAPRET_7",sentry_4_5_lvlcost(0,id))
						emit_sound( id,CHAN_VOICE,"CSSB/sentry_gun/fail_update_1.wav",1.0,0.5,0,PITCH_NORM)
                    }
                }       
            }
        }
		case 3:
		{
            if(szTime == 0)
            {                                             
                if(get_pcvar_num(g_Cvar_mode_aktiv[1]) == 1)         
                {                                   
                    if(cs_get_user_money(id) >= sentry_4_5_lvlcost(6,id))
                    {                                     
                        if(is_valid_ent(g_SentryId[id])) {
                            SentryUpgrade ( id, g_SentryId[id], 1);
                            g_SentryMode[g_SentryId[id]] = 7  
							g_SentryModem[g_SentryId[id]] = 7
                            cs_set_user_money( id, cs_get_user_money( id ) - sentry_4_5_lvlcost(6,id) )
							if (get_pcvar_num(sg_money_upgdate_owner) > 0 || id != owner)
{	
							ChatColor(  id , "%L", id , "SG_UPGRADE3",  OwnName, -1, "SG_HUD_MODE_7")
                            ChatColor(  owner , "%L", owner , "SG_UPGRADE4", idName, -1, "SG_HUD_MODE_7")	
}
                        }
                    }
                    else                                     
                    {
                        ChatColor(id,"%L", id, "SG_ZAPRET_7",sentry_4_5_lvlcost(6,id))
						emit_sound( id,CHAN_VOICE,"CSSB/sentry_gun/fail_update_1.wav",1.0,0.5,0,PITCH_NORM)
                    }
                }       
            }
        }
        case 9:{                          
        }                                  
    }
    return PLUGIN_HANDLED;
} 

public MenuFunc(id, key) 
{
			    new OwnName[33], idName[33]
				new owner = GetSentryUpgrader ( g_SentryId[id], OWNER )
    get_user_name ( owner, OwnName, 32 )
	get_user_name ( id, idName, 32 )
	    new Float:origin[3],classname[32],e, Float:distance
    entity_get_vector(id,EV_VEC_origin,origin)
        entity_get_string(e,EV_SZ_classname,classname,charsmax(classname))
     new Float:fSentryOrigin[3]
    entity_get_vector ( g_SentryId[id], EV_VEC_origin, fSentryOrigin )
        entity_get_string(e,EV_SZ_classname,classname,charsmax(classname))
		   distance = vector_distance(origin, fSentryOrigin)
		     if (distance > get_pcvar_float(sg_dist_update_in_menu_sentry)) {
				ChatColor(id,"%L", id, "SG_ZAPRET_9", get_pcvar_float(sg_dist_update_in_menu_sentry))
				  emit_sound( id,CHAN_VOICE,"CSSB/sentry_gun/fail_update_1.wav",1.0,0.5,0,PITCH_NORM)
				return false
		}
    switch(key)
    {

        case 0: { 
				if (g_SentryLaser[id] >= get_pcvar_num(max_sentry5_lvl[0]))
		{
			ChatColor(id,"%L", id, "SG_ZAPRET_15", get_pcvar_num(max_sentry5_lvl[0]), get_pcvar_num(max_sentry5_lvl[0]), id, "SG_HUD_MODE_2")
       return false
		}
		else
		{
            if(szTime == 0)
            {
                if(get_pcvar_num(g_Cvar_mode_aktiv[1]) == 1)         
                {
                    if(cs_get_user_money(id) >= sentry_4_5_lvlcost(1,id))
                    {
                        if(is_valid_ent(g_SentryId[id])) {
                            SentryUpgrade ( id, g_SentryId[id], 1);
                            g_SentryMode[g_SentryId[id]] = 2                             
                            cs_set_user_money( id, cs_get_user_money( id ) - sentry_4_5_lvlcost(1,id) )
							if (get_pcvar_num(sg_money_upgdate_owner) > 0 || id != owner)
{	
							 ChatColor(  id , "%L", id , "SG_UPGRADE3",  OwnName, -1, "SG_HUD_MODE_2")
                            ChatColor(  owner , "%L", owner , "SG_UPGRADE4", idName, -1, "SG_HUD_MODE_2")	
}
							g_SentryLaser[id]++
                       
                    }
					}					
                    else                                     
                    {
                        ChatColor(id,"%L", id, "SG_ZAPRET_7",sentry_4_5_lvlcost(1,id))
						emit_sound( id,CHAN_VOICE,"CSSB/sentry_gun/fail_update_1.wav",1.0,0.5,0,PITCH_NORM)
                    }
                }
            }
        } 
		}
        case 1: { 
						if (g_SentryFreezing[owner] >= get_pcvar_num(max_sentry5_lvl[1]))
		{
			ChatColor(id,"%L", id, "SG_ZAPRET_15", get_pcvar_num(max_sentry5_lvl[1]), get_pcvar_num(max_sentry5_lvl[1]), id, "SG_HUD_MODE_3")
       return false
		}
		else
		{
            if(szTime == 0)
            {                                   
                if(get_pcvar_num(g_Cvar_mode_aktiv[2]) == 1)
                {
                    if(cs_get_user_money(id) >= sentry_4_5_lvlcost(2,id))
                    {
                        if(is_valid_ent(g_SentryId[id])) {
                            SentryUpgrade ( id, g_SentryId[id], 1);
                            g_SentryMode[g_SentryId[id]] = 3                                                     
                            cs_set_user_money( id, cs_get_user_money( id ) - sentry_4_5_lvlcost(2,id) )
							if (get_pcvar_num(sg_money_upgdate_owner) > 0 || id != owner)
{	
							ChatColor(  id , "%L", id , "SG_UPGRADE3",  OwnName, -1, "SG_HUD_MODE_3")
                            ChatColor(  owner , "%L", owner , "SG_UPGRADE4", idName, -1, "SG_HUD_MODE_3")
}							
							g_SentryFreezing[owner]++
                        } 
                    }
                    else
                    {
                        ChatColor(id,"%L", id, "SG_ZAPRET_7",sentry_4_5_lvlcost(2,id))
						emit_sound( id,CHAN_VOICE,"CSSB/sentry_gun/fail_update_1.wav",1.0,0.5,0,PITCH_NORM)
                    }                                     
                
                }
            } 
        }
		}
         case 2: { 
		 				if (g_SentryTesla[owner] >= get_pcvar_num(max_sentry5_lvl[2]))
		{
			ChatColor(id,"%L", id, "SG_ZAPRET_15", get_pcvar_num(max_sentry5_lvl[2]), get_pcvar_num(max_sentry5_lvl[2]), id, "SG_HUD_MODE_4")
       return false
		}
		{
            if(szTime == 0)
            {
                if(get_pcvar_num(g_Cvar_mode_aktiv[3]) == 1)         
                {                                   
                    if(cs_get_user_money(id) >= sentry_4_5_lvlcost(3,id))
                    {                                     
                        if(is_valid_ent(g_SentryId[id])) {
                            SentryUpgrade ( id, g_SentryId[id], 1);
                            g_SentryMode[g_SentryId[id]] = 4   
                            cs_set_user_money( id, cs_get_user_money( id ) - sentry_4_5_lvlcost(3,id) )
							if (get_pcvar_num(sg_money_upgdate_owner) > 0 || id != owner)
{	
							ChatColor(  id , "%L", id , "SG_UPGRADE3",  OwnName, -1, "SG_HUD_MODE_4")
                            ChatColor(  owner , "%L", owner , "SG_UPGRADE4", idName, -1, "SG_HUD_MODE_4")	
}
							g_SentryTesla[owner]++
                        }
                    }
                    else                                     
                    {
                        ChatColor(id,"%L", id, "SG_ZAPRET_7",sentry_4_5_lvlcost(3,id))
						emit_sound( id,CHAN_VOICE,"CSSB/sentry_gun/fail_update_1.wav",1.0,0.5,0,PITCH_NORM)
                    }
                }
            }
        } 
		 }
        case 9:{       
        } 
    }
    return PLUGIN_HANDLED;
} 
stock EntViewHitPoint ( index, Float:origin[3], Float:hitorigin[3] )
{
    if ( !is_valid_ent ( index ) )
    return 0

    new Float:angle[3], Float:vec[3], Float:f_dest[3]

    entity_get_vector(index, EV_VEC_angles, angle)

    engfunc(EngFunc_AngleVectors, angle, vec, 0, 0)
                                                                             
    f_dest[0] = origin[0] + vec[0] * 9999
    f_dest[1] = origin[1] + vec[1] * 9999
    f_dest[2] = origin[2] + vec[2] * 9999

    return trace_line(index, origin, f_dest, hitorigin)
}

public fw_PlayerSpawn_Post ( id )
{
    if ( !is_user_alive ( id ) )
    return



    while ( GetSentryCount ( id ) > 0 )
    sentry_detonate_by_owner ( id, true )

    ammo_hud ( id, 0 )
    sentries_num[id] = 0

}
public fw_TraceLine_Post ( Float:start[3], Float:end[3], noMonsters, id, sentry )
{
	
    if ( !is_valid_player ( id ) )
    return FMRES_IGNORED                        
                 new Float:fOriginSentry[3];
            new origin[3],data[6];
            FVecIVec(fOriginSentry,origin)
            data[3] =  origin[0];
            data[4] =  origin[1];
            data[5] =  origin[2];                                                            
    new iHitEnt = get_tr ( TR_pHit )

    if ( iHitEnt <= g_iMaxPlayers )
    return FMRES_IGNORED

    new sClassName[11], sentry, base

    pev ( iHitEnt, pev_classname, sClassName, charsmax ( sClassName ) )

    if ( equal ( sClassName, "sentrybase" ) )
    {                                        
        base = iHitEnt
        sentry = entity_get_edict ( iHitEnt, BASE_ENT_SENTRY )
    }
    else if ( equal ( sClassName, "sentry" ) )
    {                       
        sentry = iHitEnt
        base = entity_get_edict ( sentry, SENTRY_ENT_BASE )
    }

    if ( !pev_valid ( sentry ) || !base )
    return FMRES_IGNORED  
    
    if ( GetSentryFiremode ( sentry ) == SENTRY_FIREMODE_NUTS )
    return FMRES_IGNORED
    
    new Float:health = entity_get_float ( sentry, EV_FL_health )

    if ( health <= 0 )
    return FMRES_IGNORED
                               
    new Float:basehealth = entity_get_float ( base, EV_FL_health )

    if ( basehealth <= 0 )
    return FMRES_IGNORED

    new CsTeams:team = GetSentryTeam ( sentry )

    if ( team != cs_get_user_team ( id ) )
    return FMRES_IGNORED

    new level = GetSentryLevel ( sentry )
                                                                        
    static tempStatusBuffer[132], tempStatusBuffer3[132], tempStatusBuffer4[132]  
new szShowMessage[256]
    new OwnName[33]
	

get_user_name(GetSentryUpgrader(sentry, OWNER), OwnName, 32);
ColorTeam = team - 1;

if (team == 1)
{
    set_dhudmessage(255, 25, 30, -1.0, 0.35, 2, 0.0, 0.2, 0.0, 0.70);
    
    new messageBuffer[128];
    format(messageBuffer, sizeof(messageBuffer), "Р’Р»Р°РґРµР»РµС†: %s^nР—РґРѕСЂРѕРІСЊРµ: %d^nРЈР±РёР№СЃС‚РІ: %d^nРЈСЂРѕРІРµРЅСЊ: %d", OwnName, floatround(health), g_iKillSentry[sentry], level + 1);
    show_dhudmessage(id, messageBuffer);

    if (level + 1 == 5)
        show_dhudmessage(id, tempStatusBuffer3);

    if (level + 1 == 4)
        show_dhudmessage(id, tempStatusBuffer4);
}
else if (team == 2)
{
    set_dhudmessage(15, 25, 255, -1.0, 0.35, 2, 0.0, 0.2, 0.0, 0.70);

    new messageBuffer[128];
    format(messageBuffer, sizeof(messageBuffer), "Р’Р»Р°РґРµР»РµС†: %s^nР—РґРѕСЂРѕРІСЊРµ: %d^nРЈР±РёР№СЃС‚РІ: %d^nРЈСЂРѕРІРµРЅСЊ: %d", OwnName, floatround(health), g_iKillSentry[sentry], level + 1);
    show_dhudmessage(id, messageBuffer);

    if (level + 1 == 5)
        show_dhudmessage(id, tempStatusBuffer3);

    if (level + 1 == 4)
        show_dhudmessage(id, tempStatusBuffer4);
}

    //formatex ( tempStatusBuffer2, charsmax ( tempStatusBuffer2 ), "^n^nРЈР±РёР№СЃС‚РІ: %d^nРЈСЂРѕРІРµРЅСЊ: %d", g_iKillSentry[sentry], level + 1)       
                                       
    if(level + 1 > 4)
    {       
    if(g_SentryMode[sentry] == 2)
        {
            formatex ( tempStatusBuffer3, charsmax ( tempStatusBuffer3 ), "^n^n^n^n%L",id ,"SG_HUD_MODE_2")

        }                                                                           
    if(g_SentryMode[sentry] == 3)                                                             
        {                                                                                 
            formatex ( tempStatusBuffer3, charsmax ( tempStatusBuffer3 ), "^n^n^n^n%L",id ,"SG_HUD_MODE_3")
        }
        else                                                                         
    if(g_SentryMode[sentry] == 4)                                                             
        {                                                                                 
            formatex ( tempStatusBuffer3, charsmax ( tempStatusBuffer3 ), "^n^n^n^n%L",id ,"SG_HUD_MODE_4")
				
        }
        else
        {
        }    
    }
    
    if(level +1 > 3)                              
    {
        if(g_SentryMode[sentry] == 1 )
        {
            formatex ( tempStatusBuffer4, charsmax ( tempStatusBuffer4 ), "^n^n^n^n%L",id ,"SG_HUD_MODE_1")
					
        }
        else
        if(g_SentryMode[sentry] == 5)                                                             
        {                                                                                  
            formatex ( tempStatusBuffer4, charsmax ( tempStatusBuffer4 ), "^n^n^n^n%L",id ,"SG_HUD_MODE_5")
        }
else		
         if(g_SentryMode[sentry] == 6)                                                             
        {                                                                                  
            formatex ( tempStatusBuffer4, charsmax ( tempStatusBuffer4 ), "^n^n^n^n%L",id ,"SG_HUD_MODE_6")
					
        }		
        else
			         if(g_SentryMode[sentry] == 7)                                                             
        {                                                                                  
            formatex ( tempStatusBuffer4, charsmax ( tempStatusBuffer4 ), "^n^n^n^n%L",id ,"SG_HUD_MODE_7")
					
        }
        
    }

    return FMRES_IGNORED                                                        
}
                                                                                    
public fw_TouchSentry ( sentry, player )
{                                                                                          
    SentryUpgrade ( player, sentry, 0);
    g_OffSpam[player] = 0;
                         
    remove_task(TASK_LEAVE_ID + player)
    set_task(TASK_CHECK_ACCU, "_player_untouch_sentry", player + TASK_LEAVE_ID);
}

public _player_untouch_sentry(pId)
{
    pId -= TASK_LEAVE_ID;
    if(!is_user_alive(pId))
    return;

    g_OffSpam[pId] = 1;
}


ammo_hud(id, sw)
{
	if(is_user_bot(id)||!is_user_alive(id)||!is_user_connected(id)) 
			return

	new s_sprite[33]
	new iSentryCount = GetSentryCount ( id )
	format(s_sprite, 32, "number_%d", sentries_num[id])
	  new team = cs_get_user_team(id)
	  switch (team)
	  {
	  case 1:
	if(sw)
	{
		message_begin( MSG_ONE, gMsgID, {0,1.0,0}, id )
		write_byte( 1 ) // status
		write_string( s_sprite ) // sprite name
		write_byte( 255 ) // red
		write_byte( 20 ) // green
		write_byte( 30 ) // blue
		message_end()
	}
	else 
	{
		message_begin( MSG_ONE, gMsgID, {0,0,0}, id )
		write_byte( 0 ) // status
		write_string( s_sprite ) // sprite name
		write_byte( 255 ) // red
		write_byte( 0 ) // green
		write_byte( 0 ) // blue
		message_end()
	}
	  case 2:
	  {
		  	if(sw)
	{
		message_begin( MSG_ONE, gMsgID, {0,0,0}, id )
		write_byte( 1 ) // status
		write_string( s_sprite ) // sprite name
		write_byte( 30 ) // red
		write_byte( 20 ) // green
		write_byte( 250 ) // blue
		message_end()
	}
	else 
	{
		message_begin( MSG_ONE, gMsgID, {0,0,0}, id )
		write_byte( 0 ) // status
		write_string( s_sprite ) // sprite name
		write_byte( 20 ) // red
		write_byte( 30 ) // green
		write_byte( 250 ) // blue
		message_end()
	}
	  }
	  }
	if(sentries_num[id] <= 0)
	{
		message_begin( MSG_ONE, gMsgID, {0,0,0}, id )
		write_byte( 0 ) // status
		write_string( s_sprite ) // sprite name
		write_byte( 250 ) // red
		write_byte( 250 ) // green
		write_byte( 250 ) // blue
		message_end()
	}    
}

stock ChatColor(const idUser, const input[], any:...)
{
    new count = 1, arrPlayers[32];
    new szMsgText[256];
    vformat(szMsgText, charsmax(szMsgText), input, 3);
    
    replace_all(szMsgText, charsmax(szMsgText), "!g", "^4");
    replace_all(szMsgText, charsmax(szMsgText), "!n", "^1");
    replace_all(szMsgText, charsmax(szMsgText), "!t", "^3");
    
    if (idUser) 
        arrPlayers[0] = idUser; 
    else 
        get_players(arrPlayers, count, "ch");
    {
        for (new i = 0; i < count; i++)
        {
            if (is_user_connected(arrPlayers[i]))
            {
                message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("SayText"), _, arrPlayers[i]);
                write_byte(arrPlayers[i]);
                write_string(szMsgText);
                message_end();
            }
        }
    }
}

bool:IsInSphere ( id )
{
    if ( !is_user_alive ( id ) )
    return false

    new ent = -1 
    while ( ( ent = engfunc ( EngFunc_FindEntityByString, ent, "classname", "campo_grenade_forze" ) ) > 0 )
    {
        new iOwner = pev ( ent, pev_owner )

        if ( cs_get_user_team ( id ) != cs_get_user_team ( iOwner ) )
        continue

        new Float:fOrigin[3]
        pev ( ent, pev_origin, fOrigin )
        new iPlayer = -1
        while ( ( iPlayer = engfunc ( EngFunc_FindEntityInSphere, iPlayer, fOrigin, 68.0 ) ) != 0 )
        {
            if ( iPlayer == id )
            return true
        }
    }
    return false
}
         
public ShootRockets(data[2]){
    new sentry = data[0]

    if ( !pev_valid ( sentry ) )
    return

    new side = data[1]
    
    new Float:rocketOrigin[3],Float:rocketAngles[3]
    
    entity_get_vector(sentry,EV_VEC_angles,rocketAngles)
    engfunc(EngFunc_MakeVectors,rocketAngles)
    
    new Float:vecForward[3],Float:vecRight[3],Float:vecUp[3]
    
    get_global_vector(GL_v_forward,vecForward)
    xs_vec_mul_scalar(vecForward,20.0,vecForward)
    
    get_global_vector(GL_v_right,vecRight)
    xs_vec_mul_scalar(vecRight,side ? 8.0 : -8.0,vecRight) // right or left rocket
    
    get_global_vector(GL_v_up,vecUp)
    xs_vec_mul_scalar(vecUp,30.0,vecUp)
    
    entity_get_vector(sentry,EV_VEC_origin,rocketOrigin)
    xs_vec_add(rocketOrigin,vecForward,rocketOrigin)
    xs_vec_add(rocketOrigin,vecRight,rocketOrigin)
    xs_vec_add(rocketOrigin,vecUp,rocketOrigin)
    
    // shot rocket
    CreateRocket(sentry,rocketOrigin,rocketAngles,GetSentryTarget(sentry,TARGET))
    
    data[1] = 1
    
    if(!side) // shot left rocket
    set_task(0.2,"ShootRockets",_,data,sizeof data)
}
                                                               
//
// Launch RPG rocket
//    sentry - sentry id                                
//    origin - rocket origin        
//    angles - sentry angles
//    traget - rocket target id           
//
CreateRocket(sentry,Float:origin[3],Float:angles[3],target){
    new rocket = create_entity("info_target")

    entity_set_string(rocket,EV_SZ_classname,"rpg_rocket")
    entity_set_edict(rocket, EV_ENT_aiment,0)
    entity_set_int(rocket,EV_INT_movetype,MOVETYPE_FLY)                                                
    entity_set_int(rocket,EV_INT_solid,SOLID_BBOX)
    
    entity_set_edict(rocket,EV_ENT_owner,sentry)               
    entity_set_edict(rocket,EV_ENT_euser4,GetSentryUpgrader(sentry,OWNER))
               new Float:targetOrigin[3]
    entity_get_vector(target,EV_VEC_origin,targetOrigin)
    angles[0] = -GetAngleOrigins(origin,targetOrigin)
	    entity_set_model(rocket,"models/cssb/sentry_v6/missile.mdl")
    entity_set_vector(rocket,EV_VEC_angles,angles)
     engfunc(EngFunc_MakeVectors,angles)      
            new OriginEnd[3]
            FVecIVec(targetOrigin,OriginEnd)
            //Р•С„С„РµРєС‚ Р»СѓС‡Р° РѕС‚ РїСѓС€РєРё РґРѕ С†РµР»Рё.
    entity_set_size(rocket,Float:{-2.0,-2.0,-2.0},Float:{2.0,2.0,2.0})
    entity_set_origin(rocket,origin)
    
    
    new Float:vecVelocity[3]
    get_global_vector(GL_v_forward,vecVelocity)
    xs_vec_mul_scalar(vecVelocity,1000.0,vecVelocity)
    entity_set_vector(rocket,EV_VEC_velocity,vecVelocity)
	emit_sound(rocket,CHAN_VOICE,"CSSB/sentry_gun/nuke_fly.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
                static Float:fGameTimea; fGameTimea = get_gametime ()  
									    if ( entity_get_float ( rocket, ABA1 ) <= fGameTimea )
{
entity_set_float ( rocket, ABA1, fGameTimea + 0.427 )	
{
	 emit_sound(rocket, CHAN_WEAPON , "CSSB/sentry_gun/rocketfire_1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
}
	}
}
                                                           
                                                           
public fw_RpgTouch(rocket,ent){
    new Float:origin[3],Float:angles[3],Float:vecPlaneNormal[3]
    entity_get_vector(rocket,EV_VEC_origin,origin)
    entity_get_vector(rocket,EV_VEC_angles,angles)
    
    engfunc(EngFunc_MakeVectors,angles)
    get_global_vector(GL_v_forward,angles)
    xs_vec_mul_scalar(angles,9999.0,angles)
    xs_vec_add(origin,angles,angles)
    engfunc(EngFunc_TraceLine,origin,angles,0,rocket,0)
    
    get_tr2(0,TR_vecEndPos,origin)
    
    get_tr2(0,TR_vecPlaneNormal,vecPlaneNormal)                                  
    
    xs_vec_mul_scalar(vecPlaneNormal,8.0,vecPlaneNormal)
    xs_vec_add(origin,vecPlaneNormal,origin)
    
    CreateRocketex(rocket)
    
    shit_radiusdamage(rocket,origin)       
    emit_sound(rocket,CHAN_VOICE,"CSSB/sentry_gun/rocket_explosion.wav",1.0,0.5,0,PITCH_NORM)
    remove_entity(rocket)
    
}                                    

// this very bad method
stock shit_radiusdamage(rocket,Float:origin_[3]) {
    new origin[3]
    FVecIVec(origin_, origin)
    
    new attacker = entity_get_edict(rocket,EV_ENT_euser4)
    
    if(!is_user_connected(attacker))        
    return
                                                                             
                                                                                                                
    new Float:playerOrigin[3], Float:distance, Float:flDmgToDo, Float:dmgbase = get_pcvar_float(g_Cvar_mode_rpg[1])
    for (new i = 1; i <= g_iMaxPlayers; i++) { 
        if (!is_user_alive(i) || get_user_godmode(i) || get_user_team(i) == get_user_team(attacker)) 
        continue

        entity_get_vector(i, EV_VEC_origin, playerOrigin)
        distance = vector_distance(playerOrigin, origin_)
        if (distance <= get_pcvar_num(g_Cvar_mode_rpg[0])) {
            flDmgToDo = dmgbase - (dmgbase * (distance / get_pcvar_num(g_Cvar_mode_rpg[0])))
            
            // zemletryasenie!!111
            Util_ScreenShake(i,0.5,16.0,16.0)
            rocket_damagetoplayer(rocket,origin_,i,flDmgToDo)
        }
    }
}
// ScreenShake
stock Util_ScreenShake(id, Float:duration, Float:frequency, Float:amplitude)
{
    static ScreenShake = 0;
    if( !ScreenShake )
    {
        ScreenShake = get_user_msgid("ScreenShake");
    }
    message_begin( id ? MSG_ONE_UNRELIABLE : MSG_BROADCAST, ScreenShake, _, id);
    write_short( FixedUnsigned16( amplitude, 1<<12 ) ); // shake amount
    write_short( FixedUnsigned16( duration, 1<<12 ) ); // shake lasts this long
    write_short( FixedUnsigned16( frequency, 1<<8 ) ); // shake noise frequency
    message_end();
}

// СѓСЂРѕРЅ РёРіСЂРѕРєСѓ
stock rocket_damagetoplayer(rocket, Float:sentryOrigin[3], target, Float:dmg) {
    new sentry = entity_get_edict(rocket,EV_ENT_owner)

    if ( !is_valid_ent ( sentry ) )
    return

    new sentryLevel = GetSentryLevel(sentry)
    
    new newHealth = get_user_health(target) - floatround(dmg)

    if (newHealth <= 0) {
        new targetFrags = get_user_frags(target) + 1
        new owner = GetSentryUpgrader(sentry, OWNER)      
                                      
        if(!is_user_connected(owner))
        return
        
        new ownerFrags = get_user_frags(owner) + 1
        set_user_frags(target, targetFrags) // otherwise frags are subtracted from victim for dying (!!)
        set_user_frags(owner, ownerFrags)
        
        new contributors[5]
        contributors[0] = owner
        contributors[1] = GetSentryUpgrader(sentry, UPGRADER_1)
        contributors[2] = GetSentryUpgrader(sentry, UPGRADER_2)
        contributors[3] = GetSentryUpgrader(sentry, UPGRADER_3)
        contributors[4] = GetSentryUpgrader(sentry, UPGRADER_4)
        
        for(new i ; i < sizeof contributors ; i++){
            if(!contributors[i])
            continue
            
            if(!is_user_connected(contributors[i]) || get_user_team(contributors[i]) != get_user_team(contributors[0])){
                switch(i){ // yao face
                case 1: SetSentryUpgrader(sentry,UPGRADER_1,0)
                case 2: SetSentryUpgrader(sentry,UPGRADER_2,0)
                case 3: SetSentryUpgrader(sentry,UPGRADER_3,0)
                case 4: SetSentryUpgrader(sentry,UPGRADER_4,0)    
                }
                
                continue
            }
            new level = GetSentryLevel ( sentry )
			if(level == SENTRY_LEVEL_1)
			{
            // izvini 4yvak, no menya nakrilo
            cs_set_user_money(contributors[i],
            clamp(
            cs_get_user_money(contributors[i]) + (i == 0 ? SENTRYLVL1 : get_pcvar_num(sg_rpg_shot_money)),
            0,
            get_pcvar_num(sentry_max_money)
            )                    
            )
			}
			if(level == SENTRY_LEVEL_2)
			{
            // izvini 4yvak, no menya nakrilo
            cs_set_user_money(contributors[i],
            clamp(
            cs_get_user_money(contributors[i]) + (i == 0 ? SENTRYLVL2 : get_pcvar_num(sg_rpg_shot_money)),
            0,
            get_pcvar_num(sentry_max_money)
            )                    
            )
			}
						if(level == SENTRY_LEVEL_3)
			{
            // izvini 4yvak, no menya nakrilo
            cs_set_user_money(contributors[i],
            clamp(
            cs_get_user_money(contributors[i]) + (i == 0 ? SENTRYLVL3 : get_pcvar_num(sg_rpg_shot_money)),
            0,
            get_pcvar_num(sentry_max_money)
            )                    
            )
			}
						if(level == SENTRY_LEVEL_4)
			{
            // izvini 4yvak, no menya nakrilo
            cs_set_user_money(contributors[i],
            clamp(
            cs_get_user_money(contributors[i]) + (i == 0 ? SENTRYLVL4 : get_pcvar_num(sg_rpg_shot_money)),
            0,
            get_pcvar_num(sentry_max_money)
            )                    
            )
			}
						if(level == SENTRY_LEVEL_5)
			{
            // izvini 4yvak, no menya nakrilo
            cs_set_user_money(contributors[i],
            clamp(
            cs_get_user_money(contributors[i]) + (i == 0 ? SENTRYLVL5 : get_pcvar_num(sg_rpg_shot_money) ),
            0,
            get_pcvar_num(sentry_max_money)
            )                    
            )
			}
        }

        // ny ebatb kakoy frag
        message_begin(MSG_ALL, g_msgDeathMsg, {0, 0, 0} ,0)
        write_byte(owner)
        write_byte(target)
        write_byte(0)
        write_string("sentry gun")
        message_end()

        scoreinfo_update(owner, ownerFrags, cs_get_user_deaths(owner), int:cs_get_user_team(owner))
        set_msg_block(g_msgDeathMsg, BLOCK_ONCE)
    
		new szShowMessage[256]
        				if (_Uf_ID_45() & get_user_flags(owner))
		{
									if (get_user_health(owner) + hp_for_kill >= max_hp_vip )
			{
			}
			else
			{
						if (get_user_health(owner) < max_hp_vip )
			{
			set_user_health(owner,get_user_health(owner) + hp_for_kill)
			}
										if (dhudmessage >0)
							{
			_Uf_ID_46(owner, szShowMessage, 0, 255, 0);	
			show_dhudmessage ( owner, "+%d", hp_for_kill )
							}
			if (blue_fade > 0)
{
	_Uf_ID_34(owner, 1<<10, 1<<10, 0x0000, 0, 0, 250, 75);
}
			}
		}
			else
			{
							if (get_user_health(owner) + hp_for_kill >= max_hp )
			{
			}
			else
			{
			if (get_user_health(owner) < max_hp )
			{
							set_user_health(owner,get_user_health(owner) + hp_for_kill)
			}
         
							if (dhudmessage >0)
							{
			_Uf_ID_46(owner, szShowMessage, 0, 255, 0);	
			show_dhudmessage ( owner, "+%d", hp_for_kill )
							}
			if (blue_fade > 0)
{
	_Uf_ID_34(owner, 1<<10, 1<<10, 0x0000, 0, 0, 250, 75);
}
			}
			}
	}
    set_user_health(target, newHealth)

    message_begin(MSG_ONE_UNRELIABLE, g_msgDamage, {0,0,0}, target)
    write_byte(get_pcvar_num(g_DMG[3]))
    write_byte(get_pcvar_num(g_DMG[3]))
    write_long(DMG_BLAST)
    write_coord(floatround(sentryOrigin[0]))
    write_coord(floatround(sentryOrigin[1]))
    write_coord(floatround(sentryOrigin[2]))
    message_end()
}

public ShootFreezing(data[])
{
    new sentry = data[0]
    if (pev_valid ( sentry ) )
    {
            //РџРѕР»СѓС‡Р°РµРј РЅР° РєРѕРіРѕ РЅР°РІРµРґРµРЅР° РїСѓС€РєР°
            new target = GetSentryTarget(sentry,TARGET)
                                        
            new Float:freezOrigin[3] , Float:freezAngles[3], Float:freezOrigin2[3];
            //РЎС‡РёС‚Р°РµРј С‚РѕС‡РєСѓ РѕС‚РєСѓРґР° СЂРёСЃРѕРІР°С‚СЊ Р»СѓС‡
            entity_get_vector(sentry,EV_VEC_angles,freezAngles)
            engfunc(EngFunc_MakeVectors,freezAngles)
            
            new Float:vecForward[3],Float:vecRight[3],Float:vecUp[3], Float:vecLeft[3]
                                              
            get_global_vector(GL_v_forward,vecForward)
            xs_vec_mul_scalar(vecForward,20.0,vecForward)
            
            get_global_vector(GL_v_right,vecRight)
            get_global_vector(GL_v_right,vecLeft) 			
			
			xs_vec_mul_scalar(vecLeft,-18.0,vecLeft) // right or left rocket
            xs_vec_mul_scalar(vecRight,18.0,vecRight) // right or left rocket
            
            get_global_vector(GL_v_up,vecUp)
            xs_vec_mul_scalar(vecUp,30.0,vecUp)
            entity_get_vector(sentry,EV_VEC_origin,freezOrigin2)
            entity_get_vector(sentry,EV_VEC_origin,freezOrigin)
            xs_vec_add(freezOrigin,vecForward,freezOrigin)    
            xs_vec_add(freezOrigin,vecRight,freezOrigin)
            xs_vec_add(freezOrigin,vecUp,freezOrigin)
			xs_vec_add(freezOrigin2,vecForward,freezOrigin2)    
            xs_vec_add(freezOrigin2,vecLeft,freezOrigin2)
            xs_vec_add(freezOrigin2,vecUp,freezOrigin2)
        
            //set_user_health( target, get_user_health( target ) - 1 )
            new Float:targetOrigin[3];
            entity_get_vector(target,EV_VEC_origin,targetOrigin)
           
            new OriginEnd[3],OriginStr[3],OriginStr2[3];
            FVecIVec(freezOrigin,OriginStr)
			FVecIVec(freezOrigin2,OriginStr2)
            FVecIVec(targetOrigin,OriginEnd)
            //Р•С„С„РµРєС‚ Р»СѓС‡Р° РѕС‚ РїСѓС€РєРё РґРѕ С†РµР»Рё.
            message_begin(MSG_BROADCAST, SVC_TEMPENTITY) //  MSG_PAS MSG_BROADCAST
            write_byte(TE_BEAMPOINTS)
            write_coord(OriginStr[0])
            write_coord(OriginStr[1])  
            write_coord(OriginStr[2])
            write_coord(OriginEnd[0])
            write_coord(OriginEnd[1])
            write_coord(OriginEnd[2] )
			new iTeam = GetSentryTeam ( sentry )
			if (iTeam == 1) 
			{
				write_short(g_red)
			}				
            else if (iTeam == 2) 
		   {
			   write_short(g_blue)
		   }
			
	write_byte(0);
	write_byte(2);
	write_byte(2);
	write_byte(35)
	write_byte(0)
	write_byte(225)
	write_byte(225)
	write_byte(225)
	write_byte(225)
	write_byte(225)
	message_end()
	     message_begin(MSG_BROADCAST, SVC_TEMPENTITY) //  MSG_PAS MSG_BROADCAST
            write_byte(TE_BEAMPOINTS)
            write_coord(OriginStr2[0])
            write_coord(OriginStr2[1])  
            write_coord(OriginStr2[2])
            write_coord(OriginEnd[0])
            write_coord(OriginEnd[1])
            write_coord(OriginEnd[2] )
			if (iTeam == 1) 
			{
				write_short(g_red)
			}				
            else if (iTeam == 2) 
		   {
			   write_short(g_blue)
		   }
			
	write_byte(0);
	write_byte(2);
	write_byte(2);
	write_byte(35)
	write_byte(0)
	write_byte(225)
	write_byte(225)
	write_byte(225)
	write_byte(225)
	write_byte(225)
	message_end()
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(TE_SPARKS)
	write_coord(OriginEnd[0])
	write_coord(OriginEnd[1])
	write_coord(OriginEnd[2])
	message_end()			
    }
}

public ShootFreezingTesla(data[])
{
    new sentry = data[0]
    if (pev_valid ( sentry ) )
    {   
new Float:dmg
            //РџРѕР»СѓС‡Р°РµРј РЅР° РєРѕРіРѕ РЅР°РІРµРґРµРЅР° РїСѓС€РєР°
            new target = GetSentryTarget(sentry,TARGET)
            new Float:freezOrigin[3] , Float:freezAngles[3]
            //РЎС‡РёС‚Р°РµРј С‚РѕС‡РєСѓ РѕС‚РєСѓРґР° СЂРёСЃРѕРІР°С‚СЊ Р»СѓС‡
            entity_get_vector(sentry,EV_VEC_angles,freezAngles)
            engfunc(EngFunc_MakeVectors,freezAngles)
            
            new Float:vecForward[3],Float:vecRight[3],Float:vecUp[3]
                                              
            get_global_vector(GL_v_forward,vecForward)
            xs_vec_mul_scalar(vecForward,20.0,vecForward)
            
            get_global_vector(GL_v_right,vecRight)                         
            //xs_vec_mul_scalar(vecRight,side ? 8.0 : -8.0,vecRight) // right or left rocket
            
            get_global_vector(GL_v_up,vecUp)
            xs_vec_mul_scalar(vecUp,30.0,vecUp)
                                                
            entity_get_vector(sentry,EV_VEC_origin,freezOrigin)
            xs_vec_add(freezOrigin,vecForward,freezOrigin)    
            xs_vec_add(freezOrigin,vecRight,freezOrigin)
            xs_vec_add(freezOrigin,vecUp,freezOrigin)
        
            //set_user_health( target, get_user_health( target ) - 1 )
			//if (get_gametime() > entity_get_float(ent, 17))
			//{
	/*			   new newHealth = get_user_health(target) - 75.0
				   
if (/*level == SENTRY_LEVEL_1 && *///newHealth <= 0) //|| level == SENTRY_LEVEL_2 && newHealth1 <= 0 || level == SENTRY_LEVEL_3 && newHealth2 <= 0 || level == SENTRY_LEVEL_4 && newHealth3 <= 0 || level == SENTRY_LEVEL_5 && newHealth4 <= 0 ) {
/*	{
		new targetFrags = get_user_frags(target) + 1
        new owner = GetSentryUpgrader(sentry, OWNER)
        
        if(!is_user_connected(owner))
        return
        
        new ownerFrags = get_user_frags(owner) + 1
        set_user_frags(target, targetFrags) // otherwise frags are subtracted from victim for dying (!!)
	}
	*/
            new Float:targetOrigin[3]
            entity_get_vector(target,EV_VEC_origin,targetOrigin)                          
            new OriginEnd[3],OriginStr[3]
            FVecIVec(freezOrigin,OriginStr)
            FVecIVec(targetOrigin,OriginEnd) 	
            message_begin(MSG_BROADCAST, SVC_TEMPENTITY) //  MSG_PAS MSG_BROADCAST
            write_byte(TE_BEAMPOINTS)
            write_coord(OriginStr[0])
            write_coord(OriginStr[1])  
            write_coord(OriginStr[2] -6)
            write_coord(OriginEnd[0])
            write_coord(OriginEnd[1])
            write_coord(OriginEnd[2]) 
            write_short(g_Tessla);         //РРЅРґРµРєСЃ СЃРїСЂР°Р№С‚Р°
            write_byte(0);                 //РЎС‚Р°СЂС‚РѕРІС‹Р№ РєР°РґСЂ
            write_byte(0);                 //РЎРєРѕСЂРѕСЃС‚СЊ Р°РЅРёРјР°С†РёРё
            write_byte(4);            //Р’СЂРµРјСЏ СЃСѓС‰РµСЃС‚РІРѕРІР°РЅРёСЏ
            write_byte(150);     //РўРѕР»С‰РёРЅР° Р»СѓС‡Р°
            write_byte(50);     //РСЃРєР°Р¶РµРЅРёРµ
				new rand = random_num(1,5);
	switch (rand)
{
		case 1:
	{
           write_byte(random_num(55,255))            //Р¦РІРµС‚ РєСЂР°СЃРЅС‹Р№      
           write_byte(random_num(55,255))            //Р¦РІРµС‚ Р·РµР»РµРЅС‹Р№
           write_byte(50)            //Р¦РІРµС‚ СЃРёРЅРёР№ 
	}
				case 2:
		{
            write_byte(random_num(255,225))            //Р¦РІРµС‚ РєСЂР°СЃРЅС‹Р№      
           write_byte(random_num(30,50))            //Р¦РІРµС‚ Р·РµР»РµРЅС‹Р№
            write_byte(random_num(30,50))            //Р¦РІРµС‚ СЃРёРЅРёР№ 
		}
				case 3:
		{
           write_byte(random_num(30,55))            //Р¦РІРµС‚ РєСЂР°СЃРЅС‹Р№      
          write_byte(random_num(225,255))            //Р¦РІРµС‚ Р·РµР»РµРЅС‹Р№
          write_byte(random_num(30,45))            //Р¦РІРµС‚ СЃРёРЅРёР№ 
	}
						case 4:
		{
           write_byte(random_num(20,70))            //Р¦РІРµС‚ РєСЂР°СЃРЅС‹Р№      
          write_byte(random_num(20,70))            //Р¦РІРµС‚ Р·РµР»РµРЅС‹Р№
          write_byte(random_num(55,255))            //Р¦РІРµС‚ СЃРёРЅРёР№ 
	}
							case 5:
		{
           write_byte(random_num(20,40))            //Р¦РІРµС‚ РєСЂР°СЃРЅС‹Р№      
          write_byte(random_num(55,255))            //Р¦РІРµС‚ Р·РµР»РµРЅС‹Р№
          write_byte(random_num(55,255))            //Р¦РІРµС‚ СЃРёРЅРёР№ 
	}
}
            write_byte(1000)            //РЇСЂРєРѕСЃС‚СЊ
            write_byte(0)                //...
            message_end()                                                                             
    new Float:playerOrigin[3], Float:distance, Float:flDmgToDo, Float:dmgbase = RPG_DAMAGE
    for (new i = 1; i <= g_iMaxPlayers; i++)
		{ 
	if (get_user_team(target) != get_user_team(i) )
	   {
	   }
else
{	
        entity_get_vector(i, EV_VEC_origin, playerOrigin)
        distance = vector_distance(playerOrigin, targetOrigin) 
        if (distance <= get_pcvar_num(g_Cvar_mode_tesla[0])) {
			if( UTIL_IsVisible( i, target, targetOrigin, playerOrigin))
			{
			flDmgToDo = dmgbase - (dmgbase * (distance / get_pcvar_num(g_Cvar_mode_tesla[0])))
            new OriginEndi[3],OriginStr[3]
            FVecIVec(targetOrigin,OriginStr)
            FVecIVec(playerOrigin,OriginEnd) 	
            message_begin(MSG_BROADCAST, SVC_TEMPENTITY) //  MSG_PAS MSG_BROADCAST
            write_byte(TE_BEAMPOINTS)
            write_coord(OriginStr[0])
            write_coord(OriginStr[1])  
            write_coord(OriginStr[2] -6)
            write_coord(OriginEnd[0])
            write_coord(OriginEnd[1])
            write_coord(OriginEnd[2]) 
            write_short(g_Tessla);         //РРЅРґРµРєСЃ СЃРїСЂР°Р№С‚Р°
            write_byte(0);                 //РЎС‚Р°СЂС‚РѕРІС‹Р№ РєР°РґСЂ
            write_byte(0);                 //РЎРєРѕСЂРѕСЃС‚СЊ Р°РЅРёРјР°С†РёРё
            write_byte(4);            //Р’СЂРµРјСЏ СЃСѓС‰РµСЃС‚РІРѕРІР°РЅРёСЏ
            write_byte(150);     //РўРѕР»С‰РёРЅР° Р»СѓС‡Р°
            write_byte(50);     //РСЃРєР°Р¶РµРЅРёРµ
				new rand = random_num(1,5);
	switch (rand)
{
		case 1:
	{
           write_byte(random_num(55,255))            //Р¦РІРµС‚ РєСЂР°СЃРЅС‹Р№      
           write_byte(random_num(55,255))            //Р¦РІРµС‚ Р·РµР»РµРЅС‹Р№
           write_byte(50)            //Р¦РІРµС‚ СЃРёРЅРёР№ 
	}
				case 2:
		{
            write_byte(random_num(255,225))            //Р¦РІРµС‚ РєСЂР°СЃРЅС‹Р№      
           write_byte(random_num(30,50))            //Р¦РІРµС‚ Р·РµР»РµРЅС‹Р№
            write_byte(random_num(30,50))            //Р¦РІРµС‚ СЃРёРЅРёР№ 
		}
				case 3:
		{
           write_byte(random_num(30,55))            //Р¦РІРµС‚ РєСЂР°СЃРЅС‹Р№      
          write_byte(random_num(225,255))            //Р¦РІРµС‚ Р·РµР»РµРЅС‹Р№
          write_byte(random_num(30,45))            //Р¦РІРµС‚ СЃРёРЅРёР№ 
	}
					case 4:
		{
           write_byte(random_num(20,70))            //Р¦РІРµС‚ РєСЂР°СЃРЅС‹Р№      
          write_byte(random_num(20,70))            //Р¦РІРµС‚ Р·РµР»РµРЅС‹Р№
          write_byte(random_num(55,255))            //Р¦РІРµС‚ СЃРёРЅРёР№ 
	}
						case 5:
		{
           write_byte(random_num(20,40))            //Р¦РІРµС‚ РєСЂР°СЃРЅС‹Р№      
          write_byte(random_num(55,255))            //Р¦РІРµС‚ Р·РµР»РµРЅС‹Р№
          write_byte(random_num(55,255))            //Р¦РІРµС‚ СЃРёРЅРёР№ 
	}
}
            write_byte(1000)            //РЇСЂРєРѕСЃС‚СЊ
            write_byte(0)                //...
            message_end()   
    new newHealth = get_user_health(i) - get_pcvar_num(sb_tesla_damage) 
    if (newHealth <= 0) {
        new targetFrags = get_user_frags(i) + 1
        new owner = GetSentryUpgrader(sentry, OWNER)      
                                      
        if(!is_user_connected(owner))
        return
   
        new ownerFrags = get_user_frags(owner) + 1
        set_user_frags(i, targetFrags) // otherwise frags are subtracted from victim for dying (!!)
        set_user_frags(owner, ownerFrags)
cs_set_user_money(owner, cs_get_user_money(owner) + get_pcvar_num(sg_tesla_shot_money))	
        message_begin(MSG_ALL, g_msgDeathMsg, {0, 0, 0} ,0)
        write_byte(owner)
        write_byte(i) 
        write_byte(0)
        write_string("sentry gun")
        message_end()

        scoreinfo_update(owner, ownerFrags, cs_get_user_deaths(owner), int:cs_get_user_team(owner))
        set_msg_block(g_msgDeathMsg, BLOCK_ONCE)
	
		new szShowMessage[256]
        				if (_Uf_ID_45() & get_user_flags(owner))
		{
									if (get_user_health(owner) + hp_for_kill >= max_hp_vip )
			{
			}
			else
			{
						if (get_user_health(owner) < max_hp_vip )
			{
			set_user_health(owner,get_user_health(owner) + hp_for_kill)
			}
										if (dhudmessage >0)
							{
			_Uf_ID_46(owner, szShowMessage, 0, 255, 0);	
			show_dhudmessage ( owner, "+%d", hp_for_kill )
							}
			if (blue_fade > 0)
{
	_Uf_ID_34(owner, 1<<10, 1<<10, 0x0000, 0, 0, 250, 75);
}
			}
		}
			else
			{
							if (get_user_health(owner) + hp_for_kill >= max_hp )
			{
			}
			else
			{
			if (get_user_health(owner) < max_hp )
			{
							set_user_health(owner,get_user_health(owner) + hp_for_kill)
			}
         
							if (dhudmessage >0)
							{
			_Uf_ID_46(owner, szShowMessage, 0, 255, 0);	
			show_dhudmessage ( owner, "+%d", hp_for_kill )
							}
			if (blue_fade > 0)
{
	_Uf_ID_34(owner, 1<<10, 1<<10, 0x0000, 0, 0, 250, 75);
}
			}
			}
	}
	set_user_health(i, newHealth)
    }
		}
}
			emit_sound(sentry, CHAN_VOICE, "CSSB/sentry_gun/tesla_lightning_2.wav", VOL_NORM, ATTN_NORM, 0, PITCH_HIGH);

}
}
			}
const Float:SPEED__BALL      =   800.0; //РЎРєРѕСЂРѕСЃС‚СЊ С€Р°СЂР°
const Float:DAMAGE__BALL    =    500.0; //РЈСЂРѕРЅ С€Р°СЂР°
const Float:RELOAD__SKILL    =    5.0; //РџРµСЂРµР·Р°СЂСЏРґРєР° СЃРєРёР»Р»Р°
const Float:RADIUS__SKILL   =   200.0; //Р Р°РґРёСѓСЃ СѓСЂРѕРЅР°

enum _:Coord_e
{
    Float:x,
    Float:y,
    Float:z
};

enum _:Angle_e
{
    Float:pitch,
    Float:yaw,
    Float:roll
};
new uragnernew = 1
public ShootUrag(data[])
{
     new sentry = data[0]

    if ( !pev_valid ( sentry ) )
    return 0
        //РџРѕР»СѓС‡Р°РµРј РЅР° РєРѕРіРѕ РЅР°РІРµРґРµРЅР° РїСѓС€РєР°
        new target = GetSentryTarget(sentry,TARGET)

    new side = data[1]
    
            new Float:freezOrigin[3],Float:freezAngles[3]
            //РЎС‡РёС‚Р°РµРј С‚РѕС‡РєСѓ РѕС‚РєСѓРґР° СЂРёСЃРѕРІР°С‚СЊ Р»СѓС‡
            entity_get_vector(sentry,EV_VEC_angles,freezAngles)
            engfunc(EngFunc_MakeVectors,freezAngles)
            
            new Float:vecForward[3],Float:vecRight[3],Float:vecUp[3]
            
            get_global_vector(GL_v_forward,vecForward)
            xs_vec_mul_scalar(vecForward,20.0,vecForward)
                                                                                
            get_global_vector(GL_v_right,vecRight)
            //xs_vec_mul_scalar(vecRight,side ? 8.0 : -8.0,vecRight) // right or left rocket
            
            get_global_vector(GL_v_up,vecUp)
            xs_vec_mul_scalar(vecUp,30.0,vecUp)
            
            entity_get_vector(sentry,EV_VEC_origin,freezOrigin)
            xs_vec_add(freezOrigin,vecForward,freezOrigin)                      
            xs_vec_add(freezOrigin,vecRight,freezOrigin)
            xs_vec_add(freezOrigin,vecUp,freezOrigin)
        
            new Float:targetOrigin[3];
            entity_get_vector(target,EV_VEC_origin,targetOrigin)
            
            new OriginEnd[3],OriginStr[3];
            FVecIVec(freezOrigin,OriginStr)
            FVecIVec(targetOrigin,OriginEnd)
      new Float:vecPlaneNormal[3]      
		
static pEntity
      if (pEntity = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_sprite")))
	  {
	    set_pev ( pEntity , pev_classname , "urag" );
        set_pev ( pEntity, pev_origin, freezOrigin );
        set_pev ( pEntity, pev_owner, sentry );
        
        set_pev ( pEntity, pev_movetype, MOVETYPE_FLY );
        set_pev ( pEntity, pev_solid, SOLID_BBOX  );
            set_pev(pEntity, pev_animtime, 6.0)
  set_pev(pEntity, pev_framerate, 1.0)
  set_pev(pEntity, pev_sequence, 0)
  set_pev(pEntity, pev_scale, 0.3)
  set_pev(pEntity, pev_maxspeed, 1700.0)
  set_pev(pEntity, pev_speed, 1700.0)
         freezAngles[0] = -GetAngleOrigins(freezOrigin,targetOrigin)
		 pev(target,pev_origin,targetOrigin)
        engfunc ( EngFunc_VecToAngles, freezAngles);
        set_pev ( pEntity, pev_angles, freezAngles );
    entity_set_edict(pEntity,EV_ENT_owner,sentry)               
    entity_set_edict(pEntity,EV_ENT_euser4,GetSentryUpgrader(sentry,OWNER))
	    engfunc ( EngFunc_SetModel , pEntity, BALL__MODEL     );
				engfunc(EngFunc_SetSize, pEntity, Float:{-5.0, -5.0, -5.0},Float:{5.0, 5.0, 5.0} )
        engfunc ( EngFunc_SetOrigin, pEntity, freezOrigin );
        set_pev ( pEntity, pev_rendermode,  kRenderTransAdd )
        set_pev ( pEntity, pev_renderamt,   255.0 ) 
        set_pev ( pEntity , EV_ENT_euser4,GetSentryUpgrader(sentry,OWNER));
    entity_get_vector(pEntity,EV_VEC_origin,targetOrigin)
    entity_get_vector(pEntity,EV_VEC_angles,freezAngles)
    
    engfunc(EngFunc_MakeVectors,freezAngles)
    get_global_vector(GL_v_forward,freezAngles)
    xs_vec_mul_scalar(freezAngles,9999.0,freezAngles)
    xs_vec_add(targetOrigin,freezAngles,freezAngles)
    engfunc(EngFunc_TraceLine,targetOrigin,freezAngles,0,pEntity,0)    
            FVecIVec(targetOrigin,OriginEnd)
            //Р•С„С„РµРєС‚ Р»СѓС‡Р° РѕС‚ РїСѓС€РєРё РґРѕ С†РµР»Рё.
    entity_set_size(pEntity,Float:{-2.0,-2.0,-2.0},Float:{2.0,2.0,2.0})
    entity_set_origin(pEntity,freezOrigin)
    
    
    new Float:vecVelocity[3]
    get_global_vector(GL_v_forward,vecVelocity)
    xs_vec_mul_scalar(vecVelocity,1000.0,vecVelocity)
    entity_set_vector(pEntity,EV_VEC_velocity,vecVelocity)
                
    
    get_tr2(0,TR_vecEndPos,targetOrigin)
    
    get_tr2(0,TR_vecPlaneNormal,vecPlaneNormal)                                  
    
    xs_vec_mul_scalar(vecPlaneNormal,8.0,vecPlaneNormal)
    xs_vec_add(targetOrigin,vecPlaneNormal,targetOrigin)
    		
            //Р•С„С„РµРєС‚ Р»СѓС‡Р° РѕС‚ РїСѓС€РєРё РґРѕ С†РµР»Рё.
		
            //Р•С„С„РµРєС‚ Р»СѓС‡Р° РѕС‚ РїСѓС€РєРё РґРѕ С†РµР»Рё.
message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(TE_BEAMFOLLOW)
	write_short(pEntity)
	write_short(m_spritetexture)
	write_byte(10)
	write_byte(5)
				new rand = random_num(1,5);
	switch (rand)
{
		case 1:
	{
           write_byte(random_num(55,215))            //Р¦РІРµС‚ РєСЂР°СЃРЅС‹Р№      
           write_byte(random_num(55,215))            //Р¦РІРµС‚ Р·РµР»РµРЅС‹Р№
           write_byte(50)            //Р¦РІРµС‚ СЃРёРЅРёР№ 
	}
				case 2:
		{
            write_byte(random_num(255,225))            //Р¦РІРµС‚ РєСЂР°СЃРЅС‹Р№      
           write_byte(random_num(30,50))            //Р¦РІРµС‚ Р·РµР»РµРЅС‹Р№
            write_byte(random_num(30,50))            //Р¦РІРµС‚ СЃРёРЅРёР№ 
		}
				case 3:
		{
           write_byte(random_num(30,55))            //Р¦РІРµС‚ РєСЂР°СЃРЅС‹Р№      
          write_byte(random_num(125,215))            //Р¦РІРµС‚ Р·РµР»РµРЅС‹Р№
          write_byte(random_num(30,45))            //Р¦РІРµС‚ СЃРёРЅРёР№ 
	}
				case 4:
		{
            write_byte(172)            //Р¦РІРµС‚ РєСЂР°СЃРЅС‹Р№      
           write_byte(217)            //Р¦РІРµС‚ Р·РµР»РµРЅС‹Р№
            write_byte(32)            //Р¦РІРµС‚ СЃРёРЅРёР№ 
		}
				case 5:
		{
           write_byte(162)            //Р¦РІРµС‚ РєСЂР°СЃРЅС‹Р№      
          write_byte(25)            //Р¦РІРµС‚ Р·РµР»РµРЅС‹Р№
          write_byte(228)            //Р¦РІРµС‚ СЃРёРЅРёР№ 
	    }
}
	write_byte(255)
	message_end()      
emit_sound(pEntity,CHAN_VOICE,"CSSB/sentry_gun/fire_charge_1.wav",1.0,0.5,0,PITCH_NORM) 
}
	  }
public ShootMoroza(pEntity)
{
	static Float:fGameTimea; fGameTimea = get_gametime ()  
        new sentry = entity_get_edict(pEntity,EV_ENT_owner)
    if (pev_valid ( sentry ) )
    {       
        //РџРѕР»СѓС‡Р°РµРј РЅР° РєРѕРіРѕ РЅР°РІРµРґРµРЅР° РїСѓС€РєР°
        new target = GetSentryTarget(sentry,TARGET)
        
        
        if(!(pev(target, pev_flags) & FL_FROZEN))
        {
            entity_set_float(sentry,SENTRY_FREEZ_TIME,get_gametime() +  get_pcvar_float(g_Cvar_mode_led[0])) //Р—Р°РґРµСЂР¶РєР° РґРѕ СЃР»РµРґСѓС‰РµРіРѕ Р·Р°РјРѕСЂР°Р¶РёРІР°РЅРёСЏ.
            
            new Float:freezOrigin[3],Float:freezAngles[3]
            //РЎС‡РёС‚Р°РµРј С‚РѕС‡РєСѓ РѕС‚РєСѓРґР° СЂРёСЃРѕРІР°С‚СЊ Р»СѓС‡
            entity_get_vector(sentry,EV_VEC_angles,freezAngles)
            engfunc(EngFunc_MakeVectors,freezAngles)
            
            new Float:vecForward[3],Float:vecRight[3],Float:vecUp[3]
            
            get_global_vector(GL_v_forward,vecForward)
            xs_vec_mul_scalar(vecForward,20.0,vecForward)
                                                                                
            get_global_vector(GL_v_right,vecRight)
            //xs_vec_mul_scalar(vecRight,side ? 8.0 : -8.0,vecRight) // right or left rocket
            
            get_global_vector(GL_v_up,vecUp)
            xs_vec_mul_scalar(vecUp,30.0,vecUp)
            
            entity_get_vector(sentry,EV_VEC_origin,freezOrigin)
            xs_vec_add(freezOrigin,vecForward,freezOrigin)                      
            xs_vec_add(freezOrigin,vecRight,freezOrigin)
            xs_vec_add(freezOrigin,vecUp,freezOrigin)
        
            new Float:targetOrigin[3];
            entity_get_vector(target,EV_VEC_origin,targetOrigin)
            
            new OriginEnd[3],OriginStr[3];
            FVecIVec(freezOrigin,OriginStr)
            FVecIVec(targetOrigin,OriginEnd)     

    		
		            FVecIVec(targetOrigin,OriginEnd)
            //Р•С„С„РµРєС‚ Р»СѓС‡Р° РѕС‚ РїСѓС€РєРё РґРѕ С†РµР»Рё.
    
    
                                       

    


            //Р•С„С„РµРєС‚ Р»СѓС‡Р° РѕС‚ РїСѓС€РєРё РґРѕ С†РµР»Рё.
          
            //РџСЂРѕРІРµСЂСЏРµРј РїРѕР»РѕР¶РµРЅРёРµ РёРіСЂРѕРєР°.
			new Float:playerOrigin[3], Float:distance
			    for (new i = 1; i <= g_iMaxPlayers; i++) { 
	if (get_user_team(target) != get_user_team(i) )
	   {
	   }
else
{	

        entity_get_vector(i, EV_VEC_origin, playerOrigin)
        distance = vector_distance(playerOrigin, targetOrigin)
        if (distance <= get_pcvar_num(g_Cvar_mode_tesla[0])) {
            new bDucking = !!(entity_get_int(i, EV_INT_flags) & FL_DUCKING);
            targetOrigin[2]  -= bDucking ? 27.0 : 36.0; //РЎС‡РёС‚Р°РµРј РєРѕРѕСЂРґРёРЅР°С‚С‹ РІ РєРѕС‚РѕСЂС‹С… СѓСЃС‚Р°РЅР°РІР»РёРІР°С‚СЊ РјРѕРґРµР»СЊ.
                                       
            new pEnt = create_entity("info_target");
            if (is_valid_ent(pEnt))
            {    
                                                
                 entity_set_model(pEnt,"models/cssb/sentry_v5/ice_cube.mdl")
                                             
                entity_set_int( pEnt, DATA_CUBE_OWNER , i );
                entity_set_vector(pEnt, EV_VEC_origin, playerOrigin);
playerOrigin[2]  -= bDucking ? 27.0 : 36.0; //РЎС‡РёС‚Р°РµРј РєРѕРѕСЂРґРёРЅР°С‚С‹ РІ РєРѕС‚РѕСЂС‹С… СѓСЃС‚Р°РЅР°РІР»РёРІР°С‚СЊ РјРѕРґРµР»СЊ.    
                entity_set_int(pEnt, EV_INT_solid, SOLID_NOT);
				    if ( is_entity_on_ground ( i ) )
    {
        drop_to_floor(pEnt)
    }
 set_rendering(i,kRenderFxGlowShell,33,252,255,kRenderNormal,20)
                if (bDucking)
                    entity_set_size(pEnt, Float:{ -24.0, -24.0, 10.0 }, Float:{ 24.0, 24.0, 68.0 });
                else
                    entity_set_size(pEnt, Float:{ -24.0, -24.0, 0.0 }, Float:{ 24.0, 24.0, 78.0 });

                entity_set_float(pEnt, EV_FL_takedamage, DAMAGE_NO);
                entity_set_int(pEnt, EV_INT_skin, (cs_get_user_team(i) == CS_TEAM_CT) ? 1 : 0);
                entity_set_int(pEnt, EV_INT_body, bDucking);
                entity_set_float(pEnt,FREEZ_ENT_TIME,get_gametime() +  get_pcvar_float(g_Cvar_mode_led[1]))
                set_pev(i, pev_flags, pev(i, pev_flags) | FL_FROZEN)				
				set_task(4.0, "UnFreez", pEnt)
              set_task(4.0, "UnRendering", i)
            }		
        }
}
				}
    }
}
}
/*
			    static pEntity;
     if ( ( pEntity = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_sprite") ) ) )
	 {
	    set_pev ( pEntity , pev_classname , "urag" );
        set_pev ( pEntity, pev_origin, freezOrigin );
        set_pev ( pEntity, pev_owner, sentry );
        
        set_pev ( pEntity, pev_movetype, MOVETYPE_FLY );
        set_pev ( pEntity, pev_solid, SOLID_BBOX  );
          set_pev(pEntity, pev_animtime, 6.0)
  set_pev(pEntity, pev_framerate, 1.0)
  set_pev(pEntity, pev_sequence, 0)
  set_pev(pEntity, pev_scale, 0.3)
         freezAngles[0] = -GetAngleOrigins(freezOrigin,targetOrigin)
		 pev(target,pev_origin,targetOrigin)
        engfunc ( EngFunc_VecToAngles, freezAngles);
        set_pev ( pEntity, pev_angles, freezAngles );
        
        engfunc ( EngFunc_SetModel , pEntity, BALL__MODEL     );
		engfunc(EngFunc_SetSize, pEntity, Float:{-5.0, -5.0, -5.0},Float:{5.0, 5.0, 5.0} )
        engfunc ( EngFunc_SetOrigin, pEntity, freezOrigin );
        set_pev ( pEntity, pev_rendermode,  kRenderTransAdd )
        set_pev ( pEntity, pev_renderamt,   255.0 ) 
        set_pev ( pEntity , EV_ENT_euser4,GetSentryUpgrader(sentry,OWNER));
    entity_get_vector(pEntity,EV_VEC_origin,targetOrigin)
    entity_get_vector(pEntity,EV_VEC_angles,freezAngles)
    
    engfunc(EngFunc_MakeVectors,freezAngles)
    get_global_vector(GL_v_forward,freezAngles)
    xs_vec_mul_scalar(freezAngles,9999.0,freezAngles)
    xs_vec_add(targetOrigin,freezAngles,freezAngles)
    engfunc(EngFunc_TraceLine,targetOrigin,freezAngles,0,pEntity,0)
    
    get_tr2(0,TR_vecEndPos,targetOrigin)
    
    get_tr2(0,TR_vecPlaneNormal,vecPlaneNormal)                                  
    
    xs_vec_mul_scalar(vecPlaneNormal,8.0,vecPlaneNormal)
    xs_vec_add(targetOrigin,vecPlaneNormal,targetOrigin)
    		
		            FVecIVec(targetOrigin,OriginEnd)
            //Р•С„С„РµРєС‚ Р»СѓС‡Р° РѕС‚ РїСѓС€РєРё РґРѕ С†РµР»Рё.
    
    
    new Float:vecVelocity[3]
    get_global_vector(GL_v_forward,vecVelocity)
    xs_vec_mul_scalar(vecVelocity,1000.0,vecVelocity)
    set_pev ( pEntity,pev_velocity,vecVelocity)
    
    if(!side) // shot left rocket
    set_task(0.2,"ShootUrag",_,data,sizeof data)
	   emit_sound(pEntity,CHAN_VOICE,"CSSB/sentry_gun/fire_charge_1.wav",1.0,0.5,0,PITCH_NORM)
            //Р•С„С„РµРєС‚ Р»СѓС‡Р° РѕС‚ РїСѓС€РєРё РґРѕ С†РµР»Рё.
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(8);
	write_short(pEntity);
	write_short(sentry);
	write_short(m_spritetexture);
	write_byte(30);
	write_byte(100);
	write_byte(255);
	write_byte(60);
	write_byte(TE_BEAMPOINTS);
				new rand = random_num(1,5);
	switch (rand)
{
		case 1:
	{
           write_byte(random_num(55,255))            //Р¦РІРµС‚ РєСЂР°СЃРЅС‹Р№      
           write_byte(random_num(55,255))            //Р¦РІРµС‚ Р·РµР»РµРЅС‹Р№
           write_byte(50)            //Р¦РІРµС‚ СЃРёРЅРёР№ 
	}
				case 2:
		{
            write_byte(random_num(255,225))            //Р¦РІРµС‚ РєСЂР°СЃРЅС‹Р№      
           write_byte(random_num(30,50))            //Р¦РІРµС‚ Р·РµР»РµРЅС‹Р№
            write_byte(random_num(30,50))            //Р¦РІРµС‚ СЃРёРЅРёР№ 
		}
				case 3:
		{
           write_byte(random_num(30,55))            //Р¦РІРµС‚ РєСЂР°СЃРЅС‹Р№      
          write_byte(random_num(225,255))            //Р¦РІРµС‚ Р·РµР»РµРЅС‹Р№
          write_byte(random_num(30,45))            //Р¦РІРµС‚ СЃРёРЅРёР№ 
	}
				case 4:
		{
            write_byte(172)            //Р¦РІРµС‚ РєСЂР°СЃРЅС‹Р№      
           write_byte(227)            //Р¦РІРµС‚ Р·РµР»РµРЅС‹Р№
            write_byte(32)            //Р¦РІРµС‚ СЃРёРЅРёР№ 
		}
				case 5:
		{
           write_byte(162)            //Р¦РІРµС‚ РєСЂР°СЃРЅС‹Р№      
          write_byte(25)            //Р¦РІРµС‚ Р·РµР»РµРЅС‹Р№
          write_byte(228)            //Р¦РІРµС‚ СЃРёРЅРёР№ 
	    }
}
            write_byte(255);            //РЇСЂРєРѕСЃС‚СЊ
            write_byte(0);                //...
            message_end();           
	 }
	 */
                                                               
//
// Launch RPG rocket
//    sentry - sentry id                                
//    origin - rocket origin        
//    angles - sentry angles
//    traget - rocket target id           
// 
public fw_UragTouch(pEntity,ent){
    new Float:origin[3],Float:angles[3],Float:vecPlaneNormal[3]
    entity_get_vector(pEntity,EV_VEC_origin,origin)
    entity_get_vector(pEntity,EV_VEC_angles,angles)
    
    engfunc(EngFunc_MakeVectors,angles)
    get_global_vector(GL_v_forward,angles)
    xs_vec_mul_scalar(angles,9999.0,angles)
    xs_vec_add(origin,angles,angles)
    engfunc(EngFunc_TraceLine,origin,angles,0,pEntity,0)
    
    get_tr2(0,TR_vecEndPos,origin)
    
    get_tr2(0,TR_vecPlaneNormal,vecPlaneNormal)                                  
    
    xs_vec_mul_scalar(vecPlaneNormal,8.0,vecPlaneNormal)
    xs_vec_add(origin,vecPlaneNormal,origin)
    
    
	Create_BeamCylinder(pEntity)
    
    urag_radiusdamage(pEntity,origin)
	uragnernew = 1
    remove_entity(pEntity)
    
}    
/*
            Urag_damagetoplayer(pEntity,origin_,i,flDmgToDo)
			new g_iTimer[33]
			g_iTimer[i] = 10
				new health = pev( i, pev_health ) - urag_damage_sec
				    if ( --g_iTimer[i] > 0 )
    {
	set_user_health (i, get_user_health (i) - urag_damage_sec);
	if( health < 1 ) dllfunc( DLLFunc_ClientKill, i )
        }
	*/ 
stock Create_BeamCylinder( iCurrent)
{
    new Float:vOrigin[3] 
    pev(iCurrent,pev_origin,vOrigin) 

    


	    engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vOrigin, 0)
    write_byte(TE_BEAMCYLINDER) // TE id
    engfunc(EngFunc_WriteCoord, vOrigin[0]) // x
    engfunc(EngFunc_WriteCoord, vOrigin[1]) // y
    engfunc(EngFunc_WriteCoord, vOrigin[2] + 1.0) // z
    engfunc(EngFunc_WriteCoord, vOrigin[0] + 100.0) // x axis
    engfunc(EngFunc_WriteCoord, vOrigin[1] + 100.0) // y axis
    engfunc(EngFunc_WriteCoord, vOrigin[2] + 85.0) // z axis
    write_short(g_Urag) // sprite
    write_byte(0) // startframe
    write_byte(0) // framerate
    write_byte(10) // life (4) 
    write_byte(15) // width (20)
    write_byte(255) // noise
    write_byte(255) // red
    write_byte(255) // green
    write_byte(225) // blue
    write_byte(255) // brightness
    write_byte(9) // speed
    message_end()
}

stock Create_BeamCylinder1( iCurrent)
{
    new Float:vOrigin[3] 
    pev(iCurrent,pev_origin,vOrigin) 

    



	    engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vOrigin, 0)
    write_byte(TE_BEAMCYLINDER) // TE id
    engfunc(EngFunc_WriteCoord, vOrigin[0]) // x
    engfunc(EngFunc_WriteCoord, vOrigin[1]) // y
    engfunc(EngFunc_WriteCoord, vOrigin[2] + 1.0) // z
    engfunc(EngFunc_WriteCoord, vOrigin[0] + 120.0) // x axis
    engfunc(EngFunc_WriteCoord, vOrigin[1] + 120.0) // y axis
    engfunc(EngFunc_WriteCoord, vOrigin[2] + 85.0) // z axis
    write_short(g_Moroz) // sprite
    write_byte(0) // startframe
    write_byte(0) // framerate
    write_byte(10) // life (4)
    write_byte(15) // width (20)
    write_byte(255) // noise
    write_byte(255) // red
    write_byte(255) // green
    write_byte(225) // blue
    write_byte(255) // brightness
    write_byte(9) // speed
    message_end()
}
new SVC_SCREENSHAKE, SVC_SCREENFADE, WTF_DAMAGE
// this very bad method
new g_iTimer[33]
public  urag_radiusdamage(pEntity,Float:origin_[3]) {
    new origin[3]
    FVecIVec(origin_, origin)
    
    new attacker = entity_get_edict(pEntity,EV_ENT_euser4)
    
    if(!is_user_connected(attacker))        
    return
                                                                             
                                                                                                                
    new Float:playerOrigin[3], Float:distance, Float:fldmgsec, Float:flDmgToDo, Float:dmgbase = get_pcvar_float(g_Cvar_mode_urag[1])
    for (new i = 1; i <= g_iMaxPlayers; i++) { 
        if (!is_user_alive(i) || get_user_godmode(i) || get_user_team(i) == get_user_team(attacker)) 
        continue

        entity_get_vector(i, EV_VEC_origin, playerOrigin)
        distance = vector_distance(playerOrigin, origin_)
   if (distance <= urag_radius) {
            flDmgToDo = dmgbase - (dmgbase * (distance / urag_radius))
            Urag_damagetoplayer(pEntity,origin_,i,flDmgToDo)  
			g_iTimer[i] = 60
set_task ( 1.0, "urag_damagesec", i, .flags = "b" )	
    }
}
}
// ScreenShake
public urag_damagesec(i)
{	
    if ( i > g_iMaxPlayers )
        i -= TASK_GODMODE

    if ( !is_user_connected ( i ) || !is_user_alive ( i ) )
        return
	    set_dhudmessage ( 255, 255, 0, -1.0, 0.37, 0, 0.0, 1.0, 0.0, 0.0 )

    if ( --g_iTimer[i] > 0 )
    {
       set_task ( 1.0, "urag_damagesec", i+TASK_GODMODE )
    
new newHealth = get_user_health(i) - 1
 if (newHealth > 0) {
		if ( entity_get_float ( i, ABA4 ) <= get_gametime() )
{	
entity_set_float ( i, ABA4, get_gametime() + 0.80 )	
set_user_health(i, newHealth)
	emit_sound ( i, CHAN_VOICE, "player/bhit_helmet-1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
}
	}
	}
}

// ScreenShake

// СѓСЂРѕРЅ РёРіСЂРѕРєСѓ
stock Urag_damagetoplayer(pEntity, Float:sentryOrigin[3], target, Float:dmg) {
    new sentry = entity_get_edict(pEntity,EV_ENT_owner)

    if ( !is_valid_ent ( sentry ) )
    return

    new sentryLevel = GetSentryLevel(sentry)
    
    new newHealth = get_user_health(target) - floatround(dmg)

    if (newHealth <= 0) {
        new targetFrags = get_user_frags(target) + 1
        new owner = GetSentryUpgrader(sentry, OWNER)      
                                      
        if(!is_user_connected(owner))
        return
        
        new ownerFrags = get_user_frags(owner) + 1
        set_user_frags(target, targetFrags) // otherwise frags are subtracted from victim for dying (!!)
        set_user_frags(owner, ownerFrags)
        
        new contributors[5]
        contributors[0] = owner
        contributors[1] = GetSentryUpgrader(sentry, UPGRADER_1)
        contributors[2] = GetSentryUpgrader(sentry, UPGRADER_2)
        contributors[3] = GetSentryUpgrader(sentry, UPGRADER_3)
        contributors[4] = GetSentryUpgrader(sentry, UPGRADER_4)
        
        for(new i ; i < sizeof contributors ; i++){
            if(!contributors[i])
            continue
            
            if(!is_user_connected(contributors[i]) || get_user_team(contributors[i]) != get_user_team(contributors[0])){
                switch(i){ // yao face
                case 1: SetSentryUpgrader(sentry,UPGRADER_1,0)
                case 2: SetSentryUpgrader(sentry,UPGRADER_2,0)
                case 3: SetSentryUpgrader(sentry,UPGRADER_3,0)
                case 4: SetSentryUpgrader(sentry,UPGRADER_4,0)    
                }
                
                continue
            }
            new level = GetSentryLevel ( sentry )
			if(level == SENTRY_LEVEL_1)
			{
            // izvini 4yvak, no menya nakrilo
            cs_set_user_money(contributors[i],
            clamp(
            cs_get_user_money(contributors[i]) + (i == 0 ? SENTRYLVL1 : get_pcvar_num(sg_hurricane_shot_money)),
            0,
            get_pcvar_num(sentry_max_money)
            )                    
            )
			}
			if(level == SENTRY_LEVEL_2)
			{
            // izvini 4yvak, no menya nakrilo
            cs_set_user_money(contributors[i],
            clamp(
            cs_get_user_money(contributors[i]) + (i == 0 ? SENTRYLVL2 : get_pcvar_num(sg_hurricane_shot_money)),
            0,
            get_pcvar_num(sentry_max_money)
            )                    
            )
			}
						if(level == SENTRY_LEVEL_3)
			{
            // izvini 4yvak, no menya nakrilo
            cs_set_user_money(contributors[i],
            clamp(
            cs_get_user_money(contributors[i]) + (i == 0 ? SENTRYLVL3 : get_pcvar_num(sg_hurricane_shot_money)),
            0,
            get_pcvar_num(sentry_max_money)
            )                    
            )
			}
						if(level == SENTRY_LEVEL_4)
			{
            // izvini 4yvak, no menya nakrilo
            cs_set_user_money(contributors[i],
            clamp(
            cs_get_user_money(contributors[i]) + (i == 0 ? SENTRYLVL4 : get_pcvar_num(sg_hurricane_shot_money)),
            0,
            get_pcvar_num(sentry_max_money)
            )                    
            )
			}
						if(level == SENTRY_LEVEL_5)
			{
            // izvini 4yvak, no menya nakrilo
            cs_set_user_money(contributors[i],
            clamp(
            cs_get_user_money(contributors[i]) + (i == 0 ? SENTRYLVL5 : get_pcvar_num(sg_hurricane_shot_money)),
            0,
            get_pcvar_num(sentry_max_money)
            )                    
            )
			}
        }

        // ny ebatb kakoy frag
        message_begin(MSG_ALL, g_msgDeathMsg, {0, 0, 0} ,0)
        write_byte(owner)
        write_byte(target)
        write_byte(0)
        write_string("sentry gun")
        message_end()

        scoreinfo_update(owner, ownerFrags, cs_get_user_deaths(owner), int:cs_get_user_team(owner))
        set_msg_block(g_msgDeathMsg, BLOCK_ONCE)
    
new szShowMessage[256]
        				if (_Uf_ID_45() & get_user_flags(owner))
		{
									if (get_user_health(owner) + hp_for_kill >= max_hp_vip )
			{
			}
			else
			{
						if (get_user_health(owner) < max_hp_vip )
			{
			set_user_health(owner,get_user_health(owner) + hp_for_kill)
			}
										if (dhudmessage >0)
							{
			_Uf_ID_46(owner, szShowMessage, 0, 255, 0);	
			show_dhudmessage ( owner, "+%d", hp_for_kill )
							}
			if (blue_fade > 0)
{
	_Uf_ID_34(owner, 1<<10, 1<<10, 0x0000, 0, 0, 250, 75);
}
			}
		}
			else
			{
							if (get_user_health(owner) + hp_for_kill >= max_hp )
			{
			}
			else
			{
			if (get_user_health(owner) < max_hp )
			{
							set_user_health(owner,get_user_health(owner) + hp_for_kill)
			}
         
							if (dhudmessage >0)
							{
			_Uf_ID_46(owner, szShowMessage, 0, 255, 0);	
			show_dhudmessage ( owner, "+%d", hp_for_kill )
							}
			if (blue_fade > 0)
{
	_Uf_ID_34(owner, 1<<10, 1<<10, 0x0000, 0, 0, 250, 75);
}
			}
			}
	}
    set_user_health(target, newHealth)

    message_begin(MSG_ONE_UNRELIABLE, g_msgDamage, {0,0,0}, target)
    write_byte(g_DMG[3])
    write_byte(g_DMG[3])
    write_long(DMG_BLAST)
    write_coord(floatround(sentryOrigin[0]))
    write_coord(floatround(sentryOrigin[1]))
    write_coord(floatround(sentryOrigin[2]))
    message_end()
}
/*
public ShootFreezing_cub(data[])
{
    new sentry = data[0]
    if (pev_valid ( sentry ) )
    {       
        //РџРѕР»СѓС‡Р°РµРј РЅР° РєРѕРіРѕ РЅР°РІРµРґРµРЅР° РїСѓС€РєР°
        new target = GetSentryTarget(sentry,TARGET)
        
        
        if(!(pev(target, pev_flags) & FL_FROZEN))
        {
            entity_set_float(sentry,SENTRY_FREEZ_TIME,get_gametime() +  get_pcvar_float(g_Cvar_mode_led[0])) //Р—Р°РґРµСЂР¶РєР° РґРѕ СЃР»РµРґСѓС‰РµРіРѕ Р·Р°РјРѕСЂР°Р¶РёРІР°РЅРёСЏ.
            
            new Float:freezOrigin[3],Float:freezAngles[3]
            //РЎС‡РёС‚Р°РµРј С‚РѕС‡РєСѓ РѕС‚РєСѓРґР° СЂРёСЃРѕРІР°С‚СЊ Р»СѓС‡
            entity_get_vector(sentry,EV_VEC_angles,freezAngles)
            engfunc(EngFunc_MakeVectors,freezAngles)
            
            new Float:vecForward[3],Float:vecRight[3],Float:vecUp[3]
            
            get_global_vector(GL_v_forward,vecForward)
            xs_vec_mul_scalar(vecForward,20.0,vecForward)
                                                                                
            get_global_vector(GL_v_right,vecRight)
            //xs_vec_mul_scalar(vecRight,side ? 8.0 : -8.0,vecRight) // right or left rocket
            
            get_global_vector(GL_v_up,vecUp)
            xs_vec_mul_scalar(vecUp,30.0,vecUp)
            
            entity_get_vector(sentry,EV_VEC_origin,freezOrigin)
            xs_vec_add(freezOrigin,vecForward,freezOrigin)                      
            xs_vec_add(freezOrigin,vecRight,freezOrigin)
            xs_vec_add(freezOrigin,vecUp,freezOrigin)
        
            new Float:targetOrigin[3];
            entity_get_vector(target,EV_VEC_origin,targetOrigin)
            
            new OriginEnd[3],OriginStr[3];
            FVecIVec(freezOrigin,OriginStr)
            FVecIVec(targetOrigin,OriginEnd)
      new Float:vecPlaneNormal[3]      
			    static pEntity;
     if ( ( pEntity = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_sprite") ) ) )
	 {
	    set_pev ( pEntity , pev_classname , "moroz" );
        set_pev ( pEntity, pev_origin, freezOrigin );
        set_pev ( pEntity, pev_owner, sentry );
        
        set_pev ( pEntity, pev_movetype, MOVETYPE_FLY );
        set_pev ( pEntity, pev_solid, SOLID_BBOX  );
          set_pev(pEntity, pev_animtime, 2.0)
  set_pev(pEntity, pev_framerate, 1.0)
  set_pev(pEntity, pev_sequence, 0)
  set_pev(pEntity, pev_scale, 0.3)
         freezAngles[0] = -GetAngleOrigins(freezOrigin,targetOrigin)
		 pev(target,pev_origin,targetOrigin)
        engfunc ( EngFunc_VecToAngles, freezAngles);
        set_pev ( pEntity, pev_angles, freezAngles );
        
        engfunc ( EngFunc_SetModel , pEntity, MOROZ__MODEL     );
		engfunc(EngFunc_SetSize, pEntity, Float:{-5.0, -5.0, -5.0},Float:{5.0, 5.0, 5.0} )
        engfunc ( EngFunc_SetOrigin, pEntity, freezOrigin );
        set_pev ( pEntity, pev_rendermode,  kRenderTransAdd )
        set_pev ( pEntity, pev_renderamt,   255.0 ) 
        set_pev ( pEntity , EV_ENT_euser4,GetSentryUpgrader(sentry,OWNER));
    entity_get_vector(pEntity,EV_VEC_origin,targetOrigin)
    entity_get_vector(pEntity,EV_VEC_angles,freezAngles)
    
    engfunc(EngFunc_MakeVectors,freezAngles)
    get_global_vector(GL_v_forward,freezAngles)
    xs_vec_mul_scalar(freezAngles,9999.0,freezAngles)
    xs_vec_add(targetOrigin,freezAngles,freezAngles)
    engfunc(EngFunc_TraceLine,targetOrigin,freezAngles,0,pEntity,0)
    
    get_tr2(0,TR_vecEndPos,targetOrigin)
    
    get_tr2(0,TR_vecPlaneNormal,vecPlaneNormal)                                  
    
    xs_vec_mul_scalar(vecPlaneNormal,8.0,vecPlaneNormal)
    xs_vec_add(targetOrigin,vecPlaneNormal,targetOrigin)
    		
		            FVecIVec(targetOrigin,OriginEnd)
            //Р•С„С„РµРєС‚ Р»СѓС‡Р° РѕС‚ РїСѓС€РєРё РґРѕ С†РµР»Рё.
    
    
    new Float:vecVelocity[3]
    get_global_vector(GL_v_forward,vecVelocity)
    xs_vec_mul_scalar(vecVelocity,1000.0,vecVelocity)
    set_pev ( pEntity,pev_velocity,vecVelocity)
    message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(TE_BEAMFOLLOW)
	write_short(pEntity)
	write_short(m_spritetexture)
	write_byte(10)
	write_byte(5)
            write_byte(42);            //Р¦РІРµС‚ РєСЂР°СЃРЅС‹Р№      
            write_byte(212);            //Р¦РІРµС‚ Р·РµР»РµРЅС‹Р№
            write_byte(255);            //Р¦РІРµС‚ СЃРёРЅРёР№ 
	write_byte(255)
	message_end()            
	emit_sound(pEntity,CHAN_VOICE,"CSSB/sentry_gun/fire_charge_3.wav",1.0,0.5,0,PITCH_NORM)
            //Р•С„С„РµРєС‚ Р»СѓС‡Р° РѕС‚ РїСѓС€РєРё РґРѕ С†РµР»Рё.
          
            //РџСЂРѕРІРµСЂСЏРµРј РїРѕР»РѕР¶РµРЅРёРµ РёРіСЂРѕРєР°.
			new Float:playerOrigin[3], Float:distance
			    for (new i = 1; i <= g_iMaxPlayers; i++) { 
	if (get_user_team(target) != get_user_team(i) )
	   {
	   }
else
{	

        entity_get_vector(i, EV_VEC_origin, playerOrigin)
        distance = vector_distance(playerOrigin, targetOrigin)
        if (distance <= get_pcvar_num(g_Cvar_mode_tesla[0])) {
            new bDucking = !!(entity_get_int(i, EV_INT_flags) & FL_DUCKING);
            targetOrigin[2]  -= bDucking ? 27.0 : 36.0; //РЎС‡РёС‚Р°РµРј РєРѕРѕСЂРґРёРЅР°С‚С‹ РІ РєРѕС‚РѕСЂС‹С… СѓСЃС‚Р°РЅР°РІР»РёРІР°С‚СЊ РјРѕРґРµР»СЊ.
            playerOrigin[2]  -= bDucking ? 27.0 : 36.0; //РЎС‡РёС‚Р°РµРј РєРѕРѕСЂРґРёРЅР°С‚С‹ РІ РєРѕС‚РѕСЂС‹С… СѓСЃС‚Р°РЅР°РІР»РёРІР°С‚СЊ РјРѕРґРµР»СЊ.                                        
            new pEnt = create_entity("info_target");
            if (is_valid_ent(pEnt))
            {    
                entity_set_model(pEnt, "models/cssb/sentry_v5/ice_cube.mdl")
                dllfunc(DLLFunc_Spawn, pEnt);
                                                
                /*
                * Owner
                * /                                            
                entity_set_int( pEnt, DATA_CUBE_OWNER , i );
                entity_set_vector(pEnt, EV_VEC_origin, playerOrigin);

                entity_set_int(pEnt, EV_INT_solid, SOLID_NOT);

                if (bDucking)
                    entity_set_size(pEnt, Float:{ -24.0, -24.0, 10.0 }, Float:{ 24.0, 24.0, 68.0 });
                else
                    entity_set_size(pEnt, Float:{ -24.0, -24.0, 0.0 }, Float:{ 24.0, 24.0, 78.0 });

                entity_set_float(pEnt, EV_FL_takedamage, DAMAGE_NO);

                entity_set_int(pEnt, EV_INT_skin, (cs_get_user_team(i) == CS_TEAM_CT) ? 1 : 0);
                entity_set_int(pEnt, EV_INT_body, bDucking);

                //entity_set_int(pEnt, EV_INT_rendermode, kRenderTransAdd);
                //entity_set_vector(pEnt, EV_VEC_rendercolor, Float:{ 255.0, 255.0, 255.0 });
                
                entity_set_float(pEnt,FREEZ_ENT_TIME,get_gametime() +  get_pcvar_float(g_Cvar_mode_led[1]))
                set_pev(i, pev_flags, pev(i, pev_flags) | FL_FROZEN)
                set_task(1.0,"UnFreez",pEnt+FREEZ_TASK_ID,_,_,"b")
                
                 
            }                                             
        }
}
				}
	 }
    }
}
}
*/
 public ShootFreezing_cub(data[])
{
     new sentry = data[0]

    if ( !pev_valid ( sentry ) )
    return
        //РџРѕР»СѓС‡Р°РµРј РЅР° РєРѕРіРѕ РЅР°РІРµРґРµРЅР° РїСѓС€РєР°
        new target = GetSentryTarget(sentry,TARGET)

    
            new Float:freezOrigin[3],Float:freezAngles[3]
            //РЎС‡РёС‚Р°РµРј С‚РѕС‡РєСѓ РѕС‚РєСѓРґР° СЂРёСЃРѕРІР°С‚СЊ Р»СѓС‡
            entity_get_vector(sentry,EV_VEC_angles,freezAngles)
            engfunc(EngFunc_MakeVectors,freezAngles)
            
            new Float:vecForward[3],Float:vecRight[3],Float:vecUp[3]
            
            get_global_vector(GL_v_forward,vecForward)
            xs_vec_mul_scalar(vecForward,20.0,vecForward)
                                                                                
            get_global_vector(GL_v_right,vecRight)
            //xs_vec_mul_scalar(vecRight,side ? 8.0 : -8.0,vecRight) // right or left rocket
            
            get_global_vector(GL_v_up,vecUp)
            xs_vec_mul_scalar(vecUp,30.0,vecUp)
            
            entity_get_vector(sentry,EV_VEC_origin,freezOrigin)
            xs_vec_add(freezOrigin,vecForward,freezOrigin)                      
            xs_vec_add(freezOrigin,vecRight,freezOrigin)
            xs_vec_add(freezOrigin,vecUp,freezOrigin)
        
            new Float:targetOrigin[3];
            entity_get_vector(target,EV_VEC_origin,targetOrigin)
            
            new OriginEnd[3],OriginStr[3];
            FVecIVec(freezOrigin,OriginStr)
            FVecIVec(targetOrigin,OriginEnd)
      new Float:vecPlaneNormal[3]      
		
static pEntity
      if (pEntity = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_sprite")))
	  {
	 
	    set_pev ( pEntity , pev_classname , "moroz" );
        set_pev ( pEntity, pev_origin, freezOrigin );
        set_pev ( pEntity, pev_owner, sentry );
        
        set_pev ( pEntity, pev_movetype, MOVETYPE_FLY );
        set_pev ( pEntity, pev_solid, SOLID_BBOX  );
            set_pev(pEntity, pev_animtime, 6.0)
  set_pev(pEntity, pev_framerate, 1.0)
  set_pev(pEntity, pev_sequence, 0)
  set_pev(pEntity, pev_scale, 0.3)
         freezAngles[0] = -GetAngleOrigins(freezOrigin,targetOrigin)
		 pev(target,pev_origin,targetOrigin)
        engfunc ( EngFunc_VecToAngles, freezAngles);
        set_pev ( pEntity, pev_angles, freezAngles );
    entity_set_edict(pEntity,EV_ENT_owner,sentry)               
    entity_set_edict(pEntity,EV_ENT_euser4,GetSentryUpgrader(sentry,OWNER))
	    engfunc ( EngFunc_SetModel , pEntity, MOROZ__MODEL     );
				engfunc(EngFunc_SetSize, pEntity, Float:{-5.0, -5.0, -5.0},Float:{5.0, 5.0, 5.0} )
        engfunc ( EngFunc_SetOrigin, pEntity, freezOrigin );
        set_pev ( pEntity, pev_rendermode,  kRenderTransAdd )
        set_pev ( pEntity, pev_renderamt,   255.0 ) 
        set_pev ( pEntity , EV_ENT_euser4,GetSentryUpgrader(sentry,OWNER));
    entity_get_vector(pEntity,EV_VEC_origin,targetOrigin)
    entity_get_vector(pEntity,EV_VEC_angles,freezAngles)
    
    engfunc(EngFunc_MakeVectors,freezAngles)
    get_global_vector(GL_v_forward,freezAngles)
    xs_vec_mul_scalar(freezAngles,9999.0,freezAngles)
    xs_vec_add(targetOrigin,freezAngles,freezAngles)
    engfunc(EngFunc_TraceLine,targetOrigin,freezAngles,0,pEntity,0)    
            FVecIVec(targetOrigin,OriginEnd)
            //Р•С„С„РµРєС‚ Р»СѓС‡Р° РѕС‚ РїСѓС€РєРё РґРѕ С†РµР»Рё.
    entity_set_size(pEntity,Float:{-2.0,-2.0,-2.0},Float:{2.0,2.0,2.0})
    entity_set_origin(pEntity,freezOrigin)
    
    
    new Float:vecVelocity[3]
    get_global_vector(GL_v_forward,vecVelocity)
    xs_vec_mul_scalar(vecVelocity,1000.0,vecVelocity)
    entity_set_vector(pEntity,EV_VEC_velocity,vecVelocity)
                
    
    get_tr2(0,TR_vecEndPos,targetOrigin)
    
    get_tr2(0,TR_vecPlaneNormal,vecPlaneNormal)                                  
    
    xs_vec_mul_scalar(vecPlaneNormal,8.0,vecPlaneNormal)
    xs_vec_add(targetOrigin,vecPlaneNormal,targetOrigin)
    		
            //Р•С„С„РµРєС‚ Р»СѓС‡Р° РѕС‚ РїСѓС€РєРё РґРѕ С†РµР»Рё.
    
    

            //Р•С„С„РµРєС‚ Р»СѓС‡Р° РѕС‚ РїСѓС€РєРё РґРѕ С†РµР»Рё.
    message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(TE_BEAMFOLLOW)
	write_short(pEntity)
	write_short(g_Tesla)
	write_byte(30)
	write_byte(15)
            write_byte(42);            //Р¦РІРµС‚ РєСЂР°СЃРЅС‹Р№      
            write_byte(212);            //Р¦РІРµС‚ Р·РµР»РµРЅС‹Р№
            write_byte(255);            //Р¦РІРµС‚ СЃРёРЅРёР№ 
	write_byte(255)
	message_end()            
	emit_sound(pEntity,CHAN_VOICE,"CSSB/sentry_gun/fire_charge_3.wav",1.0,0.5,0,PITCH_NORM) 
	  }           
} 


//
// Launch RPG rocket
//    sentry - sentry id                                
//    origin - rocket origin        
//    angles - sentry angles
//    traget - rocket target id           
//
                                                                                                              

public fw_MorozTouch(pEntity){
    new Float:freezOrigin[3],Float:angles[3],Float:vecPlaneNormal[3], Float:origin[3]
    entity_get_vector(pEntity,EV_VEC_origin,origin)
    entity_get_vector(pEntity,EV_VEC_angles,angles)
		
    engfunc(EngFunc_MakeVectors,angles)
    get_global_vector(GL_v_forward,angles)
    xs_vec_mul_scalar(angles,9999.0,angles)
    xs_vec_add(origin,angles,angles)
    engfunc(EngFunc_TraceLine,origin,angles,0,pEntity,0)
    
    get_tr2(0,TR_vecEndPos,origin)
    
    get_tr2(0,TR_vecPlaneNormal,vecPlaneNormal)                                  
    
    xs_vec_mul_scalar(vecPlaneNormal,8.0,vecPlaneNormal)
    xs_vec_add(origin,vecPlaneNormal,origin)
    
    CreateExplosion15(pEntity)
	Create_BeamCylinder1(pEntity)  
morozka(pEntity, origin)	
    remove_entity(pEntity)
    
}     
stock morozka(pEntity,Float:origin_[3]) {
    new origin[3]
    FVecIVec(origin_, origin)
    
    new attacker = entity_get_edict(pEntity,EV_ENT_euser4)
    
    if(!is_user_connected(attacker))        
    return
                                                                             
                                                                                                                
    new Float:playerOrigin[3], Float:distance, Float:flDmgToDo, Float:dmgbase = RPG_DAMAGE
    for (new i = 1; i <= g_iMaxPlayers; i++) { 
        if (!is_user_alive(i) || get_user_godmode(i) || get_user_team(i) == get_user_team(attacker)) 
        continue

        entity_get_vector(i, EV_VEC_origin, playerOrigin)
        distance = vector_distance(playerOrigin, origin_)
        if (distance <= get_pcvar_num(g_Cvar_mode_moroz[0])) {
      ShootMoroza(pEntity) 
        }
    }
}                                 
// this very bad method

						
                /*
                * Owner
                */       
/*				
                entity_set_int( pEnt, DATA_CUBE_OWNER , i );
                entity_set_vector(pEnt, EV_VEC_origin, playerOrigin);

                entity_set_int(pEnt, EV_INT_solid, SOLID_NOT);

                if (bDucking)
                    entity_set_size(pEnt, Float:{ -24.0, -24.0, 10.0 }, Float:{ 24.0, 24.0, 68.0 });
                else
                    entity_set_size(pEnt, Float:{ -24.0, -24.0, 0.0 }, Float:{ 24.0, 24.0, 78.0 });

                entity_set_float(pEnt, EV_FL_takedamage, DAMAGE_NO);

                entity_set_int(pEnt, EV_INT_skin, (cs_get_user_team(i) == CS_TEAM_CT) ? 1 : 0);
                entity_set_int(pEnt, EV_INT_body, bDucking);

                //entity_set_int(pEnt, EV_INT_rendermode, kRenderTransAdd);
                //entity_set_vector(pEnt, EV_VEC_rendercolor, Float:{ 255.0, 255.0, 255.0 });
                
                entity_set_float(pEnt,FREEZ_ENT_TIME,get_gametime() +  get_pcvar_float(g_Cvar_mode_led[1]))
                set_pev(i, pev_flags, pev(i, pev_flags) | FL_FROZEN)
                set_task(1.0,"UnFreez",pEnt+FREEZ_TASK_ID,_,_,"b")
                
                 
            }                                             
        }
}
				}
}    
*/
public UnFreez(pEnt)
{                                  
    new iOwner = entity_get_int(pEnt, DATA_CUBE_OWNER);
  
	if(!is_user_alive(iOwner))  
    {
        remove_entity(pEnt);
        set_pev(iOwner, pev_flags, pev(iOwner, pev_flags) & ~FL_FROZEN)
    }
    
    if( get_gametime() > 20.0)
    {
        remove_entity(pEnt);
        set_pev(iOwner, pev_flags, pev(iOwner, pev_flags) & ~FL_FROZEN)
    }
}
public UnRendering(i)
{
        set_user_rendering(i)    
}                                                  
stock FixedUnsigned16( Float:value, scale )
{
    new output;

    output = floatround(value * scale);
    if ( output < 0 )
    output = 0;
    if ( output > 0xFFFF )
    output = 0xFFFF;

    return output;
}

Float:GetAngleOrigins(Float:fOrigin1[3], Float:fOrigin2[3] )
{
    new Float:fVector[3];
    new Float:fAngle[3];
    new Float:fLineAngle;
                                          
    xs_vec_sub(fOrigin2, fOrigin1, fVector);
    vector_to_angle(fVector, fAngle);
    
    if( fAngle[0] > 90.0 )
    fLineAngle = -(360.0 - fAngle[0]);
    else
    fLineAngle = fAngle[0];
    
    return fLineAngle;
} 

                                    
public sentry_blast(ent)
{  
    new sentry = ent
    if (pev_valid ( sentry ) )
    {
            //РџРѕР»СѓС‡Р°РµРј РЅР° РєРѕРіРѕ РЅР°РІРµРґРµРЅР° РїСѓС€РєР°
            new target = GetSentryTarget(sentry,TARGET)
                                        
            new Float:freezOrigin[3] , Float:freezAngles[3]
            //РЎС‡РёС‚Р°РµРј С‚РѕС‡РєСѓ РѕС‚РєСѓРґР° СЂРёСЃРѕРІР°С‚СЊ Р»СѓС‡
            entity_get_vector(sentry,EV_VEC_angles,freezAngles)
            engfunc(EngFunc_MakeVectors,freezAngles)
            
            new Float:vecForward[3],Float:vecRight[3],Float:vecUp[3]
                                              
            get_global_vector(GL_v_forward,vecForward)
            xs_vec_mul_scalar(vecForward,20.0,vecForward)
            
            get_global_vector(GL_v_right,vecRight) 
			
            xs_vec_mul_scalar(vecRight,-18.0,vecRight) // right or left rocket
            
            get_global_vector(GL_v_up,vecUp)
            xs_vec_mul_scalar(vecUp,30.0,vecUp)
            
            entity_get_vector(sentry,EV_VEC_origin,freezOrigin)
            xs_vec_add(freezOrigin,vecForward,freezOrigin)    
            xs_vec_add(freezOrigin,vecRight,freezOrigin)
            xs_vec_add(freezOrigin,vecUp,freezOrigin)
        
            //set_user_health( target, get_user_health( target ) - 1 )
            new Float:targetOrigin[3];
            entity_get_vector(sentry,EV_VEC_origin,targetOrigin)
           
            new OriginEnd[3],OriginStr[3];
            FVecIVec(freezOrigin,OriginStr)
            FVecIVec(targetOrigin,OriginEnd)
            //Р•С„С„РµРєС‚ Р»СѓС‡Р° РѕС‚ РїСѓС€РєРё РґРѕ С†РµР»Рё.
    message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
    write_byte(TE_DLIGHT)
    write_coord(OriginStr[0])                                               
    write_coord(OriginStr[1])
    write_coord(OriginStr[2])
    write_byte(floatround(130.0/7.0))
    write_byte(255)
    write_byte(255)    
    write_byte(255)    
    write_byte(11)
    write_byte(1)
    message_end()  		
    }
}
                                                       
stock set_anim(ent, sequence)   
{
    set_pev(ent, pev_sequence, sequence) 
   

    set_pev(ent, pev_animtime, halflife_time())
    set_pev(ent, pev_framerate, 1.0)   
}  
public client_putinserver(id) {
if (is_user_bot(id)) {
	new parm[1]
	parm[0] = id
	botbuildsrandomly(parm)

}

return PLUGIN_CONTINUE
}
public botair(bot, id)
{
	if(is_user_bot(id))
	{
	set_task(1.0, "sentry_build", id)
}
else 
{
	set_task(3.0, "sentry_build", bot)
}
}
BotBuild(bot, Float:closestTime = 0.1, Float:longestTime = 5.0) {
// This function should only be used to build sentries at objective related targets.
// So as to not try to build all the time if recently started a build task when touched a objective related target
if (task_exists(bot))
	return

new teamSentriesNear = GetStuffInVicinity(bot, BOT_MAXSENTRIESDISTANCE, true, "sentry") + GetStuffInVicinity(bot, BOT_MAXSENTRIESDISTANCE, true, "sentrybase")
if (teamSentriesNear >= BOT_MAXSENTRIESNEAR) {
	new name[32]
	get_user_name(bot, name, 31)
	//client_print(0, print_chat, "There are already %d sentries near me, I won't build here, %s says. (objective)", teamSentriesNear, name)
	return
}

new Float:ltime = random_float(closestTime, longestTime)
set_task(1.0, "sentry_build", bot)
//server_print("Bot task %d set to %f seconds", bot, ltime)

new tempname[32]
get_user_name(bot, tempname, 31)
client_print(0, print_chat, "Bot %s will build a sentry in %f seconds...", tempname, ltime)
}
public sentry_build_randomlybybot(taskid_and_id) {
//Shaman: Check if the player is allowed to build

if (!is_user_alive(taskid_and_id - TASKID_BOTBUILDRANDOMLY))
	return

// Now finally do a short check if there already are enough (2-3 sentries) in this vicinity... then don't build.
new teamSentriesNear = GetStuffInVicinity(taskid_and_id - TASKID_BOTBUILDRANDOMLY, BOT_MAXSENTRIESDISTANCE, true, "sentry") + GetStuffInVicinity(taskid_and_id - TASKID_BOTBUILDRANDOMLY, BOT_MAXSENTRIESDISTANCE, true, "sentrybase")
if (teamSentriesNear >= BOT_MAXSENTRIESNEAR) {
	//new name[32]
	//get_user_name(taskid_and_id - TASKID_BOTBUILDRANDOMLY, name, 31)
	//client_print(0, print_chat, "There are already %d sentries near me, I won't build here, %s says. (random)", teamSentriesNear, name)
	return
}

cmd_CreateSentry(taskid_and_id - TASKID_BOTBUILDRANDOMLY)
}

GetStuffInVicinity(entity, const Float:RADIUS, bool:followTeam, STUFF[]) {
new classname[32], sentryTeam, nrOfStuffNear = 0
entity_get_string(entity, EV_SZ_classname, classname, 31)
if (followTeam) {
	if (equal(classname, "player"))
		sentryTeam = get_user_team(entity)
	else if (equal(classname, "sentry"))
		sentryTeam = entity_get_int(entity, SENTRY_INT_UGPRADERS)
}

if (followTeam) {
	if (equal(STUFF, "sentry")) {
		for (new i = 0; i < g_sentriesNum; i++) {
			if (g_sentries[i] == entity || (followTeam && entity_get_int(g_sentries[i], SENTRY_INT_UGPRADERS) != sentryTeam) || entity_range(g_sentries[i], entity) > RADIUS)
				continue

			nrOfStuffNear++
		}
	}
	else if (equal(STUFF, "sentrybase")) {
		new ent = 0
		while ((ent = find_ent_by_class(ent, STUFF))) {
			// Don't count if:
			// If follow team then if team is not same
			// If ent is the same as what we're searching from, which is entity
			// Don't count a base if it has a head, we consider sentry+base only as one item (a sentry)
			// Or if out of range
			if ((followTeam && entity_get_int(ent, BASE_INT_TEAM) != sentryTeam)
			|| ent == entity
			|| entity_get_edict(ent, BASE_ENT_SENTRY) != 0
			|| entity_range(ent, entity) > RADIUS)
				continue

			nrOfStuffNear++
		}
	}
}

//client_print(0, print_chat, "Found %d sentries within %f distance of entity %d...", nrOfSentriesNear, RADIUS, entity)
return nrOfStuffNear
}

BotBuildRandomly(bot, Float:closestTime = 0.1, Float:longestTime = 5.0) {
// This function is used to stark tasks that will build sentries randomly regardless of map objectives and its targets.
new Float:ltime = random_float(closestTime, longestTime)
set_task(ltime, "sentry_build_randomlybybot", TASKID_BOTBUILDRANDOMLY + bot)

new tempname[32]
get_user_name(bot, tempname, 31)
//client_print(0, print_chat, "Bot %s will build a random sentry in %f seconds...", tempname, ltime)
//server_print("Bot %s will build a random sentry in %f seconds...", tempname, ltime)
}

public playerreachedtarget(target, bot) {
if (!is_user_bot(bot) || GetSentryCount(bot) >= MAXPLAYERSENTRIES || entity_get_int(bot, EV_INT_bInDuck) || cs_get_user_vip(bot) || get_systime() < g_lastObjectiveBuild[bot - 1] + BOT_OBJECTIVEWAIT)
	return PLUGIN_CONTINUE

//client_print(bot, print_chat, "You touched bombtarget %d!", bombtarget)
BotBuild(bot)
g_lastObjectiveBuild[bot - 1] = get_systime()

return PLUGIN_CONTINUE
}

public playertouchedweaponbox(weaponbox, bot) {
if (!is_user_bot(bot) || GetSentryCount(bot) >= MAXPLAYERSENTRIES || cs_get_user_team(bot) != CS_TEAM_CT)
	return PLUGIN_CONTINUE

new model[22]
entity_get_string(weaponbox, EV_SZ_model, model, 21)
if (!equal(model, "models/w_backpack.mdl")) 
	return PLUGIN_CONTINUE

// A ct will build near a dropped bomb
BotBuild(bot, 0.0, 2.0)

return PLUGIN_CONTINUE
}

public playerreachedhostagerescue(target, bot) {
if (!is_user_bot(bot) || GetSentryCount(bot) >= MAXPLAYERSENTRIES) //  || cs_get_user_team(bot) != CS_TEAM_T
	return PLUGIN_CONTINUE

// ~5% chance that a ct will build a sentry here, a t always builds
if (cs_get_user_team(bot) == CS_TEAM_CT) {
	if (random_num(0, 99) < 95)
		return PLUGIN_CONTINUE
}

BotBuild(bot)

//client_print(bot, print_chat, "You touched bombtarget %d!", bombtarget)

return PLUGIN_CONTINUE
}

public playertouchedhostage(hostage, bot) {
if (!is_user_bot(bot) || GetSentryCount(bot) >= MAXPLAYERSENTRIES || cs_get_user_team(bot) != CS_TEAM_T)
	return PLUGIN_CONTINUE

// Build a sentry close to a hostage
BotBuild(bot)

//client_print(bot, print_chat, "You touched bombtarget %d!", bombtarget)

return PLUGIN_CONTINUE
}


public botbuildsrandomly(parm[1]) {
if (!is_user_connected(parm[0])) {
	//server_print("********* %d is no longer in server!", parm[0])
	return
}

new Float:ltime = random_float(BOT_WAITTIME_MIN, BOT_WAITTIME_MAX)
new Float:ltime2 = ltime + random_float(BOT_NEXT_MIN, BOT_NEXT_MAX)
BotBuildRandomly(parm[0], ltime, ltime2)

set_task(ltime2, "botbuildsrandomly", 0, parm, 1)
}

public botbuild_fn(id, level, cid) {
if (!cmd_access(id, level, cid, 1))
	return PLUGIN_HANDLED

new asked = 0
for(new i = 1; i <= g_iMaxPlayers; i++) {
	if (!is_user_connected(i) || !is_user_bot(i) || !is_user_alive(i))
		continue

	cmd_CreateSentry(i)
	asked++
}
console_print(id, "Asked %d bots to build sentries (not counting money etc)", asked)

return PLUGIN_HANDLED
}
stock SendAudio(id, audio[], pitch)
{
    static iMsgSendAudio;
    if(!iMsgSendAudio) iMsgSendAudio = get_user_msgid("SendAudio");

    message_begin( id ? MSG_ONE_UNRELIABLE : MSG_BROADCAST, iMsgSendAudio, _, id);
    write_byte(id);
    write_string(audio);
    write_short(pitch);
    message_end();
}


// =============================================================================
// ВНИМАНИЕ: Это ПУСТОЕ определение функции sentry_build.
// ОНО НЕ БУДЕТ СТРОИТЬ ТУРЕЛИ!
// Это добавлено ТОЛЬКО для устранения ошибки "Function is not present" в логах.
// Реальное решение: найти и установить основной плагин Sentry Gun.
// =============================================================================
public sentry_build(id)
{
    // client_print(id, print_chat, "Функция sentry_build вызвана, но не выполняет никаких действий.");
    // Здесь должен быть код основного плагина Sentry Gun.
    // Если турели не строятся, это означает, что вам НУЖЕН основной плагин.
    return PLUGIN_HANDLED;
}
// РЈР»СѓС‡С€РµРЅРЅР°СЏ С„СѓРЅРєС†РёСЏ РѕР±РЅР°СЂСѓР¶РµРЅРёСЏ С†РµР»РµР№ РґР»СЏ С‚СѓСЂРµР»Рё AMX Mod X
// Р’СЃС‚Р°РІСЊС‚Рµ СЌС‚РѕС‚ РєРѕРґ РІ СЃРІРѕР±РѕРґРЅРѕРµ РјРµСЃС‚Рѕ РІ РїР»Р°РіРёРЅРµ

stock bool:IsValidSentryTarget(id, Float:sentryPos[3])
{
    if(!is_user_alive(id) || !is_user_connected(id))
        return false;
    
    new Float:clientPos[3];
    new Float:clientEye[3];
    new Float:clientFeet[3];
    
    // РџРѕР»СѓС‡Р°РµРј РїРѕР·РёС†РёСЋ РёРіСЂРѕРєР°
    pev(id, pev_origin, clientFeet);
    pev(id, pev_view_ofs, clientEye);
    
    // РЎРєР»Р°РґС‹РІР°РµРј РїРѕР·РёС†РёСЋ РЅРѕРі Рё СЃРјРµС‰РµРЅРёРµ РіР»Р°Р·
    clientEye[0] += clientFeet[0];
    clientEye[1] += clientFeet[1];
    clientEye[2] += clientFeet[2];
    
    // Р¦РµРЅС‚СЂ С‚РµР»Р°
    clientPos[0] = clientFeet[0];
    clientPos[1] = clientFeet[1];
    clientPos[2] = clientFeet[2] + 18.0;
    
    // РџСЂРѕРІРµСЂСЏРµРј РІРёРґРёРјРѕСЃС‚СЊ РїРѕ С‚СЂРµРј С‚РѕС‡РєР°Рј
    new Float:fraction;
    
    // РџСЂРѕРІРµСЂРєР° РіРѕР»РѕРІС‹
    trace_line(-1, sentryPos, clientEye, fraction);
    if(fraction >= 0.99)
        return true;
    
    // РџСЂРѕРІРµСЂРєР° С†РµРЅС‚СЂР° С‚РµР»Р°
    trace_line(-1, sentryPos, clientPos, fraction);
    if(fraction >= 0.99)
        return true;
    
    // РџСЂРѕРІРµСЂРєР° РЅРѕРі
    trace_line(-1, sentryPos, clientFeet, fraction);
    if(fraction >= 0.99)
        return true;
    
    return false;
}

stock bool:CanSentrySeeCrouchingTarget(id, Float:sentryPos[3])
{
    if(!is_user_alive(id) || !is_user_connected(id))
        return false;
    
    new Float:clientPos[3];
    pev(id, pev_origin, clientPos);
    
    // РџСЂРѕРІРµСЂСЏРµРј СЂР°Р·РЅС‹Рµ РІС‹СЃРѕС‚С‹
    new Float:checkHeights[5] = {0.0, 9.0, 18.0, 27.0, 36.0};
    new Float:checkPos[3];
    new Float:fraction;
    
    for(new i = 0; i < 5; i++)
    {
        checkPos[0] = clientPos[0];
        checkPos[1] = clientPos[1];
        checkPos[2] = clientPos[2] + checkHeights[i];
        
        trace_line(-1, sentryPos, checkPos, fraction);
        if(fraction >= 0.99)
            return true;
    }
    
    return false;
}

stock GetNearestSentryTarget(Float:sentryPos[3], Float:maxRange = 1100.0)
{
    new nearestClient = 0;
    new Float:nearestDistance = maxRange;
    
    for(new i = 1; i <= get_maxplayers(); i++)
    {
        if(!is_user_alive(i) || !is_user_connected(i))
            continue;
        
        new Float:clientPos[3];
        pev(i, pev_origin, clientPos);
        
        new Float:distance = get_distance_f(sentryPos, clientPos);
        
        if(distance < nearestDistance)
        {
            // РСЃРїРѕР»СЊР·СѓРµРј СѓР»СѓС‡С€РµРЅРЅСѓСЋ РїСЂРѕРІРµСЂРєСѓ РІРёРґРёРјРѕСЃС‚Рё
            if(IsValidSentryTarget(i, sentryPos) || CanSentrySeeCrouchingTarget(i, sentryPos))
            {
                nearestDistance = distance;
                nearestClient = i;
            }
        }
    }
    
    return nearestClient;
}

// Р”РѕРїРѕР»РЅРёС‚РµР»СЊРЅР°СЏ С„СѓРЅРєС†РёСЏ РґР»СЏ Р±РѕР»РµРµ С‚РѕС‡РЅРѕР№ РїСЂРѕРІРµСЂРєРё РїСЂРёСЃРµРІС€РёС… РёРіСЂРѕРєРѕРІ
stock bool:IsPlayerCrouching(id)
{
    new Float:mins[3], Float:maxs[3];
    pev(id, pev_mins, mins);
    pev(id, pev_maxs, maxs);
    
    // Р•СЃР»Рё РІС‹СЃРѕС‚Р° С…РёС‚Р±РѕРєСЃР° РјРµРЅСЊС€Рµ РѕР±С‹С‡РЅРѕРіРѕ - РёРіСЂРѕРє РїСЂРёСЃРµР»
    return (maxs[2] - mins[2]) < 70.0;
}

// Р¤СѓРЅРєС†РёСЏ РґР»СЏ РїСЂРѕРІРµСЂРєРё РїСЂС‹Р¶РєР°
stock bool:IsPlayerJumping(id)
{
    new Float:velocity[3];
    pev(id, pev_velocity, velocity);
    
    new flags = pev(id, pev_flags);
    
    // РРіСЂРѕРє РІ РІРѕР·РґСѓС…Рµ Рё Сѓ РЅРµРіРѕ РµСЃС‚СЊ РІРµСЂС‚РёРєР°Р»СЊРЅР°СЏ СЃРєРѕСЂРѕСЃС‚СЊ
    return !(flags & FL_ONGROUND) && velocity[2] != 0.0;
}
// Р”РѕРґР°Р№С‚Рµ С†СЋ С„СѓРЅРєС†С–СЋ РІ РІР°С€ РєРѕРґ
stock GetPlayerRealOrigin(id, Float:origin[3])
{
    pev(id, pev_origin, origin)
    
    // РџРµСЂРµРІС–СЂСЏС”РјРѕ, С‡Рё РіСЂР°РІРµС†СЊ СЃРёРґРёС‚СЊ
    if (pev(id, pev_flags) & FL_DUCKING)
    {
        origin[2] -= 24.0 // РљРѕСЂРµРєС†С–СЏ РґР»СЏ СЃРёРґСЏС‡РѕРіРѕ РіСЂР°РІС†СЏ
    }
    else
    {
        origin[2] += 36.0 // РЎС‚Р°РЅРґР°СЂС‚РЅР° РІРёСЃРѕС‚Р° СЃС‚РѕСЏС‡РѕРіРѕ РіСЂР°РІС†СЏ
    }
}

// Р—РќРђР™Р”Р†РўР¬ РЈ Р’РђРЁРћРњРЈ РљРћР”Р† РњР†РЎР¦Р•, Р”Р• РћРўР РРњРЈР„РўР¬РЎРЇ РџРћР—РР¦Р†РЇ Р“Р РђР’Р¦РЇ
// Р—Р°Р·РІРёС‡Р°Р№ С†Рµ РІРёРіР»СЏРґР°С” С‚Р°Рє:
// pev(player, pev_origin, playerOrigin)
// Р°Р±Рѕ
// get_user_origin(player, playerOrigin)

// Р—РђРњР†РќР†РўР¬ РќРђ:
// GetPlayerRealOrigin(player, playerOrigin)

// РџСЂРёРєР»Р°Рґ Р·Р°РјС–РЅРё:
// РЎРўРђР РР™ РљРћР”:
/*
for (new i = 1; i <= 32; i++)
{
    if (!is_user_alive(i)) continue
    
    new Float:playerOrigin[3]
    pev(i, pev_origin, playerOrigin)  // <-- Р¦Р® РЎРўР РћРљРЈ Р—РђРњР†РќРРўР
    
    new Float:distance = vector_distance(sentryPos, playerOrigin)
    // ... СЂРµС€С‚Р° РєРѕРґСѓ
}
*/

// РќРћР’РР™ РљРћР”:
/*
for (new i = 1; i <= 32; i++)
{
    if (!is_user_alive(i)) continue
    
    new Float:playerOrigin[3]
    GetPlayerRealOrigin(i, playerOrigin)  // <-- Р—РђРњР†РќР•РќРћ РќРђ Р¦Р® Р¤РЈРќРљР¦Р†Р®
    
    new Float:distance = vector_distance(sentryPos, playerOrigin)
    // ... СЂРµС€С‚Р° РєРѕРґСѓ
}
*/
// Р¤СѓРЅРєС†РёСЏ РґР»СЏ РїРѕР»СѓС‡РµРЅРёСЏ РїСЂР°РІРёР»СЊРЅРѕР№ РІС‹СЃРѕС‚С‹ С†РµР»Рё
Float:GetTargetHeight(target)
{
    new Float:fOrigin[3]
    entity_get_vector(target, EV_VEC_origin, fOrigin)
    
    // РџСЂРѕРІРµСЂСЏРµРј, РїСЂРёСЃРµРґР°РµС‚ Р»Рё РёРіСЂРѕРє
    if (entity_get_int(target, EV_INT_flags) & FL_DUCKING)
    {
        // Р”Р»СЏ РїСЂРёСЃРµРґР°СЋС‰РµРіРѕ РёРіСЂРѕРєР° РёСЃРїРѕР»СЊР·СѓРµРј РјРµРЅСЊС€СѓСЋ РІС‹СЃРѕС‚Сѓ
        return fOrigin[2] + 18.0  // РџРѕР»РѕРІРёРЅР° РѕС‚ РѕР±С‹С‡РЅРѕР№ РІС‹СЃРѕС‚С‹ (36/2)
    }
    else
    {
        // Р”Р»СЏ СЃС‚РѕСЏС‰РµРіРѕ РёРіСЂРѕРєР°
        return fOrigin[2] + PLAYERORIGINHEIGHT
    }
}
// РђР»СЊС‚РµСЂРЅР°С‚РёРІРЅС‹Р№ РІР°СЂРёР°РЅС‚ - РјРЅРѕР¶РµСЃС‚РІРµРЅРЅС‹Рµ С‚СЂР°СЃСЃРёСЂРѕРІРєРё
bool:CanSentrySeeCrouchingTargetMultiple(sentry, target)
{
    new Float:fSentryOrigin[3], Float:fTargetOrigin[3]
    entity_get_vector(sentry, EV_VEC_origin, fSentryOrigin)
    entity_get_vector(target, EV_VEC_origin, fTargetOrigin)
    
    fSentryOrigin[2] += CANNONHEIGHTFROMFEET
    
    // РџСЂРѕРІРµСЂСЏРµРј РЅРµСЃРєРѕР»СЊРєРѕ С‚РѕС‡РµРє РЅР° С‚РµР»Рµ РёРіСЂРѕРєР°
    new Float:fHeights[3]
    
    if (entity_get_int(target, EV_INT_flags) & FL_DUCKING)
    {
        // Р”Р»СЏ РїСЂРёСЃРµРґР°СЋС‰РµРіРѕ РёРіСЂРѕРєР°
        fHeights[0] = fTargetOrigin[2] + 30.0  // Р“РѕР»РѕРІР°
        fHeights[1] = fTargetOrigin[2] + 20.0  // РўСѓР»РѕРІРёС‰Рµ
        fHeights[2] = fTargetOrigin[2] + 10.0  // РќРѕРіРё
    }
    else
    {
        // Р”Р»СЏ СЃС‚РѕСЏС‰РµРіРѕ РёРіСЂРѕРєР°
        fHeights[0] = fTargetOrigin[2] + 36.0  // Р“РѕР»РѕРІР°
        fHeights[1] = fTargetOrigin[2] + 24.0  // РўСѓР»РѕРІРёС‰Рµ
        fHeights[2] = fTargetOrigin[2] + 12.0  // РќРѕРіРё
    }
    
    // РџСЂРѕРІРµСЂСЏРµРј РІСЃРµ С‚РѕС‡РєРё
    for (new i = 0; i < 3; i++)
    {
        new Float:fTestOrigin[3]
        fTestOrigin[0] = fTargetOrigin[0]
        fTestOrigin[1] = fTargetOrigin[1]
        fTestOrigin[2] = fHeights[i]
        
        new ptr = create_tr2()
        engfunc(EngFunc_TraceLine, fSentryOrigin, fTestOrigin, IGNORE_MONSTERS, sentry, ptr)
        new Float:fFraction = get_tr2(ptr, TR_flFraction)
        free_tr2(ptr)
        
        if (fFraction >= 1.0)
            return true
    }
    
    return false
}
