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

public class ServerCommandProject : GLib.Object, RouterClass {

	public TreeMap<string, RouterHandler> mappings {get; set; default = new TreeMap<string, RouterHandler>();}

	public ServerCommandProject()
	{
		register("/cmd/project/get-projects", get_projects);
		register("/cmd/project/create-project", create_project);
		register("/cmd/project/open-project", open_project);
		register("/cmd/project/get-current-project", get_current_project);
		register("/cmd/project/open-projects-directory", open_projects_directory);
		register("/cmd/project/clean-project", clean_project);
		register("/cmd/project/close-project", close_project);
	}

	public void get_projects (Request req, Response res)
	{
		string json = "";

		string project_item = """{ "name" : "%s", "version" : "%s", "computer_name" : "%s" , "operating_system" : "%s", "distribution" : "%s", "release" : "%s", "codename" : "%s", "upstream_distribution" : "%s", "upstream_release" : "%s", "upstream_codename" : "%s", "architecture" : "%s", "date_created" : "%s" }""";

		int index = 0;
		req.css.cube.project_manager.get_projects();
		
		foreach ( Project p in req.css.cube.project_manager.all_projects )
		{
			json += ((index>0)?",":"") + project_item.printf(p.project_name, p.project_version, p.computer_name, p.operating_system, p.distribution, p.release, p.codename, p.upstream_distribution, p.upstream_release, p.upstream_codename, p.architecture, p.date_created );
			index++;
		}

		res.send(("[" + json + "]"));
	}

	public void get_current_project (Request req, Response res)
	{
		string json = """{ "name" : "%s", "version" : "%s", "computer_name" : "%s" , "operating_system" : "%s", "distribution" : "%s", "release" : "%s", "codename" : "%s", "upstream_distribution" : "%s", "upstream_release" : "%s", "upstream_codename" : "%s", "architecture" : "%s", "date_created" : "%s" }""";

		if ( req.css.cube.project == null )
			res.send("");
		else
			res.send(json.printf(req.css.cube.project.project_name, req.css.cube.project.project_version, req.css.cube.project.computer_name, req.css.cube.project.operating_system, req.css.cube.project.distribution, req.css.cube.project.release, req.css.cube.project.codename, req.css.cube.project.upstream_distribution, req.css.cube.project.upstream_release, req.css.cube.project.upstream_codename, req.css.cube.project.architecture, req.css.cube.project.date_created ));
	}
	
    public void create_project (Request req, Response res)
	{
		string json = """ { "success" : %s , "message" : "%s" } """;
		
		if ( req.query.contains ("project") )
		{
			if ( req.query["project"].strip() != "" && !req.query["project"].strip().contains(" ") )
			{
				if ( req.css.create_project( req.query["project"] ) )
					json = json.printf("true", "Project %s created".printf(req.query["project"]) );
				else
					json = json.printf("false", req.css.error_message );
			}
			else
				json = json.printf("false", "Invalid project name");
		}
		else
			json = json.printf("false","No project name received");

		res.send(json);
	}

	public void open_project (Request req, Response res)
	{
		string json = """ { "success" : %s , "project" : "%s", "message" : "%s" } """;

		if ( !req.query.contains ("project") )
			res.send(json.printf("false","null","No project name provided"));
		else if ( !(req.query["project"].strip() != "" && !req.query["project"].strip().contains(" ")) )
			res.send(json.printf("false","null","Invalid project name"));
		else if ( !req.css.open_project (req.query["project"]) )
			res.send(json.printf("false",req.query["project"],req.css.error_message));
		else
			res.send(json.printf("true",req.query["project"],"Project Opened"));
	}

	public void close_project (Request req, Response res)
	{
		string json = """ { "success" : %s , "message" : "%s" } """;

		if( !req.css.close_project() ) {
			res.send(json.printf("false",req.css.error_message));
		}
		else
			res.send(json.printf("true","Project Closed"));
	}

	public void open_projects_directory (Request req, Response res)
	{
		string json = """ { "success" : %s , "message" : "%s" } """;
		
		bool result = ProcessManager.run_default_application ( req.css.cube.base_manager.projects_directory );

		res.send(json.printf(result.to_string(),""));
	}

	public void clean_project (Request req, Response res)
	{
		string json = """ { "success" : %s , "message" : "%s" } """;
		
		bool result = req.css.cube.clean_project();

		res.send(json.printf(result.to_string(),""));
	}
}
