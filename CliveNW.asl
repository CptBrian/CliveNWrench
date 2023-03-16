/*
	Clive 'N' Wrench (Released February 23, 2023) https://store.steampowered.com/app/1094720
	ASL originally by CptBrian & TipDaddy78
*/

state("Clive 'N' Wrench", "Unknown Version"){ // Fail-safe copy of whichever version is most popular
	float IGT   : "mono-2.0-bdwgc.dll", 0x499C78, 0xBB0, 0x38;
	byte TPause : "mono-2.0-bdwgc.dll", 0x499C78, 0xBB0, 0x3C;
	int stageId : "mono-2.0-bdwgc.dll", 0x499C78, 0xE20, 0x3C;
}
state("Clive 'N' Wrench", "PC 1.0"){
	float IGT   : "mono-2.0-bdwgc.dll", 0x499C78, 0xBB0, 0x38;
	byte TPause : "mono-2.0-bdwgc.dll", 0x499C78, 0xBB0, 0x3C;
	int stageId : "mono-2.0-bdwgc.dll", 0x499C78, 0xE20, 0x3C;
}
state("Clive 'N' Wrench", "Steam 1.1"){
	float IGT   : "mono-2.0-bdwgc.dll", 0x3A418C, 0xDF8, 0x24;
	byte TPause : "mono-2.0-bdwgc.dll", 0x3A418C, 0xDF8, 0x28;
	int stageId : "mono-2.0-bdwgc.dll", 0x3A418C, 0xF30, 0x20;
	int stoneCount : "mono-2.0-bdwgc.dll", 0x3A2BFC, 0xD0, 0x51C, 0xC; 
}

startup{ // When the script first loads, before process connection
	vars.ASLVersion = "ASL Version 1.4 – March 15, 2023";
	vars.LoadSplit = "Split upon paused timer events (Loads & Cutscenes)";
	vars.BackupIGT = "Save Backup IGT in cases where the game closes. ('Reset' does not function with this.)";
	vars.ILMode = "Use IL Mode, timer will not start until a level is entered. NOT SAFE FOR FULL-GAME RUNS";
	vars.splitOnStones = "Split on # of Stones";

	settings.Add(vars.ASLVersion, false);
	settings.Add("WebsiteTip", false, "Click the 'Website' button for more info!", vars.ASLVersion);
	settings.Add(vars.LoadSplit, false);
	settings.Add(vars.BackupIGT, true);
	settings.Add(vars.ILMode, false);

	// Add options to split on X stones
	settings.Add(vars.splitOnStones, false);
	for (int i = 1; i < 116; i++) {
		string stoneText = i.ToString() + " stones";
		settings.Add(stoneText, false, stoneText, vars.splitOnStones);
	}

	vars.SavedIGT = 0;
	vars.ILModePreIGT = 0; // Holds how much time has passed on IGT prior to timer starting.
	vars.currentStoneCount = 0; // Holds how many stones have been collected on the current run.
	vars.currentStoneCountOLD = 0; // Also holds how many stones have been collected, but causes split to only happen once.

	// Stage IDs
	vars.hubWorld = 0;
	vars.bunnyIShrunk = 1;
	vars.greatWen = 2;
	vars.cajunMobBog = 3;
	vars.tempusTombs = 4;
	vars.cleocatra = 5;
	vars.graveMistake = 6;
	vars.ancientGreeceTrap = 7;
	vars.unitaur = 8;
	vars.chimpBagBunny = 9;
	vars.annieOakTree = 10;
	vars.hareTodayGongTomorrow = 11;
	vars.corsairsCove = 12;
	vars.blueBeard = 13;
	vars.iceratops = 14;
	vars.dinoBoss = 15;
	vars.middleAge = 16;
	vars.secretLevel = 17;
}

init{ // When the process connects
	// Identifies different game versions using MD5 checksums of the game's primary executable
	byte[] exeMD5HashBytes = new byte[0];
	using(var md5 = System.Security.Cryptography.MD5.Create()){
		using(var s = File.Open(modules.First().FileName, FileMode.Open, FileAccess.Read, FileShare.ReadWrite)){
			exeMD5HashBytes = md5.ComputeHash(s);
		} 
	}
	vars.MD5Hash = exeMD5HashBytes.Select(x => x.ToString("X2")).Aggregate((a, b) => a + b);
	print("MD5Hash: " + vars.MD5Hash.ToString()); // Prints generated MD5 once to see within DebugView
	
	if(vars.MD5Hash == "441AF5A444F3D19019EA9713ECF8C914") version = "PC 1.0";
	else if(vars.MD5Hash == "F113F4F54C9296AD5238A0E892406891") version = "Steam 1.1";
	else if(vars.MD5Hash == "MindGoblin") version = "Steam 1.02";
	else version = "Unknown Version";
}

onReset{ // Clears relevant local variables.
	vars.SavedIGT = 0; 
	vars.ILModePreIGT = 0;
	vars.currentStoneCount = 0;
	vars.currentStoneCountOLD = 0;
}

isLoading{
	return true; // Real timer always paused - Required to set IGT as our time
}

gameTime{
	if (settings[vars.ILMode]) {
		return TimeSpan.FromSeconds(current.IGT - vars.ILModePreIGT);
	} else {
		return TimeSpan.FromSeconds(current.IGT + vars.SavedIGT);
	}
}

start{
	// Reset stone counts at the start of a run
	vars.currentStoneCount = 0;
	vars.currentStoneCountOLD = 0;
	vars.ILModePreIGT = 0;

	if (settings[vars.ILMode]) { // Starts timer when entering a new level, but not at start of game.
		vars.ILModePreIGT = current.IGT;
		return old.stageId == vars.hubWorld && current.stageId != vars.hubWorld && current.IGT != 0;
	} else if (old.IGT == 0 && current.IGT != old.IGT) { 
		return true; // Starts timer when entering game from main menu for the first time. IL Mode will skip this check. 
	}
	return false;
}

split{
	if (settings[vars.LoadSplit] 	// Setting to split on loads is checked
		&& current.TPause == 1 		// AND Timer is paused on this frame...
		&& old.TPause == 0 			// ...AND wasn't on the last frame.
		&& current.IGT > 3) {		// AND we aren't at the start of the game.
		print("Splitting due to being paused");
		return true; // Splits when the timer pauses after it's been running, unless it's the very start of the run (IGT check)
	} 
	if (vars.currentStoneCount > vars.currentStoneCountOLD) {
		vars.currentStoneCountOLD = vars.currentStoneCount;
		print("Old stones value is now: " + vars.currentStoneCountOLD.ToString());
		if (settings[vars.splitOnStones] && settings[vars.currentStoneCount.ToString() + " stones"]) { 
			return true; // If selected to split on X stones.)
		}
	} 

	return false;
}

reset{ // If you don't want to use this, uncheck the Reset box in LiveSplit's autosplitter config.
	return (!settings[vars.BackupIGT] && old.IGT > 0 && current.IGT == 0);
}

update{
	if(settings[vars.BackupIGT] 						// Setting to save backup IGT is on
		&& timer.CurrentPhase == TimerPhase.Running 	// Livesplit is set to run
		&& old.IGT > 2 									// The previous frame's time is higher than 2 seconds
		&& old.IGT != null 
		&& (current.IGT == 0 || current.IGT == null)) {
		vars.SavedIGT += old.IGT; // Saves IGT in a failure event where the game closes, so a run can be continued despite true IGT being reset to 0
		// This method may require unwavering stability of the IGT pointer to prevent SavedIGT increasing when it shouldn't. Thankfully, the IGT pointer is very simple in this game.
	}

	if (old.stoneCount != current.stoneCount) { 
		vars.currentStoneCount += 1; // Increment stored stone count when collecting a stone.
	}
}
