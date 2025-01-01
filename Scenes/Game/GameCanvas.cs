using Godot;
using System;

public partial class GameCanvas : CanvasLayer
{
    [ExportSubgroup("Windows")]
    [Export] ReferenceRect introductionWindow;
    [Export] ReferenceRect gameWindow;

    [ExportSubgroup("MenuButtons")]
    [Export] Button backToMenuBtn;

    [ExportSubgroup("Introduction")]
    [Export] RichTextLabel story;
    [Export] Button continueBtn;

    [ExportSubgroup("GameOutput")]
    [Export] Button char1;
    [Export] Button char2;
    [Export] Button char3;
    [Export] Label charlabel1;
    [Export] Label charlabel2;
    [Export] Label charlabel3;

    [ExportSubgroup("GameInput")]
    [Export] TextEdit playerInputText;
    [Export] Button sendButton;

    public override void _Ready()
    {
        GameManager.gameState = GameManager.GameState.InGame;

        // TODO: somewhere game generation

        backToMenuBtn.Pressed += loadMenu;
        continueBtn.Pressed += continueStory;
    
    }

    
    public void loadMenu()
    {
        GetTree().ChangeSceneToFile(GameManager.menuScene);
    }

    public void continueStory()
    {
        introductionWindow.Visible = false;
        gameWindow.Visible = true;
    }

}
