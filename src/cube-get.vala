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
using Soup;

public class Main {
    static CubeServer server;
    static CubeServerRouter router;
    static CubeServerSystem css;

    static int option_port = 0;
    static bool option_no_ui = false;
    static bool option_terminal = false;
    static string option_parent_directory = null;

    private const GLib.OptionEntry[] options = {
        {"api-mode", 0, 0, OptionArg.NONE, ref option_no_ui, "Run with no user interface", null},
        {"port", 0, 0, OptionArg.INT, ref option_port, "Port to use", "PORT"},
        {"terminal", 0, 0, OptionArg.NONE, ref option_terminal, "Terminal mode"},
        {"parent-directory", 0, 0, OptionArg.STRING, ref option_parent_directory, "Cube parent directory", "PATH"},
        {null}
    };

    public static int main (string[] args) {
        try {
            var opt_context = new OptionContext ("- CubeGet");
            opt_context.set_help_enabled (true);
            opt_context.add_main_entries (options, null);
            opt_context.parse (ref args);
        } catch (OptionError e) {
            printerr ("error: %s\n", e.message);
            printerr ("Run '%s --help' to see a full list of available command line options.\n", "cube-get");
            return 1;
        }

        if (!Thread.supported ()) {
            stderr.printf ("[Init] ERROR: Cannot run without thread support.\n");
            return 1;
        }

        if (!initialize_cube_system()) {
            stdout.printf("[Init] ERROR: Failed to initialize Cube System\n");
            return 1;
        }

        if (!initialize_router()) {
            stdout.printf("[Init] ERROR: Failed to initialize Router\n");
            return 1;
        }

        if (initialize_server()) {
            server.start();
        }
        else
            stdout.printf("[Init] ERROR: Failed to start server!\n");

        return 0;
    }

    public static bool initialize_cube_system() {
        string data_dir = "";
        string projs_dir = "";
        string cube_main_dir = Path.build_filename(Environment.get_current_dir());
        string cube_system_dir = "";

        if (option_parent_directory != null) {
            if (FileUtils.test(option_parent_directory,FileTest.EXISTS))
                cube_main_dir = option_parent_directory;
        }

        string cube_system_dir_linux = Path.build_filename(cube_main_dir,"cube-system");
        string cube_system_dir_win = Path.build_filename(cube_main_dir,"cube-system");

        if (SystemInformation.get_operating_system_type() == OperatingSystemType.LINUX) {
            data_dir = Path.build_filename(cube_system_dir_linux ,"data");
            projs_dir = Path.build_filename(cube_main_dir ,"projects");
            cube_system_dir = cube_system_dir_linux;

            LinuxInformation linux_info = new LinuxInformation();
            if (linux_info.computer_name == "root") {
                stdout.printf("[Init] ERROR : Running cube-server with superuser privileges is not allowed.\n");
                return false;
            }
        } else if (SystemInformation.get_operating_system_type() == OperatingSystemType.WINDOWS) {
            data_dir = Path.build_filename(cube_system_dir_win ,"data");
            projs_dir = Path.build_filename(cube_main_dir ,"projects");
            cube_system_dir = cube_system_dir_win;
        }

        if (FileUtils.test(cube_system_dir, FileTest.EXISTS))
            Environment.set_current_dir(cube_system_dir);
        else {
            stdout.printf("[Init] ERROR: Invalid parent directory %s. Please specify correct directory. Example: ./cube-get --parent-directory=/home/user/cube-get\n", cube_main_dir);
            return false;
        }

        css = new CubeServerSystem();

        if (!css.initialize_cube_system(data_dir,projs_dir))
            return false;
        else
            return true;
    }

    public static bool initialize_router() {
        router = new CubeServerRouter();

        router.addRouterClass(new ServerCommandSystem());
        router.addRouterClass(new ServerCommandProject());
        router.addRouterClass(new ServerCommandRepository());
        router.addRouterClass(new ServerCommandDownload());
        router.addRouterClass(new ServerCommandInstall());
        router.addRouterClass(new ServerCommandUpdate());
        router.addRouterClass(new ServerCommandSource());
        router.addRouterClass(new ServerCommandConfiguration());

        router.add("/", (req, res) => {
            req.query["location"] = "/static/html/index.html";
            router.go(req.query["location"], req, res);
        });

        router.add("/favicon.ico", (req, res) => {
            req.query["location"] = "/static/images/favicon.ico";
            router.go(req.query["location"], req, res);
        });

        router.add("/static/*", (req, res) => {
            string location = req.query["location"];
            string mime_type = "text/plain";

            if (location.has_prefix("/static/js"))
                mime_type = "application/javascript";
            else if (location.has_prefix("/static/css"))
                mime_type = "text/css";
            else if (location.has_prefix("/static/html"))
                mime_type = "text/html";
            else if (location.has_prefix("/static/images")) {
                if (location.has_suffix(".svg"))
                    mime_type = "image/svg+xml";
                else
                   mime_type = "image/";
            }
            else if (location.has_prefix("/static/fonts"))
                mime_type = "text/fonts";

            location = location.replace("/static/","");
            location = Path.build_filename(req.css.cube.base_manager.main_directory, "server", location);
            res.sendFile(location, mime_type);
        });

        router.add("/cmd/bye", (req, res)=>{
            res.send("{\"success\":true}");
            req.css.emitEvent("quit");

            Thread.usleep (1000);
            server.stop_server();
        });

        return true;
    }

    public static bool initialize_server() {
        int port = 8080;

        if (option_port != 0) {
            port = option_port;
        } else {
            string? config_port = "";

            config_port = css.cube.base_manager.main_configuration_file.get_value("server-port");

            if (config_port != null) {
                port = (uint16)int.parse(config_port);
                if (port <= 0)
                    port = 8080;
            }
        }

        stdout.printf("[Server] Using port %d\n", port);
        server = new CubeServer(port, css, router);

        server.started.connect(server_started);
        server.stopped.connect(server_stopped);
        server.error_occurred.connect(server_error_occurred);

        return true;
    }

    public static void server_started () {
        stdout.printf("[Server] Started\n");

        if (option_no_ui) {
            stdout.printf("[Server] Running without user interface (API Mode)");
            return;
        }

        /* Launch Browser */
        bool result = ProcessManager.run_default_application("http://localhost:"+server.port.to_string());
        if (!result)
            stdout.printf("[Server] WARNING: Unable to open web browser. Please do it manually by opening a web browser and navigate to http://localhost:%d", server.port);
    }

    public static void server_stopped () {
        stdout.printf("[Server] Stopped\n");
    }

    public static void server_error_occurred(string message) {
        stdout.printf("[Server] Error : %s\n", message);
    }
}