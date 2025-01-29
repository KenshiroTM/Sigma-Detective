using Godot;
using System;
using System.Threading.Tasks;

public partial class GameCanvas : Node
{
	private HuggingFaceAPI bot1API = new HuggingFaceAPI();
	private HuggingFaceAPI bot2API = new HuggingFaceAPI();
	private HuggingFaceAPI bot3API = new HuggingFaceAPI();

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
	[Export] RichTextLabel charlabel1;
	[Export] RichTextLabel charlabel2;
	[Export] RichTextLabel charlabel3;
	[Export] Label SelectedCharacter;

	[ExportSubgroup("GameInput")]
	[Export] TextEdit playerInputText;
	[Export] Button sendButton;

	[ExportSubgroup("GameResult")]
	[Export] Label gameResults;

	[ExportSubgroup("GameAudio")]
	[Export] AudioStreamPlayer2D gameMusic;

	public int botNumber = -1;

	bool initialized = false;

	public override void _Ready()
	{

		continueBtn.Visible = false;
		GameManager.gameState = GameManager.GameState.InGame;
		GameManager.GenerateStory(); // generates story

		//generation of button story ik it is so bad skull
		story.Text = GameManager.currentStory.storyDesc;
		char1.Text = GameManager.currentStory.peopleNames[0];
		char2.Text = GameManager.currentStory.peopleNames[1];
		char3.Text = GameManager.currentStory.peopleNames[2];

		// czekanie az skonczy prompty analizowac
		var res1 = bot1API.SendPrompt(GameManager.currentStory.characterStartingPrompts[0]);
		var res2 = bot2API.SendPrompt(GameManager.currentStory.characterStartingPrompts[1]);
		var res3 = bot3API.SendPrompt(GameManager.currentStory.characterStartingPrompts[2]);

		// TODO: somewhere game generation

		// char1.Pressed = type to character

		backToMenuBtn.Pressed += loadMenu;


		//buttons for char
		char1.Pressed += () => ChangeBotNumber(0);
		char2.Pressed += () => ChangeBotNumber(1);
		char3.Pressed += () => ChangeBotNumber(2);

		sendButton.Pressed += () => GenerateResponse();

		//going back to story and vice versa
		continueBtn.Pressed += swapStory;
		backToStoryButton.Pressed += swapStory;

		//show guilty button
		guiltyButton.Pressed += showGuilty;

		gameMusic.Play();
		continueBtn.Visible = true;
		base._Ready();

		GD.Print("Game Loaded!");
	}

	public override void _PhysicsProcess(double delta)
	{
		if(initialized == false)
		{

			initialized = true;
		}

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

	public async void GenerateResponse()
	{
		if (botNumber != -1)
		{
			string userInput = playerInputText.Text;

			// Odpowiedzi 
			switch (botNumber)
			{
				case 0:
					sendButton.Disabled = true;
					string responseBot1 = await bot1API.SendPrompt($"Chatbot 1: {userInput}");
					charlabel1.Text = $"{GameManager.currentStory.peopleNames[0]}: {responseBot1}";
					sendButton.Disabled = false;
					break;
				case 1:
					sendButton.Disabled = true;
					string responseBot2 = await bot2API.SendPrompt($"Chatbot 2: {userInput}");
					charlabel2.Text = $"{GameManager.currentStory.peopleNames[1]}: {responseBot2}";
					sendButton.Disabled = false;
					break;
				case 2:
					sendButton.Disabled = true;
					string responseBot3 = await bot3API.SendPrompt($"Chatbot 3: {userInput}");
					charlabel3.Text = $"{GameManager.currentStory.peopleNames[2]}: {responseBot3}";
					sendButton.Disabled = false;
					break;
			}
			// Czyszczenie pola wprowadzania tekstu
			playerInputText.Clear();
		}
	}

	public void ChangeBotNumber(int num)
	{
		botNumber = num;
		SelectedCharacter.Text = $"Piszesz do: {GameManager.currentStory.peopleNames[num]}";
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
