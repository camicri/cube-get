/* -*- Mode: vala; tab-width: 4; intend-tabs-mode: t -*- */
/* cube-vala
 *
 * Copyright (C) Jake R. Capangpangan 2015 <camicrisystems@gmail.com>
 *
cube-vala is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the
 * Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * cube-vala is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along
 * with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

using Gee;

public class BaseManager
{	
	string _main_dir = "data";
	string _proj_dir = "projects";
	string _bin_dir = "bin";
	string _config_dir = "config";
	string _logs_dir = "logs";
	string _logs_error_dir = "error";
	string _logs_debug_dir = "debug";
	string _logs_info_dir = "info";
	string _packages_dir = "packages";
	string _temp_dir = "temp";
	string _resources_dir = "resources";
	string _resources_icons_dir = "icons";
	string _resources_themes_dir = "themes";
	string _hidden_dir = ".cube-server";

	string _config_filename = "config.cube";
	string _sections_config_filename = "sections.cube";
	string _app_share_config_filename = "app-share.cube";	
	string _config_file;
	string _sections_config_file;
	string _app_share_config_file;

	//Tools
	string _root_command_filename = "root";
	string _root_command_file;

	ConfigurationFile _config;
	ConfigurationFile _sections_config;
	ConfigurationFile _app_share_config;

	//Properties
	//public string slash { get { return _sl; } }
	public string main_directory { get { return _main_dir; } }
	public string projects_directory { get { return _proj_dir ; } }
	public string bin_directory { get { return _bin_dir; } }
	public string configurations_directory { get { return _config_dir; } }
	public string logs_directory { get { return _logs_dir; } }
	public string error_logs_directory { get { return _logs_error_dir; } }
	public string debug_logs_directory { get { return _logs_debug_dir; } }
	public string information_logs_directory { get { return _logs_info_dir; } }
	public string packages_directory { get { return _packages_dir; } }
	public string temporary_directory { get { return _temp_dir; } }
	public string resources_directory { get { return _resources_dir; } }
	public string resources_icon_directory { get { return _resources_icons_dir; } }
	public string resources_themes_directory { get { return _resources_themes_dir; } }
	public string hidden_directory { get { return _hidden_dir; } }

	//Signals
	public signal void process_progress_changed ( string message, int progress_current , int progress_max );

	public string root_command_file { get { return _root_command_file; } }

	public ConfigurationFile main_configuration_file { get { return _config; } }
	public ConfigurationFile section_configuration_file { get { return _sections_config; } }
	public ConfigurationFile app_share_configuration_file { get { return _app_share_config; } }

	public BaseManager(string base_dir, string proj_dir)
	{
		_main_dir = base_dir;
		_proj_dir = proj_dir;
		_bin_dir = Path.build_filename ( _main_dir , _bin_dir );
		_config_dir = Path.build_filename ( _main_dir , _config_dir );
		_logs_dir = Path.build_filename ( _main_dir , _logs_dir );
		_logs_error_dir = Path.build_filename ( _logs_dir, _logs_error_dir );
		_logs_debug_dir = Path.build_filename ( _logs_dir, _logs_debug_dir );
		_logs_info_dir = Path.build_filename ( _logs_dir, _logs_info_dir );
		_packages_dir = Path.build_filename ( _main_dir , _packages_dir );
		_temp_dir = Path.build_filename ( _main_dir , _temp_dir );
		_resources_dir = Path.build_filename ( _main_dir , _resources_dir );
		_resources_icons_dir = Path.build_filename ( _resources_dir , _resources_icons_dir );
		_resources_themes_dir = Path.build_filename (  _resources_dir , _resources_themes_dir );

		_hidden_dir = Path.build_filename (Environment.get_home_dir(), _hidden_dir); 

		_config_file = Path.build_filename ( _config_dir , _config_filename );
		_sections_config_file = Path.build_filename ( _config_dir , _sections_config_filename );
		_app_share_config_file = Path.build_filename ( _config_dir , _app_share_config_filename );
		_root_command_file = Path.build_filename ( _bin_dir , _root_command_filename );
	}

	public void initialize_base()
	{
		_config = new ConfigurationFile(_config_filename, _config_dir);
		_app_share_config = new ConfigurationFile(_app_share_config_filename, _config_dir);
		_sections_config = new ConfigurationFile(_sections_config_filename,_config_dir);

		bool result = _config.open_configuration();
		
		if ( result )
		{			
			HashMap<string,string> default_config_data = generate_default_configuration_data_cube();

			//Add missing configuration data to current configuration (if any)
			bool save = false;
			foreach ( string key in default_config_data.keys )
			{				
				if ( !_config.configuration_map.has_key(key) )
				{
					_config.set_value(key,default_config_data[key]);
					save = true;
				}
			}

			if ( save )
				_config.save_configuration();
		}
		
		_app_share_config.open_configuration();
		_sections_config.open_configuration();
	}	

	public void create_update_base()
	{
		create_directories ();
		create_configuration_files();
		create_tools();
	}

	public void create_directories()
	{		
		if ( !FileUtils.test (_main_dir, FileTest.EXISTS) )
			DirUtils.create_with_parents(_main_dir, 0775);
		if ( !FileUtils.test (_bin_dir, FileTest.EXISTS) )
			DirUtils.create_with_parents(_bin_dir, 0775);
		if ( !FileUtils.test (_proj_dir, FileTest.EXISTS) )
			DirUtils.create_with_parents(_proj_dir, 0775);
		if ( !FileUtils.test (_config_dir, FileTest.EXISTS) )
			DirUtils.create_with_parents(_config_dir, 0775);
		if ( !FileUtils.test (_logs_dir, FileTest.EXISTS) )
			DirUtils.create_with_parents(_logs_dir, 0775);
		if ( !FileUtils.test (_logs_error_dir, FileTest.EXISTS) )
			DirUtils.create_with_parents(_logs_error_dir, 0775);
		if ( !FileUtils.test (_logs_debug_dir, FileTest.EXISTS) )
			DirUtils.create_with_parents(_logs_debug_dir, 0775);
		if ( !FileUtils.test (_logs_info_dir, FileTest.EXISTS) )
			DirUtils.create_with_parents(_logs_info_dir, 0775);
		if ( !FileUtils.test (_packages_dir, FileTest.EXISTS) )
			DirUtils.create_with_parents(_packages_dir, 0775);
		if ( !FileUtils.test (_temp_dir, FileTest.EXISTS) )
			DirUtils.create_with_parents(_temp_dir, 0775);
		if ( !FileUtils.test (_resources_dir, FileTest.EXISTS) )
			DirUtils.create_with_parents(_resources_dir, 0775);
		if ( !FileUtils.test (_resources_icons_dir, FileTest.EXISTS) )
			DirUtils.create_with_parents(_resources_icons_dir, 0775);
		if ( !FileUtils.test (_resources_themes_dir, FileTest.EXISTS) )
			DirUtils.create_with_parents(_resources_themes_dir, 0775);

		if( SystemInformation.get_operating_system_type() == OperatingSystemType.LINUX ) {
			if ( !FileUtils.test (_hidden_dir, FileTest.EXISTS) )
				DirUtils.create_with_parents(_hidden_dir, 0775);
		}
	}

	public bool check_directories()
	{
		if ( !FileUtils.test (_main_dir, FileTest.EXISTS) )
			return false;
		if ( !FileUtils.test (_bin_dir, FileTest.EXISTS) )
			return false;
		if ( !FileUtils.test (_proj_dir, FileTest.EXISTS) )
			return false;
		if ( !FileUtils.test (_config_dir, FileTest.EXISTS) )
			return false;
		if ( !FileUtils.test (_logs_dir, FileTest.EXISTS) )
			return false;
		if ( !FileUtils.test (_logs_debug_dir, FileTest.EXISTS) )
			return false;
		if ( !FileUtils.test (_logs_error_dir, FileTest.EXISTS) )
			return false;
		if ( !FileUtils.test (_logs_info_dir, FileTest.EXISTS) )
			return false;
		if ( !FileUtils.test (_packages_dir, FileTest.EXISTS) )
			return false;
		if ( !FileUtils.test (_temp_dir, FileTest.EXISTS) )
			return false;
		if ( !FileUtils.test (_resources_dir, FileTest.EXISTS) )
			return false;
		if ( !FileUtils.test (_resources_icons_dir, FileTest.EXISTS) )
			return false;
		if ( !FileUtils.test (_resources_themes_dir, FileTest.EXISTS) )
			return false;
		if( SystemInformation.get_operating_system_type() == OperatingSystemType.LINUX ) {
			if ( !FileUtils.test (_hidden_dir, FileTest.EXISTS) )
				return false;
		}
		return true;
	}

	public HashMap<string,string> generate_default_configuration_data_cube()
	{
		HashMap<string,string> config_map = new HashMap<string,string>();
		config_map["downloaders"] = "axel,aria2c";
		config_map["default-downloader"] = "axel";
		config_map["axel-downloader-parameters"] = "-n 5";
		config_map["aria2c-downloader-parameters"] = "";
		config_map["installers"] = "apt-get,dpkg";
		config_map["default-installer"] = "apt-get";
		config_map["apt-get-parameters"] = "--assume-yes --no-download --allow-unauthenticated";
		config_map["dpkg-parameters"] = "--no-force-conflicts --no-force-depends --no-force-breaks --no-force-architecture --skip-same-version -i";
		config_map["enable-reverse-dependency"] = "true";
		config_map["terminals"] = "xterm;x-terminal-emulator;mate-terminal;gnome-terminal;xfce4-terminal;lxterminal;pantheon-terminal;konsole";
		config_map["server-port"] = "8080";
		config_map["enable-shellinabox"] = "false";
		config_map["shellinabox-port"] = "4200";
		config_map["shellinabox-parameters"] = "";

		return config_map;
	}

	public HashMap<string,string> generate_default_configuration_data_app_share()
	{
		HashMap<string,string> config_map = new HashMap<string,string>();		
		config_map = new HashMap<string,string>();
		config_map["LinuxMint=Ubuntu"]="13=12.04;14=12.10;15=13.04;16=13.10;17=14.04";
		config_map["Elementary OS=LinuxMint"]="0.2.1=13";
		config_map["Elementary OS=Ubuntu"]="0.2.1=12.04";

		return config_map;
	}

	public HashMap<string,string> generate_default_configuration_data_sections()
	{
		HashMap<string,string> config_map = new HashMap<string,string>();
		config_map = new HashMap<string,string>();
		config_map["admin"] = "System Administration"; 		
		//config_map["comm"] = "Communication"; 
		config_map["devel"] = "Development"; 
		config_map["doc"] = "Office"; 
		//config_map["editors"] = "Editors"; 
		//config_map["electronics"] = "Electronics"; 
		//config_map["embedded"] = "Embedded Devices"; 
		config_map["games"] = "Games and Amusement"; 
		//config_map["gnome"] = "GNOME Desktop Environment"; 
		config_map["graphics"] = "Graphics"; 
		//config_map["radio"] = "Amateur Radio";
		//config_map["interpreters"] = "Interpreted Computer Languages"; 
		//config_map["kde"] = "KDE Desktop Environment"; 
		//config_map["libdevel"] = "Libraries - Development"; 
		config_map["lib"] = "Libraries"; 
		//config_map["mail"] = "Email"; 
		//config_map["math"] = "Mathematics";
		//config_map["misc"] = "Miscellaneous - Text Based"; 
		//config_map["net"] = "Networking";
		//config_map["news"] = "News";
		//config_map["oldlibs"] = "Libraries - Old"; 
		//config_map["otherosfs"] = "Cross Platforms"; 
		//config_map["perl"] = "Perl Programming Language"; 
		//config_map["python"] = "Python Programming Language"; 
		//config_map["science"] = "Science";
		//config_map["shells"] = "Shells";
		config_map["sound"] = "Multimedia";
		config_map["educ"] = "Education";
		config_map["desktop"] = "Desktop";
		//config_map["tex"] = "Tex Authoring"; 
		//config_map["text"] = "Word Processing"; 
		config_map["utils"] = "Utilities";
		config_map["web"] = "World Wide Web"; 
		//config_map["x11"] = "Miscellaneous - Graphical";
		//config_map["unknown"] = "Unknown";

		return config_map;
	}

	public bool create_configuration_files()
	{		
		string[] headers = new string[]{};
		
		if ( !FileUtils.test (_config_file,FileTest.EXISTS) )
		{
			//Create Main Configuration File
			headers = new string[]{
				"#Camicri Cube Main Configuration File",
				"#This is the global configuration file of cube. Entering incorrect configuration values may break the whole cube system.",
				"#Format : <key>:<val>"
			};
			
			_config = new ConfigurationFile(_config_filename, _config_dir);			
			_config.create_configuration(headers,generate_default_configuration_data_cube());			
		}

		if ( !FileUtils.test (_app_share_config_file,FileTest.EXISTS) )
		{
			//Create App Share Configuration
			headers = new string[]{
				"#Camicri Cube App Share Configuration File",
				"#Format : <Project Distribution=Host Distribution> : <Project Distribution Version1>=<Host Distribution Version1>;<v2>=<v2>;..."			
			};
			
			_app_share_config = new ConfigurationFile(_app_share_config_filename, _config_dir);
			_app_share_config.create_configuration(headers,generate_default_configuration_data_app_share());
		}
		
		if ( !FileUtils.test (_sections_config_file,FileTest.EXISTS) )
		{
			//Create Sections Configuration
			headers = new string[]{
				"#Camicri Cube Package Sections",
				"#Format : <keyword>:<description>" 
			};
			
			_sections_config = new ConfigurationFile(_sections_config_filename,_config_dir);					
			_sections_config.create_configuration(headers,generate_default_configuration_data_sections());
		}

		return true;
	}

	public bool reset_configuration_files() {
		if(_config == null)
			return false;

		HashMap<string, string> defaults = generate_default_configuration_data_cube();

		foreach (string key in defaults.keys) {
			_config.set_value(key,defaults[key]);
		}
		
		return _config.save_configuration ();
	}

	public bool create_tools()
	{
		var file = File.new_for_path(_root_command_file);
		if ( file.query_exists() )
			return true;				
		try
		{
			string root_command_script = "#!/bin/bash\npkexec env DISPLAY=$DISPLAY XAUTHORITY=$XAUTHORITY $@";
			var stream = new DataOutputStream( file.create ( FileCreateFlags.REPLACE_DESTINATION ) );
			stream.put_string(root_command_script);
			stream.close();

			ProcessManager.run_get_status(new string[]{"chmod","+x",_root_command_file});
		}
		catch(Error e)
		{
			return false;
		}
		return true;
	}

	public bool check_configuration_files()
	{
		if(!FileUtils.test (_sections_config_file, FileTest.EXISTS))
			return false;
		if(!FileUtils.test (_app_share_config_file, FileTest.EXISTS))
			return false;
		if(!FileUtils.test (_config_file, FileTest.EXISTS))
			return false;
		return true;
	}
}
