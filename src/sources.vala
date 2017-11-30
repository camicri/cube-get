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

public class Source : Object
{
	private string? _source_entry_line = null;
	private string? _link = null;
	private string? _release = null;
	private string? _url = null;
	private string? _origin = null;
	private string? _release_filename = null;
	private string? _filename = null;
	private string? _ppa = null;
	private string? _ppa_short = null;
	private string? _component = null;
	private string? _name = null;
	private AptConstraint? _constraint;

	//Properties
	public string source_entry_line { get { return _source_entry_line; } }
	public string link { get { return _link; } }
	public string release { get { return _release; } }
	public string url { get { return _url; } }
	public string origin { get { return _origin; } }
	public string release_filename { get { return _release_filename; } }
	public string filename { get { return _filename; } }
	public string ppa { get { return _ppa; } }
	public string ppa_short { get { return _ppa_short; } }
	public string component { get { return _component; } }
	public string name { get { return _name; } }
	public AptConstraint constraint { get { return _constraint; } set { _constraint = value; } }

	/* Sample Entries
	 * link (used for repository download) : http://ppa.launchpad.net/upubuntu-com/flareget-i386/ubuntu/dists/precise/main/binary-i386/Packages.gz
	 * url (used for package download) : http://ppa.launchpad.net/upubuntu-com/flareget-i386/ubuntu/
	 * filename (downloaded repository filename) : ppa.launchpad.net_upubuntu-com_flareget-i386_ubuntu_dists_precise_main_binary-i386_Packages
	 * release : precise
	 * origin : ppa.launchpad.net
	 * release_filename (used for checking repository md5sum) : <reserved but not yet implemented>
	 * ppa (used for Apt Constraint) : ppa.launchpad.net/upubuntu-com/flareget-i386
	 * ppa_short (add-apt-repository) : ppa:upubuntu-com/flareget-i386
	 * component : main
	 * */

	public Source (string source_entry_line, string raw_link, string raw_url, string raw_release, string raw_component, string raw_release_filename)
	{		
		_source_entry_line = source_entry_line;
		_link = raw_link;
		_url = raw_url;
		_filename = raw_link.replace("http://", "").replace("http:/", "").replace(".gz", "").replace("/", "_").strip();
		_release = raw_release;
		_origin = raw_link.replace("http://", "").replace("http:/", "").split("/",-1)[0];
		_release_filename = raw_release_filename;
		_ppa = raw_link.replace ("http://", "").replace ("http:/", "").split("/ubuntu/dists",-1)[0].strip();
		_ppa_short = _ppa.replace("ppa.launchpad.net/","ppa:");
		_component = raw_component;
		_name = _ppa + " " + _release + " " + _component; 
	}

	public Source.only_filename( string filename )
	{
		_filename = filename;
	}
}