/* -*- Mode: vala; tab-width: 4; intend-tabs-mode: t -*- */
/* cube-server
 *
 * Copyright (C) Jake R. Capangpangan 2015 <camicrisystems@gmail.com>
 *
cube-server is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the
 * Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * cube-server is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along
 * with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

using Gee;

public class ServerCommandRepository : GLib.Object, RouterClass {

	public TreeMap<string, RouterHandler> mappings {get; set; default = new TreeMap<string, RouterHandler>();}

	public ServerCommandRepository()
	{
		register("/cmd/repository/scan-repositories", scan_repositories);
		register("/cmd/repository/get-main-lists", get_main_lists);
		register("/cmd/repository/get-sections", get_sections);
		register("/cmd/repository/get-section-packages", get_section_packages);
		register("/cmd/repository/get-available-packages", get_available_packages);
		register("/cmd/repository/get-installed-packages", get_installed_packages);
		register("/cmd/repository/get-upgradable-packages",  get_upgradable_packages);
		register("/cmd/repository/get-downloaded-packages", get_downloaded_packages);
		register("/cmd/repository/get-cleanup-packages", get_cleanup_packages);
		register("/cmd/repository/get-package-dependencies",  get_package_dependencies);
		register("/cmd/repository/get-satisfied-downloaded-packages", get_satisfied_downloaded_packages);
		register("/cmd/repository/get-next", get_next);
		register("/cmd/repository/get-previous", get_previous);
		register("/cmd/repository/find-package", find_package);
		register("/cmd/repository/find-package-starts-with", find_package_starts_with);
		register("/cmd/repository/get-marked-packages", get_marked_packages);
		register("/cmd/repository/mark-package", mark_package);
		register("/cmd/repository/unmark-package", unmark_package);
	}
	 
	public void scan_repositories (Request req, Response res)
	{		
		string json = """ { "success" : "%s" , "message" : "%s" } """;
		bool status_file_only = false;

		if ( req.css.flag_status_map["repository_scanning"] )
		{
			res.send(json.printf("false","Ongoing Repository Scan"));
			return;
		}

		if ( req.query.contains("mode") )
		{
			//stdout.printf("Status file scan only\n");
			if ( req.query["mode"] == "status-file-only" )
				status_file_only = true;
		}
		
		req.css.thread_scan_repositories(status_file_only);
		res.send(json.printf("true","Scan repository thread started"));
	}	
	
	public void get_main_lists (Request req, Response res)
	{
		string json = """ """;

		string main_list_item = """{ "name" : "%s" , "description" : "%s" , "count" : %d }""";

		json += main_list_item.printf("available","Available",req.css.cube.repository_manager.available_packages.size) + ",";
		json += main_list_item.printf("installed","Installed",req.css.cube.repository_manager.installed_packages.size) + ",";
		json += main_list_item.printf("upgradable","Upgradable",req.css.cube.repository_manager.upgradable_package_names.size) + ",";
		json += main_list_item.printf("downloaded","Downloaded",req.css.cube.repository_manager.downloaded_package_names.size) + ",";		
		json += main_list_item.printf("marked-to-download","Marked for Download",req.css.marked_to_download_packages.size) + ",";
		json += main_list_item.printf("marked-to-install","Marked for Installation",req.css.marked_to_install_packages.size);
		
		res.send(("[" + json + "]"));
	}

	

	public void get_sections (Request req, Response res)
	{
		string json = """ """;

		string section_item = """{ "name" : "%s" , "description" : "%s" , "count" : %d }""";

		int index = 0;
		foreach ( string key in req.css.cube.repository_manager.section_map.keys )
		{
			int count = req.css.cube.repository_manager.section_map[key].size;
			string description = req.css.cube.base_manager.section_configuration_file.get_value(key);
			json += ((index>0)?",":"") + section_item.printf(key,description,count);
			index++;
		}

		res.send(("[" + json + "]"));
	}



	public void get_next (Request req, Response res)
	{
		string json = """ """;
		string package_item = """ { "name" : "%s", "version" : "%s", "description" : "%s", "status" : "%s", "section" : "%s", "size" : "%s", "marked" : %s } """;

		ArrayList<Package> packages = new ArrayList<Package>(Package.equals);
		int count = 10;

		if ( !req.query.contains("type") )
		{
			res.send(json);
			return;
		}

		if ( req.query.contains("count") )
			count = int.parse(req.query["count"]);
		else
			count = 10;
		
		switch ( req.query["type"] )
		{
			case "main" :
				packages = req.css.package_query.next(count);
				break;
			case "current" :				
				packages = req.css.current_query.next(count);
				break;
		}

		int index = 0;
		bool marked = false;
		foreach ( Package p in packages )
		{
			if ( p.status == PackageStatusType.DOWNLOADED )
				req.css.marked_to_install_packages.contains(p.name)?marked=true:marked=false;
			else if ( p.status != PackageStatusType.INSTALLED )
				req.css.marked_to_download_packages.contains(p.name)?marked=true:marked=false;
			
			json += ((index>0)?",":"") + package_item.printf(p.name,p.version,p.description.replace("\\","\\\\").replace("\"","\\\""),get_package_status_string(p),p.section,SizeConverter.convert(p.size),marked.to_string());
			index++;
		}

		res.send(("[" + json + "]"));
	}


	
	public void get_previous (Request req, Response res)
	{
		string json = """ """;
		string package_item = """ { "name" : "%s", "version" : "%s", "description" : "%s", "status" : "%s", "section" : "%s", "size" : "%s", "marked" : %s } """;

		ArrayList<Package> packages = new ArrayList<Package>(Package.equals);
		int count = 10;

		if ( !req.query.contains("type") )
		{
			res.send(json);
			return;
		}

		if ( req.query.contains("count") )
			count = int.parse(req.query["count"]);
		else
			count = 10;
		
		switch ( req.query["type"] )
		{
			case "main" :
				packages = req.css.package_query.previous(count);
				break;
			case "current" :
				packages = req.css.current_query.previous(count);
				break;
		}

		int index = 0;
		bool marked = false;
		foreach ( Package p in packages )
		{
			if ( p.status == PackageStatusType.DOWNLOADED )
				req.css.marked_to_install_packages.contains(p.name)?marked=true:marked=false;
			else if ( p.status != PackageStatusType.INSTALLED )
				req.css.marked_to_download_packages.contains(p.name)?marked=true:marked=false;
			
			json += ((index>0)?",":"") + package_item.printf(p.name,p.version,p.description.replace("\\","\\\\").replace("\"","\\\""),get_package_status_string(p),p.section,SizeConverter.convert(p.size),marked.to_string());
			index++;
		}

		res.send(("[" + json + "]"));
	}
	
	
	public void get_section_packages (Request req, Response res)
	{
		if ( ! req.css.cube.repository_manager.section_map.has_key( req.query["section"] ) )
		{
		    res.send("");
			return;
		}

		req.css.current_query = new PackageQuery.package_list (req.css.cube.repository_manager.section_map[req.query["section"]],PackageQueryType.SOME);
		req.css.current_query.index = 0;

		req.query["type"] = "current";
		req.query["count"] = "20";
		
		get_next (req, res);
	}
	
	
	
	public void get_available_packages (Request req, Response res)
	{
		req.css.current_query = req.css.package_query;
		req.css.current_query.index = 0;

		req.query["type"] = "current";
		req.query["count"] = "20";
		
		get_next (req, res); 
	}


	
	public void get_installed_packages (Request req, Response res)
	{
		req.css.current_query = new PackageQuery.package_map (req.css.cube.repository_manager.installed_packages,PackageQueryType.SOME);
		req.css.current_query.index = 0;

		req.query["type"] = "current";
		req.query["count"] = "20";
		
		get_next (req, res); 
	}


	
	public void get_upgradable_packages (Request req, Response res)
	{
		ArrayList<Package> upgradable_packages = new ArrayList<Package>(Package.equals);
		foreach ( string name in req.css.cube.repository_manager.upgradable_package_names )
			upgradable_packages.add(req.css.cube.repository_manager.available_packages[name]);

		req.css.current_query = new PackageQuery.package_list ( upgradable_packages, PackageQueryType.SOME );
		req.css.current_query.index = 0;

		req.query["type"] = "current";
		req.query["count"] = "20";
		
		get_next (req, res); 
	}


	
	public void get_downloaded_packages (Request req, Response res)
	{
		ArrayList<Package> downloaded_packages = new ArrayList<Package>(Package.equals);
		foreach ( string name in req.css.cube.repository_manager.downloaded_package_names )
			downloaded_packages.add(req.css.cube.repository_manager.available_packages[name]);

		req.css.current_query = new PackageQuery.package_list ( downloaded_packages, PackageQueryType.SOME );
		req.css.current_query.index = 0;

		req.query["type"] = "current";
		req.query["count"] = "20";
		
		get_next (req, res); 
	}

	public void get_cleanup_packages (Request req, Response res)
	{
		string json = """ { "cleanup" : [%s], "cleanup_size" : "%s" } """;
		string package_item = """ { "name" : "%s", "version" : "%s", "description" : "%s", "status" : "%s", "section" : "%s", "size" : "%s" } """;

		string cleanup_items = "";
		double cleanup_size = 0;
		
		int index = 0;		
		foreach ( string name in req.css.cube.repository_manager.cleanup_package_names )
		{
			if ( !req.css.cube.repository_manager.available_packages.has_key(name) )
				continue;
			
			Package p = req.css.cube.repository_manager.available_packages[name];
			cleanup_items += ((index>0)?",":"") + package_item.printf(p.name,p.version,p.description.replace("\\","\\\\").replace("\"","\\\""),get_package_status_string(p),p.section,SizeConverter.convert(p.size));
			cleanup_size += double.parse(p.size);

			index++;
		}

		res.send(json.printf(cleanup_items,SizeConverter.convert(cleanup_size.to_string())));
	}

	public void get_package_dependencies (Request req, Response res)
	{
		string json = """ { "satisfied" : [ %s ] , "unsatisfied" : [ %s ] , "satisfied_size" : "%s", "unsatisfied_size" : "%s", "overall_size" : "%s" }""";
		string package_item = """ { "name" : "%s", "version" : "%s", "description" : "%s", "status" : "%s", "section" : "%s", "size" : "%s" } """;

		string satisfied_package_items = "";
		string unsatisfied_package_items = "";
		double satisfied_package_items_size = 0;
		double unsatisfied_package_items_size = 0;

		string[] packages = null;		

		if ( req.query.contains("package") )
		{		
			if ( req.query["package"].contains(";") )
				packages = req.query["package"].split(";",-1);
			else
				packages = new string[]{req.query["package"]};
		}

		if ( req.query.contains("type") )
		{
			if ( req.query["type"] == "all-marked-to-download" )
				packages = req.css.marked_to_download_packages.to_array();
			else if ( req.query["type"] == "all-marked-to-install" )
				packages = req.css.marked_to_install_packages.to_array();
		}		

		ArrayList<Package> pkgs = new ArrayList<Package>(Package.equals);
		foreach ( string name in packages )
		{
			if ( req.css.cube.repository_manager.available_packages.has_key(name) )
			{
				Package p = req.css.cube.repository_manager.available_packages[name];
				if ( !pkgs.contains(p) )
					pkgs.add(p);
			}
		}

		ArrayList<Package> unsatisfied_dependencies = new ArrayList<Package>(Package.equals);
		ArrayList<Package> satisfied_dependencies = new ArrayList<Package>(Package.equals);

		req.css.cube.get_packages_dependencies(pkgs, unsatisfied_dependencies, satisfied_dependencies);

		int index = 0;
		foreach ( Package p in unsatisfied_dependencies )
		{
			unsatisfied_package_items += ((index>0)?",":"") + package_item.printf(p.name,p.version,p.description.replace("\\","\\\\").replace("\"","\\\""),get_package_status_string(p),p.section,SizeConverter.convert(p.size));
			unsatisfied_package_items_size += double.parse(p.size);
			index++;
		}

		index = 0;
		foreach ( Package p in satisfied_dependencies )
		{
			satisfied_package_items += ((index>0)?",":"") + package_item.printf(p.name,p.version,p.description.replace("\\","\\\\").replace("\"","\\\""),get_package_status_string(p),p.section,SizeConverter.convert(p.size));
			satisfied_package_items_size += double.parse(p.size);
			index++;
		}
		
		res.send(json.printf(
		                   satisfied_package_items,
		                   unsatisfied_package_items,
		                   SizeConverter.convert(satisfied_package_items_size.to_string()),
		                   SizeConverter.convert(unsatisfied_package_items_size.to_string()),
		                   SizeConverter.convert((satisfied_package_items_size+unsatisfied_package_items_size).to_string())
		                   ));
	}

	public void get_satisfied_downloaded_packages(Request req, Response res)
	{
		string json = """ """;
		string package_item = """ { "name" : "%s", "version" : "%s", "description" : "%s", "status" : "%s", "section" : "%s", "size" : "%s" } """;

		ArrayList<Package> satisfied_downloaded_packages = new ArrayList<Package>(Package.equals);
		foreach ( string name in req.css.cube.repository_manager.downloaded_package_names)
		{
			Package p = req.css.cube.repository_manager.available_packages[name];
			ArrayList<Package> unsatisfied_dependencies = new ArrayList<Package>(Package.equals);
			
			req.css.cube.get_package_dependencies(p,unsatisfied_dependencies);

			if ( unsatisfied_dependencies.size == 0 )
				satisfied_downloaded_packages.add(p);
		}

		satisfied_downloaded_packages.sort(Package.compare_function);

		int index = 0;
		foreach ( Package p in satisfied_downloaded_packages )
		{
			json += ((index>0)?",":"") + package_item.printf(p.name,p.version,p.description.replace("\\","\\\\").replace("\"","\\\""),get_package_status_string(p),p.section,SizeConverter.convert(p.size));
			index++;
		}

		res.send((" [ " + json + " ] "));
	}

	
	public void find_package (Request req, Response res)
	{
		string json = """ """;

		string package_item = """ { "name" : "%s", "version" : "%s", "description" : "%s", "status" : "%s", "section" : "%s", "size" : "%s", "marked" : %s } """;

		string[] packages;
		if ( req.query["package"].contains(";") )
			packages = req.query["package"].split(";",-1);
		else
			packages = new string[]{req.query["package"]};

		bool first = true;
		bool marked = false;
		foreach ( string name in packages )
		{
			Package p = req.css.package_query.find_package ( name );
			if ( p != null )
			{
				if ( p.status == PackageStatusType.DOWNLOADED )
					req.css.marked_to_install_packages.contains(p.name)?marked=true:marked=false;
				else if ( p.status != PackageStatusType.INSTALLED )
					req.css.marked_to_download_packages.contains(p.name)?marked=true:marked=false;
				
				json += (first?"":",") + package_item.printf(p.name,p.version,p.description.replace("\\","\\\\").replace("\"","\\\""),get_package_status_string(p),p.section,SizeConverter.convert(p.size),marked.to_string());
				first = false;
			}
		}		
		
		res.send(("[" + json + "]"));
	}


	
	public void find_package_starts_with (Request req, Response res)
	{
		string json = """ """;

		string package_item = """ { "name" : "%s", "version" : "%s", "description" : "%s", "status" : "%s", "section" : "%s", "size" : "%s", "marked" : %s } """;

		int index = 0;
		req.css.current_query.index = 0;

		bool marked = false;
		foreach ( Package p in req.css.current_query.find_starts_with ( req.query["package"] , 20 ) )
		{
			if ( p.status == PackageStatusType.DOWNLOADED )
				req.css.marked_to_install_packages.contains(p.name)?marked=true:marked=false;
			else if ( p.status != PackageStatusType.INSTALLED )
				req.css.marked_to_download_packages.contains(p.name)?marked=true:marked=false;
			
			json += ((index>0)?",":"") + package_item.printf(p.name,p.version,p.description.replace("\\","\\\\").replace("\"","\\\""),get_package_status_string(p),p.section,SizeConverter.convert(p.size),marked.to_string());
			index++;
		}

		res.send(("[" + json + "]"));
	}

	public void get_marked_packages (Request req, Response res)
	{	
		string json = """ """;
		string package_item = """ { "name" : "%s", "version" : "%s", "description" : "%s", "status" : "%s", "section" : "%s", "size" : "%s", "marked" : %s } """;
		
		if ( !req.query.contains("type") )
		{
			res.send("");
			return;
		}

		ArrayList<string> package_name_list = new ArrayList<string>();
		ArrayList<Package> marked_packages = new ArrayList<Package>(Package.equals);
		
		if ( req.query["type"] == "to-install" )
			package_name_list = req.css.marked_to_install_packages;
		else if ( req.query["type"] == "to-download" )
			package_name_list = req.css.marked_to_download_packages;

		foreach ( string name in package_name_list )
			marked_packages.add(req.css.cube.repository_manager.available_packages[name]);				

		//Override for get next
		req.query["type"] = "current";
		if ( !req.query.contains("count") )
			req.query["count"] = "20";
		else if ( req.query["count"] == "-1" ) //All packages, don't change package query
		{
			int index = 0;
			bool marked = false;
			foreach ( Package p in marked_packages )
			{
				if ( p.status == PackageStatusType.DOWNLOADED )
					req.css.marked_to_install_packages.contains(p.name)?marked=true:marked=false;
				else if ( p.status != PackageStatusType.INSTALLED )
					req.css.marked_to_download_packages.contains(p.name)?marked=true:marked=false;
			
				json += ((index>0)?",":"") + package_item.printf(p.name,p.version,p.description.replace("\\","\\\\").replace("\"","\\\""),get_package_status_string(p),p.section,SizeConverter.convert(p.size),marked.to_string());
				index++;
			}

			res.send( ("[" + json + "]"));
			return;
		}

		if ( req.query["count"] != "-1" )
		{
			req.css.current_query = new PackageQuery.package_list ( marked_packages, PackageQueryType.SOME );
			req.css.current_query.index = 0;
		}
		
		get_next (req, res); 
	}	

	public void mark_package (Request req, Response res)
	{
		string json = """ { "success" : "%s", "message" : "%s" } """;

		if ( !req.query.contains("type") )
		{
			res.send(json.printf("false",""));
			return;
		}

		string?[] packages = null;
		MarkPackageType? type = null;
		
		if ( req.query["type"] == "all-downloaded" )
		{
			type = MarkPackageType.TO_INSTALL;
			packages = req.css.cube.repository_manager.downloaded_package_names.to_array();
		}
		else if ( req.query["type"] == "all-upgradable" )
		{
			type = MarkPackageType.TO_DOWNLOAD;
			packages = req.css.cube.repository_manager.upgradable_package_names.to_array();
		}
		else if ( req.query["type"] == "to-install" )
		{
			type = MarkPackageType.TO_INSTALL;
			if ( req.query.contains("package") )
			{
				if ( req.query["package"].contains(";") )
					packages = req.query["package"].split(";",-1);
				else
					packages = new string[]{ req.query["package"] };
			}
		}
		else if ( req.query["type"] == "to-download" )
		{
			type = MarkPackageType.TO_DOWNLOAD;
			if ( req.query.contains("package") )
			{
				if ( req.query["package"].contains(";") )
					packages = req.query["package"].split(";",-1);
				else
					packages = new string[]{ req.query["package"] };
			}
		}
		else
			json = json.printf("false","");

		if ( packages != null )
		{
			foreach ( string name in packages )
				req.css.mark_package(type,name);
			json = json.printf("true","");
		}
		else
			json = json.printf("false","");
		
		res.send(json);
	}

	public void unmark_package (Request req, Response res)
	{
		string json = """ { "success" : "%s", "message" : "%s" } """;

		if ( !req.query.contains("type") )
		{
			res.send(json.printf("false",""));
			return;
		}

		if ( req.query["type"] == "all-to-download" )
		{
			req.css.clear_marked_packages(MarkPackageType.TO_DOWNLOAD);
			json = json.printf("true","");
		}
		else if ( req.query["type"] == "all-to-install" )
		{
			req.css.clear_marked_packages(MarkPackageType.TO_INSTALL);
			json = json.printf("true","");
		}
		else if ( req.query["type"] == "to-install" )
		{
			if ( req.query.contains("package") )
			{
				req.css.unmark_package(MarkPackageType.TO_INSTALL,req.query["package"]);
				json = json.printf("true","");
			}
			else
				json = json.printf("false","");
		}
		else if ( req.query["type"] == "to-download" )
		{
			if ( req.query.contains("package") )
			{
				req.css.unmark_package(MarkPackageType.TO_DOWNLOAD,req.query["package"]);
				json = json.printf("true","");
			}
			else
				json = json.printf("false","");
		}
		else
			json = json.printf("false","");

		res.send(json);
	}
	
	private static string get_package_status_string ( Package p )
	{
		switch ( p.status )
		{
			case PackageStatusType.AVAILABLE : return "Available";
			case PackageStatusType.INSTALLED : return "Installed";
			case PackageStatusType.DOWNLOADED : return "Downloaded";
			case PackageStatusType.UPGRADABLE : return "Upgradable";
		}

		return "";
	}
	
}