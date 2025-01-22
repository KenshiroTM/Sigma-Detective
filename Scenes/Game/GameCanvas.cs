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
    [Export] Button backToStoryButton;
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

    [ExportSubgroup("GameAudio")]
    [Export] AudioStreamPlayer2D gameMusic;

    public override void _Ready()
    {
        GameManager.gameState = GameManager.GameState.InGame;
        GameManager.GenerateStory(); // generates story

        gameMusic.Play();

        // TODO: somewhere game generation

        backToMenuBtn.Pressed += loadMenu;

        //going back to story and vice versa
        continueBtn.Pressed += swapStory;
        backToStoryButton.Pressed += swapStory;

        //show guilty button
        guiltyButton.Pressed += showGuilty;
    }

    public override void _PhysicsProcess(double delta)
    {
        // checking for states
        if (GameManager.gameState != GameManager.GameState.InGame)
        {
            if(GameManager.gameState == GameManager.GameState.GameWon) { gameResults.Text = "You won!"; }
            else if(GameManager.gameState == GameManager.GameState.GameLost) { gameResults.Text = "Yout lost!"; }
            showResult();
        }
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

        // shows result of selected person
        char1.Pressed += checkPlayerSelection;
        char2.Pressed += checkPlayerSelection;
        char3.Pressed += checkPlayerSelection;
    }

    public void checkPlayerSelection()
    {
        // checks if player's selection of guilty is the same as the one from story
        GameManager.gameState = GameManager.GameState.GameWon; // to change to story checking!
    }

    public void showResult()
    {   //Game result screen
        gameWindow.Visible = false;
        resultWindow.Visible = true;

        // if won GameState = won, 
    }

    public void loadMenu()
    {
        GetTree().ChangeSceneToFile(GameManager.menuScene);
    }

    public void swapStory() // Swaps between story and game scene
    {
        introductionWindow.Visible = !introductionWindow.Visible;
        gameWindow.Visible = !introductionWindow.Visible;
    }

}
