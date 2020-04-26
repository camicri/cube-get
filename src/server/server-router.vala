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

public delegate void Handler(Request req, Response res);

public class RouterHandler {
    public Handler handler;

    public RouterHandler (Handler handler) {
        this.handler = handler;
    }
}

public class CubeServerRouter : GLib.Object {
    public TreeMap<string,RouterHandler> _mappings = new TreeMap<string, RouterHandler>();
    public TreeMap<string,RouterHandler> _mappings_pattern = new TreeMap<string, RouterHandler>();

    public CubeServerRouter () {
    }

    public void add(string location, Handler handler) {
        if (location.has_suffix("*"))
            this._mappings_pattern[location.replace("*","")] = new RouterHandler(handler);
        else
            this._mappings[location] = new RouterHandler(handler);
    }

    public void addRouterClass(RouterClass rc) {
        foreach (string key in rc.mappings.keys)
            this._mappings[key] = rc.mappings[key];
    }

    public bool go(string location, Request req, Response res) {
        stdout.printf("[Router] %s\n", location);
        if (this._mappings.has_key (location)) {
            this._mappings[location].handler(req, res);
            return true;
        } else {
            foreach (string location_pattern in this._mappings_pattern.keys) {
                if (location.has_prefix(location_pattern)) {
                    this._mappings_pattern[location_pattern].handler(req, res);
                    return true;
                }
            }
        }

        stdout.printf("[Router] ERROR: Location %s not found\n", location);
        res.send404();

        return false;
    }
}

public class Request {
    public HashTable<string, string> query;
    public CubeServerSystem css;

    public Request(HashTable<string, string> query, CubeServerSystem css) {
        this.query = query;
        this.css = css;
    }
}

public class Response {
    Soup.Message _msg;

    public Response(Soup.Message msg) {
        this._msg = msg;
    }

    public void send(string content, string type = "text/plain") {
        this._msg.set_status(200);
        this._msg.response_headers.append("Access-Control-Allow-Origin", "*");
        this._msg.set_response(type, Soup.MemoryUse.COPY, content.data);
    }

    public void sendFile(string path, string type = "text/plain") {
        uint8[] content = null;
        try {
            File f = File.new_for_path(path);
            if (f.query_exists())
                FileUtils.get_data(path , out content);
            else
            {
                this.send404();
                return;
            }
        } catch (Error e) {
            this.send404();
            return;
        }

        this._msg.set_status(200);
        this._msg.response_headers.append("Access-Control-Allow-Origin", "*");
        this._msg.set_response(type, Soup.MemoryUse.COPY, content);
    }

    public void send404() {
        this._msg.response_headers.append("Access-Control-Allow-Origin", "*");
        this._msg.set_status(404);
    }
}

/*
public class Response
{
    OutputStream _output_stream;

    public Response (OutputStream output_stream) {
        this._output_stream = output_stream;
    }

    public bool send(string content, string type = "text/plain") {
        return this.write(content.data, content.data.length, type);
    }

    public bool sendFile(string path, string type = "text/plain") {
        uint8[] content = null;
        try {
            File f = File.new_for_path(path);
            if (f.query_exists())
                FileUtils.get_data(path , out content);
            else
            {
                this.send404();
                return false;
            }
        } catch(Error e) {
            this.send404();
            return false;
        }

        return this.write(content, content.length, type);
    }

    public bool send404 () {
        try {
            var header = new StringBuilder ();
            header.append ("HTTP/1.0 404 Not Found\r\n");
            this._output_stream.write (header.str.data);
            this._output_stream.flush();
            this._output_stream.close();
        } catch(Error e) {
            return false;
        }
        return true;
    }

    public bool write(uint8[] content_data, int content_length, string type) {
        try {
            var header = new StringBuilder ();

            header.append ("HTTP/1.0 200 OK\r\n");
            header.append ("Access-Control-Allow-Origin: *\r\n");
            header.append ("Content-Type: "+type.strip()+"\r\n");
            header.append_printf ("Content-Length: %lu\r\n\r\n", content_data.length);

            this._output_stream.write (header.str.data);

            if (content_data != null)
                _output_stream.write (content_data);
            else
                _output_stream.write ("".data);

            this._output_stream.flush();
            this._output_stream.close();

        } catch(Error e) {
            return false;
        }
        return true;
    }
}
*/