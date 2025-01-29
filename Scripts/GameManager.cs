using Godot;
using System;
using System.Collections.Generic;
using System.IO;
using System.Text.Json.Serialization;

public partial class GameManager : Node
{
	public static string gameScene = "res://Scenes/Game/Game.tscn";
	public static string menuScene = "res://Scenes/MainMenu/MainMenu.tscn";
	
	public static Story currentStory = null;

	public enum GameState
	{
		MainMenu,
		InGame,
		GameWon,
		GameLost
	}

	public static void GenerateStory()
	{
		// make it get story before
		currentStory = StoriesReader.GetRandomStory();
	}

	public static void ResetStory()
	{
		currentStory = null;
	}

	public static GameState gameState = GameState.MainMenu;
	// TODO: global script
	
}
