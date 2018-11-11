function displaySuperfamilies() {
	var snail = clean();
	setTitle(getLang("list-superfamilies"), "list-superfamilies");
	for(var superfamily in data.snails.superfamily) {
		var d = data.snails.superfamily[superfamily];
		var div = create("div");
		div.appendChild(createLink(capitalize(d.name), `/snail/${d.name}`));
		taxonomers(d, div);
		snail.appendChild(div);
	}
	showSection("snail");
}

function displaySuperfamily(superfamily) {
	var snail = clean();
	setTitle(capitalize(superfamily));
	addHeader(superfamily);
	for(var family in data.snails.superfamily[superfamily].families) {
		var d = data.snails.superfamily[superfamily].families[family];
		var div = create("div");
		div.appendChild(createLink(capitalize(d.name), `/snail/${superfamily}/${d.name}`));
		taxonomers(d, div);
		snail.appendChild(div);
	}
	showSection("snail");
}

function displayFamily(superfamily, family) {
	var snail = clean();
	setTitle(capitalize(family));
	addHeader(superfamily, family);
	for(var genus in data.snails.superfamily[superfamily].family[family].genuses) {
		var d = data.snails.superfamily[superfamily].family[family].genuses[genus];
		var div = create("div");
		div.appendChild(createLink(capitalize(d.name), `/snail/${superfamily}/${family}/${d.name}`));
		taxonomers(d, div);
		snail.appendChild(div);
	}
	showSection("snail");
}

function displayGenus(superfamily, family, genus) {
	var snail = clean();
	setTitle(capitalize(genus));
	addHeader(superfamily, family, genus);
	for(var species in data.snails.superfamily[superfamily].family[family].genus[genus].species) {
		var d = data.snails.superfamily[superfamily].family[family].genus[genus].species[species];
		var div = create("div");
		div.appendChild(createLink(capitalize(d.name), `/snail/${superfamily}/${family}/${genus}/${d.name}`));
		taxonomers(d, div);
		if(d.extinct) div.appendChild(create("span", "&nbsp;†"));
		snail.appendChild(div);
	}
	showSection("snail");
}

function displaySpecies(superfamily, family, genus, species) {
	setTitle(`${capitalize(genus)} ${capitalize(species)}`);
	var snail = clean();
	addHeader(superfamily, family, genus, species);
	var sp = data.snails.superfamily[superfamily].family[family].genus[genus].speciess[species];
	var p = create("p");
	p.className = "lang";
	p.dataset.lang = "species-desc" + (sp.extinct ? "-extinct" : "");
	p.dataset.args = [capitalize(genus) + " " + capitalize(species), sp.viviparous ? "viviparous" : "oviparous", sp.type + "-snail", capitalize(family)].join("|");
	updateLang([p]);
	snail.appendChild(p);
	var s = sp.subspecies;
	for(var subspecies in s) {
		var d = s[subspecies];
		var div = create("div");
		div.className = "subspecies";
		if(s.length != 1 || s[0].name != species) {
			div.appendChild(create("span", getLang("subspecies"), "subspecies"));
			div.appendChild(create("span", "&nbsp;"));
			div.appendChild(create("span", capitalize(d.name)));
			taxonomers(d, div);
		}
		//TODO size of the shell
		if(d.location) {
			const locations = d.location.split(",");
			var iso = [["Country"]];
			for(var i in locations) {
				const s = locations[i].split(".");
				iso.push([s[0].toUpperCase()]);
			}
			var map = create("div");
			map.style.height = "384px";
			div.appendChild(map);
			var chart = new google.visualization.GeoChart(map);
			chart.draw(google.visualization.arrayToDataTable(iso), {});
		}
		snail.appendChild(div);
	}
	showSection("snail");
}

function displayTaxonomers() {
	var snail = clean();
	setTitle(getLang("list-taxonomers"), "list-taxonomers");
	for(var i in data.taxonomers.list) {
		const t = data.taxonomers.list[i];
		var div = create("div");
		div.appendChild(createLink(t.name.length ? `${t.surname}, ${t.name}` : t.surname, `taxonomer/${t.surname.toLowerCase()}`));
		snail.appendChild(div);
	}
	showSection("snail");
}

function displayTaxonomer(taxonomer) {
	var snail = clean();
	const info = data.taxonomers[taxonomer];
	console.log(info);
	setTitle(`${info.name} ${info.surname}`);
	function display(type) {
		if(info[type].length > 0) {
			snail.appendChild(create("b", getLang(type), type));
			for(var i in info[type]) {
				const s = info[type][i];
				var p = create("p");
			}
		}
	}
	display("superfamilies");
	display("families");
	display("genuses");
	display("species");
	showSection("snail");
}

function clean() {
	var snail = document.getElementById("snail");
	snail.innerText = "";
	return snail;
}

function addHeader(...args) {
	const d = ["superfamily", "family", "genus", "species"];
	var table = create("table");
	table.style.marginBottom = "16px";
	for(var i=0; i<args.length-1; i++) table.appendChild(addHeaderImpl(d[i], args[i], "/snail/" + args.slice(0, i+1).join("/")));
	table.appendChild(addHeaderImpl(d[args.length-1], args[args.length-1]));
	document.getElementById("snail").appendChild(table);
}

function addHeaderImpl(desc, value, uri) {
	var tr = create("tr");
	var td1 = create("td");
	var td2 = create("td");
	td1.style.textAlign = "right";
	if(!uri) td1.style.verticalAlign = "top";
	td1.appendChild(create("span", getLang(desc), desc));
	if(!uri) td2.appendChild(create("b", capitalize(value)));
	else td2.appendChild(createLink(capitalize(value), uri));
	tr.appendChild(td1);
	tr.appendChild(td2);
	return tr;
}

function taxonomers(data, parent) {
	if(data.taxonomyYear > 0) {
		parent.appendChild(create("span", "&nbsp;("));
		for(var i in data.taxonomers) {
			parent.appendChild(createLink(data.taxonomers[i].surname, `/taxonomer/${data.taxonomers[i].surname.toLowerCase()}`));
			if(i == data.taxonomers.length - 2) parent.appendChild(create("span", " & "));
			else parent.appendChild(create("span", ", "));
		}
		parent.appendChild(create("span", data.taxonomyYear));
		parent.appendChild(create("span", ")"));
	}
	return parent;
}
