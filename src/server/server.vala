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

using Soup;
using Gee;

public class CubeWebsocketConnection {
     public ArrayList<WebsocketConnection> connections = new ArrayList<WebsocketConnection>();

     public CubeWebsocketConnection() {
     }

     public void emit(string event, string? data = null) {
         string json = "\"event\":\"%s\"".printf(event);

         if (data != null)
             json += ",\"data\":%s".printf(data);
         json = "{%s}".printf(json);

         stdout.printf("[WebSocket] %s : %s\n",event,data);

         foreach (WebsocketConnection conn in connections)
            conn.send_text(json);
     }
}

public class CubeServer : Server {
    int _port;
    public CubeServerRouter router;
    public CubeServerSystem css;
    MainLoop loop = new MainLoop ();

    public int port { get {return _port;} }

    public signal void started ();
    public signal void stopped ();
    public signal void error_occurred(string message);

    public CubeServer(int port, CubeServerSystem css,  CubeServerRouter router) {
        this._port = port;
        this.router = router;
        this.css = css;
        this.css.ws = new CubeWebsocketConnection();

        this.add_handler(null, process_request);

        this.add_websocket_handler ("/ws", null, null, (server, conn, path,
        client) => {
            conn.message.connect((item, msg)=>{
                stdout.printf("[WebSocket] Received '%s'",(string)msg.get_data());
                conn.send_text("{\"success\":true}");
            });

            conn.closed.connect(()=>{
                this.css.ws.connections.remove(conn);
            });

            this.css.ws.connections.add(conn);

            if (this.css.ws.connections.size > 1) {
                stdout.printf("[WebSocket] WARNING: %d Cube instances detected. Please close other instances to prevent conflicts.\n", this.css.ws.connections.size);
            }
        });
    }

    public void process_request(Server server, Message msg, string path, GLib.HashTable<string,string>? query, ClientContext client) {
        HashTable<string,string> map_query = query;

        if (map_query == null)
            map_query = new HashTable<string,string>(str_hash, str_equal);

        map_query["location"] = path;

        Request req = new Request(map_query, css);
        Response res = new Response(msg);

        this.router.go(req.query["location"], req, res);
    }

    public void stop_server() {
        this.disconnect();
        this.loop.quit();
    }

    public bool start() {
        this.started();
        try {
            this.listen_all(this.port,0);
        } catch (Error e) {
            stdout.printf("[Server] ERROR: %s\n",e.message);
        }
        loop.run();
        this.stopped();
        return true;
    }
}