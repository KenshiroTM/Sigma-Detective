using Godot;
using System;

public partial class MenuCanvas : CanvasLayer
{
    //buttons to drag and drop
    [ExportSubgroup("MenuWindows")]
    [Export] public ReferenceRect menuWindow;
    [Export] public ReferenceRect optionsWindow;
    [Export] public ReferenceRect playMenu;

    [ExportSubgroup("PlayButtons")]
    [Export] public Button backToMenuFromPlay;

    [ExportSubgroup("OptionsWindowsButtons")]
    [Export] public Button gamePlayButton;
    [Export] public Button backToMenuBtn;

    [Export] public OptionButton resolutionSelect;
    [Export] public CheckButton fullscreenCheck;

    [Export] public Label musicText;
    [Export] public Slider musicSlider;

    [Export] public Label sfxText;
    [Export] public Slider sfxSlider;

    [Export] public Label voicesText;
    [Export] public Slider voicesSlider;

    [ExportSubgroup("MainMenuButtons")]
    [Export] public Button playBtn;
    [Export] public Button optionsBtn;
    [Export] public Button exitBtn;

    [ExportSubgroup("SoundEffects")]
    [Export] public AudioStreamPlayer2D buttonClickSFX;
    [Export] public AudioStreamPlayer2D menuSoundtrack;

    OptionSaver optionSaver = new OptionSaver(); // to save options and user preferences

    public override void _Ready() //if runs the game for first time
    {
        GameManager.gameState = GameManager.GameState.MainMenu;

        LoadSettings();
        // AddButtonsSfx();
        menuSoundtrack.Play();
        // assign to play game
        gamePlayButton.Pressed += StartGame;

        //adding functions to buttons
        playBtn.Pressed += SwapPlay;
        backToMenuFromPlay.Pressed += SwapPlay;
        optionsBtn.Pressed += SwapOptions;
        backToMenuBtn.Pressed += SwapOptions;
        exitBtn.Pressed += ExitGame;

        fullscreenCheck.Pressed += () => ChangeFullscreen();

        resolutionSelect.ItemSelected += (idx) => ChangeResolution();

        musicSlider.ValueChanged += (value) => { ChangeLabel(musicText, musicSlider, "Music"); }; //these functions need to get an argument
        sfxSlider.ValueChanged += (value) => { ChangeLabel(sfxText, sfxSlider, "Sound effects"); };
        voicesSlider.ValueChanged += (value) => { ChangeLabel(voicesText, voicesSlider, "Character Voice"); };

        musicSlider.DragEnded += (value) => { ChangeVolume("Music"); };
        sfxSlider.DragEnded += (value) => { ChangeVolume("Sound effects"); };
        voicesSlider.DragEnded += (value) => { ChangeVolume("Character Voice"); };

        // start game here

        base._Ready();
    }

    public void SwapOptions() // swapping between windows menu/option
    {
        menuWindow.Visible = !menuWindow.Visible;
        optionsWindow.Visible = !optionsWindow.Visible;
    }

    public void SwapPlay()
    {
        menuWindow.Visible = !menuWindow.Visible;
        playMenu.Visible = !playMenu.Visible;
    }

    public void ExitGame() // quitting game
    {
        optionSaver.SaveSettings();
        GetTree().Quit();
    }

    public void ChangeLabel(Label text, Slider slider, String labelName)
    {
        text.Text = labelName + " " + slider.Value + "%";
    }

    public void ChangeFullscreen()
    {
        optionSaver.isFullscreen = !optionSaver.isFullscreen;

        if (optionSaver.isFullscreen == true) // if fulscreen switch is on, enable it
        {
            DisplayServer.WindowSetMode(DisplayServer.WindowMode.Fullscreen);
        }
        else
        {
            DisplayServer.WindowSetMode(DisplayServer.WindowMode.Windowed);
        }

        ScaleResolution();
    }

    public void ChangeResolution()
    {
        String selectedResolution = resolutionSelect.GetItemText(resolutionSelect.Selected);
        String[] resolutionParams = selectedResolution.Split('x'); //split selected params with division between x (x appears in all options cause its resolution)

        optionSaver.screenWidth = Convert.ToInt32(resolutionParams[0]); // saving from array to optionSaver
        optionSaver.screenHeight = Convert.ToInt32(resolutionParams[1]);
        optionSaver.resolutionSelectId = resolutionSelect.Selected;

        ScaleResolution();
    }

    public void ChangeVolume(String volumeName) //changing volume and saving presets
    {
        if (volumeName == "Music")
        {
            optionSaver.musicVolume = musicSlider.Value; //value from slider
            var music = AudioServer.GetBusIndex("Music");
            AudioServer.SetBusVolumeDb(music, (float)Mathf.LinearToDb(musicSlider.Value / 100));
        }
        else if (volumeName == "Sound effects")
        {
            optionSaver.sfxVolume = sfxSlider.Value;
            var sfx = AudioServer.GetBusIndex("Sound Effects");
            AudioServer.SetBusVolumeDb(sfx, (float)Mathf.LinearToDb(sfxSlider.Value / 100)); // divide be 100 to fit function conversion
        }
        else if (volumeName == "Character Voice")
        {
            var voice = AudioServer.GetBusIndex("Character Voice");
            AudioServer.SetBusVolumeDb(voice, (float)Mathf.LinearToDb(sfxSlider.Value / 100));
        }
    }

    public void ScaleResolution()
    {
        //read docs here
        
        Vector2I scaledRes = new Vector2I(optionSaver.screenWidth, optionSaver.screenHeight);
        GetWindow().ContentScaleSize = scaledRes;
        DisplayServer.WindowSetSize(scaledRes);
        optionsWindow.Size = scaledRes;
        menuWindow.Size = scaledRes;
    }

    public void UpdateSettings()
    {
        DisplayServer.WindowSetVsyncMode(DisplayServer.VSyncMode.Enabled);
        Engine.MaxFps = 60;

        if (optionSaver.isFullscreen == true) { DisplayServer.WindowSetMode(DisplayServer.WindowMode.Fullscreen); }
        else { DisplayServer.WindowSetMode(DisplayServer.WindowMode.Windowed); }

        var music = AudioServer.GetBusIndex("Music");
        
        
        var sfx = AudioServer.GetBusIndex("Sound Effects");
        

        var voices = AudioServer.GetBusIndex("Character Voice");


        if (DisplayServer.ScreenGetSize()[0] < optionSaver.screenWidth || DisplayServer.ScreenGetSize()[1] < optionSaver.screenHeight)
        { //if screen size is smaller than the one in options launch code
            for (int i = 0; i < resolutionSelect.ItemCount - 1; i++)
            {
                string[] selectedRes = resolutionSelect.GetItemText(i).Split('x'); // get through all select items values
                if (DisplayServer.ScreenGetSize()[0] < Convert.ToInt32(selectedRes[0]) || DisplayServer.ScreenGetSize()[1] < Convert.ToInt32(selectedRes[1]))
                { // if selected item is bigger than screen do the code below

                    string[] highestAvaliableRes = resolutionSelect.GetItemText(i + 1).Split('x');
                    // highest res is now one below the one that was higher, do until there is resolution smaller than the screen
                    optionSaver.resolutionSelectId = i + 1; // update select same way as resolution, to one below
                    optionSaver.screenWidth = Convert.ToInt32(highestAvaliableRes[0]);
                    optionSaver.screenHeight = Convert.ToInt32(highestAvaliableRes[1]); //save highest avaliable res in option saver
                }
            }
        }
        for (int i = 0; i < resolutionSelect.ItemCount - 1; i++) // disable all the resolutions that are higher than screen size
        {
            string[] selectedRes = resolutionSelect.GetItemText(i).Split('x');
            if (DisplayServer.ScreenGetSize()[0] < Convert.ToInt32(selectedRes[0]) || DisplayServer.ScreenGetSize()[1] < Convert.ToInt32(selectedRes[1]))
            { //if screen size is lower than one in select disable it
                resolutionSelect.SetItemDisabled(i, true);
            }
        }

        ScaleResolution();
    }

    public void UpdateButtons()
    {
        fullscreenCheck.ButtonPressed = optionSaver.isFullscreen;

        musicSlider.Value = optionSaver.musicVolume;
        sfxSlider.Value = optionSaver.sfxVolume;
        voicesSlider.Value = optionSaver.voicesVolume;

        resolutionSelect.Selected = optionSaver.resolutionSelectId;

        musicText.Text = "Music " + optionSaver.musicVolume + "%";
        sfxText.Text = "Sound effects" + optionSaver.sfxVolume + "%";
        voicesText.Text = "Character voice" + optionSaver.voicesVolume + "%";
    }

    public void LoadSettings()
    {
        if(optionSaver.LoadSettings() == true)
        {
            UpdateSettings();
            UpdateButtons();
        }
        else
        {
            optionSaver.resolutionSelectId = 0;

            optionSaver.musicVolume = 50;
            optionSaver.sfxVolume = 50;
            optionSaver.voicesVolume = 50;

            optionSaver.isFullscreen = true;

            String selectedResolution = resolutionSelect.GetItemText(optionSaver.resolutionSelectId);
            String[] resolutionParams = selectedResolution.Split('x');
            optionSaver.screenWidth = Convert.ToInt32(resolutionParams[0]);
            optionSaver.screenHeight = Convert.ToInt32(resolutionParams[1]);

            optionSaver.SaveSettings();

            UpdateSettings();
            UpdateButtons();
        }
    }
    public void StartGame()
    {
        GetTree().ChangeSceneToFile(GameManager.gameScene);
    }
}
