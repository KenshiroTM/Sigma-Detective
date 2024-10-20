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
    [Export] public Button backToMenuBtn;

    [ExportSubgroup("MainMenuButtons")]
    [Export] public Button playBtn;
    [Export] public Button optionsBtn;
    [Export] public Button exitBtn;

    public override void _Ready() //if runs the game for first time
    {
        //adding functions to buttons
        playBtn.Pressed += SwapPlay;
        backToMenuFromPlay.Pressed += SwapPlay;
        optionsBtn.Pressed += SwapOptions;
        backToMenuBtn.Pressed += SwapOptions;
        exitBtn.Pressed += ExitGame;

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
        GetTree().Quit();
    }
}
