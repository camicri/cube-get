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

public class ConfigurationFile {
    string _config_name;
    string _config_dir;
    bool _is_open = false;

    HashMap<string,string> _config_map = new HashMap<string,string>();
    ArrayList<string> _headers = new ArrayList<string>();

    //Properties
    public bool is_open { get { return _is_open; } }
    public HashMap<string,string> configuration_map { get { return _config_map; } }

    public ConfigurationFile(string config_name, string config_directory) {
        _config_name = config_name;
        _config_dir = config_directory;
    }

    public bool create_configuration(string[]? headers = null, HashMap<string,string> config_map = new HashMap<string,string>()) {
        _headers.clear();
        foreach (string header in headers)
            _headers.add(header);
        _config_map = config_map;
        return save_configuration();
    }

    public bool open_configuration() {
        var file = File.new_for_path(Path.build_filename(_config_dir , _config_name));

        if (!file.query_exists())
            return false;

        _headers.clear();
        _config_map.clear();

        try {
            var stream = new DataInputStream(file.read());
            string line;
            while ((line = stream.read_line(null,null)) != null) {
                line = line.strip();
                if (line.has_prefix("#")) {
                    _headers.add(line);
                    continue;
                }

                if (line.contains(":")) {
                    string[] line_split = line.split(":",2);
                    _config_map[line_split[0].strip()] = line_split[1].strip();
                }
            }
            stream.close();
            _is_open = true;
        } catch(Error e) {
            stdout.printf("Error : %\n",e.message);
            return false;
        }

        return true;
    }

    public string? get_value(string key) {
        if (_is_open) {
            if (_config_map.keys.size > 0) {
                if (_config_map.has_key(key))
                    return _config_map[key];
            }
        }
        return null;
    }

    public bool set_value(string key, string val) {
        if (_is_open) {
            _config_map[key] = val;
            return true;
        }
        return true;
    }

    public bool save_configuration() {
        var file = File.new_for_path(Path.build_filename(_config_dir , _config_name));
        try {
            if (file.query_exists())
                file.delete();

            var stream = new DataOutputStream(file.create (FileCreateFlags.REPLACE_DESTINATION));

            foreach (string header in _headers)
                stream.put_string(header+"\n");

            foreach (string key in _config_map.keys)
                stream.put_string(key + " : " + _config_map[key] + "\n");

            stream.close();
            _is_open = false;
        } catch(Error e) {
            stdout.printf("Error : %s",e.message);
            return false;
        }
        return true;
    }
}