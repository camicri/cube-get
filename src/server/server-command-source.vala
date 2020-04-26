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

public class ServerCommandSource : GLib.Object, RouterClass {
    public TreeMap<string, RouterHandler> mappings {get; set; default = new TreeMap<string, RouterHandler>();}

    public ServerCommandSource() {
        register("/cmd/source/add-ppa-repository", add_ppa_repository);
        register("/cmd/source/check-ppa-exists", check_ppa_exists);
    }

    public void add_ppa_repository (Request req, Response res) {
        string json = """ { "success" : "%s", "message" : "%s" } """;
        bool result = false;
        string message = "";

        if (!req.query.contains("ppa"))
            res.send(json.printf("false","PPA Not Given"));
        else if (!req.query.contains("sources_list_entry"))
            res.send(json.printf("false","Sources List Entry Not Given"));
        else if (!req.query.contains("release"))
            res.send(json.printf("false","Release Not Given"));
        else if (req.css.cube.source_manager.check_ppa_exists(req.query["ppa"]))
            res.send(json.printf("false","The Personal Package Archive '"+req.query["ppa"]+"' already exist"));
        else {
            result = req.css.cube.source_manager.create_ppa_source_list(req.query["ppa"],req.query["sources_list_entry"],req.query["release"]);

            if (result)
                req.css.cube.source_manager.scan_sources();

            res.send(json.printf(result.to_string(),message));
        }
    }

    public void check_ppa_exists (Request req, Response res) {
        string json = """ { "exists" : "%s", "message" : "%s" } """;

        if (!req.query.contains("ppa"))
            res.send(json.printf("false","PPA Not Given"));
        else if (req.css.cube.source_manager.check_ppa_exists(req.query["ppa"]))
            res.send(json.printf("true",""));
        else
            res.send(json.printf("false",""));
    }
}
