void create(string n,string which)
{
	array(string) arr=indices(this);
	if (which && which!="") arr=which/" ";
	foreach (arr,string f) if (f!="create") add_constant(f,this[f]);
}

//Usage: Instead of G->G->asdf->qwer(), use bouncer("asdf","qwer") and it'll late-bind.
class bouncer(string ... keys)
{
	mixed `()(mixed ... args)
	{
		mixed func=G->G; foreach (keys,string k) func=func[k];
		return func(@args);
	}
}

//Usage: gtksignal(some_object,"some_signal",handler,arg,arg,arg) --> save that object.
//Equivalent to some_object->signal_connect("some_signal",handler,arg,arg,arg)
//When it expires, the signal is removed. obj should be a GTK2.G.Object or similar.
class gtksignal(object obj)
{
	int signal_id;
	void create(mixed ... args) {signal_id=obj->signal_connect(@args);}
	void destroy() {obj->signal_disconnect(signal_id);}
}

object persist=class(string savefn)
{
	//Persistent storage (when this dies, bring it back with a -1/-1 counter on it).
	//It's also undying storage. When it dies, bring it back one way or the other. :)
	/* Usage:
	 * persist["some/string/identifier"]=any_value;
	 * retrieved_value=persist["some/string/identifier"];
	 * old_value=m_delete(persist,"some/string/identifier");
	 * Saves to disk after every change. Loads from disk only on initialization - /update this file to reload.
	 * Note that saving is done with a call_out(0), so you can freely batch your modifications without grinding the disk too much - especially if your code is itself happening on the backend thread.
	 **/

	/* Idea: Encrypt the file with a password.
	string pwd;
	string key=Crypto.SHA256.hash("Gypsum"+string_to_utf8(pwd)+"Gypsum");
	string content=encode_value(data);
	int pad=16-sizeof(content)%16; //Will always add at least 1 byte of padding; if the data happens to be a multiple of 16 bytes, will add an entire leading block of padding.
	content=(string)allocate(pad,pad)+content;
	string enc=Crypto.AES.encrypt(key,content);

	if (catch {
		string dec=Crypto.AES.decrypt(key,enc);
		if (dec[0]>16) throw(1); //Must be incorrect password - the padding signature is damaged.
		dec=dec[dec[0]..]; //Trim off the padding
		data=decode_value(dec);
	}) error("Incorrect password.");
	*/

	mapping(string:mixed) data=([]);
	int saving;

	void create()
	{
		catch //Ignore any errors, just have no saved data.
		{
			Stdio.File f=Stdio.File(savefn);
			if (!f) return;
			string raw=f->read();
			if (!raw) return;
			mixed decode=decode_value(raw);
			if (mappingp(decode)) data=decode;
		};
	}
	mixed `[](string idx) {return data[idx];}
	mixed `[]=(string idx,mixed val)
	{
		if (!saving) {saving=1; call_out(save,0);}
		return data[idx]=val;
	}
	mixed _m_delete(string idx)
	{
		if (!saving) {saving=1; call_out(save,0);}
		return m_delete(data,idx);
	}
	void save()
	{
		saving=0;
		Stdio.File(savefn,"wct")->write(encode_value(data));
	}
}(".gypsumrc"); //Save file name. TODO: Make this configurable somewhere.
