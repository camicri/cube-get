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

public class RepositoryManager : GLib.Object
{
	//Managers
	SourceManager _src_mgr;
	BaseManager _base_mgr;

	//ETC
	ArrayList<string> _lst_package_keys = new ArrayList<string>();
	string _repository_dir_path;

	bool is_debug = false;

	//Package Containers
	TreeMap<string,Package> _available_packages = new TreeMap<string,Package>(null,null);
	TreeMap<string,Package> _installed_packages = new TreeMap<string,Package>(null,null);
	TreeMap<string,string> _provided_packages = new TreeMap<string,string>(null,null);
	TreeMap<string,ArrayList<unowned Package>> _section_map = new TreeMap<string,ArrayList<unowned Package>>();
	
	ArrayList<string> _upgradable_packages = new ArrayList<string>();
	ArrayList<string> _downloaded_packages = new ArrayList<string>();
	ArrayList<string> _cleanup_packages = new ArrayList<string>();
	ArrayList<string> _cleanup_package_paths = new ArrayList<string>();

	//Counters
	int _ctr_available_packages = 0;
	int _ctr_installed_packages = 0;
	int _ctr_upgradable_packages = 0;
	int _ctr_downloaded_packages = 0;
	int _ctr_repackaged_packages = 0;
	int _ctr_cleanup_packages = 0;
	int _ctr_broken_packages = 0;		

	//Properties
	public int available_packages_count { get { return _ctr_available_packages; } }
	public int installed_packages_count { get { return _ctr_installed_packages; } }
	public int upgradable_packages_count { get { return _ctr_upgradable_packages; } }
	public int downloaded_packages_count { get { return _ctr_downloaded_packages; } }
	public int repackaged_packages_count { get { return _ctr_repackaged_packages; } }
	public int cleanup_packages_count { get { return _ctr_cleanup_packages; } }
	public int broken_packages_count { get { return _ctr_broken_packages; } }
	public string repository_dir_path { get { return _repository_dir_path; } }

	public ArrayList<string> upgradable_package_names { get { return _upgradable_packages; } }
	public ArrayList<string> downloaded_package_names { get { return _downloaded_packages; } }
	public ArrayList<string> cleanup_package_names { get { return _cleanup_packages; } }
	public ArrayList<string> cleanup_package_paths { get { return _cleanup_package_paths; } }		

	//Signals
	public signal void process_progress_changed ( string message, int progress_current , int progress_max );

	public TreeMap<string,Package> available_packages { get { return _available_packages; } }
	public TreeMap<string,Package> installed_packages { get { return _installed_packages; } }
	public TreeMap<string,string> provided_packages { get { return _provided_packages; } }
	public TreeMap<string,ArrayList<Package>> section_map { get { return _section_map; } }


	public RepositoryManager( BaseManager base_mgr, SourceManager src_mgr , string repository_dir_path)
	{		
		_src_mgr = src_mgr;
		_base_mgr = base_mgr;
		_repository_dir_path = repository_dir_path;
		_initialize ();		
	}

	private void _initialize()
	{			
		//Set all package information keys to be recorded
		_lst_package_keys.add("Package");
		_lst_package_keys.add("Version");
		_lst_package_keys.add("Description");
		_lst_package_keys.add("Depends");
		_lst_package_keys.add("Filename");
		_lst_package_keys.add("Size");
		_lst_package_keys.add("Installed");
		_lst_package_keys.add("Recommends");
		_lst_package_keys.add("Pre-Depends");
		_lst_package_keys.add("Provides");
		_lst_package_keys.add("Suggests");
		_lst_package_keys.add("MD5sum");
		_lst_package_keys.add("Section");
		_lst_package_keys.add("Status");			
		_lst_package_keys.add("Conflicts");
		_lst_package_keys.add("Breaks");		

		_src_mgr.scan_sources();
	}	

	public void initialize_section_map()
	{
		_section_map.clear();
		foreach ( string key in _base_mgr.section_configuration_file.configuration_map.keys )
		{			
			_section_map[key] = new ArrayList<Package>(Package.equals);
		}
	}

	public void scan_repositories()
	{					
		reset_all();

		//Initialize Section Map
		initialize_section_map();
		
		int progress_ctr = 0;
		foreach ( Source source in _src_mgr.sources )
		{
			process_progress_changed ( "Reading Repositories...", progress_ctr++, _src_mgr.sources.size );
			scan_repository(source);
		}
		
		process_progress_changed ( "Reading Repositories Finished...", _src_mgr.sources.size, _src_mgr.sources.size );

	}

	public bool scan_status_repository()
	{		
		_installed_packages.clear();
		_upgradable_packages.clear();
		_downloaded_packages.clear();
		_cleanup_packages.clear();
		_cleanup_package_paths.clear();	
		_installed_packages = new TreeMap<string,Package>(null,null);

		//Scan the status source file only
		scan_repository ( _src_mgr.status_source );		
		
		return true;
	}

	public bool scan_repository(Source source)
	{
		string repository_file =  Path.build_filename ( repository_dir_path , source.filename );

		if ( repository_file.has_suffix ("Packages" ) || repository_file == ( Path.build_filename ( repository_dir_path , "status" ) ))
		{			
			try{
				var file = File.new_for_path (repository_file);

				if ( !file.query_exists() )
					return false;
				
				var repo_stream = new DataInputStream(file.read ());						

				string line;
				Package pkg = new Package();
				while ( (line = repo_stream.read_line (null,null)) != null)
				{				
					if ( line.has_prefix (" ") )
						continue;

					if ( line.contains (":") )
					{						
						string[] arr_line = line.split (":",2);
						if ( _lst_package_keys.contains (arr_line[0].strip()) )
						{
							pkg.set_value(arr_line[0].strip(),arr_line[1].strip());									
							continue;
						}
					}

					//Add package here
					if ( line.strip().length == 0 )
					{
						if ( pkg.name != null )
						{
							if ( source.filename == "status" ) //Installed Packages Here
								_add_to_installed_packages (pkg);
							else //Available Packages Here
							{										
								_add_to_available_packages (pkg, source);
							}

							pkg = new Package();
						}
					}
				}

			}
			catch( Error e )
			{
				if ( is_debug ) stdout.printf ("Error : %s\n",e.message);
				if ( is_debug ) stdin.read_line ();
				return false;
			}
		}
		
		return true;
	}

	private void _add_to_available_packages(Package pkg, Source source)
	{		
		pkg.source_index = _src_mgr.sources.index_of(source);
		pkg.filename = source.url + pkg.filename;

		if ( !_available_packages.has_key (pkg.name) )
		{
			if ( _forced_by_constraint(pkg, source.constraint) )
				pkg.forced = true;			
			_available_packages[pkg.name] = pkg;
			_add_to_section_map( pkg );
		}
		else //Duplicate packages here
		{
			if ( _available_packages[pkg.name].forced )
				return;
			if ( DebianCompare.compare(_available_packages[pkg.name].version,pkg.version) == -1 )
				_available_packages[pkg.name] = pkg;
		}

		if ( pkg.provides != null )
			_add_to_provided_packages(pkg);
	}

	private void _add_to_installed_packages(Package pkg)
	{
		if( !_installed_packages.has_key (pkg.name) )
		{
			if ( pkg.status != null )
			{				
				//Check if it is really installed
				if ( !pkg.status_string.contains("installed") )					
					return;
				//Reset because this is no longer needed
				pkg.status_string = null;
			}
			_installed_packages[pkg.name] = pkg;			
		}
	}

	private void _add_to_provided_packages(Package pkg)
	{
		if ( pkg.provides == null )
			return;

		pkg.provides = pkg.provides.strip();

		string[] provides;

		if ( pkg.provides.contains(",") )
			provides = pkg.provides.split(",",-1);
		else
			provides = new string[]{pkg.provides};

		foreach ( string p in provides )
		{
			p = p.strip();
			
			if ( !_provided_packages.has_key (p) )
				_provided_packages[p] = pkg.name;
			else if ( !_provided_packages[p].contains(pkg.name) ) 
				_provided_packages[p] = _provided_packages[p] + "," + pkg.name;
		}
	}

	private void _add_to_section_map ( Package pkg )
	{		
		string section = pkg.section;
		
		if ( section == null )
			return;	
		
		if ( _section_map.has_key(section) )
		{			
			_section_map[section].add ( pkg );
		}
		else
		{
			switch(section)
			{
				case "perl" : 
				case "python" : 
				case "shells" :
				case "interpreters" :
				case "electronics" : 
				case "embedded" :
					_section_map["devel"].add(pkg);
					break;
				case "libdevel" :
					_section_map["lib"].add(pkg);
					break;
				case "gnome" :
				case "kde" :
					_section_map["desktop"].add(pkg);
					break;
				case "math" :
				case "science" :
					_section_map["educ"].add(pkg);
					break;
				case "editor" :
				case "text" :
					_section_map["doc"].add(pkg);
					break;
			}
		}
	}

	private bool _forced_by_constraint(Package p, AptConstraint? constraint)
	{
		if ( constraint == null )
			return false;

		//Foreach target package in source constraint
		foreach(string str in constraint.packages)	
		{
			if(SimpleRegex.check ( str.strip(), p.name ))
				return true;
		}

		return false;
	}

	public void update_package_counters()
	{			
		_ctr_downloaded_packages = 0;
		_ctr_repackaged_packages = 0;
		_ctr_broken_packages = 0;
		_ctr_available_packages = _available_packages.size;
		_ctr_installed_packages = _installed_packages.size;
		_ctr_upgradable_packages = _upgradable_packages.size;
		_ctr_downloaded_packages = _downloaded_packages.size;
		_ctr_cleanup_packages = _cleanup_packages.size;
	}

	public void mark_packages()
	{
		//Check for upgradable packages
		//int progress_ctr = 0;
		foreach ( string key in _installed_packages.keys )
		{
			//process_progress_changed ( "Marking Packages...", progress_ctr++, _installed_packages.keys.size );
			                          
			if ( !_available_packages.has_key (key) ) //Installed but not available to repo list
				continue;

			_available_packages[key].installed_version = _installed_packages[key].version;			

			int cmp_result = _installed_packages[key].compare_to(_available_packages[key]);				

			if ( cmp_result == 0 )
			{
				//_available_packages[key].status = "0"; //Installed
				_available_packages[key].status = PackageStatusType.INSTALLED; //Installed
				_installed_packages[key].status = PackageStatusType.INSTALLED;
			}
			else if ( cmp_result == -1 )
			{					
				//_available_packages[key].status = "-1"; //Upgradable
				_available_packages[key].status = PackageStatusType.UPGRADABLE; //Upgradable
				_installed_packages[key].status = PackageStatusType.UPGRADABLE;
				_upgradable_packages.add(key);
			}
			else if ( cmp_result == 1 )
			{
				/*
				//_available_packages[key].status = "1"; //Installed is latest than Available				
				_available_packages[key].status = PackageStatusType.NEWER; //Installed is latest than Available
				_installed_packages[key].status = PackageStatusType.NEWER;
				*/
				//Experimental: Newer packages still marked as installed
				_available_packages[key].status = PackageStatusType.INSTALLED; //Installed
				_installed_packages[key].status = PackageStatusType.INSTALLED;
			}
		}
		
		//process_progress_changed ( "Marking Packages Complete...", _installed_packages.keys.size, _installed_packages.keys.size );

		//Set Reverse Dependencies		
		set_reverse_dependencies();		
			
		//Reset package counters
		update_package_counters();
	}

	public void mark_downloaded_packages(Project p)
	{			
		try
		{
			reset_mark_downloaded_packages();

			var packages_dir = File.new_for_path ( p.packages_directory );
			var enumerator = packages_dir.enumerate_children(FileAttribute.STANDARD_NAME,0);

			//process_progress_changed ( "Marking Downloaded Packages...", 0, 1 );
			
			FileInfo file_info;
			while ( ( file_info = enumerator.next_file() ) != null )
			{
				/*Windows Fix 
				//Check if it is a regular file (Not directory)
				if ( file_info.get_file_type() != FileType.REGULAR )
					continue;
				*/

				//Check if it ends with .deb
				if ( !file_info.get_name().has_suffix(".deb") )
					continue;

				//Check if it exists on available packages
				string name = file_info.get_name().split("_",-1)[0].strip();
				if ( !_available_packages.has_key(name) )
					continue;				

				if ( File.new_for_path(_available_packages[name].filename).get_basename() == file_info.get_name() )
				{
					//Check if it is not installed
					if ( _available_packages[name].status != null )
					{
						if ( _available_packages[name].status == PackageStatusType.INSTALLED )
						{				
							_cleanup_packages.add(name);
							_cleanup_package_paths.add( Path.build_filename( p.packages_directory, file_info.get_name() ) );
							continue;
						}
					}
					
					string md5_1 = _available_packages[name].md5sum;
					string md5_2 = MD5Sum.get_md5(Path.build_filename(p.packages_directory, file_info.get_name()));
					if ( md5_1 == md5_2 )
					{						
						_downloaded_packages.add(name);						
						_available_packages[name].old_status = _available_packages[name].status;
						_available_packages[name].status = PackageStatusType.DOWNLOADED;						
					}
					else
					{	
						_cleanup_packages.add(name);
						_cleanup_package_paths.add( Path.build_filename( p.packages_directory, file_info.get_name() ) );
						stdout.printf("Broken : %s\n", file_info.get_name());						
					}
				}
			}
			
			//process_progress_changed ( "Marking Downloaded Packages Finished...", 1, 1 );
		} 
		catch ( Error e )
		{
			stdout.printf("Error : %s\n",e.message);
		}

		update_package_counters();
	}

	public void set_reverse_dependencies()
	{
		string dependency_string_fmt = "%s (%s %s)";
		
		if ( upgradable_package_names.size == 0 )
			return;
		
		foreach ( string name in upgradable_package_names )
		{			
			ArrayList<ArrayList<DependencyItem>> or_dependencies;
			ArrayList<DependencyItem> and_dependencies;
			Package pkg = available_packages[name];

			string? dep_string = (pkg.depends!=null?pkg.depends:"");
			
			if ( pkg.pre_depends != null )
				dep_string += (dep_string!=""?",":"")+pkg.pre_depends;
			if ( pkg.recommends != null )
				dep_string += (dep_string!=""?",":"")+pkg.recommends;

			if ( dep_string.strip().length == 0 )
				continue;	

			DependencyListParser.parse_dependency_string (dep_string, out or_dependencies, out and_dependencies);			

			foreach ( DependencyItem item in and_dependencies )
			{				
				if ( !available_packages.has_key(item.package_name) )
					continue;

				if ( available_packages[item.package_name].reverse_depends == null )
				{
					if ( item.equality_operator != null )
						available_packages[item.package_name].reverse_depends = dependency_string_fmt.printf(name,item.equality_operator,item.required_version);
					else
						available_packages[item.package_name].reverse_depends = name;
				}
				else if ( !available_packages[item.package_name].reverse_depends.contains(name) )
				{
					if ( item.equality_operator != null )
						available_packages[item.package_name].reverse_depends += ", " + dependency_string_fmt.printf(name,item.equality_operator,item.required_version);
					else
						available_packages[item.package_name].reverse_depends += ", " + name;
				}
			}
		}
	}

	public void reset_mark_downloaded_packages()
	{
		foreach ( string name in _downloaded_packages )
		{				
			_available_packages[name].status = _available_packages[name].old_status;
			_available_packages[name].old_status = null;
		}
		_downloaded_packages.clear();
		_cleanup_packages.clear();
		_cleanup_package_paths.clear();
		update_package_counters();
	}

	public void reset_mark_packages()
	{
		if ( _available_packages == null )
			return;
		
		//Set package status to null (Reset)
		foreach ( string key in _available_packages.keys )
		{
			_available_packages[key].status = PackageStatusType.AVAILABLE;
			_available_packages[key].reverse_depends = null;
			_available_packages[key].installed_version = null;
			_available_packages[key].forced = false;
		}

		//Clear variable package lists
		_upgradable_packages.clear();
		_downloaded_packages.clear();			
		_cleanup_packages.clear();
		_cleanup_package_paths.clear();
		
		//Reset package counters
		update_package_counters();
	}

	public void reset_cleanup_packages()
	{
		_cleanup_packages.clear();
		_cleanup_package_paths.clear();
		update_package_counters();
	}

	public void reset_all()
	{
		_section_map.clear();		
		_available_packages.clear();
		_installed_packages.clear();
		_upgradable_packages.clear();
		_downloaded_packages.clear();
		_cleanup_packages.clear();
		_cleanup_package_paths.clear();

		_available_packages = new TreeMap<string,Package>(null,null);
		_installed_packages = new TreeMap<string,Package>(null,null);
		_section_map = new TreeMap<string,ArrayList<unowned Package>>();
	}	

	public Package[] get_upgradable_packages()
	{
		ArrayList<Package> pkgs = new ArrayList<Package>(Package.equals);
		foreach ( string p in _upgradable_packages )
			pkgs.add ( _available_packages[p] );
		return pkgs.to_array();
	}

	public Package[] get_downloaded_packages()
	{
		ArrayList<Package> pkgs = new ArrayList<Package>(Package.equals);
		foreach ( string p in _downloaded_packages )
			pkgs.add ( _available_packages[p] );
		return pkgs.to_array();
	}
}
