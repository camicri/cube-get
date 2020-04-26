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

public class AxelData : Object, DownloaderData {
    //ArrayList<string> arg_list = new ArrayList<string>();

    public string filename { get; set; default = null; }
    public string filepath { get; set; default = null; }
    public string downloader_path { get; set; default = "axel"; }
    public string download_path { get; set; default = null; }
    public ArrayList<string> arguments { get; set; default = null;}
    public string link { get; set; default = null; }
    public bool replace { get; set; default = false; }

    public void initialize_arguments() {
        ArrayList<string> arguments = new ArrayList<string>();

        arguments.add(downloader_path);

        if (filename != null) {
            filepath = Path.build_filename (download_path , filename);
            arguments.add("-o");
            arguments.add(filepath);
        }

        if (this.arguments != null)
            arguments.add_all(this.arguments);

        arguments.add(link);

        this.arguments = arguments;
    }
}

public class AxelDownloader : Object, Downloader
{
    ProcessManager _proc_mgr = new ProcessManager();
    DownloaderData _data;

    int _percent = 0;
    string _rate;
    string _size;
    string _line;
    string _error_message;
    bool _downloaded = false;

    public int progress { get { return _percent; } }
    public string transfer_rate { get { return _rate; } }
    public string size { get { return _size; } }
    public string output { get { return _line; } }
    public string error_message { get { return _error_message; } }

    public ProcessManager process_manager { get { return _proc_mgr; } }

    public AxelDownloader(DownloaderData data) {
        _data = data;
    }

    public void start() {
        _data.initialize_arguments();
        _downloaded = false;

        try {
            if (FileUtils.test(_data.filepath,FileTest.EXISTS) && _data.replace)
                File.new_for_path(_data.filepath).delete ();
            //State file
            if (FileUtils.test(_data.filepath+".st",FileTest.EXISTS) && _data.replace)
                File.new_for_path(_data.filepath+".st").delete ();
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
        _proc_mgr.kill("axel");
        _line = "Stopped";
        _error_message = "Stopped";
    }

    private void _process_output(string? output) {
        if (output.strip().length == 0)
            return;

        _line = output.strip();
        output_changed(_line);

        if (_line.strip().has_prefix("Starting"))
            started();

        if (_line.contains("]") && _line.contains("[")) {
            foreach (string s in _line.split_set("[]",-1)) {
                if (s.contains("%"))
                    _percent = int.parse(s.replace("%","").strip());
                if (s.contains("B/s"))
                    _rate = s.strip();
                progress_changed(_percent,_rate);
            }
        }

        if (_line.contains("File size")) {
            _size = _line.split(" ")[2].strip();
            status_changed();
        }

        if (_line.contains("Opening output file")) {
            _data.filename = _line.split(" ",4)[3].strip();
            status_changed();
        }

        if (_line.contains("Downloaded")) {
            _percent = 100;
            progress_changed(_percent,_rate);
            _downloaded = true;
        }
    }

    private void _process_finished(int exit_code) {
        //Process last output here
        if (!_downloaded) {
            _error_message = _line;
            failed(_error_message);
        } else
            finished();
    }

    private void _process_error_occured(string error_message) {
        failed(error_message);
    }
}