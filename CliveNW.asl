/*
	Clive 'N' Wrench (Released February 23, 2023) https://store.steampowered.com/app/1094720
	ASL originally by CptBrian & Tipdaddy78
*/

state("Clive 'N' Wrench", "Unknown Version"){ // Fail-safe copy of whichever version is most popular
	float IGT   : "mono-2.0-bdwgc.dll", 0x499C78, 0xBB0, 0x38;
	byte TPause : "mono-2.0-bdwgc.dll", 0x499C78, 0xBB0, 0x3C;
}
state("Clive 'N' Wrench", "Steam 1.00"){
	float IGT   : "mono-2.0-bdwgc.dll", 0x499C78, 0xBB0, 0x38;
	byte TPause : "mono-2.0-bdwgc.dll", 0x499C78, 0xBB0, 0x3C;
}

startup{ // When the script first loads, before process connection
	vars.LoadSplit = "Split upon paused timer events (Loads & Cutscenes)";

	settings.Add("ASL Version 1.1 – March 6, 2023", false);
	settings.Add("Click the 'Website' button for more info!", false);
	settings.Add(vars.LoadSplit, false);

	vars.SavedIGT = 0;
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
}

isLoading{
	return true; // Real timer always paused - Required to set IGT as our time
}

gameTime{
	return TimeSpan.FromSeconds(current.IGT + vars.SavedIGT);
}

start{
	return (old.IGT == 0 && current.IGT != old.IGT);
}

split{
	if(settings[vars.LoadSplit] && current.TPause == 1 && old.TPause == 0 && current.IGT > 3){
		return true; // Splits when the timer pauses after it's been running, unless it's the very start of the run (IGT check)
	}
	else{
		return false;
	}
}

reset{
	// Nope
}

update{
	if(old.IGT > 2 && old.IGT != null && (current.IGT == 0 || current.IGT == null)){
		vars.SavedIGT += old.IGT; // Saves IGT in a failure event where the game must be closed, so a run can be continued despite true IGT being reset to 0
		// This method may require unwavering stability of the IGT pointer to prevent SavedIGT increasing when it shouldn't. Thankfully, the IGT pointer is very simple in this game.
	}
}
