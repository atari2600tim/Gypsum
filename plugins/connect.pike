inherit command;

/**
 * List of worlds available by default.
 */
mapping(string:mapping(string:mixed)) worlds=persist->setdefault("worlds",([
	"threshold":(["host":"thresholdrpg.com","port":23,"name":"Threshold RPG","descr":"Threshold RPG by Frogdice, a high-fantasy game with roleplaying required."]),
	"minstrelhall":(["host":"gideon.rosuav.com","port":221,"name":"Minstrel Hall","descr":"A virtual gaming shop where players gather to play Dungeons & Dragons online."]),
]));

/**
 * Displays the connection window dialog or attempts a connection to a world.
 *
 * @param 	The world to which to connect, or dlg option.
 * @return 	always returns 1
 */
int process(string param,mapping(string:mixed) subw)
{
	if (param=="dlg")
	{
		connectdlg();
		return 1;
	}
	if (param=="" && !(param=subw->world)) return listworlds("",subw);
	mapping info=worlds[param];
	if (!info)
	{
		if (sscanf(param,"%s%*[ :]%d",string host,int port) && port) info=(["host":host,"port":port,"name":sprintf("%s : %d",host,port)]);
		else {say(subw,"%% Connect to what?"); return 1;}
	}
	G->G->window->connect(info,param,subw || G->G->window->subwindow("New tab"));
	return 1;
}

/**
 * Disconnect from current world
 */
int dc(string param,mapping(string:mixed) subw) {G->G->window->connect(0,subw); return 1;}

/**
 * List all the worlds in the global list to the provided sub window
 *
 * @param param Unused
 * @param subw	The window in which to print the world list.
 */
int listworlds(string param,mapping(string:mixed) subw)
{
	say(subw,"%% The following worlds are recognized:");
	say(subw,"%%%%   %-14s %-20s %-20s %4s","Keyword","Name","Host","Port");
	foreach (sort(indices(worlds)),string kwd)
	{
		mapping info=worlds[kwd];
		say(subw,"%%%%   %-14s %-20s %-20s %4d",kwd,info->name,info->host,info->port);
	}
	say(subw,"%% Connect to any of the above worlds with: /connect keyword");
	say(subw,"%% Connect to any other MUD with: /connect host:port");
	return 1;
}

class connectdlg
{
	inherit configdlg;
	constant strings=({"name","host","logfile","descr","writeme"});
	constant ints=({"port"});
	constant bools=({"use_ka"});
	constant persist_key="worlds";

	mapping(string:mixed) windowprops=(["title":"Connect to a world"]);
	//TODO: Find a generic way to do this. I'm not happy with the actionbtn system, and this is the only place using it.
	//Am hereby deprecating it. Will maintain support for a while but won't use it anywhere new.
	//Hmm. Maybe separate "edit worlds" from "connect"? The dialog could be "edit worlds" and simply not _have_ a
	//button to connect to the world. Would that bug people?
	//Actually - yes it would. Don't do that. But there could be something other than an action button, maybe.
	string actionbtn="Save and C_onnect";

	void load_content(mapping(string:mixed) info)
	{
		if (!info->port) {info->port=23; win->port->set_text("23");}
		if (zero_type(info->use_ka)) win->use_ka->set_active(1);
	}

	void action_callback()
	{
		pb_save();
		string kwd=selecteditem();
		if (!kwd) return;
		mapping info=worlds[kwd];
		G->G->window->connect(info,kwd,0);
		win->mainwindow->destroy();
	}

	GTK2.Widget make_content()
	{
		return GTK2.Vbox(0,10)
			->pack_start(two_column(({
				"Keyword",win->kwd=GTK2.Entry(),
				"Name",win->name=GTK2.Entry(),
				"Host name",win->host=GTK2.Entry(),
				"Port",win->port=GTK2.Entry(),
				"Auto-log",win->logfile=GTK2.Entry(),
				"",win->use_ka=GTK2.CheckButton("Use keep-alive"), //No separate label
			})),0,0,0)
			->pack_start(GTK2.Frame("Description")->add(
				win->descr=MultiLineEntryField()->set_size_request(250,70)
			),1,1,0)
			->pack_start(GTK2.Frame("Text to output upon connect")->add(
				win->writeme=MultiLineEntryField()->set_size_request(250,70)
			),1,1,0)
		;
	}
}

void create(string name)
{
	::create(name);
	G->G->commands->dc=dc;
	G->G->commands->c=process;
	G->G->commands->worlds=listworlds;
}
