/* -*- Mode: vala; tab-width: 4; intend-tabs-mode: t -*- */
/* cube-server
 *
 * Copyright (C) Jake R. Capangpangan 2015 <camicrisystem@gmail.com>
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

public interface RouterClass : Object
{
	public abstract TreeMap<string, RouterHandler> mappings { get; set; default = new TreeMap<string, RouterHandler>();}
	public void register(string location, Handler handler) 
	{
		this.mappings[location] = new RouterHandler(handler);
	}
}

public class ServerCommandSystem : GLib.Object, RouterClass {

	public TreeMap<string, RouterHandler> mappings  { get; set; default = new TreeMap<string, RouterHandler>();}

	public ServerCommandSystem()
	{
		register("/cmd/system/get-environment-data", cmd_get_environment_data);
		register("/cmd/system/get-cube-data", cmd_get_cube_data);
		register("/cmd/system/get-status", cmd_get_status);
		register("/cmd/system/get-result", cmd_get_result);
	}

	public void cmd_get_environment_data (Request req, Response res)
	{
		string json = """ { "operating_system" : "%s", "original_computer" : %s }  """;
		string os = "UNKNOWN";
		string original = "false";
		
		if ( SystemInformation.get_operating_system_type () == OperatingSystemType.LINUX )
			os = "LINUX";
		else if ( SystemInformation.get_operating_system_type () == OperatingSystemType.WINDOWS )
			os = "WINDOWS";
		
		if ( req.css.cube.project != null && os == "LINUX" )
		{
			if ( req.css.cube.project.is_original_computer )
				original = "true";		
		}

		res.send(json.printf(os,original));
	}	

	public void cmd_get_cube_data (Request req, Response res)
	{		
		string json = """ { "application_name" : "%s", "application_version" : "%s", "application_revision" : "%s", "description" : "%s", "short_description" : "%s", "authors" : [%s], "translators" : [%s], "launchpad_url" : "%s", "facebook_url" : "%s", "documentation_url" : "%s", "license" : "%s" } """;
		string authors = "";
		string translators = "";

		int index = 0;
		foreach ( string author in CubeInformation.authors )
		{
			authors += (index!=0?",":"") + """ { "name" : "%s" } """.printf(author);
			index ++;
		}

		index = 0;
		foreach ( string translator in CubeInformation.translators )
		{
			translators += (index!=0?",":"") + """ { "name" : "%s" } """.printf(translator);
			index++;
		}

		res.send(json.printf(
                   CubeInformation.application_name,
                   CubeInformation.application_version,
                   CubeInformation.application_revision,
                   CubeInformation.description,
                   CubeInformation.short_description,
                   authors,
                   translators,
                   CubeInformation.launchpad_url,
                   CubeInformation.facebook_url,
		           CubeInformation.documentation_url,
                   CubeInformation.license)
		         );
	}
	
	public void cmd_get_status (Request req, Response res)
	{
		string json = "";

		string status_item = """"%s" : %s """; 
		string system_status = """"system" : {%s} """;
		string? download_status = """"download" : {%s} """;

		//Check for system status
		int index = 0;
		foreach ( string key in req.css.flag_status_map.keys )
		{			
			json += ((index>0)?",":"") + status_item.printf(key,req.css.flag_status_map[key].to_string());
			index++;
		}

		json = system_status.printf(json);

		
		//Check for download status
		if ( req.css.flag_status_map["package_downloading"] || req.css.flag_status_map["repository_downloading"] )
		{
			string download_json = """"current_index" : "%d", "current_item" : "%s" , "current_size" : "%s" ,"current_progress" : "%d", "current_transfer_rate" : "%s" , "overall_progress_success" : "%d" , "overall_progress_failed" : "%d" , "max_count" : "%d" """;

			if ( req.css.download_status != null )
			{				
				if ( req.css.download_status.index != -1 )
				{
		
					if ( req.css.download_status.download_type == DownloadType.PACKAGE )
					{			
						download_json = download_json.printf(
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

						download_json = download_json.printf(
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

					json = json + "," + download_status.printf(download_json);
				}
			}
		}		

		res.send("{ " + json + " }");
	}

	public void cmd_get_result (Request req, Response res)
	{
		string json = "";

		string status_item = """"%s" : %s """; 

		int index = 0;
		foreach ( string key in req.css.flag_result_map.keys )
		{			
			json += ((index>0)?",":"") + status_item.printf(key,req.css.flag_result_map[key]);
			index++;
		}

		res.send("{ " + json + " }");
	}
}
