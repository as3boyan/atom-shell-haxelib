package ;

import haxe.Http;
import haxe.io.Path;
import haxe.Serializer;
import haxe.Unserializer;
import haxe.xml.Fast;
import haxe.zip.Reader;
import helpers.PlatformHelper;
import neko.Lib;
import project.Platform;
import sys.FileSystem;
import sys.io.File;
import helpers.ProcessHelper;
import helpers.LogHelper;
import helpers.PathHelper;

/**
 * ...
 * @author AS3Boyan
 */

//Heavily based on lime-tools download system (https://github.com/openfl/lime-tools)
 
enum Answer {
	Yes;
	No;
	Always;
}
 

class AutoUpdateInfo
{
	public var autoupdate:Bool;
	public var lastLocalPath:String;
	public var lastCheckedDate:Date;
	
	public function new()
	{
		autoupdate = true;
		lastLocalPath = null;
		lastCheckedDate = null;
	}
}

class Main 
{
	//private static var NODEWEBKIT_WINDOWS:String = "http://s3.amazonaws.com/node-webkit/v0.9.2/node-webkit-v0.9.2-win-ia32.zip";
	private static var nodeWebkitUrl:String;
	private static var autoUpdateInfo:AutoUpdateInfo = new AutoUpdateInfo();
	static private var localPath:String;
	
	static function main() 
	{	
		var args:Array<String> = Sys.args();
		
		if (args[0] == "setup")
		{
			setup();
		}
		else 
		{
			checkUpdates();
			
			trace(args);
			
			if (args[0] == "autoupdate")
			{
				if (args[1] == "true")
				{
					autoUpdateInfo.autoupdate = true;
					File.saveContent("autoupdate", Serializer.run(autoUpdateInfo));
					Sys.println("Autoupdate now is on");
				}
				else if (args[1] == "false") 
				{
					autoUpdateInfo.autoupdate = false;
					File.saveContent("autoupdate", Serializer.run(autoUpdateInfo));
					Sys.println("Autoupdate now is off");
				}
			}
			else if (args.length > 1)
			{			
				if (!FileSystem.exists("bin"))
				{
					setup();
				}
				
				var path:String = args[1];

				if (!FileSystem.exists(path))
				{
					path = PathHelper.combine(args[1], args[0]);
				}
				
				if (FileSystem.exists(path))
				{
					if (PlatformHelper.hostPlatform == Platform.LINUX)
					{
						if (!FileSystem.exists(args[0]))
						{
							path = PathHelper.combine(args[1], args[0]);
						}
						else
						{
							path = args[0];
						}
// 						ProcessHelper.runProcess("", "bash", ["nw-linux", path], false);
							
						ProcessHelper.runProcess("./bin", "./atom", [path], false, true, false, true);
					}
					else if(PlatformHelper.hostPlatform == Platform.MAC)
					{
						if (!FileSystem.exists(args[0]))
						{
							path = PathHelper.combine(args[1], args[0]);
						}
						else
						{
							path = args[0];
						}
						
// 						ProcessHelper.runProcess("./bin", "node-webkit.app/Contents/MacOS/node-webkit", [path], false);
						ProcessHelper.runProcess("./bin", "Atom.app/Contents/MacOS/Atom", [path], false, true, false, true);
						trace(path);
					}
					else
					{
						ProcessHelper.runProcess("./bin", "./atom", [path], false, true, false, true);
					}
				}
			}
			else 
			{
				var params = [];
				
				if (args.length == 1)
				{
					params.push(args[0]);
				}
				
				if (PlatformHelper.hostPlatform == Platform.LINUX)
				{
					ProcessHelper.runProcess("./bin", "./atom", params, false, true, false, true);
				}
				else if (PlatformHelper.hostPlatform == Platform.MAC)
				{
// 					ProcessHelper.runProcess("./bin", "node-webkit.app/Contents/MacOS/node-webkit", [args[0]], false);
					ProcessHelper.runProcess("./bin", "Atom.app/Contents/MacOS/Atom", params, false, true, false, true);
				}
				else
				{
					ProcessHelper.runProcess("./bin", "atom", params, false);
				}
			}
		}
	}
	
	macro function getVersion()
	{
			
	}
	
	static function checkUpdates():Void
	{
		if (FileSystem.exists("autoupdate"))
		{
			var buf:String = File.getContent("autoupdate");
			autoUpdateInfo = Unserializer.run(buf);
		}
		
		var outdated:Bool = autoUpdateInfo.lastCheckedDate == null || (Date.now().getTime() - autoUpdateInfo.lastCheckedDate.getTime() > DateTools.days(7));
		var notInstalled:Bool = !FileSystem.exists("bin");
		
		var success:Bool = true;

		if (autoUpdateInfo.autoupdate && (outdated || notInstalled))
		{
			try 
			{
				lookForNodeWebkitURL();
			}
			catch (err:Dynamic)
			{
				trace(err);
				success = false;
			}
			
			if (success) 
			{
				if (autoUpdateInfo.lastLocalPath != localPath || notInstalled)
				{
					Sys.println("Found a new version of node-webkit binary: " + localPath);
					downloadAndExtract();
				}
				else 
				{
					Sys.println("You are using latest version of node-webkit binary: " + localPath);
				}
			}
			
			autoUpdateInfo.lastCheckedDate = Date.now();
			File.saveContent("autoupdate", Serializer.run(autoUpdateInfo));
		}
	}
	
	private static function lookForNodeWebkitURL():Void
	{
		Sys.println("Looking for node-webkit url...");
		
		var args = Sys.args();
		
		//PathHelper.combine(args[args.length - 1], "rogerwang_node-webkit.html")
		var data = sys.io.File.getContent("Releases_atom_atom-shell.html");
		//Http.requestUrl("https://github.com/rogerwang/node-webkit");
		
		var eregLinux64bit = ~/<a href="https:\/\/(.+releases.+linux-x64\.zip)/g;
		var eregLinux32bit = ~/<a href="https:\/\/(.+releases.+linux-ia32\.zip)/g;
		var eregWindows = ~/<a href="https:\/\/(.+releases.+win32-ia32\.zip)/g;
		var eregMac = ~/<a href="https:\/\/(.+releases.+darwin-x64\.zip)/g;
		
		if (data.indexOf("atom-shell") > -1)
		{
			switch (PlatformHelper.hostPlatform) 
			{
				case Platform.WINDOWS:
					if (eregWindows.match(data))
					{
						nodeWebkitUrl = eregWindows.matched(1);
					}
				case Platform.LINUX:
					var is64Bit:Bool = PlatformHelper.hostArchitecture.match(project.Architecture.X64);

					if (is64Bit)
					{
						if (eregLinux64bit.match(data))
						{
							nodeWebkitUrl = eregLinux64bit.matched(1);
						}
					}
					else
					{
						if (eregLinux32bit.match(data))
						{
							nodeWebkitUrl = eregLinux32bit.matched(1);
						}
					}
				case Platform.MAC:
					if (eregMac.match(data))
					{
						nodeWebkitUrl = eregMac.matched(1);
					}
				default:

			}
		}
		
		if (nodeWebkitUrl != null) 
		{
// 			trace(nodeWebkitUrl);
			nodeWebkitUrl = "https://" + nodeWebkitUrl;
// 			trace(nodeWebkitUrl);
			localPath = Path.withoutDirectory(nodeWebkitUrl);
		}
	}
	
	private static function setup():Void
	{		
		lookForNodeWebkitURL();
		downloadAndExtract();
	}
	
	private static function downloadAndExtract() 
	{
		downloadFile(nodeWebkitUrl, true);
			
		if (!FileSystem.exists("bin"))
		{
			FileSystem.createDirectory("bin");
		}

		for (entry in FileSystem.readDirectory("bin"))
		{
			removeFile(PathHelper.combine("bin", entry));
		}
		
		extractFile(localPath, "bin");

		if (PlatformHelper.hostPlatform == Platform.LINUX)
		{
// 			var folder = FileSystem.readDirectory("bin")[0];
// 			Sys.command("cp" ,["-a", "bin/" + folder + "/*", "bin"]);
// 			Sys.command("rm", ["-rf", "bin/" + folder]);
		}
		
		if (PlatformHelper.hostPlatform != Platform.WINDOWS)
		{
			Sys.command("chmod", ["-R", "777", "bin"]);
		}
		
		removeFile(localPath);
		
		autoUpdateInfo.lastLocalPath = localPath;
		File.saveContent("autoupdate", Serializer.run(autoUpdateInfo));
	}
	
	static inline function readLine()
	{
		return Sys.stdin ().readLine ();
	}

	private static function ask (question:String):Answer {

		while (true) {

			Sys.println (question + " y/n/a");

			switch (readLine ()) {
				case "n": return No;
				case "y": return Yes;
				case "a": return Always;
			}

		}

		return null;

	}
	
	private static function removeFile(path:String)
	{
		if (PlatformHelper.hostPlatform == Platform.WINDOWS)
		{
			FileSystem.deleteFile(path);
		}
		else 
		{
			Sys.command("rm", [(path)]);
		}
	}
	
	//Uses parts of code from lime-tools https://github.com/openfl/lime-tools/blob/ac2ca52e89c0d5e2758246415e9286dbc63c36a5/src/utils/PlatformSetup.hx
	
	private static function downloadFile(remotePath:String, ?enableInteration:Bool = false):Void
	{		
		if (FileSystem.exists (localPath) && enableInteration) {

			var answer = ask ("File found. Install existing file?");

			if (answer != No) {

				return;
			}

		}

		trace(remotePath);

// 		var data = Http.requestUrl(remotePath);

		
// 		File.write(localPath, true).
		
		var out = File.write(localPath, true);
		var progress = new Progress (out);
		//"http://s3.amazonaws.com/node-webkit/" +
		var h = new Http (remotePath);
		
		trace(remotePath);

		h.cnxTimeout = 30;

		h.onError = function (e) {
			progress.close();
// 			removeFile(localPath);
			throw e;
		};

		Lib.println ("Downloading " + localPath + "...");

		h.customRequest (false, progress);

		if (h.responseHeaders != null && h.responseHeaders.exists ("Location")) 
		{
			var location = h.responseHeaders.get ("Location");

			if (location != remotePath) 
			{
				downloadFile (location);
			}
		}
	}
	
	private static function extractFile (sourceZIP:String, targetPath:String, ignoreRootFolder:String = ""):Void {

		var extension = Path.extension (sourceZIP);

		if (extension != "zip") {

			var arguments = "xvzf";			

			if (extension == "bz2" || extension == "tbz2") {

				arguments = "xvjf";

			}	

			if (ignoreRootFolder != "") {

				if (ignoreRootFolder == "*") {

					for (file in FileSystem.readDirectory (targetPath)) {

						if (FileSystem.isDirectory (targetPath + "/" + file)) {

							ignoreRootFolder = file;

						}

					}

				}

				ProcessHelper.runCommand ("", "tar", [ arguments, sourceZIP ], false);
				ProcessHelper.runCommand ("", "cp", [ "-R", ignoreRootFolder + "/*", targetPath ], false);
				//Sys.command ("rm", [ "-r", ignoreRootFolder ]);

			} else {

				ProcessHelper.runCommand ("", "tar", [ arguments, sourceZIP, "-C", targetPath ], false);

				//InstallTool.runCommand (targetPath, "tar", [ arguments, FileSystem.fullPath (sourceZIP) ]);

			}

			Sys.command ("chmod", [ "-R", "755", targetPath ]);

		} else {

			var file = File.read (sourceZIP, true);
			var entries = Reader.readZip (file);
			file.close ();

			for (entry in entries) {

				var fileName = entry.fileName;

				if (fileName.charAt (0) != "/" && fileName.charAt (0) != "\\" && fileName.split ("..").length <= 1) {

					var dirs = ~/[\/\\]/g.split(fileName);

					if ((ignoreRootFolder != "" && dirs.length > 1) || ignoreRootFolder == "") {

						if (ignoreRootFolder != "") {

							dirs.shift ();

						}

						var path = "";
						var file = dirs.pop();
						for( d in dirs ) {
							path += d;
							PathHelper.mkdir (targetPath + "/" + path);
							path += "/";
						}

						if( file == "" ) {
							if( path != "" ) Lib.println("  Created "+path);
							continue; // was just a directory
						}
						path += file;
						Lib.println ("  Install " + path);

						var data = Reader.unzip (entry);
						var f = File.write (targetPath + "/" + path, true);
						f.write (data);
						f.close ();

					}

				}

			}

		}

		Lib.println ("Done");

	}

}

class Progress extends haxe.io.Output {

	var o : haxe.io.Output;
	var cur : Int;
	var max : Int;
	var start : Float;

	public function new(o) {
		this.o = o;
		cur = 0;
		start = haxe.Timer.stamp();
	}

	function bytes(n) {
		cur += n;
		if( max == null )
			Lib.print(cur+" bytes\r");
		else
			Lib.print(cur+"/"+max+" ("+Std.int((cur*100.0)/max)+"%)\r");
	}

	public override function writeByte(c) {
		o.writeByte(c);
		bytes(1);
	}

	public override function writeBytes(s,p,l) {
		var r = o.writeBytes(s,p,l);
		bytes(r);
		return r;
	}

	public override function close() {
		super.close();
		o.close();
		var time = haxe.Timer.stamp() - start;
		var speed = (cur / time) / 1024;
		time = Std.int(time * 10) / 10;
		speed = Std.int(speed * 10) / 10;

		// When the path is a redirect, we don't want to display that the download completed

		if (cur > 400) {

			Lib.print("Download complete : " + cur + " bytes in " + time + "s (" + speed + "KB/s)\n");

		}

	}

	public override function prepare(m) {
		max = m;
	}

}
