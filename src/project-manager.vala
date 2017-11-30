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

public class ProjectManager : GLib.Object {

    string _proj_main_dir;
	ArrayList<Project> _projects = new ArrayList<Project>();

	//Managers
	BaseManager _base_mgr;

	//Properties
	public ArrayList<Project> all_projects { get { return _projects; } }
	
	public ProjectManager(string project_main_directory , BaseManager base_mgr)
	{
		_proj_main_dir = project_main_directory;
		_base_mgr = base_mgr;
	}

	public bool get_projects()
	{
		_projects.clear();
		
		var dir = File.new_for_path(_proj_main_dir);

		if ( !dir.query_exists() )
			return false;

		try
		{
			var enumerator = dir.enumerate_children(FileAttribute.STANDARD_NAME,0);
			FileInfo proj_dir;
			while ( ( proj_dir = enumerator.next_file() ) != null )
			{
				var proj = new Project( proj_dir.get_name(), _proj_main_dir, _base_mgr );
				if ( proj.open_project() )
				{
					_projects.add ( proj );
					proj = null;
				}
			}
		}
		catch ( Error e )
		{
			stdout.printf("Error : %s\n", e.message);
			return false;
		}
		
		return true;
	}
}
