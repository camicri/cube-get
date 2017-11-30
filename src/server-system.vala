/* -*- Mode: vala; tab-width: 4; intend-tabs-mode: t -*- */
/* server
 *
 * Copyright (C) Jake R. Capangpangan 2015 <camicrisystems@gmail.com>
 *
server is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the
 * Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * server is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along
 * with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

using Gee;

public enum DownloadType { PACKAGE, REPOSITORY }
public enum MarkPackageType { TO_INSTALL, TO_DOWNLOAD }

public class DownloadStatus
{
	public DownloadType download_type;
	public int index;
	public Package[] packages;
	public Source[] sources;
	public int[] progress;
	public DownloadStatusType[] status_type;
	public int overall_progress_success;
	public int overall_progress_failed;
	public string[] transfer_rate;
	public string[] size;
	public string[] error_message;
	public string? main_package;
}

public class CubeServerSystem
{
	CubeSystem _cube;
	PackageQuery _query;
	PackageQuery _curr_query;

	TreeMap<string,bool> _flag_status_map = new TreeMap<string,bool>();
	TreeMap<string,string> _flag_result_map = new TreeMap<string,string>();
	
	ArrayList<string> _marked_to_install_packages = new ArrayList<string>();
	ArrayList<string> _marked_to_download_packages = new ArrayList<string>();

	DownloadStatus? _dl_status = null;

	string _err_message = "";

	int _server_port = 8080;

	public CubeWebsocketConnection ws = null;

	//Properties
	public CubeSystem cube { get { return _cube; } set { _cube = value; } }
	public TreeMap<string,bool> flag_status_map { get { return _flag_status_map; } }
	public TreeMap<string,string> flag_result_map { get { return _flag_result_map; } }
	public PackageQuery package_query { get { return _query; } set { _query = value; } }
	public PackageQuery current_query { get { return _curr_query; } set { _curr_query = value; } }
	public DownloadStatus download_status { get { return _dl_status; } }	

	public ArrayList<string> marked_to_install_packages { get { return _marked_to_install_packages; } }
	public ArrayList<string> marked_to_download_packages { get { return _marked_to_download_packages; } }

	public int server_port { get { return _server_port; } set { _server_port = value; } } 
	
	public string error_message { get { return _err_message; } }	

	public signal void system_status_changed();
	public signal void download_status_changed();

	public CubeServerSystem()
	{
		initialize_flags ();
	}

	public void emitEvent(string event, string? data = null)
	{
		if (ws != null)
			ws.emit(event, data);
	}

	public void initialize_flags()
	{	
		//All '*ing' are process status which takes time to complete		
		
		_flag_status_map["cube_initialized"] = false;
		
		_flag_status_map["repository_scanning"] = false;
		_flag_status_map["repository_scanned"] = false;
		
		_flag_status_map["repository_downloading"] = false;
		
		_flag_status_map["project_opened"] = false;

		_flag_status_map["project_creating"] = false;
		_flag_status_map["project_created"] = false;
		
		_flag_status_map["project_deleting"] = false;
		_flag_status_map["project_deleted"] = false;
		
		_flag_status_map["project_updating"] = false;

		_flag_status_map["system_updating"] = false;

		_flag_status_map["package_downloading"] = false;

		_flag_status_map["package_installing"] = false;

		_flag_result_map["install_success"] = "";
		_flag_result_map["install_message"] = "";
		
		_flag_result_map["download_success"] = "";
		_flag_result_map["download_message"] = "";
		
		_flag_result_map["update_project_success"] = "";
		_flag_result_map["update_project_message"] = "";
		
		_flag_result_map["update_system_success"] = "";
		_flag_result_map["update_system_message"] = "";		

		system_status_changed();
	}

	public void change_system_status(string status_name, bool status)
	{
		_flag_status_map[status_name] = status;		
	}

	public bool initialize_cube_system(string data_dir, string projs_dir)
	{		
		change_system_status("cube_initialized",false);
		emitEvent ("initialize-started");
	
		_cube = new CubeSystem( data_dir , projs_dir );	
		if ( !_cube.create_and_initialize_system() )
		{
			emitEvent ("initialize-failed");
			return false;
		}

		change_system_status("cube_initialized",true);
		emitEvent ("initialize-done");

		return true;
	}	

	public bool create_project ( string project )
	{
		_err_message = "";

		change_system_status("project_creating",true);
		change_system_status("project_created",false);
		emitEvent ("project-create-started");
		
		if ( !_flag_status_map["cube_initialized"] )
		{
			_err_message = "Failed to initialize cube";
			change_system_status("project_creating",false);
			emitEvent ("project-create-failed", "{\"message\":\"%s\"}".printf(_err_message));
			return false;
		}

		if ( File.new_for_path ( Path.build_filename(_cube.base_manager.projects_directory,project) ).query_exists() )
		{
			_err_message = "Unable to create project %s. Project exists".printf(project);
			change_system_status("project_creating",false);
			emitEvent ("project-create-failed", "{\"message\":\"%s\"}".printf(_err_message));
			return false;
		}
	
		if ( !_cube.create_project(project) )
		{			
			_err_message = "Failed to create project %s.".printf(project);
			change_system_status("project_creating",false);
			emitEvent ("project-create-failed", "{\"message\":\"%s\"}".printf(_err_message));
			return false;
		}

		change_system_status("project_creating",false);
		change_system_status("project_created",true);
		emitEvent ("project-create-done");
		
		return true;
	}	

	public bool open_project ( string project )
	{		
		_err_message = "";
		
		change_system_status("project_opened",false);
		emitEvent ("project-open-started");
		//
		
		Project p;
		if ( (p = _cube.find_project(project)) == null )
		{
			_err_message = "Failed to open project %s".printf ( project );
			emitEvent ("project-open-failed","{\"message\":\"%s\"}".printf(_err_message));
			
			return false;
		}
		_cube.open_project( p );
				
		change_system_status("project_opened",true);
		emitEvent ("project-open-done");
		
		return true;
	}

	public bool close_project() {
		_err_message = "";

		/* Check for pending processes */
		foreach(string key in flag_status_map.keys)
		{
			if(key.has_suffix("ing") && flag_status_map[key]) {
				_err_message = "There are still pending tasks";
				return false;
			}
		}

		/* Clear Markings */
		clear_marked_packages(MarkPackageType.TO_DOWNLOAD);
		clear_marked_packages(MarkPackageType.TO_INSTALL);

		/* Clear Repositories */
		if(cube.repository_manager != null) {
			cube.repository_manager.reset_all();
		}

		/* Initialize Statuses */
		initialize_flags();
		
		emitEvent("project-closed");
		return true;
	}

	public void thread_scan_repositories(bool status_file_only=false)
	{		
		run_thread ( ()=> {			
			if (!_flag_status_map["repository_scanning"])							
				scan_repositories (status_file_only);			
			return null;
		});
	}

	public void get_previous_query(out ArrayList<string> bkup_query, out int curr_index)
	{
		//TODO : This shouldn't be here :( But what can I do? Im so tired now :/
		//Backup Current Query
		bkup_query = new ArrayList<string>();
		curr_index = 0;
		if ( _curr_query != null )
		{
			curr_index = _curr_query.index;
			//Ensure that we are not backuping the main query (all packages), we have that already
			if ( _curr_query.query_type == PackageQueryType.SOME )
			{
				foreach ( Package p in _curr_query.current_package_list )
					bkup_query.add(p.name);
			}
		}
	}

	public void set_previous_query(ArrayList<string> bkup_query, int curr_index)
	{
		_query = new PackageQuery.package_map ( _cube.repository_manager.available_packages, PackageQueryType.ALL );
		
		//TODO : This shouldn't be here :( But what can I do? Im so tired now :/
		//Restore Current Query		
		if ( _curr_query != null )
		{			
			ArrayList<Package> restore_query = new ArrayList<Package>(Package.equals);
			//Ensure that we are not restoring the main query (all packages)
			if ( _curr_query.query_type == PackageQueryType.SOME )
			{
				foreach ( string name in bkup_query )
				{
					if ( _cube.repository_manager.available_packages.has_key(name) )						
						restore_query.add(_cube.repository_manager.available_packages[name]);
				}
				_curr_query = new PackageQuery.package_list(restore_query,PackageQueryType.SOME);				
			}
			//It must be the main query, just copy
			else
				_curr_query = _query;

			_curr_query.index = curr_index;
						
			bkup_query.clear();
			restore_query.clear();
		}
	}

	public bool scan_repositories(bool status_file_only=false)
	{
		change_system_status("repository_scanning",true);
		change_system_status("repository_scanned",false);

		emitEvent ("repository-scan-started");
		
		if ( !_flag_status_map["project_opened"] )
		{
			_err_message = "No opened project";
			change_system_status("repository_scanning", false);
			emitEvent ("repository-scan-failed", "{\"message\":\"%s\"}".printf(_err_message));
			
			return false;
		}

		/* Backup the current query */
		ArrayList<string> bkup_query;
		int index;
		get_previous_query(out bkup_query, out index);

		ulong handler = _cube.repository_manager.process_progress_changed.connect((message, current, max) => {
			emitEvent("repository-scan-progress", @"{\"message\":\"$message\", \"current\": $current, \"max\": $max}");
		});
		
		if ( status_file_only )
			_cube.scan_status_repository();
		else
			_cube.scan_repositories();

		_cube.repository_manager.disconnect(handler);

		/* Restore the previous query */
		set_previous_query(bkup_query, index);

		//Refresh marked packages after scan repositories
		refresh_marked_packages();

		//2 seconds Delay
		//Thread.usleep(2000000);

		emitEvent ("repository-scan-done");
		
		change_system_status("repository_scanning",false);
		change_system_status("repository_scanned",true);
		
		return true;
	}

	public bool thread_download_packages(ArrayList<Package> packages, string? main_package = null)
	{				
		if (_flag_status_map["package_downloading"])
			return false;

		return run_thread ( ()=> {
			download_packages(packages, main_package);
			return null;
		});		
	}
	
	public void download_packages(ArrayList<Package> packages, string? main_package = null)
	{
		change_system_status("package_downloading",true);
		
		_dl_status = new DownloadStatus();
		_dl_status.download_type = DownloadType.PACKAGE;
		_dl_status.packages = packages.to_array();
		_dl_status.status_type = new DownloadStatusType[packages.size];
		_dl_status.progress = new int[packages.size];
		_dl_status.transfer_rate = new string[packages.size];
		_dl_status.size = new string[packages.size];
		_dl_status.error_message = new string[packages.size];
		_dl_status.main_package = main_package;

		int overall_size = 0;
		int overall_size_progress = 0;
		int overall_size_percent = 0;

		string mode = "download-package";

		if (_dl_status.packages.length > 1 && main_package == null)
			mode = "download-package-bulk";

		foreach (Package p in _dl_status.packages)
			overall_size += int.parse(p.size);
		
		int overall_progress_success = 0;
		int overall_progress_failed = 0;

		int previous_percent = -1;
		ulong handler = _cube.download_item_status_changed.connect ( (index,type,dl) => {
			
			_dl_status.index = index;
			_dl_status.status_type[index] = type;
			_dl_status.progress[index] = dl.progress;
			_dl_status.transfer_rate[index] = dl.transfer_rate;
			_dl_status.size[index] = dl.size;
			_dl_status.error_message[index] = dl.error_message;

			if ( type == DownloadStatusType.FINISHED )
			{
				overall_progress_success++;
				overall_size_progress += int.parse(_dl_status.packages[index].size);
				overall_size_percent = (int)(((float)overall_size_progress / (float)overall_size) * 100.00);
				previous_percent = -1;
				
				_dl_status.status_type[index] = DownloadStatusType.FINISHED;
				_dl_status.overall_progress_success = (int)((((float)overall_progress_success)/(float)packages.size)*100.00);
			}
			else if ( type == DownloadStatusType.FAILED )
			{
				overall_progress_failed++;
				overall_size_progress += int.parse(_dl_status.packages[index].size);
				overall_size_percent = (int)(((float)overall_size_progress / (float)overall_size) * 100.00);
				
				_dl_status.status_type[index] = DownloadStatusType.FAILED;
				_dl_status.error_message[index] = dl.error_message;
				_dl_status.overall_progress_failed = (int)((((float)overall_progress_failed)/(float)packages.size)*100.00);
			}
			else
			{
				overall_size_percent = (int)(((float)(overall_size_progress + (int)((float)int.parse(_dl_status.packages[index].size) * ((float)dl.progress/100.00))) / (float)overall_size) * 100.00);
			}

			if (previous_percent != _dl_status.progress[index])
			{
				emitEvent (mode+"-progress", "{\"main_package\":\"%s\",\"package\":\"%s\", \"percent\":%d, \"overall_percent\":%d, \"size\":\"%s\", \"transfer_rate\":\"%s\"}".printf(main_package,_dl_status.packages[index].name,_dl_status.progress[index], overall_size_percent, SizeConverter.convert(_dl_status.size[index]), _dl_status.transfer_rate[index]));
				previous_percent = _dl_status.progress[index];
			}
		});

		if (main_package == null)
			main_package = "";

		emitEvent (mode+"-started","{\"main_package\":\"%s\"}".printf(main_package));

		//This also includes mark packages
		_cube.download_packages ( _dl_status.packages );

		emitEvent ("repository-scan-done");

		if ( _dl_status.overall_progress_failed == 0 )
		{
			_flag_result_map["download_success"] = "true";
			_flag_result_map["download_message"] = "Download Successful";
		}
		else
		{
			_flag_result_map["download_success"] = "false";
			_flag_result_map["download_mesage"] = "failed;Failed to download %d package(s).".printf(overall_progress_failed);			
		}

		change_system_status("package_downloading",false);	
		emitEvent (mode+"-done","{\"main_package\":\"%s\"}".printf(main_package));

		//Refresh marked packages after download
		refresh_marked_packages();

		

		//TODO: Clear Download Status

		_cube.disconnect(handler);		
	}

	public bool thread_download_repositories(string? ppa = null)
	{				
		return run_thread ( ()=> {					
			if (!_flag_status_map["repository_downloading"])
				download_repositories(ppa);
			return null;
		});
	}

	public void download_repositories(string? ppa = null)
	{
		change_system_status("repository_downloading",true);
		emitEvent ("download-repository-started");
		
		_dl_status = new DownloadStatus();
		_dl_status.download_type = DownloadType.REPOSITORY;	
		_dl_status.index = -1;

		int overall_progress_success = 0;
		int overall_progress_failed = 0;
		int overall_progress = 0;
		
		ulong handler = _cube.download_item_status_changed.connect ( (index,type,dl) => {			
			_dl_status.index = index;
			_dl_status.status_type[index] = type;
			_dl_status.progress[index] = dl.progress;
			_dl_status.transfer_rate[index] = dl.transfer_rate;
			_dl_status.error_message[index] = dl.error_message;
			_dl_status.size[index] = dl.size;

			if ( type == DownloadStatusType.FINISHED )
			{				
				overall_progress_success++;				
				_dl_status.status_type[index] = DownloadStatusType.FINISHED;
				_dl_status.overall_progress_success = (int)((((float)overall_progress_success)/(float)(cube.source_manager.sources.size-1))*100.00);
			}
			else if ( type == DownloadStatusType.FAILED )
			{
				overall_progress_failed++;				
				_dl_status.status_type[index] = DownloadStatusType.FAILED;
				_dl_status.error_message[index] = dl.error_message;
				_dl_status.overall_progress_failed = (int)((((float)overall_progress_failed)/(float)(cube.source_manager.sources.size-1))*100.00);
			}

			overall_progress = (int)(((float)(overall_progress_success + overall_progress_failed)/(float)_dl_status.sources.length) * 100.00);

			emitEvent ("download-repository-progress", 
			           "{\"repository\":\"%s\", \"size\":\"%s\", \"percent\":%d, \"overall_percent\":%d, \"transfer_rate\":\"%s\"} ".printf(
			           _dl_status.sources[index].name,
			           SizeConverter.convert(_dl_status.size[index]),
			           _dl_status.progress[index],
			           overall_progress,
			           _dl_status.transfer_rate[index]));
			           
			           
		});		
				
		ArrayList<Source> sources_to_download = new ArrayList<Source>();
		
		if ( ppa != null )
		{
			foreach ( Source s in _cube.source_manager.get_sources_from_ppa(ppa) )
				sources_to_download.add(s);
		}
		else
		{			
			foreach ( Source s in _cube.source_manager.sources )
			{
				if ( s.filename != "status")
					sources_to_download.add(s);
			}
		}

		_dl_status.sources = sources_to_download.to_array();
		_dl_status.status_type = new DownloadStatusType[_dl_status.sources.length];
		_dl_status.progress = new int[_dl_status.sources.length];
		_dl_status.transfer_rate = new string[_dl_status.sources.length];
		_dl_status.size = new string[_dl_status.sources.length];
		_dl_status.error_message = new string[_dl_status.sources.length];
		
		_cube.download_repositories(_dl_status.sources);

		if ( _dl_status.overall_progress_failed == 0 )
		{
			_flag_result_map["download_success"] = "true";
			_flag_result_map["download_message"] = "Download Successful";
		}
		else
		{
			_flag_result_map["download_success"] = "false";
			_flag_result_map["download_message"] = "Failed to download %d of %d repositories".printf(overall_progress_failed,(cube.source_manager.sources.size-1));
		}

		//2 seconds Delay
		//Thread.usleep(2000000);
		
		change_system_status("repository_downloading",false);
		emitEvent ("download-repository-done");

		_cube.disconnect(handler);

		//TODO: Clear Download Status

		//Scan Repositories after download
		scan_repositories();
	}

	public bool download_stop()
	{
		if ( _flag_status_map["repository_downloading"] || _flag_status_map["package_downloading"] )
		{			
			_cube.download_manager.stop();
			return true;
		}
		return false;
	}

	public bool thread_install_packages(ArrayList<Package> packages)
	{		
		return run_thread ( ()=> {
			if ( !flag_status_map["package_installing"] )
				install_packages(packages);
			return null;
		});
	}

	public bool install_packages(ArrayList<Package> packages)
	{
		ulong handler_started = cube.installation_manager.started.connect(()=>{			
			change_system_status("package_installing",true);
			emitEvent ("install-package-started");
		});

		ulong handler_finished = cube.installation_manager.finished.connect(()=>{
			_flag_result_map["install_success"] = "true";
			_flag_result_map["install_message"] = "Installation Successful";
			change_system_status("package_installing",false);
			emitEvent ("install-package-done");
		});

		ulong handler_failed = cube.installation_manager.failed.connect((message)=>{
			_flag_result_map["install_success"] = "false";
			_flag_result_map["install_message"] = message;
			change_system_status("package_installing",false);
			emitEvent ("install-package-failed","{\"message\":\"%s\"}".printf(message));
		});
		
		bool result = cube.install_packages(packages.to_array());		
		
		cube.installation_manager.disconnect(handler_started);
		cube.installation_manager.disconnect(handler_finished);	
		cube.installation_manager.disconnect(handler_failed);

		if (result) {
			/* Update project status and rescan repositories */
			result = cube.update_project();
			if(result)
				scan_repositories(true);
		}

		return result;
	}

	public bool thread_update_project()
	{		
		return run_thread ( ()=> {
			if ( !flag_status_map["project_updating"] )
				update_project();	
			return null;
		});
	}

	public bool update_project()
	{
		change_system_status("project_updating",true);
		emitEvent ("update-project-started");
		
		bool result = cube.update_project();

		if ( result )
		{
			_flag_result_map["update_project_success"] = "true";
			_flag_result_map["update_project_message"] = "Update project successful";
			emitEvent ("update-project-done");
		}
		else
		{
			_flag_result_map["update_project_success"] = "false";
			_flag_result_map["update_project_message"] = "Failed to update project";
			emitEvent ("update-project-failed","{\"message\":\"%s\"}".printf("Failed to update project"));
		}
		
		change_system_status("project_updating",false);

		/* Rescan status repositories */
		scan_repositories(true);
		
		//2 seconds Delay
		//Thread.usleep(2000000);
		
		return result;
	}

	public bool thread_update_system()
	{		
		return run_thread ( ()=> {
			if ( !flag_status_map["system_updating"] )
				update_system();
			return null;
		});
	}

	public bool update_system()
	{		
		change_system_status("system_updating",true);
		emitEvent ("update-system-started");
		
		bool result = cube.update_system();

		if ( result )
		{
			_flag_result_map["update_system_success"] = "true";
			_flag_result_map["update_system_message"] = "Update system successful";
			emitEvent ("update-system-done");
		}
		else
		{
			_flag_result_map["update_system_success"] = "false";
			_flag_result_map["update_system_message"] = "Failed to update system";
			emitEvent ("update-system-failed", "{\"message\":\"%s\"}".printf("Failed to update"));
		}
		
		change_system_status("system_updating",false);

		//2 seconds Delay
		//Thread.usleep(2000000);
		
		return result;
	}

	public void mark_package(MarkPackageType type, string name)
	{
		if ( type == MarkPackageType.TO_INSTALL )
		{
			if ( !_marked_to_install_packages.contains(name) && cube.repository_manager.available_packages.has_key(name) )
				_marked_to_install_packages.add(name);
		}
		else if ( type == MarkPackageType.TO_DOWNLOAD )
		{
			if ( !_marked_to_download_packages.contains(name) && cube.repository_manager.available_packages.has_key(name) )
				_marked_to_download_packages.add(name);
		}		
	}

	public void unmark_package(MarkPackageType type, string name)
	{
		if ( type == MarkPackageType.TO_INSTALL )
		{
			if ( _marked_to_install_packages.contains(name) )
				_marked_to_install_packages.remove(name);
		}
		else if ( type == MarkPackageType.TO_DOWNLOAD )
		{
			if ( _marked_to_download_packages.contains(name) )
				_marked_to_download_packages.remove(name);
		}		
	}

	public void clear_marked_packages(MarkPackageType type)
	{
		if ( type == MarkPackageType.TO_INSTALL )
			_marked_to_install_packages.clear();
		else if ( type == MarkPackageType.TO_DOWNLOAD )
			_marked_to_download_packages.clear();
	}

	public void refresh_marked_packages()
	{
		string[] marked = _marked_to_install_packages.to_array();
		
		for ( int i = 0; i < marked.length; i++ )
		{
			if ( _cube.repository_manager.available_packages[marked[i]].status == PackageStatusType.INSTALLED )
				_marked_to_install_packages.remove(marked[i]);			
		}

		marked = _marked_to_download_packages.to_array();

		for ( int i = 0; i < marked.length; i++ )
		{
			if ( _cube.repository_manager.available_packages[marked[i]].status == PackageStatusType.DOWNLOADED )
				_marked_to_download_packages.remove(marked[i]);
		}
	}

	public bool run_thread(owned ThreadFunc<void*> run)
	{
		try
		{
			/*unowned Thread<void*> thread = */Thread.create<void*>(run,true);
		}
		catch ( Error e )
		{
			stdout.printf("Error : %s\n",e.message);
			return false;
		}
		return true;
	}
}