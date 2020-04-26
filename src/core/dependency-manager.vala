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

public class DependencyFinder {
    public Gee.TreeMap<string,Package> available_packages { set; get; default = null; }
    public Gee.TreeMap<string,Package> installed_packages { set; get; default = null; }
    public Gee.TreeMap<string,string> provided_packages { set; get; default = null; }

    public bool treat_host_available_as_installed { set; get; default = false; }
    public bool enable_reverse_dependency_check { set; get; default = false; }

    bool debug_flag = false;

    //public DependencyFinder(Gee.HashMap<string,Package> available_packages, Gee.HashMap<string,Package> installed_packages)
    public DependencyFinder(Gee.TreeMap<string,Package> available_packages, Gee.TreeMap<string,Package> installed_packages, Gee.TreeMap<string,string> provided_packages) {
        this.available_packages = available_packages;
        this.installed_packages = installed_packages;
        this.provided_packages = provided_packages;
    }

    //TODO Process Breaks and Conflicts requirements
    //FIXME Is map_provides still needed? (Because of provided_packages map)
    public bool get_dependencies(Package pkg, ArrayList<Package> lst_dependencies, HashMap<string,DependencyItem> map_provides = new HashMap<string,DependencyItem>()) {
        //Check for reverse dependencies, if enabled
        if (enable_reverse_dependency_check)
            get_reverse_dependencies(pkg, lst_dependencies, map_provides);

        ArrayList<ArrayList<DependencyItem>> or_dependencies;
        ArrayList<DependencyItem> and_dependencies;

        string? dep_string = (pkg.depends!=null?pkg.depends:"");

        if (pkg.pre_depends != null)
            dep_string += (dep_string!=""?",":"")+pkg.pre_depends;
        if (pkg.recommends != null)
            dep_string += (dep_string!=""?",":"")+pkg.recommends;

        if (dep_string.strip().length == 0) {
            if (!lst_dependencies.contains(pkg))
                lst_dependencies.add(pkg);
        }

        //Chop chop dependency string
        DependencyListParser.parse_dependency_string (dep_string, out or_dependencies, out and_dependencies);

        //Process OR Relation Dependencies
        foreach (ArrayList<DependencyItem> dep_item_list in or_dependencies) {
            DependencyItem? dep_item_curr = null;
            bool skipped_by_provides = false;
            foreach (DependencyItem dep_item in dep_item_list) {
                //For available packages
                if (this.available_packages.has_key(dep_item.package_name)) {
                    Package p_curr = available_packages[dep_item.package_name];

                    //Prioritize installed/upgradable items
                    if (p_curr.status == null || (p_curr.status != PackageStatusType.AVAILABLE || p_curr.status != PackageStatusType.DOWNLOADED) || lst_dependencies.contains(p_curr)) {
                        dep_item_curr = dep_item;
                        break;
                    }
                    //Check if it is virtually provided by previously added dependencies
                    if (_check_provides(dep_item, map_provides)) {
                        dep_item_curr = null;
                        skipped_by_provides = true; //Mark me as satisfied by provides!
                        break;
                    }
                    //If still not satisfied by above requirements, pick the first package
                    if (dep_item_curr == null)
                        dep_item_curr = dep_item;
                }
                //For not available packages (Maybe virtual package)
                //Check if it is virtually provided by previously added dependencies
                else if (_check_provides(dep_item, map_provides)) {
                    dep_item_curr = null;
                    skipped_by_provides = true; //Mark me as satisfied by provides!
                    break;
                } else if (dep_item_curr == null) {
                    Package? provider = _get_provider(dep_item);
                    if (provider != null) {
                        dep_item_curr = new DependencyItem.has_params(provider.name,null,null);
                        break;
                    }
                }

            }

            if (dep_item_curr != null) {
                and_dependencies.add(dep_item_curr);
            }

            //If OR package not satisified and no virtual package found
            else if (!skipped_by_provides) {
                stdout.printf("OR Dependency Not Satisfied for %s :(Panic!!\n", pkg.name);
                if (debug_flag) stdin.read_line();
            }
        }

        //And Relation Dependencies
        foreach (DependencyItem dep_item in and_dependencies) {
            //Check if it is virtually provided by previously added dependencies
            if (_check_provides(dep_item, map_provides))
                continue;

            //For not available packages (Maybe virtual package)
            if (!this.available_packages.has_key(dep_item.package_name)) {
                Package? provider = _get_provider(dep_item);
                if (provider != null)
                    dep_item = new DependencyItem.has_params(provider.name,null,null);
                else {
                    stdout.printf("AND Dependency Not Satisfied for %s. Provided package %s not found :(Panic!!\n", pkg.name,dep_item.package_name);
                    if (debug_flag) stdin.read_line();
                }
            }

            _get_dependencies_one(dep_item, /*ref*/ lst_dependencies, map_provides);
        }

        return true;
    }

    private bool _get_dependencies_one(DependencyItem dep_item, ArrayList<Package> lst_dependencies , HashMap<string,DependencyItem> map_provides = new HashMap<string,DependencyItem>()) {
        if (available_packages.has_key (dep_item.package_name)) {
            Package avail_pkg = available_packages[dep_item.package_name];

            //if (avail_pkg.status == "0" || avail_pkg.status == "-1" || (avail_pkg.status == "-2" && treat_downloaded_as_installed))
            if (avail_pkg.status == PackageStatusType.INSTALLED || avail_pkg.status == PackageStatusType.UPGRADABLE) {
                //Check if installed version is satisfied
                if (DebianCompare.compare_equality_string(avail_pkg.installed_version, dep_item.required_version, dep_item.equality_operator) == true) {
                    if (debug_flag) stdout.printf("Installed. Satisfied!\n");
                    //Dependency Satisfied
                    return true;
                }
                //Check if upgradable version / downloaded version is satisfied
                //else if (avail_pkg.status == "-1" || (avail_pkg.status == "-2" && treat_downloaded_as_installed))
                else if (avail_pkg.status == PackageStatusType.UPGRADABLE) {
                    if (DebianCompare.compare_equality_string(avail_pkg.version, dep_item.required_version, dep_item.equality_operator) == true) {
                        //Dependency Satisfied. Will add to dependency list because it is not installed
                        if (!lst_dependencies.contains(avail_pkg)) {
                            if (debug_flag) stdout.printf("Upgradable. Satisfied! Added\n");
                            _set_provides(avail_pkg , map_provides);
                            lst_dependencies.add(avail_pkg);
                            get_dependencies(avail_pkg , /*ref*/ lst_dependencies , map_provides);
                        } else if (debug_flag) stdout.printf("Upgradable. Satisfied! Already Exist\n");

                        return true;
                    } else {
                        //Dependency not satisfied and no way to resolve it :(Panic!!
                        if (debug_flag) stdout.printf("Upgradable. Not Satisfied! %s %s %s\n",avail_pkg.name,avail_pkg.version, dep_item.required_version);
                        if (debug_flag) stdin.read_line();
                        return false;
                    }

                } else {
                    //Dependency not satisfied and no way to resolve it :(Panic!!
                    if (debug_flag) stdout.printf("Available. Not Satisfied! %s %s %s %s\n",avail_pkg.name,avail_pkg.version, dep_item.equality_operator, dep_item.required_version);
                    if (debug_flag) stdin.read_line();
                    return false;
                }
            } else {
                if (DebianCompare.compare_equality_string(avail_pkg.version, dep_item.required_version, dep_item.equality_operator) == true) {
                    //Dependency Satisfied. Will add to dependency list because it is not installed
                    if (!lst_dependencies.contains(avail_pkg)) {
                        if (debug_flag) stdout.printf("%s Available. Satisfied. Added\n",avail_pkg.name);
                        lst_dependencies.add(avail_pkg);

                        _set_provides(avail_pkg , map_provides);
                        get_dependencies(avail_pkg , /*ref*/ lst_dependencies , map_provides);
                    } else if (debug_flag) stdout.printf("%s Available. Satisfied. Already Exist\n",avail_pkg.name);

                    return true;
                }
                else {
                    //Dependency not satisfied and no way to resolve it :(Panic!!
                    if (debug_flag) stdout.printf("Available. Not Satisfied! %s %s %s %s\n",avail_pkg.name,avail_pkg.version, dep_item.equality_operator, dep_item.required_version);
                    if (debug_flag) stdin.read_line();
                    return false;
                }
            }
        }
        else {
            //TODO Find package on installed packages and check if dependency is satisfied
            if (debug_flag) stdout.printf("%s Not Satisfied! Please check for installed packages!\n",dep_item.package_name);
            return false;
        }
    }

    private Package? _get_provider(DependencyItem item) {
        if (!provided_packages.has_key(item.package_name))
            return null;

        string[] providers;
        if (provided_packages[item.package_name].contains(","))
            providers = provided_packages[item.package_name].split(",",-1);
        else
            providers = new string[]{provided_packages[item.package_name]};

        Package? p = null;
        foreach (string provider in providers) {
            if (!available_packages.has_key(provider))
                continue;

            Package? p_curr = available_packages[provider];

            //Prioritize installed/upgradable/downloaded packages
            if ((p_curr.status != PackageStatusType.AVAILABLE || p_curr.status != PackageStatusType.DOWNLOADED) || p_curr.status != null) {
                p = p_curr;
                break;
            }
            //Get the first entry only (Experimental)
            else if (p == null)
                p = p_curr;
        }

        return p;
    }

    private void _set_provides (Package pkg, HashMap<string,DependencyItem> map_provides) {
        //Check for provided packages
        if (pkg.provides != null) {
            foreach (DependencyItem prov_dep_item in DependencyListParser.convert_string_list_to_dependency_item_list(pkg.provides)) {
                if (!map_provides.has_key (prov_dep_item.package_name))
                        map_provides[prov_dep_item.package_name] = prov_dep_item;
            }
        }
    }

    private bool _check_provides (DependencyItem dep_item, HashMap<string, DependencyItem> map_provides) {
        if (map_provides.size == 0)
            return false;

        //If the package has a required version, ignore provides
        if (dep_item.required_version != null)
            return false;

        if (map_provides.has_key(dep_item.package_name))
            return true;

        return false;
    }

    public bool get_reverse_dependencies(Package pkg, ArrayList<Package> lst_dependencies, HashMap<string,DependencyItem> map_provides = new HashMap<string,DependencyItem>()) {
        if (pkg.reverse_depends == null)
            return true;

        ArrayList<ArrayList<DependencyItem>> or_dependencies;
        ArrayList<DependencyItem> and_dependencies;

        //Chop chop dependency string
        DependencyListParser.parse_dependency_string (pkg.reverse_depends, out or_dependencies, out and_dependencies);

        foreach (DependencyItem item in and_dependencies) {
            if (DebianCompare.compare_equality_string(pkg.installed_version, item.required_version, item.equality_operator) == false) {
                if (DebianCompare.compare_equality_string(pkg.version.strip(), item.required_version.strip(), item.equality_operator) == true) {
                    Package pkg_rev = available_packages[item.package_name];
                    if (!lst_dependencies.contains(pkg_rev))
                        lst_dependencies.add(pkg_rev);
                    else
                        continue;

                    get_dependencies(pkg_rev , lst_dependencies, map_provides);
                } else
                    stdout.printf("Reverse Dependency not satisifed for %s of %s, %s %s %s\n",item.package_name, pkg.name, pkg.version, item.equality_operator, item.required_version);
            }
        }

        return true;
    }

}

public class DependencyListParser {
    public static void parse_dependency_string(string dependency_string, out ArrayList<ArrayList<DependencyItem>> or_dependencies, out ArrayList<DependencyItem> and_dependencies) {
        or_dependencies = new ArrayList<ArrayList<DependencyItem>>();
        and_dependencies = new ArrayList<DependencyItem>();

        string[] arr_raw_dep;

        if (dependency_string.contains(","))
            arr_raw_dep = dependency_string.split(",",-1);
        else if (dependency_string.strip().length != 0)
            arr_raw_dep = new string[]{dependency_string};
        else
            arr_raw_dep = {};

        foreach (string dep in arr_raw_dep) {
            //Or relation dependency here
            if (dep.contains("|")) {
                ArrayList<DependencyItem> dep_or_list = new ArrayList<DependencyItem>();
                string[] arr_dep_or = dep.split("|",-1);
                foreach (string dep_or in arr_dep_or) {
                    DependencyItem dep_item = convert_to_dependency_item(dep_or.strip());
                    dep_or_list.add(dep_item);
                }
                or_dependencies.add(dep_or_list);
            }
            //And relation dependency here
            else {
                DependencyItem dep_item = convert_to_dependency_item(dep.strip());
                and_dependencies.add(dep_item);
            }
        }
    }

    public static ArrayList<DependencyItem> convert_string_list_to_dependency_item_list(string string_list) {
        ArrayList<DependencyItem> dep_item_list = new ArrayList<DependencyItem>();
        if (string_list.contains(",")) {
            foreach (string item in string_list.split(",",-1))
                dep_item_list.add(convert_to_dependency_item(item.strip()));
        } else
            dep_item_list.add(convert_to_dependency_item(string_list.strip()));

        return dep_item_list;
    }

    public static DependencyItem convert_to_dependency_item(owned string dependency_string_item) {
        DependencyItem dep_item = new DependencyItem();
        if (dependency_string_item.contains("(")) {
            dependency_string_item = dependency_string_item.replace("(","").replace(")","").strip();
            string[] arr_segments = dependency_string_item.split(" ",3);
            dep_item.package_name = arr_segments[0].strip();
            dep_item.equality_operator = arr_segments[1].strip();
            dep_item.required_version = arr_segments[2].strip();
        } else
            dep_item.package_name = dependency_string_item;

        if (dep_item.package_name.contains(":"))
            dep_item.package_name = dep_item.package_name.split (":")[0].strip();

        return dep_item;
    }
}

public class DependencyItem {
    public string package_name { get; set; default = null; }
    public string? required_version { get; set; default = null ; }
    public string? equality_operator { get; set; default = null; }

    public DependencyItem.has_params(string package_name , string? required_version, string? equality_operator) {
        this.package_name = package_name;
        this.required_version = required_version;
        this.equality_operator = equality_operator;
    }
}