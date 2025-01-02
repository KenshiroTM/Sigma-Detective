using Godot;
using System;

public partial class GameCanvas : CanvasLayer
{
    [ExportSubgroup("Windows")]
    [Export] ReferenceRect introductionWindow;
    [Export] ReferenceRect gameWindow;
    [Export] ReferenceRect resultWindow;

    [ExportSubgroup("MenuButtons")]
    [Export] Button backToMenuBtn;

    [ExportSubgroup("Introduction")]
    [Export] RichTextLabel story;
    [Export] Button continueBtn;

    [ExportSubgroup("GameOutput")]
    [Export] Button guiltyButton;
    [Export] Label infoLabel;
    [Export] Button char1;
    [Export] Button char2;
    [Export] Button char3;
    [Export] Label charlabel1;
    [Export] Label charlabel2;
    [Export] Label charlabel3;

    [ExportSubgroup("GameInput")]
    [Export] TextEdit playerInputText;
    [Export] Button sendButton;

    [ExportSubgroup("GameResult")]
    [Export] Label gameResults;

    public override void _Ready()
    {
        GameManager.gameState = GameManager.GameState.InGame;

        // TODO: somewhere game generation

        backToMenuBtn.Pressed += loadMenu;
        continueBtn.Pressed += continueStory;

        guiltyButton.Pressed += showGuilty;
    
    }
    public override void _PhysicsProcess(double delta)
    {
        // checking for states

        base._PhysicsProcess(delta);
    }



    public void showGuilty()
    {
        playerInputText.Visible = false;
        sendButton.Visible = false;

        guiltyButton.Visible = false;
        infoLabel.Visible = true;

        charlabel1.Text = "Guilty?";
        charlabel2.Text = "Guilty?";
        charlabel3.Text = "Guilty?";
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
