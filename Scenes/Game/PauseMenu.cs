using Godot;
using System;

public partial class PauseMenu : CanvasLayer
{
    [Export] Button backToMenuBtn;

    public override void _Ready()
    {
        GameManager.gameState = GameManager.GameState.InGame;

        backToMenuBtn.Pressed += loadMenu;
    }

    public void loadMenu()
    {
        GetTree().ChangeSceneToFile(GameManager.menuScene);
    }
}
