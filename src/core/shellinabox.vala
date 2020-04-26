/*
 * Copyright (C) 2020 Jake R. Capangpangan <camicrisystems@gmail.com>
 *
 * cube-get is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the
 * Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * cube-get is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

public class ShellInABox : GLib.Object {
    public signal void started();
    public signal void finished();
    public signal void failed(string error_message);

    ProcessManager _proc_mgr = new ProcessManager();

    string _binary_path = "shellinaboxd";
    string _arguments = "$1 -t -d --service='/shell':\"$(id -u)\":\"$(id -g)\":\"$HOME\":\"$2\" ";
    string _temporary_directory = "";

    // Constructor
    public ShellInABox(string binary_path, string temporary_directory, string? port, string arguments) {
        if (port == null || port.strip() == "")
            port = "4200";

        _binary_path = binary_path;
        _arguments += arguments;
        _arguments += "-p " + port.strip() + " ";
        _temporary_directory = temporary_directory;
    }

    public int run(string arguments) {
        string[3] argument_arr = new string[4];
        int status = 0;

        try {
            var shellinabox_script_file = File.new_for_path(Path.build_filename (_temporary_directory, "shellinabox.sh"));
            if (shellinabox_script_file.query_exists())
                shellinabox_script_file.delete();

            string shellinabox_script = "#!/bin/bash\n"+_arguments;

            var stream = new DataOutputStream(shellinabox_script_file.create(FileCreateFlags.REPLACE_DESTINATION));
            stream.put_string(shellinabox_script);
            stream.close();

            ProcessManager.run_get_status(new string[]{"chmod","+x",shellinabox_script_file.get_path()});

            argument_arr[0] = shellinabox_script_file.get_path();
            argument_arr[1] = _binary_path;
            argument_arr[2] = arguments;

            _proc_mgr.output_changed.connect(_process_output);
            _proc_mgr.finished.connect(_process_finished);
            _proc_mgr.error_occured.connect(_process_error_occured);

            _proc_mgr.finished.connect((s) => {
                status = s;
            });

            _proc_mgr.run(argument_arr);
        } catch (Error e) {
            stdout.printf("Error: %s\n",e.message);
            status = -1;
        }

        return status;
    }

    private void _process_output(string? output) {
        if (output.strip().has_prefix("[server] Session") && output.strip().has_suffix ("done.")) {
            finished();
            ProcessManager.run_sync(new string[]{"killall","shellinaboxd"});
        }
    }

    private void _process_finished(int exit_code) {
    }

    private void _process_error_occured(string error_message) {
    }

}
