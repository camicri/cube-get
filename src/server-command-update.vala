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

public class ServerCommandUpdate : GLib.Object, RouterClass {

	public TreeMap<string, RouterHandler> mappings {get; set; default = new TreeMap<string, RouterHandler>();}

	public ServerCommandUpdate()
	{
		register("/cmd/update/update-project", update_project);
		register("/cmd/update/get-update-project-result", get_update_project_result);
		register("/cmd/update/update-system", update_system);
		register("/cmd/update/get-update-system-result", get_update_system_result);
	}

	public void update_project (Request req, Response res)
	{
		string json = """ { "success" : "%s" , "message" : "%s" } """;

		if ( req.css.flag_status_map["project_updating"] )
			res.send(json.printf("false","Ongoing Project Update"));
		else
		{
			bool result = req.css.thread_update_project();			
			res.send(json.printf(result.to_string(),""));
		}
	}

	public void get_update_project_result (Request req, Response res)
	{
		string json = """ { "success" : "%s" , "message" : "%s" } """;
		string success = req.css.flag_result_map["update_project_success"];
		string message = req.css.flag_result_map["update_project_message"];

		res.send(json.printf(success,message));
	}

	public void update_system (Request req, Response res)
	{
		string json = """ { "success" : "%s" , "message" : "%s" } """;

		if ( req.css.flag_status_map["system_updating"] )
			res.send(json.printf("false","Ongoing System Update"));
		else
		{
			bool result = req.css.thread_update_system();
		
			res.send(json.printf(result.to_string(),"Updating system"));
		}
	}

	public void get_update_system_result (Request req, Response res)
	{
		string json = """ { "success" : "%s" , "message" : "%s" } """;
		string success = req.css.flag_result_map["update_system_success"];
		string message = req.css.flag_result_map["update_system_message"];		

		res.send(json.printf(success,message));
	}
}
