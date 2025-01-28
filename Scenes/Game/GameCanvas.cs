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

	public int outputLabel;
	public string characterName = null;

	public override void _Ready()
	{
		GameManager.gameState = GameManager.GameState.InGame;
		GameManager.GenerateStory(); // generates story

		//generation of button story ik it is so bad skull
		story.Text = GameManager.currentStory.storyDesc;
		char1.Text = GameManager.currentStory.peopleNames[0];
		char2.Text = GameManager.currentStory.peopleNames[1];
		char3.Text = GameManager.currentStory.peopleNames[2];

		gameMusic.Play();

		// TODO: somewhere game generation

		// char1.Pressed = type to character

		backToMenuBtn.Pressed += loadMenu;
		

		//buttons for char
		char1.Pressed += () => setCharacter(1, GameManager.currentStory.peopleNames[0]);
		char2.Pressed += () => setCharacter(2, GameManager.currentStory.peopleNames[1]);
		char3.Pressed += () => setCharacter(3, GameManager.currentStory.peopleNames[2]);

		// sending messages to AI
		sendButton.Pressed += () => typeTo(playerInputText.Text);

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
		backToStoryButton.Visible = false;
		infoLabel.Visible = true;

		charlabel1.Text = "Guilty?";
		charlabel2.Text = "Guilty?";
		charlabel3.Text = "Guilty?";

		// shows result of selected person
		char1.Pressed += () => checkPlayerSelection(0);
		char2.Pressed += () => checkPlayerSelection(1);
		char3.Pressed += () => checkPlayerSelection(2);
	}

	public void checkPlayerSelection(int position)
	{
		// checks if player's selection of guilty is the same as the one from story
		if (GameManager.currentStory.guiltyPeople[position]) // checking pos with guilty people
		{
			GameManager.gameState = GameManager.GameState.GameWon;
		}
		else
		{
			GameManager.gameState = GameManager.GameState.GameLost;
		}
	}

	public void setCharacter(int charOutput, string personName)
	{
		outputLabel = charOutput;
		characterName = personName;
		GD.Print(outputLabel);
		GD.Print(characterName);
	}

	public void typeTo(string inputText)
	{
		if (characterName != null)
		{
			// miejsce na output z AI
			switch (outputLabel)
			{
				case 1:
					charlabel1.Text = "AI output " + characterName;
					break;
				case 2:
					charlabel2.Text = "AI output " + characterName;
					break;
				case 3:
					charlabel3.Text = "AI output of " + characterName;
					break;
			}

		}
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
