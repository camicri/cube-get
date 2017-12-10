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

public class ServerCommandConfiguration : GLib.Object, RouterClass {

	public TreeMap<string, RouterHandler> mappings {get; set; default = new TreeMap<string, RouterHandler>();}

	public ServerCommandConfiguration()
	{
		register("/cmd/configuration/get-configuration-entries", cmd_get_configuration_entries);
		register("/cmd/configuration/save-configuration-entries", cmd_save_configuration_entries);
		register("/cmd/configuration/reset-configuration-entries", cmd_reset_configuration_entries);
		register("/cmd/configuration/open-sources-list-file", cmd_open_sources_list_file);
	}
	 
    public void cmd_get_configuration_entries (Request req, Response res)
	{
		string json = """ """;
		string config_entry = """ "%s" : "%s" """;

		int index = 0;
		foreach ( string key in req.css.cube.base_manager.main_configuration_file.configuration_map.keys )
		{
			string val = req.css.cube.base_manager.main_configuration_file.configuration_map[key];
			
			json += (index>0?",":"") + config_entry.printf(key.replace("-","_"),val);

			index++;
		}

		res.send((" { " + json + " } "));
	}

	public void cmd_reset_configuration_entries (Request req, Response res) {
		string json = """ { "success" : %s, "message" : "%s" } """;

		bool result = req.css.cube.base_manager.reset_configuration_files();

		res.send(json.printf(result.to_string(),result?"Configuration Reset":"Failed to reset configuration")); 
	}

	public void cmd_save_configuration_entries (Request req, Response res)
	{
		string json = """ { "success" : %s, "message" : "%s" } """;

		foreach ( string key in req.query.get_keys() )
		{
			string config_key = key.replace("_","-");

			if ( req.css.cube.base_manager.main_configuration_file.configuration_map.has_key(config_key) )
			{				
				string val = req.query[key];				
				if ( !req.css.cube.base_manager.main_configuration_file.set_value(config_key,val) )
				{
					res.send(json.printf("false","Failed to set configuration entry for '"+config_key+"'"));
					return;
				}
			}
		}

		bool result = req.css.cube.base_manager.main_configuration_file.save_configuration();

		if ( result )
		{
			if ( !req.css.cube.base_manager.main_configuration_file.open_configuration() )
				json = json.printf("false","Failed to re-open configuration file");
			else
				json = json.printf("true","Configuration Saved");
		}
		else
			json = json.printf("false","Failed to save configuraiton changes");

		res.send(json);
	}

	public void cmd_open_sources_list_file (Request req, Response res)
	{
		string json = """ { "success" : "%s", "message" : "%s" } """ ;		
		
		if ( SystemInformation.get_operating_system_type() == OperatingSystemType.LINUX )
			ProcessManager.run_get_status ({"gedit",req.css.cube.project.sources_list_file});
		else if ( SystemInformation.get_operating_system_type() == OperatingSystemType.WINDOWS )
			ProcessManager.run_get_status ({"explorer",req.css.cube.project.sources_list_file});

		json = json.printf("true","");
		
		res.send(json);
	}
}
