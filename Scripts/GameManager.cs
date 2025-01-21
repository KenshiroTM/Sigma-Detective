using Godot;
using System;
using System.Collections.Generic;

public partial class GameManager : Node
{
    public static string gameScene = "res://Scenes/Game/Game.tscn";
    public static string menuScene = "res://Scenes/MainMenu/MainMenu.tscn";

    public static List<Character> storyCharacters;
    public static string story;

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

        storyCharacters.Add(new Character());
    }

    public static void ResetStory()
    {
        storyCharacters.Clear();
    }

    public static GameState gameState = GameState.MainMenu;
    // TODO: global script
    
}