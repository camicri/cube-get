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

public class AptConstraint
{
	ArrayList<string> _packages = new ArrayList<string>();
	string? _pin = null;
	int? _priority = null;

	public ArrayList<string> packages { get { return _packages; } }
	public string pin { get { return _pin; } }
	public int priority { get { return _priority; } }

	public AptConstraint ( owned string package, owned string pin, string priority )
	{
		package = package.strip();
		
		string[] split;
		
		if ( package.contains (" ") ) {
			split = package.split (" ");
			foreach (string s in split)
				_packages.add ( s.strip () );				
		} else
			_packages.add ( package );

		if ( pin.contains ("release o=") ) {
			pin = "Origin " + pin.replace ("release o=", "").strip ();
			if ( pin.contains ("LP-PPA") ) //Convert to Launchpad PPA address
				pin = pin.replace ("LP-PPA", "ppa.launchpad.net");
		}
		else if ( pin.contains ("release a=") )
			pin = "Release " + pin.replace ("release a=", "").strip ();
		else if (pin.contains ("origin"))
			pin = "Origin-URL " + pin.replace ("origin", "").strip ();

		_pin = pin;

		_priority = int.parse(priority.strip());
	}
}

public class AptConstraintSorter
{
	//#TODO Change to a fast sorting algo (ie. Quick Sort)
	//Bubble sort implementation
	public static void sort( ref ArrayList<AptConstraint> constraint_list )
	{
		bool swap = false;
		AptConstraint temp;
		do{
			swap = false;
			for( int i = 0; i < (constraint_list.size-1); i++ )
			{
				if ( constraint_list[i].priority < constraint_list[i+1].priority )
				{
					temp = constraint_list[i];
					constraint_list[i] = constraint_list[i+1];
					constraint_list[i+1] = temp;
					swap = true;
				}
			}
			
		}while(swap);
	}
}