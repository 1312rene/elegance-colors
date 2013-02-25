using Gtk;

class EleganceColorsWindow : ApplicationWindow {

	// General
	ComboBox combobox;

	RadioButton match_wallpaper;
	RadioButton match_theme;
	RadioButton custom_color;

	ColorButton color_button;

	Switch monitor_switch;
	Switch newbutton_switch;
	Switch entry_switch;

	FontButton fontchooser;

	SpinButton selgradient_size;
	SpinButton corner_roundness;
	SpinButton transition_duration;

	string color_value;

	string[] presets = { "elegance-colors.ini" };
	string[] titles = { "Current" };

	// Panel
	ColorButton panel_bg_color;
	ColorButton panel_fg_color;
	ColorButton panel_border_color;

	Switch panel_shadow_switch;
	Switch panel_icon_switch;

	SpinButton panel_chameleon_value;
	SpinButton panel_gradient_value;
	SpinButton panel_corner_value;

	string panel_bg_value;
	string panel_fg_value;
	string panel_border_value;

	// Dash
	ColorButton dash_bg_color;
	ColorButton dash_fg_color;
	ColorButton dash_border_color;

	Switch dash_shadow_switch;
	Switch dash_panel_switch;

	SpinButton dash_chameleon_value;
	SpinButton dash_gradient_value;
	SpinButton dash_iconsize_value;
	SpinButton dash_iconspacing_value;

	string dash_bg_value;
	string dash_fg_value;
	string dash_border_value;

	// Menu
	ColorButton menu_bg_color;
	ColorButton menu_fg_color;
	ColorButton menu_border_color;

	Switch menu_shadow_switch;
	Switch menu_arrow_switch;

	SpinButton menu_chameleon_value;
	SpinButton menu_gradient_value;

	string menu_bg_value;
	string menu_fg_value;
	string menu_border_value;

	// Dialogs
	ColorButton dialog_bg_color;
	ColorButton dialog_fg_color;
	ColorButton dialog_heading_color;
	ColorButton dialog_border_color;

	Switch dialog_shadow_switch;

	SpinButton dialog_chameleon_value;
	SpinButton dialog_gradient_value;

	string dialog_bg_value;
	string dialog_fg_value;
	string dialog_heading_value;
	string dialog_border_value;

	// Others
	Notebook notebook;

	Button apply_button;
	Button close_button;

	RadioButton general_tab;
	RadioButton panel_tab;
	RadioButton overview_tab;
	RadioButton menu_tab;
	RadioButton dialog_tab;

	File config_file;
	File presets_dir_sys;

	KeyFile key_file;

	internal EleganceColorsWindow (EleganceColorsPref app) {
		Object (application: app, title: "Elegance Colors Preferences");

		// Set window properties
		this.window_position = WindowPosition.CENTER;
		this.resizable = false;
		this.border_width = 12;

		// Set window icon
		try {
			this.icon = IconTheme.get_default ().load_icon ("elegance-colors", 48, 0);
		} catch (Error e) {
			stderr.printf ("Failed to load application icon: %s\n", e.message);
		}

		// Prefer dark theme
		// Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = true;

		// GMenu
		var export_action = new SimpleAction ("export", null);
		export_action.activate.connect (this.export_theme);
		this.add_action (export_action);

		var exsettings_action = new SimpleAction ("exsettings", null);
		exsettings_action.activate.connect (this.export_settings);
		this.add_action (exsettings_action);

		var impsettings_action = new SimpleAction ("impsettings", null);
		impsettings_action.activate.connect (this.import_settings);
		this.add_action (impsettings_action);

		var about_action = new SimpleAction ("about", null);
		about_action.activate.connect (this.show_about);
		this.add_action (about_action);

		var quit_action = new SimpleAction ("quit", null);
		quit_action.activate.connect (this.quit_window);
		this.add_action (quit_action);

		// Set variables
		var config_dir = File.new_for_path (Environment.get_user_config_dir ());
		config_file = config_dir.get_child ("elegance-colors").get_child ("elegance-colors.ini");
		presets_dir_sys = File.parse_name ("/usr/share/elegance-colors/presets");

		key_file = new KeyFile ();

		// Methods
		init_process ();
		create_widgets ();
		connect_signals ();
	}

	void init_process () {

		var home_dir = File.new_for_path (Environment.get_home_dir ());

		if (!home_dir.get_child (".themes/elegance-colors/gnome-shell/gnome-shell.css").query_exists () || !config_file.query_exists ()) {
			try {
				Process.spawn_command_line_async("elegance-colors");
			} catch (Error e) {
				stderr.printf ("Failed to run process: %s\n", e.message);
			}
			try {
				key_file.load_from_file (presets_dir_sys.get_child ("default.ini").get_path (), KeyFileFlags.NONE);
			} catch (Error e) {
				stderr.printf ("Failed to load preset: %s\n", e.message);
			}
		}
	}


	void export_theme () {

		var exportdialog = new FileChooserDialog ("Export theme", this,
								FileChooserAction.SAVE,
								Stock.CANCEL, ResponseType.CANCEL,
								Stock.SAVE, ResponseType.ACCEPT, null);

		var filter = new FileFilter ();
		filter.add_pattern ("*.zip");

		exportdialog.set_filter (filter);
		exportdialog.set_current_name ("Elegance Colors Custom.zip");
		exportdialog.set_do_overwrite_confirmation(true);

		if (exportdialog.run () == ResponseType.ACCEPT) {
			string theme_path = exportdialog.get_file ().get_path ();

			try {
				Process.spawn_command_line_sync("elegance-colors export \"%s\"".printf (theme_path));
			} catch (Error e) {
				stderr.printf ("Failed to export theme: %s\n", e.message);
			}
		}

		exportdialog.close ();
	}

	void export_settings () {

		var exportsettings = new FileChooserDialog ("Export settings", this,
								FileChooserAction.SAVE,
								Stock.CANCEL, ResponseType.CANCEL,
								Stock.SAVE, ResponseType.ACCEPT, null);

		var filter = new FileFilter ();
		filter.add_pattern ("*.ini");

		exportsettings.set_filter (filter);
		exportsettings.set_current_name ("elegance-colors-custom.ini");
		exportsettings.set_do_overwrite_confirmation(true);

		if (exportsettings.run () == ResponseType.ACCEPT) {
			try {
				var exportpath = File.new_for_path (exportsettings.get_file ().get_path ());

				config_file.copy (exportpath, FileCopyFlags.OVERWRITE);
				
			} catch (Error e) {
				stderr.printf ("Failed to export settings: %s\n", e.message);
			}
		}

		exportsettings.close ();
	}

	void import_settings () {

		var importsettings = new FileChooserDialog ("Import settings", this,
								FileChooserAction.OPEN,
								Stock.CANCEL, ResponseType.CANCEL,
								Stock.OPEN, ResponseType.ACCEPT, null);

		var filter = new FileFilter ();
		filter.add_pattern ("*.ini");

		importsettings.set_filter (filter);

		if (importsettings.run () == ResponseType.ACCEPT) {
			try {
				var importpath = File.new_for_path (importsettings.get_file ().get_path ());

				if (importpath.query_exists ()) {
					key_file.load_from_file (importpath.get_path (), KeyFileFlags.NONE);
				}
			} catch (Error e) {
				stderr.printf ("Failed to import settings: %s\n", e.message);
			}
		}

		importsettings.close ();

		set_states ();

		apply_button.set_sensitive (true);
	}

	void show_about (SimpleAction simple, Variant? parameter) {
		string license = "This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 3 of the License, or (at your option) any later version.\n\nThis program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.\n\nYou should have received a copy of the GNU General Public License along with This program; if not, write to the Free Software Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301 USA";

		show_about_dialog (this,
			"program-name", "Elegance Colors",
			"logo_icon_name", "elegance-colors",
			"copyright", "Copyright \xc2\xa9 Satyajit Sahoo",
			"comments", "A chameleon theme for Gnome Shell",
			"license", license,
			"wrap-license", true,
			"website", "https://github.com/satya164/elegance-colors",
			"website-label", "Elegance Colors on GitHub",
			null);
	}

	void quit_window () {
		destroy ();
	}

	void set_config () {

		// Read the config file
		try {
			key_file.load_from_file (config_file.get_path(), KeyFileFlags.NONE);
		} catch (Error e) {
			stderr.printf ("Failed to read configuration: %s\n", e.message);
		}
	}

	void set_states () {

		// Read the key-value pairs
		try {
			var mode = key_file.get_string ("Settings", "mode");

			color_value = "rgba(74,144,217,0.9)";

			if (mode == "wallpaper") {
				match_wallpaper.set_active (true);
				color_button.set_sensitive (false);
			} else if (mode == "gtk") {
				match_theme.set_active (true);
				color_button.set_sensitive (false);
			} else if ("#" in mode || "rgb" in mode) {
				color_value = mode;
				custom_color.set_active (true);
				color_button.set_sensitive (true);
			}

			monitor_switch.set_active (key_file.get_boolean ("Settings", "monitor"));
			newbutton_switch.set_active (key_file.get_boolean ("Settings", "newbutton"));
			entry_switch.set_active (key_file.get_boolean ("Settings", "entry"));

			fontchooser.set_font_name (key_file.get_string ("Settings", "fontname"));

			selgradient_size.adjustment.value = key_file.get_double ("Settings", "selgradient");
			corner_roundness.adjustment.value = key_file.get_double ("Settings", "roundness");
			transition_duration.adjustment.value = key_file.get_double ("Settings", "transition");

			panel_bg_value = key_file.get_string ("Panel", "panel_bg");
			panel_fg_value = key_file.get_string ("Panel", "panel_fg");
			panel_border_value = key_file.get_string ("Panel", "panel_border");

			panel_shadow_switch.set_active (key_file.get_boolean ("Panel", "panel_shadow"));
			panel_icon_switch.set_active (key_file.get_boolean ("Panel", "panel_icon"));

			panel_chameleon_value.adjustment.value = key_file.get_double ("Panel", "panel_chameleon");
			panel_gradient_value.adjustment.value = key_file.get_double ("Panel", "panel_gradient");
			panel_corner_value.adjustment.value = key_file.get_double ("Panel", "panel_corner");

			dash_bg_value = key_file.get_string ("Overview", "dash_bg");
			dash_fg_value = key_file.get_string ("Overview", "dash_fg");
			dash_border_value = key_file.get_string ("Overview", "dash_border");

			dash_shadow_switch.set_active (key_file.get_boolean ("Overview", "dash_shadow"));
			dash_panel_switch.set_active (key_file.get_boolean ("Overview", "dash_panel"));

			dash_chameleon_value.adjustment.value = key_file.get_double ("Overview", "dash_chameleon");
			dash_gradient_value.adjustment.value = key_file.get_double ("Overview", "dash_gradient");
			dash_iconsize_value.adjustment.value = key_file.get_double ("Overview", "dash_iconsize");
			dash_iconspacing_value.adjustment.value = key_file.get_double ("Overview", "dash_iconspacing");

			menu_bg_value = key_file.get_string ("Menu", "menu_bg");
			menu_fg_value = key_file.get_string ("Menu", "menu_fg");
			menu_border_value = key_file.get_string ("Menu", "menu_border");

			menu_shadow_switch.set_active (key_file.get_boolean ("Menu", "menu_shadow"));
			menu_arrow_switch.set_active (key_file.get_boolean ("Menu", "menu_arrow"));

			menu_chameleon_value.adjustment.value = key_file.get_double ("Menu", "menu_chameleon");
			menu_gradient_value.adjustment.value = key_file.get_double ("Menu", "menu_gradient");

			dialog_bg_value = key_file.get_string ("Dialogs", "dialog_bg");
			dialog_fg_value = key_file.get_string ("Dialogs", "dialog_fg");
			dialog_border_value = key_file.get_string ("Dialogs", "dialog_border");
			dialog_heading_value = key_file.get_string ("Dialogs", "dialog_heading");

			dialog_shadow_switch.set_active (key_file.get_boolean ("Dialogs", "dialog_shadow"));

			dialog_chameleon_value.adjustment.value = key_file.get_double ("Dialogs", "dialog_chameleon");
			dialog_gradient_value.adjustment.value = key_file.get_double ("Dialogs", "dialog_gradient");
		} catch (Error e) {
			stderr.printf ("Failed to set properties: %s\n", e.message);
		}

		// Set colors
		var color = Gdk.RGBA ();

		color.parse ("%s".printf (color_value));
		color_button.set_rgba (color);

		color.parse ("%s".printf (panel_bg_value));
		panel_bg_color.set_rgba (color);

		color.parse ("%s".printf (panel_fg_value));
		panel_fg_color.set_rgba (color);

		color.parse ("%s".printf (panel_border_value));
		panel_border_color.set_rgba (color);

		color.parse ("%s".printf (dash_bg_value));
		dash_bg_color.set_rgba (color);

		color.parse ("%s".printf (dash_fg_value));
		dash_fg_color.set_rgba (color);

		color.parse ("%s".printf (dash_border_value));
		dash_border_color.set_rgba (color);

		color.parse ("%s".printf (menu_bg_value));
		menu_bg_color.set_rgba (color);

		color.parse ("%s".printf (menu_fg_value));
		menu_fg_color.set_rgba (color);

		color.parse ("%s".printf (menu_border_value));
		menu_border_color.set_rgba (color);

		color.parse ("%s".printf (dialog_bg_value));
		dialog_bg_color.set_rgba (color);

		color.parse ("%s".printf (dialog_fg_value));
		dialog_fg_color.set_rgba (color);

		color.parse ("%s".printf (dialog_heading_value));
		dialog_heading_color.set_rgba (color);

		color.parse ("%s".printf (dialog_border_value));
		dialog_border_color.set_rgba (color);
	}

	void create_widgets () {

		// Create and setup widgets

		// General
		var presets_label = new Label.with_mnemonic ("Load from preset");
		presets_label.set_halign (Align.START);
		var mode_label = new Label.with_mnemonic ("Derive color from");
		mode_label.set_halign (Align.START);
		match_wallpaper = new RadioButton (null);
		match_wallpaper.set_label ("Wallpaper");
		match_wallpaper.set_tooltip_text ("Derive the highlight color from the current wallpaper");
		match_theme = new RadioButton.with_label (match_wallpaper.get_group(),"GTK theme");
		match_theme.set_tooltip_text ("Derive the highlight color from the current GTK theme");
		custom_color = new RadioButton.with_label (match_theme.get_group(),"Custom");
		custom_color.set_tooltip_text ("Manually set a custom highlight color");
		color_button = new ColorButton ();
		color_button.set_use_alpha (true);
		color_button.set_tooltip_text ("Set a custom highlight color");
		var monitor_label = new Label.with_mnemonic ("Monitor changes");
		monitor_label.set_halign (Align.START);
		monitor_switch = new Switch ();
		monitor_switch.set_tooltip_text ("Run in background and reload the theme when changes are detected");
		monitor_switch.set_halign (Align.END);
		var newbutton_label = new Label.with_mnemonic ("New button style");
		newbutton_label.set_halign (Align.START);
		newbutton_switch = new Switch ();
		newbutton_switch.set_tooltip_text ("Use the fancy new button style or the default style");
		newbutton_switch.set_halign (Align.END);
		var entry_label = new Label.with_mnemonic ("Light entry style");
		entry_label.set_halign (Align.START);
		entry_switch = new Switch ();
		entry_switch.set_tooltip_text ("Use the light color entry style or the dark style");
		entry_switch.set_halign (Align.END);
		var font_label = new Label.with_mnemonic ("Display font");
		font_label.set_halign (Align.START);
		fontchooser = new FontButton ();
		fontchooser.set_title ("Choose a font");
		fontchooser.set_use_font (true);
		fontchooser.set_use_size (true);
		fontchooser.set_tooltip_text ("Choose the shell font and its size");
		fontchooser.set_halign (Align.END);
		var selgradient_label = new Label.with_mnemonic ("Selection gradient size");
		selgradient_label.set_halign (Align.START);
		selgradient_size = new SpinButton.with_range (0, 255, 1);
		selgradient_size.set_tooltip_text ("Set the gradient size for highlight color");
		selgradient_size.set_halign (Align.END);
		var roundness_label = new Label.with_mnemonic ("Roundness");
		roundness_label.set_halign (Align.START);
		corner_roundness = new SpinButton.with_range (0, 100, 1);
		corner_roundness.set_tooltip_text ("Set the border radius of different elements");
		corner_roundness.set_halign (Align.END);
		var transition_label = new Label.with_mnemonic ("Transition duration");
		transition_label.set_halign (Align.START);
		transition_duration = new SpinButton.with_range (0, 1000, 1);
		transition_duration.set_tooltip_text ("Set the duration of the transition animations");
		transition_duration.set_halign (Align.END);

		// Panel
		var panel_bg_label = new Label.with_mnemonic ("Background color");
		panel_bg_label.set_halign (Align.START);
		panel_bg_color = new ColorButton ();
		panel_bg_color.set_use_alpha (true);
		panel_bg_color.set_tooltip_text ("Set the background color of the top panel");
		var panel_fg_label = new Label.with_mnemonic ("Text color");
		panel_fg_label.set_halign (Align.START);
		panel_fg_color = new ColorButton ();
		panel_fg_color.set_use_alpha (true);
		panel_fg_color.set_tooltip_text ("Set the text color of the top panel");
		var panel_border_label = new Label.with_mnemonic ("Border color");
		panel_border_label.set_halign (Align.START);
		panel_border_color = new ColorButton ();
		panel_border_color.set_use_alpha (true);
		panel_border_color.set_tooltip_text ("Set the border color of the top panel");
		var panel_shadow_label = new Label.with_mnemonic ("Drop shadow");
		panel_shadow_label.set_halign (Align.START);
		panel_shadow_switch = new Switch ();
		panel_shadow_switch.set_tooltip_text ("Enable/disable shadow under the top panel");
		panel_shadow_switch.set_halign (Align.END);
		var panel_icon_label = new Label.with_mnemonic ("App icon");
		panel_icon_label.set_halign (Align.START);
		panel_icon_switch = new Switch ();
		panel_icon_switch.set_tooltip_text ("Enable/disable app icon in the top panel");
		panel_icon_switch.set_halign (Align.END);
		var panel_chameleon_label = new Label.with_mnemonic ("Background tint level");
		panel_chameleon_label.set_halign (Align.START);
		panel_chameleon_value = new SpinButton.with_range (0, 100, 1);
		panel_chameleon_value.set_tooltip_text ("Set the amount of highlight color to mix with the chosen background color of the top panel");
		panel_chameleon_value.set_halign (Align.END);
		var panel_gradient_label = new Label.with_mnemonic ("Gradient size");
		panel_gradient_label.set_halign (Align.START);
		panel_gradient_value = new SpinButton.with_range (0, 255, 1);
		panel_gradient_value.set_tooltip_text ("Set the gradient size of the background of the top panel");
		panel_gradient_value.set_halign (Align.END);
		var panel_corner_label = new Label.with_mnemonic ("Corner radius");
		panel_corner_label.set_halign (Align.START);
		panel_corner_value = new SpinButton.with_range (0, 100, 1);
		panel_corner_value.set_tooltip_text ("Set the roundness the top panel corners");
		panel_corner_value.set_halign (Align.END);

		// Overview
		var dash_bg_label = new Label.with_mnemonic ("Background color");
		dash_bg_label.set_halign (Align.START);
		dash_bg_color = new ColorButton ();
		dash_bg_color.set_use_alpha (true);
		dash_bg_color.set_tooltip_text ("Set the background color of the dash and workspace panel");
		var dash_fg_label = new Label.with_mnemonic ("Text color");
		dash_fg_label.set_halign (Align.START);
		dash_fg_color = new ColorButton ();
		dash_fg_color.set_use_alpha (true);
		dash_fg_color.set_tooltip_text ("Set the text color of the dash labels and window caption");
		var dash_border_label = new Label.with_mnemonic ("Border color");
		dash_border_label.set_halign (Align.START);
		dash_border_color = new ColorButton ();
		dash_border_color.set_use_alpha (true);
		dash_border_color.set_tooltip_text ("Set the border color of the dash and workspace panel");
		var dash_shadow_label = new Label.with_mnemonic ("Drop shadow");
		dash_shadow_label.set_halign (Align.START);
		dash_shadow_switch = new Switch ();
		dash_shadow_switch.set_tooltip_text ("Enable/disable shadow under the dash and workspace panel");
		dash_shadow_switch.set_halign (Align.END);
		var dash_panel_label = new Label.with_mnemonic ("Restyled panel");
		dash_panel_label.set_halign (Align.START);
		dash_panel_switch = new Switch ();
		dash_panel_switch.set_tooltip_text ("Restyle panel in overview to be same as dash");
		dash_panel_switch.set_halign (Align.END);
		var dash_chameleon_label = new Label.with_mnemonic ("Background tint level");
		dash_chameleon_label.set_halign (Align.START);
		dash_chameleon_value = new SpinButton.with_range (0, 100, 1);
		dash_chameleon_value.set_tooltip_text ("Set the amount of highlight color to mix with the chosen background color of the dash and workspace panel");
		dash_chameleon_value.set_halign (Align.END);
		var dash_gradient_label = new Label.with_mnemonic ("Gradient size");
		dash_gradient_label.set_halign (Align.START);
		dash_gradient_value = new SpinButton.with_range (0, 255, 1);
		dash_gradient_value.set_tooltip_text ("Set the gradient size of the backgrounds of the dash and workspace panel");
		dash_gradient_value.set_halign (Align.END);
		var dash_iconsize_label = new Label.with_mnemonic ("App icon size");
		dash_iconsize_label.set_halign (Align.START);
		dash_iconsize_value = new SpinButton.with_range (0, 256, 1);
		dash_iconsize_value.set_tooltip_text ("Set the size of icons in the application grid");
		dash_iconsize_value.set_halign (Align.END);
		var dash_iconspacing_label = new Label.with_mnemonic ("App icon spacing");
		dash_iconspacing_label.set_halign (Align.START);
		dash_iconspacing_value = new SpinButton.with_range (0, 256, 1);
		dash_iconspacing_value.set_tooltip_text ("Set the spacing between icons in the application grid");
		dash_iconspacing_value.set_halign (Align.END);

		// Menu
		var menu_bg_label = new Label.with_mnemonic ("Background color");
		menu_bg_label.set_halign (Align.START);
		menu_bg_color = new ColorButton ();
		menu_bg_color.set_use_alpha (true);
		menu_bg_color.set_tooltip_text ("Set the background color of the popup menu");
		var menu_fg_label = new Label.with_mnemonic ("Text color");
		menu_fg_label.set_halign (Align.START);
		menu_fg_color = new ColorButton ();
		menu_fg_color.set_use_alpha (true);
		menu_fg_color.set_tooltip_text ("Set the text color of the popup menu");
		var menu_border_label = new Label.with_mnemonic ("Border color");
		menu_border_label.set_halign (Align.START);
		menu_border_color = new ColorButton ();
		menu_border_color.set_use_alpha (true);
		menu_border_color.set_tooltip_text ("Set the border color of the popup menu");
		var menu_shadow_label = new Label.with_mnemonic ("Drop shadow");
		menu_shadow_label.set_halign (Align.START);
		menu_shadow_switch = new Switch ();
		menu_shadow_switch.set_tooltip_text ("Enable/disable shadow under the popup menu");
		menu_shadow_switch.set_halign (Align.END);
		var menu_arrow_label = new Label.with_mnemonic ("Arrow pointer");
		menu_arrow_label.set_halign (Align.START);
		menu_arrow_switch = new Switch ();
		menu_arrow_switch.set_tooltip_text ("Enable/disable arrow pointer in the popup menu");
		menu_arrow_switch.set_halign (Align.END);
		var menu_chameleon_label = new Label.with_mnemonic ("Background tint level");
		menu_chameleon_label.set_halign (Align.START);
		menu_chameleon_value = new SpinButton.with_range (0, 100, 1);
		menu_chameleon_value.set_tooltip_text ("Set the amount of highlight color to mix with the chosen background color of the popup menu");
		menu_chameleon_value.set_halign (Align.END);
		var menu_gradient_label = new Label.with_mnemonic ("Gradient size");
		menu_gradient_label.set_halign (Align.START);
		menu_gradient_value = new SpinButton.with_range (0, 255, 1);
		menu_gradient_value.set_tooltip_text ("Set the gradient size of the background of the popup menu");
		menu_gradient_value.set_halign (Align.END);

		// Dialogs
		var dialog_bg_label = new Label.with_mnemonic ("Background color");
		dialog_bg_label.set_halign (Align.START);
		dialog_bg_color = new ColorButton ();
		dialog_bg_color.set_use_alpha (true);
		dialog_bg_color.set_tooltip_text ("Set the background color of the modal dialogs");
		var dialog_fg_label = new Label.with_mnemonic ("Text color");
		dialog_fg_label.set_halign (Align.START);
		dialog_fg_color = new ColorButton ();
		dialog_fg_color.set_use_alpha (true);
		dialog_fg_color.set_tooltip_text ("Set the text color of the modal dialogs");
		var dialog_heading_label = new Label.with_mnemonic ("Heading color");
		dialog_heading_label.set_halign (Align.START);
		dialog_heading_color = new ColorButton ();
		dialog_heading_color.set_use_alpha (true);
		dialog_heading_color.set_tooltip_text ("Set the text color of headings in the modal dialogs");
		var dialog_border_label = new Label.with_mnemonic ("Border color");
		dialog_border_label.set_halign (Align.START);
		dialog_border_color = new ColorButton ();
		dialog_border_color.set_use_alpha (true);
		dialog_border_color.set_tooltip_text ("Set the border color of the modal dialogs");
		var dialog_shadow_label = new Label.with_mnemonic ("Drop shadow");
		dialog_shadow_label.set_halign (Align.START);
		dialog_shadow_switch = new Switch ();
		dialog_shadow_switch.set_tooltip_text ("Enable/disable shadow under the modal dialogs");
		dialog_shadow_switch.set_halign (Align.END);
		var dialog_chameleon_label = new Label.with_mnemonic ("Background tint level");
		dialog_chameleon_label.set_halign (Align.START);
		dialog_chameleon_value = new SpinButton.with_range (0, 100, 1);
		dialog_chameleon_value.set_tooltip_text ("Set the amount of highlight color to mix with the chosen background color of the modal dialogs");
		dialog_chameleon_value.set_halign (Align.END);
		var dialog_gradient_label = new Label.with_mnemonic ("Gradient size");
		dialog_gradient_label.set_halign (Align.START);
		dialog_gradient_value = new SpinButton.with_range (0, 255, 1);
		dialog_gradient_value.set_tooltip_text ("Set the gradient size of the background of the modal dialogs");
		dialog_gradient_value.set_halign (Align.END);

		apply_button = new Button.from_stock (Stock.APPLY);
		close_button = new Button.from_stock(Stock.CLOSE);

		general_tab = new RadioButton (null);
		general_tab.set_label ("General");
		general_tab.set_mode (false);
		panel_tab = new RadioButton.with_label (general_tab.get_group(),"Panel");
		panel_tab.set_mode (false);
		overview_tab = new RadioButton.with_label (general_tab.get_group(),"Overview");
		overview_tab.set_mode (false);
		menu_tab = new RadioButton.with_label (general_tab.get_group(),"Menu");
		menu_tab.set_mode (false);
		dialog_tab = new RadioButton.with_label (general_tab.get_group(),"Dialogs");
		dialog_tab.set_mode (false);

		// Read presets
		try {
			var dir = Dir.open(presets_dir_sys.get_path());

			var titlechanged = false;

			string preset = "";
			string title = "";
			while ((preset = dir.read_name()) != null) {
				presets += preset;

				try {
					var dis = new DataInputStream (presets_dir_sys.get_child (preset).read ());
					string line;
					while ((line = dis.read_line (null)) != null) {
						if ("# Name:" in line) {
							title = line.substring (8, line.length-8);
							titlechanged = true;
						}
					}
				} catch (Error e) {
					stderr.printf ("Could not read preset title: %s\n", e.message);
				}
				
				if (!titlechanged == true) {
					title = preset;
				}

				titles += title;
				titlechanged = false;
			}
		} catch (Error e) {
			stderr.printf ("Failed to open presets directory: %s\n", e.message);
		}

		var liststore = new ListStore (1, typeof (string));

		for (int i = 0; i < titles.length; i++){
			TreeIter iter;
			liststore.append (out iter);
			liststore.set (iter, 0, titles[i]);
		}

		var cell = new CellRendererText ();

		combobox = new ComboBox.with_model (liststore);
		combobox.pack_start (cell, false);
		combobox.set_attributes (cell, "text", 0);
		combobox.set_active (0);
		combobox.set_tooltip_text ("Load settings from a installed preset");
		combobox.set_halign (Align.END);

		// Layout widgets

		// General
		var grid0 = new Grid ();
		grid0.set_column_homogeneous (true);
		grid0.set_column_spacing (12);
		grid0.set_row_spacing (12);
		grid0.attach (presets_label, 0, 0, 1, 1);
		grid0.attach_next_to (combobox, presets_label, PositionType.RIGHT, 2, 1);
		grid0.attach (mode_label, 0, 1, 1, 1);
		grid0.attach_next_to (match_wallpaper, mode_label, PositionType.RIGHT, 1, 1);
		grid0.attach_next_to (match_theme, match_wallpaper, PositionType.RIGHT, 1, 1);
		grid0.attach_next_to (custom_color, match_wallpaper, PositionType.BOTTOM, 1, 1);
		grid0.attach_next_to (color_button, custom_color, PositionType.RIGHT, 1, 1);
		grid0.attach (monitor_label, 0, 4, 2, 1);
		grid0.attach_next_to (monitor_switch, monitor_label, PositionType.RIGHT, 1, 1);
		grid0.attach (newbutton_label, 0, 5, 2, 1);
		grid0.attach_next_to (newbutton_switch, newbutton_label, PositionType.RIGHT, 1, 1);
		grid0.attach (entry_label, 0, 6, 2, 1);
		grid0.attach_next_to (entry_switch, entry_label, PositionType.RIGHT, 1, 1);
		grid0.attach (font_label, 0, 7, 1, 1);
		grid0.attach_next_to (fontchooser, font_label, PositionType.RIGHT, 2, 1);
		grid0.attach (selgradient_label, 0, 8, 2, 1);
		grid0.attach_next_to (selgradient_size, selgradient_label, PositionType.RIGHT, 1, 1);
		grid0.attach (roundness_label, 0, 9, 2, 1);
		grid0.attach_next_to (corner_roundness, roundness_label, PositionType.RIGHT, 1, 1);
		grid0.attach (transition_label, 0, 10, 2, 1);
		grid0.attach_next_to (transition_duration, transition_label, PositionType.RIGHT, 1, 1);

		// Panel
		var grid1 = new Grid ();
		grid1.set_column_homogeneous (true);
		grid1.set_column_spacing (12);
		grid1.set_row_spacing (12);
		grid1.attach (panel_bg_label, 0, 0, 2, 1);
		grid1.attach_next_to (panel_bg_color, panel_bg_label, PositionType.RIGHT, 1, 1);
		grid1.attach (panel_fg_label, 0, 1, 2, 1);
		grid1.attach_next_to (panel_fg_color, panel_fg_label, PositionType.RIGHT, 1, 1);
		grid1.attach (panel_border_label, 0, 2, 2, 1);
		grid1.attach_next_to (panel_border_color, panel_border_label, PositionType.RIGHT, 1, 1);
		grid1.attach (panel_shadow_label, 0, 3, 2, 1);
		grid1.attach_next_to (panel_shadow_switch, panel_shadow_label, PositionType.RIGHT, 1, 1);
		grid1.attach (panel_icon_label, 0, 4, 2, 1);
		grid1.attach_next_to (panel_icon_switch, panel_icon_label, PositionType.RIGHT, 1, 1);
		grid1.attach (panel_chameleon_label, 0, 5, 2, 1);
		grid1.attach_next_to (panel_chameleon_value, panel_chameleon_label, PositionType.RIGHT, 1, 1);
		grid1.attach (panel_gradient_label, 0, 6, 2, 1);
		grid1.attach_next_to (panel_gradient_value, panel_gradient_label, PositionType.RIGHT, 1, 1);
		grid1.attach (panel_corner_label, 0, 7, 2, 1);
		grid1.attach_next_to (panel_corner_value, panel_corner_label, PositionType.RIGHT, 1, 1);

		// Overview
		var grid2 = new Grid ();
		grid2.set_column_homogeneous (true);
		grid2.set_column_spacing (12);
		grid2.set_row_spacing (12);
		grid2.attach (dash_bg_label, 0, 0, 2, 1);
		grid2.attach_next_to (dash_bg_color, dash_bg_label, PositionType.RIGHT, 1, 1);
		grid2.attach (dash_fg_label, 0, 1, 2, 1);
		grid2.attach_next_to (dash_fg_color, dash_fg_label, PositionType.RIGHT, 1, 1);
		grid2.attach (dash_border_label, 0, 2, 2, 1);
		grid2.attach_next_to (dash_border_color, dash_border_label, PositionType.RIGHT, 1, 1);
		grid2.attach (dash_shadow_label, 0, 3, 2, 1);
		grid2.attach_next_to (dash_shadow_switch, dash_shadow_label, PositionType.RIGHT, 1, 1);
		grid2.attach (dash_panel_label, 0, 4, 2, 1);
		grid2.attach_next_to (dash_panel_switch, dash_panel_label, PositionType.RIGHT, 1, 1);
		grid2.attach (dash_chameleon_label, 0, 5, 2, 1);
		grid2.attach_next_to (dash_chameleon_value, dash_chameleon_label, PositionType.RIGHT, 1, 1);
		grid2.attach (dash_gradient_label, 0, 6, 2, 1);
		grid2.attach_next_to (dash_gradient_value, dash_gradient_label, PositionType.RIGHT, 1, 1);
		grid2.attach (dash_iconsize_label, 0, 7, 2, 1);
		grid2.attach_next_to (dash_iconsize_value, dash_iconsize_label, PositionType.RIGHT, 1, 1);
		grid2.attach (dash_iconspacing_label, 0, 8, 2, 1);
		grid2.attach_next_to (dash_iconspacing_value, dash_iconspacing_label, PositionType.RIGHT, 1, 1);

		// Menu
		var grid3 = new Grid ();
		grid3.set_column_homogeneous (true);
		grid3.set_column_spacing (12);
		grid3.set_row_spacing (12);
		grid3.attach (menu_bg_label, 0, 0, 2, 1);
		grid3.attach_next_to (menu_bg_color, menu_bg_label, PositionType.RIGHT, 1, 1);
		grid3.attach (menu_fg_label, 0, 1, 2, 1);
		grid3.attach_next_to (menu_fg_color, menu_fg_label, PositionType.RIGHT, 1, 1);
		grid3.attach (menu_border_label, 0, 2, 2, 1);
		grid3.attach_next_to (menu_border_color, menu_border_label, PositionType.RIGHT, 1, 1);
		grid3.attach (menu_shadow_label, 0, 3, 2, 1);
		grid3.attach_next_to (menu_shadow_switch, menu_shadow_label, PositionType.RIGHT, 1, 1);
		grid3.attach (menu_arrow_label, 0, 4, 2, 1);
		grid3.attach_next_to (menu_arrow_switch, menu_arrow_label, PositionType.RIGHT, 1, 1);
		grid3.attach (menu_chameleon_label, 0, 5, 2, 1);
		grid3.attach_next_to (menu_chameleon_value, menu_chameleon_label, PositionType.RIGHT, 1, 1);
		grid3.attach (menu_gradient_label, 0, 6, 2, 1);
		grid3.attach_next_to (menu_gradient_value, menu_gradient_label, PositionType.RIGHT, 1, 1);

		// Dialogs
		var grid4 = new Grid ();
		grid4.set_column_homogeneous (true);
		grid4.set_column_spacing (12);
		grid4.set_row_spacing (12);
		grid4.attach (dialog_bg_label, 0, 0, 2, 1);
		grid4.attach_next_to (dialog_bg_color, dialog_bg_label, PositionType.RIGHT, 1, 1);
		grid4.attach (dialog_fg_label, 0, 1, 2, 1);
		grid4.attach_next_to (dialog_fg_color, dialog_fg_label, PositionType.RIGHT, 1, 1);
		grid4.attach (dialog_heading_label, 0, 2, 2, 1);
		grid4.attach_next_to (dialog_heading_color, dialog_heading_label, PositionType.RIGHT, 1, 1);
		grid4.attach (dialog_border_label, 0, 3, 2, 1);
		grid4.attach_next_to (dialog_border_color, dialog_border_label, PositionType.RIGHT, 1, 1);
		grid4.attach (dialog_shadow_label, 0, 4, 2, 1);
		grid4.attach_next_to (dialog_shadow_switch, dialog_shadow_label, PositionType.RIGHT, 1, 1);
		grid4.attach (dialog_chameleon_label, 0, 5, 2, 1);
		grid4.attach_next_to (dialog_chameleon_value, dialog_chameleon_label, PositionType.RIGHT, 1, 1);
		grid4.attach (dialog_gradient_label, 0, 6, 2, 1);
		grid4.attach_next_to (dialog_gradient_value, dialog_gradient_label, PositionType.RIGHT, 1, 1);

		// Buttons
		var buttons = new ButtonBox (Orientation.HORIZONTAL);
		buttons.set_layout (ButtonBoxStyle.EDGE);
		buttons.add (apply_button);
		buttons.add (close_button);

		// Tabs
		var tabs = new Box (Orientation.HORIZONTAL, 0);
		tabs.set_homogeneous (true);
		tabs.get_style_context().add_class("linked");
		tabs.add (general_tab);
		tabs.add (panel_tab);
		tabs.add (overview_tab);
		tabs.add (menu_tab);
		tabs.add (dialog_tab);

		notebook = new Notebook ();
		notebook.set_show_tabs (false);
		notebook.append_page (grid0, new Label ("General"));
		notebook.append_page (grid1, new Label ("Panel"));
		notebook.append_page (grid2, new Label ("Overview"));
		notebook.append_page (grid3, new Label ("Menu"));
		notebook.append_page (grid4, new Label ("Dialogs"));

		var vbox = new Box (Orientation.VERTICAL, 10);
		vbox.add (tabs);
		vbox.add (notebook);
		vbox.add (buttons);

		// Setup widgets
		set_config ();
		set_states ();

		notebook.set_current_page (0);
		general_tab.set_active (true);
		apply_button.set_sensitive (false);

		this.add (vbox);
	}

	void connect_signals () {
		general_tab.toggled.connect (() => {
			notebook.set_current_page (0);
		});
		panel_tab.toggled.connect (() => {
			notebook.set_current_page (1);
		});
		overview_tab.toggled.connect (() => {
			notebook.set_current_page (2);
		});
		menu_tab.toggled.connect (() => {
			notebook.set_current_page (3);
		});
		dialog_tab.toggled.connect (() => {
			notebook.set_current_page (4);
		});
		combobox.changed.connect (() => {
			on_preset_selected ();
			apply_button.set_sensitive (true);
		});
		match_wallpaper.toggled.connect (() => {
			apply_button.set_sensitive (true);
		});
		match_theme.toggled.connect (() => {
			apply_button.set_sensitive (true);
		});
		custom_color.toggled.connect (() => {
			if (custom_color.get_active ()) {
				color_button.set_sensitive (true);
			} else {
				color_button.set_sensitive (false);
			}
			apply_button.set_sensitive (true);
		});
		color_button.color_set.connect (() => {
			apply_button.set_sensitive (true);
		});
		monitor_switch.notify["active"].connect (() => {
			if (monitor_switch.get_active ()) {
				try {
					Process.spawn_command_line_async("elegance-colors");
				} catch (Error e) {
					stderr.printf ("Failed to start background process: %s\n", e.message);
				}
			} else {
				try {
					Process.spawn_command_line_async("elegance-colors stop");
				} catch (Error e) {
					stderr.printf ("Failed to stop background process: %s\n", e.message);
				}
			}
			apply_button.set_sensitive (true);
		});
		newbutton_switch.notify["active"].connect (() => {
			apply_button.set_sensitive (true);
		});
		entry_switch.notify["active"].connect (() => {
			apply_button.set_sensitive (true);
		});
		fontchooser.font_set.connect (() => {
			apply_button.set_sensitive (true);
		});
		selgradient_size.adjustment.value_changed.connect (() => {
			apply_button.set_sensitive (true);
		});
		corner_roundness.adjustment.value_changed.connect (() => {
			apply_button.set_sensitive (true);
		});
		transition_duration.adjustment.value_changed.connect (() => {
			apply_button.set_sensitive (true);
		});
		panel_bg_color.color_set.connect (() => {
			apply_button.set_sensitive (true);
		});
		panel_fg_color.color_set.connect (() => {
			apply_button.set_sensitive (true);
		});
		panel_border_color.color_set.connect (() => {
			apply_button.set_sensitive (true);
		});
		panel_shadow_switch.notify["active"].connect (() => {
			apply_button.set_sensitive (true);
		});
		panel_icon_switch.notify["active"].connect (() => {
			apply_button.set_sensitive (true);
		});
		panel_chameleon_value.adjustment.value_changed.connect (() => {
			apply_button.set_sensitive (true);
		});
		panel_gradient_value.adjustment.value_changed.connect (() => {
			apply_button.set_sensitive (true);
		});
		panel_corner_value.adjustment.value_changed.connect (() => {
			apply_button.set_sensitive (true);
		});
		dash_bg_color.color_set.connect (() => {
			apply_button.set_sensitive (true);
		});
		dash_fg_color.color_set.connect (() => {
			apply_button.set_sensitive (true);
		});
		dash_border_color.color_set.connect (() => {
			apply_button.set_sensitive (true);
		});
		dash_shadow_switch.notify["active"].connect (() => {
			apply_button.set_sensitive (true);
		});
		dash_panel_switch.notify["active"].connect (() => {
			apply_button.set_sensitive (true);
		});
		dash_chameleon_value.adjustment.value_changed.connect (() => {
			apply_button.set_sensitive (true);
		});
		dash_gradient_value.adjustment.value_changed.connect (() => {
			apply_button.set_sensitive (true);
		});
		dash_iconsize_value.adjustment.value_changed.connect (() => {
			apply_button.set_sensitive (true);
		});
		dash_iconspacing_value.adjustment.value_changed.connect (() => {
			apply_button.set_sensitive (true);
		});
		menu_bg_color.color_set.connect (() => {
			apply_button.set_sensitive (true);
		});
		menu_fg_color.color_set.connect (() => {
			apply_button.set_sensitive (true);
		});
		menu_border_color.color_set.connect (() => {
			apply_button.set_sensitive (true);
		});
		menu_shadow_switch.notify["active"].connect (() => {
			apply_button.set_sensitive (true);
		});
		menu_arrow_switch.notify["active"].connect (() => {
			apply_button.set_sensitive (true);
		});
		menu_chameleon_value.adjustment.value_changed.connect (() => {
			apply_button.set_sensitive (true);
		});
		menu_gradient_value.adjustment.value_changed.connect (() => {
			apply_button.set_sensitive (true);
		});
		dialog_bg_color.color_set.connect (() => {
			apply_button.set_sensitive (true);
		});
		dialog_fg_color.color_set.connect (() => {
			apply_button.set_sensitive (true);
		});
		dialog_heading_color.color_set.connect (() => {
			apply_button.set_sensitive (true);
		});
		dialog_border_color.color_set.connect (() => {
			apply_button.set_sensitive (true);
		});
		dialog_shadow_switch.notify["active"].connect (() => {
			apply_button.set_sensitive (true);
		});
		dialog_chameleon_value.adjustment.value_changed.connect (() => {
			apply_button.set_sensitive (true);
		});
		dialog_gradient_value.adjustment.value_changed.connect (() => {
			apply_button.set_sensitive (true);
		});
		apply_button.clicked.connect (() => {
			write_config ();
			apply_button.set_sensitive (false);
		});
		close_button.clicked.connect (() => {
			quit_window ();
		});
	}

	void on_preset_selected () {

		if (combobox.get_active () !=0) {
			try {
				key_file.load_from_file (presets_dir_sys.get_child (presets [combobox.get_active ()]).get_path (), KeyFileFlags.NONE);
			} catch (Error e) {
				stderr.printf ("Failed to load preset: %s\n", e.message);
			}
		} else {
			set_config ();
		}

		set_states ();
	}

	void write_config () {
		if (match_wallpaper.get_active()) {
			key_file.set_string ("Settings", "mode", "wallpaper");
		} else if (match_theme.get_active()) {
			key_file.set_string ("Settings", "mode", "gtk");
		} else if (custom_color.get_active()) {
			key_file.set_string ("Settings", "mode", color_button.get_rgba ().to_string());
		}

		key_file.set_boolean ("Settings", "monitor", monitor_switch.get_active());
		key_file.set_boolean ("Settings", "newbutton", newbutton_switch.get_active());
		key_file.set_boolean ("Settings", "entry", entry_switch.get_active());

		key_file.set_string ("Settings", "fontname", fontchooser.get_font_name());

		key_file.set_double ("Settings", "selgradient", selgradient_size.adjustment.value);
		key_file.set_double ("Settings", "roundness", corner_roundness.adjustment.value);
		key_file.set_double ("Settings", "transition", transition_duration.adjustment.value);

		key_file.set_string ("Panel", "panel_bg", panel_bg_color.get_rgba ().to_string());
		key_file.set_string ("Panel", "panel_fg", panel_fg_color.get_rgba ().to_string());
		key_file.set_string ("Panel", "panel_border", panel_border_color.get_rgba ().to_string());

		key_file.set_boolean ("Panel", "panel_shadow", panel_shadow_switch.get_active());
		key_file.set_boolean ("Panel", "panel_icon", panel_icon_switch.get_active());

		key_file.set_double ("Panel", "panel_chameleon", panel_chameleon_value.adjustment.value);
		key_file.set_double ("Panel", "panel_gradient", panel_gradient_value.adjustment.value);
		key_file.set_double ("Panel", "panel_corner", panel_corner_value.adjustment.value);

		key_file.set_string ("Overview", "dash_bg", dash_bg_color.get_rgba ().to_string());
		key_file.set_string ("Overview", "dash_fg", dash_fg_color.get_rgba ().to_string());
		key_file.set_string ("Overview", "dash_border", dash_border_color.get_rgba ().to_string());

		key_file.set_boolean ("Overview", "dash_shadow", dash_shadow_switch.get_active());
		key_file.set_boolean ("Overview", "dash_panel", dash_panel_switch.get_active());

		key_file.set_double ("Overview", "dash_chameleon", dash_chameleon_value.adjustment.value);
		key_file.set_double ("Overview", "dash_gradient", dash_gradient_value.adjustment.value);
		key_file.set_double ("Overview", "dash_iconsize", dash_iconsize_value.adjustment.value);
		key_file.set_double ("Overview", "dash_iconspacing", dash_iconspacing_value.adjustment.value);

		key_file.set_string ("Menu", "menu_bg", menu_bg_color.get_rgba ().to_string());
		key_file.set_string ("Menu", "menu_fg", menu_fg_color.get_rgba ().to_string());
		key_file.set_string ("Menu", "menu_border", menu_border_color.get_rgba ().to_string());

		key_file.set_boolean ("Menu", "menu_shadow", menu_shadow_switch.get_active());
		key_file.set_boolean ("Menu", "menu_arrow", menu_arrow_switch.get_active());

		key_file.set_double ("Menu", "menu_chameleon", menu_chameleon_value.adjustment.value);
		key_file.set_double ("Menu", "menu_gradient", menu_gradient_value.adjustment.value);

		key_file.set_string ("Dialogs", "dialog_bg", dialog_bg_color.get_rgba ().to_string());
		key_file.set_string ("Dialogs", "dialog_fg", dialog_fg_color.get_rgba ().to_string());
		key_file.set_string ("Dialogs", "dialog_heading", dialog_heading_color.get_rgba ().to_string());
		key_file.set_string ("Dialogs", "dialog_border", dialog_border_color.get_rgba ().to_string());

		key_file.set_boolean ("Dialogs", "dialog_shadow", dialog_shadow_switch.get_active());

		key_file.set_double ("Dialogs", "dialog_chameleon", dialog_chameleon_value.adjustment.value);
		key_file.set_double ("Dialogs", "dialog_gradient", dialog_gradient_value.adjustment.value);

		if (config_file.query_exists ()) {
			try {
				config_file.delete ();
			} catch (Error e) {
				stderr.printf ("Failed to delete old configuration: %s\n", e.message);
			}
		}

		try {
			string keyfile_str = key_file.to_data ();
			var dos = new DataOutputStream (config_file.create (FileCreateFlags.REPLACE_DESTINATION));
			dos.put_string (keyfile_str);
		} catch (Error e) {
			stderr.printf ("Failed to write configuration: %s\n", e.message);
		}

		try {
			Process.spawn_command_line_sync("elegance-colors apply");
		} catch (Error e) {
			stderr.printf ("Failed to apply changes: %s\n", e.message);
		}
	}
}

class EleganceColorsPref : Gtk.Application {

	internal EleganceColorsPref () {
		Object (application_id: "org.elegance.colors");
	}

	protected override void activate () {
		var window = new EleganceColorsWindow (this);
		window.show_all ();
	}

	protected override void startup () {
		base.startup ();

		var menu = new GLib.Menu ();
		menu.append ("Export theme", "win.export");
		menu.append ("Export settings", "win.exsettings");
		menu.append ("Import settings", "win.impsettings");
		menu.append ("About", "win.about");
		menu.append ("Quit", "win.quit");
		this.app_menu = menu;
	}
}

int main (string[] args) {
	return new EleganceColorsPref ().run (args);
}
