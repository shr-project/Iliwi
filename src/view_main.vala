/*
    This file is part of iliwi.

    iliwi is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License Version 3
    as published by the Free Software Foundation.

    iliwi is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with iliwi.  If not, see <http://www.gnu.org/licenses/>.
*/

using Elm;
using Gee;

namespace iliwi.View {
  public const string SSL_CERT_DIR = "/etc/ssl/certs/";

  Win win;
  unowned Pager? pager;
  unowned Box? frontpage;
  unowned Label? status;
  unowned Button? button;
  unowned Label? cert_status;
  
  unowned Genlist? wifilist;
  GenlistItemClass itc;
  GenlistItemClass itc2;
  bool items_in_list;
  ArrayList<Certificate> ls;

  void show_main_window(string[] args) {
    Elm.init(args);
    
    items_in_list = false;
    
    itc = new GenlistItemClass();
    //itc.item_style = "double_label";
    itc.item_style = "default";
    itc.func.text_get = genlist_get_label;
    itc.func.content_get = null;
    itc.func.state_get = null;
    itc.func.del = null;

	itc2 = new GenlistItemClass();
    itc2.item_style = "default";
    itc2.func.text_get = certlist_get_label;
    itc2.func.content_get = null;
    itc2.func.state_get = null;
    itc2.func.del = null;
    
    generate_window();
    
    wifi.status_change.connect((t) => {
      status.text_set(wifi.status);
    });
    wifi.network_list_change.connect((t) => {
      button.disabled_set(false);
      if( items_in_list==false ) {
        refresh_list_elements();
      }
    });
    
    
    //Ecore.MainLoop.begin();
    Elm.run();
    Elm.shutdown();
    //Ecore.MainLoop.quit();
  }
  
  private void generate_window() {
    win = new Win(null, "main", WinType.BASIC);
    win.title_set("iliwi");
    win.smart_callback_add("delete,request", close_window_event );
    
    unowned Bg? bg = Bg.add(win);
    bg.size_hint_weight_set(1, 1);
    bg.show();
    win.resize_object_add(bg);
    
    pager = Pager.add(win);
    pager.size_hint_weight_set(1, 1);
    pager.size_hint_align_set(-1, -1);
    pager.show();
    
    frontpage = Box.add(win);
    frontpage.size_hint_weight_set(1, 1);
    frontpage.size_hint_align_set(-1, -1);
    frontpage.homogeneous_set(false);
    frontpage.show();
    
    wifilist = Genlist.add(win);
    wifilist.size_hint_weight_set(1, 1);
    wifilist.size_hint_align_set(-1, -1);
    refresh_list_elements();
    wifilist.show();
    frontpage.pack_end(wifilist);
    
    unowned Box? box = Box.add(win);
    box.horizontal_set(true);
    box.homogeneous_set(false);
    box.size_hint_weight_set(1,-1);
    box.size_hint_align_set(-1, -1);
    box.show();

    status = Label.add(win);
    status.size_hint_weight_set(0, 0);
    status.size_hint_align_set(0.5, 0.5);
    status.text_set(wifi.status);
    status.show();
    box.pack_end(status);
    
    button = Button.add(win);
    button.text_set("Refresh list");
    button.disabled_set(true);
    button.show();
    button.smart_callback_add("clicked", refresh_list_elements );
    box.pack_end(button);
    
    frontpage.pack_end(box);
    
    pager.content_push(frontpage);
    
    win.resize_object_add(pager);
    win.show();
  }
  
  private void close_window_event() {
    Elm.exit();
  }
  
  private void refresh_list_elements() {
    wifilist.clear();
    items_in_list = false;
    unowned GenlistItem? listitem_tmp;
    unowned GenlistItem? listitem_tmp2;
    foreach(Network network in wifi.get_visible_networks()) {
      // Find place (sorted by preferred > strength
      if( items_in_list == false )
        network.listitem = wifilist.item_append( itc, (void*)network, null, Elm.GenlistItemType.NONE, item_select );
      else {
        listitem_tmp = wifilist.first_item_get();
        Network list_network = (Network) listitem_tmp.data_get();
        bool found_place = false;
        while(found_place == false) {
          if( network.preferred_network && list_network.preferred_network==false ) {
            found_place = true;
            network.listitem = wifilist.item_insert_before( itc, (void*)network, null, listitem_tmp, Elm.GenlistItemType.NONE, item_select );
          } else if( list_network.preferred_network==network.preferred_network && list_network.strength<=network.strength ) {
            found_place = true;
            network.listitem = wifilist.item_insert_before( itc, (void*)network, null, listitem_tmp, Elm.GenlistItemType.NONE, item_select );
          } else { // Couldn't find a place to put it
            listitem_tmp2 = listitem_tmp.next_get();
            listitem_tmp = listitem_tmp2;
            if( listitem_tmp==null ) {
              found_place = true;
              network.listitem = wifilist.item_append( itc, (void*)network, null, Elm.GenlistItemType.NONE, item_select );
            } else
              list_network = (Network) listitem_tmp.data_get();
          }
        }
      }
      items_in_list = true;
      button.disabled_set(true);
    }
  }


  unowned Entry? password;
  unowned Entry? username;
  unowned Network network;
  //unowned Box? network_page;
  private void show_network(Network _network) {
    network = _network; 

    unowned Box? outer_box = Box.add(win);
    outer_box.homogeneous_set(false);
    outer_box.size_hint_weight_set(1, 1);
    outer_box.size_hint_align_set(-1, -1);
    outer_box.show();

    unowned Scroller? sc = Scroller.add(win);
    sc.bounce_set(false, false);
    sc.policy_set(Elm.ScrollerPolicy.OFF, Elm.ScrollerPolicy.AUTO);
    sc.size_hint_weight_set(1, 1);
    sc.size_hint_align_set(-1, -1);
    outer_box.pack_end(sc);
    sc.show();

    unowned Box? network_page = Box.add(win);
    network_page.homogeneous_set(false);
    network_page.size_hint_weight_set(1, 1);
    network_page.size_hint_align_set(-1, -1);
    sc.content_set(network_page);
    network_page.show();

    unowned Frame? title_padding = Frame.add(win);
    title_padding.style_set("pad_small");
    title_padding.size_hint_weight_set(1, 1);
    title_padding.size_hint_align_set(0.5, 0.5);
    title_padding.show();

    unowned Label? title = Label.add(win);
    title.size_hint_weight_set(1, 1);
    title.size_hint_align_set(0.5, 0.5);
    title.scale_set(2);
    title.text_set(network.get_title());
    title.show();
    title_padding.content_set(title);

    network_page.pack_end(title_padding);

    if(network.authentication) {
      unowned Frame? username_container = Frame.add(win);
      username_container.text_set("Username");
      username_container.size_hint_weight_set(1, -1);
      username_container.size_hint_align_set(-1, -1);
      username = Entry.add(win);
      username.single_line_set(true);
      username.entry_insert(network.username);
      username.show();
      username_container.content_set(username);
      username_container.show();
      network_page.pack_end(username_container);
    }

    if(network.encryption) {
      unowned Frame? password_container = Frame.add(win);
      password_container.text_set("Password");
      password_container.size_hint_weight_set(1, -1);
      password_container.size_hint_align_set(-1, -1);
      password = Entry.add(win);
      password.single_line_set( true );
      password.entry_insert(network.password);
      password.show();
      password_container.content_set(password);
      password_container.show();
      network_page.pack_end(password_container);
      
      if(!network.authentication) {
        unowned Check? ascii_hex = Check.add(win);
        ascii_hex.style_set("toggle");
        ascii_hex.text_set("Password format");
        ascii_hex.part_text_set("on", "ASCII");
		ascii_hex.part_text_set("off", "Hex");
        ascii_hex.smart_callback_add("changed", change_network_ascii_hex );
        ascii_hex.state_set(network.password_in_ascii);
        ascii_hex.show();
        network_page.pack_end(ascii_hex);
      }
    }

    if(network.authentication) {
      unowned Frame? certificate_container = Frame.add(win);
      certificate_container.text_set("Server Certificate");
      certificate_container.size_hint_weight_set(1, -1);
      certificate_container.size_hint_align_set(-1, -1);
      certificate_container.show();
 
      unowned Box? cert_box = Box.add(win);
      cert_box.homogeneous_set(false);
      cert_box.size_hint_weight_set(1,-1);
      cert_box.size_hint_align_set(-1, -1);
      cert_box.show();
      certificate_container.content_set(cert_box);

      cert_status = Label.add(win);
      cert_status.size_hint_weight_set(1, 1);
      cert_status.size_hint_align_set(-1, -1);
      certlist_text_set();
      cert_status.show();
      cert_box.pack_end(cert_status);

      unowned Box? cert_button_box = Box.add(win);
      cert_button_box.horizontal_set(true);
      cert_button_box.homogeneous_set(false);
      cert_button_box.size_hint_weight_set(1, -1);
      cert_button_box.size_hint_align_set(-1, -1);
      cert_button_box.show();

      unowned Button? cert_add_button = Button.add(win);
      cert_add_button.size_hint_weight_set(1, 1);
      cert_add_button.size_hint_align_set(-1, -1);
      cert_add_button.text_set("Select");
      cert_add_button.show();
      cert_button_box.pack_end(cert_add_button);
      cert_add_button.smart_callback_add("clicked", show_cert_chooser);

      unowned Button? cert_del_button = Button.add(win);
      cert_del_button.size_hint_weight_set(1, 1);
      cert_del_button.size_hint_align_set(-1, -1);
      cert_del_button.text_set("Clear");
      cert_del_button.show();
      cert_button_box.pack_end(cert_del_button);
      cert_del_button.smart_callback_add("clicked", clear_cert);

      cert_box.pack_end(cert_button_box);

      network_page.pack_end(certificate_container);
    }

    unowned Check? preferred = Check.add(win);
    preferred.style_set("toggle");
    preferred.smart_callback_add("changed", change_network_preferred );
    preferred.text_set( "Preferred network");
    preferred.part_text_set("on", "Yes");
	preferred.part_text_set("off", "No");
    preferred.state_set(network.preferred_network);
    preferred.show();
    network_page.pack_end(preferred);
    
    unowned Button? button = Button.add(win);
    button.size_hint_weight_set(1,-1);
    button.size_hint_align_set(-1,-1);
    button.text_set("Connect");
    button.disabled_set(network.status!=NetworkStatus.UNCONNECTED);
    button.show();
    button.smart_callback_add("clicked", connect_to );
    network_page.pack_end(button);
    
    button = Button.add(win);
    button.size_hint_weight_set(1,-1);
    button.size_hint_align_set(-1,-1);
    button.text_set("Back");
    button.show();
    button.smart_callback_add("clicked", back_to_list );
    network_page.pack_end(button);

    pager.content_push(outer_box);
  }

  public class Certificate : GLib.Object, Gee.Comparable<Certificate> {
    public string cert = "";
    public string cert_dir = "";
    public unowned GenlistItem? listitem = null;

    public Certificate (string _cert, string _cert_dir) {
      cert = _cert;
      cert_dir = _cert_dir;
    }

    public static string trim_cert_name(string full_cert_name) {
      string trimmed_name = full_cert_name.substring(0, (full_cert_name.length - 4));
      Regex line_regex_cert_name;
      try {
        line_regex_cert_name = new Regex("(_)");
        trimmed_name = line_regex_cert_name.replace(trimmed_name, -1, 0, " ");
      }
      catch (Error e) {
        debug("Regex error: e.message");
      }
      return trimmed_name;
    }

    public int compare_to(Certificate other) {
      if (this.cert.up() < other.cert.up()) return -1;
      if (this.cert.up() > other.cert.up()) return 1;
      return 0;
    }
  }


  // Certificate chooser page
  private void show_cert_chooser() {
    ls = new ArrayList<Certificate>();

    unowned Box? cert_chooser_page = Box.add(win);
    cert_chooser_page.size_hint_weight_set(1, 1);
    cert_chooser_page.size_hint_align_set(-1, -1);
    cert_chooser_page.homogeneous_set(false);
    cert_chooser_page.show();
    
    unowned Genlist? certlist = Genlist.add(win);
    certlist.size_hint_weight_set(1, 1);
    certlist.size_hint_align_set(-1, -1);
    list_cert_dir();
    foreach (Certificate cert in ls) {
      cert.listitem = certlist.item_append(itc2, (void*)cert, null, Elm.GenlistItemType.NONE, cert_select);
    }
    certlist.show();
    cert_chooser_page.pack_end(certlist);

    unowned Button? back_button = Button.add(win);
    back_button.size_hint_weight_set(1,-1);
    back_button.size_hint_align_set(-1,-1);
    back_button.text_set("Back");
    back_button.show();
    back_button.smart_callback_add("clicked", back_to_net_definition);
    cert_chooser_page.pack_end(back_button);

    pager.content_push(cert_chooser_page);
  }

  private void save_password() {
    if (network.encryption) {
      network.password = password.entry_get();
      if (network.authentication)
        network.username = username.entry_get();
      if (network.preferred_network) {
        wifi.preferred_network_password_change(network);
        wifi.preferred_network_username_change(network);
        wifi.preferred_network_certificate_change(network);
      }
    }
  }
  private void change_network_ascii_hex(Evas.Object obj, void* event_info) {
    bool current_state = ((Check)obj).state_get();
    if( current_state!=network.password_in_ascii )
      wifi.set_ascii_state(network,current_state);
  }
  private void change_network_preferred(Evas.Object obj, void* event_info) {
    save_password();
    bool current_state = ((Check)obj).state_get();
    if( current_state!=network.preferred_network )
      wifi.set_preferred_state(network,current_state);
  }
  private void connect_to() {
    save_password();
    wifi.connect_to(network);
    back_to_list();
  }
  private void back_to_list() {
    save_password();
    refresh_list_elements();
    pager.content_pop();
    password = null;
    username = null;
  }
  private void back_to_net_definition() {
    certlist_text_set();
    pager.content_pop();
//  gui_container3 = {}; causes error - see below, moved to method back_to_list()
//ERR:elementary elm_widget.c:1303 elm_widget_type_check() Passing Object: 0x1ce5e0, of type: '(unknown)' when expecting type: 'genlist'
  }
  private void certlist_text_set() {
      if (network.cert != "") {
         cert_status.text_set(Certificate.trim_cert_name(network.cert));
      }
      else {
         cert_status.text_set("Not Set - Password recipient unverified!");
      }
  }
  private void list_cert_dir() {
    ls.clear();
    MatchInfo result;
    try {
      Regex line_regex_cert_name = new Regex("""^(.+?\.pem)$""");
      var directory = File.new_for_path(SSL_CERT_DIR);
      var enumerator = directory.enumerate_children(FILE_ATTRIBUTE_STANDARD_NAME, 0, null);
      FileInfo file_info;
      while ((file_info = enumerator.next_file(null)) != null) {
        if (line_regex_cert_name.match(file_info.get_name(), 0, out result)) {
          ls.add(new Certificate(result.fetch(1), SSL_CERT_DIR));
        }
      }
    }
    catch (Error e) {
      debug("Error: e.message");
    }
    ls.sort();
  }
  private void clear_cert() {
    network.cert = "";
    network.cert_dir = "";
    certlist_text_set();
  }
  
  // unowned Genlist? stuff
  private static string genlist_get_label(void *data, Elm.Object obj, string part ) {
    /*if( strcmp(part,"elm.text")==0 )
      return "elm.text";
    if( strcmp(part,"elm.text.sub")==0 )
      return "elm.text.sub";*/
    return ((Network)data).pretty_string();
  }
  private static string certlist_get_label(void *data,  Elm.Object obj, string part) {
    string cert = ((Certificate)data).cert;
    return Certificate.trim_cert_name(cert);
  }
  public void item_select( Evas.Object obj, void* event_info) {
    Network clicked = (Network) ((GenlistItem)event_info).data_get();
    show_network(clicked);
    //debug( "clicked %s", clicked.pretty_string() );
  }
  public void cert_select( Evas.Object obj, void* event_info) {
    Certificate selected_cert = (Certificate) ((GenlistItem)event_info).data_get();
    network.cert = selected_cert.cert;
    network.cert_dir = selected_cert.cert_dir;
    back_to_net_definition();
  }


}
