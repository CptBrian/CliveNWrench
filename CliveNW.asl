/*
	Clive 'N' Wrench (Released February 23, 2023) https://store.steampowered.com/app/1094720
	ASL originally by CptBrian & TipDaddy78
*/

state("Clive 'N' Wrench", "Unknown Version"){ // Fail-safe copy of whichever version is most popular
	float IGT   : "mono-2.0-bdwgc.dll", 0x499C78, 0xBB0, 0x38;
	byte TPause : "mono-2.0-bdwgc.dll", 0x499C78, 0xBB0, 0x3C;
	int stageId : "mono-2.0-bdwgc.dll", 0x499C78, 0xE20, 0x3C;
}
state("Clive 'N' Wrench", "Steam 1.00"){
	float IGT   : "mono-2.0-bdwgc.dll", 0x499C78, 0xBB0, 0x38;
	byte TPause : "mono-2.0-bdwgc.dll", 0x499C78, 0xBB0, 0x3C;
	int stageId : "mono-2.0-bdwgc.dll", 0x499C78, 0xE20, 0x3C;
}

startup{ // When the script first loads, before process connection
	vars.ASLVersion = "ASL Version 1.3 – March 6, 2023";
	vars.LoadSplit = "Split upon paused timer events (Loads & Cutscenes)";
	vars.BackupIGT = "Save Backup IGT in cases where the game closes. ('Reset' does not function with this.)";
	vars.ILMode = "Use IL Mode, timer will not start until a level is entered. NOT SAFE FOR FULL-GAME RUNS";

	settings.Add(vars.ASLVersion, false);
	settings.Add("WebsiteTip", false, "Click the 'Website' button for more info!", vars.ASLVersion);
	settings.Add(vars.LoadSplit, false);
	settings.Add(vars.BackupIGT, true);
	settings.Add(vars.ILMode, false);

	vars.SavedIGT = 0;
	vars.ILModePreIGT = 0; // Holds how much time has passed on IGT prior to timer starting.

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
	
	if(vars.MD5Hash == "441AF5A444F3D19019EA9713ECF8C914") version = "Steam 1.00";
	else if(vars.MD5Hash == "Ligma") version = "Steam 1.01";
	else if(vars.MD5Hash == "MindGoblin") version = "Steam 1.02";
	else version = "Unknown Version";
}

onReset{
	vars.SavedIGT = 0; // Clears any saved IGT when you want to start a new run
	vars.ILModePreIGT = 0;
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
	if (settings[vars.ILMode]) {
		vars.ILModePreIGT = current.IGT;
		return old.stageId == vars.hubWorld && current.stageId != vars.hubWorld;
	} else {
		return (old.IGT == 0 && current.IGT != old.IGT);
	}
}

split{
	if (settings[vars.LoadSplit] 	// Setting to split on loads is checked
		&& current.TPause == 1 		// AND Timer is paused on this frame...
		&& old.TPause == 0 			// ...AND wasn't on the last frame.
		&& current.IGT > 3) {		// AND we aren't at the start of the game.
		return true; // Splits when the timer pauses after it's been running, unless it's the very start of the run (IGT check)
	} else {
		return false;
	}
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
}
