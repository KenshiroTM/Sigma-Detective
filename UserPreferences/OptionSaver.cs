using Godot;
using System;

public partial class OptionSaver : JsonRpc
{
    public string pathname;

    public int resolutionSelectId; 

    public bool isFullscreen;

    public double musicVolume;
    public double sfxVolume;
    public double voicesVolume;

    public int screenWidth;
    public int screenHeight;

    public OptionSaver()
    {
        pathname = "res://UserPreferences/game_settings.json";
    }

    public void SaveSettings()
    {
        ConfigFile menuOptions = new ConfigFile();

        menuOptions.SetValue("game_settings", "resolutionSelectId", resolutionSelectId);

        menuOptions.SetValue("game_settings", "isFullscreen", isFullscreen); //fullscreen

        menuOptions.SetValue("game_settings", "musicVolume", musicVolume); // audio
        menuOptions.SetValue("game_settings", "sfxVolume", sfxVolume);
        menuOptions.SetValue("game_settings", "voicesVolume", voicesVolume);

        menuOptions.SetValue("game_settings", "screenWidth", screenWidth); // resolution
        menuOptions.SetValue("game_settings", "screenHeingt", screenHeight);

        menuOptions.Save(pathname);
    }

    public bool LoadSettings()
    {
        ConfigFile menuOptions = new ConfigFile();

        Error err = menuOptions.Load(pathname);

        if(err!=Error.Ok)
        {
            return false;
        }

        resolutionSelectId = (int)menuOptions.GetValue("game_settings", "resolutionSelectId");

        isFullscreen = (bool)menuOptions.GetValue("game_settings", "isFullscreen");

        musicVolume = (double)menuOptions.GetValue("game_settings", "musicVolume");
        sfxVolume = (double)menuOptions.GetValue("game_settings", "sfxVolume");
        voicesVolume = (double)menuOptions.GetValue("game_settings", "voicesVolume");

        screenWidth = (int)menuOptions.GetValue("game_settings", "screenWidth");
        screenHeight = (int)menuOptions.GetValue("game_settings", "screenHeingt");

        return true;
    }
}
