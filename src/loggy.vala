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

public enum LogType { DEBUG, INFORMATION , ERROR }

public class Loggy : GLib.Object {
	
	public static void log ( BaseManager base_mgr, LogType type, string message )
	{
		string log_name = new DateTime.now_local().format("%F");
		if ( type == LogType.INFORMATION )
			log_name = Path.build_filename ( base_mgr.information_logs_directory , log_name );
		else if ( type == LogType.DEBUG )
			log_name = Path.build_filename ( base_mgr.debug_logs_directory , log_name );
		else if ( type == LogType.ERROR )
			log_name = Path.build_filename ( base_mgr.error_logs_directory , log_name );

		File log_file = File.new_for_path ( log_name );
		DataOutputStream stream;

		try
		{		
			if ( !log_file.query_exists() )
				stream = new DataOutputStream ( log_file.create ( FileCreateFlags.REPLACE_DESTINATION ) );
			else
				stream = new DataOutputStream ( log_file.append_to (FileCreateFlags.NONE) );

			string log_message = "[%s] %s\n".printf(new DateTime.now_local().format("%T"),message);
			stream.put_string(log_message);
			stream.close();
		}
		catch ( Error e )
		{
			stdout.printf("Error : %s\n",e.message);
		}
	}

	public static void copy_installation_logs ( BaseManager base_mgr )
	{
		string log_name = "install-log-" + new DateTime.now_local().format("%F");
		string source = Path.build_filename ( base_mgr.temporary_directory , "install-log.txt" );
		string destination =  Path.build_filename ( base_mgr.error_logs_directory , log_name );

		FileManager.copy ( source, destination );
	}
}
