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

public class ProcessManager : GLib.Object {

	public signal void output_changed ( string? output );
	public signal void started ();
	public signal void finished (int exit_status);
	public signal void error_occured (string error_message);

	int _exit_status;
	Pid? _child_pid = null;
	MainLoop loop;

	public int exit_status { get { return _exit_status; } }

    // Constructor
    public ProcessManager () {

    }

	public static bool run_default_application ( string arguments )
	{
		string app_name = "";

		if ( SystemInformation.get_operating_system_type() == OperatingSystemType.LINUX )
			app_name = "xdg-open";
		else if ( SystemInformation.get_operating_system_type() == OperatingSystemType.WINDOWS )
			app_name = "explorer";

		return run_sync ( { app_name, arguments} );
	}
	
	public static bool run_sync (string[] arguments, string working_directory=Environment.get_current_dir() )
	{
		try
		{
			Process.spawn_sync (Environment.get_current_dir(),arguments,null,SpawnFlags.SEARCH_PATH,null);
		}
		catch ( Error e )
		{
			stdout.printf("Error : %s\n",e.message);
			return false;
		}
		
		return true;
	}

	public static string? run_get_output(string[] arguments, string working_directory=Environment.get_current_dir())
	{
		string? temp = null ;
		ProcessManager proc_mgr = new ProcessManager();
		proc_mgr.output_changed.connect( (output) => {
			if ( temp == null )
				temp = "";
			temp += output;
		});
		proc_mgr.run(arguments,working_directory);
		return temp.strip();
	}

	public static int? run_get_status(string[] arguments, string working_directory=Environment.get_current_dir())
	{
		int? temp = null;
		ProcessManager proc_mgr = new ProcessManager();
		proc_mgr.finished.connect( (status) => {
			temp = status;
		});
		proc_mgr.run(arguments,working_directory, false);
		return temp;
	}

	public void run_arglist(ArrayList<string> arguments, string working_directory = Environment.get_current_dir())
	{
		string s_args = "";
		for(int i = 0; i < arguments.size; i++)
			s_args += arguments[i] + ((i!=(arguments.size-1))?"<split>":"");			
		run(s_args.split("<split>"),working_directory);
	}

	public void run(string[] arguments , string working_directory = Environment.get_current_dir(), bool listen = true)
	{		
		loop = new MainLoop ();
		int standard_input;
		int standard_output;
		int standard_error;
		
		try {

			Process.spawn_async_with_pipes (working_directory,
				arguments,
				/*Windows Fix*/ /*Environ.get (),*/
			    null,
				SpawnFlags.SEARCH_PATH | SpawnFlags.DO_NOT_REAP_CHILD,
				null,
				out _child_pid,
				out standard_input,
				out standard_output,
				out standard_error);

			if( listen ) {
				// stdout 
				IOChannel output = new IOChannel.unix_new (standard_output);
				output.add_watch (IOCondition.IN | IOCondition.HUP, (channel, condition) => {
					return process_line (channel, condition, "stdout");
				});

				// stderr:
				IOChannel error = new IOChannel.unix_new (standard_error);

				error.add_watch (IOCondition.IN | IOCondition.HUP, (channel, condition) => {
					return process_line (channel, condition, "stderr");
				});
			}
			
			ChildWatch.add (_child_pid, (pid, status) => {
				// Triggered when the child indicated by child_pid exits
				Process.close_pid (pid);
				finished ( status );
				loop.quit ();
			});

			started();
			loop.run ();
			if (listen) {
				Posix.close(standard_input);
				Posix.close(standard_output);
				Posix.close(standard_error);
			}
			Process.close_pid(_child_pid);
		} catch (SpawnError e) {
			stdout.printf("[ProcMgr] Error : %s\n",e.message);
			output_changed("Error : "+e.message);

			if (listen) {
				Posix.close(standard_input);
				Posix.close(standard_output);
				Posix.close(standard_error);
			}
			Process.close_pid(_child_pid);
			
			loop.quit ();
		}
	}

	public bool kill(string name = "")
	{
		if ( _child_pid != null && loop != null)
		{
			if ( SystemInformation.get_operating_system_type() == OperatingSystemType.LINUX )				
				ProcessManager.run_sync ( {"kill","-9",((int)_child_pid).to_string()} );
			else if ( SystemInformation.get_operating_system_type() == OperatingSystemType.WINDOWS )				
				ProcessManager.run_sync ( {"taskkill","/F","/IM",name+".exe"} );
			return true;
		}
		return false;
	}

	private bool process_line (IOChannel channel, IOCondition condition, string stream_name)
	{
		if (condition == IOCondition.HUP) {
			//stdout.printf ("%s: The fd has been closed.\n", stream_name);
			return false;
		}

		try {
			string line;
			channel.read_line (out line, null, null);

			//Windows fix
			if ( line == null )
				return false;

			//stdout.printf ("%s: %s", stream_name, line);
			output_changed(line);
		} catch (IOChannelError e) {
			stdout.printf ("[ProcMgr] Error : %s: IOChannelError: %s\n", stream_name, e.message);
			return false;
		} catch (ConvertError e) {
			stdout.printf ("[ProcMgr] Error : : %s: ConvertError: %s\n", stream_name, e.message);
			return false;
		}

		return true;
	}
}