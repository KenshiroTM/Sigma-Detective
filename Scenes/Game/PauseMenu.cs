using Godot;
using System;

public partial class PauseMenu : CanvasLayer
{
    [Export] Button backToMenuBtn;

    public override void _Ready()
    {
        backToMenuBtn.Pressed += loadMenu;
    }

    public void loadMenu()
    {
        GetTree().ChangeSceneToFile("res://Scenes/MainMenu/MainMenu.tscn");
    }
}
