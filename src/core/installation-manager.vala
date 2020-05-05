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

public enum InstallationResultType { SUCCESS = 0, FAILED = 1, NO_TERMINAL = 2, INCOMPLETE = 3, PROHIBITED = 4 }

public class InstallationManager : GLib.Object
{
    Package[] _packages;
    BaseManager _base_mgr;
    SourceManager _source_mgr;
    Project _proj;

    string _default_installer;

    public signal void started();
    public signal void finished();
    public signal void failed(string error_message);

    public InstallationManager (BaseManager base_manager, SourceManager source_manager, Project project) {
        _base_mgr = base_manager;
        _source_mgr = source_manager;
        _proj = project;
    }

    public int start_installation(Package[] packages) {
        _packages = packages;

        //Ensure that we are in the original computer
        if (!_proj.is_project_original_computer())
            return InstallationResultType.PROHIBITED;

        _default_installer = _base_mgr.main_configuration_file.get_value("default-installer");
        if (_default_installer != null) {
            if (_default_installer == "apt-get")
                return _start_apt_installation();
            else
                return _start_dpkg_installation();
        }
        else
            return _start_apt_installation();
    }

    private int _start_apt_installation() {
        string install_script = """
#!/bin/bash

cache_dir="%s"
apt_options="%s"
packages="%s"
log_file="%s"
res_file="%s"
lock_file="$cache_dir/lock"
partial_dir="$cache_dir/partial"

apt-get -o dir::cache::archives="$cache_dir" $apt_options install $packages 2>&1 | tee $log_file
echo Result: $? > $res_file
grep "Unable to fetch some archives" $log_file
if [ $? -eq 0 ] ; then
    echo Incomplete >> $res_file
fi
grep "Errors were encountered while processing" $log_file
if [ $? -eq 0 ] ; then
    echo Error >> $res_file
fi

if [ -f $lock_file ] ; then
    rm -f $lock_file
fi

if [ -d $partial_dir ] ; then
    rmdir $partial_dir
fi

""";
        string install_log_file = Path.build_filename(_base_mgr.temporary_directory , "install-log.txt");
        string install_result_file = Path.build_filename(_base_mgr.temporary_directory , "install-result.txt");

        string config_params = _base_mgr.main_configuration_file.get_value("apt-get-parameters");
        config_params = config_params!=null?config_params:"";
        string cache_dir = _proj.packages_directory;
        string packages = "";

        foreach (Package p in _packages) {
            //packages += p.name + "/" + _source_mgr.sources[p.source_index].release + " ";
            packages += p.name + "=" + p.version + " ";
        }

        packages = packages.strip();

        install_script = install_script.printf(cache_dir,config_params,packages,install_log_file, install_result_file);

        return _run(install_script);
    }

    private int _start_dpkg_installation() {
        string install_script = """
#!/bin/bash
cache_dir="%s"
lock_file="$cache_dir/lock"
partial_dir="$cache_dir/partial"

dpkg %s %s | tee %s
echo Result: $? > %s

if [ -f $lock_file ] ; then
    rm -f $lock_file
fi

if [ -d $partial_dir ] ; then
    rmdir $partial_dir
fi
""";
        string install_log_file = Path.build_filename(_base_mgr.temporary_directory , "install-log.txt");
        string install_result_file = Path.build_filename(_base_mgr.temporary_directory , "install-result.txt");

        string config_params = _base_mgr.main_configuration_file.get_value("dpkg-parameters");
        string cache_dir = _proj.packages_directory;
        config_params = config_params!=null?config_params:"";
        string packages = "";

        foreach (Package p in _packages) {
            string filename = File.new_for_path(p.filename).get_basename();
            packages += "\"" + Path.build_filename(_proj.packages_directory , filename) + "\" ";
        }
        packages = packages.strip();

        install_script = install_script.printf(cache_dir, config_params,packages,install_log_file, install_result_file);
        return _run(install_script);
    }

    private int _run(string install_script) {
        int res = 0;
        string install_result_file = Path.build_filename(_base_mgr.temporary_directory , "install-result.txt");
        string install_log_file = Path.build_filename(_base_mgr.temporary_directory , "install-log.txt");
        string? enable_shellinabox = _base_mgr.main_configuration_file.get_value("enable-shellinabox");

        var install_script_file = File.new_for_path(Path.build_filename (_base_mgr.temporary_directory, "install.sh"));

        started();

        try {
            if (install_script_file.query_exists())
                install_script_file.delete();
            var stream = new DataOutputStream(install_script_file.create(FileCreateFlags.REPLACE_DESTINATION));
            stream.put_string(install_script);
            stream.close();

            ProcessManager.run_get_status(new string[]{"chmod","+x",Path.build_filename(_base_mgr.temporary_directory,"install.sh")});

            if (enable_shellinabox != "true") {
                string terminal = find_terminal();
                if (terminal == null) {
                    stdout.printf("Error: Unable to find terminal\n");
                    failed("Unable to find terminal");
                    return InstallationResultType.NO_TERMINAL;
                }

                res = ProcessManager.run_get_status (new string[]{_base_mgr.root_command_file,terminal,"-e","\""+install_script_file.get_path()+"\""});

                // If terminal is not xterm, wait until default installer main process is complete.
                if (!terminal.has_suffix("xterm")) {
                    Thread.usleep(1000000);
                    while(ProcessManager.run_get_status(new string[]{"pgrep", _default_installer}) == 0) {
                        stdout.printf("[Server] Waiting for %s to finish.\n", _default_installer);
                        Thread.usleep(1000000);
                    }
                }
            } else {
                string? shellinabox_path = Which.which ("shellinaboxd",_base_mgr);
                if (shellinabox_path != null) {
                    var shellinabox_parameters = _base_mgr.main_configuration_file.get_value("shellinabox-parameters");
                    var shellinabox_port = _base_mgr.main_configuration_file.get_value("shellinabox-port");

                    ShellInABox snb = new ShellInABox(shellinabox_path,_base_mgr.temporary_directory,shellinabox_port,shellinabox_parameters);
                    snb.run("sudo bash "+install_script_file.get_path());
                } else {
                    stdout.printf("Error: Unable to find shellinaboxd\n");
                    failed ("Unable to find shellinaboxd");
                    return InstallationResultType.FAILED;
                }
            }

            if (res == 0) {
                var file = File.new_for_path(install_result_file);
                if (file.query_exists()) {
                    var instream = new DataInputStream(file.read());
                    string line;
                    int result = 0;
                    bool complete = true;
                    while ((line = instream.read_line(null,null)) != null) {
                        if (line.contains("Incomplete"))
                            complete = false;
                        if (line.contains("Error"))
                            result = -1;
                        if (line.contains("Result"))
                            result = int.parse(line.split(":",2)[1].strip());
                    }

                    if (!complete) {
                        failed ("More packages are needed to be downloaded. See " + install_log_file + " file for details.");
                        return InstallationResultType.INCOMPLETE;
                    }
                    if (result != 0) {
                        failed ("Failed to install package(s). See " + install_log_file + " file for details.");
                        return InstallationResultType.FAILED;
                    }
                }
            } else {
                failed ("Failed to install package(s). See " + install_log_file + " file for details.");
                return InstallationResultType.FAILED;
            }
        } catch (Error e) {
            failed (e.message);
            return InstallationResultType.FAILED;
        }

        finished();
        return InstallationResultType.SUCCESS;
    }

    private string? find_terminal() {
        string terminals = _base_mgr.main_configuration_file.get_value("terminals");
        if (terminals != null) {
            if (terminals.contains(";")) {
                foreach (string terminal in terminals.split(";",-1)) {
                    string? path = Which.which(terminal.strip(),_base_mgr);
                    if (path != null)
                        return path;
                }
            }

            string? path = Which.which(terminals.strip(),_base_mgr);
            if (path != null)
                return path;
        }

        return null;
    }
}