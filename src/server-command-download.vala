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

public class ServerCommandDownload : GLib.Object, RouterClass {

	public TreeMap<string, RouterHandler> mappings {get; set; default = new TreeMap<string, RouterHandler>();}
	 
	public ServerCommandDownload()
	{
		register("/cmd/download/download-package", download_package);
		register("/cmd/download/download-marked-packages", download_marked_packages);
		register("/cmd/download/download-repository", download_repository);
		register("/cmd/download/stop-download", download_stop);
		register("/cmd/download/get-download-package-result", get_download_package_result);
		register("/cmd/download/get-download-repository-result", get_download_repository_result);
		register("/cmd/download/get-download-status", get_download_status);
	}

	public void download_package (Request req, Response res)
	{
		string json = """ { "success" : "%s" , "message" : "%s" } """;
		string? main_package = null;

		if ( req.css.flag_status_map["package_downloading"] || req.css.flag_status_map["repository_downloading"])
		{
			res.send(json.printf("false","Ongoing Download"));
			return;
		}

		string[] packages = null;		

		if ( req.query.contains("package") )
		{		
			if ( req.query["package"].contains(";") )
				packages = req.query["package"].split(";",-1);
			else
			{
				packages = new string[]{req.query["package"]};
				main_package = req.query["package"];
			}
		}
		else
		{
			res.send(json.printf("false",""));
			return;
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

		bool result = req.css.thread_download_packages(unsatisfied_dependencies,main_package);
		
		res.send(json.printf(result.to_string(),"Download Started"));
	}

	public void download_marked_packages(Request req, Response res)
	{
		string json = """ { "success" : "%s" , "message" : "%s" } """;
		string package_list = "";

		if (req.css.marked_to_download_packages.size == 0) {
			res.send(json.printf("false","No marked packages"));
		}
		
		foreach(string name in req.css.marked_to_download_packages) {
			package_list += name + ";";
		}

		req.query["package"] = package_list;

		download_package(req, res);
	}

	public void download_repository (Request req, Response res)
	{
		string json = """ { "success" : "%s" , "message" : "%s" } """;		
		string? ppa = null;

		if ( req.css.flag_status_map["package_downloading"] || req.css.flag_status_map["repository_downloading"])
		{
			res.send(json.printf("false","Ongoing Download"));
			return;
		}

		if ( req.query.contains("ppa") )
			ppa = req.query["ppa"];
		
		bool result = req.css.thread_download_repositories(ppa);
		
		res.send(json.printf(result.to_string(),"Download Started"));
	}

	public void download_stop (Request req, Response res)
	{
		string json = """ { "success" : "%s" , "message" : "%s" } """;		

		bool result = req.css.download_stop();
		
		res.send(json.printf(result.to_string(),"Download Stopped"));
	}

	public void get_download_status (Request req, Response res)
	{
		string json = """ { "current_index" : "%d", "current_item" : "%s" , "current_size" : "%s" ,"current_progress" : "%d", "current_transfer_rate" : "%s" , "overall_progress_success" : "%d" , "overall_progress_failed" : "%d" , "max_count" : "%d" } """;

		if ( req.css.download_status == null )
		{
			res.send("");
			return;
		}

		if ( req.css.download_status.index == -1 )
		{
			res.send("");
			return;
		}
		
		if ( req.css.download_status.download_type == DownloadType.PACKAGE )
		{			
			json = json.printf(
			            req.css.download_status.index + 1 ,
			            req.css.download_status.packages[req.css.download_status.index].name,
			            SizeConverter.convert(req.css.download_status.packages[req.css.download_status.index].size),
				        req.css.download_status.progress[req.css.download_status.index],
			            req.css.download_status.transfer_rate[req.css.download_status.index],
				        req.css.download_status.overall_progress_success,
			            req.css.download_status.overall_progress_failed,
			            req.css.download_status.packages.length
				        );
		}
		else
		{			
			
			string repo_name = req.css.download_status.sources[req.css.download_status.index].ppa + " "  
				+ req.css.download_status.sources[req.css.download_status.index].release + " "
				+ req.css.download_status.sources[req.css.download_status.index].component;

			json = json.printf(
			            req.css.download_status.index + 1,
			                   repo_name,			            
			            SizeConverter.convert(req.css.download_status.size[req.css.download_status.index]),
				        req.css.download_status.progress[req.css.download_status.index],
			            req.css.download_status.transfer_rate[req.css.download_status.index],
				        req.css.download_status.overall_progress_success,
			            req.css.download_status.overall_progress_failed,
			            req.css.download_status.sources.length
			);
		}

		if ( json != null )
			res.send(json);
		else
			res.send("");
	}

	public void get_download_package_result (Request req, Response res)
	{
		string json = """ { "success" : [%s] , "failed" : [%s] } """;
		string success = "";
		string failed = "";
		string download_item = """ { "name" : "%s" , "size" : "%s" , "error_message" : "%s" } """;		

		if ( req.css.download_status == null )
		{
			res.send(json.printf("",""));
			return;
		}
		if ( req.css.download_status.packages == null )
		{
			res.send(json.printf("",""));
			return;
		}

		for ( int i = 0; i < req.css.download_status.packages.length; i++ )
		{
			string name = req.css.download_status.packages[i].name;
			string size = SizeConverter.convert(req.css.download_status.size[i]);
			string error_message = req.css.download_status.error_message[i];
			
			if ( req.css.download_status.status_type[i] == DownloadStatusType.FINISHED )
				success += (success!=""?",":"") + download_item.printf(name,size,error_message!=null?error_message:"");
			else
				failed += (failed!=""?",":"") + download_item.printf(name,size,error_message!=null?error_message:"");
		}

		res.send(json.printf(success,failed));
	}

	public void get_download_repository_result (Request req, Response res)
	{
		string json = """ { "success" : [%s] , "failed" : [%s] } """;
		string success = "";
		string failed = "";
		string download_item = """ { "name" : "%s" , "size" : "%s" , "error_message" : "%s" } """;		

		if ( req.css.download_status == null )
		{
			res.send(json.printf("",""));
			return;
		}
		if ( req.css.download_status.sources == null )
		{
			res.send(json.printf("",""));
			return;
		}
		
		for ( int i = 0; i < req.css.download_status.sources.length; i++ )
		{
			string name = req.css.download_status.sources[i].ppa + " "  
				+ req.css.download_status.sources[i].release + " "
				+ req.css.download_status.sources[i].component;
						
			string size = SizeConverter.convert(req.css.download_status.size[i]);
			string error_message = req.css.download_status.error_message[i];
				
			if ( req.css.download_status.status_type[i] == DownloadStatusType.FINISHED )
				success += (success!=""?",":"") + download_item.printf(name,size,error_message!=null?error_message:"");
			else
				failed += (failed!=""?",":"") + download_item.printf(name,size,error_message!=null?error_message:"");
		}

		res.send(json.printf(success,failed));
	}
}
