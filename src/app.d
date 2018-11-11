/*
 * Copyright (c) 2018 Kasokuz
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 *
 */
module app;

import std.file;
import std.json;
import std.net.curl : g = get;
import std.string : split, replace, capitalize;

import lighttp;

enum api = "https://api.snaildb.org/";

void main() {

	Server server = new Server();
	
	// index
	server.router.add(new Router());
	
	// robots.txt
	server.router.add(Get("robots.txt"), new CachedResource("text/plain", read("res/robots.txt")));
	
	// icon
	server.router.add(Get("favicon.ico"), new CachedResource("image/x-icon", read("res/favicon.ico")));
	
	// css
	foreach(string file ; dirEntries("res/style", SpanMode.shallow)) {
		debug server.router.add(Get("style/" ~ file[10..$]), new SystemResource("text/css", file));
		else server.router.add(Get("style/" ~ file[10..$]), new CachedResource("text/css", read(file)));
	}
	
	// javascript
	foreach(string file ; dirEntries("res/script", SpanMode.shallow)) {
		debug server.router.add(Get("script/" ~ file[11..$]), new SystemResource("application/javascript", file));
		else server.router.add(Get("script/" ~ file[11..$]), new CachedResource("application/javascript", read(file)));
	}
	
	// png images
	foreach(string file ; dirEntries("res/img", SpanMode.shallow)) {
		debug server.router.add(Get("img/" ~ file[8..$]), new SystemResource("image/png", file));
		else server.router.add(Get("img/" ~ file[8..$]), new CachedResource("image/png", read(file)));
	}
	
	// svg images
	foreach(string file ; dirEntries("res/svg", SpanMode.shallow)) {
		debug server.router.add(Get("img/" ~ file[8..$]), new SystemResource("image/svg+xml", file));
		else server.router.add(Get("img/" ~ file[8..$]), new CachedResource("image/svg+xml", read(file)));
	}
	
	// language files
	foreach(string file ; dirEntries("res/lang", SpanMode.shallow)) {
		debug server.router.add(Get("lang/" ~ file[9..$]), new SystemResource("application/json", file));
		else server.router.add(Get("lang/" ~ file[9..$]), new CachedResource("application/json", read(file)));
	}
	
	server.host("0.0.0.0", 3000);
	server.run();

}

class Router {

	string[string] raw;
	string[string][string] lang;
	TemplatedResource index;
	
	this() {
		// preload language files
		foreach(string file ; dirEntries("res/lang", SpanMode.shallow)) {
			immutable lang = file[9..$-5];
			this.raw[lang] = (cast(string)read(file)).replace("\n", "").replace("\r", "").replace("\t", "");
			JSONValue json = parseJSON(this.raw[lang]);
			foreach(key, value; json.object) {
				this.lang[lang][key] = value.str;
			}
		}
		index = new TemplatedResource("text/html", read("res/index.html"));
	}

	@Get(".*") _(Request request, Response response) {
		immutable _lang = request.headers.get("accept-language", "");
		immutable lang = _lang.length >= 2 && _lang[0..2] in this.lang ? _lang[0..2] : "en";
		string[string] data;
		data["lang"] = lang;
		data["title"] = this.lang[lang]["title"];
		data["description"] = this.lang[lang]["about-desc-0"];
		data["url"] = "https://snaildb.org" ~ request.path;
		data["preload_lang"] = this.raw[lang];
		data["preload_uri"] = "";
		data["preload_data"] = "{}";
		void setTitle(string title) {
			data["title"] = title ~ " - " ~ this.lang[lang]["title"];
		}
		void notFound() {
			data["title"] = this.lang[lang]["notfound"];
			data["description"] = this.lang[lang]["notfound-desc"];
			response.status = StatusCodes.notFound;
		}
		if(request.path.length > 1) {
			immutable split = request.path[1..$].split("/");
			if(split.length == 1) {
				switch(split[0]) {
					case "snail":
						setTitle(this.lang[lang]["list-superfamilies"]);
						break;
					case "taxonomer":
						setTitle(this.lang[lang]["list-taxonomers"]);
						break;
					case "search":
						//TODO
						break;
					case "sources":
						setTitle(this.lang[lang]["sources"]);
						data["description"] = this.lang[lang]["sources-desc"];
						break;
					default:
						notFound();
				}
			} else if(split[0] == "snail" && split.length <= 5) {
				final switch(split.length) {
					case 2:
						immutable uri = "getsnailbyname/" ~ split[1];
						immutable d = g(api ~ uri).idup;
						auto json = parseJSON(d);
						if(json["result"].type == JSON_TYPE.OBJECT) {
							setTitle(capitalize(json["result"]["name"].str));
							//TODO set description
							data["preload_uri"] = uri;
							data["preload_data"] = d;
						} else {
							notFound();
						}
						break;
					case 3:
						immutable uri = "getsnailbyname/" ~ split[1] ~ "/" ~ split[2];
						immutable d = g(api ~ uri).idup;
						auto json = parseJSON(d);
						if(json["result"].type == JSON_TYPE.OBJECT) {
							setTitle(capitalize(json["result"]["name"].str));
							//TODO set description
							data["preload_uri"] = uri;
							data["preload_data"] = d;
						} else {
							notFound();
						}
						break;
					case 4:
						immutable uri = "getsnailbyname/" ~ split[1] ~ "/" ~ split[2] ~ "/" ~ split[3];
						immutable d = g(api ~ uri).idup;
						auto json = parseJSON(d);
						if(json["result"].type == JSON_TYPE.OBJECT) {
							setTitle(capitalize(json["result"]["name"].str));
							//TODO set description
							data["preload_uri"] = uri;
							data["preload_data"] = d;
						} else {
							notFound();
						}
						break;
					case 5:
						immutable uri = "getsnailbyname/" ~ split[1] ~ "/" ~ split[2] ~ "/" ~ split[3] ~ "/" ~ split[4];
						immutable d = g(api ~ uri).idup;
						auto json = parseJSON(d);
						if(json["result"].type == JSON_TYPE.OBJECT) {
							setTitle(capitalize(json["result"]["name"].str));
							//TODO set description
							data["preload_uri"] = uri;
							data["preload_data"] = d;
						} else {
							notFound();
						}
						break;
				}
			}
		}
		this.index.apply(data).apply(request, response);
	}

}

debug class SystemResource : Resource {

	private immutable string path;
	
	this(string mime, string path) {
		super(mime);
		this.path = path;
	}
	
	override void apply(Request req, Response res) {
		this.uncompressed = read(path);
		super.apply(req, res);
	}

}
