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

public class SourceManager : GLib.Object {

	Source _status_source;
	ArrayList<Source> _sources_list = new ArrayList<Source>();
	ArrayList<AptConstraint> _constraints_list = new ArrayList<AptConstraint>();
	ArrayList<string> _sources_key_list = new ArrayList<string>();
	ArrayList<string> _releases_key_list = new ArrayList<string>();
	//ArrayList<string> _constraints_key_list = new ArrayList<string>();

	string _sources_dir_path = "data/sources/";
	string _architecture = "binary-i386";

	//Properties
	public ArrayList<Source> sources { get { return _sources_list; } set { _sources_list = value; } }
	public ArrayList<AptConstraint> constraints { get { return _constraints_list; } }
	public string sources_dir_path { get { return _sources_dir_path; } }
	public Source status_source { get { return _status_source; } }

    // Constructor
    public SourceManager (string sources_dir_path, string architecture)
	{
		_sources_dir_path = sources_dir_path;
		_architecture = architecture;
    }

	public bool scan_sources()
	{
		scan_repository_lists();
		scan_constraints();
		sort_sources();

		//Add status file at the end
		_status_source = new Source.only_filename("status");
		_sources_list.add(_status_source);

		return true;
	}

	public bool scan_repository_lists()
	{
		_sources_list = new ArrayList<Source>();
		_sources_key_list = new ArrayList<string>();
		_releases_key_list = new ArrayList<string>();

		try
		{
			Dir sources_dir = Dir.open (_sources_dir_path);
			string source_file;

			while ( ( source_file = sources_dir.read_name() ) != null )
			{
				if ( !source_file.has_suffix("list" ) )
					continue;

				//TODO How to manage backports?? Do we need to skip it? How Repository Manager handle this also?				

				var source_stream = new DataInputStream( File.new_for_path(Path.build_filename ( _sources_dir_path , source_file )).read() );
				string line;
				string source_entry_line = "";

				while ( ( line = source_stream.read_line(null,null) ) != null )
				{
					line = line.strip();
					source_entry_line = line;

					if ( line.length == 0 || 
					     line.has_prefix("#") ||
					     line.has_prefix("deb-src") ||
					     line.has_prefix("deb cdrom"))
						continue;

					if( line.contains("#") )
						line = line.split("#",2)[0].strip();

					line = line.replace("deb ", "").replace("\"","").strip();
					line = line.replace("http://","").strip();

					/* Ignore entries enclosed with [] */
					try {
						line = /\[.*?\]/.replace(line, -1 , 0, "").strip();
					} catch (Error e) {
					}

					string raw_main_url = line.split(" ",-1)[0];
					if( line.strip() != raw_main_url.strip() )
						line = line.replace(raw_main_url,"").strip();

					string[] line_split = line.split(" ",-1);

					if(!raw_main_url.has_suffix("/"))
						raw_main_url += "/";

					string raw_main_source = raw_main_url + "dists/" + line_split[0];
					string raw_release = line_split[0];

					if(!_releases_key_list.contains(raw_main_source))
					{
						_releases_key_list.add(raw_main_source);
					}

					for(int i = 1 ; i < line_split.length ; i++)
					{
						string raw_component = line_split[i];
						line = "http://" + raw_main_source + "/" + raw_component + "/" + _architecture + "/Packages.gz";
						if( !_sources_key_list.contains(line) )
						{
							_sources_key_list.add(line);
							_sources_list.add( new Source(source_entry_line, line, "http://"+raw_main_url, raw_release, raw_component, "rel.ReleaseFilename") );
						}
					}
				}

				source_stream.close();
			}
		}
		catch ( Error e )
		{
			stdout.printf("Error : %s\n",e.message);
		}
		return true;
	}

	public bool scan_constraints()
	{
		_constraints_list = new ArrayList<AptConstraint>();
		//if (!File.Exists (strOtherListDir + "preferences"))
		//	return false;

		try
		{
			Dir sources_dir = Dir.open (_sources_dir_path);
			string constraint_file;
			while ( ( constraint_file = sources_dir.read_name() ) != null )
			{
				if ( constraint_file == "preferences" || constraint_file.has_suffix(".pref") )
				{
					var constraint_stream = new DataInputStream( File.new_for_path( Path.build_filename ( _sources_dir_path , constraint_file ) ).read() );
					string pac = null, pin = null, pri = null;
					string line;

					while ( ( line = constraint_stream.read_line(null,null) ) != null )
					{
						string[] splitArr = line.split(":");
						if( splitArr.length == 2)
						{
							if ( splitArr[0].strip() == "Package" )
								pac = splitArr[1].strip();
							else if ( splitArr[0].strip() == "Pin" )
								pin = splitArr[1].strip();
							else if ( splitArr[0].strip() == "Pin-Priority")
								pri = splitArr[1].strip();
						}
						else if (line.strip().length == 0)
						{
							if (pin != null && pac != null && pri != null)
								_constraints_list.add (new AptConstraint(pac, pin, pri));
							pac = null;
							pin = null;
							pri = null;
						}
					}
					if (pin != null && pac != null && pri != null)
						_constraints_list.add (new AptConstraint(pac, pin, pri));

					constraint_stream.close();
				}
			}
		}
		catch ( Error e )
		{
			stdout.printf("Error : %s\n",e.message);
		}
		AptConstraintSorter.sort(ref _constraints_list);

		return true;
	}

	public bool check_ppa_exists( string ppa )
	{
		//Check if exists
		foreach ( Source s in _sources_list )
		{
			if ( s.ppa_short == ppa )
				return true;
		}
		return false;
	}

	public bool create_ppa_source_list( string ppa, string source_entry_contents, string? release = "")
	{
		if ( check_ppa_exists (ppa) )
			return false;

		string filename = ppa.replace("ppa:","").replace("/","-")+(release!=""?"-":"")+release+".list";
		filename = Path.build_filename(_sources_dir_path,filename);

		File file = File.new_for_path(filename);

		try
		{
			DataOutputStream stream = new DataOutputStream ( file.create (FileCreateFlags.REPLACE_DESTINATION) );
			stream.put_string(source_entry_contents);
			stream.close();
			return true;
		}
		catch( Error e)
		{
			stdout.printf("Error : %s\n",e.message);
		}

		return false;
	}

	public Source[] get_sources_from_ppa(string ppa)
	{
		ArrayList<Source> sources = new ArrayList<Source>();

		foreach ( Source s in _sources_list )
		{
			if ( s.ppa_short == ppa )
				sources.add(s);
		}

		return sources.to_array();
	}

	public void sort_sources()
	{
		ArrayList<Source> new_sources_list = new ArrayList<Source> ();

		foreach ( AptConstraint c in _constraints_list )
		{
			for ( int i = 0; i < _sources_list.size; i++ )
			{
				Source s = _sources_list[i];
				if( c.pin.contains("Release") )
				{
					if( s.release.strip() == c.pin.split(" ",-1)[1].strip() )
					{
						s.constraint = c;
						if(!new_sources_list.contains(s))
							new_sources_list.add(s);
						_sources_list.remove_at(i);
						i--;
					}
				}
				else if ( c.pin.contains("Origin") )
				{
					if ( s.ppa.replace("/","-") == c.pin.split (" ",-1) [1].strip()) {
						s.constraint = c;
						if(!new_sources_list.contains(s))
							new_sources_list.add(s);
						_sources_list.remove_at(i);
						i--;
					}
					else if( s.origin.down().contains(c.pin.split(" ",-1)[1]) )
					{
						s.constraint = c;
						if( !new_sources_list.contains(s) )
							new_sources_list.add(s);
						_sources_list.remove_at(i);
						i--;
					}
				}
				else if( c.pin.contains("Origin-URL") )
				{
					if( s.origin.strip() == c.pin.split(" ",-1)[1].strip() )
					{
						s.constraint = c;
						if( !new_sources_list.contains(s) )
							new_sources_list.add(s);
						_sources_list.remove_at(i);
						i--;
					}
				}
			}
		}

		for ( int i = 0; i < _sources_list.size; i++ )
		{
			Source s = _sources_list[i];
			if ( s.release.contains("updates") )
			{
				if ( !new_sources_list.contains(s) )
					new_sources_list.add(s);
				_sources_list.remove_at(i);
				i--;
			}
		}

		if ( _sources_list.size > 0)
			new_sources_list.add_all (_sources_list);

		_sources_list.clear ();
		_sources_list = new_sources_list;
	}
}