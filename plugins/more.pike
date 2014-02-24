inherit plugin_menu;

/* Magic: "Active-by-default" plugins

When this starts up, if there's no persist list, it compiles every plugin in
plugins-more to see if it has a constant 'plugin_active_by_default'. If it does,
it creates an entry with active=1; if not, it creates an entry with active=0.

Don't apply plugin_active_by_default to anything where there's really no downside to
having it active. Keep 'em in the main section. Use this only for plugins where it's
normal to have it, but might be logical to remove it - like statusbar entries, which
have to compete for space.
*/

//Prune the list of plugins to only what can be statted, and add any from plugins-more
mapping(string:mapping(string:mixed)) prune()
{
	mapping(string:mapping(string:mixed)) items=persist["plugins/more/list"]||([]);
	foreach (items;string fn;mapping plg) if (!file_stat(fn)) m_delete(items,fn);
	foreach (get_dir("plugins-more"),string fn) if (has_suffix(fn,".pike") && !items["plugins-more/"+fn])
	{
		//Try to compile the plugin. If that succeeds, look for a constant plugin_active_by_default;
		//if it's found, that's the default active state. (Normally, if it's present, it'll be 1.)
		program compiled; catch {compiled=compile_file("plugins-more/"+fn);};
		items["plugins-more/"+fn]=(["active":compiled && compiled->plugin_active_by_default]);
	}
	persist["plugins/more/list"]=items; //Autosave (even if nothing's changed, currently)
	return items;
}

constant menu_label="More plugins";
class menu_clicked
{
	inherit configdlg;
	mapping(string:mixed) windowprops=(["title":"Load more plugins"]);
	constant allow_rename=0;

	void create()
	{
		items=prune();
		::create("plugins/moreplugins");
		showwindow();
	}

	GTK2.Widget make_content()
	{
		return GTK2.Vbox(0,10)
			->pack_start(two_column(({
				"Filename",win->kwd=GTK2.Entry(),
				"",win->active=GTK2.CheckButton("Active"),
				"NOTE: Deactivating a plugin will not unload it.\nUse the /unload command or restart Gypsum.",0,
			})),0,0,0);
	}

	void load_content(mapping(string:mixed) info)
	{
		win->active->set_active(info->active);
	}

	void save_content(mapping(string:mixed) info)
	{
		int nowactive=win->active->get_active();
		if (!info->active && nowactive) function_object(G->G->commands->update)->build(selecteditem());
		info->active=nowactive;
		persist["plugins/more/list"]=items;
	}

	void delete_content(string kwd,mapping(string:mixed) info)
	{
		persist["plugins/more/list"]=items;
	}
}

void load_all()
{
	if (!G->G->commands->update) {call_out(load_all,0); return;} //Can't load other plugins without the /update command
	function build=function_object(G->G->commands->update)->build;
	foreach (persist["plugins/more/list"]||([]);string fn;mapping plg)
		if (plg->active) build(fn);
}

void create(string name)
{
	::create(name);
	prune();
	load_all();
}
