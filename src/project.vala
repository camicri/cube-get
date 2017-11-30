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

public class Project
{
	ConfigurationFile _conf_file;
	LinuxInformation _linux_info;
	BaseManager _base_mgr;

	//Etc
	string _proj_name;
	string _proj_ver;
	string _comp_name;
	string _operating_system;
	string _distribution;
	string _codename;
	string _release;
	string _upstream_distribution;
	string _upstream_codename;
	string _upstream_release;
	string _architecture;
	string _date_created;
	bool _is_project_original_computer = false;

	//Project Directories	
	string _proj_dir;
	string _proj_main_dir = "projects";	
	string _data_dir = "data";
	string _sources_dir = "sources";
	string _list_dir = "list";
	string _list_temp_dir = "temp";
	string _packages_dir = "packages";
	string _repacked_packages_dir = "repacked_packages";
	string _screenshots_dir = "screenshots";
	string _temp_dir = "temp";

	//Project Files
	string _info_filename = "info.cube";
	string _sources_list_file = "sources.list";
	string _preferences_file = "preferences";
	string _status_file = "status";
	string _info_file;
	string _sys_info_file="";

	public ConfigurationFile config { get { return _conf_file; } }	

	//Properties - Configuration File Contents
	public string project_name { get { return _proj_name; } }
	public string project_version { get { return _proj_ver; } }
	public string computer_name { get { return _comp_name; } }
	public string operating_system { get { return _operating_system; } }
	public string distribution { get { return _distribution; } }
	public string release { get { return _release; } }
	public string codename { get { return _codename; } }
	public string upstream_distribution { get { return _upstream_distribution; } }
	public string upstream_release { get { return _upstream_release; } }
	public string upstream_codename { get { return _upstream_codename; } }
	public string architecture { get { return _architecture; } }
	public string date_created { get { return _date_created; } }	

	//Properties - Project Contents
	public string information_file { get { return _info_file; } }
	public string information_filename { get { return _info_filename; } }
	public string sources_list_file { get { return _sources_list_file; } }	
	public string preferences_file { get { return _preferences_file; } }	
	public string status_file { get { return _status_file; } }	
	public string project_directory { get { return _proj_dir; } }
	public string main_projects_directory { get { return _proj_main_dir; } }
	public string data_directory { get { return _data_dir; } }
	public string sources_directory { get { return _sources_dir; } }
	public string list_directory { get { return _list_dir; } }
	public string list_temp_directory { get { return _list_temp_dir; } }
	public string packages_directory { get { return _packages_dir; } }
	public string repacked_packages_directory { get { return _repacked_packages_dir; } }
	public string screenshots_directory { get { return _screenshots_dir; } }
	public string temporary_directory { get { return _temp_dir; } }	
	public string system_information_file { get { return _sys_info_file; } }
	public bool is_original_computer{ get { return _is_project_original_computer; } }
	
	//Signals
	public signal void process_progress_changed ( string message, int progress_current , int progress_max );	
	
	public Project ( string project_name, string project_main_directory , BaseManager base_mgr )
	{		
		_proj_main_dir = project_main_directory;
		_proj_name = project_name;
		_base_mgr = base_mgr;
		
		initialize_directories ();
		_conf_file = new ConfigurationFile( _info_filename , _proj_dir );	
	}

	public void initialize_directories()
	{		
		_proj_dir = Path.build_filename ( _proj_main_dir , _proj_name );
		_data_dir = Path.build_filename ( _proj_dir , _data_dir );
		_sources_dir = Path.build_filename ( _data_dir , _sources_dir );
		_list_dir = Path.build_filename ( _data_dir , _list_dir );
		_list_temp_dir = Path.build_filename ( _list_dir , _list_temp_dir );
		_packages_dir = Path.build_filename ( _data_dir , _packages_dir );
		_repacked_packages_dir = Path.build_filename ( _data_dir , _repacked_packages_dir );
		_screenshots_dir = Path.build_filename ( _data_dir , _screenshots_dir );
		_temp_dir = Path.build_filename ( _data_dir , _temp_dir );
		
		_info_file = Path.build_filename ( _proj_dir , _info_filename );
		_sources_list_file = Path.build_filename ( _sources_dir , _sources_list_file );
		_preferences_file = Path.build_filename ( _sources_dir , _preferences_file );
		_status_file = Path.build_filename ( _list_dir , _status_file );
		_sys_info_file = Path.build_filename ( _base_mgr.hidden_directory , _sys_info_file );
	}

	public bool create_directories()
	{
		int res = 0;
		if ( !FileUtils.test (_proj_dir, FileTest.EXISTS) )
			res += DirUtils.create_with_parents(_proj_dir, 0777);
		if ( !FileUtils.test (_data_dir, FileTest.EXISTS) )
			res += DirUtils.create_with_parents(_data_dir, 0777);
		if ( !FileUtils.test (_sources_dir, FileTest.EXISTS) )
			res += DirUtils.create_with_parents(_sources_dir, 0777);
		if ( !FileUtils.test (_list_dir, FileTest.EXISTS) )
			res += DirUtils.create_with_parents(_list_dir, 0777);
		if ( !FileUtils.test (_list_temp_dir, FileTest.EXISTS) )
			res += DirUtils.create_with_parents(_list_temp_dir, 0777);
		if ( !FileUtils.test (_packages_dir, FileTest.EXISTS) )
			res += DirUtils.create_with_parents(_packages_dir, 0777);
		if ( !FileUtils.test (_repacked_packages_dir, FileTest.EXISTS) )
			res += DirUtils.create_with_parents(_repacked_packages_dir, 0777);
		if ( !FileUtils.test (_screenshots_dir, FileTest.EXISTS) )
			res += DirUtils.create_with_parents(_screenshots_dir, 0777);
		if ( !FileUtils.test (_temp_dir, FileTest.EXISTS) )
			res += DirUtils.create_with_parents(_temp_dir, 0777);
		if (res < 0)
			return false;
		return true;
	}

	public bool create_project()
	{		
		if ( FileUtils.test ( _proj_dir , FileTest.EXISTS) )
			DirUtils.remove( _proj_dir );		
		
		if ( create_directories() )
		{			
			_linux_info = new LinuxInformation();
			HashMap<string,string> config_map = new HashMap<string,string>();
			config_map["Project Version"] = CubeInformation.project_version;
			config_map["Project Name"] = _proj_name;
			config_map["Computer Name"] = _linux_info.computer_name;
			config_map["Operating System"] = _linux_info.operating_system;
			config_map["Distribution"] = _linux_info.distribution;
			config_map["Release"] = _linux_info.release;
			config_map["Code Name"] = _linux_info.codename;
			config_map["Architecture"] = _linux_info.architecture;
			config_map["Date Created"] = new DateTime.now_local().format("%x %X");

			if ( _linux_info.upstream_distribution != null )
				config_map["Upstream Distribution"] = _linux_info.upstream_distribution;

			if ( _linux_info.upstream_release != null )
				config_map["Upstream Release"] = _linux_info.upstream_release;

			if ( _linux_info.upstream_codename != null )
				config_map["Upstream Code Name"] = _linux_info.upstream_codename;

			_sys_info_file = Path.build_filename ( _base_mgr.hidden_directory ,
			    config_map["Project Name"].replace(":","-").replace("/","-").replace(" ","-") + "_" + 
				config_map["Computer Name"].replace(":","-").replace("/","-").replace(" ","-") + "_" + 
				config_map["Operating System"].replace(":","-").replace("/","-").replace(" ","-") + "_" + 
				config_map["Date Created"].replace(":","-").replace("/","-").replace(" ","-")
			);
			
			string[] headers = new string[]{
				"#Camicri Cube Project Information File"
			};	
			
			update_project();
			if ( _conf_file.create_configuration(headers,config_map) )
			{
				if ( _create_system_information_file() )
				{
					return true;
				}
			}
		}
		
		return false;
	}

	private bool _create_system_information_file()
	{				
		File sys_info_file = File.new_for_path( _sys_info_file );
		try
		{
			DataOutputStream stream = new DataOutputStream ( sys_info_file.create (FileCreateFlags.REPLACE_DESTINATION) );
			stream.put_string(_sys_info_file);
			stream.close();
		}
		catch ( Error e )
		{
			stdout.printf("Error : " + e.message );
			return false;
		}
		
		return true;
	}

	public bool open_project()
	{
		if( !_conf_file.open_configuration() )
			return false;

		_proj_name = _conf_file.get_value("Project Name");
		_proj_ver = _conf_file.get_value("Project Version");
		_comp_name = _conf_file.get_value("Computer Name");
		_operating_system = _conf_file.get_value("Operating System");
		_distribution = _conf_file.get_value("Distribution");
		_codename = _conf_file.get_value("Code Name");
		_release = _conf_file.get_value("Release");
		_upstream_distribution = _conf_file.get_value("Upstream Distribution");
		_upstream_codename = _conf_file.get_value("Upstream Code Name");
		_upstream_release = _conf_file.get_value("Upstream Release");
		_architecture = _conf_file.get_value("Architecture");
		_date_created = _conf_file.get_value("Date Created");		

		_sys_info_file = Path.build_filename ( _base_mgr.hidden_directory , 
		                                      _proj_name.replace(":","-").replace("/","-").replace(" ","-") + "_" +
		                                      _comp_name.replace(":","-").replace("/","-").replace(" ","-") + "_" +
		                                      _operating_system.replace(":","-").replace("/","-").replace(" ","-") + "_" +
		                                      _date_created.replace(":","-").replace("/","-").replace(" ","-") 
		                                      );		

		_is_project_original_computer = is_project_original_computer();
		
		return true;
	}

	public bool update_project()
	{
		//Copy sources list
		process_progress_changed ( "Updating Sources..." , 0 , 4 );
		FileManager.copy ( AptInformation.sources_file , _sources_list_file );
		FileManager.copy_directory_files ( AptInformation.sources_directory , _sources_dir , "*.list" );

		//Copy preferences
		process_progress_changed ( "Updating Apt Preferences..." , 1 , 4 );
		FileManager.copy ( AptInformation.preferences_file , _preferences_file );
		FileManager.copy_directory_files ( AptInformation.preferences_directory , _sources_dir , "*.pref" );

		//Copy lists
		process_progress_changed ( "Updating Repository Lists..." , 2 , 4 );
		FileManager.copy_directory_files ( AptInformation.lists_directory , _list_dir, "*Packages");

		//Copy status file
		process_progress_changed ( "Updating Project Status..." , 3 , 4 );
		FileManager.copy ( AptInformation.status_file , _status_file );
		process_progress_changed ( "Update Finished..." , 4 , 4 );

		return true;
	}

	public bool update_system()
	{
		//Ensure that we are in the original computer
		if ( !_is_project_original_computer)
			return false;
		
		string copy_format = "cp -uvf \"%s\" \"%s\"\n";
		string script_content = "#!/bin/bash\n";
		string script_path = Path.build_filename ( _temp_dir , "copy-to-sys.sh" );

		try 
		{
		
			var dir = File.new_for_path ( _sources_dir );
			var enumerator = dir.enumerate_children(FileAttribute.STANDARD_NAME,0);
			FileInfo file_info;

			//Copy sources.list
			script_content += "\n#Sources\n";
			var filepath = _sources_list_file;
			script_content += copy_format.printf(filepath, AptInformation.sources_file);		

			//Copy *.list
			while ( ( file_info = enumerator.next_file() ) != null )
			{
				if ( file_info.get_file_type() == FileType.REGULAR )
				{
					if ( file_info.get_name().has_suffix(".list") && file_info.get_name() != "sources.list" )
					{
						filepath = Path.build_filename(_sources_dir, file_info.get_name());
						script_content += copy_format.printf(filepath, AptInformation.sources_directory); 
					}
				}
			}

			//Copy preferences
			script_content += "\n#Preferences\n";
			filepath = Path.build_filename( _preferences_file );
			script_content += copy_format.printf(filepath, AptInformation.sources_directory);

			//Copy *.pref
			dir = File.new_for_path ( sources_directory );
			enumerator = dir.enumerate_children(FileAttribute.STANDARD_NAME,0);
			while ( ( file_info = enumerator.next_file() ) != null )
			{
				if ( file_info.get_file_type() == FileType.REGULAR )
				{
					if ( file_info.get_name().has_suffix(".pref") )
					{
						filepath = Path.build_filename( _sources_dir , file_info.get_name());
						script_content += copy_format.printf(filepath, AptInformation.preferences_directory); 
					}
				}
			}

			//Copy *Packages
			script_content += "\n#Lists\n";
			dir = File.new_for_path ( list_directory );
			enumerator = dir.enumerate_children(FileAttribute.STANDARD_NAME,0);
			while ( ( file_info = enumerator.next_file() ) != null )
			{
				if ( file_info.get_file_type() == FileType.REGULAR )
				{
					if ( file_info.get_name().has_suffix("Packages") )
					{
						filepath = Path.build_filename( _list_dir, file_info.get_name());
						script_content += copy_format.printf(filepath, AptInformation.lists_directory); 
					}
				}
			}

			var script_file = File.new_for_path(script_path);
			if ( script_file.query_exists() )
				script_file.delete();		
		
			var stream = new DataOutputStream( script_file.create ( FileCreateFlags.REPLACE_DESTINATION ) );
			stream.put_string(script_content);
			stream.close();

			process_progress_changed ( "Updating System..." , 0 , 1 );
			ProcessManager.run_get_status ( new string[] { "chmod","+x",script_path } );

			string? enable_shellinabox = _base_mgr.main_configuration_file.get_value("enable-shellinabox");

			int res = 0;
			
			if (enable_shellinabox != "true")
			{
				res = ProcessManager.run_get_status ( new string[]{_base_mgr.root_command_file, script_file.get_path()} );
				process_progress_changed ( "Update Finished..." , 1 , 1 );
			}
			else
			{				
				string? shellinabox_path = Which.which ("shellinaboxd",_base_mgr);
				if ( shellinabox_path != null )
				{
					var shellinabox_parameters = _base_mgr.main_configuration_file.get_value("shellinabox-parameters");
					var shellinabox_port = _base_mgr.main_configuration_file.get_value("shellinabox-port");
					
					ShellInABox snb = new ShellInABox(shellinabox_path,_base_mgr.temporary_directory,shellinabox_port,shellinabox_parameters);
					res = snb.run("sudo bash "+script_file.get_path());
				}
				else
				{
					process_progress_changed ( "Update Failed. shellinaboxd not found..." , 1 , 1 );
					res = -1;
				}
			}
			
			
			if ( res == 0 )
				return true;
		}
		catch ( Error e )
		{
			stdout.printf ("Error : %s\n",e.message);
			return false;
		}		
		return false;
	}

	public bool is_project_original_computer()
	{
		_linux_info = new LinuxInformation();
		
		//Check for the system information file
		if ( !File.new_for_path( _sys_info_file ).query_exists() )
			return false;

		if ( config.get_value("Computer Name") != _linux_info.computer_name )
			return false;

		if ( config.get_value("Operating System") != _linux_info.operating_system )
			return false;

		if ( config.get_value("Distribution") != _linux_info.distribution )
			return false;

		if ( config.get_value("Release") != _linux_info.release )
			return false;

		if ( config.get_value("Code Name") != _linux_info.codename )
			return false;

		if ( config.get_value("Architecture") != _linux_info.architecture )
			return false;

		return true;
	}

	public bool update_project_status_file()
	{
		bool res = false;

		//Ensure that we are in the original computer
		if ( !_is_project_original_computer )
			return false;
		
		process_progress_changed ( "Updating Project..." , 0 , 1 );
		res = FileManager.copy ( AptInformation.status_file , _status_file );
		process_progress_changed ( "Update Finished" , 1 , 1 );					
		
		return res;
	}
}