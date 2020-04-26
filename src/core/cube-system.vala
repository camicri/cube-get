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

public class CubeSystem : GLib.Object {
    //Managers
    private BaseManager _base_mgr;
    private SourceManager? _source_mgr;
    private RepositoryManager? _repo_mgr;
    private DependencyFinder? _dep_finder;
    private ProjectManager _proj_mgr;
    private DownloadManager? _dl_mgr;
    private InstallationManager? _instl_mgr;

    private Project? _proj;

    //Properties - Managers
    public BaseManager base_manager { get { return _base_mgr; } }
    public SourceManager source_manager { get { return _source_mgr; } }
    public RepositoryManager repository_manager { get { return _repo_mgr; } }
    public DependencyFinder dependency_finder { get { return _dep_finder; } }
    public ProjectManager project_manager { get { return _proj_mgr; } }
    public DownloadManager download_manager { get { return _dl_mgr; } set { _dl_mgr = value; } }
    public InstallationManager installation_manager { get { return _instl_mgr; } }

    //Signals
    public signal void process_progress_changed(string message, int progress_current , int progress_max);
    public signal void download_item_status_changed(int index, DownloadStatusType status_type, Downloader dl);

    public Project project { get { return _proj; } }

    public class CubeSystem(string base_directory = "data", string projects_directory = "projects") {
        _base_mgr = new BaseManager(base_directory, projects_directory);
    }

    public bool create_and_initialize_system() {
        _base_mgr.create_update_base();
        return initialize_system ();
    }

    public bool initialize_system() {
        if (!_check_base())
            return false;

        _base_mgr.process_progress_changed.connect((message, curr, max) => { process_progress_changed (message, curr, max); });
        _base_mgr.initialize_base();
        _proj_mgr = new ProjectManager(_base_mgr.projects_directory , _base_mgr);
        _proj_mgr.get_projects();

        return true;
    }

    private bool _check_base() {
        if (! _base_mgr.check_directories())
            _base_mgr.create_directories();
        if (! _base_mgr.check_configuration_files())
            _base_mgr.create_configuration_files();

        if (!_base_mgr.check_directories() || !_base_mgr.check_configuration_files())
            return false;

        return true;
    }

    public ArrayList<Project> get_projects() {
        _proj_mgr.get_projects();
        return _proj_mgr.all_projects;
    }

    public bool create_project(string project_name) {
        Project p = new Project(project_name, _base_mgr.projects_directory , _base_mgr);
        if (p.create_project()) {
            _proj_mgr.get_projects();
            _proj = p;

            return true;
        }
        return false;
    }

    public void open_project(Project p) {
        _proj = p;

        if (_repo_mgr != null)
            _repo_mgr.reset_all();

        _source_mgr = new SourceManager(_proj.sources_directory, _proj.architecture);
        _repo_mgr = new RepositoryManager(_base_mgr, _source_mgr, _proj.list_directory);
        _instl_mgr = new InstallationManager(_base_mgr, _source_mgr, _proj);

        _proj.process_progress_changed.connect((message, curr, max) => { process_progress_changed (message, curr, max); });
        _repo_mgr.process_progress_changed.connect((message, curr, max) => { process_progress_changed (message, curr, max); });

        //Update the project status file if in original Linux computer
        if (SystemInformation.get_operating_system_type () == OperatingSystemType.LINUX)
            _proj.update_project_status_file();
    }

    public Project? find_project(string project_name) {
        foreach (Project p in _proj_mgr.all_projects) {
            if (p.project_name == project_name)
                return p;
        }
        return null;
    }

    public bool scan_repositories() {
        if (_repo_mgr == null)
            return false;

        _repo_mgr.scan_repositories();
        remark_packages();

        _dep_finder = new DependencyFinder(_repo_mgr.available_packages, _repo_mgr.installed_packages, _repo_mgr.provided_packages);

        return true;
    }

    public bool scan_status_repository() {
        if (_repo_mgr == null)
            return false;

        _repo_mgr.scan_status_repository();
        remark_packages();

        _dep_finder = new DependencyFinder(_repo_mgr.available_packages, _repo_mgr.installed_packages, _repo_mgr.provided_packages);

        return true;
    }

    public bool download_all_repositories() {
        ArrayList<Source> sources_to_download = new ArrayList<Source>();

        foreach (Source s in _source_mgr.sources) {
            if (s.filename != "status")
                sources_to_download.add(s);
        }

        return download_repositories(sources_to_download.to_array());
    }

    public bool download_repositories(Source[] sources) {
        _dl_mgr = new DownloadManager.from_sources(sources, _proj.list_temp_directory, _base_mgr);

        _dl_mgr.item_status_changed.connect((index,type, dl) => {
            process_progress_changed ("Downloading Repositories...", index, _dl_mgr.sources.length);
            download_item_status_changed(index, type, dl);
            if (type == DownloadStatusType.FINISHED)
                Compressor.decompress(Path.build_filename(_proj.list_temp_directory , _dl_mgr.sources[index].filename + ".gz") , Path.build_filename(_proj.list_directory,_dl_mgr.sources[index].filename), _base_mgr);
        });

        _dl_mgr.start();
        process_progress_changed ("Downloading Repositories Complete...", _dl_mgr.sources.length, _dl_mgr.sources.length);

        return true;
    }

    public bool download_packages(Package[] pkgs) {
        _dl_mgr = new DownloadManager.from_packages (pkgs, _proj.packages_directory , _base_mgr);

        _dl_mgr.item_status_changed.connect((index,type,dl) => {
            process_progress_changed ("Downloading Packages...", index, pkgs.length);
            download_item_status_changed(index, type, dl);
        });

        _dl_mgr.start();
        process_progress_changed ("Downloading Packages Finished...", _dl_mgr.packages.length, _dl_mgr.packages.length);

        _repo_mgr.mark_downloaded_packages(_proj);
        return true;
    }

    public bool install_packages(Package[] pkgs) {
        process_progress_changed ("Installing Packages...", 0, 1);
        int res = _instl_mgr.start_installation(pkgs);
        _proj.update_project_status_file();

        if (res == InstallationResultType.SUCCESS) {
            process_progress_changed ("Installation Complete...", 1, 1);
            return true;
        }

        process_progress_changed ("Installation Failed...", 1, 1);
        return false;
    }

    public bool remark_packages() {
        if (_repo_mgr == null)
            return false;

        _repo_mgr.reset_mark_packages();
        _repo_mgr.mark_packages();
        _repo_mgr.mark_downloaded_packages(_proj);

        process_progress_changed ("Marking Packages...", 3, 3);

        return true;
    }

    public Package? find_package(string package_name) {
        if (_repo_mgr.available_packages.has_key(package_name))
            return _repo_mgr.available_packages[package_name];
        return null;
    }

    public ArrayList<Package>? get_dependencies(Package pkg , owned ArrayList<Package>? dependency_list = null) {
        if (_repo_mgr == null)
            return null;

        if (dependency_list == null)
            dependency_list = new ArrayList<Package>(Package.equals);

        dependency_list.add(pkg);

        _dep_finder.enable_reverse_dependency_check = true;
        _dep_finder.get_dependencies(pkg , dependency_list);

        return dependency_list;
    }

    public bool get_packages_dependencies(ArrayList<Package> pkgs , ArrayList<Package> unsatisfied_dependencies, ArrayList<Package> satisfied_dependencies = new ArrayList<Package>(Package.equals)) {
        if (_repo_mgr == null)
            return false;

        foreach (Package p in pkgs) {
            ArrayList<Package> curr_unsatisfied_dep = new ArrayList<Package>(Package.equals);
            ArrayList<Package> curr_satisfied_dep = new ArrayList<Package>(Package.equals);

            get_package_dependencies(p,curr_unsatisfied_dep,curr_satisfied_dep);

            foreach (Package p_curr in curr_unsatisfied_dep) {
                if (!unsatisfied_dependencies.contains(p_curr))
                    unsatisfied_dependencies.add(p_curr);
            }

            foreach (Package p_curr in curr_satisfied_dep) {
                if (!satisfied_dependencies.contains(p_curr))
                    satisfied_dependencies.add(p_curr);
            }
        }

        satisfied_dependencies.sort(Package.compare_function);
        unsatisfied_dependencies.sort(Package.compare_function);

        return true;
    }

    public bool get_package_dependencies(Package pkg , ArrayList<Package> unsatisfied_dependencies, ArrayList<Package> satisfied_downloaded_dependencies = new ArrayList<Package>(Package.equals), ArrayList<Package>? dependency_list = null) {
        if (_repo_mgr == null)
            return false;

        if (pkg.status == PackageStatusType.INSTALLED)
            return true;

        foreach (Package p in get_dependencies(pkg, dependency_list)) {
            if (p.status != PackageStatusType.DOWNLOADED)
                unsatisfied_dependencies.add(p);
            else {
                if (!satisfied_downloaded_dependencies.contains(p))
                    satisfied_downloaded_dependencies.add(p);
            }
        }

        satisfied_downloaded_dependencies.sort(Package.compare_function);
        unsatisfied_dependencies.sort(Package.compare_function);

        return true;
    }

    public bool update_project() {
        return _proj.update_project();
    }

    public bool update_system() {
        return _proj.update_system();
    }

    public bool clean_project() {
        if (repository_manager.cleanup_packages_count > 0) {
            foreach (var path in repository_manager.cleanup_package_paths) {
                try {
                    File.new_for_path(path).delete();
                } catch(Error e) {
                    stdout.printf("Error: %s\n",e.message);
                }
            }

            repository_manager.reset_cleanup_packages();
        } else
            return false;

        return true;
    }
}
