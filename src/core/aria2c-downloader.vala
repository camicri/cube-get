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

public class Aria2cData : Object, DownloaderData {
    public string filename { get; set; default = null; }
    public string filepath { get; set; default = null; }
    public string downloader_path { get; set; default = "aria2c"; }
    public string download_path { get; set; default = null; }
    public ArrayList<string> arguments { get; set; default = null;}
    public string link { get; set; default = null; }
    public bool replace { get; set; default = false; }
    public string proxy { get; set; default = null; }

    public void initialize_arguments() {
        ArrayList<string> arguments = new ArrayList<string>();

        arguments.add(downloader_path);

        arguments.add("-d");
        arguments.add(download_path);

        if (filename != null) {
            arguments.add("-o");
            arguments.add(filename);
        }

        if (proxy != null) {
            arguments.add("--all-proxy");
            arguments.add(proxy);
        }

        if (this.arguments != null)
            arguments.add_all(this.arguments);

        arguments.add(link);

        this.arguments = arguments;
    }
}

public class Aria2cDownloader : Object, Downloader {
    ProcessManager _proc_mgr = new ProcessManager();
    DownloaderData _data;

    int _percent = 0;
    string _rate;
    string _size;
    string _size_downloaded;
    string _eta;
    string _line;
    string _error_message;
    bool _downloaded = false;

    public int progress { get { return _percent; } }
    public string transfer_rate { get { return _rate; } }
    public string size { get { return _size; } }
    public string size_downloaded { get { return _size_downloaded; } }
    public string ETA { get { return _eta; } }
    public string output { get { return _line; } }
    public string error_message { get { return _error_message; } }

    public ProcessManager process_manager { get { return _proc_mgr; } }

    public Aria2cDownloader(DownloaderData data) {
        _data = data;
    }

    public void start() {
        _data.initialize_arguments();
        _downloaded = false;

        try {
            if (FileUtils.test(_data.filepath,FileTest.EXISTS) && _data.replace)
                File.new_for_path(_data.filepath).delete ();

            //State file
            if (FileUtils.test(_data.filepath+".aria2",FileTest.EXISTS) && _data.replace)
                File.new_for_path(_data.filepath+".aria2").delete ();

        } catch (Error e) {
            stdout.printf("Error : %s",e.message);
        }

        _proc_mgr.output_changed.connect(_process_output);
        _proc_mgr.finished.connect(_process_finished);
        _proc_mgr.error_occured.connect(_process_error_occured);

        /*
        string working_dir = "/";
        if (SystemInformation.get_operating_system_type () == OperatingSystemType.WINDOWS)
            working_dir = "C:";
        */

        //_proc_mgr.run (_data.arguments.split(" ",-1) , _data.download_path);
        //_proc_mgr.run (_data.arguments.split(" ",-1) , working_dir);

        //Fix in windows
        //ArrayList<string>.to_array() causing problem, use run_arrlist instead of run
        //for ArrayList<string>

        //_proc_mgr.run (_data.arguments.to_array());
        _proc_mgr.run_arglist(_data.arguments);
    }

    public void stop() {
        _proc_mgr.kill("aria2c");
        _line = "Stopped";
        _error_message = "Stopped";
    }

    private void _process_output(string? output) {
        if (output.strip().length == 0)
            return;

        _line = output.strip();
        output_changed(_line);

        if (_line.has_prefix ("[")) {
            _line.replace ("]","");

            foreach (string s in _line.split(" ")) {
                if (s.strip().has_prefix ("SIZE")) {
                    string size = _line.replace("SIZE:","");
                    string[] size_stat = size.split("/");
                    _size_downloaded = size_stat[0];

                    if (!size_stat[1].contains("("))
                        _size = size_stat[1].strip();
                    else {
                        string[] size_stat_2 = size_stat[1].split("(");
                        _size = size_stat_2[0].strip();
                        _percent = int.parse(size_stat_2[1].replace(")","").replace("%","").strip());
                    }
                } else if (s.strip().has_prefix ("SPD"))
                    _rate = s.replace("SPD:","");
                else if (s.strip().has_prefix ("ETA"))
                    _eta = s.replace("ETA:","");
            }

            progress_changed(_percent,_rate);
        } else if (_line.contains("NOTICE")) {
            if (_line.contains("Download complete")) {
                _percent = 100;
                _eta = "00s";
                _size_downloaded = _size;
                _downloaded = true;

                progress_changed(_percent,_rate);
            }
        } else if (_line.contains("ERROR")) {
            _error_message = _line;
            _downloaded = false;
        }
    }

    private void _process_finished(int exit_code) {
        //Process last output here
        if (!_downloaded)
            failed(_error_message);
        else
            finished();
    }

    private void _process_error_occured(string error_message) {
        failed(error_message);
    }
}
