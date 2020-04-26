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

using Gee;

public class LinuxInformation {
    //System Information
    string _architecture;
    string _operating_system;
    string _release;
    string _distribution;
    string _codename;
    string _upstream_release;
    string _upstream_distribution;
    string _upstream_codename;
    string _computer_name;

    //Properties
    public string architecture { get { return _architecture; } }
    public string operating_system { get { return _operating_system; } }
    public string release { get { return _release; } }
    public string distribution { get { return _distribution; } }
    public string codename { get { return _codename; } }
    public string upstream_release { get { return _upstream_release; } }
    public string upstream_distribution { get { return _upstream_distribution; } }
    public string upstream_codename { get { return _upstream_codename; } }
    public string computer_name { get { return _computer_name; } }

    public LinuxInformation() {
        if (SystemInformation.get_operating_system_type() != OperatingSystemType.LINUX)
            return;

        _architecture = ProcessManager.run_get_output (new string[]{"dpkg","--print-architecture"});

        if (_architecture == "x86_64")
            _architecture = "binary-amd64";
        else if (_architecture == "i686")
            _architecture = "binary-i386";
        else if (_architecture != null)
            _architecture = "binary-" + _architecture;
        else
            _architecture = "binary-unknown";

        _operating_system = ProcessManager.run_get_output (new string[]{"cat","/etc/issue.net"});
        _computer_name = ProcessManager.run_get_output (new string[]{"whoami"});

        _release = _get_lsb_release_data ("-r");
        _distribution = _get_lsb_release_data ("-i");
        _codename = _get_lsb_release_data ("-c");

        TreeMap<string,string> upstream_lsb_release_map = get_all_upstream_lsb_release_data();

        if (upstream_lsb_release_map.has_key("DISTRIB_ID"))
            _upstream_distribution = upstream_lsb_release_map["DISTRIB_ID"];

        if (upstream_lsb_release_map.has_key("DISTRIB_RELEASE"))
            _upstream_release = upstream_lsb_release_map["DISTRIB_RELEASE"];

        if (upstream_lsb_release_map.has_key("DISTRIB_CODENAME"))
            _upstream_codename = upstream_lsb_release_map["DISTRIB_CODENAME"];
    }

    private string _get_lsb_release_data(string argument) {
        if (SystemInformation.get_operating_system_type() != OperatingSystemType.LINUX)
            return "";

        string data =  ProcessManager.run_get_output (new string[]{"lsb_release",argument});
        if (data != null) {
            if (data.contains(":"))
                data = data.split (":",2)[1].strip();
        }
        return data;
    }

    private TreeMap<string,string> get_all_upstream_lsb_release_data() {
        TreeMap<string,string> upstream_lsb_release_map = new TreeMap<string,string>();
        File upstream_lsb_release = File.new_for_path("/etc/upstream-release/lsb-release");

        if (!upstream_lsb_release.query_exists())
            return upstream_lsb_release_map;

        try {
            DataInputStream stream = new DataInputStream(upstream_lsb_release.read());

            string line;

            while ((line = stream.read_line(null,null)) != null) {
                if (line.contains("=")) {
                    string[] split = line.split("=",-1);
                    upstream_lsb_release_map[split[0]] = split[1];
                }
            }

            stream.close();
        } catch(Error e) {
            stdout.printf("Error : %s\n",e.message);
        }

        return upstream_lsb_release_map;
    }
}