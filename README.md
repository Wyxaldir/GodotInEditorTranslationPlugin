# GodotInEditorTranslationPlugin
A plugin for Godot that makes creating and maintaining translations much easier and intuitive in-editor. 

The goal of this plugin is to make it easy to create new translations and add them to existing or new .csv files. 
This will replace the old workflow of creating new .csv files and adding text before then adding them to editor without being able to see what you're adding. This method is also prone to mistakes where you could make a typo in the key for example. This workflow is also harder to follow through with, as you need to plan out all the text you need ahead of time, or go back and forth between the game and your .csv files constantly.

This plugin fixes these issues, and makes it all doable within the editor's inspector. 

# Features
![image](https://user-images.githubusercontent.com/36777181/158617495-b95b6239-b059-4519-90bb-ab49cce61f20.png)

When viewing a variable in the inspector that you have configured to use the translation plugin, you will see the above ui. From here, you can see the translation key (KEY_WELCOME_MESSAGE) and below is the translated version. 

If you want to swap the key to another, you can click on the folder button to browse all keys found in the configured translation files location.
If you need to edit the translation, simply change it in editor and hit the save icon to save it back to the same file.

You can also create new translations by writing in a new key and translation value and hitting the save icon. From here, you can select an existing file to append to it or save to a new file which will be properly configured based on which languages are loaded with the translation server.

# Installation:
Simply copy/paste the addons folder into your own addons folder in your project. 
Once you have copied over the addon, enable it in projectSettings/plugins.

# Configuration:
There are two settings that can be configured once the plugin is loaded: Translation Location and Valid Variable Names.

Editing Translation Locations will set where the plugin will look for the translation files. Is "res://translations" by default.

Editing Valid Variable Names will set which string edits will have the translation display. Is "text" by default.
For example, you can add "DisplayValue" to the array and whenever you have an exported variable called DisplayValue it will make use of the translation ui.

