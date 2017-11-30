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

public class ServerCommandInstall : GLib.Object, RouterClass {

	public TreeMap<string, RouterHandler> mappings {get; set; default = new TreeMap<string, RouterHandler>();}

	public ServerCommandInstall()
	{
		register("/cmd/install/install-package", install_package);
		register("/cmd/install/install-marked-packages", install_marked_packages);
		register("/cmd/install/get-install-package-result", get_install_package_result);
	}
	
	public void install_package (Request req, Response res)
	{
		string json = """ { "success" : "%s" , "message" : "%s" } """;
		string[] packages;

		if ( req.css.flag_status_map["package_installing"] )
		{
			res.send(json.printf("false","Ongoing Installation"));
			return;
		}
		
		if ( req.query["package"].contains(";") )
			packages = req.query["package"].split(";",-1);
		else
			packages = new string[]{req.query["package"]};

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

		if ( satisfied_dependencies.size > 0 && unsatisfied_dependencies.size == 0 )
		{			
			req.css.thread_install_packages(satisfied_dependencies);
			res.send(json.printf("true","Installation Started"));
		}
		else
			res.send(json.printf("false","Installation Aborted. There are still packages to download"));		
	}

	public void install_marked_packages (Request req, Response res)
	{
		string json = """ { "success" : "%s" , "message" : "%s" } """;
		string package_list = "";

		if (req.css.marked_to_install_packages.size == 0) {
			res.send(json.printf("false","No marked packages"));
		}
		
		foreach(string name in req.css.marked_to_install_packages) {
			package_list += name + ";";
		}

		req.query["package"] = package_list;

		install_package(req, res);
	}

	public void get_install_package_result (Request req, Response res)
	{
		string json = """ { "success" : "%s" , "message" : "%s" } """;
		string success = req.css.flag_result_map["install_success"];
		string message = req.css.flag_result_map["install_message"];		

		res.send(json.printf(success,message));
	}
}
