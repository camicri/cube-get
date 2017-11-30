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

public enum PackageQueryType { ALL , SOME }

public class PackageQuery
{
	TreeMap<unowned string,Package>? _package_map;
	ArrayList<Package> _package_list;
	int? _index = null;
	
	PackageQueryType _type = PackageQueryType.SOME;	
	
	public int? index { get { return _index; } set { _index = value; } }
	public PackageQueryType query_type { get { return _type; } set { _type = value; } }

	public ArrayList<Package> current_package_list { get { return _package_list; } }
	public TreeMap<unowned string,Package> current_package_map { get { return _package_map; } }	
	
	public PackageQuery.package_map ( TreeMap<unowned string,Package> package_map , PackageQueryType query_type )
	{
		_package_map = package_map;
		_package_list = new ArrayList<Package>(Package.equal_function);
		_package_list.add_all ( package_map.values );
		_type = query_type;
	}

	public PackageQuery.package_list ( ArrayList<Package> package_list , PackageQueryType query_type  )
	{
		_package_list = new ArrayList<Package>(Package.equal_function);		
		_package_list.add_all ( package_list );		
		_package_list.sort ( Package.compare_function);
		_type = query_type;
	}

	public Package? find_package ( string package_name )
	{
		if ( _package_map != null )
			return _package_map[package_name];
		else
		{
			int index = find_index ( package_name );
			if ( index >= 0 )
				return _package_list[index];
			else
				return null;
		}
	}

	public int find_index ( string package_name )
	{
		if ( _package_map != null )
		{
			if ( _package_map.has_key(package_name) )
				return _package_list.index_of ( _package_map[package_name] );
		}
		
		Package p = new Package();
		p.set_value ("Package", package_name);
		int index = 0;
		index = _package_list.index_of ( p );
		return index;
	}

	public ArrayList<Package> find_starts_with ( string package_name , int count = -1 )
	{
		ArrayList<Package> packages = new ArrayList<Package>(Package.equals);
		int start_index = find_index ( package_name );

		if ( start_index < 0 )
			return packages;

		int c = 0;

		if ( count == -1 )
			count = (_package_list.size - index) + 1;
		
		for ( int i = start_index; i < _package_list.size ; i++ )
		{			
			if ( _package_list[i].name.has_prefix ( package_name ) )
			{
			    packages.add ( _package_list[i] );
				index = i;
			}

			if ( c == count )
				break;
			else
				c++;
		}

		index += 1;

		return packages;
	}

	public ArrayList<Package> next ( int count )
	{
		ArrayList<Package> list = new ArrayList<Package>(Package.equals);
		
		if ( _index == null )
			return list;

		if ( index == (_package_list.size) )
			return list;

		if ( count == -1 )
			count = (_package_list.size - index) + 1;

		for ( int c = 0; c <= count && _index < _package_list.size; _index+=1, c+=1 )
		{
			list.add ( _package_list[_index] );
		}		
		
		return list;
	}

	public ArrayList<Package> previous ( int count )
	{
		ArrayList<Package> list = new ArrayList<Package>(Package.equals);
		
		if ( index == null )
			return new ArrayList<Package>(Package.equals);

		if ( index == 0 )
			return list;

		if ( count == -1 )
			count = (_package_list.size - index) + 1;
		
		for ( int c = 0; c <= count && _index >=0; _index-=1, c+=1 )
		{
			list.add (_package_list[_index] );
		}
		
		return list;
	}
}