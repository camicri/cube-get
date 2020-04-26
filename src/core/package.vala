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

public enum PackageStatusType { AVAILABLE=0, INSTALLED=1, UPGRADABLE=2, DOWNLOADED=3, NEWER=4 }

public class Package : GLib.Object , Comparable<Package> {
    public string? name { get; set; default = null; }
    public string? version { get; set; default = null; }
    public string? installed_version { get; set; default = null ; }
    public string? description { get; set; default = null; }
    public string? depends { get; set; default = null; }
    public string? reverse_depends { get; set; default = null; }
    public string? filename { get; set; default = null; }
    public string? size { get; set; default = null; }
    public string? installed_size { get; set; default = null; }
    public string? recommends { get; set; default = null; }
    public string? pre_depends { get; set; default = null; }
    public string? provides { get; set; default = null; }
    public string? suggests { get; set; default = null; }
    public string? conflicts { get; set; default = null; }
    public string? breaks { get; set; default = null; }
    public string? md5sum { get; set; default = null; }
    public string? section { get; set; default = null; }
    public int? status { get; set; default = PackageStatusType.AVAILABLE; }
    public string? status_string { get; set; default = null; }
    public int? old_status { get; set; default = null; }
    public string? extra { get; set; default = null ; }
    public bool forced { get; set; default = false ; }
    public int source_index { get; set; default = -1; }

    public string? get_value(string key) {
        if (key == "Package")
            return name;
        if (key == "Version")
            return version;
        if (key == "Installed Version")
            return installed_version;
        if (key == "Description")
            return description;
        if (key == "Depends")
            return depends;
        if (key == "Reverse Depends")
            return reverse_depends;
        if (key == "Filename")
            return filename;
        if (key == "Size")
            return size;
        if (key == "Installed-Size")
            return installed_size;
        if (key == "Recommends")
            return recommends;
        if (key == "Pre-Depends")
            return pre_depends;
        if (key == "Suggests")
            return suggests;
        if (key == "Provides")
            return provides;
        if (key == "Conflicts")
            return conflicts;
        if (key == "Breaks")
            return breaks;
        if (key == "MD5sum")
            return md5sum;
        if (key == "Section")
            return section;
        if (key == "Status")
            return status_string;
        /*
        if (key == "Old Status")
            return old_status;
        */

        return null;
    }

    public bool set_value(string key, string? val) {
        if (key == "Package")
            name = val;
        else if (key == "Version")
            version = val;
        else if (key == "Installed Version")
            installed_version = val;
        else if (key == "Description")
            description = val;
        else if (key == "Depends")
            depends = val;
        else if (key == "Reverse Depends")
            reverse_depends = val;
        else if (key == "Filename")
            filename = val;
        else if (key == "Size")
            size = val;
        else if (key == "Installed-Size")
            installed_size = val;
        else if (key == "Recommends")
            recommends = val;
        else if (key == "Pre-Depends")
            pre_depends = val;
        else if (key == "Provides")
            provides = val;
        else if (key == "Suggests")
            suggests = val;
        else if (key == "Conflicts")
            conflicts = val;
        else if (key == "Breaks")
            breaks = val;
        else if (key == "MD5sum")
            md5sum = val;
        else if (key == "Section") {
            if (val.contains("/"))
                section = val.split("/",-1)[1];
        }
        else if (key == "Status")
            status_string = val;
        /*
        else if (key == "Old Status")
            old_status = val;
        */
        else
            return false;
        return true;
    }

    public int compare_to(Package pkg) {
        return DebianCompare.compare(this.version, pkg.version);
    }

    public static Gee.EqualDataFunc<Package>? equal_function = (a, b) => {
        if (a.name.has_prefix(b.name)) {
            return true;
        }
        return false;
    };

    public static Gee.EqualDataFunc<Package>? equals = (a, b) => {
        if (a.name == b.name) {
            return true;
        }
        return false;
    };

    public static GLib.CompareDataFunc<Package>? compare_function = (a, b) => {
        return strcmp(a.name , b.name);
    };
}
